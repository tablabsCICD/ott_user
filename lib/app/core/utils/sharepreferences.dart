import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/user.dart';
import '../constant/prefrense_constant.dart';

class LocalSharePreferences {
  static final LocalSharePreferences localSharePreferences =
      LocalSharePreferences._internal();
  factory LocalSharePreferences() {
    return localSharePreferences;
  }
  LocalSharePreferences._internal();
  setString(String key, String val) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.setString(key, val);
  }

  setBool(String key, bool val) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    _prefs.setBool(key, val);
  }

  Future<String> getString(String key) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    return _prefs.getString(key)!;
  }

  Future<bool> getBool(String key) async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    bool val = false;
    if (_prefs.getBool(key) != null) {
      val = _prefs.getBool(key)!;
    }
    return val;
  }

  Future<User> getLoginData() async {
    String data = await getString(SharedPreferencesConstant.currentUser);
    User user = User.fromJson(jsonDecode(data));
    return user;
  }

  Future<User?> getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userJson = prefs.getString(SharedPreferencesConstant.currentUser);
    debugPrint("getUser method in $userJson");

    if (userJson != null) {
      try {
        Map<String, dynamic> userMap = jsonDecode(userJson);
        debugPrint("Parsed User Map: $userMap");
        return User.fromJson(userMap);
      } catch (e) {
        debugPrint("Error decoding user JSON: $e");
        return null;
      }
    } else {
      debugPrint("getUser method in null return $userJson");
      return null;
    }
  }

  Future<bool> logOut() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    await _prefs.setBool(SharedPreferencesConstant.isUserLoggedIn, false);
    await _prefs.remove(SharedPreferencesConstant.currentUser);
    await _prefs.clear();
    return true;
  }
}
