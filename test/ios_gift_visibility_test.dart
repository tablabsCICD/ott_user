import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/services/gift_deep_link_service.dart';
import 'package:ott/app/core/services/wallet_platform.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/localeLanguageProvider.dart';
import 'package:ott/app/provider/onboarding_tour_provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/movieCard.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _giftCode = 'GF000843A767720E';

Widget _app(Widget home) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(isDark: true)),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => LocaleLanguageProvider()),
      ChangeNotifierProvider(create: (_) => BookmarkProvider()),
      ChangeNotifierProvider(create: (_) => OnboardingTourProvider()),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    ),
  );
}

Widget _movieCardApp() {
  return _app(
    Scaffold(
      body: Center(
        child: SizedBox(
          height: MovieCard.standardHeight,
          width: MovieCard.mobileCardWidth,
          child: MovieCard(
            movie: Content(
              id: 101,
              title: 'Gift Test Movie',
              type: ContentType.movie,
              price: 99.0,
              isRental: false,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _seedPendingGift() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(SharedPreferencesConstant.pendingGiftCode, _giftCode);
  await DeepLinkService.instance.savePendingDeepLinkTarget(
    DeepLinkTarget(type: DeepLinkContentType.gift, couponCode: _giftCode),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('Gift options hidden on iOS', () {
    final ios = TargetPlatformVariant.only(TargetPlatform.iOS);

    test('gifting flag is on for native iOS', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(WalletPlatform.isGiftingHidden, isTrue);
    });

    testWidgets('pending gift popup is never shown', (tester) async {
      await GiftDeepLinkService.instance.savePendingGiftCode(_giftCode);
      late BuildContext ctx;
      await tester.pumpWidget(_app(Builder(builder: (c) {
        ctx = c;
        return const Scaffold();
      })));

      expect(
        await GiftDeepLinkService.instance.checkAndProcessPendingGift(ctx),
        isFalse,
      );
      expect(
        await GiftDeepLinkService.instance.showGiftDialogForCode(
          ctx,
          _giftCode,
        ),
        isFalse,
      );
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(find.byType(LoginCard), findsNothing);
    }, variant: ios);

    test('deferred gift install check does not read the clipboard', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(
        await GiftDeepLinkService.instance.checkDeferredGiftInstall(),
        isNull,
      );
    });

    testWidgets('login screen hides the gift code badge', (tester) async {
      await _seedPendingGift();
      await tester.pumpWidget(_app(const LoginCard()));
      await tester.pumpAndSettle();

      expect(find.textContaining('Gift Code:'), findsNothing);
    }, variant: ios);

    testWidgets('movie card more-actions menu has no Gift item',
        (tester) async {
      await tester.pumpWidget(_movieCardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Gift'), findsNothing);
    }, variant: ios);

    test('onboarding tour copy does not mention Gift', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final tour = OnboardingTourProvider()..replayTour();
      final moreActions = tour.activeSteps
          .firstWhere((s) => s.id == FeatureTourStepId.moreActions);
      expect(moreActions.description, isNot(contains('Gift')));
    });
  });

  group('Gift options unchanged on Android', () {
    final android = TargetPlatformVariant.only(TargetPlatform.android);

    test('gifting flag is off', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(WalletPlatform.isGiftingHidden, isFalse);
    });

    testWidgets('login screen still shows the gift code badge', (tester) async {
      await _seedPendingGift();
      await tester.pumpWidget(_app(const LoginCard()));
      await tester.pumpAndSettle();

      expect(find.text('Gift Code: $_giftCode'), findsOneWidget);
    }, variant: android);

    testWidgets('movie card more-actions menu still has Gift item',
        (tester) async {
      await tester.pumpWidget(_movieCardApp());
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Gift'), findsOneWidget);
    }, variant: android);

    test('onboarding tour copy still mentions Gift', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final tour = OnboardingTourProvider()..replayTour();
      final moreActions = tour.activeSteps
          .firstWhere((s) => s.id == FeatureTourStepId.moreActions);
      expect(moreActions.description, contains('Gift'));
    });
  });
}
