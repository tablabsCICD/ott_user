import 'dart:convert';
import 'dart:developer';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/response/languageResponse.dart';
import 'baseProvider.dart';
import '../core/constant/api_constant.dart';

class LanguageProvider extends BaseProvider {
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

      if (response.statusCode == 200) {
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
      } else {
        throw Exception('Grouped language API status: ${response.statusCode}');
      }
    } catch (e) {
      log('Grouped language fetch error: $e, falling back to standard list');
      try {
        await fetchLanguages();
        if (_allLanguages.isNotEmpty) {
          majorIndianLanguages = _allLanguages
              .map((name) => GroupedLanguageItem(id: 0, name: name, native: name))
              .toList();
        }
      } catch (_) {}

      // If still empty, supply default major Indian languages fallback
      if (majorIndianLanguages.isEmpty &&
          otherIndianLanguages.isEmpty &&
          foreignLanguages.isEmpty) {
        majorIndianLanguages = [
          GroupedLanguageItem(id: 1, name: 'Hindi', native: 'हिन्दी'),
          GroupedLanguageItem(id: 2, name: 'English', native: 'English'),
          GroupedLanguageItem(id: 3, name: 'Marathi', native: 'मराठी'),
          GroupedLanguageItem(id: 4, name: 'Tamil', native: 'தமிழ்'),
          GroupedLanguageItem(id: 5, name: 'Telugu', native: 'తెలుగు'),
          GroupedLanguageItem(id: 6, name: 'Kannada', native: 'ಕನ್ನಡ'),
          GroupedLanguageItem(id: 7, name: 'Malayalam', native: 'മലയാളം'),
          GroupedLanguageItem(id: 8, name: 'Bengali', native: 'বাংলা'),
          GroupedLanguageItem(id: 9, name: 'Gujarati', native: 'ગુજરાતી'),
          GroupedLanguageItem(id: 10, name: 'Punjabi', native: 'ਪੰਜਾਬੀ'),
        ];
      }
      _error = null;
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

