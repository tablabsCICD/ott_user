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
  AppUpdateService({
    ApiHelper? apiHelper,
    String currentVersion = AppConstant.appVersion,
  })  : _apiHelper = apiHelper ?? ApiHelper(),
        _currentVersion = currentVersion;

  final ApiHelper _apiHelper;
  final String _currentVersion;

  Future<bool> isUpdateAvailable() async {
    return (await getUpdateInfo()).isUpdateAvailable;
  }

  Future<AppUpdateInfo> getUpdateInfo() async {
    final currentVersion = _currentVersion;

    try {
      final response = await _apiHelper.getApi(ApiConstant.getLatestVersion);
      if (response.statusCode != 200) {
        return AppUpdateInfo(
          isUpdateAvailable: false,
          currentVersion: currentVersion,
          latestVersion: '',
        );
      }

      final latestVersion = _readVersion(jsonDecode(response.body));
      return AppUpdateInfo(
        isUpdateAvailable: _isNewerVersion(latestVersion, currentVersion),
        currentVersion: currentVersion,
        latestVersion: latestVersion,
      );
    } catch (_) {
      return AppUpdateInfo(
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

  bool _isNewerVersion(String candidate, String current) {
    final candidateVersion = _SemanticVersion.tryParse(candidate);
    final currentVersion = _SemanticVersion.tryParse(current);
    if (candidateVersion == null || currentVersion == null) return false;
    return candidateVersion.compareTo(currentVersion) > 0;
  }
}

class _SemanticVersion implements Comparable<_SemanticVersion> {
  const _SemanticVersion(this.numbers, this.preRelease);

  final List<int> numbers;
  final List<String> preRelease;

  static final RegExp _pattern = RegExp(
    r'^v?(\d+(?:\.\d+)*)(?:-([0-9A-Za-z.-]+))?(?:\+[0-9A-Za-z.-]+)?$',
    caseSensitive: false,
  );

  static _SemanticVersion? tryParse(String value) {
    final match = _pattern.firstMatch(value.trim());
    if (match == null) return null;

    final numbers = match.group(1)!.split('.').map(int.tryParse).toList();
    if (numbers.any((number) => number == null)) return null;

    final preRelease = match.group(2)?.split('.') ?? const <String>[];
    return _SemanticVersion(numbers.cast<int>(), preRelease);
  }

  @override
  int compareTo(_SemanticVersion other) {
    final length = numbers.length > other.numbers.length
        ? numbers.length
        : other.numbers.length;
    for (var index = 0; index < length; index++) {
      final left = index < numbers.length ? numbers[index] : 0;
      final right = index < other.numbers.length ? other.numbers[index] : 0;
      final comparison = left.compareTo(right);
      if (comparison != 0) return comparison;
    }

    if (preRelease.isEmpty && other.preRelease.isEmpty) return 0;
    if (preRelease.isEmpty) return 1;
    if (other.preRelease.isEmpty) return -1;

    final preReleaseLength = preRelease.length > other.preRelease.length
        ? preRelease.length
        : other.preRelease.length;
    for (var index = 0; index < preReleaseLength; index++) {
      if (index >= preRelease.length) return -1;
      if (index >= other.preRelease.length) return 1;

      final left = preRelease[index];
      final right = other.preRelease[index];
      final leftNumber = int.tryParse(left);
      final rightNumber = int.tryParse(right);
      final comparison = leftNumber != null && rightNumber != null
          ? leftNumber.compareTo(rightNumber)
          : leftNumber != null
              ? -1
              : rightNumber != null
                  ? 1
                  : left.compareTo(right);
      if (comparison != 0) return comparison;
    }
    return 0;
  }
}
