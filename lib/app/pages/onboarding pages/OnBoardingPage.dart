import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/onboarding%20pages/selectLanguagePage.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';

class OnboardingPage extends StatefulWidget {
  @override
  _OnboardingPageState createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/images/devices.png',
      'title': 'Watch on any device',
      'description':
          'Stream on your phone, tablet, and laptop without paying more.',
    },
    {
      'image': 'assets/images/download.png',
      'title': '3,2,1... Download!',
      'description': 'Always have something to watch offline.',
    },
    {
      'image': 'assets/images/contract.png',
      'title': 'No annoying contracts',
      'description': 'Join today, cancel any time.',
    },
  ];

  int _currentIndex = 0;

  void _goToNext() {
    if (_currentIndex < _onboardingData.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // Navigate to the next page or home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) =>
                SelectLocaleLanguagePage()), // Replace with your HomePage
      );
    }
  }

  void _skipOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) =>
              SelectLocaleLanguagePage()), // Replace with your HomePage
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final currentData = _onboardingData[_currentIndex];
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: EdgeInsets.only(
                  top: ResponsiveWidget.isMobile(context) ? 30 : 60,
                  right: ResponsiveWidget.isMobile(context) ? 30 : 60,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Hero(
                      tag: "logo",
                      child: Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: Image.asset(
                          ImageConstant.logo2,
                          width: ResponsiveWidget.isMobile(context) ? 60 : 60,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _skipOnboarding,
                      child: Text(
                        lang.skip,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Image
                  Image.asset(
                    currentData['image']!,
                    height: ResponsiveWidget.isMobile(context) ? 150 : 200,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 20),
                  // Title
                  Text(
                    currentData['title']!,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.canvasColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      currentData['description']!,
                      style: TextStyle(fontSize: 16, color: theme.canvasColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom Next Button
            Padding(
              padding: EdgeInsets.only(
                bottom: ResponsiveWidget.isMobile(context) ? 30 : 60,
                left: 30,
                right: 30,
              ),
              child: GestureDetector(
                onTap: _goToNext,
                child: Container(
                  height: 50,
                  width: ResponsiveWidget.isMobile(context)
                      ? double.infinity
                      : 400,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(
                      15,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _currentIndex == _onboardingData.length - 1
                          ? lang.getStarted
                          : lang.next,
                      style: TextStyle(
                        fontSize: 18,
                        color: theme.canvasColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
