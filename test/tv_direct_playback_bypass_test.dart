import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TV direct playback bypass remains isolated before secure playback', () {
    final source = File(
      'lib/app/pages/watchlist page/component/playMoviePage.dart',
    ).readAsStringSync();

    final bypass = source.indexOf('if (FlavorConfig.current.isTv)');
    final securePlayback = source.indexOf('await _startSecurePlayback(');

    expect(bypass, greaterThanOrEqualTo(0));
    expect(securePlayback, greaterThan(bypass));
    expect(source, contains('preferAndroidNativeDirect: true'));
    expect(
      source,
      contains('(diagnoseSignedHls || preferAndroidNativeDirect)'),
    );
  });
}
