enum PurchaseKind {
  content('CONTENT'),
  season('SEASON'),
  episode('EPISODE'),
  shortPart('SHORT_PART');

  final String value;
  const PurchaseKind(this.value);

  static PurchaseKind fromString(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    for (final kind in PurchaseKind.values) {
      if (kind.value == normalized) return kind;
    }
    return PurchaseKind.content;
  }
}

/// Request payload for POST /api/coupons/validate
class CouponValidationRequest {
  const CouponValidationRequest({
    required this.couponCode,
    required this.userId,
    required this.purchaseKind,
    required this.targetId,
  });

  final String couponCode;
  final int userId;
  final String purchaseKind;
  final int targetId;

  Map<String, dynamic> toJson() {
    return {
      'couponCode': couponCode.trim().toUpperCase(),
      'userId': userId,
      'purchaseKind': purchaseKind,
      'targetId': targetId,
    };
  }
}

/// Validated coupon financial snapshot from backend
class CouponValidationData {
  const CouponValidationData({
    required this.couponCode,
    required this.originalAmount,
    required this.discountAmount,
    required this.finalPayableAmount,
    this.currency = 'INR',
    this.discountPercentage,
  });

  final String couponCode;
  final double originalAmount;
  final double discountAmount;
  final double finalPayableAmount;
  final String currency;
  final double? discountPercentage;

  factory CouponValidationData.fromJson(Map<String, dynamic> json) {
    final original = _asDouble(
      json['originalAmount'] ?? json['originalPrice'] ?? json['amount'],
    ) ?? 0.0;
    final discount = _asDouble(
      json['discountAmount'] ?? json['discount'] ?? 0.0,
    ) ?? 0.0;
    final finalAmount = _asDouble(
      json['finalPayableAmount'] ??
          json['finalAmount'] ??
          (original - discount > 0 ? original - discount : 0.0),
    ) ?? 0.0;
    final percentage = _asDouble(
      json['discountPercentage'] ?? json['percentage'],
    );

    return CouponValidationData(
      couponCode: (json['couponCode'] ?? json['code'] ?? '').toString().trim().toUpperCase(),
      originalAmount: original,
      discountAmount: discount,
      finalPayableAmount: finalAmount,
      currency: (json['currency'] ?? 'INR').toString().toUpperCase(),
      discountPercentage: percentage,
    );
  }

  String get formattedOriginalPrice => '₹${originalAmount.toStringAsFixed(2)}';
  String get formattedDiscountAmount => '₹${discountAmount.toStringAsFixed(2)}';
  String get formattedFinalAmount => '₹${finalPayableAmount.toStringAsFixed(2)}';

  Map<String, dynamic> toJson() {
    return {
      'couponCode': couponCode,
      'originalAmount': originalAmount,
      'discountAmount': discountAmount,
      'finalPayableAmount': finalPayableAmount,
      'currency': currency,
      if (discountPercentage != null) 'discountPercentage': discountPercentage,
    };
  }
}

/// Top-level response for POST /api/coupons/validate
class CouponValidationResponse {
  const CouponValidationResponse({
    required this.success,
    required this.message,
    this.data,
    this.errorCode,
    this.statusCode,
  });

  final bool success;
  final String message;
  final CouponValidationData? data;
  final String? errorCode;
  final int? statusCode;

  factory CouponValidationResponse.fromJson(
    Map<String, dynamic> json, {
    int? statusCode,
  }) {
    final isSuccess = json['success'] == true;
    final rawData = json['data'];
    CouponValidationData? data;
    if (rawData is Map<String, dynamic>) {
      data = CouponValidationData.fromJson(rawData);
    } else if (rawData is Map) {
      data = CouponValidationData.fromJson(Map<String, dynamic>.from(rawData));
    }

    final rawCode = json['errorCode'] ?? json['code'] ?? json['status'];
    final errorCode = rawCode?.toString();

    final message = (json['message'] ??
            (isSuccess ? 'Success' : 'Failed to validate coupon'))
        .toString();

    return CouponValidationResponse(
      success: isSuccess,
      message: message,
      data: data,
      errorCode: errorCode,
      statusCode: statusCode,
    );
  }

  factory CouponValidationResponse.failure({
    required String message,
    String? errorCode,
    int? statusCode,
  }) {
    return CouponValidationResponse(
      success: false,
      message: message,
      errorCode: errorCode,
      statusCode: statusCode,
    );
  }

  /// Maps backend error codes to user-friendly messages as required by specs
  String get userFriendlyMessage {
    return resolveCouponErrorMessage(errorCode: errorCode, fallbackMessage: message);
  }
}

/// Resolves user-friendly error messages based on official backend specs
String resolveCouponErrorMessage({
  String? errorCode,
  String? fallbackMessage,
}) {
  final normalizedCode = (errorCode ?? '').trim().toUpperCase();

  switch (normalizedCode) {
    case 'INVALID_COUPON':
      return 'This coupon code is invalid. Please check the code and try again.';
    case 'COUPON_INACTIVE':
      return 'This coupon is currently inactive.';
    case 'COUPON_NOT_STARTED':
      return 'This coupon is not available yet.';
    case 'COUPON_EXPIRED':
      return 'This coupon has expired.';
    case 'COUPON_CONTENT_MISMATCH':
      return 'This coupon is not valid for the selected content.';
    case 'COUPON_USER_LIMIT_REACHED':
      return 'You have already used or reserved this coupon.';
    case 'COUPON_TOTAL_LIMIT_REACHED':
      return 'This coupon has reached its redemption limit.';
    case 'IDEMPOTENCY_KEY_REQUIRED':
      return 'Checkout session expired. Please retry applying the coupon.';
    case 'IDEMPOTENCY_CONFLICT':
      return 'A checkout attempt with this reservation is already in progress. Please retry.';
    case 'CHECKOUT_EXPIRED':
      return 'The checkout session has expired. Please try again.';
    case 'INSUFFICIENT_BALANCE':
      return 'Insufficient wallet balance to complete this purchase.';
    case 'ALREADY_PURCHASED':
      return 'You have already purchased this content.';
    case 'PAYMENT_NOT_CAPTURED':
      return 'Payment was not captured. Please check with your payment provider.';
    case 'PAYMENT_MISMATCH':
      return 'Payment amount mismatch. Please retry checkout.';
    case 'VERIFIED_ORDER_REQUIRED':
      return 'A verified order is required to redeem this coupon.';
  }

  if (fallbackMessage != null && fallbackMessage.trim().isNotEmpty) {
    final clean = fallbackMessage
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .trim();
    if (!clean.toLowerCase().contains('stacktrace') &&
        !clean.toLowerCase().contains('internal server error') &&
        !clean.toLowerCase().contains('sql') &&
        !clean.toLowerCase().contains('entitymanager')) {
      return clean;
    }
  }

  return 'Unable to apply coupon. Please check the code and try again.';
}

double? _asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
