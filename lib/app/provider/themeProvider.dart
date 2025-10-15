import 'package:flutter/material.dart';
import 'package:ott/data/themes/custom_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  late ThemeData _selectedTheme;
  late SharedPreferences _prefs;

  ThemeProvider({bool isDark = false}) {
    _selectedTheme = isDark ? AppTheme.darkTheme : AppTheme.lightTheme;
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
  }

  ThemeData get getTheme => _selectedTheme;

  bool get isDark => _selectedTheme == AppTheme.darkTheme;

  Future<void> toggleTheme() async {
    _selectedTheme = isDark ? AppTheme.lightTheme : AppTheme.darkTheme;
    await _prefs.setBool("isDark", isDark);
    notifyListeners();
  }
}
