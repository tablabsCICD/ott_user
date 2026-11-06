import 'package:flutter/widgets.dart';
import 'package:ott/app/route/navigation_service.dart';
import 'package:ott/l10n/app_localizations.dart';

/// The app's current [AppLocalizations] for code that has no `BuildContext`
/// (providers and services that build user-facing messages).
///
/// Call it when the message is created — never cache the result in a field or
/// static — so the text follows the language the user has selected.
/// Falls back to English when no app navigator is mounted (e.g. unit tests).
AppLocalizations appL10n() {
  AppLocalizations? l10n;
  try {
    final context = navigatorKey.currentContext;
    l10n = context == null
        ? null
        : Localizations.of<AppLocalizations>(context, AppLocalizations);
  } catch (_) {
    // No Flutter binding yet (pure Dart tests / very early startup).
  }
  return l10n ?? lookupAppLocalizations(const Locale('en'));
}
