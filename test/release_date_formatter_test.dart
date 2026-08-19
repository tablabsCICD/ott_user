import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/utils/release_date_formatter.dart';

void main() {
  test('formats ISO release dates as DD-MM-YYYY without timezone conversion', () {
    expect(formatReleaseDate('2026-08-18'), '18-08-2026');
    expect(formatReleaseDate('2026-01-05'), '05-01-2026');
    expect(formatReleaseDate('2025-12-31'), '31-12-2025');
    expect(formatReleaseDate('2026-08-18T00:00:00.000Z'), '18-08-2026');
  });

  test('handles absent and unrecognized values safely', () {
    expect(formatReleaseDate(null), isEmpty);
    expect(formatReleaseDate(''), isEmpty);
    expect(formatReleaseDate('not-a-date'), 'not-a-date');
  });
}
