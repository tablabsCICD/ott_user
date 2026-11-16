import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/widgets/LanguageDropdown.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';

class SelectLocaleLanguagePage extends StatelessWidget {
  const SelectLocaleLanguagePage({super.key});

  void _goNext(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginCard(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    // Android TV: compact welcome card with a remote-operable language menu.
    if (ResponsiveWidget.isAndroidTv(context)) {
      return _TvSelectLocaleLanguage(onNext: () => _goNext(context));
    }

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
                    onTap: () => _goNext(context),
                    child: ElevatedButton(
                      autofocus: ResponsiveWidget.isTabletOrTv(context),
                      onPressed: () => _goNext(context),
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

/// Android TV layout of [SelectLocaleLanguagePage]. Holds the popup key so
/// OK on the language selector opens the locale menu (on TV the dropdown is
/// otherwise not reachable with the remote).
class _TvSelectLocaleLanguage extends StatefulWidget {
  const _TvSelectLocaleLanguage({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_TvSelectLocaleLanguage> createState() =>
      _TvSelectLocaleLanguageState();
}

class _TvSelectLocaleLanguageState extends State<_TvSelectLocaleLanguage> {
  final GlobalKey<PopupMenuButtonState<String>> _menuKey =
      GlobalKey<PopupMenuButtonState<String>>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(TvDesign.pageGutter),
          child: Container(
            width: 360,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(TvDesign.panelRadius),
              border: Border.all(
                color: theme.canvasColor.withValues(alpha: 0.06),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Hero(
                    tag: "logo",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        ImageConstant.logo,
                        width: 72,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  lang.selectPreferredLanguage,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TvDesign.pageTitle(theme).copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),
                Center(
                  child: OttTvFocus(
                    borderRadius: 8,
                    scale: 1.04,
                    semanticLabel: lang.selectPreferredLanguage,
                    onTap: () => _menuKey.currentState?.showButtonMenu(),
                    child: LanguageDropdown(
                      menuKey: _menuKey,
                      showSelectedLabel: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      backgroundColor: theme.scaffoldBackgroundColor,
                      constraints: const BoxConstraints(minHeight: 34),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                OttTvFocus(
                  autofocus: true,
                  borderRadius: 8,
                  scale: 1.04,
                  semanticLabel: lang.next,
                  onTap: widget.onNext,
                  child: Container(
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      lang.next,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
