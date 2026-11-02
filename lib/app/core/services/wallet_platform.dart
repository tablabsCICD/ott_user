import 'package:flutter/foundation.dart';

class WalletPlatform {
  const WalletPlatform._();

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// TEMPORARY: hides every gifting entry point (gift a movie/series, claim
  /// gift, gifted lists, gift deep-link popups) in the native iOS app only.
  /// Gift APIs, models and logic are untouched; Android, web (including
  /// Safari on Apple devices) and TV keep the existing behaviour.
  /// Flip this to `false` to restore gifting on iOS.
  static bool get isGiftingHidden => isIOS;

  static String? get operatingSystem {
    if (kIsWeb) return 'WEB';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return null;
    }
  }
}
