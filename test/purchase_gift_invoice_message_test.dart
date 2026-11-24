import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/pages/profile%20page/PurchaseHistoryPage.dart';
import 'package:ott/data/models/response/purchase_history_response.dart';
import 'package:ott/l10n/app_localizations.dart';

void main() {
  PurchaseHistoryItem item(String? method) =>
      PurchaseHistoryItem.fromJson({'id': 1, 'paymentMethod': method});

  test('gift is identified only by paymentMethod GIFT', () {
    expect(item('GIFT').isGift, isTrue);
    expect(item(' gift ').isGift, isTrue);
    expect(item('ONLINE').isGift, isFalse);
    expect(item('WALLET').isGift, isFalse);
    expect(item(null).isGift, isFalse);
  });

  test('message names the sender only when a real name exists', () async {
    final l10n = await AppLocalizations.delegate.load(const Locale('en'));
    expect(giftedInvoiceMessage(l10n, 'Rahul Sharma'),
        'This content was gifted to you by Rahul Sharma. Therefore, an invoice is not available.');
    const fallback =
        'This content was gifted to you. Therefore, an invoice is not available.';
    expect(giftedInvoiceMessage(l10n, null), fallback);
    expect(giftedInvoiceMessage(l10n, ''), fallback);
    expect(giftedInvoiceMessage(l10n, '   '), fallback);
    expect(giftedInvoiceMessage(l10n, 'null'), fallback);
  });

  test('every language has both gift messages', () async {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      expect(l10n.purchaseGiftedToYouBy('X'), contains('X'), reason: '$locale');
      expect(l10n.purchaseGiftInvoiceUnavailable, isNotEmpty,
          reason: '$locale');
    }
  });
}
