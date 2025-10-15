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
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final localSharePreferences = LocalSharePreferences();
    final user = await localSharePreferences.getUser();

    _selectedLanguages = user!.selectedLanguages!;
    //log('$_selectedLanguages');
  }

  List<String> _selectedLanguages = []; // Stores selected languages

  List<String> get selectedLanguages => _selectedLanguages;

  List<String> _allLanguages = []; // Stores selected languages

  List<String> get allLanguages => _allLanguages;

  void updateLanguages(List<String> newLanguages) {
    _selectedLanguages = newLanguages;
    notifyListeners(); // Notifies UI to update
    //log('$_selectedLanguages');
  }

  Future<void> fetchLanguages() async {
    String apiUrl = ApiConstant.fetchLang;
    ApiHelper apiHelper = ApiHelper();
    try {
      var response = await apiHelper.getApi(apiUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseBody = json.decode(response.body);
        AllLangResponse addUserResponse =
            AllLangResponse.fromJson(responseBody);
        _allLanguages.clear();
        addUserResponse.data!.languages!
            .forEach((elemnet) => {_allLanguages.add(elemnet.name.toString())});
        notifyListeners();
      } else {
        throw Exception('Failed to fetch languages');
      }
    } catch (e) {
      debugPrint('Error fetching languages: $e');
    }
  }
}
