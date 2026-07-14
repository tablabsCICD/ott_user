import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/services/apple_receipt_service.dart';

void main() {
  group('AppleReceiptService receipt validation', () {
    test('accepts a base64 encoded binary app receipt', () {
      final receipt = base64Encode(List<int>.generate(128, (index) => index));

      expect(AppleReceiptService.isBase64AppReceipt(receipt), isTrue);
    });

    test('rejects a StoreKit 2 JWS transaction', () {
      const jws = 'header.payload.signature';

      expect(AppleReceiptService.isBase64AppReceipt(jws), isFalse);
    });

    test('rejects transaction IDs, empty values, and malformed base64', () {
      expect(
        AppleReceiptService.isBase64AppReceipt('2000001204242986'),
        isFalse,
      );
      expect(AppleReceiptService.isBase64AppReceipt(''), isFalse);
      expect(AppleReceiptService.isBase64AppReceipt('!' * 100), isFalse);
    });
  });
}
