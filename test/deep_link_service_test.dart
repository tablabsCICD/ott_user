import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';

void main() {
  group('DeepLinkService.parseTarget', () {
    test('parses gift app link coupon code', () {
      final target = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/gift/GF00233665671E55'),
      );

      expect(target?.type, DeepLinkContentType.gift);
      expect(target?.couponCode, 'GF00233665671E55');
    });

    test('parses movie app link id', () {
      final target = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/movie/1'),
      );

      expect(target?.type, DeepLinkContentType.movie);
      expect(target?.id, 1);
    });

    test('parses www host and ott-prefixed paths', () {
      final target = DeepLinkService.instance.parseTarget(
        Uri.parse('https://www.filmytell.com/ott/movie/1'),
      );

      expect(target?.type, DeepLinkContentType.movie);
      expect(target?.id, 1);
    });

    test('parses the user-reported deep links', () {
      // 1. https://filmytell.com/register?referralCode=FILMY-XX-60E7
      final registerTarget = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/register?referralCode=FILMY-XX-60E7'),
      );
      expect(registerTarget?.type, DeepLinkContentType.register);
      expect(registerTarget?.referralCode, 'FILMY-XX-60E7');

      // 2. https://filmytell.com/movie/6
      final movieTarget = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/movie/6'),
      );
      expect(movieTarget?.type, DeepLinkContentType.movie);
      expect(movieTarget?.id, 6);

      // 3. https://filmytell.com/series/6
      final seriesTarget = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/series/6'),
      );
      expect(seriesTarget?.type, DeepLinkContentType.series);
      expect(seriesTarget?.id, 6);

      // 4. https://filmytell.com/short/6
      final shortTarget = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/short/6'),
      );
      expect(shortTarget?.type, DeepLinkContentType.short);
      expect(shortTarget?.id, 6);
    });

    test('parses custom scheme myapp:// and filmytell:// variants', () {
      final registerScheme = DeepLinkService.instance.parseTarget(
        Uri.parse('myapp://register?referralCode=FILMY-XX-60E7'),
      );
      expect(registerScheme?.type, DeepLinkContentType.register);
      expect(registerScheme?.referralCode, 'FILMY-XX-60E7');

      final movieScheme = DeepLinkService.instance.parseTarget(
        Uri.parse('myapp://movie/6'),
      );
      expect(movieScheme?.type, DeepLinkContentType.movie);
      expect(movieScheme?.id, 6);

      final seriesScheme = DeepLinkService.instance.parseTarget(
        Uri.parse('myapp://series/6'),
      );
      expect(seriesScheme?.type, DeepLinkContentType.series);
      expect(seriesScheme?.id, 6);

      final shortScheme = DeepLinkService.instance.parseTarget(
        Uri.parse('myapp://short/6'),
      );
      expect(shortScheme?.type, DeepLinkContentType.short);
      expect(shortScheme?.id, 6);

      // Verify filmytell:// scheme
      final filmytellMovie = DeepLinkService.instance.parseTarget(
        Uri.parse('filmytell://movie/6'),
      );
      expect(filmytellMovie?.type, DeepLinkContentType.movie);
      expect(filmytellMovie?.id, 6);

      final filmytellSeries = DeepLinkService.instance.parseTarget(
        Uri.parse('filmytell://series/6'),
      );
      expect(filmytellSeries?.type, DeepLinkContentType.series);
      expect(filmytellSeries?.id, 6);

      final filmytellRegister = DeepLinkService.instance.parseTarget(
        Uri.parse('filmytell://register?referralCode=FILMY-XX-60E7'),
      );
      expect(filmytellRegister?.type, DeepLinkContentType.register);
      expect(filmytellRegister?.referralCode, 'FILMY-XX-60E7');
    });

    test('parses www and ott prefixed variants for all target types', () {
      final registerOtt = DeepLinkService.instance.parseTarget(
        Uri.parse('https://www.filmytell.com/ott/register?referralCode=FILMY-XX-60E7'),
      );
      expect(registerOtt?.type, DeepLinkContentType.register);
      expect(registerOtt?.referralCode, 'FILMY-XX-60E7');

      final seriesOtt = DeepLinkService.instance.parseTarget(
        Uri.parse('https://www.filmytell.com/ott/series/6'),
      );
      expect(seriesOtt?.type, DeepLinkContentType.series);
      expect(seriesOtt?.id, 6);

      final shortOtt = DeepLinkService.instance.parseTarget(
        Uri.parse('https://www.filmytell.com/ott/short/6'),
      );
      expect(shortOtt?.type, DeepLinkContentType.short);
      expect(shortOtt?.id, 6);
    });

    test('parses plural and alternative aliases', () {
      final moviesTarget = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/movies/6'),
      );
      expect(moviesTarget?.type, DeepLinkContentType.movie);
      expect(moviesTarget?.id, 6);

      final shortsTarget = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/shorts/6'),
      );
      expect(shortsTarget?.type, DeepLinkContentType.short);
      expect(shortsTarget?.id, 6);

      final pathRegister = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/register/FILMY-XX-60E7'),
      );
      expect(pathRegister?.type, DeepLinkContentType.register);
      expect(pathRegister?.referralCode, 'FILMY-XX-60E7');
    });
  });
}
