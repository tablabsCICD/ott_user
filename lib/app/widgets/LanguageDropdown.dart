import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../provider/localeLanguageProvider.dart';

class LanguageDropdown extends StatelessWidget {
  final bool isTitle;
  const LanguageDropdown({
    super.key,
    this.isTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleLanguageProvider>(context);
    final currentCode = provider.locale.languageCode;
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context);

    final Map<String, String> languages = {
      'en': 'English',
      'hi': 'हिंदी',
      'ur': 'اُردُو',
      'mr': 'मराठी',
      'ml': 'മലയാളം',
      'ta': 'தமிழ்',
      'kn': 'ಕನ್ನಡ',
      'te': 'తెలుగు',
      'or': 'ଓଡ଼ିଆ',
      'gu': 'ગુજરાતી',
      'pa': 'ਪੰਜਾਬੀ',
      'as': 'অসমীয়া',
      'bn': 'বাংলা',
      'ne': 'नेपाली',
    };

    return PopupMenuButton<String>(
      color: theme.cardColor,
      icon: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isTitle)
            Text(
              '${lang?.translate ?? 'Select Language'}  ',
              style: TextStyle(
                color: theme.canvasColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          SvgPicture.asset(
            'assets/icons/translate_swap.svg',
            width: 30,
            height: 30,
            colorFilter: ColorFilter.mode(
              Theme.of(context).canvasColor,
              BlendMode.srcIn,
            ),
          )

          // Icon(
          //   FontAwesomeIcons.language,
          //   color: theme.canvasColor,
          // ),
        ],
      ),
      tooltip: lang?.translate ?? 'Select Language',
      onSelected: provider.setLocale,
      itemBuilder: (context) {
        return languages.entries.map((entry) {
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                if (entry.key == currentCode)
                  Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.green,
                  ),
                if (entry.key == currentCode) const SizedBox(width: 6),
                Text(
                  entry.value,
                  style: TextStyle(
                    color: theme.canvasColor,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
