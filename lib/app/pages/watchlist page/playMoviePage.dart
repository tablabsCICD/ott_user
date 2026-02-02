import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/data/models/content.dart';
import '../../core/utils/sharepreferences.dart';

class PlayMediaPage extends StatefulWidget {
  final String title;
  final int mediaId;
  final String videoUrl;
  final Content? content;

  const PlayMediaPage({
    super.key,
    required this.title,
    required this.mediaId,
    required this.videoUrl,
    this.content,
  });

  @override
  State<PlayMediaPage> createState() => _PlayMediaPageState();
}

class _PlayMediaPageState extends State<PlayMediaPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _initPlayer();
    _addViewApi();
  }

  Future<void> _initPlayer() async {
    if (_videoController != null) return;

    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    );

    await _videoController!.initialize();

    _videoController!.addListener(() {
      if (_videoController!.value.isPlaying) {
        WakelockPlus.enable();
      } else {
        WakelockPlus.disable();
      }
    });

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      showControls: true,
      allowFullScreen: true,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      zoomAndPan: true,
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

    setState(() => _loading = false);
  }

  Future<void> _addViewApi() async {
    try {
      final prefs = LocalSharePreferences();
      final user = await prefs.getUser();

      if (user == null || user.id == null) return;

      final isSeries = widget.content?.type?.toLowerCase() == "series";

      final url = isSeries
          ? ApiConstant.addViewForEpisode(widget.mediaId, user.id!)
          : ApiConstant.addViewForMovie(widget.mediaId, user.id!);

      await http.post(Uri.parse(url));
    } catch (_) {}
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: ResponsiveWidget.isDesktop(context)
          ? null
          : AppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              title: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.canvasColor,
                ),
              ),
            ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
              color: theme.primaryColor,
            ))
          : Center(
              child: ResponsiveWidget.isDesktop(context)
                  ? _desktopPlayer()
                  : _mobilePlayer(),
            ),
    );
  }

  Widget _mobilePlayer() {
    return Column(
      children: [
        _playerSurface(),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _desktopPlayer() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(child: _playerSurface()),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _playerSurface() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          Chewie(controller: _chewieController!),

          /// Gesture overlay (Netflix-style)
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
          // Positioned(
          //   top: 10,
          //   right: 10,
          //   child: Container(
          //     height: 30,
          //     width: 30,
          //     decoration: BoxDecoration(
          //       borderRadius: BorderRadius.circular(
          //         25,
          //       ),
          //     ),
          //     child: ClipRRect(
          //       borderRadius: BorderRadiusGeometry.circular(20),
          //       child: Image.asset(
          //         ImageConstant.logo,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
}
