import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../provider/localeLanguageProvider.dart';

class LanguageDropdown extends StatefulWidget {
  const LanguageDropdown({
    super.key,
    this.isTitle = false,
    this.showSelectedLabel = false,
    this.foregroundColor,
    this.backgroundColor,
    this.padding,
    this.constraints,
  });

  final bool isTitle;
  final bool showSelectedLabel;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;

  static const Map<String, String> languages = {
    'en': 'English',
    'hi': 'हिन्दी',
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

  @override
  State<LanguageDropdown> createState() => _LanguageDropdownState();
}

class _LanguageDropdownState extends State<LanguageDropdown> {
  Future<void> _selectLanguage(String languageCode) async {
    if (!mounted) return;
    final provider = context.read<LocaleLanguageProvider>();
    final previousCode = provider.locale.languageCode;
    _logLocale(
      'Language selected previous=$previousCode selected=$languageCode mounted=$mounted',
    );

    await provider.setLocale(languageCode);

    if (!mounted) {
      _logLocale(
        'Language dropdown unmounted after locale change selected=$languageCode',
      );
      return;
    }

    _logLocale(
      'Language change completed current=${provider.locale.languageCode} mounted=$mounted',
    );
  }

  void _logLocale(String message) {
    if (!kDebugMode) return;
    developer.log(message, name: 'LocaleLanguage');
  }

  @override
  Widget build(BuildContext context) {
    final currentCode = context.select<LocaleLanguageProvider, String>(
      (provider) => provider.locale.languageCode,
    );
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context);
    final selectedLabel = LanguageDropdown.languages[currentCode] ??
        LanguageDropdown.languages['en']!;
    final color = widget.foregroundColor ?? theme.canvasColor;
    _logLocale('LanguageDropdown build locale=$currentCode mounted=$mounted');

    return PopupMenuButton<String>(
      color: theme.cardColor,
      padding: EdgeInsets.zero,
      tooltip: lang?.translate ?? 'Select Language',
      onSelected: _selectLanguage,
      itemBuilder: (context) {
        return LanguageDropdown.languages.entries.map((entry) {
          final selected = entry.key == currentCode;
          return PopupMenuItem<String>(
            value: entry.key,
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: selected
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: theme.primaryColor,
                        )
                      : null,
                ),
                const SizedBox(width: 6),
                Text(
                  entry.value,
                  style: TextStyle(
                    color: theme.canvasColor,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        constraints: widget.constraints,
        padding: widget.padding ??
            EdgeInsets.symmetric(
              horizontal: widget.showSelectedLabel ? 12 : 0,
              vertical: widget.showSelectedLabel ? 9 : 0,
            ),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: widget.showSelectedLabel
              ? Border.all(color: color.withOpacity(0.24))
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.isTitle)
              Text(
                '${lang?.translate ?? 'Select Language'}  ',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            if (widget.showSelectedLabel)
              Icon(
                Icons.language_rounded,
                size: 19,
                color: color,
              )
            else
              SvgPicture.asset(
                'assets/icons/translate_swap.svg',
                width: 30,
                height: 30,
                colorFilter: ColorFilter.mode(
                  color,
                  BlendMode.srcIn,
                ),
              ),
            if (widget.showSelectedLabel) ...[
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Text(
                  selectedLabel,
                  key: ValueKey(selectedLabel),
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: color,
                size: 19,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
