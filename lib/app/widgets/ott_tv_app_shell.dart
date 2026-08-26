import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/flavor/app_flavor.dart';

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

  static final Set<LogicalKeyboardKey> rewind = {
    LogicalKeyboardKey.mediaRewind,
  };

  static final Set<LogicalKeyboardKey> fastForward = {
    LogicalKeyboardKey.mediaFastForward,
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

  void _dismissKeyboardOrRoute() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final focusContext = primaryFocus?.context;
    final editingText = focusContext?.widget is EditableText ||
        focusContext?.findAncestorWidgetOfExactType<EditableText>() != null;
    if (editingText) {
      primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      return;
    }
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isMobile(context) && !FlavorConfig.current.isTv) {
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
              _dismissKeyboardOrRoute();
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

    // One focus/shortcut layer owns remote traversal. Avoid parallel raw-key
    // listeners, which can turn a single D-pad press into two actions.
    return Focus(
      focusNode: _keyboardNode,
      autofocus: true,
      child: shortcuts,
    );
  }
}
