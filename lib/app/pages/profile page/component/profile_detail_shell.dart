import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileDetailShell extends StatefulWidget {
  const ProfileDetailShell({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;

  @override
  State<ProfileDetailShell> createState() => _ProfileDetailShellState();
}

class _ProfileDetailShellState extends State<ProfileDetailShell> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) widget.onBack();
      },
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): widget.onBack,
          const SingleActivator(LogicalKeyboardKey.goBack): widget.onBack,
          const SingleActivator(LogicalKeyboardKey.browserBack): widget.onBack,
        },
        child: FocusTraversalGroup(
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute<void>(
              builder: (_) => _ProfileDetailRouteBody(
                onBack: widget.onBack,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileDetailRouteBody extends StatefulWidget {
  const _ProfileDetailRouteBody({
    required this.onBack,
    required this.child,
  });

  final VoidCallback onBack;
  final Widget child;

  @override
  State<_ProfileDetailRouteBody> createState() =>
      _ProfileDetailRouteBodyState();
}

class _ProfileDetailRouteBodyState extends State<_ProfileDetailRouteBody> {
  bool _historyAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_historyAdded) return;
    _historyAdded = true;
    ModalRoute.of(context)?.addLocalHistoryEntry(
      LocalHistoryEntry(onRemove: widget.onBack),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
