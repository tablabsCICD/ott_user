import 'package:flutter/material.dart';

/// Design tokens and color schemes for Filmytell Web Landing Page designs.
/// Provides meticulously crafted palettes for both Dark and Light modes.
class LandingThemeColors {
  LandingThemeColors({
    required this.isDark,
    required this.background,
    required this.surface,
    required this.surfaceHover,
    required this.surfaceElevated,
    required this.cardBackground,
    required this.border,
    required this.borderGlow,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primaryAccent,
    required this.secondaryAccent,
    required this.goldAccent,
    required this.glassFill,
    required this.glassBorder,
    required this.headerBackground,
    required this.footerBackground,
    required this.heroGradientStart,
    required this.heroGradientEnd,
    required this.badgeBackground,
    required this.badgeText,
  });

  final bool isDark;
  final Color background;
  final Color surface;
  final Color surfaceHover;
  final Color surfaceElevated;
  final Color cardBackground;
  final Color border;
  final Color borderGlow;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primaryAccent;
  final Color secondaryAccent;
  final Color goldAccent;
  final Color glassFill;
  final Color glassBorder;
  final Color headerBackground;
  final Color footerBackground;
  final Color heroGradientStart;
  final Color heroGradientEnd;
  final Color badgeBackground;
  final Color badgeText;

  static final LandingThemeColors dark = LandingThemeColors(
    isDark: true,
    background: const Color(0xFF08090D),
    surface: const Color(0xFF111319),
    surfaceHover: const Color(0xFF1A1D27),
    surfaceElevated: const Color(0xFF1E2230),
    cardBackground: const Color(0xFF141720),
    border: const Color(0xFF262B3D),
    borderGlow: const Color(0xFFE50914).withOpacity(0.35),
    textPrimary: const Color(0xFFFFFFFF),
    textSecondary: const Color(0xFFCBD5E1),
    textMuted: const Color(0xFF94A3B8),
    primaryAccent: const Color(0xFFE50914), // Filmytell Cinematic Crimson
    secondaryAccent: const Color(0xFFFF334B),
    goldAccent: const Color(0xFFFFB800),
    glassFill: const Color(0xFF111319).withOpacity(0.72),
    glassBorder: Colors.white.withOpacity(0.12),
    headerBackground: const Color(0xFF08090D).withOpacity(0.85),
    footerBackground: const Color(0xFF050608),
    heroGradientStart: const Color(0xFF08090D).withOpacity(0.2),
    heroGradientEnd: const Color(0xFF08090D),
    badgeBackground: const Color(0xFFE50914).withOpacity(0.2),
    badgeText: const Color(0xFFFF4D5E),
  );

  static final LandingThemeColors light = LandingThemeColors(
    isDark: false,
    background: const Color(0xFFF8FAFC),
    surface: const Color(0xFFFFFFFF),
    surfaceHover: const Color(0xFFF1F5F9),
    surfaceElevated: const Color(0xFFFFFFFF),
    cardBackground: const Color(0xFFFFFFFF),
    border: const Color(0xFFE2E8F0),
    borderGlow: const Color(0xFFE50914).withOpacity(0.25),
    textPrimary: const Color(0xFF0F172A),
    textSecondary: const Color(0xFF334155),
    textMuted: const Color(0xFF64748B),
    primaryAccent: const Color(0xFFE50914),
    secondaryAccent: const Color(0xFFDC2626),
    goldAccent: const Color(0xFFD97706),
    glassFill: Colors.white.withOpacity(0.82),
    glassBorder: const Color(0xFFE2E8F0),
    headerBackground: Colors.white.withOpacity(0.92),
    footerBackground: const Color(0xFF0F172A),
    heroGradientStart: const Color(0xFFF8FAFC).withOpacity(0.1),
    heroGradientEnd: const Color(0xFFF8FAFC),
    badgeBackground: const Color(0xFFE50914).withOpacity(0.12),
    badgeText: const Color(0xFFB91C1C),
  );

  static LandingThemeColors of(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return isDarkMode ? dark : light;
  }
}
