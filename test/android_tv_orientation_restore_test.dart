import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('movie and trailer players restore landscape for the TV flavor', () {
    final moviePlayer = File(
      'lib/app/pages/watchlist page/component/playMoviePage.dart',
    ).readAsStringSync();
    final trailerPlayer = File(
      'lib/app/pages/watchlist page/component/DisplayTrailer.dart',
    ).readAsStringSync();

    for (final source in <String>[moviePlayer, trailerPlayer]) {
      expect(source, contains('FlavorConfig.current.isTv'));
      expect(source, contains('DeviceOrientation.landscapeLeft'));
      expect(source, contains('DeviceOrientation.landscapeRight'));
      expect(source, contains('DeviceOrientation.portraitUp'));
    }
  });
}
