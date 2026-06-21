import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
import 'package:ott/l10n/app_localizations.dart';

class LandingHeader extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final showLanguageLabel = width >= 620;
    const headerControlHeight = 46.0;
    final navItems = [
      (target: 'Home', label: lang.home),
      (target: 'Movies', label: lang.movie),
      (target: 'Series', label: lang.series),
      (target: 'Mini Series', label: 'Mini Series'),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      height: 84,
      decoration: BoxDecoration(
        color: scrolled ? Colors.black.withOpacity(0.72) : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(scrolled ? 0.10 : 0),
          ),
        ),
        boxShadow: [
          if (scrolled)
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
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
                  sigmaX: scrolled ? 16 : 0,
                  sigmaY: scrolled ? 16 : 0,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 56,
            ),
            child: SizedBox.expand(
              child: Row(
                children: [
                  SizedBox(
                    height: 76,
                    width: 252,
                    child: Transform.scale(
                      scale: 1.65,
                      alignment: Alignment.centerLeft,
                      child: Image.asset(
                        ImageConstant.logo,
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  for (final item in navItems)
                    _HeaderNavItem(
                      label: item.label,
                      onTap: () => onNavigate(item.target),
                    ),
                  const Spacer(),
                  LanguageDropdown(
                    showSelectedLabel: showLanguageLabel,
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withOpacity(0.08),
                    constraints: const BoxConstraints.tightFor(
                      height: headerControlHeight,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: showLanguageLabel ? 12 : 9,
                      vertical: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: onSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      fixedSize: const Size.fromHeight(headerControlHeight),
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(lang.login),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderNavItem extends StatefulWidget {
  const _HeaderNavItem({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  State<_HeaderNavItem> createState() => _HeaderNavItemState();
}

class _HeaderNavItemState extends State<_HeaderNavItem> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(right: 6),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
          decoration: BoxDecoration(
            color:
                _hovered ? Colors.white.withOpacity(0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hovered ? Colors.white : Colors.white.withOpacity(0.78),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconCircle extends StatefulWidget {
  const _IconCircle({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_IconCircle> createState() => _IconCircleState();
}

class _IconCircleState extends State<_IconCircle> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 42,
          width: 42,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withOpacity(0.16)
                : Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(widget.icon, color: Colors.white, size: 21),
        ),
      ),
    );
  }
}
