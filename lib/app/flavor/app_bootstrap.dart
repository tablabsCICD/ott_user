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
  FilmytellFlavor? fallbackFlavor,
}) {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('UNCAUGHT_PLATFORM_ERROR: $error\n$stack');
    return false;
  };
  return _runFilmytellApp(fallbackFlavor: fallbackFlavor);
}

Future<void> _runFilmytellApp({
  FilmytellFlavor? fallbackFlavor,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.current = await _resolveFlavor(fallbackFlavor);

  bool themeBool = true;
  bool isLoggedIn = false;
  try {
    final prefs = await SharedPreferences.getInstance().timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => throw TimeoutException('prefs timeout'),
    );
    themeBool = prefs.getBool("isDark") ?? true;
    final localSharePreferences = LocalSharePreferences();
    isLoggedIn = await localSharePreferences.getBool(
      SharedPreferencesConstant.isUserLoggedIn,
    ).timeout(
      const Duration(milliseconds: 500),
      onTimeout: () => false,
    );
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Startup preferences read note: $e');
    }
  }

  // Mount application immediately so the first frame and splash screen render without UI blocking
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

  // Initialize non-critical services asynchronously in background with timeouts and safety guards
  unawaited(_initializeBackgroundServicesSafely());
}

Future<void> _initializeBackgroundServicesSafely() async {
  // 1. Initialize MediaKit safely in background without blocking UI rendering
  try {
    MediaKit.ensureInitialized();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('MediaKit background init note: $e');
    }
  }

  // 2. Firebase & Notifications (strictly bypassed on Jio STB and Web)
  if (!kIsWeb && !FlavorConfig.current.isJio) {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    } catch (_) {}

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 3));
    } catch (_) {}

    try {
      await NotificationService.instance.init().timeout(const Duration(seconds: 2));
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Notification initialization failed: $error');
      }
    }
  }

  // 3. Deep link service initialization (with timeout)
  try {
    await DeepLinkService.instance.init().timeout(const Duration(seconds: 2));
  } catch (_) {}
}

Future<FlavorConfig> _resolveFlavor(FilmytellFlavor? fallbackFlavor) async {
  // 1. Explicit flavor from appFlavor, FLAVOR, or FLUTTER_APP_FLAVOR takes highest priority
  if (FlavorConfig.hasExplicitFlavor) {
    return FlavorConfig.fromEnvironment();
  }

  // 2. Web platform
  if (kIsWeb) return const FlavorConfig.forFlavor(FilmytellFlavor.web);

  // 3. Dedicated entrypoint fallback (main_jio.dart, main_tv.dart, etc.)
  if (fallbackFlavor != null) {
    return FlavorConfig.forFlavor(fallbackFlavor);
  }

  try {
    final packageInfo = await PackageInfo.fromPlatform().timeout(
      const Duration(milliseconds: 500),
    );
    if (packageInfo.packageName == 'com.filmytell.ott.tv') {
      return const FlavorConfig.forFlavor(FilmytellFlavor.tv);
    }
  } catch (error) {
    if (kDebugMode) {
      debugPrint('Flavor package detection failed: $error');
    }
  }

  return FlavorConfig.fromEnvironment(fallback: FilmytellFlavor.mobile);
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
    if (!kIsWeb && !FlavorConfig.current.isJio) {
      sendNotification();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        NotificationService.instance.consumePendingNavigation();
      });
    }
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
    if (kIsWeb || FlavorConfig.current.isJio) return;
    try {
      await FirebaseMessaging.instance
          .subscribeToTopic('all')
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }
}
