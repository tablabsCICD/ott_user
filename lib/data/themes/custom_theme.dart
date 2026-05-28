import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(),
      primaryTextTheme: GoogleFonts.interTextTheme(),
      primaryColor: const Color(0xFFCF171D), // Netflix Red
      scaffoldBackgroundColor: const Color(0xFFF6F7FA),
      canvasColor: const Color(0xFF000000), // White canvas color for light mode
      cardColor: const Color(0xFFFFFFFF),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFCF171D),
        brightness: Brightness.light,
        primary: const Color(0xFFCF171D),
        surface: const Color(0xFFFFFFFF),
      ),
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      )
      );

  static final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      primaryColor: const Color(0xFFCF171D), // Netflix Red
      scaffoldBackgroundColor: const Color(0xFF05060A),
      canvasColor: const Color(0xFFFFFFFF), // Black canvas color for dark mode
      cardColor: const Color(0xFF11131A),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFCF171D),
        brightness: Brightness.dark,
        primary: const Color(0xFFCF171D),
        surface: const Color(0xFF11131A),
      ),
      visualDensity: VisualDensity.standard,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      )
      );
}
