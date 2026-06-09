import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:ott/app/core/services/anti_piracy_service.dart';

class PlaybackWatermarkOverlay extends StatefulWidget {
  const PlaybackWatermarkOverlay({
    super.key,
    required this.identity,
  });

  final WatermarkIdentity identity;

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

  final DateFormat _timestampFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
  Timer? _timer;
  int _positionIndex = 0;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (!mounted) return;
      setState(() {
        _positionIndex = (_positionIndex + 1) % _positions.length;
        _now = DateTime.now();
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
    final lines = [
      //  'User: ${widget.identity.userId}',
      widget.identity.email,
      // _timestampFormat.format(_now),
    ];

    return IgnorePointer(
      child: SafeArea(
        minimum: const EdgeInsets.all(28),
        child: AnimatedAlign(
          alignment: _positions[_positionIndex],
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.22),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              child: Text(
                lines.join('\n'),
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
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
