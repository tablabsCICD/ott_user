import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme_provider.dart';
import 'package:provider/provider.dart';

/// Micro-animated toggle switch with smooth Sun/Moon icon transitions and glow effects.
class AnimatedThemeToggle extends StatefulWidget {
  const AnimatedThemeToggle({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  State<AnimatedThemeToggle> createState() => _AnimatedThemeToggleState();
}

class _AnimatedThemeToggleState extends State<AnimatedThemeToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isDark = context.watch<LandingThemeProvider>().isDarkMode;
    if (isDark && _controller.value < 0.5) {
      _controller.forward();
    } else if (!isDark && _controller.value > 0.5) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<LandingThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final colors = LandingThemeColors.of(context);

    final width = widget.compact ? 68.0 : 76.0;
    final height = widget.compact ? 34.0 : 38.0;
    final thumbSize = widget.compact ? 26.0 : 30.0;

    return Tooltip(
      message: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {
            themeProvider.toggleTheme();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: width,
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E2230)
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hovered
                    ? colors.primaryAccent.withOpacity(0.6)
                    : (isDark
                        ? Colors.white.withOpacity(0.12)
                        : Colors.black.withOpacity(0.08)),
                width: 1.4,
              ),
              boxShadow: [
                if (_hovered || isDark)
                  BoxShadow(
                    color: isDark
                        ? colors.primaryAccent.withOpacity(0.22)
                        : Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background stationary icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Icon(
                        Icons.wb_sunny_rounded,
                        size: widget.compact ? 13 : 15,
                        color: isDark
                            ? Colors.white.withOpacity(0.28)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Icon(
                        Icons.nightlight_round,
                        size: widget.compact ? 13 : 15,
                        color: isDark
                            ? const Color(0xFF93C5FD)
                            : Colors.black.withOpacity(0.25),
                      ),
                    ),
                  ],
                ),
                // Animated sliding thumb
                AnimatedAlign(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _controller.value * math.pi * 2,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: isDark
                                  ? const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]
                                  : const [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark
                                        ? const Color(0xFF3B82F6)
                                        : const Color(0xFFF59E0B))
                                    .withOpacity(0.45),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isDark
                                  ? Icons.nightlight_round
                                  : Icons.wb_sunny_rounded,
                              size: widget.compact ? 14 : 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
