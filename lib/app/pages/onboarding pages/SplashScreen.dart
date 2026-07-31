import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/services/session_manager.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/services/app_update_service.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/onboarding pages/selectLanguagePage.dart';
import 'package:ott/app/route/routes/web_navigation_routes.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/presentation/web_landing/screens/web_landing_screen.dart';
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
  final AppUpdateService _appUpdateService = AppUpdateService();
  bool _isLoggedIn = false;
  int _flowVersion = 0;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    final flowVersion = ++_flowVersion;
    final requestedPath = widget.initialNavigationRoute?.path ?? '/';
    final loggedIn =
        await _prefs.getBool(SharedPreferencesConstant.isUserLoggedIn);
    if (!_isActiveFlow(flowVersion)) return;
    final token = await SessionManager.instance.token;
    if (!_isActiveFlow(flowVersion)) return;
    final hasToken = token != null;

    _isLoggedIn = kIsWeb ? loggedIn && hasToken : loggedIn;
    _logWebAuth(
      'Splash auth check requestedPath=$requestedPath loggedInFlag=$loggedIn hasToken=$hasToken authenticated=$_isLoggedIn',
    );

    if (widget.initialNavigationRoute == null) {
      // Splash delay
      await Future.delayed(const Duration(seconds: 2));
      if (!_isActiveFlow(flowVersion)) return;

      if (_supportsUpdateDialog) {
        final updateInfo = await _appUpdateService.getUpdateInfo();
        if (!_isActiveFlow(flowVersion)) return;

        final shouldShowUpdateDialog = updateInfo.isUpdateAvailable;

        if (shouldShowUpdateDialog) {
          await _showUpdateDialog(updateInfo);
          if (!_isActiveFlow(flowVersion)) return;
        }
      }
    }

    if (!_isActiveFlow(flowVersion)) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }

    final initialNavigationRoute = widget.initialNavigationRoute;
    final isLoggedIn = _isLoggedIn;
    final routeName = isLoggedIn
        ? initialNavigationRoute?.path
        : kIsWeb
            ? '/'
            : null;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        settings: RouteSettings(name: routeName),
        builder: (routeContext) {
          if (isLoggedIn) {
            final route = initialNavigationRoute;
            return NavigationPage(
              initialIndex: route?.index ?? 0,
              initialHomeContentType: route?.homeContentType ?? 'MOVIE',
            );
          }
          if (_shouldShowWebLandingForContext(routeContext)) {
            if (kIsWeb && kDebugMode) {
              developer.log(
                'Splash redirecting to web landing because authenticated=false',
                name: 'WebAuthGuard',
              );
            }
            return const WebLandingScreen();
          }
          return const SelectLocaleLanguagePage();
        },
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        DeepLinkService.instance.consumePendingNavigation();
      }
    });
  }

  bool _isActiveFlow(int flowVersion) {
    return mounted && flowVersion == _flowVersion;
  }

  @override
  void dispose() {
    _flowVersion++;
    super.dispose();
  }

  static bool _shouldShowWebLandingForContext(BuildContext context) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= 1024;
  }

  void _logWebAuth(String message) {
    if (!kIsWeb || !kDebugMode) return;
    developer.log(message, name: 'WebAuthGuard');
  }

  bool get _supportsUpdateDialog {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> _showUpdateDialog(AppUpdateInfo updateInfo) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return AlertDialog(
          backgroundColor: theme.cardColor,
          title: const Text('Update Available'),
          content: Text(
            'A newer version is available (${updateInfo.latestVersion}). Please update for the best experience.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(dialogContext, rootNavigator: true).pop(),
              child: const Text('Later'),
            ),
            ElevatedButton(
              onPressed: () async {
                final uri = Uri.parse(AppConstant.platformStoreLink);
                await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext, rootNavigator: true).pop();
                }
              },
              child: const Text('Update Now'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: SafeArea(
          child: Stack(fit: StackFit.expand, children: [
        kIsWeb
            ? Hero(
                tag: 'logo',
                child: Image.asset(
                  ImageConstant.webFullScreenLogo,
                  fit: BoxFit.cover,
                ),
              )
            : Hero(
                tag: 'logo',
                child: Transform.scale(
                  scale: ResponsiveWidget.isMobile(context) ? 1.2 : 1.0,
                  child: Image.asset(
                    ImageConstant.fullScreenLogo,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
        /* Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Text(
              'Watch First Day First Show',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: textSize,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                shadows: const [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black54,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ), */
      ])),
    );
  }
}
