import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:video_player/video_player.dart';
import 'package:universal_html/html.dart' as html;

import '../../data/models/content.dart';
import '../../data/models/response/saveViewHistory.dart';
import '../core/constant/api_constant.dart';
import '../core/network/api_helper.dart';
import '../core/utils/sharepreferences.dart';

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
  VideoPlayerController? _controller;

  bool _initialized = false;
  bool _showControls = true;
  bool _isMuted = false;
  bool _isFullScreen = false;
  bool _historySaved = false;

  Timer? _hideTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool get _hasUrl => widget.trailerUrl?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    if (_hasUrl) _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.trailerUrl!));
    await c.initialize();
    c.setLooping(false);
    c.play(); // autoplay

    c.addListener(() {
      if (!mounted) return;

      setState(() {
        _position = c.value.position;
        _duration = c.value.duration;
      });

      if (c.value.isPlaying && !_historySaved && !widget.isTrailerUrl) {
        _historySaved = true;
        _saveHistory();
      }
    });

    setState(() {
      _controller = c;
      _initialized = true;
    });

    _startHideTimer();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onInteract() {
    setState(() => _showControls = true);
    _startHideTimer();
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    c.value.isPlaying ? c.pause() : c.play();
    setState(() {});
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    _isMuted = !_isMuted;
    c.setVolume(_isMuted ? 0 : 1);
    setState(() {});
  }

  void _seek(int seconds) {
    final c = _controller;
    if (c == null) return;
    final target = (c.value.position.inSeconds + seconds)
        .clamp(0, c.value.duration.inSeconds);
    c.seekTo(Duration(seconds: target));
  }

  void _toggleFullscreen() {
    _isFullScreen = !_isFullScreen;
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }
    setState(() {});
  }

  Future<void> _saveHistory() async {
    try {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user == null) return;

      final body = {
        "contentId": widget.content.id,
        "resumeTime": _controller?.value.position.toString() ?? "0:00",
        "selectedLanguage":
            widget.content.languageList?.first.language ?? "Unknown",
        "userId": user.id,
        "viewDate": DateTime.now().toUtc().toIso8601String(),
      };

      final res =
          await ApiHelper().postApiWithBody(ApiConstant.saveViewHistory, body);

      if (res.statusCode == 200) {
        final parsed = SaveViewHistory.fromJson(json.decode(res.body));
        if (parsed.success != true) {
          debugPrint("History save failed: ${parsed.message}");
        }
      }
    } catch (e) {
      debugPrint("History error: $e");
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onInteract,
      onPanDown: (_) => _onInteract(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: !_hasUrl
                  ? const Text("No trailer available",
                      style: TextStyle(color: Colors.white))
                  : _initialized
                      ? AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: VideoPlayer(_controller!),
                        )
                      : CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
            ),
            if (_showControls) _buildOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return SafeArea(
      child: Container(
        height: double.infinity,
        width: double.infinity,
        color: Colors.black.withOpacity(0.35),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white),
                  onPressed: _toggleMute,
                ),
                IconButton(
                  icon: Icon(
                      _isFullScreen
                          ? Icons.rotate_90_degrees_ccw
                          : Icons.rotate_90_degrees_cw,
                      color: Colors.white),
                  onPressed: _toggleFullscreen,
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    onPressed: () => _seek(-10),
                    icon: const Icon(Icons.replay_10, color: Colors.white)),
                IconButton(
                  onPressed: _togglePlay,
                  icon: Icon(
                    _controller?.value.isPlaying == true
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                    onPressed: () => _seek(10),
                    icon: const Icon(Icons.forward_10, color: Colors.white)),
              ],
            ),
            Spacer(),
            _buildProgress(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final theme = Theme.of(context);

    String fmt(Duration d) =>
        "${d.inMinutes.remainder(60).toString().padLeft(2, '0')}:${d.inSeconds.remainder(60).toString().padLeft(2, '0')}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Slider(
            activeColor: theme.primaryColor,
            min: 0,
            max: _duration.inSeconds.toDouble(),
            value: _position.inSeconds.clamp(0, _duration.inSeconds).toDouble(),
            onChanged: (v) => _controller?.seekTo(Duration(seconds: v.toInt())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt(_position), style: const TextStyle(color: Colors.white)),
              Text(fmt(_duration), style: const TextStyle(color: Colors.white)),
            ],
          )
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
  bool _showControls = false;

  @override
  void initState() {
    super.initState();

    widget.controller.pause = () {
      _c?.pause();
    };

    widget.controller.play = () {
      _c?.play();
    };

    if (widget.trailerUrl?.isNotEmpty == true) _init();
  }

  Future<void> _init() async {
    final c = VideoPlayerController.networkUrl(Uri.parse(widget.trailerUrl!));
    await c.initialize();
    c.setLooping(true);
    c.play();
    setState(() => _c = c);
  }

  @override
  void dispose() {
    widget.controller.pause = null;
    widget.controller.play = null;
    _c?.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    if (d == Duration.zero) return "00:00";
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  @override
  Widget build(BuildContext context) {
    if (_c == null) {
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
}

class TrailerPreviewController {
  VoidCallback? pause;
  VoidCallback? play;
}
