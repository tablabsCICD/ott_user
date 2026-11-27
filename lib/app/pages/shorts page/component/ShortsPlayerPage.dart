import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ott/app/core/network/anti_piracy_api_client.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/services/invoice_service.dart';
import 'package:ott/app/core/services/session_manager.dart';
import 'package:ott/app/core/utils/security_debug_log.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/wallet%20page/WalletPage.dart';
import 'package:ott/app/core/constant/feature_flags.dart';
import 'package:ott/app/pages/shorts%20page/component/mini_series_commerce_sheets.dart';
import 'package:ott/app/provider/secure_playback_controller.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/widgets/content_share_sheet.dart';
import 'package:ott/app/widgets/playback_watermark_overlay.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/data/models/anti_piracy_models.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart' as native_video;

String _resolveShortPlaybackCountryCode() {
  final countryCode =
      WidgetsBinding.instance.platformDispatcher.locale.countryCode;
  final normalized = countryCode?.trim().toUpperCase();
  if (normalized != null && RegExp(r'^[A-Z]{2}$').hasMatch(normalized)) {
    return normalized;
  }
  return 'IN';
}

class ShortsPlayerPage extends StatefulWidget {
  final ShortDetailModel short;
  const ShortsPlayerPage({super.key, required this.short});

  @override
  State<ShortsPlayerPage> createState() => _ShortsPlayerPageState();
}

