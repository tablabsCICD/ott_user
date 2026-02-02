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
    final size = MediaQuery.of(context).size;

    /// Responsive logo size
    double logoSize;
    if (ResponsiveWidget.isMobile(context)) {
      logoSize = size.width * 0.42;
    } else if (ResponsiveWidget.isTablet(context)) {
      logoSize = size.width * 0.28;
    } else {
      logoSize = size.width * 0.18;
    }

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
        child: Center(
          child: Column(
            children: [
              const Spacer(flex: 3),

              /// Logo
              Hero(
                tag: 'logo',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(logoSize),
                  child: Image.asset(
                    ImageConstant.logo,
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const Spacer(flex: 2),

              /// Tagline
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Watch First Day First Show',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: textSize,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const Spacer(flex: 4),
            ],
          ),
        ),
      ),
    );
  }
}
