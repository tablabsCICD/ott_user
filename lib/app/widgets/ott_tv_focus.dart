import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/widgets/ott_tv_app_shell.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class OttTvFocus extends StatefulWidget {
  const OttTvFocus({
    super.key,
    required this.child,
    this.onTap,
    this.focusNode,
    this.borderRadius = 14,
    this.autofocus = false,
    this.scale = 1.04,
    this.padding = EdgeInsets.zero,
    this.focusColor,
    this.semanticLabel,
    this.onFocusChange,
  });

  final Widget child;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final double borderRadius;
  final bool autofocus;
  final double scale;
  final EdgeInsetsGeometry padding;
  final Color? focusColor;
  final String? semanticLabel;
  final ValueChanged<bool>? onFocusChange;

  @override
  State<OttTvFocus> createState() => _OttTvFocusState();
}

class _OttTvFocusState extends State<OttTvFocus> {
  late FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'ott-tv-focus');
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant OttTvFocus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == widget.focusNode) return;

    _focusNode.removeListener(_handleFocusChanged);
    if (oldWidget.focusNode == null) {
      _focusNode.dispose();
    }
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'ott-tv-focus');
    _focusNode.addListener(_handleFocusChanged);
    _focused = _focusNode.hasFocus;
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!mounted) return;
    setState(() => _focused = _focusNode.hasFocus);
    widget.onFocusChange?.call(_focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (widget.onTap != null && OttTvRemoteKey.activate.contains(key)) {
      widget.onTap?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusColor = widget.focusColor ?? theme.primaryColor;

    if (ResponsiveWidget.isMobile(context)) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: widget.child,
      );
    }

    final focusable = Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKey,
      child: MouseRegion(
        onEnter: (_) => _focusNode.requestFocus(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _focused ? widget.scale : 1,
            duration: const Duration(milliseconds: 170),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 170),
              curve: Curves.easeOutCubic,
              padding: widget.padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: _focused ? focusColor : Colors.transparent,
                  width: 2,
                ),
                boxShadow: _focused
                    ? [
                        BoxShadow(
                          color: focusColor.withValues(alpha: 0.36),
                          blurRadius: 16,
                          spreadRadius: 1,
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

    if (widget.semanticLabel == null) return focusable;

    return Semantics(
      button: widget.onTap != null,
      focusable: true,
      label: widget.semanticLabel,
      child: focusable,
    );
  }
}
