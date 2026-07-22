import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/data/models/content.dart';

void main() {
  group('SHORT_FILM content type', () {
    test('is movie-like but retains its backend value and label', () {
      expect(ContentType.isMovieLike('SHORT_FILM'), isTrue);
      expect(ContentType.isMovieLike('MOVIE'), isTrue);
      expect(ContentType.isSeries('SHORT_FILM'), isFalse);
      expect(ContentType.displayLabel('SHORT_FILM'), 'Short Film');
    });

    test('parses contentType without mapping it to MOVIE', () {
      final content = Content.fromJson(<String, dynamic>{
        'id': 101,
        'title': 'Example Short Film',
        'contentType': 'SHORT_FILM',
      });

      expect(content.type, 'SHORT_FILM');
      expect(content.toJson()['type'], 'SHORT_FILM');
    });

    test('deep links round-trip through the movie-like Short Film route', () {
      final service = DeepLinkService.instance;
      final uri = service.buildAppLink(
        type: DeepLinkContentType.shortFilm,
        id: 101,
      );
      final target = service.parseTarget(uri);

      expect(uri.path, '/short-film/101');
      expect(target?.type, DeepLinkContentType.shortFilm);
      expect(target?.id, 101);
    });

    test('unknown future values remain safe', () {
      expect(ContentType.isMovieLike('FUTURE_TYPE'), isFalse);
      expect(ContentType.displayLabel('FUTURE_TYPE'), 'FUTURE_TYPE');
    });
  });
}
