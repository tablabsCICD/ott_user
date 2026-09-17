import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/pages/profile%20page/ProfilePage.dart';
import 'package:ott/app/provider/localeLanguageProvider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

Widget createTestableWidget(Widget child, {GlobalKey<NavigatorState>? navigatorKey}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider(isDark: false)),
      ChangeNotifierProvider(create: (_) => UserProvider()),
      ChangeNotifierProvider(create: (_) => WalletProvider()),
      ChangeNotifierProvider(create: (_) => LocaleLanguageProvider()),
    ],
    child: MaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  testWidgets('ProfilePage shows back button when showBackButton is true',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestableWidget(
        const ProfilePage(showBackButton: true),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
  });

  testWidgets(
      'ProfilePage hides back button when embedded in NavigationPage (onOpenDetail provided)',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestableWidget(
        ProfilePage(
          onOpenDetail: (title, page) {},
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
  });

  testWidgets('Tapping back button pops ProfilePage back to previous screen',
      (WidgetTester tester) async {
    final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      createTestableWidget(
        const Scaffold(body: Text('HomeScreen')),
        navigatorKey: navKey,
      ),
    );
    await tester.pump();

    navKey.currentState!.push(
      MaterialPageRoute(
        builder: (_) => const ProfilePage(showBackButton: true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    expect(find.text('HomeScreen'), findsOneWidget);
  });
}
