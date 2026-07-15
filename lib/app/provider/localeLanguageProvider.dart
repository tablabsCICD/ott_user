import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleLanguageProvider extends ChangeNotifier {
  static const String _localeKey = 'selected_locale';
  Locale _locale = const Locale('en');
  bool _disposed = false;

  Locale get locale => _locale;

  LocaleLanguageProvider() {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_localeKey);
    if (!_disposed && code != null) {
      _logLocale('Restoring saved locale code=$code');
      _locale = Locale(code);
      _notifyIfAlive();
    }
  }

  Future<void> setLocale(String languageCode) async {
    _logLocale(
      'setLocale requested previous=${_locale.languageCode} selected=$languageCode disposed=$_disposed',
    );
    if (_disposed) return;
    if (_locale.languageCode == languageCode) {
      _logLocale('setLocale skipped unchanged=$languageCode');
      return;
    }
    _locale = Locale(languageCode);
    _logLocale('setLocale notifying locale=$languageCode');
    _notifyIfAlive();
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    await prefs.setString(_localeKey, languageCode);
    _logLocale('setLocale persisted locale=$languageCode');
  }

  Future<void> resetLocale() async {
    _logLocale('resetLocale requested disposed=$_disposed');
    if (_disposed) return;
    _locale = const Locale('en');
    _notifyIfAlive();
    final prefs = await SharedPreferences.getInstance();
    if (_disposed) return;
    await prefs.remove(_localeKey);
    _logLocale('resetLocale persisted default=en');
  }

  void _logLocale(String message) {
    if (!kDebugMode) return;
    developer.log(message, name: 'LocaleLanguage');
  }

  void _notifyIfAlive() {
    if (_disposed) {
      _logLocale('notifyListeners skipped: provider disposed');
      return;
    }
    _logLocale('notifyListeners called locale=${_locale.languageCode}');
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
