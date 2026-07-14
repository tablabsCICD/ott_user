import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

/// Loads the legacy App Store app receipt expected by Apple's `verifyReceipt`
/// endpoint. StoreKit 2 transaction JWS values are intentionally not returned.
class AppleReceiptService {
  AppleReceiptService({InAppPurchase? inAppPurchase})
      : _iap = inAppPurchase ?? InAppPurchase.instance;

  final InAppPurchase _iap;

  Future<String> loadBase64AppReceipt() async {
    var receipt = (await SKReceiptManager.retrieveReceiptData()).trim();

    if (!isBase64AppReceipt(receipt)) {
      debugPrint(
        '[APPLE_IAP][RECEIPT] Bundle receipt is missing or invalid; '
        'requesting one receipt refresh.',
      );
      final addition =
          _iap.getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      final refreshed = await addition.refreshPurchaseVerificationData();
      receipt = refreshed?.serverVerificationData.trim() ?? '';
    }

    if (!isBase64AppReceipt(receipt)) {
      throw const FormatException(
        'Apple app receipt is missing or is not valid base64 receipt data.',
      );
    }

    debugPrint(
      '[APPLE_IAP][RECEIPT] Base64 app receipt loaded '
      '(characters=${receipt.length}); receipt content is not logged.',
    );
    return receipt;
  }

  @visibleForTesting
  static bool isBase64AppReceipt(String value) {
    final candidate = value.trim();
    if (candidate.length < 64 || candidate.contains('.')) return false;

    try {
      // App receipts are binary PKCS#7 containers and therefore decode to a
      // sizeable byte array. This also rejects transaction IDs and JWS values.
      return base64Decode(base64.normalize(candidate)).length >= 32;
    } on FormatException {
      return false;
    }
  }
}
