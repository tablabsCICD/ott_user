import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/payment/models/payment_result.dart';
import 'package:ott/app/core/utils/content_sort.dart';
import 'package:ott/app/widgets/gift_claim_dialog.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/response/purchase_history_response.dart';

void main() {
  group('Search: newest content first', () {
    Content c(int id, {int? uploaded, dynamic release}) =>
        Content(id: id, uploadDateTime: uploaded, releaseDate: release);

    test('orders by upload time, newest first', () {
      final sorted = sortContentNewestFirst([
        c(1, uploaded: 1700000000000),
        c(2, uploaded: 1750000000000),
        c(3, uploaded: 1600000000000),
      ]);
      expect(sorted.map((e) => e.id), [2, 1, 3]);
    });

    test('falls back to release date, then id; input is not modified', () {
      final input = [
        c(10, release: '2021-05-01'),
        c(11, release: '2024-01-15'),
        c(12),
        c(13),
      ];
      final sorted = sortContentNewestFirst(input);
      expect(sorted.map((e) => e.id), [11, 10, 13, 12]);
      expect(input.map((e) => e.id), [10, 11, 12, 13]);
    });

    test('handles epoch seconds and millis alike', () {
      final sorted = sortContentNewestFirst([
        c(1, uploaded: 1700000000), // seconds
        c(2, uploaded: 1690000000000), // millis, older
      ]);
      expect(sorted.map((e) => e.id), [1, 2]);
    });
  });

  group('Payment cancellation message', () {
    test('Razorpay "undefined" description yields no message', () {
      const raw =
          '{"error":{"code":"BAD_REQUEST_ERROR","description":"undefined",'
          '"reason":"payment_cancelled"}}';
      expect(PaymentResult.readableGatewayMessage(raw), isNull);
      expect(PaymentResult.looksCancelled(raw), isTrue);
      expect(PaymentResult.readableGatewayMessage('undefined'), isNull);
      expect(PaymentResult.readableGatewayMessage(''), isNull);
    });

    test('a real gateway reason is kept', () {
      const raw = '{"error":{"description":"Payment processing cancelled by user"}}';
      expect(
        PaymentResult.readableGatewayMessage(raw),
        'Payment processing cancelled by user',
      );
      expect(
        PaymentResult.readableGatewayMessage('Card declined'),
        'Card declined',
      );
    });

    test('cancelled flag is part of the result map', () {
      const result = PaymentResult(
        success: false,
        cancelled: true,
        message: PaymentResult.defaultCancelledMessage,
      );
      expect(result.toMap()['cancelled'], isTrue);
      expect(result.toMap()['success'], isFalse);
    });
  });

  group('Purchase history status', () {
    test('maps API status text', () {
      expect(PurchaseStatus.fromRaw('SUCCESS'), PurchaseStatus.success);
      expect(PurchaseStatus.fromRaw('captured'), PurchaseStatus.success);
      expect(PurchaseStatus.fromRaw('CANCELLED'), PurchaseStatus.cancelled);
      expect(PurchaseStatus.fromRaw('canceled'), PurchaseStatus.cancelled);
      expect(PurchaseStatus.fromRaw('FAILED'), PurchaseStatus.failed);
      expect(PurchaseStatus.fromRaw('PENDING'), PurchaseStatus.pending);
      expect(PurchaseStatus.fromRaw(null), PurchaseStatus.success);
    });

    test('reads status and transaction id from existing keys', () {
      final item = PurchaseHistoryItem.fromJson({
        'id': 5,
        'amount': 49,
        'paymentStatus': 'CANCELLED',
        'razorpayPaymentId': 'pay_123',
        'paymentMode': 'UPI',
      });
      expect(item.status, PurchaseStatus.cancelled);
      expect(item.transactionId, 'pay_123');
      expect(item.paymentMethod, 'UPI');
    });
  });

  group('Gift claim response: gifted content', () {
    test('embedded movie object', () {
      final ref = giftedContentFromClaimData({
        'userContentPurchase': {
          'isGifted': true,
          'movie': {'id': 42, 'type': 'SERIES', 'title': 'X'},
        },
      });
      expect(ref?.id, 42);
      expect(ref?.content?.type, 'SERIES');
    });

    test('content id only', () {
      expect(giftedContentFromClaimData({'contentId': 7})?.id, 7);
      expect(giftedContentFromClaimData({'movieId': '9'})?.id, 9);
    });

    test('data that is itself content', () {
      final ref = giftedContentFromClaimData({'id': 3, 'type': 'MOVIE'});
      expect(ref?.id, 3);
    });

    test('nothing identifiable means no redirect', () {
      expect(giftedContentFromClaimData(null), isNull);
      expect(giftedContentFromClaimData('ok'), isNull);
      expect(giftedContentFromClaimData({'couponCode': 'GF1'}), isNull);
    });
  });
}
