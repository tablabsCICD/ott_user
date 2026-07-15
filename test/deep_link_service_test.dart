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

    test('parses the production universal-link paths', () {
      final movieTarget = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/movie/1'),
      );
      final giftTarget = DeepLinkService.instance.parseTarget(
        Uri.parse('https://filmytell.com/gift/GF00233665671E55'),
      );

      expect(movieTarget?.id, 1);
      expect(giftTarget?.couponCode, 'GF00233665671E55');
    });
  });
}
