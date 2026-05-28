import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OttTvAppShell extends StatelessWidget {
  const OttTvAppShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final enableTvControls = _shouldEnableTvControls(context);
    if (!enableTvControls) {
      return ScrollConfiguration(
        behavior: const _OttTvScrollBehavior(),
        child: child,
      );
    }

    return Shortcuts(
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
        SingleActivator(LogicalKeyboardKey.numpadEnter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.gameButtonA): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.goBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.browserBack): DismissIntent(),
        SingleActivator(LogicalKeyboardKey.escape): DismissIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (intent) {
              final navigator = Navigator.maybeOf(context);
              navigator?.maybePop();
              return null;
            },
          ),
        },
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: FocusScope(
            autofocus: true,
            child: ScrollConfiguration(
              behavior: const _OttTvScrollBehavior(),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

bool _shouldEnableTvControls(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final isTabletOrTv = size.width >= 750;

  if (kIsWeb) {
    return isTabletOrTv;
  }

  return defaultTargetPlatform == TargetPlatform.android && isTabletOrTv;
}

class _OttTvScrollBehavior extends MaterialScrollBehavior {
  const _OttTvScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
