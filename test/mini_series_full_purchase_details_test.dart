import 'package:flutter_test/flutter_test.dart';
import 'package:ott/data/models/mini_series_commerce_models.dart';

void main() {
  // `data` of a real dev-server response from
  // GET api/mini-series/1/full-purchase-details (5 owned, 6 eligible parts).
  Map<String, dynamic> realDetails() => {
        'miniSeriesId': 1,
        'title': 'Yeshu – A Divine Tale',
        'totalParts': 11,
        'eligibleParts': 6,
        'alreadyOwnedParts': 5,
        'currency': 'INR',
        'partPriceBreakdown': [
          for (var i = 1; i <= 11; i++)
            {
              'partId': i,
              'partNumber': i,
              'price': 0.01,
              'owned': i <= 5,
              'eligible': i > 5,
            },
        ],
        'totalAmount': 0.06,
        'purchaseAvailable': true,
      };

  test('maps the real full-purchase-details response', () {
    final quote = MiniSeriesPurchaseQuote.fromFullPurchaseDetails(realDetails());

    expect(quote.shortId, 1);
    expect(quote.totalParts, 11);
    expect(quote.purchasablePartCount, 6);
    expect(quote.ownedPartCount, 5);
    expect(quote.freePartCount, 0);
    expect(quote.fullPurchasePrice, 0.06);
    expect(quote.fullPurchaseAvailable, isTrue);
    expect(quote.alreadyOwnsAll, isFalse);
    // The backend total equals the sum of eligible (unowned) part prices.
    expect(quote.purchasablePartsSum, closeTo(quote.fullPurchasePrice, 1e-9));
    // This response carries no gift price, so gifting stays unavailable.
    expect(quote.giftAvailable, isFalse);
  });

  test('all parts owned means nothing to buy', () {
    final json = realDetails()
      ..['eligibleParts'] = 0
      ..['alreadyOwnedParts'] = 11
      ..['totalAmount'] = 0
      ..['purchaseAvailable'] = false
      ..['partPriceBreakdown'] = [
        for (var i = 1; i <= 11; i++)
          {'partId': i, 'partNumber': i, 'price': 0.01, 'owned': true, 'eligible': false},
      ];
    final quote = MiniSeriesPurchaseQuote.fromFullPurchaseDetails(json);

    expect(quote.alreadyOwnsAll, isTrue);
    expect(quote.purchasablePartCount, 0);
    expect(quote.fullPurchaseAvailable, isFalse);
  });

  test('unowned, non-eligible zero-price part counts as free', () {
    final json = realDetails()
      ..['partPriceBreakdown'] = [
        {'partId': 1, 'partNumber': 1, 'price': 0, 'owned': false, 'eligible': false},
        {'partId': 2, 'partNumber': 2, 'price': 20, 'owned': false, 'eligible': true},
      ];
    final quote = MiniSeriesPurchaseQuote.fromFullPurchaseDetails(json);

    expect(quote.freePartCount, 1);
    expect(quote.parts.first.free, isTrue);
    expect(quote.parts.last.purchasable, isTrue);
  });
}
