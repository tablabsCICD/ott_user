import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:ott/app/widgets/ott_tv_app_shell.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
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
    final isAndroidTv = ResponsiveWidget.isAndroidTv(context);
    // Android TV: a neutral outline (white on dark, near-black on light)
    // reads on the page and on brand-red buttons alike (a red ring
    // disappears on red controls).
    final focusColor = widget.focusColor ??
        (isAndroidTv ? TvDesign.focusRingColor(theme) : theme.primaryColor);

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
                  color: _focused && !isAndroidTv
                      ? focusColor
                      : Colors.transparent,
                  width: 1,
                ),
                // Android TV: focused controls lift off the page.
                boxShadow: _focused && isAndroidTv
                    ? TvDesign.controlShadowFor(theme)
                    : null,
              ),
              // Android TV: a crisp outline that is easy to spot from the
              // sofa. Painted on top so it never changes the layout size.
              foregroundDecoration: _focused && isAndroidTv
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      border: Border.all(color: focusColor, width: 2),
                    )
                  : null,
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

/// A focusable card with one secondary action (e.g. bookmark, delete,
/// share) that is drawn inside the card.
///
/// Flutter's directional focus can never move from a card to a control
/// inside it, so on TV such buttons are unreachable. Here the card stays a
/// single focus stop: pressing [actionDirection] (towards the button)
/// selects the action, OK runs it, and the opposite arrow returns to the
/// card. Any other arrow leaves the card as usual. On mobile it behaves like
/// a plain [OttTvFocus].
class OttTvActionCard extends StatefulWidget {
  const OttTvActionCard({
    super.key,
    required this.builder,
    required this.onTap,
    required this.onAction,
    this.actionDirection = TraversalDirection.up,
    this.borderRadius = 14,
    this.scale = 1.04,
    this.semanticLabel,
    this.autofocus = false,
  });

  /// Builds the card. `actionSelected` is true while the remote has the
  /// secondary action selected — use [OttTvActionHighlight] on the button.
  final Widget Function(BuildContext context, bool actionSelected) builder;
  final VoidCallback? onTap;
  final VoidCallback? onAction;
  final TraversalDirection actionDirection;
  final double borderRadius;
  final double scale;
  final String? semanticLabel;
  final bool autofocus;

  @override
  State<OttTvActionCard> createState() => _OttTvActionCardState();
}

class _OttTvActionCardState extends State<OttTvActionCard> {
  bool _actionSelected = false;

  LogicalKeyboardKey _keyFor(TraversalDirection direction) {
    switch (direction) {
      case TraversalDirection.up:
        return LogicalKeyboardKey.arrowUp;
      case TraversalDirection.down:
        return LogicalKeyboardKey.arrowDown;
      case TraversalDirection.left:
        return LogicalKeyboardKey.arrowLeft;
      case TraversalDirection.right:
        return LogicalKeyboardKey.arrowRight;
    }
  }

  LogicalKeyboardKey get _towardsAction => _keyFor(widget.actionDirection);

  LogicalKeyboardKey get _backToCard {
    switch (widget.actionDirection) {
      case TraversalDirection.up:
        return LogicalKeyboardKey.arrowDown;
      case TraversalDirection.down:
        return LogicalKeyboardKey.arrowUp;
      case TraversalDirection.left:
        return LogicalKeyboardKey.arrowRight;
      case TraversalDirection.right:
        return LogicalKeyboardKey.arrowLeft;
    }
  }

  void _setSelected(bool value) {
    if (_actionSelected == value || !mounted) return;
    setState(() => _actionSelected = value);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onAction == null) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (!_actionSelected && key == _towardsAction) {
      _setSelected(true);
      return KeyEventResult.handled;
    }
    if (_actionSelected && key == _backToCard) {
      _setSelected(false);
      return KeyEventResult.handled;
    }
    if (_actionSelected && OttTvRemoteKey.isDirectional(key)) {
      // Leaving the card in another direction: drop the selection.
      _setSelected(false);
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return OttTvFocus(
      autofocus: widget.autofocus,
      borderRadius: widget.borderRadius,
      scale: widget.scale,
      semanticLabel: widget.semanticLabel,
      onTap: () {
        if (_actionSelected) {
          widget.onAction?.call();
        } else {
          widget.onTap?.call();
        }
      },
      onKeyEvent: _handleKey,
      onFocusChange: (focused) {
        if (!focused) _setSelected(false);
      },
      child: widget.builder(context, _actionSelected),
    );
  }
}

