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
  static const Duration _displayDuration = Duration(seconds: 10);
  static const Duration _displayInterval = Duration(minutes: 30);
  static const List<Alignment> _positions = [
    Alignment.topLeft,
    Alignment.topRight,
    Alignment.centerLeft,
    Alignment.centerRight,
    Alignment.bottomLeft,
    Alignment.bottomRight,
    Alignment.center,
  ];

  Timer? _intervalTimer;
  Timer? _hideTimer;
  int _positionIndex = 0;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
    _intervalTimer = Timer.periodic(_displayInterval, (_) => _showWatermark());
  }

  void _showWatermark() {
    if (!mounted) return;
    _hideTimer?.cancel();
    setState(() {
      _positionIndex = (_positionIndex + 1) % _positions.length;
      _isVisible = true;
    });
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_displayDuration, () {
      if (mounted) setState(() => _isVisible = false);
    });
  }

  @override
  void dispose() {
    _intervalTimer?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

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
