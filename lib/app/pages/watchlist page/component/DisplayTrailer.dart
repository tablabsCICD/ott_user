import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart' as native_video;
import 'package:ott/app/core/utils/direct_trailer_source.dart';
import 'package:ott/app/core/utils/security_debug_log.dart';
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

  final looksLikeVideoId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(value);
  return looksLikeVideoId ? value : null;
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
  YoutubePlayerController? _youtubeController;
  native_video.VideoPlayerController? _androidController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  bool _initialized = false;
  bool _historySaved = false;
  bool _hasError = false;

  String get _trailerUrl =>
      DirectTrailerSource.fromBackend(widget.trailerUrl) ?? '';
  bool get _hasUrl => _trailerUrl.isNotEmpty;
  String? get _youtubeId => _extractYoutubeId(_trailerUrl);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_hasUrl) _initPlayer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_player?.pause());
      unawaited(_androidController?.pause());
      _youtubeController?.pause();
    }
  }

  Future<void> _initPlayer() async {
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
        ),
      )..addListener(() {
          if (!mounted) return;
          _youtubeController!.value.isPlaying
              ? WakelockPlus.enable()
              : WakelockPlus.disable();
        });

      if (mounted) {
        setState(() => _initialized = true);
      }
      return;
    }

    final uri = Uri.tryParse(_trailerUrl);
    if (uri == null || !uri.hasScheme) {
      if (mounted) setState(() => _hasError = true);
      return;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final controller = native_video.VideoPlayerController.networkUrl(uri);
      try {
        await controller.initialize();
        await controller.setVolume(1);
        if (!mounted) {
          await controller.dispose();
          return;
        }
        _androidController = controller;
        await controller.play();
        WakelockPlus.enable();
        setState(() => _initialized = true);
        return;
      } catch (error, stackTrace) {
        debugPrint('Android trailer ExoPlayer error: $error\n$stackTrace');
        await controller.dispose();
        if (mounted) setState(() => _hasError = true);
        return;
      }
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
          debugPrint('Trailer media_kit error: $error');
          if (mounted) setState(() => _hasError = true);
        }));

      SecurityDebugLog.event(
        'TRAILER',
        'Passing the direct backend trailer URL to media_kit.',
      );
      await player.open(Media(_trailerUrl), play: true);
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
    } catch (error) {
      debugPrint('Trailer init error: $error');
      await player.dispose();
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _saveHistory() async {
    try {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user == null) return;

      final body = {
        "contentId": widget.content.id,
        "resumeTime": _player?.state.position.toString() ?? "0:00",
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
    final androidController = _androidController;
    if (androidController != null) {
      unawaited(androidController.seekTo(boundedSeekPosition(
        position: androidController.value.position,
        duration: androidController.value.duration,
        offset: offset,
      )));
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
    final androidController = _androidController;
    _player = null;
    _videoController = null;
    _androidController = null;
    if (player != null) {
      try {
        await player.pause();
      } catch (_) {}
      await player.dispose();
    }
    if (androidController != null) {
      await androidController.pause();
      await androidController.dispose();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_disposePlayer());
    _youtubeController?.dispose();
    WakelockPlus.disable();

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_hasUrl
          ? const Center(
              child: Text("No trailer available",
                  style: TextStyle(color: Colors.white)),
            )
          : _hasError
              ? const Center(
                  child: Text("Trailer unavailable",
                      style: TextStyle(color: Colors.white)),
                )
              : !_initialized
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  : Stack(
                      children: [
                        Center(child: _playerSurface()),
                        SafeArea(
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios,
                                  color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _playerSurface() {
    if (_youtubeController != null) {
      return YoutubePlayerBuilder(
        player: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.redAccent,
          progressColors: const ProgressBarColors(
            playedColor: Colors.redAccent,
            handleColor: Colors.redAccent,
          ),
        ),
        builder: (context, player) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                player,
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
        },
      );
    }

    final androidController = _androidController;
    if (androidController != null && androidController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: androidController.value.aspectRatio == 0
            ? 16 / 9
            : androidController.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            native_video.VideoPlayer(androidController),
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
    with WidgetsBindingObserver {
  Player? _player;
  VideoController? _videoController;
  native_video.VideoPlayerController? _androidController;
  YoutubePlayerController? _youtubeController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _showControls = false;
  bool _isDisposed = false;
  bool _hasError = false;
  int _initToken = 0;
  Future<void>? _initializationFuture;
  bool _manuallyPaused = false;
  bool _appIsActive = true;

  String get _trailerUrl =>
      DirectTrailerSource.fromBackend(widget.trailerUrl) ?? '';
  String? get _youtubeId => _extractYoutubeId(_trailerUrl);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appIsActive = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    widget.controller.pause = () {
      _manuallyPaused = true;
      _player?.pause();
      _androidController?.pause();
      _youtubeController?.pause();
    };

    widget.controller.play = () {
      _manuallyPaused = false;
      if (!_appIsActive) return;
      _player?.play();
      _androidController?.play();
      _youtubeController?.play();
    };

    widget.controller.mute = () {
      _player?.setVolume(0);
      _androidController?.setVolume(0);
      _youtubeController?.mute();
    };

    widget.controller.unmute = () {
      _player?.setVolume(100);
      _androidController?.setVolume(1);
      _youtubeController?.unMute();
    };
    widget.controller.disposePlayer = _disposeControllerAsync;

    if (widget.trailerUrl?.isNotEmpty == true) {
      _initializationFuture = _init();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appIsActive = state == AppLifecycleState.resumed;
    if (!_appIsActive) {
      unawaited(_player?.pause());
      unawaited(_androidController?.pause());
      _youtubeController?.pause();
    } else if (widget.autoPlay && !_manuallyPaused) {
      unawaited(_player?.play());
      unawaited(_androidController?.play());
      _youtubeController?.play();
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
      if (!widget.autoPlay || _manuallyPaused || !_appIsActive) {
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

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final controller = native_video.VideoPlayerController.networkUrl(uri);
      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(widget.muted ? 0 : 1);
        if (widget.autoPlay && !_manuallyPaused && _appIsActive) {
          await controller.play();
        }
        if (_isDisposed || currentToken != _initToken) {
          await controller.dispose();
          return;
        }
        if (mounted) {
          setState(() {
            _hasError = false;
            _androidController = controller;
          });
        }
      } catch (error, stackTrace) {
        debugPrint('Android trailer preview error: $error\n$stackTrace');
        await controller.dispose();
        if (mounted && !_isDisposed) setState(() => _hasError = true);
      }
      return;
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
          if (completed &&
              !_isDisposed &&
              currentToken == _initToken &&
              widget.autoPlay &&
              !_manuallyPaused &&
              _appIsActive) {
            player.seek(Duration.zero);
            player.play();
          }
        }))
        ..add(player.stream.error.listen((error) {
          debugPrint('Trailer preview media_kit error: $error');
          if (mounted && !_isDisposed) {
            setState(() => _hasError = true);
          }
        }));

      SecurityDebugLog.event(
        'TRAILER',
        'Passing the direct backend trailer URL to the embedded media_kit player.',
      );
      await player.open(Media(_trailerUrl), play: false);
      await player.setVolume(widget.muted ? 0 : 100);
      if (widget.autoPlay && !_manuallyPaused && _appIsActive) {
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
      debugPrint('Trailer preview init error: $error');
      await player.dispose();
      if (mounted && !_isDisposed) {
        setState(() => _hasError = true);
      }
    }
  }

  @override
  void didUpdateWidget(covariant TrailerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trailerUrl != widget.trailerUrl) {
      _manuallyPaused = false;
      _disposeController();
      _hasError = false;
      if (widget.trailerUrl?.isNotEmpty == true) {
        _initializationFuture = _init();
      }
      return;
    }
    if (oldWidget.muted != widget.muted) {
      unawaited(_player?.setVolume(widget.muted ? 0 : 100));
      unawaited(_androidController?.setVolume(widget.muted ? 0 : 1));
      widget.muted ? _youtubeController?.mute() : _youtubeController?.unMute();
    }
    if (oldWidget.autoPlay != widget.autoPlay) {
      if (widget.autoPlay && !_manuallyPaused && _appIsActive) {
        unawaited(_player?.play());
        unawaited(_androidController?.play());
        _youtubeController?.play();
      } else {
        unawaited(_player?.pause());
        unawaited(_androidController?.pause());
        _youtubeController?.pause();
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
    final androidController = _androidController;
    _player = null;
    _videoController = null;
    _androidController = null;
    if (player != null) {
      unawaited(player.pause());
      unawaited(player.dispose());
    }
    if (androidController != null) {
      unawaited(androidController.pause());
      unawaited(androidController.dispose());
    }

    _youtubeController?.pause();
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  Future<void> _disposeControllerAsync() async {
    _initToken++;
    await _initializationFuture;
    _initializationFuture = null;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    final player = _player;
    final androidController = _androidController;
    _player = null;
    _videoController = null;
    _androidController = null;
    if (player != null) {
      SecurityDebugLog.event(
        'TRAILER',
        'Awaiting embedded trailer disposal before secure playback.',
      );
      await player.dispose();
      SecurityDebugLog.event(
        'TRAILER',
        'Embedded trailer disposal completed before secure playback.',
      );
    }
    if (androidController != null) {
      await androidController.pause();
      await androidController.dispose();
    }
    _youtubeController?.pause();
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.pause = null;
    widget.controller.play = null;
    widget.controller.mute = null;
    widget.controller.unmute = null;
    widget.controller.disposePlayer = null;
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
    final androidController = _androidController;
    if (androidController != null) {
      unawaited(androidController.seekTo(boundedSeekPosition(
        position: androidController.value.position,
        duration: androidController.value.duration,
        offset: offset,
      )));
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

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: Text(
            "Trailer unavailable",
            style: TextStyle(color: Colors.white.withOpacity(0.7)),
          ),
        ),
      );
    }

    final androidController = _androidController;
    if (androidController != null && androidController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: androidController.value.aspectRatio == 0
            ? 16 / 9
            : androidController.value.aspectRatio,
        child: native_video.VideoPlayer(androidController),
      );
    }

    if (_player == null || _videoController == null) {
      if (_youtubeController != null) {
        return _buildYoutubePreview();
      }

      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
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
                    onPressed: () {
                      if (player.state.playing) {
                        _manuallyPaused = true;
                        player.pause();
                      } else {
                        _manuallyPaused = false;
                        if (_appIsActive) player.play();
                      }
                      setState(() {});
                    },
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
  VoidCallback? mute;
  VoidCallback? unmute;
  Future<void> Function()? disposePlayer;
}
