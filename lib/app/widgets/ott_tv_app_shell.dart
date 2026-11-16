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

/// Pins the Android TV app to a fixed design canvas so that fonts, cards,
/// spacing and icons have the same physical size on every TV.
///
/// Android TVs report very different pixel densities for the same 1080p
/// panel (for example 960x540, 1280x720 or 1920x1080 logical pixels), which
/// otherwise makes the whole UI look tiny on some TVs and huge on others.
/// This lays the app out at [designHeight] logical pixels tall (the width
/// follows the screen's aspect ratio) and scales it uniformly to fill the
/// screen. On TVs that already report 540 logical pixels it is a no-op.
class TvDesignViewport extends StatelessWidget {
  const TvDesignViewport({super.key, required this.child});

  /// Logical height the TV UI is designed for (1080p at 2x density).
  static const double designHeight = 540;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    if (size.isEmpty) return child;

    final scale = size.height / designHeight;
    if ((scale - 1).abs() < 0.01) return child;

    final designSize = Size(size.width / scale, designHeight);
    EdgeInsets unscale(EdgeInsets insets) => insets / scale;

    return FittedBox(
      fit: BoxFit.fill,
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: designSize.width,
        height: designSize.height,
        child: MediaQuery(
          data: mediaQuery.copyWith(
            size: designSize,
            // Keep images and text rasterised at the panel's real resolution.
            devicePixelRatio: mediaQuery.devicePixelRatio * scale,
            padding: unscale(mediaQuery.padding),
            viewPadding: unscale(mediaQuery.viewPadding),
            viewInsets: unscale(mediaQuery.viewInsets),
            systemGestureInsets: unscale(mediaQuery.systemGestureInsets),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Android TV: gives every standard Material control a clearly visible focus
/// ring (buttons, icon buttons, list tiles, chips, popup items) so the remote
/// cursor is easy to find even on screens that don't use [OttTvFocus].
/// Only the focused state is changed; all other styling is preserved.
ThemeData tvFocusTheme(ThemeData theme) {
  // Neutral outline that reads on every surface, including brand-red filled
  // buttons: white on the dark theme, near-black on the light theme.
  final ringColor = theme.brightness == Brightness.dark
      ? Colors.white
      : const Color(0xFF111111);
  final ring = BorderSide(color: ringColor, width: 2);
  final focusFill = ringColor.withValues(alpha: 0.16);

  ButtonStyle withRing(ButtonStyle? base) {
    return (base ?? const ButtonStyle()).copyWith(
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return ring;
        return base?.side?.resolve(states);
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) return focusFill;
        return base?.overlayColor?.resolve(states);
      }),
    );
  }

  return theme.copyWith(
    focusColor: focusFill,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: withRing(theme.elevatedButtonTheme.style),
    ),
    textButtonTheme: TextButtonThemeData(
      style: withRing(theme.textButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: withRing(theme.outlinedButtonTheme.style),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: withRing(theme.filledButtonTheme.style),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: withRing(theme.iconButtonTheme.style),
    ),
  );
}
