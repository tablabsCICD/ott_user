import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const String _fontFamily = 'Inter';

  /// Default foreground for AppBars that keep their theme (surface) background:
  /// black in Light theme, white in Dark theme. Backgrounds are unchanged.
  ///
  /// Only [AppBarTheme.foregroundColor] is set: Flutter derives the title,
  /// leading and action icon colours from it, and an AppBar's own
  /// `foregroundColor` (white on the red AppBars) still takes precedence.
  /// Setting `iconTheme`/`actionsIconTheme` here would override that.
  static AppBarTheme _foregroundAppBarTheme(Color foreground) => AppBarTheme(
        foregroundColor: foreground,
      );

  /// Dialog text keeps Flutter's default typography (whose colour is already
  /// onSurface: black in Light, white in Dark); only the icon colour is set.
  static DialogThemeData _foregroundDialogTheme(Color foreground) =>
      DialogThemeData(iconColor: foreground);

  static final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFCD2027),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
      ),
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
          const Color(0xFFFFFFFF), // White background for light mode
      canvasColor: const Color(0xFF000000), // Black canvas color for light mode
      cardColor: Colors.grey[100], // Medium dark card color
      iconTheme: const IconThemeData(color: Color(0xFF000000)),
      appBarTheme: _foregroundAppBarTheme(const Color(0xFF000000)),
      dialogTheme: _foregroundDialogTheme(const Color(0xFF000000)),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFF000000),
        textColor: Color(0xFF000000),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        iconColor: Color(0xFF000000),
      ),
      );

  static final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFCD2027),
        surface: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
      ),
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
      canvasColor: const Color(0xFFFFFFFF), // White canvas color for dark mode
      cardColor: Colors.grey[900], // Medium dark card color
      iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
      appBarTheme: _foregroundAppBarTheme(const Color(0xFFFFFFFF)),
      dialogTheme: _foregroundDialogTheme(const Color(0xFFFFFFFF)),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFFFFFFFF),
        textColor: Color(0xFFFFFFFF),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        iconColor: Color(0xFFFFFFFF),
      ),
      );
}
