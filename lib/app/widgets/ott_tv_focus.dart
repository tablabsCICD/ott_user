import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/flavor/app_flavor.dart';
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
    this.enabled = true,
    this.onKeyEvent,
    this.alignment,
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
  final bool enabled;
  final FocusOnKeyEventCallback? onKeyEvent;
  final double? alignment;

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
        alignment: widget.alignment ?? 0.0,
        alignmentPolicy: widget.alignment != null
            ? ScrollPositionAlignmentPolicy.explicit
            : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final customResult = widget.onKeyEvent?.call(node, event);
    if (customResult == KeyEventResult.handled ||
        customResult == KeyEventResult.skipRemainingHandlers) {
      return customResult!;
    }
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (widget.enabled &&
        widget.onTap != null &&
        OttTvRemoteKey.activate.contains(key)) {
      widget.onTap?.call();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusColor = widget.focusColor ?? theme.primaryColor;

    final isMobile =
        ResponsiveWidget.isMobile(context) && !FlavorConfig.current.isTv;
    if (isMobile) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: widget.child,
      );
    }

    final focusable = Focus(
      focusNode: _focusNode,
      autofocus: widget.enabled && widget.autofocus,
      canRequestFocus: widget.enabled && widget.onTap != null,
      onKeyEvent: _handleKey,
      child: MouseRegion(
        onEnter: (_) {
          if (widget.enabled && widget.onTap != null) {
            _focusNode.requestFocus();
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.enabled ? widget.onTap : null,
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
                  width: 1,
                ),
                boxShadow: null,
              ),
              child: Focus(
                canRequestFocus: false,
                descendantsAreFocusable: false,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.semanticLabel == null) return focusable;

    return Semantics(
      button: widget.enabled && widget.onTap != null,
      enabled: widget.enabled,
      focusable: widget.enabled && widget.onTap != null,
      label: widget.semanticLabel,
      child: focusable,
    );
  }
}
