import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/payment/models/payment_gateway_type.dart';
import 'package:ott/app/core/payment/models/payment_order.dart';
import 'package:ott/app/core/payment/models/payment_result.dart';
import 'package:ott/app/core/payment/razorpay/razorpay_payment_service.dart';
import 'package:ott/app/core/payment/selector/payment_gateway_selector.dart';
import 'package:ott/app/core/payment/stripe/stripe_payment_service.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';

export 'package:ott/app/core/payment/models/payment_gateway_type.dart';
export 'package:ott/app/core/payment/models/payment_order.dart';
export 'package:ott/app/core/payment/models/payment_result.dart';
export 'package:ott/app/core/payment/selector/payment_gateway_selector.dart';

class PaymentService {
  PaymentService({
    ApiHelper? apiHelper,
    LocalSharePreferences? preferences,
    RazorpayPaymentService? razorpayService,
    StripePaymentService? stripeService,
  })  : _razorpayService = razorpayService ??
            RazorpayPaymentService(
              apiHelper: apiHelper,
              preferences: preferences,
            ),
        _stripeService = stripeService ??
            StripePaymentService(
              apiHelper: apiHelper,
              preferences: preferences,
            );

  final RazorpayPaymentService _razorpayService;
  final StripePaymentService _stripeService;

  static bool get isSupportedPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  void init() {
    _razorpayService.init();
  }

  /// Creates a payment order using country-based gateway selection:
  /// - India -> Razorpay
  /// - All other countries -> Stripe
  Future<PaymentOrder> createOrder({
    required double amount,
    required int userId,
    String? country,
    String? currency,
    PaymentGatewayType? gatewayOverride,
  }) async {
    final gateway = gatewayOverride ??
        PaymentGatewaySelector.selectGateway(country: country);

    if (gateway == PaymentGatewayType.stripe) {
      final selectedCurrency = currency ??
          PaymentGatewaySelector.getDefaultCurrency(country: country);
      return _stripeService.createOrder(
        amount: amount,
        userId: userId,
        currency: selectedCurrency,
        country: country,
      );
    }

    return _razorpayService.createOrder(
      amount: amount,
      userId: userId,
    );
  }

  /// Opens the appropriate checkout experience:
  /// - India -> Razorpay Checkout
  /// - All other countries -> Stripe Checkout Session
  Future<PaymentResult> openCheckout({
    required PaymentOrder order,
    required double amount,
    String description = 'Add Money to Wallet',
    int plan = 0,
    String? country,
    PaymentGatewayType? gatewayOverride,
  }) async {
    final gateway = gatewayOverride ??
        (order.checkoutUrl != null || order.sessionId != null
            ? PaymentGatewayType.stripe
            : PaymentGatewaySelector.selectGateway(country: country));

    if (gateway == PaymentGatewayType.stripe) {
      return _stripeService.openCheckout(
        order: order,
        amount: amount,
        description: description,
        plan: plan,
      );
    }

    return _razorpayService.openCheckout(
      order: order,
      amount: amount,
      description: description,
      plan: plan,
    );
  }

  /// Verifies a Razorpay payment with the backend.
  Future<PaymentResult> verifyPayment({
    required String razorPayOrderId,
    required String transactionId,
    required String signature,
    required double amount,
    required int userId,
    int plan = 0,
  }) {
    return _razorpayService.verifyPayment(
      razorPayOrderId: razorPayOrderId,
      transactionId: transactionId,
      signature: signature,
      amount: amount,
      userId: userId,
      plan: plan,
    );
  }

  /// Verifies a Stripe payment with the backend.
  Future<PaymentResult> verifyStripePayment({
    required String sessionId,
    required double amount,
    required int userId,
    int plan = 0,
    String currency = 'USD',
  }) {
    return _stripeService.verifyPayment(
      sessionId: sessionId,
      amount: amount,
      userId: userId,
      plan: plan,
      currency: currency,
    );
  }

  void dispose() {
    _razorpayService.dispose();
    _stripeService.dispose();
  }
}
