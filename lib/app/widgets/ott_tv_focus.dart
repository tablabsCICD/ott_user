import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OttTvFocus extends StatefulWidget {
  const OttTvFocus({
    super.key,
    required this.child,
    this.onTap,
    this.onFocusChange,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.scale = 1.045,
    this.padding = EdgeInsets.zero,
    this.enabled = true,
    this.autofocus = false,
    this.focusNode,
    this.showFocusDecoration = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFocusChange;
  final BorderRadius borderRadius;
  final double scale;
  final EdgeInsetsGeometry padding;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool showFocusDecoration;

  @override
  State<OttTvFocus> createState() => _OttTvFocusState();
}

class _OttTvFocusState extends State<OttTvFocus> {
  bool _focused = false;
  FocusNode? _ownedFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  @override
  void didUpdateWidget(covariant OttTvFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode && widget.focusNode != null) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    }
  }

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange(bool focused) {
    if (_focused == focused) return;
    setState(() => _focused = focused);
    widget.onFocusChange?.call(focused);

    if (focused) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (!widget.enabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;
    if (widget.onTap != null &&
        (key == LogicalKeyboardKey.select ||
            key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.gameButtonA ||
            key == LogicalKeyboardKey.space)) {
      widget.onTap?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final enableTvFocus = _shouldEnableTvFocus(context);
    if (!enableTvFocus) {
      return MouseRegion(
        cursor: widget.enabled && widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: widget.enabled ? widget.onTap : null,
          child: widget.child,
        ),
      );
    }

    final theme = Theme.of(context);
    final glowColor = theme.primaryColor.withValues(alpha: 0.62);

    return Focus(
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      canRequestFocus: widget.enabled,
      descendantsAreFocusable: true,
      onFocusChange: _handleFocusChange,
      onKeyEvent: _handleKey,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enabled) {
            _effectiveFocusNode.requestFocus();
          }
        },
        cursor: widget.enabled && widget.onTap != null
            ? SystemMouseCursors.click
            : MouseCursor.defer,
        child: Semantics(
          button: widget.onTap != null,
          focusable: widget.enabled,
          child: AnimatedScale(
            scale: _focused ? widget.scale : 1,
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: widget.borderRadius,
                border: Border.all(
                  color: widget.showFocusDecoration && _focused
                      ? glowColor
                      : Colors.transparent,
                  width: widget.showFocusDecoration && _focused ? 2 : 0,
                ),
                boxShadow: widget.showFocusDecoration && _focused
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.34),
                          blurRadius: 26,
                          spreadRadius: 1.5,
                        ),
                      ]
                    : null,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

bool _shouldEnableTvFocus(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isTabletOrTv = size.width >= 750;

  return isTabletOrTv &&
      (kIsWeb || defaultTargetPlatform == TargetPlatform.android);
}
