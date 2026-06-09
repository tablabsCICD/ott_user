import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/services/app_update_service.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/onboarding pages/selectLanguagePage.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/presentation/web_landing/screens/web_landing_screen.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constant/prefrense_constant.dart';
import '../../core/utils/sharepreferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalSharePreferences _prefs = LocalSharePreferences();
  final AppUpdateService _appUpdateService = AppUpdateService();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    final loggedIn =
        await _prefs.getBool(SharedPreferencesConstant.isUserLoggedIn);

    _isLoggedIn = loggedIn;

    // Splash delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final updateInfo = await _appUpdateService.getUpdateInfo();
    if (!mounted) return;

    final shouldShowMobileUpdateDialog =
        updateInfo.isUpdateAvailable && ResponsiveWidget.isMobile(context);

    if (shouldShowMobileUpdateDialog) {
      await _showUpdateDialog(updateInfo);
      if (!mounted) return;
    }

    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) {
          if (_isLoggedIn) return NavigationPage();
          if (_shouldShowWebLanding(context)) {
            return const WebLandingScreen();
          }
          return const SelectLocaleLanguagePage();
        },
      ),
    );
  }

  bool _shouldShowWebLanding(BuildContext context) {
    return kIsWeb && MediaQuery.sizeOf(context).width >= 1024;
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
                final uri = Uri.parse(AppConstant.playStoreLink);
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
        ResponsiveWidget.isMobile(context)
            ? Hero(
                tag: 'logo',
                child: Image.asset(
                  ImageConstant.fullScreenLogo,
                  fit: BoxFit.cover,
                ),
              )
            : Hero(
                tag: 'logo',
                child: Image.asset(
                  ImageConstant.webFullScreenLogo,
                  fit: BoxFit.cover,
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
