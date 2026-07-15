import 'dart:async';

import 'package:flutter/material.dart';

import 'package:ott/data/models/anti_piracy_models.dart';

class PlaybackWatermarkOverlay extends StatefulWidget {
  const PlaybackWatermarkOverlay({
    super.key,
    required this.watermark,
  });

  final WatermarkData watermark;

  @override
  State<PlaybackWatermarkOverlay> createState() =>
      _PlaybackWatermarkOverlayState();
}

class _PlaybackWatermarkOverlayState extends State<PlaybackWatermarkOverlay> {
  static const List<Alignment> _positions = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
    Alignment.center,
  ];

  Timer? _timer;
  int _positionIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      setState(() {
        _positionIndex = (_positionIndex + 1) % _positions.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        minimum: const EdgeInsets.all(28),
        child: AnimatedAlign(
          alignment: _positions[_positionIndex],
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                widget.watermark.displayText,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.58),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                  shadows: const [
                    Shadow(
                      blurRadius: 2,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
