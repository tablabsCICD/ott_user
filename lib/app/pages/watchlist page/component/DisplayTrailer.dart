import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart' hide PlayerState;
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ott/app/core/utils/direct_trailer_source.dart';
import 'package:ott/app/core/utils/security_debug_log.dart';
import 'package:ott/app/route/route_observer.dart';
import 'package:video_player/video_player.dart' as native_video;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:ott/app/widgets/video_skip_controls.dart';

import '../../../../data/models/content.dart';
import '../../../core/constant/api_constant.dart';
import '../../../core/network/api_helper.dart';
import '../../../core/utils/sharepreferences.dart';

String? _extractYoutubeId(String urlOrId) {
  final value = urlOrId.trim();
  if (value.isEmpty) return null;

  final converted = YoutubePlayer.convertUrlToId(value);
  if (converted != null && converted.isNotEmpty) return converted;

  final uri = Uri.tryParse(value);
  if (uri != null) {
    final segments = uri.pathSegments.where((part) => part.isNotEmpty).toList();
    if ((uri.host.contains('youtube.com') || uri.host == 'youtu.be') &&
        segments.isNotEmpty) {
      final candidate = uri.host == 'youtu.be'
          ? segments.first
          : segments.first == 'shorts' && segments.length > 1
              ? segments[1]
              : null;
      if (candidate != null &&
          RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(candidate)) {
        return candidate;
      }
    }
  }

  final looksLikeVideoId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(value);
  return looksLikeVideoId ? value : null;
}

const Duration _trailerNativeInitializeTimeout = Duration(seconds: 12);
const Duration _trailerMediaKitOpenTimeout = Duration(seconds: 20);

bool get _shouldUseNativeIosTrailerPlayer =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

bool _looksLikeHlsUri(Uri uri) {
  final value = uri.toString().toLowerCase();
  return uri.path.toLowerCase().endsWith('.m3u8') || value.contains('.m3u8?');
}

class TrailerPage extends StatefulWidget {
  final String? trailerUrl;
  final bool isTrailerUrl;
  final Content content;

  const TrailerPage({
    super.key,
    required this.trailerUrl,
    required this.isTrailerUrl,
    required this.content,
  });

  @override
  State<TrailerPage> createState() => _TrailerPageState();
}

class _TrailerPageState extends State<TrailerPage> with WidgetsBindingObserver {
  Player? _player;
  VideoController? _videoController;
  native_video.VideoPlayerController? _nativePlayer;
  YoutubePlayerController? _youtubeController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _initialized = false;
  bool _historySaved = false;
  bool _hasError = false;
  bool _controlsVisible = true;
  bool _isSeeking = false;
  Timer? _controlsTimer;

