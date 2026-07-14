import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/repositories/secure_playback_repository.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/offline_download_provider.dart';
import 'package:ott/app/provider/secure_playback_controller.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/route/navigation_service.dart';
import 'package:ott/presentation/web_landing/utils/post_logout_navigation.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  static const String replacementSessionMessage =
      'Your session has expired because you logged in from another device.';

  bool _handlingForcedLogout = false;

  Future<String?> get token async =>
      LocalSharePreferences.localSharePreferences.getAuthToken();

  Future<void> saveToken(String? token) async {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) return;
    await LocalSharePreferences.localSharePreferences.setAuthToken(normalized);
  }

  Future<void> saveSessionRecordId(String? sessionRecordId) async {
    final normalized = sessionRecordId?.trim();
    if (normalized == null || normalized.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      SharedPreferencesConstant.currentSessionRecordId,
      normalized,
    );
  }

  Future<void> clearLocalSession() async {
    await SecurePlaybackSessionRegistry.instance.stopAll();
    SecurePlaybackRepository.instance.markRegistrationUnknown();
    await LocalSharePreferences.localSharePreferences.clearSession();
  }

  Future<bool> logoutFromServer() async {
    await SecurePlaybackSessionRegistry.instance.stopAll();
    SecurePlaybackRepository.instance.markRegistrationUnknown();
    final authToken = await token;
    _logWebAuth('Explicit logout requested hasToken=${authToken != null}');
    if (authToken == null) return true;
    try {
      final response = await http.post(
        Uri.parse(ApiConstant.sessionLogout),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
      ).timeout(const Duration(seconds: 10));
      _logWebAuth('Explicit logout response status=${response.statusCode}');
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      _logWebAuth('Explicit logout request failed');
      return false;
    }
  }

  Future<void> handleSessionExpired(String message) async {
    if (_handlingForcedLogout) return;
    _handlingForcedLogout = true;
    _logWebAuth('Session expired redirect triggered message=$message');

    await clearLocalSession();

    final navigator = navigatorKey.currentState;
    final context = navigator?.context;
    if (context != null && context.mounted) {
      _clearProviders(context);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    if (navigator != null) {
      pushPostLogoutAndRemoveUntil(navigator);
    }

    Future<void>.delayed(const Duration(seconds: 2), () {
      _handlingForcedLogout = false;
    });
  }

  bool isReplacementSessionResponse(http.Response response) {
    if (response.statusCode != 401) return false;
    final message = extractMessage(response.body);
    _logWebAuth(
      '401 response inspected replacementSession=${message == replacementSessionMessage}',
    );
    return message == replacementSessionMessage;
  }

  static String? extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        final message = decoded['message'] ?? decoded['error'];
        return message?.toString();
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void _clearProviders(BuildContext context) {
    Provider.of<DashboardProvider>(context, listen: false).clear();
    Provider.of<BookmarkProvider>(context, listen: false).clear();
    Provider.of<UserProvider>(context, listen: false).clear();
    Provider.of<UserProvider>(context, listen: false).disposeData();
    Provider.of<OfflineDownloadProvider>(context, listen: false).clear();
  }

  void _logWebAuth(String message) {
    if (!kIsWeb || !kDebugMode) return;
    developer.log(message, name: 'WebAuthGuard');
  }
}
