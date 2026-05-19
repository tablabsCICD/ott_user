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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, val);
  }

  setBool(String key, bool val) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(key, val);
  }

  Future<String> getString(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key)!;
  }

  Future<bool> getBool(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool val = false;
    if (prefs.getBool(key) != null) {
      val = prefs.getBool(key)!;
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SharedPreferencesConstant.isUserLoggedIn, false);
    await prefs.remove(SharedPreferencesConstant.currentUser);
    await prefs.clear();
    return true;
  }
}
