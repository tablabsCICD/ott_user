import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/onboarding%20pages/OnBoardingPage.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

import '../../core/constant/prefrense_constant.dart';
import '../../core/utils/sharepreferences.dart';

class SplashScreen extends StatefulWidget {
  //final bool isLoggedIn;

  //SplashScreen({super.key, required this.isLoggedIn});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  bool isLoggedIn = false;
  final LocalSharePreferences localSharePreferences = LocalSharePreferences();

  Future<void> _initializeSplash() async {
    await getData();
  }

  Future<void> getData() async {
    final bool? loggedIn = await localSharePreferences
        .getBool(SharedPreferencesConstant.isUserLoggedIn);
    print(loggedIn);
    setState(() {
      isLoggedIn = loggedIn ?? false; // Default to false if null
    });
  }

  @override
  void initState() {
    super.initState();
    _initializeSplash();

    // Initialize the animation controller for the ripple effect
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(); // Loop the animation

    // Timer for navigation after 2 seconds
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => isLoggedIn ? NavigationPage() : OnboardingPage(),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 100,
            ),
            Hero(
              tag: "logo",
              child: Image.asset(
                ImageConstant.logo,
                width: ResponsiveWidget.isMobile(context) ? 250 : 400,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(
              height: ResponsiveWidget.isMobile(context) ? 150 : 10,
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Text(
                'Discover, Watch & Collect the Latest Movies & TV',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveWidget.isMobile(context) ? 15 : 20,
                  color: theme.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
