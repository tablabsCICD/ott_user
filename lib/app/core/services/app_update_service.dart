import 'dart:convert';

import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';

class AppUpdateInfo {
  const AppUpdateInfo({
    required this.isUpdateAvailable,
    required this.currentVersion,
    required this.latestVersion,
  });

  final bool isUpdateAvailable;
  final String currentVersion;
  final String latestVersion;
}

class AppUpdateService {
  AppUpdateService({ApiHelper? apiHelper})
      : _apiHelper = apiHelper ?? ApiHelper();

  final ApiHelper _apiHelper;

  Future<bool> isUpdateAvailable() async {
    return (await getUpdateInfo()).isUpdateAvailable;
  }

  Future<AppUpdateInfo> getUpdateInfo() async {
    const currentVersion = AppConstant.appVersion;

    try {
      final response = await _apiHelper.getApi(ApiConstant.getLatestVersion);
      if (response.statusCode != 200) {
        return const AppUpdateInfo(
          isUpdateAvailable: false,
          currentVersion: currentVersion,
          latestVersion: '',
        );
      }

      final latestVersion = _readVersion(jsonDecode(response.body));
      return AppUpdateInfo(
        isUpdateAvailable:
            latestVersion.isNotEmpty && latestVersion != currentVersion,
        currentVersion: currentVersion,
        latestVersion: latestVersion,
      );
    } catch (_) {
      return const AppUpdateInfo(
        isUpdateAvailable: false,
        currentVersion: currentVersion,
        latestVersion: '',
      );
    }
  }

  String _readVersion(Object? body) {
    if (body is Map<String, dynamic>) {
      final version = body['version'] ?? body['appVersion'];
      if (version != null) return version.toString().trim();

      final data = body['data'];
      if (data is Map<String, dynamic>) {
        return _readVersion(data);
      }
    }
    return '';
  }
}
