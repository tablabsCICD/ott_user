import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:video_player/video_player.dart';
import 'package:universal_html/html.dart' as html;

import '../../data/models/content.dart';
import '../../data/models/response/saveViewHistory.dart';
import '../core/constant/api_constant.dart';
import '../core/network/api_helper.dart';
import '../core/utils/sharepreferences.dart';
import '../widgets/show_toast.dart';

class TrailerPage extends StatefulWidget {
  final String? trailerUrl;
  final bool isTrailerUrl;
  final Content content;

  const TrailerPage({
    Key? key,
    required this.trailerUrl,
    required this.isTrailerUrl,
    required this.content,
  }) : super(key: key);

  @override
  State<TrailerPage> createState() => _TrailerPageState();
}

class _TrailerPageState extends State<TrailerPage> {
  VideoPlayerController? _controller;

  bool _isInitialized = false;
  bool _isMuted = false;
  bool _viewHistorySaved = false;
  bool _showControls = true;
  bool _isFullScreen = false;

  Timer? _hideControlsTimer;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  bool get _hasValidUrl => widget.trailerUrl?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    if (_hasValidUrl) _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      final controller = VideoPlayerController.network(widget.trailerUrl!);
      await controller.initialize();
      controller.setLooping(false);
      controller.play();

      controller.addListener(() {
        if (!mounted) return;

        setState(() {
          _currentPosition = controller.value.position;
          _videoDuration = controller.value.duration;
        });

        if (controller.value.isPlaying &&
            !_viewHistorySaved &&
            !widget.isTrailerUrl) {
          _viewHistorySaved = true;
          _saveViewHistory();
        }
      });

      setState(() {
        _controller = controller;
        _isInitialized = true;
      });

      _startAutoHideTimer();
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  void _startAutoHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _onInteraction() {
    setState(() => _showControls = true);
    _startAutoHideTimer();

    // First tap → fullscreen
    if (!_isFullScreen) {
      _toggleFullScreen();
    }
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    _isFullScreen ? _enterFullScreen() : _exitFullScreen();
  }

