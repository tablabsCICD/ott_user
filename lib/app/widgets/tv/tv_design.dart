import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Android TV design system for Filmytell.
///
/// Values are logical pixels of the TV design canvas: [TvDesignViewport]
/// (ott_tv_app_shell.dart) lays the app out 540 px tall and scales it to the
/// panel, so the same numbers give identical proportions on 720p, 1080p and
/// 4K TVs (a 16:9 TV is ~960 x 540 here).
///
/// Movie cards keep their existing horizontal design size and are scaled by
/// [TvCardScale]; this file only provides the shared look (spacing, type,
/// focus treatment). Everything here is used behind
/// `ResponsiveWidget.isAndroidTv(context)`, so mobile/iOS/web are untouched.
class TvDesign {
  const TvDesign._();

  // Layout -------------------------------------------------------------------

  /// Collapsed navigation rail (icons only).
  static const double railWidth = 56;

  /// Expanded navigation rail (icons + labels), drawn over the content.
  static const double railExpandedWidth = 184;

  /// Horizontal page gutter inside the content area (TV safe area).
  static const double pageGutter = 20;

  /// Movie imagery is standardised to 16:9.
  static const double imageAspectRatio = 16 / 9;

  static const double cardRadius = 10;
  static const double panelRadius = 12;

  // Focus --------------------------------------------------------------------

  /// Kept small so a focused card stays inside its existing slot (cards have
  /// a 5 px side margin at design size) — no overlap, no layout shift.
  static const double cardFocusScale = 1.035;
  static const Duration focusDuration = Duration(milliseconds: 180);
  static const Curve focusCurve = Curves.easeOutCubic;
  static const Color focusRing = Colors.white;
  static const double focusRingWidth = 2;

  static const List<BoxShadow> focusShadow = [
    BoxShadow(
      color: Color(0xB3000000),
      blurRadius: 22,
      spreadRadius: 1,
      offset: Offset(0, 10),
    ),
  ];

  static bool _isDark(ThemeData theme) => theme.brightness == Brightness.dark;

  /// Focus outline that contrasts with the theme's background: white on the
  /// dark theme, near-black on the light theme.
  static Color focusRingColor(ThemeData theme) =>
      _isDark(theme) ? Colors.white : const Color(0xFF111111);

