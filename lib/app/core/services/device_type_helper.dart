import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:ott/app/core/services/device_identity_service.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

import 'device_runtime.dart';

enum SessionDeviceType {
  mobile('MOBILE'),
  tv('TV'),
  web('WEB');

  const SessionDeviceType(this.apiValue);

  final String apiValue;
}

class DeviceSessionInfo {
  const DeviceSessionInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.appVersion,
    required this.deviceMetadata,
  });

  final String deviceId;
  final String deviceName;
  final SessionDeviceType deviceType;
  final String appVersion;
  final String deviceMetadata;

  Map<String, dynamic> toLoginPayload({
    required String username,
    required String password,
    String? referralCode,
  }) {
    return {
      'username': username,
      'password': password,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType.apiValue,
      'appVersion': appVersion,
      'deviceMetadata': deviceMetadata,
      if (referralCode != null && referralCode.trim().isNotEmpty)
        'referralCode': referralCode.trim(),
    };
  }

  Map<String, dynamic> toVerifyOtpPayload({
    required String username,
    required String otp,
    String? referralCode,
  }) {
    return {
      'username': username,
      'otp': otp,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType.apiValue,
      'appVersion': appVersion,
      'deviceMetadata': deviceMetadata,
      if (referralCode != null && referralCode.trim().isNotEmpty)
        'referralCode': referralCode.trim(),
    };
  }
}

class DeviceTypeHelper {
  const DeviceTypeHelper._();

  static Future<DeviceSessionInfo> buildSessionInfo({
    BuildContext? context,
  }) async {
    final runtime = readDeviceRuntimeInfo();
    final deviceType = resolveDeviceType(context: context, runtime: runtime);
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceId = await getOrCreateDeviceId();
    final appVersion = packageInfo.version;
    final metadata = {
      'os': runtime.os,
      'model': runtime.model,
      'manufacturer': runtime.manufacturer,
      'appVersion': appVersion,
      'buildNumber': packageInfo.buildNumber,
      'deviceType': deviceType.apiValue,
      if (runtime.browser.isNotEmpty) 'browser': runtime.browser,
      if (runtime.userAgent.isNotEmpty) 'userAgent': runtime.userAgent,
    };

    return DeviceSessionInfo(
      deviceId: deviceId,
      deviceName: readableDeviceName(deviceType, runtime),
      deviceType: deviceType,
      appVersion: appVersion,
      deviceMetadata: jsonEncode(metadata),
    );
  }

  static SessionDeviceType resolveDeviceType({
    BuildContext? context,
    DeviceRuntimeInfo? runtime,
  }) {
    final info = runtime ?? readDeviceRuntimeInfo();
    if (kIsWeb || info.isWeb) return SessionDeviceType.web;

    if (FlavorConfig.current.isTv ||
        (context != null && ResponsiveWidget.isTv(context))) {
      return SessionDeviceType.tv;
    }

    final signature =
        '${info.os} ${info.model} ${info.userAgent}'.toLowerCase();
    if (signature.contains('android tv') ||
        signature.contains('fire tv') ||
        signature.contains('aft') ||
        signature.contains('smart-tv') ||
        signature.contains('smarttv') ||
        signature.contains('jio') ||
        signature.contains('jiostb')) {
      return SessionDeviceType.tv;
    }

    return SessionDeviceType.mobile;
  }

  static String readableDeviceName(
    SessionDeviceType type,
    DeviceRuntimeInfo runtime,
  ) {
    if (type == SessionDeviceType.web) {
      return runtime.browser.isEmpty
          ? 'Web Browser'
          : '${runtime.browser} Browser';
    }
    if (type == SessionDeviceType.tv) {
      if (runtime.model.toLowerCase().contains('fire')) return 'Fire TV Stick';
      return 'Living Room Android TV';
    }
    return runtime.model.trim().isEmpty ? 'Mobile Device' : runtime.model;
  }

  static Future<String> getOrCreateDeviceId() async {
    final identity = await DeviceIdentityService.instance.getIdentity();
    return identity.deviceId;
  }
}
