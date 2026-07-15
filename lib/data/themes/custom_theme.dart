import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const String _fontFamily = 'Inter';

  static final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: _fontFamily,
      textTheme: GoogleFonts.interTextTheme(),
      primaryTextTheme: GoogleFonts.interTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      primaryColor: const Color(0xFFCD2027), // Netflix Red
      scaffoldBackgroundColor:
          const Color(0xFFFFFFFF), // Dark background for light mode
      canvasColor: const Color(0xFF000000), // White canvas color for light mode
      cardColor: Colors.grey[100] // Medium dark card color
      );

  static final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: _fontFamily,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      primaryTextTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0,
          ),
        ),
      ),
      primaryColor: const Color(0xFFCD2027), // Netflix Red
      scaffoldBackgroundColor:
          const Color(0xFF000000), // Dark background for dark mode
      canvasColor: const Color(0xFFFFFFFF), // Black canvas color for dark mode
      cardColor: Colors.grey[900] // Medium dark card color
      );
}
