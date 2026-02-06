import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/response/languageResponse.dart';
import '../core/constant/api_constant.dart';

class LanguageProvider with ChangeNotifier {
  /// State
  bool _loading = false;
  String? _error;

  List<String> _allLanguages = [];
  List<String> _selectedLanguages = [];

// grouped languges
  List<GroupedLanguageItem> majorIndianLanguages = [];
  List<GroupedLanguageItem> otherIndianLanguages = [];
  List<GroupedLanguageItem> foreignLanguages = [];

  /// Getters
  bool get loading => _loading;
  String? get error => _error;
  List<String> get allLanguages => _allLanguages;
  List<String> get selectedLanguages => _selectedLanguages;

  /// ---------------------------
  /// User language injection
  /// ---------------------------
  /// Call this ONCE after login / splash
  void setUserLanguages(List<String>? langs) {
    if (langs == null || langs.isEmpty) {
      _selectedLanguages = [];
    } else {
      _selectedLanguages = List.from(langs);
    }

    log('User languages set: $_selectedLanguages');
    notifyListeners();
  }

  /// ---------------------------
  /// Update selection from UI
  /// ---------------------------
  void updateLanguages(List<String> newLanguages) {
    _selectedLanguages = List.from(newLanguages);
    notifyListeners();
  }

  /// ---------------------------
  /// Fetch available languages
  /// ---------------------------
  Future<void> fetchLanguages() async {
    if (_loading) return; // 🔒 prevent duplicate calls

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiHelper().getApi(ApiConstant.fetchLang);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch languages');
      }

      final body = json.decode(response.body);
      final res = AllLangResponse.fromJson(body);

      _allLanguages = res.data?.languages
              ?.map((e) => e.name ?? '')
              .where((e) => e.isNotEmpty)
              .toList() ??
          [];

      log('Languages fetched: ${_allLanguages.length}');
    } catch (e) {
      _error = e.toString();
      log('Language fetch error: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ---------------------------
  /// Fetch Grouped languages
  /// ---------------------------
  Future<void> fetchGroupedLanguages() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiHelper().getApi(ApiConstant.fetchGroupedLang);

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch grouped languages');
      }

      final body = json.decode(response.body);
      final res = GroupedLanguageResponse.fromJson(body);

      majorIndianLanguages = res.majorIndianLanguages;
      otherIndianLanguages = res.otherIndianLanguages;
      foreignLanguages = res.foreignLanguages;

      log(
        'Grouped languages loaded → '
        'Major: ${majorIndianLanguages.length}, '
        'Other: ${otherIndianLanguages.length}, '
        'Foreign: ${foreignLanguages.length}',
      );
    } catch (e) {
      _error = e.toString();
      log('Grouped language fetch error: $_error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// ---------------------------
  /// Utilities
  /// ---------------------------
  bool isSelected(String lang) => _selectedLanguages.contains(lang);

  void toggleLanguage(String lang) {
    if (_selectedLanguages.contains(lang)) {
      _selectedLanguages.remove(lang);
    } else {
      _selectedLanguages.add(lang);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedLanguages.clear();
    notifyListeners();
  }
}
