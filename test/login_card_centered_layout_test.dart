import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/localeLanguageProvider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildLoginScreen({
    Size surfaceSize = const Size(390, 844),
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<UserProvider>(create: (_) => UserProvider()),
        ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
        ChangeNotifierProvider<LocaleLanguageProvider>(
          create: (_) => LocaleLanguageProvider(),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(
            size: surfaceSize,
            viewInsets: viewInsets,
            padding: const EdgeInsets.only(top: 47, bottom: 34),
          ),
          child: const LoginCard(),
        ),
      ),
    );
  }

  group('LoginCard Centered Layout & Responsive Tests', () {
    testWidgets('renders all login elements in proper sequence', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildLoginScreen());
      await tester.pumpAndSettle();

      // Verify essential widgets exist
      expect(find.byType(SafeArea), findsWidgets);
      expect(find.byType(LayoutBuilder), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.byType(IntrinsicHeight), findsOneWidget);
      expect(find.byType(Center), findsWidgets);
      expect(find.byType(Hero), findsOneWidget); // Logo
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);

      // Verify vertical ordering: Logo above Card, Login title above field, button below field
      final logoTop = tester.getTopLeft(find.byType(Hero)).dy;
      final cardTop = tester.getTopLeft(find.byType(Card)).dy;
      final titleTop = tester.getTopLeft(find.text('Login')).dy;
      final sendOtpTop = tester.getTopLeft(find.text('Send OTP')).dy;

      expect(logoTop, lessThan(cardTop));
      expect(cardTop, lessThan(titleTop));
      expect(titleTop, lessThan(sendOtpTop));
    });

    testWidgets('centers login form vertically and horizontally within available area', (tester) async {
      const surfaceSize = Size(390, 844);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildLoginScreen(surfaceSize: surfaceSize));
      await tester.pumpAndSettle();

      final cardRect = tester.getRect(find.byType(Card));
      final screenCenter = surfaceSize.width / 2;

      // Check horizontal centering: card center should align with screen center
      expect(cardRect.center.dx, closeTo(screenCenter, 2.0));

      // Check that content is balanced vertically (not stuck at the extreme top or bottom)
      final logoTop = tester.getTopLeft(find.byType(Hero)).dy;
      final cardBottom = cardRect.bottom;

      expect(logoTop, greaterThan(60)); // Clear of the top AppBar
      expect(cardBottom, lessThan(surfaceSize.height - 20)); // Clear of the bottom
    });

    testWidgets('renders cleanly on small phone (iPhone SE 375x667) without overflow', (tester) async {
      const surfaceSize = Size(375, 667);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildLoginScreen(surfaceSize: surfaceSize));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Send OTP'), findsOneWidget);
    });

    testWidgets('renders cleanly on large phone (iPhone 16 Pro Max 430x932) without overflow', (tester) async {
      const surfaceSize = Size(430, 932);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildLoginScreen(surfaceSize: surfaceSize));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final cardRect = tester.getRect(find.byType(Card));
      expect(cardRect.center.dx, closeTo(430 / 2, 2.0));
      expect(cardRect.width, lessThanOrEqualTo(400));
    });

    testWidgets('renders cleanly on iPad / tablet (820x1180) and caps card width to 400', (tester) async {
      const surfaceSize = Size(820, 1180);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(buildLoginScreen(surfaceSize: surfaceSize));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final cardRect = tester.getRect(find.byType(Card));
      expect(cardRect.center.dx, closeTo(820 / 2, 2.0));
      expect(cardRect.width, lessThanOrEqualTo(400));
    });

    testWidgets('handles keyboard appearance gracefully via scroll view without overflow', (tester) async {
      const surfaceSize = Size(390, 844);
      tester.view.physicalSize = surfaceSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Simulate keyboard open by supplying viewInsets.bottom = 336
      await tester.pumpWidget(
        buildLoginScreen(
          surfaceSize: surfaceSize,
          viewInsets: const EdgeInsets.only(bottom: 336),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);

      // Verify that user can scroll down and tap the button
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -150));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Send OTP'), findsOneWidget);
    });
  });
}
