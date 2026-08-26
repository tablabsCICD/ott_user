import 'package:flutter/foundation.dart';

enum FilmytellFlavor {
  mobile,
  tv,
  jio,
  ios,
  web,
}

class FlavorConfig {
  const FlavorConfig._(this.flavor);

  const FlavorConfig.forFlavor(this.flavor);

  factory FlavorConfig.fromEnvironment({
    FilmytellFlavor? fallback,
  }) {
    const value = String.fromEnvironment('FLAVOR');
    return FlavorConfig._(_parse(value, fallback: fallback));
  }

  final FilmytellFlavor flavor;

  static FlavorConfig current = FlavorConfig.fromEnvironment();

  bool get isMobile => flavor == FilmytellFlavor.mobile;
  bool get isTv => flavor == FilmytellFlavor.tv || flavor == FilmytellFlavor.jio;
  bool get isJio => flavor == FilmytellFlavor.jio;
  bool get isIos => flavor == FilmytellFlavor.ios;
  bool get isWeb => flavor == FilmytellFlavor.web;

  String get name => flavor.name;

  static FilmytellFlavor _parse(
    String value, {
    FilmytellFlavor? fallback,
  }) {
    switch (value.trim().toLowerCase()) {
      case 'mobile':
        return FilmytellFlavor.mobile;
      case 'tv':
        return FilmytellFlavor.tv;
      case 'jio':
      case 'jiostb':
        return FilmytellFlavor.jio;
      case 'ios':
        return FilmytellFlavor.ios;
      case 'web':
        return FilmytellFlavor.web;
    }

    if (fallback != null) return fallback;
    if (kIsWeb) return FilmytellFlavor.web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return FilmytellFlavor.ios;
      default:
        return FilmytellFlavor.mobile;
    }
  }
}
