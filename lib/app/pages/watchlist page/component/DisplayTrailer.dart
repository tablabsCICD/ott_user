import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

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

class _TrailerPageState extends State<TrailerPage> {
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  ChewieController? _chewieController;

  bool _initialized = false;
  bool _historySaved = false;
  bool _hasError = false;

  String get _trailerUrl => widget.trailerUrl?.trim() ?? '';
  bool get _hasUrl => _trailerUrl.isNotEmpty;
  String? get _youtubeId => _extractYoutubeId(_trailerUrl);

  @override
  void initState() {
    super.initState();
    if (_hasUrl) _initPlayer();
  }

  Future<void> _initPlayer() async {
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

    try {
      _videoController = VideoPlayerController.networkUrl(uri);

    await _videoController!.initialize();
    _videoController!.play();

    _videoController!.addListener(() {
      if (!mounted) return;

      // 🔋 wakelock like PlayMediaPage
      if (_videoController!.value.isPlaying) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }

      // 👁 save history once (non-trailer playback)
      if (_videoController!.value.isPlaying &&
          !_historySaved &&
          !widget.isTrailerUrl) {
        _historySaved = true;
        _saveHistory();
      }
    });

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      zoomAndPan: true,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.redAccent,
        bufferedColor: Colors.white30,
        handleColor: Colors.white,
        backgroundColor: Colors.white12,
      ),
      deviceOrientationsOnEnterFullScreen: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: const [
        DeviceOrientation.portraitUp,
      ],
    );

      if (mounted) setState(() => _initialized = true);
    } catch (_) {
      await _videoController?.dispose();
      _videoController = null;
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _saveHistory() async {
    try {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user == null) return;

      final body = {
        "contentId": widget.content.id,
        "resumeTime": _videoController?.value.position.toString() ?? "0:00",
        "selectedLanguage":
            widget.content.languageList?.first.language ?? "Unknown",
        "userId": user.id,
        "viewDate": DateTime.now().toUtc().toIso8601String(),
      };

      await ApiHelper().postApiWithBody(ApiConstant.saveViewHistory, body);
    } catch (_) {}
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _youtubeController?.dispose();
    _chewieController?.dispose();
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
                ))
              : Stack(
                  children: [
                    Center(child: _playerSurface()),

                    // 🔙 Back button overlay
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
            child: player,
          );
        },
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),

          /// 🎯 Netflix-style gesture overlay
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onDoubleTapDown: (details) async {
                final box = context.findRenderObject() as RenderBox;
                final local = box.globalToLocal(details.globalPosition);
                final isLeft = local.dx < box.size.width / 2;

                final current = _videoController!.value.position;
                final duration = _videoController!.value.duration;

                final target = isLeft
                    ? current - const Duration(seconds: 10)
                    : current + const Duration(seconds: 10);

                await _videoController!.seekTo(
                  target < Duration.zero
                      ? Duration.zero
                      : target > duration
                          ? duration
                          : target,
                );
              },
              onLongPressStart: (_) {
                _videoController!.setPlaybackSpeed(2.0);
              },
              onLongPressEnd: (_) {
                _videoController!.setPlaybackSpeed(1.0);
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Lightweight autoplay preview for MovieDetailsPage
///
class TrailerPreview extends StatefulWidget {
  final String? trailerUrl;
  final Content content;
  final TrailerPreviewController controller;

  const TrailerPreview({
    super.key,
    required this.trailerUrl,
    required this.content,
    required this.controller,
  });

  @override
  State<TrailerPreview> createState() => _TrailerPreviewState();
}

class _TrailerPreviewState extends State<TrailerPreview> {
  VideoPlayerController? _c;
  YoutubePlayerController? _youtubeController;
  bool _showControls = false;
  bool _isDisposed = false;
  bool _hasError = false;
  int _initToken = 0;

  String get _trailerUrl => widget.trailerUrl?.trim() ?? '';
  String? get _youtubeId => _extractYoutubeId(_trailerUrl);

  @override
  void initState() {
    super.initState();

    widget.controller.pause = () {
      _c?.pause();
      _youtubeController?.pause();
    };

    widget.controller.play = () {
      _c?.play();
      _youtubeController?.play();
    };

    if (widget.trailerUrl?.isNotEmpty == true) _init();
  }

  Future<void> _init() async {
    if (_trailerUrl.isEmpty) return;

    final currentToken = ++_initToken;
    final youtubeId = _youtubeId;
    if (youtubeId != null && youtubeId.isNotEmpty) {
      _youtubeController?.dispose();
      final controller = YoutubePlayerController(
        initialVideoId: youtubeId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          loop: true,
        ),
      );

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

    final c = VideoPlayerController.networkUrl(uri);

    try {
      await c.initialize();
      if (_isDisposed || currentToken != _initToken) {
        await c.dispose();
        return;
      }

      c.setLooping(true);
      await c.play();
      if (_isDisposed || currentToken != _initToken) {
        await c.dispose();
        return;
      }

      if (mounted) {
        setState(() {
          _hasError = false;
          _c = c;
        });
      }
    } catch (e) {
      await c.dispose();
      if (mounted && !_isDisposed) {
        setState(() => _hasError = true);
      }
    }
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
    _c?.pause();
    _c?.dispose();
    _c = null;
    _youtubeController?.pause();
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.controller.pause = null;
    widget.controller.play = null;
    _disposeController();
    super.dispose();
  }

  String _format(Duration d) {
    if (d == Duration.zero) return "00:00";
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
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

    if (_c == null) {
      if (_youtubeController != null) {
        return _buildYoutubePreview();
      }

      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(
            child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        )),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _showControls = true),
      onExit: (_) => setState(() => _showControls = false),
      child: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              Positioned.fill(child: VideoPlayer(_c!)),
              if (_showControls) ...[
                // Dark overlay
                Positioned.fill(
                  child: Container(color: Colors.black.withOpacity(0.35)),
                ),

                // Center Play / Pause
                Center(
                  child: IconButton(
                    iconSize: 40,
                    icon: Icon(
                      _c!.value.isPlaying
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _c!.value.isPlaying ? _c!.pause() : _c!.play();
                      });
                    },
                  ),
                ),

                // Bottom controls
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 8,
                  child: Row(
                    children: [
                      // Current time
                      Text(
                        _format(_c!.value.position),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),

                      const SizedBox(width: 6),

                      // Progress bar
                      Expanded(
                        child: VideoProgressIndicator(
                          _c!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white54,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                      ),

                      const SizedBox(width: 6),

                      // Total duration
                      Text(
                        _format(_c!.value.duration),
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
                    _c!.value.volume == 0 ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    final muted = _c!.value.volume == 0;
                    _c!.setVolume(muted ? 1 : 0);
                    setState(() {});
                  },
                ),
              ),
              Positioned(
                top: 0,
                right: 1,
                child: IconButton(
                  onPressed: () {
                    _c!.pause(); // pauses preview while navigating to fullsfcreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrailerPage(
                            trailerUrl: widget.trailerUrl,
                            isTrailerUrl: true,
                            content: widget.content),
                      ),
                    );
                  },
                  icon: Icon(
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
                  onPressed: () {
                    _youtubeController!.pause();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TrailerPage(
                          trailerUrl: widget.trailerUrl,
                          isTrailerUrl: true,
                          content: widget.content,
                        ),
                      ),
                    );
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
}

class TrailerPreviewController {
  VoidCallback? pause;
  VoidCallback? play;
}
