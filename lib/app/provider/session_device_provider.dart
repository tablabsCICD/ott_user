import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/session_device.dart';

class SessionDeviceProvider extends ChangeNotifier {
  final ApiHelper _apiHelper = ApiHelper();

  bool isLoading = false;
  String? errorMessage;
  List<SessionDevice> devices = [];

  Future<void> fetchDevices() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiHelper.getApi(ApiConstant.activeDevices);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final rawDevices = _extractDeviceList(decoded);
        devices = rawDevices
            .whereType<Map>()
            .map((item) => SessionDevice.fromJson(item.cast<String, dynamic>()))
            .where((device) => device.id.trim().isNotEmpty)
            .toList();
      } else {
        errorMessage =
            _extractMessage(response.body) ?? 'Unable to load active devices.';
      }
    } catch (error) {
      errorMessage = 'Unable to load active devices.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logoutDevice(String sessionRecordId) async {
    try {
      final response = await _apiHelper.postApi(
        ApiConstant.forceLogoutDevice(sessionRecordId),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        await fetchDevices();
        return true;
      }
      errorMessage =
          _extractMessage(response.body) ?? 'Unable to logout this device.';
      notifyListeners();
      return false;
    } catch (_) {
      errorMessage = 'Unable to logout this device.';
      notifyListeners();
      return false;
    }
  }

  List<dynamic> _extractDeviceList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map) {
      final data = decoded['data'];
      if (data is List) return data;
      if (data is Map) {
        for (final key in const ['devices', 'activeDevices', 'sessions']) {
          final value = data[key];
          if (value is List) return value;
        }
      }
      for (final key in const ['devices', 'activeDevices', 'sessions']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return const [];
  }

  String? _extractMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map) {
        return (decoded['message'] ?? decoded['error'])?.toString();
      }
    } catch (_) {}
    return null;
  }
}
