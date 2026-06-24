import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef PackageInfoLoader = Future<PackageInfo> Function();

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.currentBuildNumber,
    required this.latestVersion,
    required this.latestBuildNumber,
  });

  final bool isUpdateAvailable;
  final String currentVersion;
  final int currentBuildNumber;
  final String latestVersion;
  final int latestBuildNumber;
}

class AppUpdateService {
  AppUpdateService({
    ApiHelper? apiHelper,
    PackageInfoLoader? packageInfoLoader,
  })  : _apiHelper = apiHelper ?? ApiHelper(),
        _packageInfoLoader = packageInfoLoader ?? PackageInfo.fromPlatform;

  final ApiHelper _apiHelper;
  final PackageInfoLoader _packageInfoLoader;

  Future<bool> isUpdateAvailable() async {
    final info = await getUpdateInfo();
    return info.isUpdateAvailable;
  }

  Future<AppUpdateInfo> getUpdateInfo() async {
    final currentPackage = await _currentPackageInfo();
    final currentVersion = _normalizeVersion(currentPackage.version);
    final currentBuildNumber = _parseBuildNumber(currentPackage.buildNumber);

    try {
      final response = await _apiHelper.getApi(ApiConstant.getLatestVersion);
      if (response.statusCode != 200) {
        return AppUpdateInfo(
          isUpdateAvailable: false,
          currentVersion: currentVersion,
          currentBuildNumber: currentBuildNumber,
          latestVersion: '',
          latestBuildNumber: 0,
        );
      }

      final body = jsonDecode(response.body);
      final payload = _extractVersionPayload(body);
      final latestVersionValue = _firstValue(
        payload,
        _versionKeysForPlatform(defaultTargetPlatform),
      );
      final latestVersion = _normalizeVersion(latestVersionValue);
      final latestBuildNumber = _parseBuildNumber(
        _firstValue(payload, _buildKeysForPlatform(defaultTargetPlatform)),
        fallbackVersion: latestVersionValue,
      );
      final versionComparison = _compareVersion(latestVersion, currentVersion);
      final hasNewerVersion = versionComparison > 0;
      final hasNewerBuild = versionComparison == 0 &&
          latestBuildNumber > currentBuildNumber;
      final updateAvailable =
          latestVersion.isNotEmpty && (hasNewerVersion || hasNewerBuild);

      log(
        'current=$currentVersion+$currentBuildNumber latest=$latestVersion+$latestBuildNumber update=$updateAvailable',
        name: 'AppUpdateService',
      );

      return AppUpdateInfo(
        isUpdateAvailable: updateAvailable,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: latestVersion,
        latestBuildNumber: latestBuildNumber,
      );
    } catch (_) {
      log(
        'version check failed',
        name: 'AppUpdateService',
      );
      return AppUpdateInfo(
        isUpdateAvailable: false,
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        latestVersion: '',
        latestBuildNumber: 0,
      );
    }
  }

  Future<PackageInfo> _currentPackageInfo() async {
    try {
      return await _packageInfoLoader();
    } catch (_) {
      return PackageInfo(
        appName: 'Filmytell',
        packageName: 'com.filmytell.ott',
        version: AppConstant.appVersion,
        buildNumber: AppConstant.appBuildNumber.toString(),
      );
    }
  }

  List<String> _versionKeysForPlatform(TargetPlatform platform) {
    const commonKeys = [
      'version',
      'appVersion',
      'latestVersion',
      'versionName',
      'app_version',
      'latest_version',
    ];

    if (platform == TargetPlatform.iOS) {
      return const [
        'iosVersion',
        'iOSVersion',
        'iosAppVersion',
        'iosLatestVersion',
        'ios_version',
        'ios_app_version',
        'ios_latest_version',
        ...commonKeys,
      ];
    }

    return const [
      'androidVersion',
      'androidAppVersion',
      'androidLatestVersion',
      'android_version',
      'android_app_version',
      'android_latest_version',
      ...commonKeys,
    ];
  }

  List<String> _buildKeysForPlatform(TargetPlatform platform) {
    const commonKeys = [
      'buildNumber',
      'versionCode',
      'appVersionCode',
      'build_number',
      'version_code',
      'app_version_code',
      'id',
    ];

    if (platform == TargetPlatform.iOS) {
      return const [
        'iosBuildNumber',
        'iosVersionCode',
        'iosAppVersionCode',
        'ios_build_number',
        'ios_version_code',
        'ios_app_version_code',
        ...commonKeys,
      ];
    }

    return const [
      'androidBuildNumber',
      'androidVersionCode',
      'androidAppVersionCode',
      'android_build_number',
      'android_version_code',
      'android_app_version_code',
      ...commonKeys,
    ];
  }

  Map<String, dynamic> _extractVersionPayload(Object? body) {
    if (body is List && body.isNotEmpty) {
      return _extractVersionPayload(body.first);
    }

    if (body is! Map<String, dynamic>) {
      return const <String, dynamic>{};
    }

    final data = body['data'];
    if (data is Map<String, dynamic>) return data;

    final result = body['result'];
    if (result is Map<String, dynamic>) return result;
    if (result is List && result.isNotEmpty) {
      return _extractVersionPayload(result.first);
    }

    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }

    final response = body['response'];
    if (response is Map<String, dynamic>) return response;
    if (response is List && response.isNotEmpty) {
      return _extractVersionPayload(response.first);
    }

    return body;
  }

  Object? _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      Object? value = source[key];
      if (value == null) {
        for (final entry in source.entries) {
          if (entry.key.toLowerCase() == key.toLowerCase()) {
            value = entry.value;
            break;
          }
        }
      }
      if (value != null && value.toString().trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  String _normalizeVersion(Object? value) {
    final version = (value ?? '').toString().trim();
    return version.split('+').first.trim();
  }

  int _parseBuildNumber(Object? value, {Object? fallbackVersion}) {
    final directValue = (value ?? '').toString().trim();
    final directBuildNumber = int.tryParse(directValue);
    if (directBuildNumber != null) return directBuildNumber;

    final version = (fallbackVersion ?? '').toString().trim();
    final buildSeparatorIndex = version.indexOf('+');
    if (buildSeparatorIndex == -1 || buildSeparatorIndex == version.length - 1) {
      return 0;
    }
    return int.tryParse(version.substring(buildSeparatorIndex + 1).trim()) ?? 0;
  }

  int _compareVersion(String a, String b) {
    final pa = a.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final pb = b.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final maxLen = pa.length > pb.length ? pa.length : pb.length;

    for (int i = 0; i < maxLen; i++) {
      final va = i < pa.length ? pa[i] : 0;
      final vb = i < pb.length ? pb[i] : 0;
      if (va != vb) return va.compareTo(vb);
    }
    return 0;
  }
}
