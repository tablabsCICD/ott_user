import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/presentation/web_landing/designs/common/animated_theme_toggle.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// Universal responsive adaptive navbar for Filmytell landing pages.
class LandingCommonHeader extends StatefulWidget {
  const LandingCommonHeader({
    super.key,
    required this.scrolled,
    required this.onLogin,
    required this.onSignUp,
    required this.onNavigate,
    this.activeNavLabel = 'Home',
    this.customAction,
  });

  final bool scrolled;
  final VoidCallback onLogin;
  final VoidCallback onSignUp;
  final ValueChanged<String> onNavigate;
  final String activeNavLabel;
  final Widget? customAction;

  @override
  State<LandingCommonHeader> createState() => _LandingCommonHeaderState();
}

class _LandingCommonHeaderState extends State<LandingCommonHeader> {
  static const _navItems = [
    'Home',
    'Movies',
    'Series',
    'Short Film',
    'Mini Series',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final isDark = colors.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 820;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      height: isMobile ? 64 : 76,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 48,
      ),
      decoration: BoxDecoration(
        color: widget.scrolled
            ? (isDark
                ? const Color(0xFF08090D).withOpacity(0.92)
                : Colors.white.withOpacity(0.95))
            : Colors.transparent,
        border: Border(
          bottom: BorderSide(
            color: widget.scrolled
                ? (isDark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.06))
                : Colors.transparent,
            width: 1.0,
          ),
        ),
        boxShadow: [
          if (widget.scrolled)
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.45 : 0.06),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Filmytell Logo
          GestureDetector(
            onTap: () => widget.onNavigate('Home'),
            child: Image.asset(
              ImageConstant.webFullScreenLogo,
              height: isMobile ? 36 : 44,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                ImageConstant.fullScreenLogo,
                height: isMobile ? 36 : 44,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(width: 32),

          // Desktop Nav Items
          if (!isMobile)
            Expanded(
              child: Row(
                children: _navItems.map((item) {
                  final isSelected = widget.activeNavLabel == item;
                  return _NavItemButton(
                    label: item,
                    isSelected: isSelected,
                    onTap: () => widget.onNavigate(item),
                  );
                }).toList(),
              ),
            )
          else
            const Spacer(),

          // Right Actions: Theme Toggle + Auth Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AnimatedThemeToggle(compact: true),
              const SizedBox(width: 14),
              if (widget.customAction != null) ...[
                widget.customAction!,
                const SizedBox(width: 12),
              ],
              TextButton(
                onPressed: widget.onLogin,
                style: TextButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 10 : 16,
                    vertical: isMobile ? 8 : 12,
                  ),
                ),
                child: Text(
                  'Sign In',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: widget.onSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 14 : 20,
                    vertical: isMobile ? 10 : 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  shadowColor: colors.primaryAccent.withOpacity(0.5),
                ),
                child: Text(
                  'Watch Now',
                  style: TextStyle(
                    fontSize: isMobile ? 12 : 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavItemButton extends StatefulWidget {
  const _NavItemButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_NavItemButton> createState() => _NavItemButtonState();
}

class _NavItemButtonState extends State<_NavItemButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? colors.primaryAccent
                      : (_hovered ? colors.textPrimary : colors.textSecondary),
                  fontSize: 14,
                  fontWeight: widget.isSelected || _hovered
                      ? FontWeight.w700
                      : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2,
                width: widget.isSelected ? 20 : (_hovered ? 14 : 0),
                decoration: BoxDecoration(
                  color: colors.primaryAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
