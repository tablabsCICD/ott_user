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