  /// Focus lift that stays visible in both themes. On the dark theme a black
  /// shadow alone disappears into the background, so a faint white glow is
  /// added; on the light theme a softer black shadow is enough.
  static List<BoxShadow> focusShadowFor(ThemeData theme) => _isDark(theme)
      ? const [
          BoxShadow(
            color: Color(0xB3000000),
            blurRadius: 22,
            spreadRadius: 1,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Color(0x2EFFFFFF),
            blurRadius: 16,
            spreadRadius: 0.5,
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x47000000),
            blurRadius: 18,
            spreadRadius: 0.5,
            offset: Offset(0, 8),
          ),
        ];

  /// Lighter variant for small controls (buttons, chips, list rows).
  static List<BoxShadow> controlShadowFor(ThemeData theme) => _isDark(theme)
      ? const [
          BoxShadow(
            color: Color(0x99000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x24FFFFFF),
            blurRadius: 12,
          ),
        ]
      : const [
          BoxShadow(
            color: Color(0x3D000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ];

  // Typography (10-foot UI on the 540 px canvas) -------------------------------

  static TextStyle pageTitle(ThemeData theme) => TextStyle(
        color: theme.canvasColor,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      );

  static TextStyle sectionTitle(ThemeData theme) => TextStyle(
        color: theme.canvasColor,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      );

  static TextStyle caption(ThemeData theme) => TextStyle(
        color: theme.canvasColor.withValues(alpha: 0.62),
        fontSize: 10.5,
        fontWeight: FontWeight.w500,
      );

  // Scrolling ------------------------------------------------------------------

  /// Brings a newly focused card into view like TV launchers: the row scrolls
  /// just enough to show the card, and the page scrolls so the row sits in
  /// the upper-middle of the screen.
  static void revealFocused(BuildContext context) {
    final target = context.findRenderObject();
    if (target == null || !target.attached) return;

    final horizontal = Scrollable.maybeOf(context, axis: Axis.horizontal);
    if (horizontal != null) {
      final viewport = RenderAbstractViewport.maybeOf(target);
      final leading = viewport?.getOffsetToReveal(target, 0).offset;
      horizontal.position.ensureVisible(
        target,
        duration: focusDuration,
        curve: focusCurve,
        alignmentPolicy:
            leading != null && leading < horizontal.position.pixels
                ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
                : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    }

    final vertical = Scrollable.maybeOf(context, axis: Axis.vertical);
    if (vertical != null) {
      vertical.position.ensureVisible(
        target,
        alignment: 0.4,
        duration: const Duration(milliseconds: 260),
        curve: focusCurve,
      );
    }
  }

  /// Scrolls only the horizontal row containing [context] so the focused
  /// card is visible (for pages that manage vertical scrolling themselves
  /// with [scrollPageToFocus]).
  static void revealInRow(BuildContext context) {
    final target = context.findRenderObject();
    if (target == null || !target.attached) return;
    final horizontal = Scrollable.maybeOf(context, axis: Axis.horizontal);
    if (horizontal == null) return;
    final viewport = RenderAbstractViewport.maybeOf(target);
    final leading = viewport?.getOffsetToReveal(target, 0).offset;
    horizontal.position.ensureVisible(
      target,
      duration: focusDuration,
      curve: focusCurve,
      alignmentPolicy: leading != null && leading < horizontal.position.pixels
          ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
          : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  /// Makes a page's vertical scroll view follow the remote focus, whatever
  /// widget holds it (buttons, rails, text fields, galleries...). Call it
  /// from a [FocusManager] listener. Focus within the first screen (the
  /// hero) scrolls back to the top so the hero is shown whole; anything
  /// further down is brought to ~30% from the top of the screen.
  static void scrollPageToFocus(
    BuildContext pageContext,
    ScrollController controller,
  ) {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null || !ctx.mounted || !controller.hasClients) return;
    if (ModalRoute.of(ctx) != ModalRoute.of(pageContext)) return;
    final vertical = Scrollable.maybeOf(ctx, axis: Axis.vertical);
    if (vertical == null || vertical.position != controller.position) return;

    // The child of the page's own viewport that contains the focus (a whole
    // horizontal rail, when the focus is inside one).
    final horizontal = Scrollable.maybeOf(ctx, axis: Axis.horizontal);
    final object = (horizontal != null
            ? horizontal.context.findRenderObject()
            : ctx.findRenderObject());
    if (object == null || !object.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(object);
    if (viewport == null) return;

    final position = controller.position;
    // Fully visible with the page at the top (e.g. the hero's buttons):
    // keep the whole hero on screen. Otherwise bring it to ~30% from the top.
    final visibleAtTop = viewport.getOffsetToReveal(object, 1.0).offset <= 0;
    var destination = visibleAtTop
        ? 0.0
        : viewport.getOffsetToReveal(object, 0.3).offset;
    destination =
        destination.clamp(position.minScrollExtent, position.maxScrollExtent);
    if ((destination - position.pixels).abs() < 2) return;
    controller.animateTo(
      destination,
      duration: const Duration(milliseconds: 280),
      curve: focusCurve,
    );
  }
}

/// Premium TV focus treatment: the focused child grows slightly, lifts with a
/// soft shadow and gets a thin white outline. Purely visual — the layout size
/// never changes, so rows don't shift while the remote moves.
class TvFocusFrame extends StatelessWidget {
  const TvFocusFrame({
    super.key,
    required this.focused,
    required this.child,
    this.borderRadius = TvDesign.cardRadius,
    this.scale = TvDesign.cardFocusScale,
    this.color,
  });

  final bool focused;
  final Widget child;
  final double borderRadius;
  final double scale;

  /// Card surface colour (painted under the content).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final theme = Theme.of(context);
    return AnimatedScale(
      scale: focused ? scale : 1,
      duration: TvDesign.focusDuration,
      curve: TvDesign.focusCurve,
      child: AnimatedContainer(
        duration: TvDesign.focusDuration,
        curve: TvDesign.focusCurve,
        decoration: BoxDecoration(
          color: color,
          borderRadius: radius,
          boxShadow: focused ? TvDesign.focusShadowFor(theme) : const [],
        ),
        foregroundDecoration: focused
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: TvDesign.focusRingColor(theme),
                  width: TvDesign.focusRingWidth,
                ),
              )
            : null,
        child: ClipRRect(borderRadius: radius, child: child),
      ),
    );
  }
}

/// Row / section title used on TV screens.
class TvSectionHeader extends StatelessWidget {
  const TvSectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(6, 4, 6, 0),
  });

  final String title;
  final Widget? trailing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TvDesign.sectionTitle(Theme.of(context)),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
