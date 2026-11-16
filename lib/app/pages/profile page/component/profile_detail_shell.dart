import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';

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

/// Android TV only: compact page header (back button + title + optional
/// trailing actions) used by the profile detail pages instead of their
/// phone app bars. Inside [ProfileDetailShell] the back button pops the
/// shell's local history entry, so it returns to the profile page.
///
/// Callers render it behind `ResponsiveWidget.isAndroidTv(context)`.
class TvDetailHeader extends StatelessWidget {
  const TvDetailHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.onBack,
    this.trailing = const [],
    this.autofocusBack = false,
    this.showBack,
  });

  final String title;
  final String? subtitle;

  /// Custom back action (e.g. a discard-changes prompt). Defaults to
  /// `Navigator.maybePop`; the button is hidden when there is nothing to pop.
  final VoidCallback? onBack;
  final List<Widget> trailing;
  final bool autofocusBack;

  /// Forces the back button on/off; by default it is shown when [onBack] is
  /// set or the navigator can pop.
  final bool? showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack =
        showBack ?? (onBack != null || Navigator.of(context).canPop());
    final goBack = onBack ?? () => Navigator.of(context).maybePop();

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        TvDesign.pageGutter,
        16,
        TvDesign.pageGutter,
        10,
      ),
      child: Row(
        children: [
          if (canGoBack) ...[
            OttTvFocus(
              autofocus: autofocusBack,
              onTap: goBack,
              borderRadius: 8,
              scale: 1.06,
              semanticLabel: 'Back',
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.canvasColor.withValues(alpha: 0.08),
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  size: 18,
                  color: theme.canvasColor,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TvDesign.pageTitle(theme),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TvDesign.caption(theme),
                  ),
                ],
              ],
            ),
          ),
          for (final action in trailing) ...[
            const SizedBox(width: 10),
            action,
          ],
        ],
      ),
    );
  }
}

/// Android TV only: compact button (32 px tall) used across the profile
/// detail pages. A single focus stop that runs [onPressed] on OK.
class TvCompactButton extends StatelessWidget {
  const TvCompactButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
    this.danger = false,
    this.autofocus = false,
    this.loading = false,
    this.expand = false,
    this.focusNode,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool danger;
  final bool autofocus;
  final bool loading;
  final bool expand;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Stays focusable while loading (so focus is not dropped) but ignores OK.
    final enabled = onPressed != null;
    final accent = danger ? Colors.redAccent : theme.primaryColor;
    final filled = primary || danger;
    final foreground = filled ? Colors.white : theme.canvasColor;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
            ),
          )
        else if (icon != null)
          Icon(icon, size: 16, color: foreground),
        if (loading || icon != null) const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );

    return OttTvFocus(
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      onTap: onPressed == null ? null : (loading ? () {} : onPressed),
      borderRadius: 8,
      scale: 1.04,
      semanticLabel: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: filled ? accent : theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: filled
                ? null
                : Border.all(color: theme.canvasColor.withValues(alpha: 0.16)),
          ),
          child: content,
        ),
      ),
    );
  }
}

/// Android TV only: rounded panel surface (card colour, 12 px radius,
/// hairline border) shared by the profile detail pages.
class TvPanel extends StatelessWidget {
  const TvPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(TvDesign.panelRadius),
        border: Border.all(color: theme.canvasColor.withValues(alpha: 0.06)),
      ),
      child: child,
    );
  }
}
