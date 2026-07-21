import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final sourceManifest = File('android/app/src/main/AndroidManifest.xml');
  final tvManifest = File('android/app/src/tv/AndroidManifest.xml');
  final gradleFile = File('android/app/build.gradle.kts');

  test('TV-incompatible hardware is explicitly optional', () {
    final xml = sourceManifest.readAsStringSync();
    for (final feature in <String>[
      'android.hardware.touchscreen',
      'android.hardware.touchscreen.multitouch',
      'android.hardware.touchscreen.multitouch.distinct',
      'android.hardware.location',
      'android.hardware.location.gps',
      'android.hardware.location.network',
      'android.hardware.telephony',
      'android.hardware.camera',
      'android.hardware.camera.autofocus',
      'android.hardware.microphone',
      'android.hardware.nfc',
      'android.hardware.bluetooth',
      'android.hardware.bluetooth_le',
      'android.hardware.usb.host',
      'android.hardware.screen.portrait',
    ]) {
      expect(
        RegExp(
          '<uses-feature\\s+android:name="$feature"\\s+'
          'android:required="false"\\s*/>',
        ).hasMatch(xml),
        isTrue,
        reason: '$feature must not filter Android TV devices',
      );
    }
  });

  test('TV and phone launchers remain declared', () {
    expect(
      sourceManifest.readAsStringSync(),
      contains('android.intent.category.LAUNCHER'),
    );
    expect(
      tvManifest.readAsStringSync(),
      contains('android.intent.category.LEANBACK_LAUNCHER'),
    );
  });

  test('TV flavor requires Leanback for the Play TV track', () {
    expect(
      RegExp(
        '<uses-feature\\s+android:name="android\\.software\\.leanback"\\s+'
        'android:required="true"\\s*/>',
      ).hasMatch(tvManifest.readAsStringSync()),
      isTrue,
    );
  });

  test('both Android flavors preserve the production application ID', () {
    final gradle = gradleFile.readAsStringSync();
    expect(RegExp('applicationId = "com\\.filmytell\\.ott"').allMatches(gradle),
        hasLength(3));
  });
}
