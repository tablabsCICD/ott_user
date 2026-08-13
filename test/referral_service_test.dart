import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/prefrense_constant.dart';
import 'package:ott/app/core/services/referral_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ReferralService.instance.clearReferralCode();
  });

  group('ReferralService - Code Parsing & Sanitization', () {
    test('valid referral code is sanitized correctly', () {
      final code = ReferralService.instance.sanitizeCode(' ABC123 ');
      expect(code, equals('ABC123'));
    });

    test('URL encoded referral code is decoded and trimmed', () {
      final code = ReferralService.instance.sanitizeCode('ABC%20123');
      expect(code, equals('ABC 123'));
    });

    test('placeholder {referralCode} is rejected as null', () {
      expect(ReferralService.instance.sanitizeCode('{referralCode}'), isNull);
      expect(ReferralService.instance.sanitizeCode('{ABC123}'), isNull);
      expect(ReferralService.instance.sanitizeCode(''), isNull);
      expect(ReferralService.instance.sanitizeCode('  '), isNull);
      expect(ReferralService.instance.sanitizeCode('null'), isNull);
    });

    test('captures referralCode from Uri query parameters', () async {
      final uri = Uri.parse(
        'https://filmytell.com/register?referralCode=PROMO123&utm_source=facebook',
      );
      final captured = await ReferralService.instance.captureFromUri(uri);
      expect(captured, equals('PROMO123'));

      final stored = await ReferralService.instance.getReferralCode();
      expect(stored, equals('PROMO123'));
    });

    test('captures referral_code and ref query parameters fallback', () async {
      final uri1 = Uri.parse('https://filmytell.com/register?referral_code=CODE1');
      final captured1 = await ReferralService.instance.captureFromUri(uri1);
      expect(captured1, equals('CODE1'));

      final uri2 = Uri.parse('https://filmytell.com/register?ref=CODE2');
      final captured2 = await ReferralService.instance.captureFromUri(uri2);
      expect(captured2, equals('CODE2'));
    });

    test('ignores placeholder referralCode in Uri', () async {
      final uri = Uri.parse(
        'https://filmytell.com/register?referralCode={referralCode}',
      );
      final captured = await ReferralService.instance.captureFromUri(uri);
      expect(captured, isNull);
    });
  });

  group('ReferralService - Persistence Lifecycle', () {
    test('store and clear referral code', () async {
      await ReferralService.instance.storeReferralCode('REF999');
      expect(
        await ReferralService.instance.getReferralCode(),
        equals('REF999'),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(SharedPreferencesConstant.referralCode),
        equals('REF999'),
      );

      await ReferralService.instance.clearReferralCode();
      expect(await ReferralService.instance.getReferralCode(), isNull);
      expect(
        prefs.getString(SharedPreferencesConstant.referralCode),
        isNull,
      );
    });
  });
}
