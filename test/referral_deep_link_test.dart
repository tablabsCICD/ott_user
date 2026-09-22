import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/services/referral_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReferralService Validation and Extraction', () {
    test('isValidCode tests', () {
      expect(ReferralService.isValidCode('FILMY-XX-60E7'), isTrue);
      expect(ReferralService.isValidCode('FILMY-ABC-1234'), isTrue);
      expect(ReferralService.isValidCode('AB'), isTrue);
      expect(ReferralService.isValidCode(''), isFalse);
      expect(ReferralService.isValidCode(' '), isFalse);
      expect(ReferralService.isValidCode(null), isFalse);
      expect(ReferralService.isValidCode('{referralCode}'), isFalse);
      expect(ReferralService.isValidCode('{referral_code}'), isFalse);
      expect(ReferralService.isValidCode('{code}'), isFalse);
      expect(ReferralService.isValidCode('undefined'), isFalse);
      expect(ReferralService.isValidCode('null'), isFalse);
      expect(ReferralService.isValidCode('none'), isFalse);
    });

    test('extractCodeFromUri with various query keys', () {
      final uri1 = Uri.parse('https://filmytell.com/register?referralCode=FILMY-XX-60E7');
      expect(ReferralService.extractCodeFromUri(uri1), 'FILMY-XX-60E7');

      final uri2 = Uri.parse('https://filmytell.com/register?referral_code=FILMY-ABC-1234');
      expect(ReferralService.extractCodeFromUri(uri2), 'FILMY-ABC-1234');

      final uri3 = Uri.parse('https://filmytell.com/register?ref=REF123');
      expect(ReferralService.extractCodeFromUri(uri3), 'REF123');

      final uri4 = Uri.parse('https://filmytell.com/register?code=CODE123');
      expect(ReferralService.extractCodeFromUri(uri4), 'CODE123');

      final uri5 = Uri.parse('myapp://register?referralCode=FILMY-XX-60E7');
      expect(ReferralService.extractCodeFromUri(uri5), 'FILMY-XX-60E7');

      final uriEmpty = Uri.parse('https://filmytell.com/register');
      expect(ReferralService.extractCodeFromUri(uriEmpty), isNull);

      final uriInvalid = Uri.parse('https://filmytell.com/register?referralCode={referralCode}');
      expect(ReferralService.extractCodeFromUri(uriInvalid), isNull);
    });

    test('extractCodeFromString from Play Store referrer payload', () {
      expect(
        ReferralService.extractCodeFromString('referralCode=FILMY-XX-60E7'),
        'FILMY-XX-60E7',
      );
      expect(
        ReferralService.extractCodeFromString(
          'utm_source=google-play&utm_medium=organic&referralCode=FILMY-XX-60E7',
        ),
        'FILMY-XX-60E7',
      );
      expect(
        ReferralService.extractCodeFromString('FILMY-XX-60E7'),
        'FILMY-XX-60E7',
      );
      expect(
        ReferralService.extractCodeFromString(
          'https://play.google.com/store/apps/details?id=com.filmytell.ott&referrer=referralCode%3DFILMY-XX-60E7',
        ),
        'FILMY-XX-60E7',
      );
    });
  });

  group('DeepLinkService Parse Target', () {
    final service = DeepLinkService.instance;

    test('parses register HTTPS link with referralCode', () {
      final uri = Uri.parse('https://filmytell.com/register?referralCode=FILMY-XX-60E7');
      final target = service.parseTarget(uri);

      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.register);
      expect(target.referralCode, 'FILMY-XX-60E7');
    });

    test('parses register HTTPS link without referralCode', () {
      final uri = Uri.parse('https://filmytell.com/register');
      final target = service.parseTarget(uri);

      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.register);
      expect(target.referralCode, isNull);
    });

    test('parses register myapp scheme link', () {
      final uri = Uri.parse('myapp://register?referralCode=FILMY-ABC-1234');
      final target = service.parseTarget(uri);

      expect(target, isNotNull);
      expect(target!.type, DeepLinkContentType.register);
      expect(target.referralCode, 'FILMY-ABC-1234');
    });

    test('preserves existing deep link parsing for movie, series, gift', () {
      final movieUri = Uri.parse('https://filmytell.com/movie/123');
      final movieTarget = service.parseTarget(movieUri);
      expect(movieTarget, isNotNull);
      expect(movieTarget!.type, DeepLinkContentType.movie);
      expect(movieTarget.id, 123);

      final seriesUri = Uri.parse('https://filmytell.com/series/456');
      final seriesTarget = service.parseTarget(seriesUri);
      expect(seriesTarget, isNotNull);
      expect(seriesTarget!.type, DeepLinkContentType.series);
      expect(seriesTarget.id, 456);

      final giftUri = Uri.parse('myapp://gift/GF12345678');
      final giftTarget = service.parseTarget(giftUri);
      expect(giftTarget, isNotNull);
      expect(giftTarget!.type, DeepLinkContentType.gift);
      expect(giftTarget.couponCode, 'GF12345678');
    });
  });
}
