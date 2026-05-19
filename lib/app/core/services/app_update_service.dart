import 'dart:convert';
import 'dart:developer';

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  AppUpdateService({ApiHelper? apiHelper})
      : _apiHelper = apiHelper ?? ApiHelper();

  final ApiHelper _apiHelper;

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
      final latestVersion = _normalizeVersion(_firstValue(payload, const [
        'version',
        'appVersion',
        'latestVersion',
        'androidVersion',
        'versionName',
      ]));
      final latestBuildNumber = _parseBuildNumber(_firstValue(payload, const [
        'buildNumber',
        'versionCode',
        'appVersionCode',
        'androidVersionCode',
        'id',
      ]));

      final versionComparison = _compareVersion(latestVersion, currentVersion);
      final updateAvailable = latestVersion.isNotEmpty &&
          (versionComparison > 0 ||
              (versionComparison == 0 &&
                  latestBuildNumber > currentBuildNumber));

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
      return PackageInfo.fromPlatform();
    } catch (_) {
      return PackageInfo(
        appName: 'Filmytell',
        packageName: 'com.filmytell.ott',
        version: AppConstant.appVersion,
        buildNumber: AppConstant.appBuildNumber.toString(),
      );
    }
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

    if (data is List && data.isNotEmpty && data.first is Map<String, dynamic>) {
      return data.first as Map<String, dynamic>;
    }

    return body;
  }

  Object? _firstValue(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key];
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

  int _parseBuildNumber(Object? value) {
    return int.tryParse((value ?? '').toString().trim()) ?? 0;
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
