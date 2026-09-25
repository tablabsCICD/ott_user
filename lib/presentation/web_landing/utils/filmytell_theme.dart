import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Filmytell OTT Design System Tokens — Netflix-Inspired Cinematic Black & Red Theme
class FilmytellTheme {
  FilmytellTheme._();

  // ===========================================================================
  // Netflix-Calibrated OTT Typography System
  // Primary Target: Netflix Sans / Plus Jakarta Sans geometric neo-grotesque
  // ===========================================================================
  static const List<String> fontFallback = [
    'Plus Jakarta Sans',
    'Inter',
    'Netflix Sans',
    '-apple-system',
    'BlinkMacSystemFont',
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static TextStyle font({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
    );
  }

  // Section Heading ("Trending Now", "Latest Content")
  // Netflix Desktop: 24px (1.5rem), w700, -0.2px tracking, 1.25 line-height
  // Netflix Mobile: 20px (1.25rem), w700, -0.2px tracking, 1.25 line-height
  static TextStyle sectionHeading({
    bool isMobile = false,
    bool isTablet = false,
    Color? color,
  }) {
    final size = isMobile ? 20.0 : (isTablet ? 22.0 : 24.0);
    return font(
      fontSize: size,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      height: 1.25,
      color: color ?? textPrimary,
    );
  }

  // Hero Main Title
  static TextStyle heroHeading({
    bool isMobile = false,
    Color? color,
  }) {
    return font(
      fontSize: isMobile ? 32.0 : 48.0,
      fontWeight: FontWeight.w800,
      letterSpacing: isMobile ? -0.4 : -0.8,
      height: 1.12,
      color: color ?? textPrimary,
    );
  }

  // Hero / Section Description Copy
  static TextStyle bodyLarge({
    bool isMobile = false,
    Color? color,
  }) {
    return font(
      fontSize: isMobile ? 14.5 : 16.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.50,
      color: color ?? textSecondary,
    );
  }

  // Standard Body Copy
  static TextStyle bodyMedium({
    Color? color,
  }) {
    return font(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      height: 1.45,
      color: color ?? textBody,
    );
  }

  // Metadata / Badges / Chips
  static TextStyle metadata({
    Color? color,
  }) {
    return font(
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      height: 1.30,
      color: color ?? textMuted,
    );
  }

  // Buttons (CTA, Primary, Secondary)
  static TextStyle buttonText({
    double fontSize = 14.5,
    FontWeight fontWeight = FontWeight.w600,
    Color color = Colors.white,
    double letterSpacing = 0.1,
  }) {
    return font(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: 1.20,
      color: color,
    );
  }

  // Navigation Menu Items
  static TextStyle navItem({
    bool active = false,
    Color? color,
  }) {
    return font(
      fontSize: 14.5,
      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: 0.0,
      height: 1.20,
      color: color ?? (active ? textPrimary : textSecondary),
    );
  }

  // Near-Black Cinematic Backgrounds (avoiding flat solid black)
  static const Color background = Color(0xFF050505); // Near-black base
  static const Color backgroundTop =
      Color(0xFF08060B); // Subtle deep purple/black top
  static const Color backgroundMiddle =
      Color(0xFF050507); // Neutral dark middle
  static const Color backgroundBottom =
      Color(0xFF030303); // Pitch obsidian bottom
  static const Color backgroundSecondary = Color(0xFF0A080D);
  static const Color backgroundTertiary = Color(0xFF110F16);

  // Surfaces & Cards
  static const Color surfaceDark = Color(0xFF111014);
  static const Color surfaceElevated = Color(0xFF17131C);
  static const Color surfaceCard = Color(0xFF131217);
  static const Color surfaceCardHover = Color(0xFF1C1924);
  static const Color surfaceGlass = Color(0xEB08060C);

  // Brand Accent Colors — Pure Red OTT Identity
  static const Color primary = Color(0xFFE50914); // Filmytell Vibrant Crimson
  static const Color primaryHover = Color(0xFFE50914);
  static const Color primaryDark = Color(0xFFB8050F);
  static const Color primaryGlow = Color(0x40E50914);
  static const Color accentRedLight = Color(0xFFFF4D56);
  static const Color gold = Color(0xFFFFB800);

  // Border & Divider Colors
  static const Color borderSubtle =
      Color(0x1AFFFFFF); // 10% White (rgba(255,255,255,0.10))
  static const Color borderMedium = Color(0x2EFFFFFF); // 18% White
  static const Color borderDark = Color(0xFF1F1E24);
  static const Color borderGlow = Color(0x99E50914);

  // High-Readability Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // High-contrast White
  static const Color textSecondary = Color(0xFFD6D6D6); // Crisp Secondary Text
  static const Color textBody = Color(0xFFD0D0D0); // Readable Body Copy
  static const Color textMuted = Color(0xFFA8A8A8); // Accessible Muted Text
  static const Color textSubtle = Color(0x80FFFFFF); // 50% White

  // Cinematic Gradients
  static const LinearGradient pageBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF08060B),
      Color(0xFF050507),
      Color(0xFF06050A),
      Color(0xFF030303),
    ],
    stops: [0.0, 0.35, 0.70, 1.0],
  );

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF120E16),
      Color(0xFF08060B),
      Color(0xFF030304),
    ],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF15131A),
      Color(0xFF0E0D12),
    ],
  );

  static const LinearGradient cardHoverGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1E1A26),
      Color(0xFF121017),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFF1E27),
      Color(0xFFE50914),
      Color(0xFFB8050F),
    ],
  );

  static const LinearGradient rankTextGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2E2E36),
      Color(0xFF18181E),
      Color(0xFF0C0C10),
    ],
  );

  // Shadows
  static List<BoxShadow> cardShadow({bool hovered = false, Color? glowColor}) {
    final glow = glowColor ?? primary;
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.75),
        blurRadius: hovered ? 24 : 14,
        offset: Offset(0, hovered ? 10 : 6),
      ),
      if (hovered)
        BoxShadow(
          color: glow.withValues(alpha: 0.35),
          blurRadius: 28,
          offset: const Offset(0, 6),
        ),
    ];
  }

  // Animation Durations & Curves
  static const Duration animFast = Duration(milliseconds: 180);
  static const Duration animNormal = Duration(milliseconds: 280);
  static const Duration animSlow = Duration(milliseconds: 550);
  static const Duration heroRotation = Duration(seconds: 7);

  static const Curve curveDefault = Curves.easeOutCubic;
  static const Curve curveSmooth = Curves.easeOutQuart;
}
