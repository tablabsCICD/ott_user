import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/response/languageResponse.dart';

import '../core/constant/api_constant.dart';
import '../core/utils/sharepreferences.dart';

class LanguageProvider with ChangeNotifier {
  LanguageProvider() {
    fetchLanguages();
  }

  List<String> _selectedLanguages = [];
  List<String> _allLanguages = [];

  List<String> get selectedLanguages => _selectedLanguages;
  List<String> get allLanguages => _allLanguages;

  /// Called by UI when user is loaded (login / splash / profile)
  void setUserLanguages(List<String> langs) {
    if (langs.isEmpty) {
      _selectedLanguages = ['English'];
    } else {
      _selectedLanguages = List.from(langs);
    }

    log('setUserLanguages = ${_selectedLanguages}');
    notifyListeners();
  }

  void updateLanguages(List<String> newLanguages) {
    _selectedLanguages = List.from(newLanguages);
    log('updateLanguages = ${selectedLanguages.length}');

    notifyListeners();
  }

  Future<void> fetchLanguages() async {
    String apiUrl = ApiConstant.fetchLang;
    ApiHelper apiHelper = ApiHelper();

    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AllLangResponse res = AllLangResponse.fromJson(responseBody);

        _allLanguages.clear();
        res.data?.languages?.forEach((e) {
          _allLanguages.add(e.name.toString());
        });

        notifyListeners();
      } else {
        throw Exception('Failed to fetch languages');
      }
    } catch (e) {
      debugPrint('Error fetching languages: $e');
    }
  }
}
