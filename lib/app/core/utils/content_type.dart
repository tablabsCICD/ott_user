import 'package:ott/l10n/app_localizations.dart';

abstract final class ContentType {
  static const String movie = 'MOVIE';
  static const String series = 'SERIES';
  static const String miniSeries = 'MINI SERIES';
  static const String madioo = 'MADIOO';
  static const String shortFilm = 'SHORT_FILM';

  static const List<String> homeTypes = <String>[
    movie,
    shortFilm,
    series,
    miniSeries,
    madioo,
  ];

  static String normalize(String? value) => (value ?? '').trim().toUpperCase();

  static bool isMovieLike(String? value) {
    final normalized = normalize(value);
    return normalized == movie || normalized == shortFilm;
  }

  static bool isSeries(String? value) => normalize(value) == series;

  /// Display label in the app language. Unknown types (and Madioo, a brand
  /// name) fall back to [displayLabel].
  static String localizedLabel(AppLocalizations lang, String? value) {
    switch (normalize(value)) {
      case movie:
        return lang.cardTypeMovie;
      case shortFilm:
        return lang.shortFilm;
      case series:
        return lang.series;
      case miniSeries:
      case 'MINI_SERIES':
        return lang.minSeries;
      default:
        return displayLabel(value);
    }
  }

  /// English display label (no BuildContext needed).
  static String displayLabel(String? value) {
    switch (normalize(value)) {
      case movie:
        return 'Movie';
      case shortFilm:
        return 'Short Film';
      case series:
        return 'Series';
      case miniSeries:
      case 'MINI_SERIES':
        return 'Mini Series';
      case madioo:
        return 'Madioo';

      default:
        final original = value?.trim();
        return original == null || original.isEmpty ? 'Unknown' : original;
    }
  }
}
