import 'package:flutter/services.dart' show appFlavor;
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/services/app_update_service.dart';
import 'package:ott/app/flavor/app_flavor.dart';

void main() {
  group('Jio STB Startup & Flavor Resilience Tests', () {
    test('FlavorConfig parses jio and jiostb correctly', () {
      final configJio = FlavorConfig.forFlavor(FilmytellFlavor.jio);
      expect(configJio.isJio, isTrue);
      expect(configJio.isTv, isTrue);
      expect(configJio.isMobile, isFalse);
      expect(configJio.isWeb, isFalse);
      expect(configJio.name, equals('jio'));
    });

    test('FlavorConfig environment parsing defaults safely', () {
      final config = FlavorConfig.fromEnvironment(fallback: FilmytellFlavor.jio);
      expect(config.flavor, equals(FilmytellFlavor.jio));
      expect(config.isJio, isTrue);
      expect(config.isTv, isTrue);
    });

    test('App update service returns isUpdateAvailable: false on Jio STB', () async {
      FlavorConfig.current = const FlavorConfig.forFlavor(FilmytellFlavor.jio);
      final service = AppUpdateService();
      final updateInfo = await service.getUpdateInfo();

      expect(updateInfo.isUpdateAvailable, isFalse);
      expect(updateInfo.currentVersion, equals(AppConstant.appVersion));
    });

    test('App version and build number are aligned for JioStore resubmission', () {
      expect(AppConstant.appVersion, equals('1.0.21'));
      expect(AppConstant.appBuildNumber, equals(52));
      expect(AppConstant.appBuildNumber, greaterThan(51)); // Must exceed rejected v51 and v46
    });
  });
}
