import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;

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

  static bool get hasExplicitFlavor {
    final env = const String.fromEnvironment('FLAVOR');
    final flutterAppFlavor = const String.fromEnvironment('FLUTTER_APP_FLAVOR');
    final runtime = (appFlavor ?? '').trim();
    return runtime.isNotEmpty || env.trim().isNotEmpty || flutterAppFlavor.trim().isNotEmpty;
  }

  factory FlavorConfig.fromEnvironment({
    FilmytellFlavor? fallback,
  }) {
    final env = const String.fromEnvironment('FLAVOR').trim();
    final flutterAppFlavor = const String.fromEnvironment('FLUTTER_APP_FLAVOR').trim();
    final runtime = (appFlavor ?? '').trim();

    if (env.isNotEmpty && env.toLowerCase() != 'mobile') {
      return FlavorConfig._(_parse(env, fallback: fallback));
    }
    if (flutterAppFlavor.isNotEmpty && flutterAppFlavor.toLowerCase() != 'mobile') {
      return FlavorConfig._(_parse(flutterAppFlavor, fallback: fallback));
    }
    if (runtime.isNotEmpty && runtime.toLowerCase() != 'mobile') {
      return FlavorConfig._(_parse(runtime, fallback: fallback));
    }

    if (fallback != null) {
      return FlavorConfig.forFlavor(fallback);
    }

    final candidate = env.isNotEmpty
        ? env
        : (flutterAppFlavor.isNotEmpty ? flutterAppFlavor : runtime);
    return FlavorConfig._(_parse(candidate, fallback: FilmytellFlavor.mobile));
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
