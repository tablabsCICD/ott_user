import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:ott/app/core/network/anti_piracy_api_client.dart';
import 'package:ott/app/core/repositories/secure_playback_repository.dart';
import 'package:ott/app/core/services/playback_analytics_coordinator.dart';
import 'package:ott/app/core/utils/security_debug_log.dart';
import 'package:ott/data/models/anti_piracy_models.dart';

enum SecurePlaybackState {
  preparingSecurity,
  requestingPlaybackAccess,
  initializingPlayer,
  ready,
  playing,
  paused,
  refreshingUrl,
  accessDenied,
  playbackError,
  disposed,
}

class SecureMediaRestoreResult {
  const SecureMediaRestoreResult({required this.isPlaying});
  final bool isPlaying;
}

typedef SecureMediaLoader = Future<SecureMediaRestoreResult> Function(
  SignedPlaybackResponse authorization, {
  required bool isRefresh,
});
typedef SecureMediaPauser = Future<void> Function();

class SecurePlaybackController extends ChangeNotifier {
  SecurePlaybackController({
    required this.contentId,
    required this.originalPlaybackUrl,
    required this.type,
    required this.country,
    required SecureMediaLoader mediaLoader,
    required SecureMediaPauser pausePlayer,
    SecurePlaybackRepository? repository,
    this.refreshLead = const Duration(seconds: 60),
    this.watermarkInterval = const Duration(seconds: 60),
  })  : _repository = repository ?? SecurePlaybackRepository.instance,
        _mediaLoader = mediaLoader,
        _pausePlayer = pausePlayer {
    _analytics = PlaybackAnalyticsCoordinator(
      repository: _repository,
      contentId: contentId,
      country: country,
    );
    SecurePlaybackSessionRegistry.instance.add(this);
  }

  final String contentId;
  final String originalPlaybackUrl;
  final String country;
  final Duration refreshLead;
  final Duration watermarkInterval;
  final SecurePlaybackRepository _repository;
  final SecureMediaLoader _mediaLoader;
  final SecureMediaPauser _pausePlayer;
  late final PlaybackAnalyticsCoordinator _analytics;
  final String type;
  SecurePlaybackState _state = SecurePlaybackState.preparingSecurity;
  SecurePlaybackState get state => _state;
  SignedPlaybackResponse? _currentAuthorization;
  String? _sessionId;
  DateTime? _expiresAt;
  WatermarkData? _watermark;
  WatermarkData? get watermark => _watermark;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  SecurePlaybackFailure? _failure;
  SecurePlaybackFailure? get failure => _failure;
  Timer? _refreshTimer;
  Timer? _watermarkTimer;
  Future<void>? _refreshRequest;
  Future<void>? _startRequest;
  bool _disposed = false;
  bool _handledPlayer403 = false;

  Future<void> start() {
    return _startRequest ??= _start().whenComplete(() => _startRequest = null);
  }

  Future<void> _start() async {
    if (_disposed) return;
    SecurityDebugLog.event(
      'FLOW',
      'Player controller requested protected playback.',
    );
    _setState(SecurePlaybackState.preparingSecurity);
    try {
      _setState(SecurePlaybackState.requestingPlaybackAccess);
      final response = await _repository.createSignedPlaybackSession(
        contentId: contentId,
        playbackUrl: originalPlaybackUrl,
        country: country,
        type: type,
      );
      if (_disposed) return;
      final secondsUntilExpiry =
          response.expiresAt.difference(DateTime.now().toUtc()).inSeconds;
      SecurityDebugLog.event(
        'FLOW',
        'Playback authorization validated in memory; expires in approximately $secondsUntilExpiry seconds.',
      );
      _applySession(response);
      _analytics.bindSession(response.sessionId);
      _setState(SecurePlaybackState.initializingPlayer);
      SecurityDebugLog.event(
        'PLAYER',
        'Calling the media loader with the normalized platform authorization.',
      );
      final restored = await _mediaLoader(response, isRefresh: false);
      if (_disposed) return;
      SecurityDebugLog.event(
        'PLAYER',
        'Signed media source initialized; playing=${restored.isPlaying}.',
      );
      _setState(restored.isPlaying
          ? SecurePlaybackState.playing
          : SecurePlaybackState.ready);
      _analytics.onPlayingChanged(restored.isPlaying);
      _scheduleRefresh();
      await _refreshWatermark();
      _watermarkTimer?.cancel();
      _watermarkTimer = Timer.periodic(
        watermarkInterval,
        (_) => unawaited(_refreshWatermark()),
      );
    } on SecurePlaybackException catch (error) {
      SecurityDebugLog.event(
        'ERROR',
        'Secure startup failed with category ${error.failure.name}.',
      );
      await _analytics.stopCurrentSession();
      await _handleFailure(error);
    } catch (error, stackTrace) {
      SecurityDebugLog.exception(
        'SECURE_STARTUP',
        error,
        stackTrace,
      );
      SecurityDebugLog.event(
        'ERROR',
        'Secure startup failed with an unexpected error; sanitized details are in HTTP_DIAGNOSTIC.',
      );
      await _analytics.stopCurrentSession();
      await _handleFailure(const SecurePlaybackException(
        SecurePlaybackFailure.invalidResponse,
        'Secure playback could not be prepared.',
      ));
    }
  }

