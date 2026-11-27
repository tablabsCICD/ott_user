import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/data/models/coupon/coupon_models.dart';
import 'package:uuid/uuid.dart';

class CouponService {
  CouponService({ApiHelper? apiHelper}) : _apiHelper = apiHelper ?? ApiHelper();

  final ApiHelper _apiHelper;
  static const Uuid _uuid = Uuid();

  /// Generates a unique UUID v4 idempotency key for checkout attempts.
  static String generateIdempotencyKey() => _uuid.v4();

  /// Validates a coupon code against the backend for a specific purchase target.
  ///
  /// Purchase kind mapping:
  /// - Movie / Short film: 'CONTENT'
  /// - Series season: 'SEASON'
  /// - Series episode: 'EPISODE'
  /// - ShortMaster part: 'SHORT_PART'
  Future<CouponValidationResponse> validateCoupon({
    required String couponCode,
    required int userId,
    required String purchaseKind,
    required int targetId,
  }) async {
    final cleanCode = couponCode.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      return CouponValidationResponse.failure(
        message: 'Please enter a coupon code.',
        errorCode: 'INVALID_COUPON',
      );
    }

    final requestPayload = CouponValidationRequest(
      couponCode: cleanCode,
      userId: userId,
      purchaseKind: purchaseKind,
      targetId: targetId,
    ).toJson();

    final url = ApiConstant.validateCoupon;
    log('Validating coupon at: $url with payload: $requestPayload', name: 'CouponService');

    try {
      final response = await _apiHelper.postApiWithBody(url, requestPayload);
      final statusCode = response.statusCode;
      final rawBody = response.body.toString();
      log('Coupon validate response ($statusCode): $rawBody', name: 'CouponService');

      Map<String, dynamic> json;
      try {
        final decoded = jsonDecode(rawBody);
        json = decoded is Map<String, dynamic>
            ? decoded
            : decoded is Map
                ? Map<String, dynamic>.from(decoded)
                : <String, dynamic>{};
      } catch (_) {
        json = <String, dynamic>{};
      }

      if (statusCode == 200) {
        final parsed = CouponValidationResponse.fromJson(json, statusCode: 200);
        return parsed;
      }

      // Non-200 failure (e.g. 400, 404, 409, 422)
      final parsed = CouponValidationResponse.fromJson(json, statusCode: statusCode);
      if (parsed.success) {
        // If the server returned non-200 but body said success, enforce failure
        return CouponValidationResponse.failure(
          message: parsed.message.isNotEmpty
              ? parsed.message
              : 'Coupon is not valid for this content.',
          errorCode: parsed.errorCode ?? 'INVALID_COUPON',
          statusCode: statusCode,
        );
      }
      return parsed;
    } catch (error, st) {
      log('Coupon validation network error: $error', stackTrace: st, name: 'CouponService');
      return CouponValidationResponse.failure(
        message: resolveCouponErrorMessage(
          fallbackMessage: error.toString(),
        ),
      );
    }
  }
}
