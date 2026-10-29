import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/services/coupon_service.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/coupon/coupon_models.dart';
import 'package:ott/data/models/response/purchase_history_response.dart';

void main() {
  group('A. Coupon Models and Serialization', () {
    test('PurchaseKind mapping', () {
      expect(PurchaseKind.content.value, 'CONTENT');
      expect(PurchaseKind.season.value, 'SEASON');
      expect(PurchaseKind.episode.value, 'EPISODE');
      expect(PurchaseKind.shortPart.value, 'SHORT_PART');

      expect(PurchaseKind.fromString('content'), PurchaseKind.content);
      expect(PurchaseKind.fromString('SEASON'), PurchaseKind.season);
      expect(PurchaseKind.fromString('episode'), PurchaseKind.episode);
      expect(PurchaseKind.fromString('short_part'), PurchaseKind.shortPart);
      expect(PurchaseKind.fromString('unknown'), PurchaseKind.content);
    });

    test('CouponValidationRequest formats uppercase and trims code', () {
      final req = CouponValidationRequest(
        couponCode: '  filmy20  ',
        userId: 42,
        purchaseKind: 'CONTENT',
        targetId: 101,
      );

      final json = req.toJson();
      expect(json['couponCode'], 'FILMY20');
      expect(json['userId'], 42);
      expect(json['purchaseKind'], 'CONTENT');
      expect(json['targetId'], 101);
    });

    test('CouponValidationResponse parses valid response with decimals', () {
      final raw = {
        'success': true,
        'message': 'Coupon validated successfully',
        'data': {
          'couponCode': 'FILMY10',
          'originalAmount': 100.0,
          'discountAmount': 10.90,
          'finalPayableAmount': 89.10,
          'currency': 'INR',
          'discountPercentage': 10.9,
        }
      };

      final res = CouponValidationResponse.fromJson(raw);
      expect(res.success, isTrue);
      expect(res.data, isNotNull);
      expect(res.data!.couponCode, 'FILMY10');
      expect(res.data!.originalAmount, 100.0);
      expect(res.data!.discountAmount, 10.90);
      expect(res.data!.finalPayableAmount, 89.10);
      expect(res.data!.currency, 'INR');
      expect(res.data!.discountPercentage, 10.9);
      expect(res.data!.formattedOriginalPrice, '₹100.00');
      expect(res.data!.formattedDiscountAmount, '₹10.90');
      expect(res.data!.formattedFinalAmount, '₹89.10');
    });

    test('CouponValidationResponse correctly handles integer numbers from backend', () {
      final raw = {
        'success': true,
        'message': 'Success',
        'data': {
          'couponCode': 'FILMY20',
          'originalAmount': 100,
          'discountAmount': 20,
          'finalPayableAmount': 80,
          'currency': 'INR',
          'discountPercentage': 20,
        }
      };

      final res = CouponValidationResponse.fromJson(raw);
      expect(res.success, isTrue);
      expect(res.data!.originalAmount, 100.0);
      expect(res.data!.discountAmount, 20.0);
      expect(res.data!.finalPayableAmount, 80.0);
      expect(res.data!.discountPercentage, 20.0);
    });
  });

  group('B. Backend Error Code Resolution', () {
    test('Resolves all 15+ backend error codes to user-friendly messages', () {
      expect(
        resolveCouponErrorMessage(errorCode: 'INVALID_COUPON'),
        'This coupon code is invalid. Please check the code and try again.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'COUPON_INACTIVE'),
        'This coupon is currently inactive.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'COUPON_NOT_STARTED'),
        'This coupon is not available yet.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'COUPON_EXPIRED'),
        'This coupon has expired.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'COUPON_CONTENT_MISMATCH'),
        'This coupon is not valid for the selected content.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'COUPON_USER_LIMIT_REACHED'),
        'You have already used or reserved this coupon.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'COUPON_TOTAL_LIMIT_REACHED'),
        'This coupon has reached its redemption limit.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'IDEMPOTENCY_KEY_REQUIRED'),
        'Checkout session expired. Please retry applying the coupon.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'IDEMPOTENCY_CONFLICT'),
        'A checkout attempt with this reservation is already in progress. Please retry.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'CHECKOUT_EXPIRED'),
        'The checkout session has expired. Please try again.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'INSUFFICIENT_BALANCE'),
        'Insufficient wallet balance to complete this purchase.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'ALREADY_PURCHASED'),
        'You have already purchased this content.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'PAYMENT_NOT_CAPTURED'),
        'Payment was not captured. Please check with your payment provider.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'PAYMENT_MISMATCH'),
        'Payment amount mismatch. Please retry checkout.',
      );
      expect(
        resolveCouponErrorMessage(errorCode: 'VERIFIED_ORDER_REQUIRED'),
        'A verified order is required to redeem this coupon.',
      );
    });

    test('Falls back to backend message or safe generic message when code unknown', () {
      expect(
        resolveCouponErrorMessage(fallbackMessage: 'Custom server error description'),
        'Custom server error description',
      );
      expect(
        resolveCouponErrorMessage(),
        'Unable to apply coupon. Please check the code and try again.',
      );
    });
  });

  group('C. Idempotency Key Generation', () {
    test('Generates valid UUID v4 string', () {
      final key1 = CouponService.generateIdempotencyKey();
      final key2 = CouponService.generateIdempotencyKey();

      expect(key1, isNotEmpty);
      expect(key2, isNotEmpty);
      expect(key1, isNot(equals(key2)));

      final uuidRegex = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        caseSensitive: false,
      );
      expect(uuidRegex.hasMatch(key1), isTrue);
      expect(uuidRegex.hasMatch(key2), isTrue);
    });
  });

  group('D. API URL Generation with Coupon & Idempotency Key', () {
    test('createContentOrder URL encodes parameters correctly', () {
      final url = ApiConstant.createContentOrder(
        customerId: 42,
        contentId: 101,
        couponCode: 'filmy10',
        idempotencyKey: 'checkout-unique-uuid',
      );

      final uri = Uri.parse(url);
      expect(uri.path, contains('api/razorpay/create-order'));
      expect(uri.queryParameters['customerId'], '42');
      expect(uri.queryParameters['contentId'], '101');
      expect(uri.queryParameters['couponCode'], 'FILMY10');
      expect(uri.queryParameters['idempotencyKey'], 'checkout-unique-uuid');
    });

    test('purchaseSeason URL encodes coupon parameters', () {
      final url = ApiConstant.purchaseSeason(
        5,
        42,
        couponCode: 'SEASON20',
        idempotencyKey: 'season-uuid-123',
      );

      final uri = Uri.parse(url);
      expect(uri.path, contains('series/purchase/season'));
      expect(uri.queryParameters['seasonId'], '5');
      expect(uri.queryParameters['userId'], '42');
      expect(uri.queryParameters['couponCode'], 'SEASON20');
      expect(uri.queryParameters['idempotencyKey'], 'season-uuid-123');
    });

    test('purchaseEpisode URL encodes coupon parameters', () {
      final url = ApiConstant.purchaseEpisode(
        12,
        42,
        couponCode: 'EPISODE10',
        idempotencyKey: 'ep-uuid-123',
      );

      final uri = Uri.parse(url);
      expect(uri.path, contains('series/purchase/episode'));
      expect(uri.queryParameters['episodeId'], '12');
      expect(uri.queryParameters['userId'], '42');
      expect(uri.queryParameters['couponCode'], 'EPISODE10');
      expect(uri.queryParameters['idempotencyKey'], 'ep-uuid-123');
    });

    test('purchaseShort URL encodes coupon parameters', () {
      final url = ApiConstant.purchaseShort(
        7,
        42,
        couponCode: 'SHORT5',
        idempotencyKey: 'short-uuid-123',
      );

      final uri = Uri.parse(url);
      expect(uri.path, contains('api/shortsMaster/purchaseShort'));
      expect(uri.queryParameters['partId'], '7');
      expect(uri.queryParameters['userId'], '42');
      expect(uri.queryParameters['couponCode'], 'SHORT5');
      expect(uri.queryParameters['idempotencyKey'], 'short-uuid-123');
    });
  });

  group('E. SeriesPurchaseResult Decimal Preservation', () {
    test('Preserves decimal amounts and coupon transaction fields', () {
      final json = {
        'success': true,
        'message': 'Purchase successful',
        'data': {
          'coinsDeducted': 89.10,
          'newBalance': 310.90,
          'couponCode': 'FILMY10',
          'discountAmount': 10.90,
          'originalAmount': 100.0,
          'invoiceUrl': 'https://example.com/inv/123.pdf',
        },
      };

      final result = SeriesPurchaseResult.fromJson(json);

      expect(result.success, isTrue);
      expect(result.coinsDeducted, 89.10);
      expect(result.newBalance, 310.90);
      expect(result.couponCode, 'FILMY10');
      expect(result.discountAmount, 10.90);
      expect(result.originalAmount, 100.0);
      expect(result.invoiceUrl, 'https://example.com/inv/123.pdf');
    });
  });

  group('F. Content Model Discount Fields', () {
    test('Parses discount fields when provided by backend', () {
      final json = {
        'id': 101,
        'title': 'Second Son',
        'price': 100.0,
        'discountPercentage': 20.0,
        'discountedPrice': 80.0,
        'offerBadge': '20% OFF',
      };

      final content = Content.fromJson(json);
      expect(content.id, 101);
      expect(content.title, 'Second Son');
      expect(content.price, 100.0);
      expect(content.discountPercentage, 20.0);
      expect(content.discountedPrice, 80.0);
      expect(content.offerBadge, '20% OFF');
    });

    test('Leaves discount fields null when backend does not provide them', () {
      final json = {
        'id': 102,
        'title': 'Regular Movie',
        'price': 150.0,
      };

      final content = Content.fromJson(json);
      expect(content.discountPercentage, isNull);
      expect(content.discountedPrice, isNull);
      expect(content.offerBadge, isNull);
    });
  });

  group('G. PurchaseHistoryItem Coupon Fields', () {
    test('Parses coupon snapshot from purchase history response', () {
      final json = {
        'id': 99,
        'amount': 80.0,
        'originalAmount': 100.0,
        'discountAmount': 20.0,
        'couponCode': 'FILMY20',
        'status': 'Paid',
        'orderId': 'order_12345',
        'itemTitle': 'Second Son',
      };

      final item = PurchaseHistoryItem.fromJson(json);
      expect(item.id, 99);
      expect(item.amount, 80.0);
      expect(item.originalAmount, 100.0);
      expect(item.discountAmount, 20.0);
      expect(item.couponCode, 'FILMY20');
      expect(item.status, 'Paid');
      expect(item.orderId, 'order_12345');
    });
  });
}
