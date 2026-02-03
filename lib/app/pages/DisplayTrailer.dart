import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/content.dart';

class TrailerPage extends StatefulWidget {
  final String trailerUrl;
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
  VideoPlayerController? _video;
  ChewieController? _chewie;

  VlcPlayerController? _vlc;

  bool _useVlc = false;
  bool _initialized = false;
  bool _vlcControlsVisible = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), _initChewie);
  }

  // -------------------- CHEWIE (PRIMARY) --------------------

  Future<void> _initChewie() async {
    try {
      _video = VideoPlayerController.networkUrl(Uri.parse(widget.trailerUrl));
      await _video!.initialize();
      _video!.play();
      _video!.addListener(_chewieListener);

      _chewie = ChewieController(
        videoPlayerController: _video!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        showControls: true,
        deviceOrientationsOnEnterFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: const [
          DeviceOrientation.portraitUp,
        ],
      );

      setState(() => _initialized = true);
    } catch (_) {
      _switchToVlc();
    }
  }

  void _chewieListener() {
    final v = _video?.value;
    if (v == null) return;

    if (v.hasError) {
      _switchToVlc();
      return;
    }

    if (v.isPlaying) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  // -------------------- VLC FALLBACK --------------------

  Future<void> _switchToVlc() async {
    if (_useVlc) return;

    await _video?.dispose();
     _chewie?.dispose();
    _video = null;
    _chewie = null;

    _vlc = VlcPlayerController.network(
      widget.trailerUrl,
      hwAcc: HwAcc.disabled, // 🚨 software decode
      autoPlay: true,
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(1500),
        ]),
      ),
    );

    setState(() {
      _useVlc = true;
      _initialized = true;
    });
  }

  // -------------------- UI --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Center(
            child: _useVlc ? _vlcSurface() : _chewieSurface(),
          ),
          SafeArea(
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chewieSurface() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Chewie(controller: _chewie!),
    );
  }

  Widget _vlcSurface() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          VlcPlayer(
            controller: _vlc!,
            aspectRatio: 16 / 9,
            placeholder: const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            ),
          ),

          // Gestures
          Positioned.fill(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _vlcControlsVisible = !_vlcControlsVisible),
              onDoubleTapDown: (d) {
                final box = context.findRenderObject() as RenderBox;
                final local = box.globalToLocal(d.globalPosition);
                final isLeft = local.dx < box.size.width / 2;
                final pos = _vlc!.value.position;
                _vlc!.seekTo(
                  pos + (isLeft
                      ? const Duration(seconds: -10)
                      : const Duration(seconds: 10)),
                );
              },
              onLongPressStart: (_) => _vlc!.setPlaybackSpeed(2),
              onLongPressEnd: (_) => _vlc!.setPlaybackSpeed(1),
            ),
          ),

          if (_vlcControlsVisible) ...[
            Positioned.fill(
              child: Container(color: Colors.black.withOpacity(0.35)),
            ),
            Center(
              child: IconButton(
                iconSize: 56,
                color: Colors.white,
                icon: Icon(
                  _vlc!.value.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                ),
                onPressed: () {
                  _vlc!.value.isPlaying ? _vlc!.pause() : _vlc!.play();
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _video?.dispose();
    _chewie?.dispose();
    _vlc?.dispose();
    WakelockPlus.disable();
    super.dispose();
  }
}


class TrailerPreview extends StatelessWidget {
  final String? trailerUrl;
  final Content content;

  const TrailerPreview({
    super.key,
    required this.trailerUrl,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          // Thumbnail (replace with your real image)
          Container(
            color: Colors.black,
            child: const Center(
              child: Icon(Icons.movie, color: Colors.white54, size: 48),
            ),
          ),

          // Play button
          Center(
            child: IconButton(
              iconSize: 56,
              icon: const Icon(Icons.play_circle_fill, color: Colors.white),
              onPressed: () {
                if (trailerUrl == null) return;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TrailerPage(
                      trailerUrl: trailerUrl!,
                      isTrailerUrl: true,
                      content: content,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
