import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/utils/content_type.dart';

void main() {
  test('short films are movie-like offline content', () {
    expect(ContentType.isMovieLike('SHORT_FILM'), isTrue);
    expect(ContentType.isMovieLike('short_film'), isTrue);
  });
}
