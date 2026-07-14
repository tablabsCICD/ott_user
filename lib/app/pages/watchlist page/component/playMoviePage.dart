import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/network/anti_piracy_api_client.dart';
import 'package:ott/app/core/services/anti_piracy_service.dart';
import 'package:ott/app/core/utils/security_debug_log.dart';
import 'package:ott/app/core/services/session_manager.dart';
import 'package:ott/app/provider/secure_playback_controller.dart';
import 'package:ott/data/models/anti_piracy_models.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as youtube;

import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/playback_watermark_overlay.dart';
import 'package:ott/app/widgets/video_skip_controls.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import '../../../provider/offline_download_provider.dart';
import '../../../provider/playMediaProvider.dart';

String? _extractYoutubeId(String urlOrId) {
  final value = urlOrId.trim();
  if (value.isEmpty) return null;

  final converted = youtube.YoutubePlayer.convertUrlToId(value);
  if (converted != null && converted.isNotEmpty) return converted;

  final looksLikeVideoId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(value);
  return looksLikeVideoId ? value : null;
}

String _resolvePlaybackCountryCode() {
  final countryCode =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode;
  final normalized = countryCode?.trim().toUpperCase();
  if (normalized != null && RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
    return normalized;
  }
  return 'IN';
}

class PlayMediaPage extends StatefulWidget {
  final Content? content;
  final int? seasonIndex;
  final int? episodeIndex;
  final List<SeasonEntity>? seasons;
  final String videoUrl;

  const PlayMediaPage({
    super.key,
    required this.videoUrl,
    this.content,
    this.seasonIndex,
    this.episodeIndex,
    this.seasons,
  });

  @override
  State<PlayMediaPage> createState() => _PlayMediaPageState();
}

