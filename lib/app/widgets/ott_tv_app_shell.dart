import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class OttTvRemoteKey {
  static final Set<LogicalKeyboardKey> up = {
    LogicalKeyboardKey.arrowUp,
  };

  static final Set<LogicalKeyboardKey> down = {
    LogicalKeyboardKey.arrowDown,
  };

  static final Set<LogicalKeyboardKey> left = {
    LogicalKeyboardKey.arrowLeft,
  };

  static final Set<LogicalKeyboardKey> right = {
    LogicalKeyboardKey.arrowRight,
  };

  static final Set<LogicalKeyboardKey> activate = {
    LogicalKeyboardKey.select,
    LogicalKeyboardKey.enter,
    LogicalKeyboardKey.space,
    LogicalKeyboardKey.gameButtonA,
  };

  static final Set<LogicalKeyboardKey> back = {
    LogicalKeyboardKey.escape,
    LogicalKeyboardKey.goBack,
    LogicalKeyboardKey.browserBack,
    LogicalKeyboardKey.gameButtonB,
  };

  static final Set<LogicalKeyboardKey> menu = {
    LogicalKeyboardKey.contextMenu,
    LogicalKeyboardKey.gameButtonStart,
  };

  static final Set<LogicalKeyboardKey> playPause = {
    LogicalKeyboardKey.mediaPlayPause,
    LogicalKeyboardKey.mediaPlay,
    LogicalKeyboardKey.mediaPause,
  };

  static bool isDirectional(LogicalKeyboardKey key) {
    return up.contains(key) ||
        down.contains(key) ||
        left.contains(key) ||
        right.contains(key);
  }
}

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

  KeyEventResult _handleFocusKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    return _moveFocusForKey(event.logicalKey)
        ? KeyEventResult.handled
        : KeyEventResult.ignored;
  }

  bool _moveFocusForKey(LogicalKeyboardKey key) {
    final primaryFocus = FocusManager.instance.primaryFocus;
    if (primaryFocus == null) {
      _keyboardNode.requestFocus();
      return false;
    }

    if (OttTvRemoteKey.up.contains(key)) {
      primaryFocus.focusInDirection(TraversalDirection.up);
      return true;
    } else if (OttTvRemoteKey.down.contains(key)) {
      primaryFocus.focusInDirection(TraversalDirection.down);
      return true;
    } else if (OttTvRemoteKey.left.contains(key)) {
      primaryFocus.focusInDirection(TraversalDirection.left);
      return true;
    } else if (OttTvRemoteKey.right.contains(key)) {
      primaryFocus.focusInDirection(TraversalDirection.right);
      return true;
    } else if (OttTvRemoteKey.back.contains(key)) {
      if (!mounted) return false;
      Navigator.of(context).maybePop();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || ResponsiveWidget.isMobile(context)) {
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
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.goBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonB): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) {
              if (!mounted) return null;
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

    return KeyboardListener(
      focusNode: _keyboardNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          _moveFocusForKey(event.logicalKey);
        }
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _handleFocusKey,
        child: shortcuts,
      ),
    );
  }
}
