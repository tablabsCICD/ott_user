import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/utils/direct_trailer_source.dart';
import 'package:ott/data/models/content.dart';

void main() {
  test('returns the backend trailer URL without signing or rewriting it', () {
    const backendUrl =
        'https://trailers.example.com/movie/trailer.m3u8?token=backend-value';

    expect(DirectTrailerSource.fromBackend(backendUrl), same(backendUrl));
  });

  test('preserves the exact non-blank backend value', () {
    const backendUrl =
        '  https://trailers.example.com/movie/trailer.m3u8?token=backend-value  ';

    expect(DirectTrailerSource.fromBackend(backendUrl), same(backendUrl));
  });

  test('rejects missing and blank trailer values', () {
    expect(DirectTrailerSource.fromBackend(null), isNull);
    expect(DirectTrailerSource.fromBackend('   '), isNull);
  });

  test('content model preserves backend teaser and trailer URL values', () {
    const teaserUrl =
        '  https://trailers.example.com/movie/teaser.m3u8?token=backend-teaser  ';
    const trailerUrl =
        '  https://trailers.example.com/movie/trailer.m3u8?token=backend-trailer  ';

    final content = Content.fromJson({
      'id': 1,
      'title': 'Movie',
      'teaserUrl': teaserUrl,
      'trailerUrl': trailerUrl,
    });

    expect(content.teaserUrl, same(teaserUrl));
    expect(content.trailerUrl, same(trailerUrl));
    expect(content.teaserOrTrailerUrl, same(teaserUrl));
  });
}