  void onPlayingChanged(bool isPlaying) {
    if (_disposed || _state == SecurePlaybackState.refreshingUrl) return;
    _setState(
      isPlaying ? SecurePlaybackState.playing : SecurePlaybackState.paused,
    );
    _analytics.onPlayingChanged(isPlaying);
  }

  Future<void> refreshNow() {
    return _refreshRequest ??= _refresh().whenComplete(() {
      _refreshRequest = null;
    });
  }

  Future<void> _refresh() async {
    if (_disposed || _sessionId == null) return;
    SecurityDebugLog.event(
      'REFRESH',
      'Refreshing signed access while preserving player state.',
    );
    _refreshTimer?.cancel();
    _setState(SecurePlaybackState.refreshingUrl);
    try {
      final response = await _requestRefreshWithRetry();
      if (_disposed) return;
      SecurityDebugLog.event(
        'REFRESH',
        'New signed response validated; replacing the player media source.',
      );
      final restored = await _mediaLoader(response, isRefresh: true);
      if (_disposed) return;
      await _analytics.stopCurrentSession();
      _applySession(response);
      _analytics.bindSession(response.sessionId);
      _setState(restored.isPlaying
          ? SecurePlaybackState.playing
          : SecurePlaybackState.paused);
      _analytics.onPlayingChanged(restored.isPlaying);
      _scheduleRefresh();
      SecurityDebugLog.event(
        'REFRESH',
        'Player state restored and the next refresh was scheduled.',
      );
    } on SecurePlaybackException catch (error) {
      await _pausePlayer();
      await _handleFailure(error);
    } catch (error, stackTrace) {
      SecurityDebugLog.exception(
        'SIGNED_URL_REFRESH',
        error,
        stackTrace,
      );
      await _pausePlayer();
      await _handleFailure(const SecurePlaybackException(
        SecurePlaybackFailure.invalidResponse,
        'Secure playback could not be refreshed. Please retry.',
      ));
    }
  }

  Future<SignedPlaybackResponse> _requestRefreshWithRetry() async {
    try {
      return await _repository.createSignedPlaybackSession(
          contentId: contentId,
          playbackUrl: originalPlaybackUrl,
          country: country,
          type: type);
    } on SecurePlaybackException catch (error) {
      if (!error.isTransient || _disposed) rethrow;
      await Future<void>.delayed(const Duration(seconds: 2));
      if (_disposed) rethrow;
      return _repository.createSignedPlaybackSession(
          contentId: contentId,
          playbackUrl: originalPlaybackUrl,
          country: country,
          type: type);
    }
  }

  Future<void> handlePlayerHttp403() async {
    if (_disposed || _handledPlayer403) return;
    _handledPlayer403 = true;
    SecurityDebugLog.event(
      'PLAYER',
      'Player reported HTTP 403; starting the single controlled refresh.',
    );
    await refreshNow();
  }

  Future<void> onBackground() async {
    if (_disposed) return;
    await _pausePlayer();
  }

