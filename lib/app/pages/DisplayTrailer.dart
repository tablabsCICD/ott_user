import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:universal_html/html.dart' as html;

import '../../data/models/content.dart';
import '../../data/models/user.dart';
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
// ... (imports and class declarations remain the same)

class _TrailerPageState extends State<TrailerPage> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isMuted = false;
  bool _viewHistorySaved = false;
  bool _showControls = true;
  Timer? _hideControlsTimer;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _enterFullScreen();
    if (_hasValidUrl) _initializeVideoPlayer();
  }

  bool get _hasValidUrl => widget.trailerUrl?.isNotEmpty == true;

  Future<void> _initializeVideoPlayer() async {
    try {
      final controller = VideoPlayerController.network(widget.trailerUrl!);
      await controller.initialize();
      controller.setLooping(false);
      controller.play();

      controller.addListener(() {
        final position = controller.value.position;
        final duration = controller.value.duration;

        if (mounted) {
          setState(() {
            _currentPosition = position;
            _videoDuration = duration;
          });
        }

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
      debugPrint('Error initializing video player: $e');
    }
  }

  void _startAutoHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      setState(() => _showControls = false);
    });
  }

  void _onInteraction() {
    setState(() => _showControls = true);
    _startAutoHideTimer();
  }

  Future<void> _saveViewHistory() async {
    try {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (user == null) return;

      final resumeTime = _controller?.value.position.toString() ?? "0:00";

      final data = {
        "contentId": widget.content.id,
        "resumeTime": resumeTime,
        "selectedLanguage": widget.content.languageList?.first ?? "Unknown",
        "userId": user.id,
        "viewDate": DateTime.now().toUtc().toIso8601String(),
      };

      final response =
          await ApiHelper().postApiWithBody(ApiConstant.saveViewHistory, data);

      if (response.statusCode == 200) {
        final result = SaveViewHistory.fromJson(json.decode(response.body));
        if (!result.success!) {
          debugPrint("Failed to save history: ${result.message}");
        }
      } else {
        debugPrint("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error saving view history: $e");
    }
  }

  void _seek(Duration offset) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    final current = controller.value.position;
    final total = controller.value.duration;
    final targetSeconds =
        (current + offset).inSeconds.clamp(0, total.inSeconds);

    controller.seekTo(Duration(seconds: targetSeconds));
  }

  void _toggleMute() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  void _togglePlayPause() {
    final controller = _controller;
    if (controller == null) return;

    setState(() {
      controller.value.isPlaying ? controller.pause() : controller.play();
    });
  }

  void _downloadVideo() {
    if (_hasValidUrl) {
      final filename = Uri.parse(widget.trailerUrl!).pathSegments.last;
      final anchor = html.AnchorElement(href: widget.trailerUrl)
        ..target = 'blank'
        ..download = filename
        ..click();
    } else {
      CustomToast.show(context, "No video URL available to download.",
          isSuccess: false);
    }
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
      DeviceOrientation.portraitDown,
    ]);
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
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            _buildVideoPlayer(),
            if (_showControls) _buildOverlayControls(),
            if (_showControls)
              Center(
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
                        color: Colors.white,
                        size: 50,
                      ),
                      onPressed: _togglePlayPause,
                    ),
                    IconButton(
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      onPressed: () => _seek(const Duration(seconds: 10)),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    if (!_hasValidUrl) {
      return const Center(
        child: Text(
          "No trailer available.",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Center(
      child: _isInitialized
          ? AspectRatio(
              aspectRatio: _controller!.value.aspectRatio,
              child: VideoPlayer(_controller!),
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildOverlayControls() {
    String formatDuration(Duration duration) {
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final minutes = twoDigits(duration.inMinutes.remainder(60));
      final seconds = twoDigits(duration.inSeconds.remainder(60));
      return "${duration.inHours > 0 ? '${twoDigits(duration.inHours)}:' : ''}$minutes:$seconds";
    }

    return SafeArea(
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: Column(
          children: [
            // Top bar with back and mute
            Align(
              alignment: Alignment.topLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                    ),
                    onPressed: _toggleMute,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Time slider + label
            Padding(
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
                    onChanged: (value) {
                      final newPosition = Duration(seconds: value.toInt());
                      _controller?.seekTo(newPosition);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        formatDuration(_currentPosition),
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        formatDuration(_videoDuration),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Download button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!widget.isTrailerUrl)
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white10),
                      onPressed: _downloadVideo,
                      icon: const Icon(Icons.download, color: Colors.white),
                      label: const Text("Download",
                          style: TextStyle(color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
