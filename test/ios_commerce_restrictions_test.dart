import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/services/WalletService.dart';
import 'package:ott/app/core/services/PaymentService.dart';
import 'package:ott/app/core/services/wallet_platform.dart';
import 'package:ott/app/provider/giftProvider.dart';

void main() {
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  test('iOS platform guard is active', () {
    expect(WalletPlatform.isIOS, isTrue);
    expect(PaymentService.isSupportedPlatform, isFalse);
  });

  test('gift code redemption is blocked before any backend request', () async {
    final result = await GiftProvider().useGiftByCoupon('TEST-GIFT-CODE');

    expect(result['success'], isFalse);
    expect(result['message'], contains('unavailable on iOS'));
  });

  test('direct wallet credit is blocked on iOS', () async {
    expect(
      () => WalletService().addWalletAmount(99),
      throwsA(isA<StateError>()),
    );
  });
}
