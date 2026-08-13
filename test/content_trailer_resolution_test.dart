import 'package:flutter_test/flutter_test.dart';
import 'package:ott/data/models/content.dart';

void main() {
  group('Content teaser or trailer URL resolution', () {
    test('uses teaser URL when the movie details response provides it', () {
      const teaserUrl = 'https://cdn.example.com/movie-teaser.m3u8';
      final content = Content.fromJson({'teaserUrl': teaserUrl});

      expect(content.teaserOrTrailerUrl, teaserUrl);
    });

    test('uses trailer URL when teaser URL is missing', () {
      const trailerUrl = 'https://cdn.example.com/movie-trailer.mp4';
      final content = Content.fromJson({'trailerUrl': trailerUrl});

      expect(content.teaserOrTrailerUrl, trailerUrl);
    });

    test('ignores a blank teaser and uses the trailer URL', () {
      const trailerUrl = 'https://youtu.be/abcdefghijk';
      final content = Content.fromJson({
        'teaserUrl': '   ',
        'trailerUrl': trailerUrl,
      });

      expect(content.teaserOrTrailerUrl, trailerUrl);
    });

    test('reads the detail API trailer media-list shape', () {
      const trailerUrl = 'https://cdn.example.com/movie-trailer.m3u8';
      final content = Content.fromJson({
        'trailerAudioUrlList': [trailerUrl],
      });

      expect(content.teaserOrTrailerUrl, trailerUrl);
    });

    test('reads a URL object from the detail API trailer media list', () {
      const trailerUrl = 'https://cdn.example.com/movie-trailer.mp4';
      final content = Content.fromJson({
        'trailerAudioUrlList': [
          {'fileUrl': trailerUrl},
        ],
      });

      expect(content.teaserOrTrailerUrl, trailerUrl);
    });
  });
}
