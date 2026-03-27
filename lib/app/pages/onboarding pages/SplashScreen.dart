import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/onboarding pages/selectLanguagePage.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

import '../../core/constant/prefrense_constant.dart';
import '../../core/utils/sharepreferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalSharePreferences _prefs = LocalSharePreferences();
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _startFlow();
  }

  Future<void> _startFlow() async {
    final loggedIn =
        await _prefs.getBool(SharedPreferencesConstant.isUserLoggedIn);

    _isLoggedIn = loggedIn ?? false;

    // Splash delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _isLoggedIn ? NavigationPage() : const SelectLocaleLanguagePage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    /// Responsive text size
    double textSize;
    if (ResponsiveWidget.isMobile(context)) {
      textSize = 16;
    } else if (ResponsiveWidget.isTablet(context)) {
      textSize = 20;
    } else {
      textSize = 22;
    }

    return Scaffold(
      backgroundColor: theme.primaryColor,
      body: SafeArea(
          child: Stack(fit: StackFit.expand, children: [
        Hero(
          tag: 'logo',
          child: Image.asset(
            ImageConstant.fullScreenLogo,
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
