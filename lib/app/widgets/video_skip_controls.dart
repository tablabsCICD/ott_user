import 'dart:async';

import 'package:flutter/material.dart';

Duration boundedSeekPosition({
  required Duration position,
  required Duration duration,
  required Duration offset,
}) {
  final target = position + offset;
  if (target <= Duration.zero) return Duration.zero;
  if (duration > Duration.zero && target >= duration) return duration;
  return target;
}

class VideoSkipControls extends StatelessWidget {
  const VideoSkipControls({
    super.key,
    required this.onBackward,
    required this.onForward,
    this.gap = 64,
    this.compact = false,
    this.foregroundColor = Colors.white,
  });

  final FutureOr<void> Function() onBackward;
  final FutureOr<void> Function() onForward;
  final double gap;
  final bool compact;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedSkipButton(
          icon: Icons.replay_10_rounded,
          semanticsLabel: 'Skip backward 10 seconds',
          onPressed: onBackward,
          compact: compact,
          foregroundColor: foregroundColor,
        ),
        SizedBox(width: gap),
        _AnimatedSkipButton(
          icon: Icons.forward_10_rounded,
          semanticsLabel: 'Skip forward 10 seconds',
          onPressed: onForward,
          compact: compact,
          foregroundColor: foregroundColor,
        ),
      ],
    );
  }
}

class _AnimatedSkipButton extends StatefulWidget {
  const _AnimatedSkipButton({
    required this.icon,
    required this.semanticsLabel,
    required this.onPressed,
    required this.compact,
    required this.foregroundColor,
  });

  final IconData icon;
  final String semanticsLabel;
  final FutureOr<void> Function() onPressed;
  final bool compact;
  final Color foregroundColor;

  @override
  State<_AnimatedSkipButton> createState() => _AnimatedSkipButtonState();
}

class _AnimatedSkipButtonState extends State<_AnimatedSkipButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (mounted && _pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.compact ? 42.0 : 50.0;
    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: AnimatedScale(
        scale: _pressed ? 0.86 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: _pressed ? 0.72 : 0.48),
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.foregroundColor.withValues(alpha: 0.38),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => widget.onPressed(),
              onTapDown: (_) => _setPressed(true),
              onTapUp: (_) => _setPressed(false),
              onTapCancel: () => _setPressed(false),
              child: Icon(
                widget.icon,
                color: widget.foregroundColor,
                size: widget.compact ? 27 : 32,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