class _PlayMediaPageState extends State<PlayMediaPage>
    with WidgetsBindingObserver {
  Player? _player;
  VideoController? _videoController;
  youtube.YoutubePlayerController? _youtubeController;
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];
  Timer? _progressTimer;

  bool _loading = true;
  bool _hasPlaybackError = false;
  bool _handlingEnd = false;
  Duration _lastSavedPosition = Duration.zero;
  bool _wakelockEnabled = false;
  bool _isDisposed = false;
  bool _isExiting = false;
  int _setupToken = 0;
  bool _isOfflinePlayback = false;
  String? _playbackMessage;
  String? _currentRemotePlaybackUrl;
  SecurePlaybackController? _securePlaybackController;
  bool _handlingSecureAuthenticationFailure = false;
  Duration? _lastLoggedDuration;

  bool get _isSeries =>
      widget.content?.type?.toLowerCase() == "series" &&
      widget.seasons != null &&
      widget.episodeIndex != null;

  @override
  void initState() {
    super.initState();
    SecurityDebugLog.event(
      'ROUTE',
      'PlayMediaPage.initState reached from the Watch Movie route.',
    );
    WidgetsBinding.instance.addObserver(this);
    unawaited(AntiPiracyService.instance.enableScreenProtection());
    unawaited(_startFullscreenPlayback());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_player?.pause());
      _youtubeController?.pause();
      unawaited(_securePlaybackController?.onBackground());
      _saveProgress();
    } else if (state == AppLifecycleState.resumed) {
      unawaited(_securePlaybackController?.onForeground());
    }
  }

  Future<void> _enterLandscapePlayback() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restorePortraitPlayback() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    await AntiPiracyService.instance.disableScreenProtection();
  }

  Future<void> _startFullscreenPlayback() async {
    SecurityDebugLog.event(
      'FLOW',
      'Fullscreen player startup began.',
    );
    try {
      await _enterLandscapePlayback();
      SecurityDebugLog.event(
        'PLAYER',
        'Landscape fullscreen mode was enabled.',
      );
    } catch (_) {
      SecurityDebugLog.event(
        'PLAYER',
        'Fullscreen/orientation setup is unavailable; continuing secure playback.',
      );
    }
    if (!mounted || _isDisposed) return;

    SecurityDebugLog.event(
      'FLOW',
      'Calling secure playback preparation.',
    );
    await _preparePlayback();
    if (!mounted || _isDisposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _addView();
      }
    });
  }

  void _addView() {
    if (widget.content?.id == null) return;

    context.read<PlayMediaProvider>().addView(
          mediaId: _isSeries ? widget.episodeIndex! : widget.content!.id!,
          isSeries: _isSeries,
        );
  }

  Future<void> _preparePlayback() async {
    SecurityDebugLog.event(
      'FLOW',
      'Resolving the media source before requesting signed access.',
    );
    String sourceUrl = await _resolveOfflineSourceUrl(widget.videoUrl.trim());
    if (sourceUrl.isEmpty) {
      SecurityDebugLog.event(
        'FLOW',
        'Secure playback stopped because the media source is empty.',
      );
      _showPlaybackError('Video unavailable');
      return;
    }

    final youtubeId = _extractYoutubeId(sourceUrl);

    if (youtubeId != null && youtubeId.isNotEmpty) {
      SecurityDebugLog.event(
        'FLOW',
        'External YouTube source identified; using the existing YouTube player path.',
      );
      await _setupYoutubePlayer(youtubeId);
      return;
    }

    if (_isOfflinePlayback) {
      SecurityDebugLog.event(
        'FLOW',
        'Signed API was not called because an existing offline file was selected.',
      );
      // Existing downloaded files are local media and do not have a CloudFront
      // URL to sign. Online protected content always follows the secure flow.
      await _setupPlayer(sourceUrl, playFromFile: true);
      return;
    }

    final contentId = _isSeries ? widget.episodeIndex : widget.content?.id;
    if (contentId == null) {
      SecurityDebugLog.event(
        'FLOW',
        'Signed API was not called because the content ID is missing.',
      );
      _showPlaybackError('The requested content was not found.');
      return;
    }
    SecurityDebugLog.event(
      'FLOW',
      'Online protected content identified; starting the anti-piracy API flow.',
    );
    await _startSecurePlayback(
      sourceUrl: sourceUrl,
      contentId: contentId.toString(),
    );
  }

  Future<String> _resolveOfflineSourceUrl(String sourceUrl) async {
    if (sourceUrl.isNotEmpty && await _isExistingLocalFile(sourceUrl)) {
      _isOfflinePlayback = true;
      return sourceUrl;
    }

    final content = widget.content;
    if (content == null) {
      _isOfflinePlayback = false;
      return sourceUrl;
    }

    if (!mounted) return sourceUrl;
    final offlinePath =
        await context.read<OfflineDownloadProvider>().getOfflinePath(content);
    if (offlinePath != null &&
        offlinePath.trim().isNotEmpty &&
        await _isExistingLocalFile(offlinePath)) {
      _isOfflinePlayback = true;
      return offlinePath.trim();
    }

    _isOfflinePlayback = false;
    return sourceUrl;
  }

  Future<bool> _isExistingLocalFile(String value) async {
    if (kIsWeb || value.trim().isEmpty) return false;

    final fileUri = Uri.tryParse(value);
    final path = fileUri?.scheme == 'file' ? fileUri!.toFilePath() : value;

    try {
      return File(path).exists();
    } catch (_) {
      return false;
    }
  }

  Future<void> _startSecurePlayback({
    required String sourceUrl,
    required String contentId,
  }) async {
    SecurityDebugLog.event(
      'PLAYER',
      'Protected player route is calling SecurePlaybackController.start().',
    );
    final previous = _securePlaybackController;
    if (previous != null) {
      previous.removeListener(_onSecurePlaybackChanged);
      await previous.stop();
      previous.dispose();
    }
    _currentRemotePlaybackUrl = sourceUrl;
    final controller = SecurePlaybackController(
      contentId: contentId,
      originalPlaybackUrl: sourceUrl,
      country: _resolvePlaybackCountryCode(),
      mediaLoader: _loadSecureMedia,
      pausePlayer: _pauseActivePlayer,
    );
    _securePlaybackController = controller;
    controller.addListener(_onSecurePlaybackChanged);
    await controller.start();
  }

  void _onSecurePlaybackChanged() {
    if (!mounted || _isDisposed) return;
    final controller = _securePlaybackController;
    if (controller == null) return;
    if (controller.failure == SecurePlaybackFailure.unauthenticated &&
        !_handlingSecureAuthenticationFailure) {
      _handlingSecureAuthenticationFailure = true;
      unawaited(
        SessionManager.instance.handleSessionExpired(
            'Your session has expired. Please sign in again.'),
      );
    }
    setState(() {
      _playbackMessage = controller.errorMessage;
      _hasPlaybackError =
          controller.state == SecurePlaybackState.accessDenied ||
              controller.state == SecurePlaybackState.playbackError;
    });
  }

  Future<SecureMediaRestoreResult> _loadSecureMedia(
    SignedPlaybackResponse authorization, {
    required bool isRefresh,
  }) async {
    SecurityDebugLog.event(
      'PLAYER',
      isRefresh
          ? 'Received refreshed CloudFront cookies; reinitializing media_kit.'
          : 'Received CloudFront signed-cookie authorization; initializing media_kit now.',
    );
    final playbackUri = Uri.tryParse(authorization.playbackUrl);
    SecurityDebugLog.diagnostic(
      'SIGNED_MEDIA_METADATA validUri=${playbackUri != null} '
      'scheme=${playbackUri?.scheme ?? '<missing>'} '
      'host=${playbackUri?.host ?? '<missing>'} '
      'authorizationType=${authorization.authorizationType} '
      'cookieNames=${authorization.cookies.keys.toList()} '
      'cookieValuesRedacted=true',
    );
    final previous = _player?.state;
    final position = previous?.position ?? Duration.zero;
    final wasPlaying = previous?.playing ?? true;
    final volume = previous?.volume ?? 100;
    final rate = previous?.rate ?? 1;
    final audioTrack = previous?.track.audio;
    final subtitleTrack = previous?.track.subtitle;

    await _setupPlayer(
      authorization.playbackUrl,
      httpHeaders: {'Cookie': authorization.cookieHeader},
      diagnoseSignedHls: true,
    );
    final player = _player;
    if (player == null || _hasPlaybackError) {
      SecurityDebugLog.event(
        'PLAYER',
        'media_kit could not initialize the signed media source.',
      );
      throw StateError('Secure media initialization failed');
    }

    if (isRefresh) {
      if (position > Duration.zero) await player.seek(position);
      await player.setVolume(volume);
      await player.setRate(rate);
      if (audioTrack != null) await player.setAudioTrack(audioTrack);
      if (subtitleTrack != null) await player.setSubtitleTrack(subtitleTrack);
      if (wasPlaying) {
        await player.play();
      } else {
        await player.pause();
      }
    }
    SecurityDebugLog.event(
      'PLAYER',
      'media_kit accepted the cookie-authorized source; URL and cookies remain redacted.',
    );
    return SecureMediaRestoreResult(isPlaying: player.state.playing);
  }

  Future<void> _pauseActivePlayer() async {
    await _player?.pause();
    _youtubeController?.pause();
  }

  void _showPlaybackError([String message = 'Video unavailable']) {
    if (!mounted || _isDisposed) return;

    setState(() {
      _loading = false;
      _hasPlaybackError = true;
      _playbackMessage = message;
    });
  }

  Future<void> _setupYoutubePlayer(String videoId) async {
    final token = ++_setupToken;

    final secureController = _securePlaybackController;
    if (secureController != null) {
      secureController.removeListener(_onSecurePlaybackChanged);
      await secureController.stop();
      secureController.dispose();
      _securePlaybackController = null;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _hasPlaybackError = false;
        _playbackMessage = null;
      });
    }

    _progressTimer?.cancel();
    await _disposePlayer(saveProgress: false);
    if (_isDisposed || !mounted || token != _setupToken) return;

    final provider = context.read<PlayMediaProvider>();
    final resumeSeconds = _isSeries
        ? provider.getLocalResume(
            contentId: widget.content!.id!,
            seasonId: widget.seasonIndex,
            episodeId: widget.episodeIndex,
          )
        : widget.content?.watchedSeconds ?? 0;

    final controller = youtube.YoutubePlayerController(
      initialVideoId: videoId,
      flags: youtube.YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: false,
        startAt: resumeSeconds > 5 ? resumeSeconds : 0,
      ),
    );

    controller.addListener(() {
      if (_isDisposed || !mounted || token != _setupToken) return;

      final value = controller.value;
      _handlePlayingChanged(value.isPlaying);

      if (value.hasError) {
        SecurityDebugLog.event(
          'PLAYER',
          'YouTube player reported a sanitized playback error.',
        );
        _showPlaybackError('Failed to load video');
      }

      if (value.playerState == youtube.PlayerState.ended) {
        _handlePlaybackCompleted();
      }

      setState(() {});
    });

    if (_isDisposed || !mounted || token != _setupToken) {
      controller.dispose();
      return;
    }

    _youtubeController = controller;
    SecurityDebugLog.event(
      'PLAYER',
      'YouTube player initialized without exposing the source URL.',
    );

    if (mounted && token == _setupToken) {
      setState(() => _loading = false);
    }

    _progressTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _saveProgress(),
    );
  }

  Future<void> _setupPlayer(
    String url, {
    bool playFromFile = false,
    bool diagnoseSignedHls = false,
    Map<String, String>? httpHeaders,
  }) async {
    final token = ++_setupToken;

    if (mounted) {
      setState(() {
        _loading = true;
        _hasPlaybackError = false;
        _playbackMessage = null;
      });
    }

    _progressTimer?.cancel();
    await _disposePlayer(saveProgress: false);
    if (_isDisposed || !mounted || token != _setupToken) return;

    await Future.delayed(const Duration(milliseconds: 250));
    if (_isDisposed || !mounted || token != _setupToken) return;

    if (kDebugMode && diagnoseSignedHls) {
      await _probeSignedHls(
        url,
        cookieHeader: httpHeaders?['Cookie'],
      );
      if (_isDisposed || !mounted || token != _setupToken) return;
    }

    final player = Player();
    final controller = VideoController(player);

    try {
      // media_kit is the underlying playback engine; the route keeps the
      // existing fullscreen, resume, continue-watching and auto-next behavior.
      await player.open(
        Media(
          playFromFile ? _localFileMediaUri(url) : url,
          httpHeaders: httpHeaders,
        ),
        play: false,
      );
      await player.setVolume(100);
    } catch (error, stackTrace) {
      SecurityDebugLog.exception(
        'MEDIA_KIT_OPEN',
        error,
        stackTrace,
      );
      SecurityDebugLog.event(
        'PLAYER',
        'media_kit initialization failed; sanitized details are in HTTP_DIAGNOSTIC.',
      );
      await player.dispose();
      if (mounted && token == _setupToken) {
        _showPlaybackError('Failed to load video');
      }
      return;
    }

    if (_isDisposed || !mounted || token != _setupToken) {
      await player.dispose();
      return;
    }

    _player = player;
    _videoController = controller;
    _bindPlayerStreams(player);
    SecurityDebugLog.event(
      'PLAYER',
      'media_kit open completed and player streams were attached.',
    );

    if (mounted && token == _setupToken) {
      setState(() => _loading = false);
    }

    await _resumeAndPlay(token);
  }

  Future<void> _probeSignedHls(
    String playbackUrl, {
    required String? cookieHeader,
  }) async {
    final uri = Uri.tryParse(playbackUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      SecurityDebugLog.event(
        'HLS_PROBE',
        'Signed media URL is not a valid HTTPS URL.',
      );
      return;
    }

    SecurityDebugLog.event(
      'HLS_PROBE',
      'Requesting the top-level HLS resource with redacted CloudFront cookies before media_kit opens it.',
    );
    if (cookieHeader == null || cookieHeader.isEmpty) {
      SecurityDebugLog.event(
        'HLS_PROBE',
        'CloudFront cookie header is missing; the protected request was not sent.',
      );
      return;
    }
    try {
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/vnd.apple.mpegurl, application/x-mpegURL, */*',
          'Range': 'bytes=0-65535',
          'Cookie': cookieHeader,
        },
      ).timeout(const Duration(seconds: 10));
      final contentType = response.headers['content-type'] ?? '<missing>';
      final cloudFrontResult = response.headers['x-cache'] ?? '<missing>';
      SecurityDebugLog.diagnostic(
        'HLS_PROBE_RESPONSE status=${response.statusCode} '
        'contentType=$contentType bytes=${response.bodyBytes.length} '
        'cloudFrontXCache=$cloudFrontResult',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final errorBody = utf8.decode(
          response.bodyBytes.take(2048).toList(growable: false),
          allowMalformed: true,
        );
        SecurityDebugLog.exception(
          'HLS_PROBE_HTTP_${response.statusCode}',
          errorBody.isEmpty ? 'CloudFront returned an empty error body.' : errorBody,
        );
        return;
      }

      final playlist = utf8.decode(response.bodyBytes, allowMalformed: true);
      final isHls = playlist.trimLeft().startsWith('#EXTM3U');
      final mediaUris = playlist
          .split(RegExp(r'\r?\n'))
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty && !line.startsWith('#'))
          .toList(growable: false);
      var relativeUris = 0;
      var absoluteUris = 0;
      for (final value in mediaUris) {
        final child = Uri.tryParse(value);
        if (child == null) continue;
        if (child.hasScheme) {
          absoluteUris++;
        } else {
          relativeUris++;
        }
      }
      SecurityDebugLog.diagnostic(
        'HLS_PLAYLIST_CHECK validM3u8=$isHls childUriCount=${mediaUris.length} '
        'relativeChildUris=$relativeUris absoluteChildUris=$absoluteUris '
        'cookieAuthorizationApplied=true',
      );
    } catch (error, stackTrace) {
      SecurityDebugLog.exception('HLS_PROBE_NETWORK', error, stackTrace);
    }
  }

  void _bindPlayerStreams(Player player) {
    _playerSubscriptions
      ..add(player.stream.playing.listen((isPlaying) {
        _handlePlayingChanged(isPlaying);
        if (mounted) setState(() {});
      }))
      ..add(player.stream.position.listen((_) => _handlePositionChanged()))
      ..add(player.stream.duration.listen((_) {
        final duration = player.state.duration;
        if (duration != _lastLoggedDuration) {
          _lastLoggedDuration = duration;
          SecurityDebugLog.event(
            'PLAYER',
            'Media duration updated to ${duration.inMilliseconds} ms.',
          );
        }
        if (mounted) setState(() {});
      }))
      ..add(player.stream.buffering.listen((isBuffering) {
        SecurityDebugLog.event(
          'PLAYER',
          'media_kit buffering=$isBuffering positionMs=${player.state.position.inMilliseconds}.',
        );
      }))
      ..add(player.stream.completed.listen((completed) {
        if (completed) {
          SecurityDebugLog.event('PLAYER', 'media_kit reported completion.');
          _handlePlaybackCompleted();
        }
      }))
      ..add(player.stream.error.listen((error) {
        SecurityDebugLog.exception('MEDIA_KIT_STREAM', error);
        final isForbidden = error.toString().contains('403');
        if (isForbidden && _securePlaybackController != null) {
          unawaited(_securePlaybackController!.handlePlayerHttp403());
          return;
        }
        if (mounted) {
          _showPlaybackError('Failed to load video');
        }
      }));
  }

  Future<void> _resumeAndPlay(int token) async {
    if (_player == null || !mounted) return;
    if (_isDisposed || token != _setupToken) return;

    final provider = context.read<PlayMediaProvider>();
    await _player!.setVolume(100);

    final resumeSeconds = _isSeries
        ? provider.getLocalResume(
            contentId: widget.content!.id!,
            seasonId: widget.seasonIndex,
            episodeId: widget.episodeIndex,
          )
        : widget.content?.watchedSeconds ?? 0;

    if (resumeSeconds > 5) {
      await _player!.seek(Duration(seconds: resumeSeconds));
    }

    SecurityDebugLog.event(
      'PLAYER',
      'Requesting media_kit play at positionMs=${_player!.state.position.inMilliseconds}.',
    );
    await _player!.play();
    SecurityDebugLog.event(
      'PLAYER',
      'media_kit play returned playing=${_player!.state.playing} buffering=${_player!.state.buffering}.',
    );
    if (_isDisposed || token != _setupToken) return;

    _progressTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _saveProgress(),
    );
  }

  void _handlePlayingChanged(bool isPlaying) {
    if (_isDisposed || !mounted) return;

    _securePlaybackController?.onPlayingChanged(isPlaying);

    if (isPlaying && !_wakelockEnabled) {
      WakelockPlus.enable();
      _wakelockEnabled = true;
    } else if (!isPlaying && _wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
  }

  void _handlePositionChanged() {
    if (_isDisposed || !mounted || _player == null || _handlingEnd) return;

    final state = _player!.state;

    if (state.playing &&
        (state.position - _lastSavedPosition).inSeconds >= 15) {
      _saveProgress();
    }

    if (!state.playing &&
        state.position > Duration.zero &&
        state.position != _lastSavedPosition) {
      _saveProgress();
    }

    if (mounted) setState(() {});
  }

  void _handlePlaybackCompleted() {
    unawaited(_securePlaybackController?.stop());
    if (_handlingEnd || !_isSeries) return;
    _handlingEnd = true;
    unawaited(_playNextEpisode());
  }

  void _saveProgress() {
    if (widget.content?.id == null) return;

    final position =
        _youtubeController?.value.position ?? _player?.state.position;
    final duration =
        _youtubeController?.value.metaData.duration ?? _player?.state.duration;

    if (position == null || duration == null) return;

    if (duration.inSeconds == 0) return;

    _lastSavedPosition = position;

    debugPrint(
      "SAVE PROGRESS => ${position.inSeconds}s / ${duration.inSeconds}s",
    );

    context.read<PlayMediaProvider>().saveLocalResume(
          contentId: widget.content!.id!,
          seasonId: _isSeries ? widget.seasonIndex : null,
          episodeId: _isSeries ? widget.episodeIndex : null,
          seconds: position.inSeconds,
        );

    context.read<PlayMediaProvider>().saveContinueWatching(
          contentId: widget.content!.id!,
          seasonId: _isSeries ? widget.seasonIndex : null,
          episodeId: _isSeries ? widget.episodeIndex : null,
          position: position,
          duration: duration,
        );
  }

  Future<void> _playNextEpisode() async {
    if (!_isSeries ||
        widget.seasons == null ||
        widget.seasonIndex == null ||
        widget.episodeIndex == null) {
      return;
    }

    final provider = context.read<PlayMediaProvider>();

    final next = provider.getNextEpisode(
      seasons: widget.seasons!,
      seasonId: widget.seasonIndex!,
      episodeId: widget.episodeIndex!,
    );

    if (next == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _handlingEnd = false;
    final nextUrl = next.videoUrl?.trim() ?? "";
    if (nextUrl.isEmpty) {
      _showPlaybackError('Video unavailable');
      return;
    }

    final youtubeId = _extractYoutubeId(nextUrl);
    if (youtubeId != null && youtubeId.isNotEmpty) {
      await _setupYoutubePlayer(youtubeId);
    } else {
      await _startSecurePlayback(
        sourceUrl: nextUrl,
        contentId: next.episodeId.toString(),
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _setupToken++;
    WidgetsBinding.instance.removeObserver(this);
    final secureController = _securePlaybackController;
    secureController?.removeListener(_onSecurePlaybackChanged);
    secureController?.dispose();
    _securePlaybackController = null;
    _disposePlayerSync(saveProgress: true);
    unawaited(_restorePortraitPlayback());
    super.dispose();
  }

  Future<void> _disposePlayer({bool saveProgress = true}) async {
    if (saveProgress) {
      _saveProgress();
    }
    _progressTimer?.cancel();
    _progressTimer = null;

    for (final subscription in _playerSubscriptions) {
      await subscription.cancel();
    }
    _playerSubscriptions.clear();

    final player = _player;
    final youtubeController = _youtubeController;
    _player = null;
    _videoController = null;
    _youtubeController = null;

    if (player != null) {
      try {
        await player.pause();
      } catch (_) {}
      try {
        await player.setVolume(0);
      } catch (_) {}
      await player.dispose();
    }

    youtubeController?.pause();
    youtubeController?.dispose();

    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
  }

  void _disposePlayerSync({bool saveProgress = true}) {
    if (saveProgress) {
      _saveProgress();
    }
    _progressTimer?.cancel();
    _progressTimer = null;

    for (final subscription in _playerSubscriptions) {
      unawaited(subscription.cancel());
    }
    _playerSubscriptions.clear();

    final player = _player;
    final youtubeController = _youtubeController;
    _player = null;
    _videoController = null;
    _youtubeController = null;

    if (player != null) {
      try {
        player.pause();
      } catch (_) {}
      try {
        player.setVolume(0);
      } catch (_) {}
      player.dispose();
    }

    youtubeController?.pause();
    youtubeController?.dispose();

    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
  }

  Future<void> _handleExit() async {
    if (_isExiting) return;
    _isExiting = true;
    await _securePlaybackController?.stop();
    await _disposePlayer(saveProgress: true);
    await _restorePortraitPlayback();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  KeyEventResult _handleRemoteKey(FocusNode node, KeyEvent event) {
    if (!ResponsiveWidget.isTabletOrTv(context) || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA) {
      _togglePlayback();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _seekBy(const Duration(seconds: 10));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _seekBy(const Duration(seconds: -10));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      unawaited(_handleExit());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _togglePlayback() {
    final youtubeController = _youtubeController;
    if (youtubeController != null) {
      if (youtubeController.value.isPlaying) {
        youtubeController.pause();
      } else {
        youtubeController.play();
      }
      return;
    }

    final player = _player;
    if (player != null) {
      unawaited(player.playOrPause());
    }
  }

  void _seekBy(Duration delta) {
    final youtubeController = _youtubeController;
    if (youtubeController != null) {
      final duration = youtubeController.value.metaData.duration;
      youtubeController.seekTo(
        boundedSeekPosition(
          position: youtubeController.value.position,
          duration: duration,
          offset: delta,
        ),
      );
      return;
    }

    final player = _player;
    if (player != null) {
      final duration = player.state.duration;
      unawaited(
        player.seek(
          boundedSeekPosition(
            position: player.state.position,
            duration: duration,
            offset: delta,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().getTheme;
    final secureState = _securePlaybackController?.state;
    final secureLoading =
        secureState == SecurePlaybackState.preparingSecurity ||
            secureState == SecurePlaybackState.requestingPlaybackAccess ||
            secureState == SecurePlaybackState.initializingPlayer ||
            secureState == SecurePlaybackState.refreshingUrl;
    final showLoading = _loading || secureLoading;
    final watermark = _securePlaybackController?.watermark;

    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: null,
        body: Focus(
          autofocus: ResponsiveWidget.isTabletOrTv(context),
          onKeyEvent: _handleRemoteKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: showLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.primaryColor,
                        ),
                      )
                    : _hasPlaybackError
                        ? _secureErrorView()
                        : ResponsiveWidget.isDesktop(context)
                            ? _desktopPlayer()
                            : _mobilePlayer(),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: SafeArea(child: _backButton()),
              ),
              if (!showLoading && !_hasPlaybackError)
                Positioned.fill(
                  child: Center(
                    child: VideoSkipControls(
                      onBackward: () => _seekBy(const Duration(seconds: -10)),
                      onForward: () => _seekBy(const Duration(seconds: 10)),
                      gap: ResponsiveWidget.isMobile(context) ? 82 : 120,
                    ),
                  ),
                ),
              if (!showLoading && !_hasPlaybackError)
                Positioned(
                  top: 12,
                  right: 12,
                  child: SafeArea(child: _downloadButton()),
                ),
              if (!showLoading && !_hasPlaybackError && watermark != null)
                Positioned.fill(
                  child: PlaybackWatermarkOverlay(
                    watermark: watermark,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secureErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white70, size: 42),
            const SizedBox(height: 12),
            Text(
              _playbackMessage ?? 'Video unavailable',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            if (_securePlaybackController != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => unawaited(_securePlaybackController!.start()),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _downloadButton() {
    final content = widget.content;
    final contentId = content?.id;
    final sourceUrl = _downloadSourceUrl(content);

    if (content == null ||
        contentId == null ||
        content.isDownloadable != true ||
        sourceUrl.isEmpty) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Colors.black.withValues(alpha: 0.48),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () async {
          final offlineProvider = context.read<OfflineDownloadProvider>();
          if (offlineProvider.isDownloading(contentId)) return;

          final result = offlineProvider.isDownloaded(contentId)
              ? <String, Object>{
                  'success': true,
                  'message': 'Movie is already downloaded.',
                }
              : await offlineProvider.downloadContent(
                  content,
                  sourceUrl: sourceUrl,
                );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message']?.toString() ?? 'Download updated',
              ),
              backgroundColor: result['success'] == true
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          );
        },
        child: const SizedBox(
          height: 40,
          width: 40,
          child: Icon(
            Icons.download_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  String _downloadSourceUrl(Content? content) {
    final currentUrl = _currentRemotePlaybackUrl?.trim() ?? '';
    if (_isRemoteHttpUrl(currentUrl)) return currentUrl;

    final widgetUrl = widget.videoUrl.trim();
    if (_isRemoteHttpUrl(widgetUrl)) return widgetUrl;

    final contentUrl = content?.contentUrl?.trim() ?? '';
    return _isRemoteHttpUrl(contentUrl) ? contentUrl : '';
  }

  bool _isRemoteHttpUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri?.scheme == 'https' || uri?.scheme == 'http';
  }

  Widget _backButton() {
    return Material(
      color: Colors.black.withValues(alpha: 0.45),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: _handleExit,
        child: const SizedBox(
          height: 36,
          width: 36,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _mobilePlayer() {
    return SizedBox.expand(
      child: _playerSurface(),
    );
  }

  Widget _desktopPlayer() {
    return SizedBox.expand(
      child: _playerSurface(),
    );
  }

  Widget _playerSurface() {
    final theme = Theme.of(context);

    if (_youtubeController != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          if (width <= 0 || height <= 0) return const SizedBox.expand();
          final aspectRatio = width / height;

          return SizedBox(
            width: width,
            height: height,
            child: youtube.YoutubePlayer(
              controller: _youtubeController!,
              width: width,
              aspectRatio: aspectRatio,
              showVideoProgressIndicator: true,
              progressIndicatorColor: theme.primaryColor,
            ),
          );
        },
      );
    }

    if (_player == null || _videoController == null) {
      if (_hasPlaybackError) {
        return Center(
          child: Text(
            _playbackMessage ?? 'Video unavailable',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        );
      }
      return Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) return const SizedBox.expand();

        return SizedBox(
          width: width,
          height: height,
          child: Video(
            controller: _videoController!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            fill: Colors.black,
          ),
        );
      },
    );
  }

  String _localFileMediaUri(String pathOrUri) {
    final uri = Uri.tryParse(pathOrUri);
    if (uri?.scheme == 'file') return pathOrUri;
    return File(pathOrUri).uri.toString();
  }
}
