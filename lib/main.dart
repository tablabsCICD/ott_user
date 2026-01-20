import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/localeLanguageProvider.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/provider/ticketProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/core/constant/prefrense_constant.dart';
import 'app/core/utils/sharepreferences.dart';
import 'app/provider/userProvider.dart';
import 'app/route/routes/routes.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();

  // Check theme preference
  final themeBool = prefs.getBool("isDark") ?? true;

  LocalSharePreferences localSharePreferences = LocalSharePreferences();
  // Check if user is logged in
  final isLoggedIn = await localSharePreferences
      .getBool(SharedPreferencesConstant.isUserLoggedIn);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(isDark: themeBool),
        ),
        ChangeNotifierProvider(
          create: (context) => LanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => UserProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => WalletProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => TicketProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => VideoProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => PurchaseContentProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => LocaleLanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => GiftProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ShortProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SeriesProvider(),
        ),
      ],
      child: MyApp(
        isLoggedIn: isLoggedIn,
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleLanguageProvider>(context);
    return MaterialApp(
      title: 'Filmytell',
      locale: localeProvider.locale,

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'), // English
        Locale('hi'), // Hindi (हिंदी)
        Locale('ur'), // Urdu (اُردُو)
        Locale('mr'), // Marathi (मराठी)
        Locale('ml'), // Malayalam (മലയാളം)
        Locale('ta'), // Tamil (தமிழ்)
        Locale('kn'), // Kannada (ಕನ್ನಡ)
        Locale('te'), // Telugu (తెలుగు)
        Locale('or'), // Odia (ଓଡ଼ିଆ)
        Locale('gu'), // Gujarati (ગુજરાતી)
        Locale('pa'), // Punjabi (ਪੰਜਾਬੀ)
        Locale('as'), // Assamese (অসমীয়া)
        Locale('bn'), // Bengali (বাংলা)
        Locale('ne'), // Nepali (नेपाली)
      ],
      theme: themeProvider.getTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      // Navigate based on login state
      initialRoute: "/",
      onGenerateRoute: RouteGenerator.generateRoute,
      /* home: SplashScreen(
        isLoggedIn: isLoggedIn,
      ),*/
    );
  }
}
