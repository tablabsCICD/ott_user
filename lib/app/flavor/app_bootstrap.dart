import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_kit/media_kit.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/services/notification_service.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/giftProvider.dart';
import 'package:ott/app/provider/language_provider.dart';
import 'package:ott/app/provider/localeLanguageProvider.dart';
import 'package:ott/app/provider/offline_download_provider.dart';
import 'package:ott/app/provider/onboarding_tour_provider.dart';
import 'package:ott/app/provider/playMediaProvider.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/app/provider/session_device_provider.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/ticketProvider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/provider/wallet_provider.dart';
import 'package:ott/app/route/navigation_service.dart';
import 'package:ott/app/route/route_observer.dart';
import 'package:ott/app/route/routes/routes.dart';
import 'package:ott/app/widgets/feature_tour.dart';
import 'package:ott/app/widgets/ott_tv_app_shell.dart';
import 'package:ott/firebase_options.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> runFilmytellApp({
  required FilmytellFlavor fallbackFlavor,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.current = await _resolveFlavor(fallbackFlavor);
  MediaKit.ensureInitialized();
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await DeepLinkService.instance.init();

  final prefs = await SharedPreferences.getInstance();
  final themeBool = prefs.getBool("isDark") ?? true;

  final localSharePreferences = LocalSharePreferences();
  final isLoggedIn = await localSharePreferences.getBool(
    SharedPreferencesConstant.isUserLoggedIn,
  );

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
        ChangeNotifierProvider(
          create: (_) => PlayMediaProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OfflineDownloadProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => BookmarkProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => SessionDeviceProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => OnboardingTourProvider(),
        ),
      ],
      child: MyApp(
        isLoggedIn: isLoggedIn,
      ),
    ),
  );

  if (!kIsWeb) {
    unawaited(_initializeNotificationsSafely());
  }
}

Future<FlavorConfig> _resolveFlavor(FilmytellFlavor fallbackFlavor) async {
  final configured = FlavorConfig.fromEnvironment(fallback: fallbackFlavor);
  if (kIsWeb) return configured;

  try {
    final packageInfo = await PackageInfo.fromPlatform();
    if (packageInfo.packageName == 'com.filmytell.ott.tv') {
      return const FlavorConfig.forFlavor(FilmytellFlavor.tv);
    }
    if (packageInfo.packageName == 'com.filmytell.ott') {
      return const FlavorConfig.forFlavor(FilmytellFlavor.mobile);
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Flavor package detection failed: $error');
    }
  }

  return configured;
}

Future<void> _initializeNotificationsSafely() async {
  try {
    await NotificationService.instance.init();
  } catch (error, stackTrace) {
    debugPrint('Notification initialization failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({
    super.key,
    required this.isLoggedIn,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    sendNotification();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationService.instance.consumePendingNavigation();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleLanguageProvider>(context);
    if (kDebugMode) {
      debugPrint(
        '[LocaleLanguage] MaterialApp rebuild locale=${localeProvider.locale.languageCode} mounted=$mounted',
      );
    }
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
        Locale('en'),
        Locale('hi'),
        Locale('ur'),
        Locale('mr'),
        Locale('ml'),
        Locale('ta'),
        Locale('kn'),
        Locale('te'),
        Locale('or'),
        Locale('gu'),
        Locale('pa'),
        Locale('as'),
        Locale('bn'),
        Locale('ne'),
      ],
      theme: themeProvider.getTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      navigatorObservers: [routeObserver],
      initialRoute: "/",
      onGenerateRoute: RouteGenerator.generateRoute,
      builder: (context, child) {
        final routeChild = child ?? const SizedBox.shrink();
        return Stack(
          fit: StackFit.expand,
          children: [
            kIsWeb ? routeChild : OttTvAppShell(child: routeChild),
            const Positioned.fill(child: FeatureTourOverlay()),
          ],
        );
      },
    );
  }

  Future<void> sendNotification() async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.subscribeToTopic('all');
  }
}
