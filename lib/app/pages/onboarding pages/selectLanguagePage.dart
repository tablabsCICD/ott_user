import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/NavigationPage.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';

class SelectLocaleLanguagePage extends StatelessWidget {
  const SelectLocaleLanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = ResponsiveWidget.isMobile(context);

          return Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: "logo",
                    child: ClipRRect(
                      borderRadius: BorderRadiusGeometry.circular(25),
                      child: Image.asset(
                        ImageConstant.logo,
                        width: ResponsiveWidget.isMobile(context) ? 100 : 150,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                  Text(
                    lang.selectPreferredLanguage,
                    style: TextStyle(
                      color: theme.canvasColor,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  OttTvFocus(
                    borderRadius: 20,
                    scale: 1.04,
                    semanticLabel: lang.selectPreferredLanguage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 5,
                        horizontal: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const LanguageDropdown(isTitle: false),
                    ),
                  ),
                  const SizedBox(height: 40),
                  OttTvFocus(
                    autofocus: ResponsiveWidget.isTabletOrTv(context),
                    borderRadius: 10,
                    scale: 1.05,
                    semanticLabel: lang.next,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResponsiveWidget.isTv(context)
                              ? const NavigationPage()
                              : const LoginCard(),
                        ),
                      );
                    },
                    child: ElevatedButton(
                      autofocus: ResponsiveWidget.isTabletOrTv(context),
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ResponsiveWidget.isTv(context)
                                ? const NavigationPage()
                                : const LoginCard(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 30),
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        lang.next,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