  String get _trailerUrl =>
      DirectTrailerSource.fromBackend(widget.trailerUrl) ?? '';
  bool get _hasUrl => _trailerUrl.isNotEmpty;
  String? get _youtubeId => _extractYoutubeId(_trailerUrl);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (_hasUrl) _initPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_player?.pause());
      unawaited(_nativePlayer?.pause());
      _youtubeController?.pause();
    }
  }

  Future<void> _initPlayer() async {
    if (kDebugMode) {
      debugPrint(_youtubeId == null
          ? 'TRAILER_FLOW: Opening direct trailer player'
          : 'TRAILER_FLOW: Opening YouTube trailer player');
    }
    SecurityDebugLog.event(
      'TRAILER',
      'Initializing trailer from the direct backend URL; signed playback API is intentionally bypassed.',
    );
    final youtubeId = _youtubeId;
    if (youtubeId != null && youtubeId.isNotEmpty) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: false,
          hideControls: true,
        ),
      )..addListener(() {
          if (!mounted) return;
          _youtubeController!.value.isPlaying
              ? WakelockPlus.enable()
              : WakelockPlus.disable();
          setState(() {});
          if (_youtubeController!.value.isPlaying) _scheduleControlsHide();
        });

      if (mounted) {
        setState(() => _initialized = true);
        if (kDebugMode) {
          debugPrint('TRAILER_FLOW: Trailer player initialized');
        }
      }
      return;
    }

    final uri = Uri.tryParse(_trailerUrl);
    if (uri == null || !uri.hasScheme) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    if (_shouldUseNativeIosTrailerPlayer) {
      final initialized = await _initNativeTrailerPlayer(uri);
      if (initialized) return;
      if (!mounted) return;
      SecurityDebugLog.event(
        'TRAILER',
        'Native iOS trailer player could not initialize; falling back to media_kit.',
      );
    }

    final player = Player();
    final controller = VideoController(player);

    try {
      // media_kit powers direct trailer URLs while YouTube URLs keep their
      // existing YouTube-specific controller.
      _subscriptions
        ..add(player.stream.playing.listen((isPlaying) {
          isPlaying ? WakelockPlus.enable() : WakelockPlus.disable();
          if (isPlaying && !_historySaved && !widget.isTrailerUrl) {
            _historySaved = true;
            _saveHistory();
          }
          if (mounted) setState(() {});
        }))
        ..add(player.stream.position.listen((_) {
          if (mounted) setState(() {});
        }))
        ..add(player.stream.duration.listen((_) {
          if (mounted) setState(() {});
        }))
        ..add(player.stream.error.listen((error) {
          if (mounted) setState(() => _hasError = true);
        }));

      SecurityDebugLog.event(
        'TRAILER',
        'Passing the direct backend trailer URL to media_kit.',
      );
      final openFuture = player.open(Media(_trailerUrl), play: true);
      if (_shouldUseNativeIosTrailerPlayer) {
        await openFuture.timeout(_trailerMediaKitOpenTimeout);
      } else {
        await openFuture;
      }
      await player.setVolume(100);

      if (!mounted) {
        await player.dispose();
        return;
      }

      setState(() {
        _player = player;
        _videoController = controller;
        _initialized = true;
      });
      if (kDebugMode) {
        debugPrint('TRAILER_FLOW: Trailer player initialized');
      }
      _scheduleControlsHide();
    } catch (error) {
      await player.dispose();
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<bool> _initNativeTrailerPlayer(Uri uri) async {
    SecurityDebugLog.event(
      'TRAILER',
      'Opening trailer with AVPlayer on iOS using the direct backend trailer URL.',
    );
    SecurityDebugLog.diagnostic(
      'TRAILER_NATIVE_METADATA scheme=${uri.scheme} '
      'host=${uri.host} '
      'queryPresent=${uri.hasQuery} '
      'credentialValuesRedacted=true',
    );

    final controller = native_video.VideoPlayerController.networkUrl(
      uri,
      formatHint: _looksLikeHlsUri(uri) ? native_video.VideoFormat.hls : null,
      videoPlayerOptions: native_video.VideoPlayerOptions(
        mixWithOthers: false,
      ),
    );

    var historySaved = false;
    void listener() {
      if (!mounted) return;

      final value = controller.value;
      value.isPlaying ? WakelockPlus.enable() : WakelockPlus.disable();

      if (value.isPlaying &&
          !historySaved &&
          !_historySaved &&
          !widget.isTrailerUrl) {
        historySaved = true;
        _historySaved = true;
        _saveHistory();
      }

      if (value.hasError) {
        SecurityDebugLog.event(
          'TRAILER',
          'AVPlayer reported a trailer playback error.',
        );
        setState(() => _hasError = true);
        return;
      }

      if (value.isCompleted) {
        unawaited(controller.pause());
      }

      setState(() {});
    }

    controller.addListener(listener);
    try {
      await controller.initialize().timeout(_trailerNativeInitializeTimeout);
      await controller.setLooping(false);
      await controller.setVolume(1.0);
      await controller.play();
    } catch (error) {
      debugPrint('Trailer native init error: $error');
      controller.removeListener(listener);
      await controller.dispose();
      return false;
    }

    if (!mounted) {
      controller.removeListener(listener);
      await controller.dispose();
      return true;
    }

    setState(() {
      _nativePlayer = controller;
      _initialized = true;
      _hasError = false;
    });
    return true;
  }

  Future<void> _saveHistory() async {
    try {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user == null) return;

      final body = {
        "contentId": widget.content.id,
        "resumeTime": _nativePlayer?.value.position.toString() ??
            _player?.state.position.toString() ??
            "0:00",
        "selectedLanguage":
            widget.content.languageList?.first.language ?? "Unknown",
        "userId": user.id,
        "viewDate": DateTime.now().toUtc().toIso8601String(),
      };

      await ApiHelper().postApiWithBody(ApiConstant.saveViewHistory, body);
    } catch (_) {}
  }

  void _seekBy(Duration offset) {
    final youtube = _youtubeController;
    if (youtube != null) {
      youtube.seekTo(
        boundedSeekPosition(
          position: youtube.value.position,
          duration: youtube.value.metaData.duration,
          offset: offset,
        ),
      );
      return;
    }
    final player = _player;
    final nativePlayer = _nativePlayer;
    if (nativePlayer != null && nativePlayer.value.isInitialized) {
      unawaited(
        nativePlayer.seekTo(
          boundedSeekPosition(
            position: nativePlayer.value.position,
            duration: nativePlayer.value.duration,
            offset: offset,
          ),
        ),
      );
      return;
    }
    if (player == null) return;
    unawaited(
      player.seek(
        boundedSeekPosition(
          position: player.state.position,
          duration: player.state.duration,
          offset: offset,
        ),
      ),
    );
  }

  Future<void> _disposePlayer() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    final player = _player;
    final nativePlayer = _nativePlayer;
    _player = null;
    _videoController = null;
    _nativePlayer = null;
    if (player != null) {
      try {
        await player.pause();
      } catch (_) {}
      await player.dispose();
    }
    if (nativePlayer != null) {
      try {
        await nativePlayer.pause();
      } catch (_) {}
      await nativePlayer.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controlsTimer?.cancel();
    unawaited(_disposePlayer());
    _youtubeController?.dispose();
    WakelockPlus.disable();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    if (kDebugMode) {
      debugPrint('TRAILER_FLOW: Trailer player disposed');
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _initialized ? _toggleControls : null,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_initialized)
              Center(child: _playerSurface())
            else
              Center(
                child: _hasError || !_hasUrl
                    ? const Text('Unable to play this trailer.',
                        style: TextStyle(color: Colors.white))
                    : CircularProgressIndicator(
                        color: Theme.of(context).primaryColor),
              ),
            if (_initialized && _controlsVisible) _buildControls(),
            if (_initialized) _buildBottomProgressBar(),
            if (!_initialized || _hasError)
              SafeArea(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return ColoredBox(
      color: Colors.black38,
      child: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    iconSize: 38,
                    onPressed: () => _seekBy(const Duration(seconds: -10)),
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                  ),
                  const SizedBox(width: 28),
                  if (_isBuffering)
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    IconButton(
                      iconSize: 52,
                      onPressed: _togglePlayback,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 28),
                  IconButton(
                    iconSize: 38,
                    onPressed: () => _seekBy(const Duration(seconds: 10)),
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomProgressBar() {
    final durationMs = _duration.inMilliseconds;
    final positionMs = _position.inMilliseconds.clamp(0, durationMs);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          child: Row(
            children: [
              Text(
                _formatDuration(_position),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: positionMs.toDouble(),
                  max: durationMs > 0 ? durationMs.toDouble() : 1,
                  onChangeStart: (_) {
                    _controlsTimer?.cancel();
                    setState(() {
                      _isSeeking = true;
                      _controlsVisible = true;
                    });
                  },
                  onChanged: (value) =>
                      _seekTo(Duration(milliseconds: value.round())),
                  onChangeEnd: (_) {
                    setState(() => _isSeeking = false);
                    _scheduleControlsHide();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDuration(_duration),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _playerSurface() {
    if (_youtubeController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: false,
        ),
        builder: (context, player) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: player,
          );
        },
      );
    }

    final nativePlayer = _nativePlayer;
    if (nativePlayer != null && nativePlayer.value.isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            Positioned.fill(
              child: native_video.VideoPlayer(nativePlayer),
            ),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTapDown: (details) {
                  final box = context.findRenderObject() as RenderBox;
                  final local = box.globalToLocal(details.globalPosition);
                  final isLeft = local.dx < box.size.width / 2;
                  _seekBy(Duration(seconds: isLeft ? -10 : 10));
                },
                onLongPressStart: (_) {
                  nativePlayer.setPlaybackSpeed(2.0);
                },
                onLongPressEnd: (_) {
                  nativePlayer.setPlaybackSpeed(1.0);
                },
              ),
            ),
            Center(
              child: VideoSkipControls(
                onBackward: () => _seekBy(const Duration(seconds: -10)),
                onForward: () => _seekBy(const Duration(seconds: 10)),
                gap: 92,
              ),
            ),
          ],
        ),
      );
    }

    final player = _player;
    final controller = _videoController;
    if (player == null || controller == null) {
      return const SizedBox.shrink();
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Positioned.fill(
            child: Video(
              controller: controller,
              fit: BoxFit.contain,
              controls: null,
            ),
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTapDown: (details) async {
                final box = context.findRenderObject() as RenderBox;
                final local = box.globalToLocal(details.globalPosition);
                final isLeft = local.dx < box.size.width / 2;

                final current = player.state.position;
                final duration = player.state.duration;

                final target = isLeft
                    ? current - const Duration(seconds: 10)
                    : current + const Duration(seconds: 10);

                await player.seek(
                  target < Duration.zero
                      ? Duration.zero
                      : target > duration
                          ? duration
                          : target,
                );
              },
              onLongPressStart: (_) {
                player.setRate(2.0);
              },
              onLongPressEnd: (_) {
                player.setRate(1.0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TrailerPreview extends StatefulWidget {
  final String? trailerUrl;
  final Content content;
  final TrailerPreviewController controller;
  final bool autoPlay;
  final bool muted;

  const TrailerPreview({
    super.key,
    required this.trailerUrl,
    required this.content,
    required this.controller,
    this.autoPlay = true,
    this.muted = false,
  });

  @override
  State<TrailerPreview> createState() => _TrailerPreviewState();
}

class _TrailerPreviewState extends State<TrailerPreview>
    with WidgetsBindingObserver, RouteAware {
  Player? _player;
  VideoController? _videoController;
  native_video.VideoPlayerController? _nativePlayer;
  YoutubePlayerController? _youtubeController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  PageRoute<dynamic>? _route;
  bool _showControls = false;
  bool _isDisposed = false;
  bool _hasError = false;
  bool _userPaused = false;
  bool _wasPlayingBeforeRoutePause = false;
  bool _wasPlayingBeforeLifecyclePause = false;
  int _initToken = 0;

  String get _trailerUrl =>
      DirectTrailerSource.fromBackend(widget.trailerUrl) ?? '';
  String? get _youtubeId => _extractYoutubeId(_trailerUrl);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    widget.controller.pause = () {
      _pausePreview();
    };

    widget.controller.play = () {
      _playPreview();
    };

    widget.controller.canAutoPlay =
        () => !_userPaused && _trailerUrl.isNotEmpty;

    widget.controller.mute = () {
      _player?.setVolume(0);
      _nativePlayer?.setVolume(0);
      _youtubeController?.mute();
    };

    widget.controller.unmute = () {
      _player?.setVolume(100);
      _nativePlayer?.setVolume(1);
      _youtubeController?.unMute();
    };

    if (widget.trailerUrl?.isNotEmpty == true) _init();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic> && route != _route) {
      if (_route != null) {
        routeObserver.unsubscribe(this);
      }
      _route = route;
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void didPushNext() {
    _wasPlayingBeforeRoutePause = _isPreviewPlaying;
    _pausePreview();
  }

  @override
  void didPopNext() {
    if (_wasPlayingBeforeRoutePause && widget.autoPlay && !_userPaused) {
      _playPreview();
    }
    _wasPlayingBeforeRoutePause = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _wasPlayingBeforeLifecyclePause = _isPreviewPlaying;
      _pausePreview();
    } else if (state == AppLifecycleState.resumed &&
        _wasPlayingBeforeLifecyclePause &&
        widget.autoPlay &&
        !_userPaused) {
      _playPreview();
      _wasPlayingBeforeLifecyclePause = false;
    }
  }

  bool get _isPreviewPlaying {
    final player = _player;
    if (player != null) return player.state.playing;
    final nativePlayer = _nativePlayer;
    if (nativePlayer != null) return nativePlayer.value.isPlaying;
    return _youtubeController?.value.isPlaying ?? false;
  }

  void _pausePreview() {
    unawaited(_player?.pause());
    unawaited(_nativePlayer?.pause());
    _youtubeController?.pause();
    if (mounted && !_isDisposed) setState(() {});
  }

  void _playPreview() {
    if (_userPaused) return;
    unawaited(_player?.play());
    unawaited(_nativePlayer?.play());
    _youtubeController?.play();
    if (mounted && !_isDisposed) setState(() {});
  }

  void _toggleManualPlayback() {
    if (_isPreviewPlaying) {
      _userPaused = true;
      _pausePreview();
    } else {
      _userPaused = false;
      _playPreview();
    }
  }

  Future<void> _init() async {
    if (_trailerUrl.isEmpty) return;

    SecurityDebugLog.event(
      'TRAILER',
      'Initializing embedded trailer directly; no signed URL is requested.',
    );
    final currentToken = ++_initToken;
    final youtubeId = _youtubeId;
    if (youtubeId != null && youtubeId.isNotEmpty) {
      _youtubeController?.dispose();
      final controller = YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: true,
          loop: true,
        ),
      );

      if (!widget.muted) {
        controller.unMute();
      }
      if (!widget.autoPlay || _userPaused) {
        controller.pause();
      }

      if (_isDisposed || currentToken != _initToken) {
        controller.dispose();
        return;
      }

      if (mounted) {
        setState(() {
          _hasError = false;
          _youtubeController = controller;
        });
      }
      return;
    }

    final uri = Uri.tryParse(_trailerUrl);
    if (uri == null || !uri.hasScheme) {
      if (mounted && !_isDisposed) {
        setState(() => _hasError = true);
      }
      return;
    }

    if (_shouldUseNativeIosTrailerPlayer) {
      final nativeReady = await _initNativePreview(uri, currentToken);
      if (_isDisposed || currentToken != _initToken) return;
      if (nativeReady) return;
      SecurityDebugLog.event(
        'TRAILER',
        'Native iOS embedded trailer player could not initialize; falling back to media_kit.',
      );
    }

    final player = Player();
    final controller = VideoController(player);

    try {
      _subscriptions
        ..add(player.stream.position.listen((_) {
          if (mounted) setState(() {});
        }))
        ..add(player.stream.duration.listen((_) {
          if (mounted) setState(() {});
        }))
        ..add(player.stream.playing.listen((_) {
          if (mounted) setState(() {});
        }))
        ..add(player.stream.volume.listen((_) {
          if (mounted) setState(() {});
        }))
        ..add(player.stream.completed.listen((completed) {
          if (completed && !_isDisposed && currentToken == _initToken) {
            player.seek(Duration.zero);
            player.play();
          }
        }))
        ..add(player.stream.error.listen((error) {
          if (mounted && !_isDisposed) {
            setState(() => _hasError = true);
          }
        }));

      SecurityDebugLog.event(
        'TRAILER',
        'Passing the direct backend trailer URL to the embedded media_kit player.',
      );
      final openFuture = player.open(Media(_trailerUrl), play: false);
      if (_shouldUseNativeIosTrailerPlayer) {
        await openFuture.timeout(_trailerMediaKitOpenTimeout);
      } else {
        await openFuture;
      }
      await player.setVolume(widget.muted ? 0 : 100);
      if (widget.autoPlay && !_userPaused) {
        await player.play();
      }

      if (_isDisposed || currentToken != _initToken) {
        await player.dispose();
        return;
      }

      if (mounted) {
        setState(() {
          _hasError = false;
          _player = player;
          _videoController = controller;
        });
      }
    } catch (error) {
      await player.dispose();
      if (mounted && !_isDisposed) {
        setState(() => _hasError = true);
      }
    }
  }

  Future<bool> _initNativePreview(Uri uri, int currentToken) async {
    SecurityDebugLog.event(
      'TRAILER',
      'Opening embedded trailer with AVPlayer on iOS using the direct backend trailer URL.',
    );
    SecurityDebugLog.diagnostic(
      'TRAILER_PREVIEW_NATIVE_METADATA scheme=${uri.scheme} '
      'host=${uri.host} '
      'queryPresent=${uri.hasQuery} '
      'credentialValuesRedacted=true',
    );

    final controller = native_video.VideoPlayerController.networkUrl(
      uri,
      formatHint: _looksLikeHlsUri(uri) ? native_video.VideoFormat.hls : null,
      videoPlayerOptions: native_video.VideoPlayerOptions(
        mixWithOthers: false,
      ),
    );

    void listener() {
      if (_isDisposed || !mounted || currentToken != _initToken) return;
      if (controller.value.hasError) {
        SecurityDebugLog.event(
          'TRAILER',
          'AVPlayer reported an embedded trailer playback error.',
        );
        setState(() => _hasError = true);
        return;
      }
      setState(() {});
    }

    controller.addListener(listener);
    try {
      await controller.initialize().timeout(_trailerNativeInitializeTimeout);
      await controller.setLooping(true);
      await controller.setVolume(widget.muted ? 0 : 1);
      if (widget.autoPlay && !_userPaused) {
        await controller.play();
      }
    } catch (error) {
      debugPrint('Trailer preview native init error: $error');
      controller.removeListener(listener);
      await controller.dispose();
      return false;
    }

    if (_isDisposed || currentToken != _initToken) {
      controller.removeListener(listener);
      await controller.dispose();
      return false;
    }

    if (mounted) {
      setState(() {
        _hasError = false;
        _nativePlayer = controller;
      });
    }
    return true;
  }

  @override
  void didUpdateWidget(covariant TrailerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trailerUrl != widget.trailerUrl) {
      _disposeController();
      _hasError = false;
      if (widget.trailerUrl?.isNotEmpty == true) {
        _init();
      }
    }
  }

  void _disposeController() {
    _initToken++;
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    _subscriptions.clear();

    final player = _player;
    final nativePlayer = _nativePlayer;
    _player = null;
    _videoController = null;
    _nativePlayer = null;
    if (player != null) {
      unawaited(player.pause());
      unawaited(player.dispose());
    }
    if (nativePlayer != null) {
      unawaited(nativePlayer.pause());
      unawaited(nativePlayer.dispose());
    }

    _youtubeController?.pause();
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    widget.controller.pause = null;
    widget.controller.play = null;
    widget.controller.canAutoPlay = null;
    widget.controller.mute = null;
    widget.controller.unmute = null;
    _disposeController();
    super.dispose();
  }

  String _format(Duration d) {
    if (d == Duration.zero) return "00:00";
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  void _seekPreviewBy(Duration offset) {
    final youtube = _youtubeController;
    if (youtube != null) {
      youtube.seekTo(
        boundedSeekPosition(
          position: youtube.value.position,
          duration: youtube.value.metaData.duration,
          offset: offset,
        ),
      );
      return;
    }
    final player = _player;
    final nativePlayer = _nativePlayer;
    if (nativePlayer != null && nativePlayer.value.isInitialized) {
      unawaited(
        nativePlayer.seekTo(
          boundedSeekPosition(
            position: nativePlayer.value.position,
            duration: nativePlayer.value.duration,
            offset: offset,
          ),
        ),
      );
      return;
    }
    if (player == null) return;
    unawaited(
      player.seek(
        boundedSeekPosition(
          position: player.state.position,
          duration: player.state.duration,
          offset: offset,
        ),
      ),
    );
  }

  Future<void> _openFullscreenTrailer() async {
    final trailerUrl = _trailerUrl;
    if (trailerUrl.isEmpty) return;

    await _disposeControllerAsync();
    if (!mounted || _isDisposed) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrailerPage(
          trailerUrl: trailerUrl,
          isTrailerUrl: true,
          content: widget.content,
        ),
      ),
    );

    if (mounted && !_isDisposed) {
      _initializationFuture = _init();
    }
  }

  Widget _fullscreenButton() {
    return Positioned(
      right: 8,
      bottom: 8,
      child: Semantics(
        button: true,
        label: 'Play trailer fullscreen',
        child: Material(
          color: Colors.black54,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Fullscreen trailer',
            onPressed: _openFullscreenTrailer,
            icon: const Icon(Icons.fullscreen, color: Colors.white),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: Text(
                "Trailer unavailable",
                style: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
            ),
            if (_trailerUrl.isNotEmpty) _fullscreenButton(),
          ],
        ),
      );
    }

    final nativePlayer = _nativePlayer;
    if (nativePlayer != null && nativePlayer.value.isInitialized) {
      return _buildNativePreview(nativePlayer);
    }

    if (_player == null || _videoController == null) {
      if (_youtubeController != null) {
        return _buildYoutubePreview();
      }

      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
            ),
            if (_trailerUrl.isNotEmpty) _fullscreenButton(),
          ],
        ),
      );
    }

    final player = _player!;
    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: Video(
                  controller: _videoController!,
                  fit: BoxFit.cover,
                  controls: null,
                ),
              ),
              if (_showControls) ...[
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.35)),
                ),
                Center(
                  child: IconButton(
                    iconSize: 40,
                    icon: Icon(
                      player.state.playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: _toggleManualPlayback,
                  ),
                ),
                Center(
                  child: VideoSkipControls(
                    onBackward: () =>
                        _seekPreviewBy(const Duration(seconds: -10)),
                    onForward: () =>
                        _seekPreviewBy(const Duration(seconds: 10)),
                    gap: 72,
                    compact: true,
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 58,
                  bottom: 8,
                  child: Row(
                    children: [
                      Text(
                        _format(player.state.position),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: _progressSlider(player)),
                      const SizedBox(width: 6),
                      Text(
                        _format(player.state.duration),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              Positioned(
                top: 0,
                left: 1,
                child: IconButton(
                  icon: Icon(
                    player.state.volume == 0
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    final muted = player.state.volume == 0;
                    player.setVolume(muted ? 100 : 0);
                    setState(() {});
                  },
                ),
              ),
              Positioned(
                top: 0,
                right: 1,
                child: IconButton(
                  onPressed: () async {
                    final trailerUrl = widget.trailerUrl;
                    _disposeController();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrailerPage(
                          trailerUrl: trailerUrl,
                          isTrailerUrl: true,
                          content: widget.content,
                        ),
                      ),
                    );
                    if (mounted &&
                        !_isDisposed &&
                        (trailerUrl?.trim().isNotEmpty ?? false)) {
                      _init();
                    }
                  },
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNativePreview(native_video.VideoPlayerController player) {
    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: native_video.VideoPlayer(player),
              ),
              if (_showControls) ...[
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.35)),
                ),
                Center(
                  child: IconButton(
                    iconSize: 40,
                    icon: Icon(
                      player.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: _toggleManualPlayback,
                  ),
                ),
                Center(
                  child: VideoSkipControls(
                    onBackward: () =>
                        _seekPreviewBy(const Duration(seconds: -10)),
                    onForward: () =>
                        _seekPreviewBy(const Duration(seconds: 10)),
                    gap: 72,
                    compact: true,
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: Row(
                    children: [
                      Text(
                        _format(player.value.position),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: _nativeProgressSlider(player)),
                      const SizedBox(width: 6),
                      Text(
                        _format(player.value.duration),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
              Positioned(
                top: 0,
                left: 1,
                child: IconButton(
                  icon: Icon(
                    player.value.volume == 0
                        ? Icons.volume_off
                        : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    final muted = player.value.volume == 0;
                    player.setVolume(muted ? 1 : 0);
                    setState(() {});
                  },
                ),
              ),
              Positioned(
                top: 0,
                right: 1,
                child: IconButton(
                  onPressed: () async {
                    final trailerUrl = widget.trailerUrl;
                    _disposeController();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrailerPage(
                          trailerUrl: trailerUrl,
                          isTrailerUrl: true,
                          content: widget.content,
                        ),
                      ),
                    );
                    if (mounted &&
                        !_isDisposed &&
                        (trailerUrl?.trim().isNotEmpty ?? false)) {
                      _init();
                    }
                  },
                  icon: const Icon(
                    Icons.fullscreen,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _progressSlider(Player player) {
    final durationMs = player.state.duration.inMilliseconds;
    final positionMs = player.state.position.inMilliseconds;
    if (durationMs <= 0) {
      return const LinearProgressIndicator(
        value: 0,
        color: Colors.red,
        backgroundColor: Colors.white24,
      );
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      ),
      child: Slider(
        min: 0,
        max: durationMs.toDouble(),
        value: positionMs.clamp(0, durationMs).toDouble(),
        activeColor: Colors.red,
        inactiveColor: Colors.white24,
        onChanged: (value) {
          player.seek(Duration(milliseconds: value.round()));
        },
      ),
    );
  }

  Widget _nativeProgressSlider(native_video.VideoPlayerController player) {
    final durationMs = player.value.duration.inMilliseconds;
    final positionMs = player.value.position.inMilliseconds;
    if (durationMs <= 0) {
      return const LinearProgressIndicator(
        value: 0,
        color: Colors.red,
        backgroundColor: Colors.white24,
      );
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
      ),
      child: Slider(
        min: 0,
        max: durationMs.toDouble(),
        value: positionMs.clamp(0, durationMs).toDouble(),
        activeColor: Colors.red,
        inactiveColor: Colors.white24,
        onChanged: (value) {
          player.seekTo(Duration(milliseconds: value.round()));
        },
      ),
    );
  }

  Widget _buildYoutubePreview() {
    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(
                child: YoutubePlayer(
                  controller: _youtubeController!,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Colors.red,
                  progressColors: const ProgressBarColors(
                    playedColor: Colors.red,
                    handleColor: Colors.red,
                    bufferedColor: Colors.white54,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
              _fullscreenButton(),
              if (_showControls)
                Center(
                  child: VideoSkipControls(
                    onBackward: () =>
                        _seekPreviewBy(const Duration(seconds: -10)),
                    onForward: () =>
                        _seekPreviewBy(const Duration(seconds: 10)),
                    gap: 72,
                    compact: true,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrailerPreviewController {
  VoidCallback? pause;
  VoidCallback? play;
  bool Function()? canAutoPlay;
  VoidCallback? mute;
  VoidCallback? unmute;
}
