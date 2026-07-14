import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/utils/direct_trailer_source.dart';

void main() {
  test('returns the backend trailer URL without signing or rewriting it', () {
    const backendUrl =
        'https://trailers.example.com/movie/trailer.m3u8?token=backend-value';

    expect(DirectTrailerSource.fromBackend(backendUrl), same(backendUrl));
  });

  test('rejects missing and blank trailer values', () {
    expect(DirectTrailerSource.fromBackend(null), isNull);
    expect(DirectTrailerSource.fromBackend('   '), isNull);
  });
}
