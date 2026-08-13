import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/services/device_type_helper.dart';

void main() {
  group('DeviceSessionInfo - Login Payload Referral Handling', () {
    const sessionInfo = DeviceSessionInfo(
      deviceId: 'dev123',
      deviceName: 'Test Phone',
      deviceType: SessionDeviceType.mobile,
      appVersion: '1.0.0',
      deviceMetadata: '{"os":"Android"}',
    );

    test('toLoginPayload includes referralCode when provided', () {
      final payload = sessionInfo.toLoginPayload(
        username: 'user@example.com',
        password: 'password123',
        referralCode: 'REF123',
      );

      expect(payload['username'], equals('user@example.com'));
      expect(payload['password'], equals('password123'));
      expect(payload['referralCode'], equals('REF123'));
    });

    test('toLoginPayload omits referralCode when null or empty', () {
      final payload1 = sessionInfo.toLoginPayload(
        username: 'user@example.com',
        password: 'password123',
        referralCode: null,
      );
      expect(payload1.containsKey('referralCode'), isFalse);

      final payload2 = sessionInfo.toLoginPayload(
        username: 'user@example.com',
        password: 'password123',
        referralCode: '   ',
      );
      expect(payload2.containsKey('referralCode'), isFalse);
    });

    test('toVerifyOtpPayload includes referralCode when provided', () {
      final payload = sessionInfo.toVerifyOtpPayload(
        username: '9876543210',
        otp: '123456',
        referralCode: 'PROMO99',
      );

      expect(payload['username'], equals('9876543210'));
      expect(payload['otp'], equals('123456'));
      expect(payload['referralCode'], equals('PROMO99'));
    });

    test('ApiConstant.verifyOTP includes referralCode in query when provided', () {
      final url = ApiConstant.verifyOTP(
        mobileNum: '9876543210',
        otp: '123456',
        deviceId: 'dev123',
        deviceName: 'Test Phone',
        deviceType: 'MOBILE',
        appVersion: '1.0.0',
        referralCode: 'PROMO99',
      );

      final uri = Uri.parse(url);
      expect(uri.queryParameters['referralCode'], equals('PROMO99'));
      expect(uri.queryParameters['mobileNumber'], equals('9876543210'));
      expect(uri.queryParameters['otp'], equals('123456'));
    });

    test('ApiConstant.verifyOTP omits referralCode in query when null or empty', () {
      final url = ApiConstant.verifyOTP(
        mobileNum: '9876543210',
        otp: '123456',
        deviceId: 'dev123',
        deviceName: 'Test Phone',
        deviceType: 'MOBILE',
        appVersion: '1.0.0',
        referralCode: null,
      );

      final uri = Uri.parse(url);
      expect(uri.queryParameters.containsKey('referralCode'), isFalse);
    });
  });
}