class _ShortsPlayerPageState extends State<ShortsPlayerPage>
    with WidgetsBindingObserver {
  // media_kit player: used on web/desktop, and as a fallback on mobile.
  Player? _controller;
  VideoController? _videoController;
  // Native (ExoPlayer / AVPlayer) player: preferred on Android and iOS, the
  // same as the movie player. media_kit on mobile falls back to software
  // rendering on emulators and does not reliably forward CloudFront cookies
  // to HLS child playlists/segments.
  native_video.VideoPlayerController? _nativeController;
  SecurePlaybackController? _securePlaybackController;
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];
  final PageController _pageController = PageController();

  List<ShortPart> _parts = [];
  int _currentIndex = 0;

  /// Parts already counted as viewed in this player session.
  final Set<int> _viewedPartIds = <int>{};

  /// Page the user is on (updates immediately on swipe; [_currentIndex] only
  /// changes once that part has loaded). Used for the header episode number.
  int _displayIndex = 0;

  /// Latest part requested while another part was still loading.
  int? _pendingIndex;

  /// Bumped for every episode load and whenever a newer swipe supersedes the
  /// one in flight; a load whose generation is no longer current is dropped
  /// before it can attach a player (no audio overlap, no wrong episode).
  int _loadGeneration = 0;

  /// Completes once the current episode's player is attached and playing, so
  /// navigation unlocks without waiting for watermark/view/detail requests.
  Completer<void>? _mediaReady;

  /// Debug-only timings of the episode currently loading.
  _EpisodeLoadTrace? _trace;

  /// Playback position, updated without rebuilding the page: only the
  /// progress bar listens to it.
  final ValueNotifier<Duration> _positionNotifier =
      ValueNotifier(Duration.zero);

  bool _controlsVisible = true;
  Timer? _hideControlsTimer;
  static const Duration _controlsAutoHide = Duration(seconds: 3);

  /// True while the episode sheet is open: controls stay visible and the
  /// auto-hide timer is held until it closes.
  bool _episodesSheetOpen = false;

  /// Audio mute (not microphone). Kept across episodes.
  bool _isMuted = false;
  bool _isBuffering = false;
  bool _resumeOnForeground = false;

  bool _isLoadingPart = false;
  bool _isMetaExpanded = false;
  bool _hasVideoError = false;
  String? _videoErrorMessage;
  bool _handlingSecureAuthenticationFailure = false;

  int get totalParts => _parts.length;

  /// Backend flag: the user owns the whole mini series through a claimed gift.
  bool _hasFullSeriesGiftAccess = false;

  /// A part plays without payment when it is a free preview, purchased, or
  /// covered by full-series gift access. All three come from the backend.
  bool _isPartAccessible(ShortPart part) =>
      part.isFreePreview || part.isPurchased || _hasFullSeriesGiftAccess;

  bool get _useNativePlayer =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _hasPlayer => _nativeController != null || _controller != null;

  bool get _isPlaying =>
      _nativeController?.value.isPlaying ?? _controller?.state.playing ?? false;

  Duration get _position =>
      _nativeController?.value.position ??
      _controller?.state.position ??
      Duration.zero;

  Duration get _duration =>
      _nativeController?.value.duration ??
      _controller?.state.duration ??
      Duration.zero;

  Future<void> _play() async {
    final native = _nativeController;
    if (native != null) return native.play();
    await _controller?.play();
  }

  Future<void> _pause() async {
    final native = _nativeController;
    if (native != null) return native.pause();
    await _controller?.pause();
  }

  Future<void> _seekTo(Duration position) async {
    final native = _nativeController;
    if (native != null) return native.seekTo(position);
    await _controller?.seek(position);
  }

  /// Stops and releases whichever player is currently active.
  Future<void> _disposeActivePlayer() async {
    final oldMediaKit = _controller;
    final oldNative = _nativeController;
    if (oldMediaKit == null && oldNative == null) return;
    final watch = Stopwatch()..start();
    _controller = null;
    _videoController = null;
    _nativeController = null;
    for (final subscription in _playerSubscriptions) {
      await subscription.cancel();
    }
    _playerSubscriptions.clear();
    oldNative?.removeListener(_onNativePlayerChanged);
    _positionNotifier.value = Duration.zero;
    _isBuffering = false;
    await oldNative?.pause();
    await oldNative?.dispose();
    await oldMediaKit?.pause();
    await oldMediaKit?.dispose();
    _EpisodeLoadTrace.log(
        'MINI_SERIES_EPISODE_DISPOSE',
        'player=${oldNative != null ? 'native' : 'media_kit'} '
            'released=${watch.elapsedMilliseconds}ms');
  }

  bool _lastNativePlaying = false;
  String _lastNativeError = '';

  void _onNativePlayerChanged() {
    final controller = _nativeController;
    if (controller == null) return;
    final value = controller.value;
    // Position ticks only move the progress bar (no full-page rebuild).
    _positionNotifier.value = value.position;
    final trace = _trace;
    if (trace != null && !trace.firstFrameLogged) {
      if (value.isBuffering != _isBuffering) {
        trace.bufferingChanged(value.isBuffering);
      }
      trace.maybeFirstFrame(playing: value.isPlaying, position: value.position);
    } else if (trace != null && value.isBuffering != _isBuffering) {
      trace.bufferingChanged(value.isBuffering);
    }
    var changed = false;
    if (value.isPlaying != _lastNativePlaying) {
      _lastNativePlaying = value.isPlaying;
      _securePlaybackController?.onPlayingChanged(value.isPlaying);
      _onPlayingStateChanged(value.isPlaying);
      changed = true;
    }
    if (value.isBuffering != _isBuffering) {
      _isBuffering = value.isBuffering;
      changed = true;
    }
    final error = value.errorDescription ?? '';
    if (value.hasError && error != _lastNativeError) {
      _lastNativeError = error;
      SecurityDebugLog.event('PLAYER', 'Mini Series native player error.');
      if (error.contains('403') && _securePlaybackController != null) {
        unawaited(_securePlaybackController!.handlePlayerHttp403());
      } else if (mounted) {
        _hasVideoError = true;
        _videoErrorMessage =
            AppLocalizations.of(context)!.playerFailedToLoadVideo;
      }
      changed = true;
    }
    if (changed && mounted) setState(() {});
  }

  /// Keeps controls in step with real playback: visible while paused,
  /// auto-hidden a few seconds after playback (re)starts.
  void _onPlayingStateChanged(bool isPlaying) {
    if (isPlaying) {
      _scheduleControlsHide();
    } else {
      _hideControlsTimer?.cancel();
      _controlsVisible = true;
    }
  }

  /// Single visibility rule for every player control (back, episodes,
  /// mute, play/pause): shown after a tap, always shown while paused or while
  /// the episode sheet is open.
  bool get _controlsShown =>
      _controlsVisible || !_isPlaying || _episodesSheetOpen;

  /// The one auto-hide timer. Each call replaces the previous timer, so
  /// rapid taps never stack timers.
  void _scheduleControlsHide() {
    _hideControlsTimer?.cancel();
    if (_episodesSheetOpen) return;
    _hideControlsTimer = Timer(_controlsAutoHide, () {
      if (mounted && _isPlaying && !_episodesSheetOpen && _controlsVisible) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  /// Shows the controls and restarts the inactivity timeout. Rebuilds only
  /// when visibility actually changes.
  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    if (_isPlaying) {
      _scheduleControlsHide();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  /// Screen tap: shows all controls and resets the timeout (no toggling, so
  /// rapid taps cannot make the controls flicker).
  void _onScreenTap() => _showControls();

  Future<void> _applyVolume() async {
    final native = _nativeController;
    if (native != null) {
      await native.setVolume(_isMuted ? 0 : 1);
      return;
    }
    await _controller?.setVolume(_isMuted ? 0 : 100);
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    unawaited(_applyVolume());
    _showControls();
  }

  int? _parsePartId(ShortPart part) => int.tryParse(part.partId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Wallet balance once per page (was requested on every rebuild).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<WalletProvider>().getBalance());
    });
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (!mounted) return;

    final watch = Stopwatch()..start();
    await context
        .read<ShortProvider>()
        .fetchShortDetail(widget.short.id, user?.id ?? 1);
    if (!mounted) return;

    final detail = context.read<ShortProvider>().shortDetail;
    _EpisodeLoadTrace.log(
        'MINI_SERIES_EPISODE_DETAILS_API',
        'seriesId=${widget.short.id} source=network reason=open '
            'parts=${detail?.parts.length ?? 0} duration=${watch.elapsedMilliseconds}ms');
    if (detail == null || detail.parts.isEmpty) return;

    setState(() {
      _parts = List.from(detail.parts);
      _hasFullSeriesGiftAccess = detail.hasFullSeriesGiftAccess;
    });

    await _loadPart(0, reason: 'open');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final secureController = _securePlaybackController;
    if (secureController != null) {
      secureController.removeListener(_onSecurePlaybackChanged);
      unawaited(secureController.stop());
      secureController.dispose();
    }
    _hideControlsTimer?.cancel();
    unawaited(_disposeActivePlayer());
    _pageController.dispose();
    _positionNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Remember whether to resume (inactive arrives before paused).
      _resumeOnForeground = _resumeOnForeground || _isPlaying;
      unawaited(_pause());
    } else if (state == AppLifecycleState.resumed) {
      final resume = _resumeOnForeground;
      _resumeOnForeground = false;
      if (resume && _hasPlayer && !_hasVideoError) unawaited(_play());
    }
  }

  Future<void> _refreshFromBackend() async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (!mounted) return;

    await context
        .read<ShortProvider>()
        .fetchShortDetail(widget.short.id, user?.id ?? 1);

    if (!mounted) return;

    final detail = context.read<ShortProvider>().shortDetail;
    if (detail == null) return;

    setState(() {
      _parts = List.from(detail.parts);
      _hasFullSeriesGiftAccess = detail.hasFullSeriesGiftAccess;
    });
  }

  Future<void> _handleShortPurchaseInvoice(ShortPart part) async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    if (!mounted || user == null) return;

    try {
      final invoice = await InvoiceService.instance.generatePurchaseInvoice(
        PurchaseInvoiceData(
          user: user,
          contentTitle: widget.short.title,
          contentType: 'MINI SERIES',
          amount: part.coins.toDouble(),
          purchaseDate: DateTime.now(),
          itemTitle: part.title,
          itemSubtitle: 'Part ${part.partNumber}',
          rentalDuration: "3", //widget.short.rentlDuration,
        ),
      );

      if (!mounted) return;
      await InvoiceService.instance.showShareOptions(context, invoice);
    } catch (error) {
      if (!mounted) return;
    }
  }

  /// Releases the secure session of the previous/abandoned episode. dispose()
  /// already sends the analytics STOP (best-effort), so it is not awaited:
  /// the next episode no longer waits for that round trip.
  void _releaseSecureController() {
    final old = _securePlaybackController;
    _securePlaybackController = null;
    if (old == null) return;
    old.removeListener(_onSecurePlaybackChanged);
    old.dispose();
  }

  Future<void> _loadPart(int index, {String reason = 'swipe'}) async {
    if (index < 0 || index >= _parts.length) return;
    if (_isLoadingPart) {
      // A part is loading: remember only the newest request and load it
      // right after, instead of ignoring the swipe. The in-flight load is
      // superseded: its secure session stops after its current network step
      // and its player (if one is initializing) is discarded, never shown.
      _pendingIndex = index;
      final inFlight = _trace;
      if (inFlight != null && !inFlight.finished) {
        _loadGeneration++;
        _releaseSecureController();
        _EpisodeLoadTrace.log('MINI_SERIES_EPISODE_LOAD_START',
            '${inFlight.ids} cancelled: superseded by index=$index');
        inFlight.finish('superseded');
      }
      return;
    }
    _isLoadingPart = true;
    final generation = ++_loadGeneration;
    bool stale() => !mounted || generation != _loadGeneration;
    final ready = Completer<void>();
    _mediaReady = ready;

    try {
      if (mounted) {
        setState(() {
          _hasVideoError = false;
          _videoErrorMessage = null;
        });
      }

      final part = _parts[index];
      final trace = _EpisodeLoadTrace(
        seriesId: widget.short.id,
        partId: part.partId,
        index: index,
        generation: generation,
        reason: reason,
      );
      _trace?.finish('replaced');
      _trace = trace;
      _EpisodeLoadTrace.log('MINI_SERIES_EPISODE_LOAD_START',
          '${trace.ids} reason=$reason accessible=${_isPartAccessible(part)}');
      // Episode metadata comes from the series detail already in memory.
      _EpisodeLoadTrace.log('MINI_SERIES_EPISODE_DETAILS_API',
          '${trace.ids} source=cache (no request)');

      _releaseSecureController();
      await _disposeActivePlayer();
      if (mounted) setState(() {});

      if (!_isPartAccessible(part)) {
        final partId = _parsePartId(part);
        if (partId == null) {
          if (mounted) {
            setState(() {
              _hasVideoError = true;
              _videoErrorMessage =
                  AppLocalizations.of(context)!.playerInvalidVideo;
            });
          }
          return;
        }

        final wallet = context.read<WalletProvider>();
        await wallet.getBalance();
        // The user already scrolled past this locked part: never show the
        // dialog or buy it.
        if (stale()) {
          trace.finish('superseded');
          return;
        }

        if (wallet.walletBalance < part.coins) {
          await _showInsufficientBalanceDialog();
          return;
        }

        final purchaseResult = await context
            .read<ShortProvider>()
            .purchaseShortPart(partId: partId);

        /*  if (purchaseResult != null &&
            purchaseResult['alreadyPurchased'] != true) {
          await _handleShortPurchaseInvoice(part);
        } */

        await _refreshFromBackend();
      }
      if (stale()) {
        trace.finish('superseded');
        return;
      }

      final updated = _parts[index];
      if (!_isPartAccessible(updated)) {
        trace.finish('locked');
        return;
      }

      if (updated.videoUrl.trim().isEmpty) {
        if (mounted) {
          setState(() {
            _hasVideoError = true;
            _videoErrorMessage =
                AppLocalizations.of(context)!.playerVideoUnavailable;
          });
        }
        trace.finish('no_video_url');
        return;
      }

      // A signed playback session is requested per episode, every time
      // (never reused or prefetched): entitlement, device and expiry checks
      // stay exactly as before.
      final secureController = SecurePlaybackController(
          contentId: updated.partId,
          originalPlaybackUrl: updated.videoUrl,
          country: _resolveShortPlaybackCountryCode(),
          mediaLoader: (authorization, {required isRefresh}) =>
              _loadSecureMedia(authorization,
                  isRefresh: isRefresh, generation: generation),
          pausePlayer: _pause,
          type: "SHORT_PART");
      _securePlaybackController = secureController;
      secureController.addListener(_onSecurePlaybackChanged);
      trace.playbackUrlRequestedAt = trace.watch.elapsed;
      final started = secureController.start();
      // Unlock navigation as soon as the player is attached; the watermark
      // request inside start() keeps running in the background.
      await Future.any([started, ready.future]);

      if (stale()) {
        trace.finish('superseded');
        return;
      }
      if (secureController.state == SecurePlaybackState.accessDenied ||
          secureController.state == SecurePlaybackState.playbackError) {
        trace.finish('error:${secureController.state.name}');
        return;
      }

      _EpisodeLoadTrace.log('MINI_SERIES_EPISODE_READY',
          '${trace.ids} playerAttached=${trace.ms}ms');
      setState(() {
        _currentIndex = index;
        _hasVideoError = false;
        _videoErrorMessage = null;
      });

      // View count + detail refresh no longer block the next swipe.
      unawaited(_recordViewAndRefresh(updated));
    } finally {
      _isLoadingPart = false;
      final trace = _trace;
      if (trace != null &&
          trace.generation == generation &&
          !ready.isCompleted) {
        trace.finish('stopped'); // early return (locked, dialog, error)
      }
      final superseded = generation != _loadGeneration;
      final next = _pendingIndex;
      _pendingIndex = null;
      // A superseded load must be redone even for the same index (swipe away
      // and straight back while it was loading).
      if (mounted && next != null && (next != index || superseded)) {
        unawaited(_loadPart(next, reason: 'queued'));
      }
    }
  }

  /// Counts a view once per part per player session (like a Movie: once per
  /// open), then refreshes the series detail so counts stay current. Runs in
  /// the background; revisiting an already counted part makes no requests.
  Future<void> _recordViewAndRefresh(ShortPart part) async {
    final partId = _parsePartId(part);
    if (partId == null || !_viewedPartIds.add(partId)) return;
    final ok = await context
        .read<ShortProvider>()
        .addShortView(partId: partId)
        .timeout(const Duration(seconds: 8), onTimeout: () => false);
    if (!mounted) return;
    final watch = Stopwatch()..start();
    await _refreshFromBackend();
    _EpisodeLoadTrace.log(
        'MINI_SERIES_EPISODE_DETAILS_API',
        'seriesId=${widget.short.id} partId=${part.partId} source=network '
            'reason=view_refresh viewOk=$ok duration=${watch.elapsedMilliseconds}ms');
  }

  void _onSecurePlaybackChanged() {
    if (!mounted) return;
    final controller = _securePlaybackController;
    if (controller == null) return;
    if (controller.failure == SecurePlaybackFailure.unauthenticated &&
        !_handlingSecureAuthenticationFailure) {
      _handlingSecureAuthenticationFailure = true;
      unawaited(SessionManager.instance.handleSessionExpired(
        AppLocalizations.of(context)!.playerSessionExpired,
      ));
    }
    setState(() {
      _hasVideoError = controller.state == SecurePlaybackState.accessDenied ||
          controller.state == SecurePlaybackState.playbackError;
      _videoErrorMessage = controller.errorMessage;
    });
  }

  /// Marks the episode's player as attached (unlocks navigation).
  void _markMediaReady(int generation) {
    final ready = _mediaReady;
    if (generation == _loadGeneration && ready != null && !ready.isCompleted) {
      ready.complete();
    }
  }

  Future<SecureMediaRestoreResult> _loadSecureMedia(
    SignedPlaybackResponse authorization, {
    required bool isRefresh,
    required int generation,
  }) async {
    // A newer swipe superseded this episode: attach nothing.
    if (generation != _loadGeneration || !mounted) {
      return SecureMediaRestoreResult(isPlaying: false);
    }
    final trace = _trace;
    if (!isRefresh && trace != null && trace.generation == generation) {
      final requestedAt = trace.playbackUrlRequestedAt?.inMilliseconds ?? 0;
      // Includes device registration (cached), integrity check and the
      // POST /anti-piracy/playback/signed-url round trip.
      _EpisodeLoadTrace.log(
          'MINI_SERIES_PLAYBACK_URL',
          '${trace.ids} source=network duration=${trace.ms - requestedAt}ms '
              'headers=${authorization.httpHeaders.length}');
    } else if (isRefresh) {
      _EpisodeLoadTrace.log('MINI_SERIES_PLAYBACK_URL',
          'partId=${trace?.partId} refresh (expiry or HTTP 403)');
    }
    final hadPlayer = _hasPlayer;
    final position = _position;
    final wasPlaying = hadPlayer ? _isPlaying : true;
    final volume = _controller?.state.volume ?? 100;
    final rate =
        _controller?.state.rate ?? _nativeController?.value.playbackSpeed ?? 1;

    if (authorization.audioTracks.length > 1 ||
        authorization.subtitleTracks.length > 1) {
      SecurityDebugLog.event(
        'PLAYER',
        'Multiple supported external tracks were returned for the selected part; only one automatic track will be attached.',
      );
    }

    await _disposeActivePlayer();

    if (_useNativePlayer) {
      final nativeResult = await _loadNativeMedia(
        authorization,
        isRefresh: isRefresh,
        position: position,
        wasPlaying: wasPlaying,
        rate: rate,
        generation: generation,
      );
      if (nativeResult != null) return nativeResult;
      // Native initialization failed: fall through to media_kit.
      if (generation != _loadGeneration || !mounted) {
        return SecureMediaRestoreResult(isPlaying: false);
      }
    }
    final mediaKitWatch = Stopwatch()..start();

    final player = Player(
      configuration: const PlayerConfiguration(
        protocolWhitelist: [
          'udp',
          'rtp',
          'tcp',
          'tls',
          'data',
          'file',
          'http',
          'https',
          'crypto',
        ],
      ),
    );
    final videoController = VideoController(player);
    // Media.httpHeaders alone is not always applied to HLS child playlists
    // and segments, so also set libmpv's header option (same as the movie
    // player). Without it, CloudFront signed-cookie segments return 403.
    if (!kIsWeb && authorization.httpHeaders.isNotEmpty) {
      try {
        await (player.platform as dynamic).setProperty(
          'http-header-fields',
          authorization.httpHeaders.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join('\n'),
        );
      } catch (_) {
        SecurityDebugLog.event(
          'PLAYER',
          'Native header configuration skipped for platform compatibility.',
        );
      }
    }
    _playerSubscriptions
      ..add(player.stream.position.listen((position) {
        _positionNotifier.value = position;
        final trace = _trace;
        if (trace != null && trace.generation == generation) {
          trace.maybeFirstFrame(
              playing: player.state.playing, position: position);
        }
      }))
      ..add(player.stream.duration.listen((_) {
        if (mounted) setState(() {});
      }))
      ..add(player.stream.buffering.listen((buffering) {
        final trace = _trace;
        if (trace != null &&
            trace.generation == generation &&
            buffering != _isBuffering) {
          trace.bufferingChanged(buffering);
        }
        if (mounted && buffering != _isBuffering) {
          setState(() => _isBuffering = buffering);
        }
      }))
      ..add(player.stream.playing.listen((isPlaying) {
        _securePlaybackController?.onPlayingChanged(isPlaying);
        _onPlayingStateChanged(isPlaying);
        if (mounted) setState(() {});
      }))
      ..add(player.stream.error.listen((error) {
        if (mounted) {
          setState(() {
            _hasVideoError = true;
            _videoErrorMessage =
                AppLocalizations.of(context)!.playerFailedToLoadVideo;
          });
        }
      }));

    try {
      await player.open(
        Media(
          authorization.urlToPlay,
          httpHeaders: authorization.httpHeaders,
        ),
        play: true,
      );
      final automaticAudio = getAutomaticAudioTrack(authorization.audioTracks);
      if (automaticAudio != null) {
        try {
          await player.setAudioTrack(
            AudioTrack.uri(
              automaticAudio.url,
              title: automaticAudio.label,
              language: automaticAudio.language,
            ),
          );
        } catch (_) {
          SecurityDebugLog.event(
            'PLAYER',
            'Automatic external part audio is unsupported; using manifest audio.',
          );
        }
      }
      final automaticSubtitle =
          getAutomaticSubtitleTrack(authorization.subtitleTracks);
      if (automaticSubtitle != null) {
        try {
          await player.setSubtitleTrack(
            SubtitleTrack.uri(
              automaticSubtitle.url,
              title: automaticSubtitle.label,
              language: automaticSubtitle.language,
            ),
          );
        } catch (_) {
          SecurityDebugLog.event(
            'PLAYER',
            'Automatic external part subtitle is unsupported; continuing playback.',
          );
        }
      }
      // Keep the user's mute choice across episodes and signed-URL refreshes.
      await player.setVolume(_isMuted ? 0 : volume.clamp(1, 100).toDouble());
      if (isRefresh) {
        if (position > Duration.zero) await player.seek(position);
        await player.setRate(rate);
        if (!wasPlaying) await player.pause();
      }
    } catch (_) {
      await player.dispose();
      rethrow;
    }

    if (!mounted) {
      await player.dispose();
      throw StateError('Mini Series player was disposed');
    }
    if (generation != _loadGeneration) {
      // Superseded while opening: never attach (no audio overlap).
      for (final subscription in _playerSubscriptions) {
        await subscription.cancel();
      }
      _playerSubscriptions.clear();
      await player.dispose();
      return SecureMediaRestoreResult(isPlaying: false);
    }
    final initTrace = _trace;
    if (!isRefresh && initTrace != null && initTrace.generation == generation) {
      initTrace.playRequestedAt ??= initTrace.watch.elapsed;
      _EpisodeLoadTrace.log('MINI_SERIES_CONTROLLER_INIT',
          '${initTrace.ids} player=media_kit open=${mediaKitWatch.elapsedMilliseconds}ms');
    }
    setState(() {
      _controller = player;
      _videoController = videoController;
      _hasVideoError = false;
      _videoErrorMessage = null;
    });
    if (!isRefresh) _markMediaReady(generation);
    return SecureMediaRestoreResult(isPlaying: player.state.playing);
  }

  /// Opens the signed part with the platform's native player. Returns null if
  /// initialization fails so the caller can fall back to media_kit.
  Future<SecureMediaRestoreResult?> _loadNativeMedia(
    SignedPlaybackResponse authorization, {
    required bool isRefresh,
    required Duration position,
    required bool wasPlaying,
    required double rate,
    required int generation,
  }) async {
    final initWatch = Stopwatch()..start();
    final controller = native_video.VideoPlayerController.networkUrl(
      Uri.parse(authorization.urlToPlay),
      httpHeaders: Map<String, String>.unmodifiable(authorization.httpHeaders),
      videoPlayerOptions: native_video.VideoPlayerOptions(mixWithOthers: false),
    );
    try {
      await controller.initialize();
    } catch (_) {
      SecurityDebugLog.event(
        'PLAYER',
        'Mini Series native player failed to initialize; falling back to media_kit.',
      );
      await controller.dispose();
      if (!mounted) throw StateError('Mini Series player was disposed');
      _EpisodeLoadTrace.log(
          'MINI_SERIES_CONTROLLER_INIT',
          'partId=${_trace?.partId} player=native failed after '
              '${initWatch.elapsedMilliseconds}ms; falling back to media_kit');
      return null;
    }

    if (!mounted) {
      await controller.dispose();
      throw StateError('Mini Series player was disposed');
    }
    if (generation != _loadGeneration) {
      // Superseded while initializing: discard, never attach or play.
      await controller.dispose();
      _EpisodeLoadTrace.log('MINI_SERIES_EPISODE_DISPOSE',
          'gen=$generation stale native player discarded after init');
      return SecureMediaRestoreResult(isPlaying: false);
    }
    final initTrace = _trace;
    if (!isRefresh && initTrace != null && initTrace.generation == generation) {
      // initialize() covers the HLS master/media playlists and the first
      // segment needed to report duration and size.
      _EpisodeLoadTrace.log('MINI_SERIES_CONTROLLER_INIT',
          '${initTrace.ids} player=native initialize=${initWatch.elapsedMilliseconds}ms');
    }

    await controller.setLooping(false);
    // Keep the user's mute choice across episodes and signed-URL refreshes.
    await controller.setVolume(_isMuted ? 0 : 1);
    if (isRefresh) {
      if (position > Duration.zero) await controller.seekTo(position);
      await controller.setPlaybackSpeed(rate);
    }

    _lastNativePlaying = false;
    _lastNativeError = '';
    controller.addListener(_onNativePlayerChanged);
    setState(() {
      _nativeController = controller;
      _hasVideoError = false;
      _videoErrorMessage = null;
    });

    if (!isRefresh && initTrace != null && initTrace.generation == generation) {
      initTrace.playRequestedAt = initTrace.watch.elapsed;
    }
    if (!isRefresh || wasPlaying) await controller.play();
    if (!isRefresh) _markMediaReady(generation);
    return SecureMediaRestoreResult(isPlaying: controller.value.isPlaying);
  }

  Future<void> _changePage(int index) async {
    setState(() {
      _isMetaExpanded = false;
      _displayIndex = index;
      _controlsVisible = true;
    });
    // Restart the shared timeout; it only hides once the episode plays.
    _scheduleControlsHide();
    await _loadPart(index);
  }

  Future<void> _showInsufficientBalanceDialog() async {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(lang.shortsInsufficientBalance,
            style: TextStyle(
                color: theme.primaryColor, fontWeight: FontWeight.bold)),
        content: Text(lang.shortsNotEnoughCoins,
            style: TextStyle(color: theme.canvasColor)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child:
                Text(lang.cancel, style: TextStyle(color: theme.canvasColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => WalletPage()));
            },
            child: Text(lang.recharge),
          ),
        ],
      ),
    );
  }

  /// Height reserved above the system inset for the progress bar
  /// (see [_bottomEpisodeBar]). The episode selector is in the top bar.
  static const double _bottomBarHeight = 28;
  static const double _bottomBarGap = 12;

  /// Real bottom system inset: Android 3-button/gesture bar or iOS home
  /// indicator. viewPadding is used (not padding) so it is never zeroed by
  /// an ancestor SafeArea.
  double get _bottomInset => MediaQuery.viewPaddingOf(context).bottom;

  /// Distance from the screen bottom to the top of the bottom bar.
  double get _bottomBarTop => _bottomInset + _bottomBarGap + _bottomBarHeight;

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final shortsScrollDirection =
        orientation == Orientation.landscape ? Axis.horizontal : Axis.vertical;
    final isLandscape = orientation == Orientation.landscape;
    final useFullWidthPlayer =
        isLandscape || ResponsiveWidget.isMobile(context);
    final watermark = _securePlaybackController?.watermark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: SizedBox(
          width: useFullWidthPlayer ? double.infinity : 450,
          child: Stack(
            children: [
              // Every Stack slot below keeps the same widget type and key
              // across episode loads. Previously the video slot switched
              // Positioned -> ShimmerLoader and the watermark slot vanished
              // in the same frame, so Flutter recreated the PageView and it
              // silently jumped back to episode 1 (wrong title/likes shown,
              // and the next swipe reloaded episode 2).
              KeyedSubtree(
                key: const ValueKey('mini-series-video'),
                child: _videoBackground(),
              ),
              GestureDetector(
                key: const ValueKey('mini-series-pages'),
                behavior: HitTestBehavior.translucent,
                // Tap shows/hides the controls; play/pause has its own button.
                onTap: _onScreenTap,
                onDoubleTap: _handleDoubleTapLike,
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: shortsScrollDirection,
                  itemCount: totalParts,
                  onPageChanged: _changePage,
                  itemBuilder: (_, i) => _overlay(i),
                ),
              ),
              _playbackControls(),
              KeyedSubtree(
                key: const ValueKey('mini-series-watermark'),
                child: watermark != null
                    ? PlaybackWatermarkOverlay(watermark: watermark)
                    : const SizedBox.shrink(),
              ),
              _topBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _videoBackground() {
    final controller = _controller;
    final videoController = _videoController;
    if (_hasVideoError) {
      return Positioned.fill(
        child: Container(
          color: Colors.black,
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_disabled, color: Colors.white70, size: 32),
              const SizedBox(height: 8),
              Text(
                _videoErrorMessage ??
                    AppLocalizations.of(context)!.playerVideoUnavailable,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }
    final videoFit = MediaQuery.of(context).orientation == Orientation.landscape
        ? BoxFit.contain
        : BoxFit.cover;

    final native = _nativeController;
    if (native != null && native.value.isInitialized) {
      final size = native.value.size;
      return Positioned.fill(
        child: ColoredBox(
          color: Colors.black,
          child: FittedBox(
            fit: videoFit,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: size.width > 0 ? size.width : 1,
              height: size.height > 0 ? size.height : 1,
              child: native_video.VideoPlayer(native),
            ),
          ),
        ),
      );
    }

    if (controller == null || videoController == null) {
      return const Positioned.fill(
        child: ShimmerLoader(
          height: double.infinity,
          width: double.infinity,
        ),
      );
    }

    return Positioned.fill(
      child: Video(
        controller: videoController,
        fit: videoFit,
        controls: null,
      ),
    );
  }

  Widget _overlay(int index) {
    final part = _parts[index];
    final theme = Theme.of(context);
    final titleText = part.title.trim().isNotEmpty
        ? part.title.trim()
        : widget.short.title.trim();
    final descriptionText = widget.short.description.trim();
    final hasDescription = descriptionText.isNotEmpty;
    final showSeeMore =
        !_isMetaExpanded && (titleText.length > 36 || hasDescription);
    return Stack(
      children: [
        Positioned(
          left: 16,
          // Sits just above the bottom bar, which follows the system inset.
          bottom: _bottomBarTop + 4,
          right: 130,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    height: 34,
                    width: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white30, width: 1),
                      color: Colors.white10,
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(100),
                        child: Image.network(
                          part.thumbnail,
                          fit: BoxFit.cover,
                        )),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    widget.short.creatorName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                      shadows: [
                        Shadow(
                          offset: Offset(2, 2), // x, y
                          blurRadius: 4,
                          color: Colors.black.withOpacity(0.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isMetaExpanded = !_isMetaExpanded;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        maxLines: _isMetaExpanded ? 3 : 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                          shadows: [
                            Shadow(
                              offset: Offset(2, 2), // x, y
                              blurRadius: 4,
                              color: Colors.black.withOpacity(0.2),
                            ),
                          ],
                        ),
                      ),
                      if (_isMetaExpanded && hasDescription) ...[
                        const SizedBox(height: 3),
                        Text(
                          descriptionText,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.35,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2), // x, y
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (showSeeMore) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.shortsSeeMore,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2, 2), // x, y
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.expand_more,
                              size: 12,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2), // x, y
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                      if (_isMetaExpanded) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.shortsSeeLess,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    offset: Offset(2, 2), // x, y
                                    blurRadius: 4,
                                    color: Colors.black.withOpacity(0.2),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.expand_more,
                              size: 12,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  offset: Offset(2, 2), // x, y
                                  blurRadius: 4,
                                  color: Colors.black.withOpacity(0.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        _rightButtons(index),
        _bottomEpisodeBar(),
      ],
    );
  }

  /// Centre play/pause (and a buffering spinner). Shown with the controls;
  /// always shown while paused. Tapping it updates playback immediately.
  Widget _playbackControls() {
    if (!_hasPlayer || _hasVideoError) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final playing = _isPlaying;
    final visible = _controlsShown;
    return Positioned.fill(
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isBuffering && playing)
            const IgnorePointer(
              child: SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                    color: Colors.white70, strokeWidth: 3),
              ),
            ),
          IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: Colors.black.withValues(alpha: 0.45),
                shape: CircleBorder(
                  side: BorderSide(
                      color: theme.primaryColor.withValues(alpha: 0.9),
                      width: 2),
                ),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    _togglePlayPause();
                    _showControls();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Icon(
                      playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 44,
                      semanticLabel: playing
                          ? AppLocalizations.of(context)!.playerPause
                          : AppLocalizations.of(context)!.playerPlay,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rightButtons(int index) {
    final part = _parts[index];
    final provider = context.watch<ShortProvider>();

    return Positioned(
      right: 12,
      bottom: _bottomBarTop + 24,
      child: Column(
        children: [
          _actionBtn(
            part.isLiked ? Icons.favorite : Icons.favorite_border,
            "${part.likes}",
            provider.isLiking
                ? null
                : () async {
                    final partId = _parsePartId(part);
                    if (partId == null) return;
                    final ok = part.isLiked
                        ? await context
                            .read<ShortProvider>()
                            .unlikeShortPart(partId: partId)
                        : await context
                            .read<ShortProvider>()
                            .likeShortPart(partId: partId);

                    if (ok) await _refreshFromBackend();
                  },
            isActive: part.isLiked,
          ),
          const SizedBox(height: 18),
          _actionBtn(Icons.telegram_outlined,
              AppLocalizations.of(context)!.shortsShareAction, () {
            _shareShortContent(context);
          }),
          if (FeatureFlags.miniSeriesCommerce) ...[
            const SizedBox(height: 18),
            _actionBtn(
              Icons.lock_open_rounded,
              AppLocalizations.of(context)!.miniSeriesBuyAllAction,
              _openFullPurchaseSheet,
            ),
            // Mini Series gifting is not part of the iOS app (final_iOS):
            // only the one-time full purchase is offered here.
          ],
          //const SizedBox(height: 18),
          // _actionBtn(Icons.visibility_outlined, "${part.views}", null),
        ],
      ),
    );
  }

  Future<void> _openFullPurchaseSheet() async {
    final wasPlaying = _isPlaying;
    await _pause();
    if (!mounted) return;
    final purchased = await showMiniSeriesFullPurchaseSheet(
      context,
      shortId: widget.short.id,
      title: widget.short.title,
    );
    if (!mounted) return;
    if (purchased) {
      // Ownership comes from the backend: reload parts so purchased parts
      // play without asking for payment.
      await _refreshFromBackend();
      if (!mounted) return;
      if (!_hasPlayer && !_isLoadingPart) {
        await _loadPart(_currentIndex, reason: 'full_purchase');
        return;
      }
    }
    if (wasPlaying) await _play();
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    VoidCallback? onTap, {
    bool isActive = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Colors.black12),
            child: Icon(icon,
                size: 26, color: isActive ? theme.primaryColor : Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              shadows: [
                Shadow(
                  offset: Offset(2, 2), // x, y
                  blurRadius: 4,
                  color: Colors.black.withOpacity(0.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareShortContent(BuildContext context) {
    return showContentShareSheet(
      context,
      widget.short.toShareContent(),
      contentType: DeepLinkContentType.short,
      unavailableMessage:
          AppLocalizations.of(context)!.shortsMiniSeriesDetailsUnavailable,
    );
  }

  void _shareShort(BuildContext context, ShortPart short) async {
    final String shareText = '''
🎬 ${short.title ?? ''}

${short.durationSec ?? ''}

▶️ Watch here:
** filmytell navigation link **

📲 Download Filmytell App now!
'''
        .trim();

    if (kIsWeb) {
      // Flutter Web fallback → Copy to Clipboard
      await Clipboard.setData(ClipboardData(text: shareText));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.shortsShareTextCopied),
        ),
      );
    } else {
      // Android / iOS / Desktop
      await Share.share(
        shareText,
        subject: short.title ?? "Movie",
      );
    }
  }

  /// Progress bar, placed above the real bottom system inset (navigation
  /// buttons, gesture bar or iOS home indicator).
  Widget _bottomEpisodeBar() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: _bottomInset + _bottomBarGap,
      child: SizedBox(
        height: _bottomBarHeight,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _videoProgressBar(),
          ],
        ),
      ),
    );
  }

  /// Episodes selector merged with the episode count: `Episodes ▼  1/11`.
  /// Same box as before; opens the existing episode sheet.
  Widget _episodesSelector() {
    final lang = AppLocalizations.of(context)!;
    final current = _displayIndex.clamp(0, totalParts - 1) + 1;
    return InkWell(
      onTap: () => unawaited(_openEpisodes()),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_library_outlined,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                lang.shortsEpisodesLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.expand_more, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              '$current/$totalParts',
              maxLines: 1,
              softWrap: false,
              semanticsLabel: lang.shortsEpisodeOfTotal(current, totalParts),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rebuilds on its own from [_positionNotifier]; the page does not rebuild
  /// on every position tick.
  Widget _videoProgressBar() {
    if (!_hasPlayer) return const SizedBox(height: 20);
    final theme = Theme.of(context);
    return SizedBox(
      height: 20,
      child: ValueListenableBuilder<Duration>(
        valueListenable: _positionNotifier,
        builder: (context, position, _) {
          final duration = _duration.inMilliseconds;
          if (duration <= 0) return const SizedBox.shrink();
          return SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
            ),
            child: Slider(
              min: 0,
              max: duration.toDouble(),
              value: position.inMilliseconds.clamp(0, duration).toDouble(),
              activeColor: theme.primaryColor,
              inactiveColor: Colors.white24,
              onChanged: (value) {
                final target = Duration(milliseconds: value.round());
                _positionNotifier.value = target;
                unawaited(_seekTo(target));
                if (_controlsVisible) _showControls();
              },
            ),
          );
        },
      ),
    );
  }

  void _togglePlayPause() {
    if (!_hasPlayer) return;
    unawaited(_isPlaying ? _pause() : _play());
  }

  Future<void> _handleDoubleTapLike() async {
    if (!_hasPlayer || _parts.isEmpty) {
      return;
    }

    if (_currentIndex < 0 || _currentIndex >= _parts.length) return;
    final part = _parts[_currentIndex];
    final partId = _parsePartId(part);
    if (partId == null) return;
    final provider = context.read<ShortProvider>();
    if (provider.isLiking || part.isLiked) return;

    HapticFeedback.lightImpact();
    final ok = await provider.likeShortPart(partId: partId);

    if (ok) await _refreshFromBackend();
  }

  Future<void> _openEpisodes() async {
    final theme = Theme.of(context);
    // Hold the controls while the sheet is open.
    _hideControlsTimer?.cancel();
    setState(() {
      _episodesSheetOpen = true;
      _controlsVisible = true;
    });
    await showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: GridView.builder(
            itemCount: totalParts,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) {
              final part = _parts[i];
              final active = i == _currentIndex;

              return GestureDetector(
                onTap: () async {
                  Navigator.pop(context);
                  _pageController.jumpToPage(i);
                  await _loadPart(i, reason: 'episode_list');
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: active ? theme.primaryColor : theme.cardColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: theme.canvasColor.withOpacity(.7)),
                      ),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context)!
                              .shortsEpisodeShort(part.partNumber),
                          style: TextStyle(
                            color: active ? Colors.white : theme.canvasColor,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(2, 2), // x, y
                                blurRadius: 4,
                                color: Colors.black.withOpacity(0.2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (!_isPartAccessible(part))
                      const Positioned(
                          right: 4, top: 4, child: Icon(Icons.lock, size: 14)),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
    if (!mounted) return;
    // Sheet closed (dismissed or episode chosen): resume normal auto-hide.
    setState(() => _episodesSheetOpen = false);
    _showControls();
  }

  /// One row: [Back] [Episodes ▼ N/total] [Mute]. Back and mute keep their
  /// fixed size (full touch targets). Shown and hidden together with the
  /// play/pause button ([_controlsShown], same fade). Placed below the real
  /// top inset (status bar / notch).
  Widget _topBar() {
    final lang = AppLocalizations.of(context)!;
    final narrow = MediaQuery.sizeOf(context).width < 360;
    final gap = narrow ? 6.0 : 8.0;
    final visible = _controlsShown;
    return Positioned(
      top: MediaQuery.viewPaddingOf(context).top + 8,
      left: narrow ? 8 : 12,
      right: narrow ? 8 : 12,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 200),
          child: Row(
            children: [
              _circleButton(
                icon: Icons.arrow_back_ios_new,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onTap: () {
                  unawaited(_pause());
                  Navigator.pop(context);
                },
              ),
              SizedBox(width: gap),
              Expanded(
                child: totalParts > 0
                    ? Align(
                        alignment: Alignment.centerLeft,
                        child: _episodesSelector(),
                      )
                    : const SizedBox.shrink(),
              ),
              if (_hasPlayer) ...[
                SizedBox(width: gap),
                _circleButton(
                  icon: _isMuted
                      ? Icons.volume_off_rounded
                      : Icons.volume_up_rounded,
                  tooltip:
                      _isMuted ? lang.playerUnmuteSound : lang.playerMuteSound,
                  onTap: _toggleMute,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.black45,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Debug-only timing of one Mini Series episode load. Logs IDs and elapsed
/// milliseconds only: never URLs, tokens, cookies or user data.
class _EpisodeLoadTrace {
  _EpisodeLoadTrace({
    required this.seriesId,
    required this.partId,
    required this.index,
    required this.generation,
    required this.reason,
  });

  final int seriesId;
  final String partId;
  final int index;
  final int generation;
  final String reason;
  final Stopwatch watch = Stopwatch()..start();

  Duration? playbackUrlRequestedAt;
  Duration? playRequestedAt;
  Duration? _bufferingSince;
  Duration _bufferingBeforeFirstFrame = Duration.zero;
  bool firstFrameLogged = false;
  bool finished = false;

  int get ms => watch.elapsedMilliseconds;
  String get ids =>
      'seriesId=$seriesId partId=$partId index=$index gen=$generation';

  static void log(String tag, String message) {
    if (kDebugMode) debugPrint('[$tag] $message');
  }

  void bufferingChanged(bool buffering) {
    final now = watch.elapsed;
    if (buffering) {
      _bufferingSince ??= now;
      return;
    }
    final since = _bufferingSince;
    if (since == null) return;
    _bufferingSince = null;
    final spent = now - since;
    if (!firstFrameLogged) {
      _bufferingBeforeFirstFrame += spent;
    } else {
      log('MINI_SERIES_HLS_BUFFERING',
          '$ids rebuffer=${spent.inMilliseconds}ms at=${now.inMilliseconds}ms');
    }
  }

  /// Called with the latest playing position; the first advancing position
  /// while playing is the first rendered frame (video_player exposes no
  /// first-frame callback, so this is the closest observable signal).
  void maybeFirstFrame({required bool playing, required Duration position}) {
    if (firstFrameLogged || !playing || position <= Duration.zero) return;
    firstFrameLogged = true;
    if (_bufferingSince != null) bufferingChanged(false);
    final sincePlay = playRequestedAt == null
        ? 'n/a'
        : '${ms - playRequestedAt!.inMilliseconds}ms';
    log('MINI_SERIES_HLS_BUFFERING',
        '$ids startupBuffering=${_bufferingBeforeFirstFrame.inMilliseconds}ms');
    log('MINI_SERIES_FIRST_FRAME',
        '$ids sincePlay=$sincePlay sinceLoadStart=${ms}ms');
    finish('playing');
  }

  void finish(String result) {
    if (finished) return;
    finished = true;
    log('MINI_SERIES_EPISODE_LOAD_TOTAL',
        '$ids result=$result reason=$reason total=${ms}ms');
  }
}
