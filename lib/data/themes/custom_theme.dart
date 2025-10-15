import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: const Color(0xFFE50914), // Netflix Red
      scaffoldBackgroundColor:
          const Color(0xFFFFFFFF), // Dark background for light mode
      canvasColor: const Color(0xFF000000), // White canvas color for light mode
      cardColor: Colors.grey[100] // Medium dark card color
      );

  static final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: const Color(0xFFE50914), // Netflix Red
      scaffoldBackgroundColor:
          const Color(0xFF000000), // Dark background for dark mode
      canvasColor: const Color(0xFFFFFFFF), // Black canvas color for dark mode
      cardColor: Colors.grey[900] // Medium dark card color
      );
}
