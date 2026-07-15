import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/services/apple_iap_models.dart';

void main() {
  group('ApplePurchaseVerificationRequest', () {
    test('serializes the modern StoreKit verification contract', () {
      const request = ApplePurchaseVerificationRequest(
        productId: 'com.filmytell.wallet.99',
        purchaseId: '2000001204242986',
        transactionId: '2000001204242986',
        originalTransactionId: '2000001204000000',
        verificationData: 'header.payload.signature',
        verificationSource: 'app_store',
        transactionDate: '1784000000000',
        userId: 5,
        deviceId: 'saved-device-id',
      );

      expect(request.toJson(), {
        'platform': 'ios',
        'productId': 'com.filmytell.wallet.99',
        'purchaseId': '2000001204242986',
        'transactionId': '2000001204242986',
        'transaction_id': '2000001204242986',
        'originalTransactionId': '2000001204000000',
        'verificationData': 'header.payload.signature',
        'verificationSource': 'app_store',
        'transactionDate': '1784000000000',
        'userId': 5,
        'deviceId': 'saved-device-id',
      });
      expect(request.toJson(), isNot(contains('walletAmount')));
    });
  });

  group('ApplePurchaseVerificationResult', () {
    test('parses a verified idempotent backend response', () {
      final result = ApplePurchaseVerificationResult.fromJson({
        'success': true,
        'verified': true,
        'alreadyProcessed': true,
        'transactionId': '2000001204242986',
        'productId': 'com.filmytell.wallet.99',
        'creditedAmount': 99,
        'walletBalance': 1099,
        'environment': 'Sandbox',
      });

      expect(result.success, isTrue);
      expect(result.verified, isTrue);
      expect(result.alreadyProcessed, isTrue);
      expect(result.creditedAmount, 99);
      expect(result.environment, 'Sandbox');
    });

    test('does not infer verification from success alone', () {
      final result = ApplePurchaseVerificationResult.fromJson({
        'success': true,
        'transactionId': '2000001204242986',
      });

      expect(result.success, isTrue);
      expect(result.verified, isFalse);
    });

    test('categorizes retryable backend failures', () {
      const exception = ApplePurchaseVerificationException(
        message: 'Apple is temporarily unavailable.',
        code: 'APPLE_SERVER_UNAVAILABLE',
        statusCode: 503,
      );

      expect(exception.isTemporary, isTrue);
    });
  });
}
