import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/widgets/gift_claim_dialog.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider whose redemption only completes when the test says so, so the
/// in-flight state of the dialog can be inspected.
class _ControlledGiftProvider extends GiftProvider {
  int callCount = 0;
  Completer<Map<String, dynamic>> completer = Completer();

  @override
  Future<Map<String, dynamic>> useGiftByCoupon(String couponCode) {
    callCount++;
    return completer.future;
  }
}

const _code = 'GF000843A767720E';

Widget _app(
  _ControlledGiftProvider provider,
  ValueNotifier<bool?> result, {
  String? initialCode = _code,
  bool fromDeepLink = true,
}) {
  return ChangeNotifierProvider<GiftProvider>.value(
    value: provider,
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result.value = await showGiftClaimDialog(
                context,
                initialCouponCode: initialCode,
                isFromDeepLink: fromDeepLink,
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
}

Finder get _redeemButton => find.widgetWithText(ElevatedButton, 'Redeem');
Finder get _dialog => find.byType(GiftClaimDialog);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

  testWidgets('repeated taps send one request; success closes the dialog',
      (tester) async {
    final provider = _ControlledGiftProvider();
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(_app(provider, result));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(_redeemButton);
    await tester.pump();

    // While in flight: spinner shown, button disabled, extra taps ignored.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final inFlightButton = tester.widget<ElevatedButton>(
      find.ancestor(
        of: find.byType(CircularProgressIndicator),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(inFlightButton.onPressed, isNull);
    await tester.tap(find.byWidget(inFlightButton), warnIfMissed: false);
    await tester.tap(find.byWidget(inFlightButton), warnIfMissed: false);
    expect(provider.callCount, 1);

    provider.completer.complete({'success': true, 'message': 'ok'});
    await tester.pumpAndSettle(const Duration(seconds: 4));

    expect(_dialog, findsNothing);
    expect(result.value, isTrue);
    expect(provider.callCount, 1);
  });

  testWidgets(
      'API error keeps dialog open, shows backend message, allows retry',
      (tester) async {
    final provider = _ControlledGiftProvider();
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(_app(provider, result));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(_redeemButton);
    await tester.pump();
    provider.completer.complete({
      'success': false,
      'message': 'Gift card is not valid for your region',
      'statusCode': 400,
    });
    await tester.pump();
    await tester.pump();

    expect(_dialog, findsOneWidget);
    expect(find.text('Gift card is not valid for your region'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(_redeemButton);
    expect(button.onPressed, isNotNull, reason: 'button re-enabled for retry');

    // Retry works and succeeds.
    provider.completer = Completer();
    await tester.tap(_redeemButton);
    await tester.pump();
    expect(provider.callCount, 2);
    provider.completer.complete({'success': true});
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(_dialog, findsNothing);
    expect(result.value, isTrue);
  });

  testWidgets('network failure keeps dialog open and re-enables the button',
      (tester) async {
    final provider = _ControlledGiftProvider();
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(_app(provider, result));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(_redeemButton);
    await tester.pump();
    provider.completer.completeError(Exception('SocketException: failed'));
    await tester.pump();
    await tester.pump();

    expect(_dialog, findsOneWidget);
    expect(
      find.textContaining('check your internet connection'),
      findsOneWidget,
    );
    expect(tester.widget<ElevatedButton>(_redeemButton).onPressed, isNotNull);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('success toast shows exactly the backend message',
      (tester) async {
    final provider = _ControlledGiftProvider();
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(_app(provider, result));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(_redeemButton);
    await tester.pump();
    provider.completer.complete(
        {'success': true, 'message': 'Movie unlocked: enjoy Bahubali!'});
    await tester.pump();
    await tester.pump();

    expect(find.text('Movie unlocked: enjoy Bahubali!'), findsOneWidget);
    expect(find.text('Gift card claimed successfully!'), findsNothing);
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(_dialog, findsNothing);
  });

  testWidgets('backend error text is never rewritten and the code is kept',
      (tester) async {
    final provider = _ControlledGiftProvider();
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(_app(provider, result));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(_redeemButton);
    await tester.pump();
    // Previously mapped to "Invalid gift card code. Please check and try again."
    provider.completer.complete({
      'success': false,
      'message': 'Invalid coupon code GF000843A767720E',
      'statusCode': 200,
    });
    await tester.pump();
    await tester.pump();

    expect(find.text('Invalid coupon code GF000843A767720E'), findsOneWidget);
    expect(_dialog, findsOneWidget);
    expect(find.text(_code), findsOneWidget);
    await tester.pumpAndSettle(const Duration(seconds: 4));
  });

  testWidgets('Profile flow: Redeem enabled only for exactly 16 characters',
      (tester) async {
    final provider = _ControlledGiftProvider();
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(
        _app(provider, result, initialCode: null, fromDeepLink: false));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    ElevatedButton redeem() => tester.widget<ElevatedButton>(_redeemButton);
    final field =
        find.descendant(of: _dialog, matching: find.byType(TextField));

    expect(redeem().onPressed, isNull, reason: 'empty');
    await tester.enterText(field, 'GF000843A76772');
    await tester.pump();
    expect(redeem().onPressed, isNull, reason: '14 chars');
    await tester.enterText(field, 'GF000843A767720EX');
    await tester.pump();
    expect(redeem().onPressed, isNull, reason: '17 chars');
    await tester.tap(_redeemButton, warnIfMissed: false);
    expect(provider.callCount, 0);

    await tester.enterText(field, 'gf000843a767720e');
    await tester.pump();
    expect(redeem().onPressed, isNotNull, reason: '16 chars');
    await tester.tap(_redeemButton);
    await tester.tap(_redeemButton, warnIfMissed: false);
    await tester.pump();
    expect(provider.callCount, 1);
    provider.completer.complete({'success': true, 'message': 'Done'});
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(_dialog, findsNothing);
  });

  testWidgets('Deep link flow: dialog opens pre-filled with the gift code',
      (tester) async {
    final provider = _ControlledGiftProvider();
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(_app(provider, result));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text(_code), findsOneWidget);
    expect(tester.widget<ElevatedButton>(_redeemButton).onPressed, isNotNull);
  });

  test('isValidGiftCardCodeLength', () {
    expect(isValidGiftCardCodeLength(''), isFalse);
    expect(isValidGiftCardCodeLength('   '), isFalse);
    expect(isValidGiftCardCodeLength('GF000843A76772'), isFalse);
    expect(isValidGiftCardCodeLength('GF000843A767720EX'), isFalse);
    expect(isValidGiftCardCodeLength('GF000843A767720E'), isTrue);
    expect(isValidGiftCardCodeLength(' gf00 0843a767720e '), isTrue);
  });
}
