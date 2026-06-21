import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/services/app_update_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  const currentVersion = AppConstant.appVersion;
  const currentBuildNumber = AppConstant.appBuildNumber;

  group('AppUpdateService', () {
    test('does not show update when API version is older', () async {
      final latestVersion = _decrementPatch(currentVersion);
      final service = _serviceFor(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        apiBody: _apiBody(version: latestVersion, id: 3),
      );

      final info = await service.getUpdateInfo();

      expect(info.currentVersion, currentVersion);
      expect(info.latestVersion, latestVersion);
      expect(info.isUpdateAvailable, isFalse);
    });

    test('does not show update when version and build number match', () async {
      final service = _serviceFor(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        apiBody: _apiBody(version: currentVersion, id: currentBuildNumber),
      );

      final info = await service.getUpdateInfo();

      expect(info.latestVersion, currentVersion);
      expect(info.latestBuildNumber, currentBuildNumber);
      expect(info.isUpdateAvailable, isFalse);
    });

    test('shows update when latest API version is newer', () async {
      final latestVersion = _incrementPatch(currentVersion);
      final service = _serviceFor(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        apiBody: _apiBody(version: latestVersion, id: currentBuildNumber),
      );

      final info = await service.getUpdateInfo();

      expect(info.latestVersion, latestVersion);
      expect(info.isUpdateAvailable, isTrue);
    });

    test('shows update when version matches but build number is newer',
        () async {
      final latestBuildNumber = currentBuildNumber + 1;
      final service = _serviceFor(
        currentVersion: currentVersion,
        currentBuildNumber: currentBuildNumber,
        apiBody: _apiBody(version: currentVersion, id: latestBuildNumber),
      );

      final info = await service.getUpdateInfo();

      expect(info.latestBuildNumber, latestBuildNumber);
      expect(info.isUpdateAvailable, isTrue);
    });
  });
}

AppUpdateService _serviceFor({
  required String currentVersion,
  required int currentBuildNumber,
  required String apiBody,
}) {
  return AppUpdateService(
    apiHelper: _FakeApiHelper(apiBody),
    packageInfoLoader: () async => PackageInfo(
      appName: 'Filmytell',
      packageName: 'com.filmytell.ott',
      version: currentVersion,
      buildNumber: currentBuildNumber.toString(),
    ),
  );
}

String _apiBody({
  required String version,
  required int id,
}) {
  return jsonEncode({
    'id': id,
    'version': version,
  });
}

String _incrementPatch(String version) {
  final parts = _versionParts(version);
  parts[2] = parts[2] + 1;
  return parts.join('.');
}

String _decrementPatch(String version) {
  final parts = _versionParts(version);
  parts[2] = parts[2] > 0 ? parts[2] - 1 : 0;
  return parts.join('.');
}

List<int> _versionParts(String version) {
  final parts = version
      .split('.')
      .map((part) => int.tryParse(part) ?? 0)
      .toList(growable: true);
  while (parts.length < 3) {
    parts.add(0);
  }
  return parts;
}

class _FakeApiHelper extends ApiHelper {
  _FakeApiHelper(this.body);

  final String body;

  @override
  Future<dynamic> getApi(String url) async {
    return http.Response(body, 200);
  }
}
