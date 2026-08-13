import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TV login activation submits completed credentials', () {
    final source = File(
      'lib/app/pages/sign in page/LoginCard.dart',
    ).readAsStringSync();

    expect(source, contains('onDone: _handleTvDone'));
    expect(source, contains('if (_currentTvCredentialIsComplete)'));
    expect(source, contains('_handleLoginOrOtp();'));
    expect(
      source,
      contains('event.logicalKey == LogicalKeyboardKey.select'),
    );
    expect(
      source,
      contains('event.logicalKey == LogicalKeyboardKey.enter'),
    );
  });
}
