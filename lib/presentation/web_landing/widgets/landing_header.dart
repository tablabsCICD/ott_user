import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';

class LandingHeader extends StatefulWidget {
  const LandingHeader({
    super.key,
    required this.scrolled,
    required this.onLogin,
    required this.onSignUp,
    required this.onNavigate,
  });

  final bool scrolled;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final ValueChanged<String> onNavigate;

  static const double desktopHeight = 80.0;
  static const double mobileBaseHeight = 64.0;

  static double getHeaderHeight(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    if (!isMobile) return desktopHeight;
    final topSafeSpacing = MediaQuery.viewPaddingOf(context)
        .top
        .clamp(0.0, double.infinity)
        .toDouble();
    return mobileBaseHeight + topSafeSpacing;
  }

  @override
  State<LandingHeader> createState() => _LandingHeaderState();
}

class _LandingHeaderState extends State<LandingHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final topSafeSpacing = isMobile
        ? MediaQuery.viewPaddingOf(context)
            .top
            .clamp(0.0, double.infinity)
            .toDouble()
        : 0.0;
    final headerHeight = LandingHeader.getHeaderHeight(context);
    final showLanguageLabel = width >= 620;
    const headerControlHeight = 44.0;

    final navItems = [
      (target: 'Home', label: lang.home),
      (target: 'Movies', label: lang.movie),
      (target: 'Short Film', label: lang.shortFilm),
      (target: 'Series', label: lang.series),
      (target: 'Mini Series', label: lang.minSeries),
    ];

    return FadeTransition(
      opacity: _fadeAnim,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        height: headerHeight,
        decoration: BoxDecoration(
          color: widget.scrolled
              ? const Color(0xFF0A0A0C).withValues(alpha: 0.95)
              : Colors.black.withValues(alpha: 0.35),
          border: Border(
            bottom: BorderSide(
              color: widget.scrolled
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.white.withValues(alpha: 0.02),
            ),
          ),
          boxShadow: [
            if (widget.scrolled)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.60),
                blurRadius: 32,
                offset: const Offset(0, 10),
              ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: widget.scrolled ? 24 : 12,
                    sigmaY: widget.scrolled ? 24 : 12,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 16 : (isTablet ? 28 : 56),
                topSafeSpacing,
                isMobile ? 16 : (isTablet ? 28 : 56),
                0,
              ),
              child: SizedBox.expand(
                child: Row(
                  children: [
                    // Brand Logo
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => widget.onNavigate('Home'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Image.asset(
                            ImageConstant.logo,
                            height: isMobile ? 44 : 58,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Image.asset(
                              ImageConstant.fullScreenLogo,
                              height: isMobile ? 44 : 58,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 16 : 36),
                    // Desktop Navigation items
                    if (!isMobile && !isTablet)
                      for (int i = 0; i < navItems.length; i++)
                        _HeaderNavItem(
                          label: navItems[i].label,
                          index: i,
                          onTap: () => widget.onNavigate(navItems[i].target),
                        ),
                    const Spacer(),
                    // Mobile / Tablet Navigation Menu Hamburger
                    if (isMobile || isTablet) ...[
                      PopupMenuButton<String>(
                        tooltip: 'Open navigation menu',
                        onSelected: widget.onNavigate,
                        color: FilmytellTheme.surfaceElevated,
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                        ),
                        itemBuilder: (context) => [
                          for (final item in navItems)
                            PopupMenuItem<String>(
                              value: item.target,
                              child: Row(
                                children: [
                                  Container(
                                    height: 6,
                                    width: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: FilmytellTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    item.label,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        child: Container(
                          height: headerControlHeight,
                          width: headerControlHeight,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: const Icon(
                            Icons.menu_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                      SizedBox(width: isMobile ? 8 : 10),
                    ],
                    // Language Dropdown
                    LanguageDropdown(
                      showSelectedLabel: showLanguageLabel,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      constraints: const BoxConstraints.tightFor(
                        height: headerControlHeight,
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: showLanguageLabel ? 12 : 8,
                        vertical: 0,
                      ),
                    ),
                    SizedBox(width: isMobile ? 8 : 14),
                    // Login / Sign Up Action Button
                    _HeaderLoginButton(
                      label: lang.login,
                      onPressed: widget.onSignUp,
                      isMobile: isMobile,
                      height: headerControlHeight,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderNavItem extends StatefulWidget {
  const _HeaderNavItem({
    required this.label,
    required this.index,
    required this.onTap,
  });

  final String label;
  final int index;
  final VoidCallback onTap;

  @override
  State<_HeaderNavItem> createState() => _HeaderNavItemState();
}

class _HeaderNavItemState extends State<_HeaderNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: FilmytellTheme.navItem(
                  active: _hovered,
                  color: _hovered ? Colors.white : const Color(0xFFE8E8E8),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 2.0,
                width: _hovered ? 24.0 : 0.0,
                decoration: BoxDecoration(
                  color: FilmytellTheme.primary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    if (_hovered)
                      BoxShadow(
                        color: FilmytellTheme.primary.withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderLoginButton extends StatefulWidget {
  const _HeaderLoginButton({
    required this.label,
    required this.onPressed,
    required this.isMobile,
    required this.height,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isMobile;
  final double height;

  @override
  State<_HeaderLoginButton> createState() => _HeaderLoginButtonState();
}

class _HeaderLoginButtonState extends State<_HeaderLoginButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.03 : 1.0,
        duration: const Duration(milliseconds: 180),
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: _hovered
                ? const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFE50914)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFE50914)],
                  ),
            boxShadow: [
              BoxShadow(
                color: FilmytellTheme.primary
                    .withValues(alpha: _hovered ? 0.45 : 0.22),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMobile ? 14 : 22,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              widget.label,
              style: FilmytellTheme.buttonText(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
