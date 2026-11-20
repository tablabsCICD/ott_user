import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/services/gift_deep_link_service.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/gift_claim_dialog.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockGiftProvider extends GiftProvider {
  String? lastClaimedCode;
  int callCount = 0;

  @override
  Future<Map<String, dynamic>> useGiftByCoupon(String couponCode) async {
    callCount++;
    lastClaimedCode = couponCode;
    return {
      "success": true,
      "message": "Gift card claimed successfully!",
    };
  }
}

Widget _buildTestApp({
  required _MockGiftProvider giftProvider,
  VoidCallback? onOpenDeepLinkDialog,
  VoidCallback? onOpenProfileDialog,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<GiftProvider>.value(value: giftProvider),
      ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: onOpenDeepLinkDialog ??
                      () {
                        showGiftClaimDialog(
                          context,
                          initialCouponCode: 'GF000843A767720E',
                          isFromDeepLink: true,
                        );
                      },
                  child: const Text('Open From Deep Link'),
                ),
                ElevatedButton(
                  onPressed: onOpenProfileDialog ??
                      () {
                        showGiftClaimDialog(
                          context,
                          isFromDeepLink: false,
                        );
                      },
                  child: const Text('Open From Profile'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('Gift Card Claim Dialog Editability Based on Entry Point', () {
    testWidgets(
        'Test A: Deep-link flow pre-populates code, locks input field (read-only), and allows redemption',
        (tester) async {
      final mockProvider = _MockGiftProvider();

      await tester.pumpWidget(_buildTestApp(giftProvider: mockProvider));
      await tester.pumpAndSettle();

      // Open through deep link entry point
      await tester.tap(find.text('Open From Deep Link'));
      await tester.pumpAndSettle();

      // Verify Claim Gift Card dialog opens
      expect(find.text('Enter Gift Card Number'), findsOneWidget);

      // Verify coupon code is prefilled
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'GF000843A767720E');

      // Verify input field is read-only
      expect(textField.readOnly, isTrue);

      // Verify Redeem button claims the prefilled code
      await tester.tap(find.text('Redeem'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockProvider.callCount, 1);
      expect(mockProvider.lastClaimedCode, 'GF000843A767720E');
      expect(find.text('Gift card claimed successfully!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets(
        'Test B: Profile flow opens editable input field, allows typing, editing, and redemption',
        (tester) async {
      final mockProvider = _MockGiftProvider();

      await tester.pumpWidget(_buildTestApp(giftProvider: mockProvider));
      await tester.pumpAndSettle();

      // Open through Profile entry point
      await tester.tap(find.text('Open From Profile'));
      await tester.pumpAndSettle();

      // Verify Claim Gift Card dialog opens
      expect(find.text('Enter Gift Card Number'), findsOneWidget);

      // Verify input field is NOT read-only (editable)
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isFalse);
      expect(textField.controller?.text, isEmpty);

      // Type initial gift code
      await tester.enterText(find.byType(TextField), 'GF11112222333344');
      await tester.pumpAndSettle();
      expect(find.text('GF11112222333344'), findsOneWidget);

      // Modify / replace code before submitting
      await tester.enterText(find.byType(TextField), 'GF55556666777788');
      await tester.pumpAndSettle();
      expect(find.text('GF55556666777788'), findsOneWidget);

      // Submit claim
      await tester.tap(find.text('Redeem'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockProvider.callCount, 1);
      expect(mockProvider.lastClaimedCode, 'GF55556666777788');
      expect(find.text('Gift card claimed successfully!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets(
        'Test C: Navigation and state switching preserves correct editability between deep link and profile flows',
        (tester) async {
      final mockProvider = _MockGiftProvider();

      await tester.pumpWidget(_buildTestApp(giftProvider: mockProvider));
      await tester.pumpAndSettle();

      // 1. Open from deep link
      await tester.tap(find.text('Open From Deep Link'));
      await tester.pumpAndSettle();

      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isTrue);
      expect(textField.controller?.text, 'GF000843A767720E');

      // 2. Close dialog without claiming
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Enter Gift Card Number'), findsNothing);

      // 3. Open through Profile flow
      await tester.tap(find.text('Open From Profile'));
      await tester.pumpAndSettle();

      // 4. Confirm field is editable and has no stale deep link code
      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isFalse);
      expect(textField.controller?.text, isEmpty);

      // 5. Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // 6. Open again from deep link
      await tester.tap(find.text('Open From Deep Link'));
      await tester.pumpAndSettle();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.readOnly, isTrue);
      expect(textField.controller?.text, 'GF000843A767720E');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets(
        'Test D: GiftDeepLinkService showGiftDialogForCode launches dialog with readOnly: true',
        (tester) async {
      final mockProvider = _MockGiftProvider();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(SharedPreferencesConstant.isUserLoggedIn, true);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<GiftProvider>.value(value: mockProvider),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      GiftDeepLinkService.instance.showGiftDialogForCode(
                        context,
                        'GF000843A767720E',
                      );
                    },
                    child: const Text('Trigger Gift Deep Link Service'),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap to trigger dialog via GiftDeepLinkService
      await tester.tap(find.text('Trigger Gift Deep Link Service'));
      await tester.pumpAndSettle();

      // Confirm dialog opened with readOnly: true
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'GF000843A767720E');
      expect(textField.readOnly, isTrue);

      // Claim through dialog
      await tester.tap(find.text('Redeem'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(mockProvider.callCount, 1);
      expect(mockProvider.lastClaimedCode, 'GF000843A767720E');
      expect(find.text('Gift card claimed successfully!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));
    });
  });
}
