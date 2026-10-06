import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for managing and persisting Light/Dark theme mode in landing page designs.
class LandingThemeProvider extends ChangeNotifier {
  LandingThemeProvider({ThemeMode initialMode = ThemeMode.dark})
      : _themeMode = initialMode {
    _loadFromPreferences();
  }

  static const String _prefKey = 'filmytell_landing_theme_mode';
  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadFromPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode != null) {
        if (savedMode == 'light') {
          _themeMode = ThemeMode.light;
        } else {
          _themeMode = ThemeMode.dark;
        }
        notifyListeners();
      }
    } catch (_) {
      // Graceful fallback to default dark theme
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    _saveToPreferences(mode);
  }

  void toggleTheme() {
    setThemeMode(
      _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }

  Future<void> _saveToPreferences(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        mode == ThemeMode.light ? 'light' : 'dark',
      );
    } catch (_) {
      // Ignored
    }
  }
}
