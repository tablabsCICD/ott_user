import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/services/gift_deep_link_service.dart';
import 'package:ott/app/widgets/gift_claim_dialog.dart';
import 'package:ott/data/models/mini_series_commerce_models.dart';

void main() {
  test('gift-details maps unit price and quantity limits', () {
    final quote = MiniSeriesPurchaseQuote.fromGiftDetails(
      {
        'giftAvailable': true,
        'giftUnitPrice': 100,
        'minQuantity': 1,
        'maxQuantity': 20,
      },
      shortId: 123,
      title: 'Example',
    );
    expect(quote.giftAvailable, isTrue);
    expect(quote.giftPrice, 100.0);
    expect(quote.minGiftCount, 1);
    expect(quote.maxGiftCount, 20);
    // Total = giftUnitPrice × quantity.
    expect(quote.giftPrice * 3, 300.0);
  });

  test('zero gift price is not giftable', () {
    final quote = MiniSeriesPurchaseQuote.fromGiftDetails(
      {'giftAvailable': true, 'giftUnitPrice': 0, 'minQuantity': 1, 'maxQuantity': 5},
      shortId: 1,
      title: '',
    );
    expect(quote.giftAvailable, isFalse);
  });

  test('giftAvailable false or missing is not giftable', () {
    for (final flag in [false, null]) {
      final quote = MiniSeriesPurchaseQuote.fromGiftDetails(
        {'giftAvailable': flag, 'giftUnitPrice': 2.7, 'minQuantity': 1},
        shortId: 1,
        title: '',
      );
      expect(quote.giftAvailable, isFalse);
    }
  });

  test('purchase response maps codes, totals and epoch-millisecond dates', () {
    // 2026-11-30T00:00:00Z in epoch milliseconds (not seconds).
    const expiryMs = 1795996800000;
    final result = MiniSeriesGiftPurchaseResult.fromJson({
      'transactionId': 'MSGIFT-1',
      'totalAmount': 300,
      'expiryDate': expiryMs,
      'gifts': [
        {'giftCode': 'AAAA1111', 'status': 'ACTIVE', 'expiryDate': expiryMs},
        {'giftCode': 'BBBB2222', 'status': 'ACTIVE', 'expiryDate': expiryMs},
        {'giftCode': 'CCCC3333', 'status': 'ACTIVE', 'expiryDate': expiryMs},
      ],
    });
    expect(result.transactionId, 'MSGIFT-1');
    expect(result.totalAmount, 300.0);
    expect(result.gifts.map((g) => g.giftCode).toSet().length, 3);
    expect(result.idempotentReplay, isFalse);
    expect(
      result.gifts.first.expiryDate!.toUtc(),
      DateTime.utc(2026, 11, 30),
    );
  });

  test('idempotent replay flag is read from data or envelope', () {
    expect(
      MiniSeriesGiftPurchaseResult.fromJson({'idempotentReplay': true, 'gifts': []})
          .idempotentReplay,
      isTrue,
    );
    expect(
      MiniSeriesGiftPurchaseResult.fromJson({'gifts': []},
              envelope: {'idempotentReplay': true})
          .idempotentReplay,
      isTrue,
    );
  });

  test('no response means an uncertain outcome (keep the idempotency key)', () {
    expect(MiniSeriesCommerceResult.failure('offline').isNetworkFailure, isTrue);
    expect(
      MiniSeriesCommerceResult.fromJson({'success': false, 'message': 'x'},
              fallbackMessage: 'f', statusCode: 400)
          .isNetworkFailure,
      isFalse,
    );
  });

  test('history item maps Swagger MiniSeriesGiftHistoryItem', () {
    final items = MiniSeriesGiftHistoryEntry.listFrom([
      {
        'giftId': 11,
        'giftCode': 'MSG-9A1F3C5E7B2D4F6A8C0E1B3D5F7A9C2E',
        'giftStatus': 'AVAILABLE',
        'miniSeriesId': 123,
        'miniSeriesTitle': 'Example Drama',
        'giftPrice': 2.7,
        'purchaseDate': 1763892900000,
        'expiryDate': 1795428900000,
        'claimDate': null,
      },
    ]);
    expect(items.single.isAvailable, isTrue);
    expect(items.single.giftPrice, 2.7);
    expect(items.single.claimDate, isNull);
    expect(items.single.purchaseDate!.toUtc().year, 2025);
  });

  test('claim data maps Swagger MiniSeriesGiftClaimData', () {
    final claim = MiniSeriesGiftClaimResult.fromJson({
      'miniSeriesId': 123,
      'miniSeriesTitle': 'Example Drama',
      'accessGranted': true,
      'grantedParts': 9,
      'accessValidUntil': 1766571300000,
    });
    expect(claim.accessGranted, isTrue);
    expect(claim.grantedParts, 9);
    expect(claim.accessValidUntil, isNotNull);
  });

  test('MSG- codes are recognised; 16-char movie codes are unchanged', () {
    const msg = 'MSG-9A1F3C5E7B2D4F6A8C0E1B3D5F7A9C2E';
    expect(isMiniSeriesGiftCode(msg), isTrue);
    expect(isMiniSeriesGiftCode('msg-9a1f3c5e7b2d4f6a8c0e1b3d5f7a9c2e'), isTrue);
    expect(isMiniSeriesGiftCode('GF000843A767720E'), isFalse);
    expect(isValidGiftCardCodeLength('GF000843A767720E'), isTrue);
    expect(GiftDeepLinkService.isValidGiftCode(msg), isTrue);
    expect(
      GiftDeepLinkService.extractGiftCodeFromUri(
          Uri.parse('https://filmytell.com/gift/$msg')),
      msg,
    );
  });

  group('received gift sender and expiry', () {
    Map<String, dynamic> item({Object? sender, Object? giftExpiry, Object? expiry, Object? access}) => {
          'giftId': 11,
          'giftStatus': 'CLAIMED',
          'miniSeriesId': 123,
          'miniSeriesTitle': 'Example Drama',
          'purchaserId': 7,
          'senderName': sender,
          'giftExpiryDate': giftExpiry,
          'expiryDate': expiry,
          'claimDate': 1763979300000,
          if (access != null) 'accessValidUntil': access,
        };

    test('sender name is used when present', () {
      final e = MiniSeriesGiftHistoryEntry.fromJson(item(sender: 'Asha Patil'));
      expect(e.displaySenderName, 'Asha Patil');
    });

    test('null or blank sender name falls back (UI shows "A friend")', () {
      expect(MiniSeriesGiftHistoryEntry.fromJson(item(sender: null)).displaySenderName, isNull);
      expect(MiniSeriesGiftHistoryEntry.fromJson(item(sender: '   ')).displaySenderName, isNull);
    });

    test('giftExpiryDate is epoch milliseconds; expiryDate is the fallback', () {
      // 2026-11-30T00:00:00Z
      const ms = 1795996800000;
      final e = MiniSeriesGiftHistoryEntry.fromJson(item(giftExpiry: ms, expiry: ms));
      expect(e.giftExpiryDate!.toUtc(), DateTime.utc(2026, 11, 30));
      expect(e.codeExpiry!.toUtc(), DateTime.utc(2026, 11, 30));
      final legacy = MiniSeriesGiftHistoryEntry.fromJson(item(expiry: ms));
      expect(legacy.giftExpiryDate, isNull);
      expect(legacy.codeExpiry!.toUtc(), DateTime.utc(2026, 11, 30));
    });

    test('access validity comes only from accessValidUntil', () {
      const ms = 1795996800000;
      final noAccess = MiniSeriesGiftHistoryEntry.fromJson(item(giftExpiry: ms, expiry: ms));
      expect(noAccess.accessValidUntil, isNull, reason: 'never derived from gift-code expiry');
      final withAccess = MiniSeriesGiftHistoryEntry.fromJson(item(access: 1766571300000));
      expect(withAccess.accessValidUntil, isNotNull);
    });
  });
}
