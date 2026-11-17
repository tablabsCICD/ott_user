import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/localeLanguageProvider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/ott_tv_app_shell.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Jio STB / Android TV login: the remote must be able to move the focus and
/// type a number. Regression: the focus used to land on a full-screen
/// key-listener wrapper, from which no D-pad direction had a neighbour, so
/// every remote key did nothing.
void main() {
  late FlavorConfig previousFlavor;

  setUp(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
    previousFlavor = FlavorConfig.current;
    FlavorConfig.current = const FlavorConfig.forFlavor(FilmytellFlavor.jio);
  });

  tearDown(() => FlavorConfig.current = previousFlavor);

  Future<void> pumpLogin(WidgetTester tester) async {
    // The test font (Ahem) renders "Skip & Browse App as Guest" wider than
    // the card; the real fonts fit. Ignore only that layout overflow.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.exceptionAsString().contains('RenderFlex overflowed')) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    // Landscape TV canvas. Larger than the 960x540 device canvas only
    // because the test font (Ahem: every glyph a full square) is far wider
    // than the real fonts; the TV layout is chosen by the flavor.
    await tester.binding.setSurfaceSize(const Size(1600, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => LocaleLanguageProvider()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // Same app-level remote shell as the TV / Jio build.
          builder: (context, child) => OttTvAppShell(child: child!),
          home: const LoginCard(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  String? focusLabel() => FocusManager.instance.primaryFocus?.debugLabel;

  testWidgets('focus starts on the first keypad key', (tester) async {
    await pumpLogin(tester);
    expect(focusLabel(), 'login-tv-keypad-0');
  });

  testWidgets('D-pad moves the focus and OK types the focused digit',
      (tester) async {
    await pumpLogin(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(focusLabel(), 'login-tv-keypad-1');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 200));

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focusLabel(), 'login-tv-keypad-4');

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('25'), findsOneWidget);
  });

  testWidgets('remote number keys and Delete edit the number',
      (tester) async {
    await pumpLogin(tester);

    for (final key in [
      LogicalKeyboardKey.digit9,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.numpad7,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }
    expect(find.text('987'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(find.text('98'), findsOneWidget);
  });

  testWidgets('D-pad reaches Send OTP and Skip below the keypad',
      (tester) async {
    await pumpLogin(tester);

    for (var i = 0; i < 4; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    expect(focusLabel(), 'login-submit');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focusLabel(), 'login-skip');
  });

  testWidgets('clicking the number box focuses it; keyboard types into it',
      (tester) async {
    await pumpLogin(tester);

    await tester.tap(
      find.text('Enter 10 digit number'),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(focusLabel(), 'login-mobile');

    for (final key in [
      LogicalKeyboardKey.digit9,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit7,
    ]) {
      await tester.sendKeyEvent(key);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    expect(find.text('98'), findsOneWidget);
    // Focus stays on the box while typing.
    expect(focusLabel(), 'login-mobile');
  });

  testWidgets('mouse clicks on keypad keys type digits', (tester) async {
    await pumpLogin(tester);

    for (final digit in ['4', '2']) {
      await tester.tap(find.text(digit), kind: PointerDeviceKind.mouse);
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.text('42'), findsOneWidget);
  });

  testWidgets('D-pad Up from the keypad reaches the number box',
      (tester) async {
    await pumpLogin(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(focusLabel(), 'login-mobile');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(focusLabel(), startsWith('login-tv-keypad-'));
  });
}
