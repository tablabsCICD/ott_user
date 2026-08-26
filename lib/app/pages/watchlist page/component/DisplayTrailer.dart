import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ott/app/core/utils/direct_trailer_source.dart';
import 'package:ott/app/core/utils/security_debug_log.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:video_player/video_player.dart' as native_video;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:ott/app/widgets/ott_tv_app_shell.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/video_skip_controls.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

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

Duration boundedSeekPosition({
  required Duration position,
  required Duration duration,
  required Duration offset,
}) {
  final target = position + offset;
  if (target < Duration.zero) return Duration.zero;
  if (duration > Duration.zero && target > duration) return duration;
  return target;
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
  bool _isMuted = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;

  String get _trailerUrl =>
      DirectTrailerSource.fromBackend(widget.trailerUrl) ?? '';
  bool get _hasUrl => _trailerUrl.isNotEmpty;
  String? get _youtubeId => _extractYoutubeId(_trailerUrl);

  Duration get _currentPosition {
    if (_player != null) return _player!.state.position;
    if (_androidController != null && _androidController!.value.isInitialized) {
      return _androidController!.value.position;
    }
    if (_youtubeController != null) return _youtubeController!.value.position;
    return Duration.zero;
  }

  Duration get _totalDuration {
    if (_player != null) return _player!.state.duration;
    if (_androidController != null && _androidController!.value.isInitialized) {
      return _androidController!.value.duration;
    }
    if (_youtubeController != null) {
      return _youtubeController!.value.metaData.duration;
    }
    return Duration.zero;
  }

  bool get _isPlaying {
    if (_player != null) return _player!.state.playing;
    if (_androidController != null && _androidController!.value.isInitialized) {
      return _androidController!.value.isPlaying;
    }
    if (_youtubeController != null) {
      return _youtubeController!.value.isPlaying;
    }
    return false;
  }

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
          setState(() {});
        });

      if (mounted) {
        setState(() => _initialized = true);
        _scheduleHideControls();
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
        await controller.setVolume(_isMuted ? 0 : 1);
        controller.addListener(() {
          if (!mounted) return;
          controller.value.isPlaying
              ? WakelockPlus.enable()
              : WakelockPlus.disable();
          setState(() {});
        });
        if (!mounted) {
          await controller.dispose();
          return;
        }
        _androidController = controller;
        await controller.play();
        WakelockPlus.enable();
        setState(() => _initialized = true);
        _scheduleHideControls();
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
      _subscriptions
        ..add(player.stream.playing.listen((playing) {
          if (!mounted) return;
          if (playing) {
            WakelockPlus.enable();
            _scheduleHideControls();
          } else {
            WakelockPlus.disable();
          }
          if (mounted) setState(() {});
        }))
        ..add(player.stream.completed.listen((completed) {
          if (completed && !_historySaved) {
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
      await player.setVolume(_isMuted ? 0 : 100);

      if (!mounted) {
        await player.dispose();
        return;
      }

      setState(() {
        _player = player;
        _videoController = controller;
        _initialized = true;
      });
      _scheduleHideControls();
    } catch (error) {
      debugPrint('Trailer init error: $error');
      await player.dispose();
      if (mounted) setState(() => _hasError = true);
    }
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _showControlsTemporarily() {
    _hideControlsTimer?.cancel();
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _scheduleHideControls();
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
    _showControlsTemporarily();
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
    _hideControlsTimer?.cancel();
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
    SystemChrome.setPreferredOrientations(
      FlavorConfig.current.isTv
          ? const [
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]
          : const [DeviceOrientation.portraitUp],
    );

    super.dispose();
  }

  void _togglePlayback() {
    _showControlsTemporarily();
    final youtube = _youtubeController;
    if (youtube != null) {
      if (youtube.value.isPlaying) {
        youtube.pause();
      } else {
        youtube.play();
      }
      setState(() {});
      return;
    }
    final androidController = _androidController;
    if (androidController != null) {
      if (androidController.value.isPlaying) {
        unawaited(androidController.pause());
      } else {
        unawaited(androidController.play());
      }
      setState(() {});
      return;
    }
    final player = _player;
    if (player != null) {
      unawaited(player.playOrPause());
      setState(() {});
    }
  }

  void _toggleMute() {
    _showControlsTemporarily();
    final newMuted = !_isMuted;
    _isMuted = newMuted;
    if (_player != null) {
      _player!.setVolume(newMuted ? 0 : 100);
    }
    if (_androidController != null) {
      unawaited(_androidController!.setVolume(newMuted ? 0.0 : 1.0));
    }
    if (_youtubeController != null) {
      newMuted ? _youtubeController!.mute() : _youtubeController!.unMute();
    }
    setState(() {});
  }

  KeyEventResult _handleRemoteKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    _showControlsTemporarily();
    final key = event.logicalKey;
    if (OttTvRemoteKey.playPause.contains(key) ||
        key == LogicalKeyboardKey.space) {
      _togglePlayback();
      return KeyEventResult.handled;
    }
    if (OttTvRemoteKey.fastForward.contains(key)) {
      _seekBy(const Duration(seconds: 10));
      return KeyEventResult.handled;
    }
    if (OttTvRemoteKey.rewind.contains(key)) {
      _seekBy(const Duration(seconds: -10));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack ||
        key == LogicalKeyboardKey.gameButtonB) {
      Navigator.pop(context);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _format(Duration d) {
    if (d == Duration.zero) return "00:00";
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _disposePlayer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          autofocus: ResponsiveWidget.isTv(context),
          onKeyEvent: _handleRemoteKey,
          child: !_hasUrl
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
                      : MouseRegion(
                          onHover: (_) => _showControlsTemporarily(),
                          child: GestureDetector(
                            onTap: () {
                              if (_showControls) {
                                setState(() => _showControls = false);
                              } else {
                                _showControlsTemporarily();
                              }
                            },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Center(child: _playerSurface()),
                                _buildControlOverlay(),
                              ],
                            ),
                          ),
                        ),
        ),
      ),
    );
  }

  Widget _buildControlOverlay() {
    final title = widget.content.title ?? 'Trailer';
    return AnimatedOpacity(
      opacity: _showControls ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      child: IgnorePointer(
        ignoring: !_showControls,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black87,
                Colors.transparent,
                Colors.transparent,
                Colors.black87,
              ],
              stops: [0.0, 0.25, 0.72, 1.0],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      OttTvFocus(
                        onTap: () => Navigator.pop(context),
                        borderRadius: 24,
                        semanticLabel: 'Back',
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      OttTvFocus(
                        onTap: _toggleMute,
                        borderRadius: 24,
                        semanticLabel: _isMuted ? 'Unmute' : 'Mute',
                        child: IconButton(
                          icon: Icon(
                            _isMuted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _toggleMute,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OttTvFocus(
                        onTap: () => Navigator.pop(context),
                        borderRadius: 24,
                        semanticLabel: 'Close Full Screen',
                        child: IconButton(
                          icon: const Icon(
                            Icons.fullscreen_exit_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OttTvFocus(
                        onTap: () => _seekBy(const Duration(seconds: -10)),
                        borderRadius: 30,
                        semanticLabel: 'Rewind 10 seconds',
                        child: IconButton(
                          iconSize: 42,
                          icon: const Icon(Icons.replay_10_rounded,
                              color: Colors.white),
                          onPressed: () =>
                              _seekBy(const Duration(seconds: -10)),
                        ),
                      ),
                      const SizedBox(width: 36),
                      OttTvFocus(
                        autofocus: true,
                        onTap: _togglePlayback,
                        borderRadius: 36,
                        semanticLabel: _isPlaying ? 'Pause' : 'Play',
                        child: IconButton(
                          iconSize: 58,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayback,
                        ),
                      ),
                      const SizedBox(width: 36),
                      OttTvFocus(
                        onTap: () => _seekBy(const Duration(seconds: 10)),
                        borderRadius: 30,
                        semanticLabel: 'Forward 10 seconds',
                        child: IconButton(
                          iconSize: 42,
                          icon: const Icon(Icons.forward_10_rounded,
                              color: Colors.white),
                          onPressed: () =>
                              _seekBy(const Duration(seconds: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 24,
                  right: 24,
                  child: Row(
                    children: [
                      Text(
                        _format(_currentPosition),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProgressSlider(),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _format(_totalDuration),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSlider() {
    final durationMs = _totalDuration.inMilliseconds;
    final posMs = _currentPosition.inMilliseconds;
    if (durationMs <= 0) {
      return const LinearProgressIndicator(
        value: 0,
        color: Colors.redAccent,
        backgroundColor: Colors.white24,
      );
    }
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
        activeTrackColor: Theme.of(context).primaryColor,
        inactiveTrackColor: Colors.white24,
        thumbColor: Theme.of(context).primaryColor,
      ),
      child: Slider(
        min: 0,
        max: durationMs.toDouble(),
        value: posMs.clamp(0, durationMs).toDouble(),
        onChanged: (value) {
          final target = Duration(milliseconds: value.round());
          if (_player != null) {
            _player!.seek(target);
          } else if (_androidController != null) {
            _androidController!.seekTo(target);
          } else if (_youtubeController != null) {
            _youtubeController!.seekTo(target);
          }
          setState(() {});
        },
      ),
    );
  }

  Widget _playerSurface() {
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
            child: YoutubePlayer(
              controller: _youtubeController!,
              width: width,
              aspectRatio: aspectRatio,
              showVideoProgressIndicator: false,
            ),
          );
        },
      );
    }

    final androidController = _androidController;
    if (androidController != null && androidController.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: androidController.value.size.width > 0
                ? androidController.value.size.width
                : 1920,
            height: androidController.value.size.height > 0
                ? androidController.value.size.height
                : 1080,
            child: native_video.VideoPlayer(androidController),
          ),
        ),
      );
    }

    final player = _player;
    final controller = _videoController;
    if (player == null || controller == null) {
      return const SizedBox.shrink();
    }

    return SizedBox.expand(
      child: Video(
        controller: controller,
        fit: BoxFit.contain,
        fill: Colors.black,
        controls: NoVideoControls,
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
  bool _isMuted = false;
  int _initToken = 0;
  Future<void>? _initializationFuture;
  bool _manuallyPaused = false;
  bool _appIsActive = true;

  String get _trailerUrl =>
      DirectTrailerSource.fromBackend(widget.trailerUrl) ?? '';
  String? get _youtubeId => _extractYoutubeId(_trailerUrl);

  Duration get _currentPosition {
    if (_player != null) return _player!.state.position;
    if (_androidController != null && _androidController!.value.isInitialized) {
      return _androidController!.value.position;
    }
    if (_youtubeController != null) return _youtubeController!.value.position;
    return Duration.zero;
  }

  Duration get _totalDuration {
    if (_player != null) return _player!.state.duration;
    if (_androidController != null && _androidController!.value.isInitialized) {
      return _androidController!.value.duration;
    }
    if (_youtubeController != null) {
      return _youtubeController!.value.metaData.duration;
    }
    return Duration.zero;
  }

  bool get _isPlaying {
    if (_player != null) return _player!.state.playing;
    if (_androidController != null && _androidController!.value.isInitialized) {
      return _androidController!.value.isPlaying;
    }
    if (_youtubeController != null) {
      return _youtubeController!.value.isPlaying;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _isMuted = widget.muted;
    WidgetsBinding.instance.addObserver(this);
    _appIsActive = WidgetsBinding.instance.lifecycleState == null ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

    widget.controller.pause = () {
      _manuallyPaused = true;
      _player?.pause();
      _androidController?.pause();
      _youtubeController?.pause();
      if (mounted) setState(() {});
    };

    widget.controller.play = () {
      _manuallyPaused = false;
      if (!_appIsActive) return;
      _player?.play();
      _androidController?.play();
      _youtubeController?.play();
      if (mounted) setState(() {});
    };

    widget.controller.mute = () {
      _isMuted = true;
      _player?.setVolume(0);
      _androidController?.setVolume(0);
      _youtubeController?.mute();
      if (mounted) setState(() {});
    };

    widget.controller.unmute = () {
      _isMuted = false;
      _player?.setVolume(100);
      _androidController?.setVolume(1);
      _youtubeController?.unMute();
      if (mounted) setState(() {});
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
        flags: YoutubePlayerFlags(
          autoPlay: widget.autoPlay,
          mute: _isMuted,
          loop: true,
        ),
      )..addListener(() {
          if (mounted) setState(() {});
        });

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
        await controller.setVolume(_isMuted ? 0 : 1);
        controller.addListener(() {
          if (mounted) setState(() {});
        });
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
      await player.setVolume(_isMuted ? 0 : 100);
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
      _isMuted = widget.muted;
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

  void _togglePlayback() {
    final youtube = _youtubeController;
    if (youtube != null) {
      if (youtube.value.isPlaying) {
        _manuallyPaused = true;
        youtube.pause();
      } else {
        _manuallyPaused = false;
        if (_appIsActive) youtube.play();
      }
      setState(() {});
      return;
    }
    final androidController = _androidController;
    if (androidController != null) {
      if (androidController.value.isPlaying) {
        _manuallyPaused = true;
        unawaited(androidController.pause());
      } else {
        _manuallyPaused = false;
        if (_appIsActive) unawaited(androidController.play());
      }
      setState(() {});
      return;
    }
    final player = _player;
    if (player != null) {
      if (player.state.playing) {
        _manuallyPaused = true;
        player.pause();
      } else {
        _manuallyPaused = false;
        if (_appIsActive) player.play();
      }
      setState(() {});
    }
  }

  void _toggleMute() {
    final newMuted = !_isMuted;
    _isMuted = newMuted;
    if (_player != null) {
      _player!.setVolume(newMuted ? 0 : 100);
    }
    if (_androidController != null) {
      unawaited(_androidController!.setVolume(newMuted ? 0.0 : 1.0));
    }
    if (_youtubeController != null) {
      newMuted ? _youtubeController!.mute() : _youtubeController!.unMute();
    }
    setState(() {});
  }

  Future<void> _openFullScreen() async {
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

    final isInitialized = (_youtubeController != null) ||
        (_androidController != null && _androidController!.value.isInitialized) ||
        (_player != null && _videoController != null);

    if (!isInitialized) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    final isTv = ResponsiveWidget.isTv(context);
    final showOverlay = _showControls || isTv;

    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildSurface(),
              if (showOverlay) ...[
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.55),
                          Colors.transparent,
                          Colors.black.withOpacity(0.65),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OttTvFocus(
                        onTap: () => _seekPreviewBy(const Duration(seconds: -10)),
                        borderRadius: 24,
                        semanticLabel: 'Rewind 10s',
                        child: IconButton(
                          iconSize: 32,
                          icon: const Icon(
                            Icons.replay_10_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              _seekPreviewBy(const Duration(seconds: -10)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      OttTvFocus(
                        onTap: _togglePlayback,
                        borderRadius: 28,
                        semanticLabel: _isPlaying ? 'Pause' : 'Play',
                        child: IconButton(
                          iconSize: 44,
                          icon: Icon(
                            _isPlaying
                                ? Icons.pause_circle_filled_rounded
                                : Icons.play_circle_filled_rounded,
                            color: Colors.white,
                          ),
                          onPressed: _togglePlayback,
                        ),
                      ),
                      const SizedBox(width: 16),
                      OttTvFocus(
                        onTap: () => _seekPreviewBy(const Duration(seconds: 10)),
                        borderRadius: 24,
                        semanticLabel: 'Forward 10s',
                        child: IconButton(
                          iconSize: 32,
                          icon: const Icon(
                            Icons.forward_10_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () =>
                              _seekPreviewBy(const Duration(seconds: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: Row(
                    children: [
                      Text(
                        _format(_currentPosition),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                      const SizedBox(width: 6),
                      Expanded(child: _buildSlider()),
                      const SizedBox(width: 6),
                      Text(
                        _format(_totalDuration),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              Positioned(
                top: 4,
                left: 4,
                child: OttTvFocus(
                  onTap: _toggleMute,
                  borderRadius: 20,
                  semanticLabel: _isMuted ? 'Unmute' : 'Mute',
                  child: IconButton(
                    iconSize: 22,
                    icon: Icon(
                      _isMuted
                          ? Icons.volume_off_rounded
                          : Icons.volume_up_rounded,
                      color: Colors.white,
                    ),
                    onPressed: _toggleMute,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: OttTvFocus(
                  onTap: _openFullScreen,
                  borderRadius: 20,
                  semanticLabel: 'Full Screen',
                  child: IconButton(
                    iconSize: 22,
                    onPressed: _openFullScreen,
                    icon: const Icon(
                      Icons.fullscreen_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSurface() {
    if (_youtubeController != null) {
      return YoutubePlayer(
        controller: _youtubeController!,
        showVideoProgressIndicator: false,
      );
    }
    final androidController = _androidController;
    if (androidController != null && androidController.value.isInitialized) {
      return native_video.VideoPlayer(androidController);
    }
    if (_player != null && _videoController != null) {
      return Video(
        controller: _videoController!,
        fit: BoxFit.cover,
        controls: null,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSlider() {
    final durationMs = _totalDuration.inMilliseconds;
    final positionMs = _currentPosition.inMilliseconds;
    if (durationMs <= 0) {
      return const LinearProgressIndicator(
        value: 0,
        color: Colors.redAccent,
        backgroundColor: Colors.white24,
      );
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
        activeTrackColor: Theme.of(context).primaryColor,
        inactiveTrackColor: Colors.white24,
        thumbColor: Theme.of(context).primaryColor,
      ),
      child: Slider(
        min: 0,
        max: durationMs.toDouble(),
        value: positionMs.clamp(0, durationMs).toDouble(),
        onChanged: (value) {
          final target = Duration(milliseconds: value.round());
          if (_player != null) {
            _player!.seek(target);
          } else if (_androidController != null) {
            _androidController!.seekTo(target);
          } else if (_youtubeController != null) {
            _youtubeController!.seekTo(target);
          }
          setState(() {});
        },
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
