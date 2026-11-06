import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/provider/localeLanguageProvider.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Same wiring as main.dart: MaterialApp.locale follows LocaleLanguageProvider.
Widget _app(LocaleLanguageProvider provider) {
  return ChangeNotifierProvider<LocaleLanguageProvider>.value(
    value: provider,
    child: Consumer<LocaleLanguageProvider>(
      builder: (context, locale, _) => MaterialApp(
        locale: locale.locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const _Probe(),
      ),
    ),
  );
}

class _Probe extends StatefulWidget {
  const _Probe();

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  // Survives language switches only if the screen is not rebuilt from scratch.
  final int createdAt = DateTime.now().microsecondsSinceEpoch;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(lang.purchaseHistory)),
      body: Text(lang.home),
    );
  }
}

void main() {
  testWidgets('switching app language updates UI immediately and persists',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final provider = LocaleLanguageProvider();
    await tester.pumpWidget(_app(provider));
    await tester.pumpAndSettle();

    final en = lookupAppLocalizations(const Locale('en'));
    final mr = lookupAppLocalizations(const Locale('mr'));
    final hi = lookupAppLocalizations(const Locale('hi'));
    expect(find.text(en.home), findsOneWidget);
    final stateBefore = tester.state<_ProbeState>(find.byType(_Probe));

    await provider.setLocale('mr');
    await tester.pumpAndSettle();
    expect(find.text(mr.home), findsOneWidget);
    expect(find.text(mr.purchaseHistory), findsOneWidget);
    expect(find.text(en.home), findsNothing);
    // Same screen instance: navigation state is kept, no restart.
    expect(tester.state<_ProbeState>(find.byType(_Probe)), same(stateBefore));

    await provider.setLocale('hi');
    await tester.pumpAndSettle();
    expect(find.text(hi.home), findsOneWidget);

    // Persisted and restored on the next app start.
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('selected_locale'), 'hi');
    final restarted = LocaleLanguageProvider();
    await tester.pumpWidget(_app(restarted));
    await tester.pumpAndSettle();
    expect(restarted.locale.languageCode, 'hi');
    expect(find.text(hi.home), findsOneWidget);
  });

  test('every supported locale has a generated localization class', () {
    final en = lookupAppLocalizations(const Locale('en'));
    for (final locale in AppLocalizations.supportedLocales) {
      // lookup throws for unsupported locales; generation fails on bad ARB.
      expect(lookupAppLocalizations(locale), isNotNull);
    }
    expect(en.home, 'Home');
  });
}
