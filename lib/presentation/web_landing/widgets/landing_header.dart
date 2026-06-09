import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';

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
    final navItems = ['Home', 'Movies', 'Series'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      height: 76,
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
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
              sigmaX: scrolled ? 16 : 0, sigmaY: scrolled ? 16 : 0),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 56,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset(
                    ImageConstant.logo,
                    height: 75,
                    width: 75,
                  ),
                ),
                const SizedBox(width: 34),
                for (final item in navItems)
                  _HeaderNavItem(
                    label: item,
                    onTap: () => onNavigate(item),
                  ),
                const Spacer(),
                ElevatedButton(
                  onPressed: onSignUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
