import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class CustomMaterialControlsWithSpacing extends StatefulWidget {
  final ChewieController Function() controllerGetter;

  const CustomMaterialControlsWithSpacing({
    super.key,
    required this.controllerGetter,
  });

  @override
  State<CustomMaterialControlsWithSpacing> createState() =>
      _CustomMaterialControlsWithSpacingState();
}

class _CustomMaterialControlsWithSpacingState
    extends State<CustomMaterialControlsWithSpacing> {
  late ChewieController _chewie;
  late VideoPlayerController _video;
  late VoidCallback _listener;

  @override
  void initState() {
    super.initState();
    _chewie = widget.controllerGetter();
    _video = _chewie.videoPlayerController;

    // Rebuild UI when video updates
    _listener = () => setState(() {});
    _video.addListener(_listener);
  }

  @override
  void dispose() {
    _video.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          VideoProgressIndicator(
            _video,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            colors: const VideoProgressColors(
              playedColor: Colors.blue,
              bufferedColor: Colors.blueGrey,
              backgroundColor: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  _video.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: () {
                  _video.value.isPlaying ? _video.pause() : _video.play();
                },
              ),
              Text(
                _formatDuration(_video.value.position),
                style: const TextStyle(color: Colors.white),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    useRootNavigator: _chewie.useRootNavigator,
                    builder: (_) => _buildSettingsSheet(context),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.fullscreen, color: Colors.white),
                onPressed: _chewie.enterFullScreen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSheet(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        shrinkWrap: true,
        children: [
          const Text('Playback Speed',
              style: TextStyle(fontWeight: FontWeight.bold)),
          ...[0.5, 1.0, 1.5, 2.0].map(
                (speed) => ListTile(
              title: Text('${speed}×'),
              onTap: () {
                _video.setPlaybackSpeed(speed);
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
