import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/services/session_manager.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/services/referral_service.dart';
import 'package:ott/app/flavor/app_flavor.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/route/routes/web_navigation_routes.dart';
import 'package:ott/presentation/web_landing/screens/web_landing_screen.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constant/prefrense_constant.dart';
import '../../core/utils/sharepreferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.initialNavigationRoute,
  });

  final WebNavigationRoute? initialNavigationRoute;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalSharePreferences _prefs = LocalSharePreferences();
  bool _isLoggedIn = false;
  int _flowVersion = 0;
  bool _hasNavigated = false;
  Timer? _safetyTimer;

  @override
  void initState() {
    super.initState();
    debugPrint('SPLASH_TRACE: initState called');
    // Safety timer: guarantees the splash screen will NEVER freeze indefinitely
    _safetyTimer = Timer(const Duration(seconds: 4), () {
      debugPrint('SPLASH_TRACE: safety timer fired, mounted=$mounted, _hasNavigated=$_hasNavigated');
      if (mounted && !_hasNavigated) {
        _performNavigation(isLoggedIn: _isLoggedIn);
      }
    });
    _startFlow();
  }

  Future<void> _startFlow() async {
    debugPrint('SPLASH_TRACE: _startFlow started');
    final flowVersion = ++_flowVersion;
    final requestedPath = widget.initialNavigationRoute?.path ?? '/';

    try {
      // Recover any deferred install referral code on cold start / first launch
      unawaited(ReferralService.instance.checkDeferredInstallReferrer());

      final loggedIn = await _prefs
          .getBool(SharedPreferencesConstant.isUserLoggedIn)
          .timeout(
            const Duration(milliseconds: 1000),
            onTimeout: () => false,
          );
      if (!_isActiveFlow(flowVersion)) return;
    }
  }

  void _performNavigation({required bool isLoggedIn}) {
    debugPrint('SPLASH_TRACE: _performNavigation entered, isLoggedIn=$isLoggedIn, mounted=$mounted, _hasNavigated=$_hasNavigated');
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _safetyTimer?.cancel();

    final initialNavigationRoute = widget.initialNavigationRoute;
    final routeName = isLoggedIn
        ? initialNavigationRoute?.path
        : kIsWeb
            ? '/'
            : null;

    debugPrint('SPLASH_TRACE: pushing route replacement, routeName=$routeName');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (routeContext) {
          debugPrint('SPLASH_TRACE: MaterialPageRoute builder executing, isLoggedIn=$isLoggedIn');
          if (isLoggedIn) {
            final route = initialNavigationRoute;
            return NavigationPage(
              initialIndex: route?.index ?? 0,
              initialHomeContentType: route?.homeContentType ?? 'MOVIE',
            );
          }
          if (_shouldShowWebLandingForContext(routeContext)) {
            return const WebLandingScreen();
          }
          debugPrint('SPLASH_TRACE: Returning const LoginCard()');
          return const LoginCard();
        },
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && isLoggedIn) {
        DeepLinkService.instance.consumePendingNavigation();
      }
    });
  }

  bool _isActiveFlow(int flowVersion) {
    return mounted && flowVersion == _flowVersion && !_hasNavigated;
  }

  @override
  void dispose() {
    _flowVersion++;
    _safetyTimer?.cancel();
    super.dispose();
  }

  static bool _shouldShowWebLandingForContext(BuildContext context) {
    return kIsWeb;
  }

  void _logWebAuth(String message) {
    if (!kIsWeb || !kDebugMode) return;
    developer.log(message, name: 'WebAuthGuard');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Hero(
              tag: 'logo',
              child: Image.asset(
                kIsWeb
                    ? ImageConstant.webFullScreenLogo
                    : ImageConstant.fullScreenLogo,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
