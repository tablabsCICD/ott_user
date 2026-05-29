import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class OttTvAppShell extends StatefulWidget {
  const OttTvAppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<OttTvAppShell> createState() => _OttTvAppShellState();
}

class _OttTvAppShellState extends State<OttTvAppShell> {
  final FocusNode _keyboardNode = FocusNode(debugLabel: 'ott-tv-keyboard');

  @override
  void dispose() {
    _keyboardNode.dispose();
    super.dispose();
  }

  void _handleRawKey(RawKeyEvent event) {
    if (event is! RawKeyDownEvent) return;

    _moveFocusForKey(event.logicalKey);
  }

  KeyEventResult _handleFocusKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    return _moveFocusForKey(event.logicalKey)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  bool _moveFocusForKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowUp) {
      FocusManager.instance.primaryFocus
          ?.focusInDirection(TraversalDirection.up);
      return true;
    } else if (key == LogicalKeyboardKey.arrowDown) {
      FocusManager.instance.primaryFocus
          ?.focusInDirection(TraversalDirection.down);
      return true;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      FocusManager.instance.primaryFocus
          ?.focusInDirection(TraversalDirection.left);
      return true;
    } else if (key == LogicalKeyboardKey.arrowRight) {
      FocusManager.instance.primaryFocus
          ?.focusInDirection(TraversalDirection.right);
      return true;
    } else if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      Navigator.of(context).maybePop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isMobile(context)) {
      return widget.child;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && FocusManager.instance.primaryFocus == null) {
        _keyboardNode.requestFocus();
      }
    });

    final shortcuts = Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowUp):
            DirectionalFocusIntent(TraversalDirection.up),
        SingleActivator(LogicalKeyboardKey.arrowDown):
            DirectionalFocusIntent(TraversalDirection.down),
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            DirectionalFocusIntent(TraversalDirection.left),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            DirectionalFocusIntent(TraversalDirection.right),
        SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.goBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              Navigator.of(context).maybePop();
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: FocusScope(
            autofocus: true,
            child: widget.child,
          ),
        ),
      ),
    );

    return RawKeyboardListener(
      focusNode: _keyboardNode,
      autofocus: true,
      onKey: _handleRawKey,
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleFocusKey,
        child: shortcuts,
      ),
    );
  }
}