  Future<void> onForeground() async {
    if (_disposed || _currentAuthorization == null || _expiresAt == null) {
      return;
    }
    if (DateTime.now().toUtc().isAfter(_expiresAt!.subtract(refreshLead))) {
      await refreshNow();
    }
  }

  static Duration refreshDelay({
    required DateTime expiresAt,
    required DateTime now,
    Duration lead = const Duration(seconds: 60),
  }) {
    final delay = expiresAt.toUtc().difference(now.toUtc()) - lead;
    return delay.isNegative ? Duration.zero : delay;
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    final expiry = _expiresAt;
    if (_disposed || expiry == null) return;
    final delay =
        refreshDelay(expiresAt: expiry, now: DateTime.now(), lead: refreshLead);
    SecurityDebugLog.event(
      'REFRESH',
      'Next signed-access refresh scheduled in ${delay.inSeconds} seconds.',
    );
    _refreshTimer = Timer(
      delay,
      () => unawaited(refreshNow()),
    );
  }

  Future<void> _refreshWatermark() async {
    if (_disposed) return;
    try {
      SecurityDebugLog.event(
        'WATERMARK',
        'Requesting the current forensic watermark.',
      );
      final value = await _repository.getCurrentWatermark();
      if (_disposed) return;
      _watermark = value;
      SecurityDebugLog.event(
        'WATERMARK',
        'Watermark loaded successfully; protected credential values remain redacted.',
      );
      notifyListeners();
    } catch (error, stackTrace) {
      SecurityDebugLog.exception(
        'WATERMARK_REFRESH',
        error,
        stackTrace,
      );
      SecurityDebugLog.event(
        'WATERMARK',
        'Watermark refresh failed; playback continues.',
      );
      // Watermark refresh failure must not expose data or crash playback.
    }
  }

  void _applySession(SignedPlaybackResponse response) {
    _currentAuthorization = response;
    _sessionId = response.sessionId;
    _expiresAt = response.expiresAt;
    _failure = null;
    _errorMessage = null;
  }

  Future<void> _handleFailure(SecurePlaybackException error) async {
    if (_disposed) return;
    _refreshTimer?.cancel();
    _watermarkTimer?.cancel();
    _refreshTimer = null;
    _watermarkTimer = null;
    _currentAuthorization = null;
    _sessionId = null;
    _expiresAt = null;
    _failure = error.failure;
    _errorMessage = error.userMessage;
    SecurityDebugLog.event(
      'ERROR',
      'Mapped failure ${error.failure.name} to a safe player error state.',
    );
    _setState(error.failure == SecurePlaybackFailure.accessDenied ||
            error.failure == SecurePlaybackFailure.unauthenticated ||
            error.failure == SecurePlaybackFailure.integrityUnavailable ||
            error.failure == SecurePlaybackFailure.unsupportedPlatform
        ? SecurePlaybackState.accessDenied
        : SecurePlaybackState.playbackError);
  }

  void _setState(SecurePlaybackState value) {
    if (_disposed || _state == value) return;
    SecurityDebugLog.state(_state.name, value.name);
    _state = value;
    notifyListeners();
  }

  Future<void> stop() => _analytics.stopCurrentSession();

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _state = SecurePlaybackState.disposed;
    _refreshTimer?.cancel();
    _watermarkTimer?.cancel();
    _refreshTimer = null;
    _watermarkTimer = null;
    _currentAuthorization = null;
    _sessionId = null;
    _expiresAt = null;
    _watermark = null;
    SecurePlaybackSessionRegistry.instance.remove(this);
    unawaited(_analytics.dispose());
    super.dispose();
  }
}

class SecurePlaybackSessionRegistry {
  SecurePlaybackSessionRegistry._();
  static final SecurePlaybackSessionRegistry instance =
      SecurePlaybackSessionRegistry._();

  final Set<SecurePlaybackController> _controllers = {};

  void add(SecurePlaybackController controller) => _controllers.add(controller);
  void remove(SecurePlaybackController controller) =>
      _controllers.remove(controller);

  Future<void> stopAll() async {
    final controllers = List<SecurePlaybackController>.from(_controllers);
    await Future.wait(controllers.map((controller) => controller.stop()));
    for (final controller in controllers) {
      controller.dispose();
    }
  }
}