/// Visible ring around a secondary action while [OttTvActionCard] has it
/// selected. Painted on top, so it never changes the layout.
class OttTvActionHighlight extends StatelessWidget {
  const OttTvActionHighlight({
    super.key,
    required this.selected,
    required this.child,
    this.borderRadius = 18,
  });

  final bool selected;
  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).primaryColor;
    return AnimatedScale(
      scale: selected ? 1.15 : 1,
      duration: const Duration(milliseconds: 140),
      child: Container(
        foregroundDecoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: Colors.white, width: 2),
              )
            : null,
        decoration: selected
            ? BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(borderRadius),
              )
            : null,
        child: child,
      ),
    );
  }
}

/// Like [OttTvActionCard] but with several inline actions laid out in a row
/// (e.g. Copy / Share). [actionDirection] selects the first action,
/// Left/Right move between actions, the opposite arrow returns to the card.
class OttTvActionsCard extends StatefulWidget {
  const OttTvActionsCard({
    super.key,
    required this.builder,
    required this.onTap,
    required this.actions,
    this.actionDirection = TraversalDirection.down,
    this.borderRadius = 14,
    this.scale = 1.02,
    this.semanticLabel,
  });

  /// `selectedAction` is the index of the selected action, or null while the
  /// card itself is selected.
  final Widget Function(BuildContext context, int? selectedAction) builder;
  final VoidCallback? onTap;
  final List<VoidCallback> actions;
  final TraversalDirection actionDirection;
  final double borderRadius;
  final double scale;
  final String? semanticLabel;

  @override
  State<OttTvActionsCard> createState() => _OttTvActionsCardState();
}

class _OttTvActionsCardState extends State<OttTvActionsCard> {
  int? _selected;

  void _select(int? index) {
    if (_selected == index || !mounted) return;
    setState(() => _selected = index);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.actions.isEmpty) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final towards = widget.actionDirection == TraversalDirection.up
        ? LogicalKeyboardKey.arrowUp
        : LogicalKeyboardKey.arrowDown;
    final back = widget.actionDirection == TraversalDirection.up
        ? LogicalKeyboardKey.arrowDown
        : LogicalKeyboardKey.arrowUp;
    final selected = _selected;

    if (selected == null) {
      if (key == towards) {
        _select(0);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == back) {
      _select(null);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight &&
        selected < widget.actions.length - 1) {
      _select(selected + 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && selected > 0) {
      _select(selected - 1);
      return KeyEventResult.handled;
    }
    if (OttTvRemoteKey.isDirectional(key)) _select(null);
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return OttTvFocus(
      borderRadius: widget.borderRadius,
      scale: widget.scale,
      semanticLabel: widget.semanticLabel,
      onTap: () {
        final selected = _selected;
        if (selected != null && selected < widget.actions.length) {
          widget.actions[selected]();
        } else {
          widget.onTap?.call();
        }
      },
      onKeyEvent: _handleKey,
      onFocusChange: (focused) {
        if (!focused) _select(null);
      },
      child: widget.builder(context, _selected),
    );
  }
}

/// Android TV: lets the remote scroll a page whose content is mostly text
/// (nothing focusable to move to). Up/Down scroll the page; at the bottom,
/// Down moves on to the first focusable control (e.g. attachments).
/// The scrollable inside must be vertical and use the primary scroll
/// controller (the default for a ListView / SingleChildScrollView without
/// an explicit controller). On other platforms [child] is returned as is.
class OttTvKeyScroll extends StatefulWidget {
  const OttTvKeyScroll({super.key, required this.child, this.step = 120});

  final Widget child;
  final double step;

  @override
  State<OttTvKeyScroll> createState() => _OttTvKeyScrollState();
}

class _OttTvKeyScrollState extends State<OttTvKeyScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Only scroll while this page itself has focus, not a child control.
    if (FocusManager.instance.primaryFocus != node ||
        !_controller.hasClients) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final position = _controller.position;
    double? target;
    if (key == LogicalKeyboardKey.arrowDown) {
      if (position.pixels >= position.maxScrollExtent - 1) {
        node.nextFocus();
        return KeyEventResult.handled;
      }
      target = position.pixels + widget.step;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      target = position.pixels - widget.step;
    }
    if (target == null) return KeyEventResult.ignored;
    _controller.animateTo(
      target.clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOut,
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    if (!ResponsiveWidget.isAndroidTv(context)) return widget.child;
    return Focus(
      autofocus: true,
      onKeyEvent: _handleKey,
      child: PrimaryScrollController(
        controller: _controller,
        child: widget.child,
      ),
    );
  }
}
