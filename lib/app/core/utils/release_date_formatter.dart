/// Formats content release dates without parsing date-only values as UTC.
String formatReleaseDate(dynamic releaseDate) {
  if (releaseDate == null) return '';
  if (releaseDate is DateTime) {
    return '${releaseDate.day.toString().padLeft(2, '0')}-'
        '${releaseDate.month.toString().padLeft(2, '0')}-${releaseDate.year}';
  }

  final value = releaseDate.toString().trim();
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:$|[T\s])').firstMatch(value);
  if (match == null) return value;
  return '${match.group(3)}-${match.group(2)}-${match.group(1)}';
}