  void _enterFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  void _exitFullScreen() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _saveViewHistory() async {
    try {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user == null) return;

      final data = {
        "contentId": widget.content.id,
        "resumeTime": _controller?.value.position.toString() ?? "0:00",
        "selectedLanguage": widget.content.languageList?.first ?? "Unknown",
        "userId": user.id,
        "viewDate": DateTime.now().toUtc().toIso8601String(),
      };

      final response =
          await ApiHelper().postApiWithBody(ApiConstant.saveViewHistory, data);

      if (response.statusCode == 200) {
        final result = SaveViewHistory.fromJson(json.decode(response.body));
        if (!result.success!) {
          debugPrint("Save history failed: ${result.message}");
        }
      }
    } catch (e) {
      debugPrint("History error: $e");
    }
  }

  void _seek(Duration offset) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;

    final target = (c.value.position + offset)
        .inSeconds
        .clamp(0, c.value.duration.inSeconds);
    c.seekTo(Duration(seconds: target));
  }

  void _toggleMute() {
    final c = _controller;
    if (c == null) return;
    setState(() {
      _isMuted = !_isMuted;
      c.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _togglePlayPause() {
    final c = _controller;
    if (c == null) return;
    setState(() => c.value.isPlaying ? c.pause() : c.play());
  }

  void _downloadVideo() {
    if (!_hasValidUrl) {
      CustomToast.show(context, "No video URL available", isSuccess: false);
      return;
    }

    if (kIsWeb) {
      final filename = Uri.parse(widget.trailerUrl!).pathSegments.last;
      html.AnchorElement(href: widget.trailerUrl)
        ..target = 'blank'
        ..download = filename
        ..click();
    }
  }

  @override
  void dispose() {
    _exitFullScreen();
    _controller?.dispose();
    _hideControlsTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onInteraction,
      onPanDown: (_) => _onInteraction(),
      child: Scaffold(
        appBar: AppBar(
          forceMaterialTransparency: true,
        ),
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildVideo(),
            if (_showControls) _buildControls(),
            if (_showControls) _buildCenterActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideo() {
    if (!_hasValidUrl) {
      return const Center(
        child:
            Text("No trailer available", style: TextStyle(color: Colors.white)),
      );
    }

    return Center(
      child: _isInitialized
          ? AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          : const CircularProgressIndicator(),
    );
  }

  Widget _buildCenterActions() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10, color: Colors.white),
            onPressed: () => _seek(const Duration(seconds: -10)),
          ),
          IconButton(
            icon: Icon(
              _controller?.value.isPlaying ?? false
                  ? Icons.pause
                  : Icons.play_arrow,
              size: 50,
              color: Colors.white,
            ),
            onPressed: _togglePlayPause,
          ),
          IconButton(
            icon: const Icon(Icons.forward_10, color: Colors.white),
            onPressed: () => _seek(const Duration(seconds: 10)),
          ),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return SafeArea(
      child: Container(
        color: Colors.black.withOpacity(0.35),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    if (_isFullScreen) {
                      _toggleFullScreen();
                    } else {
                      Navigator.pop(context);
                    }
                  },
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _isMuted ? Icons.volume_off : Icons.volume_up,
                        color: Colors.white,
                      ),
                      onPressed: _toggleMute,
                    ),
                    IconButton(
                      icon: Icon(
                        _isFullScreen
                            ? Icons.fullscreen_exit
                            : Icons.fullscreen,
                        color: Colors.white,
                      ),
                      onPressed: _toggleFullScreen,
                    ),
                  ],
                ),
              ],
            ),
            const Spacer(),
            _buildProgress(),
            const SizedBox(height: 16),
            if (!widget.isTrailerUrl && kIsWeb)
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 16),
                child: ElevatedButton.icon(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.white10),
                  onPressed: _downloadVideo,
                  icon: const Icon(Icons.download, color: Colors.white),
                  label: const Text("Download",
                      style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    String fmt(Duration d) {
      String two(int n) => n.toString().padLeft(2, '0');
      return "${d.inHours > 0 ? '${two(d.inHours)}:' : ''}${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Slider(
            activeColor: Colors.red,
            inactiveColor: Colors.white54,
            min: 0,
            max: _videoDuration.inSeconds.toDouble(),
            value: _currentPosition.inSeconds
                .clamp(0, _videoDuration.inSeconds)
                .toDouble(),
            onChanged: (v) => _controller?.seekTo(Duration(seconds: v.toInt())),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(fmt(_currentPosition),
                  style: const TextStyle(color: Colors.white)),
              Text(fmt(_videoDuration),
                  style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}

class FullScreenTrailerPage extends StatelessWidget {
  final String trailerUrl;
  final Content content;

  const FullScreenTrailerPage({
    super.key,
    required this.trailerUrl,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: TrailerPage(
                trailerUrl: trailerUrl,
                isTrailerUrl: true,
                content: content,
              ),
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrailerPreview extends StatefulWidget {
  final String? trailerUrl;
  final Content content;

  const TrailerPreview({
    super.key,
    required this.trailerUrl,
    required this.content,
  });

  @override
  State<TrailerPreview> createState() => _TrailerPreviewState();
}

class _TrailerPreviewState extends State<TrailerPreview> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.trailerUrl?.isNotEmpty == true) {
      _init();
    }
  }

  Future<void> _init() async {
    final c = VideoPlayerController.network(widget.trailerUrl!);
    await c.initialize();
    c.setLooping(true);
    setState(() {
      _controller = c;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _openFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenTrailerPage(
          trailerUrl: widget.trailerUrl!,
          content: widget.content,
        ),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (widget.trailerUrl?.isEmpty != false) {
      return const AspectRatio(
        aspectRatio: 16 / 8,
        child: Center(child: Text("No trailer available")),
      );
    }

    return GestureDetector(
      onTap: _openFullScreen,
      child: AspectRatio(
        aspectRatio: 16 / 8,
        child: Container(
          width: double.infinity,
          color: Colors.black,
          child: _initialized
              ? Stack(
                  children: [
                    // Video
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _controller!.value.size.width,
                          height: _controller!.value.size.height,
                          child: VideoPlayer(_controller!),
                        ),
                      ),
                    ),

                    // Play / Pause (center)
                    Center(
                      child: IconButton(
                        iconSize: 48,
                        color: Colors.white,
                        icon: Icon(
                          _controller!.value.isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                        ),
                        onPressed: () {
                          setState(() {
                            _controller!.value.isPlaying
                                ? _controller!.pause()
                                : _controller!.play();
                          });
                        },
                      ),
                    ),

                    // Slider (bottom)
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        _controller!,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.red,
                          bufferedColor: Colors.white54,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
