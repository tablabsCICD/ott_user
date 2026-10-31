import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/payment/models/payment_gateway_type.dart';
import 'package:ott/app/core/payment/models/payment_order.dart';
import 'package:ott/app/core/payment/models/payment_result.dart';
import 'package:ott/app/core/payment/stripe/stripe_config.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/user.dart';
import 'package:url_launcher/url_launcher.dart';

class StripePaymentService {
  StripePaymentService({
    ApiHelper? apiHelper,
    LocalSharePreferences? preferences,
  })  : _apiHelper = apiHelper ?? ApiHelper(),
        _preferences =
            preferences ?? LocalSharePreferences.localSharePreferences;

  final ApiHelper _apiHelper;
  final LocalSharePreferences _preferences;

  static bool get isSupportedPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<User?> _getUser() => _preferences.getUser();

  Future<PaymentOrder> createOrder({
    required double amount,
    required int userId,
    String currency = StripeConfig.defaultCurrency,
    String? country,
  }) async {
    final normalizedAmount =
        amount == amount.truncateToDouble() ? amount.toInt() : amount;
    final centsAmount = (amount * 100).round();

    final urls = <String>[
      ApiConstant.createStripeCheckoutSession(amount, userId, currency: currency),
      '${ApiConstant.baseUrl}api/stripe/create-checkout-session?amount=$normalizedAmount&userId=$userId&currency=$currency',
      '${ApiConstant.baseUrl}api/stripe/create-checkout-session?amount=$centsAmount&customerId=$userId&currency=$currency',
      '${ApiConstant.baseUrl}api/stripe/create-order?amount=$normalizedAmount&userId=$userId&currency=$currency',
    ];

    Object? lastError;
    int? lastStatusCode;

    for (final url in urls) {
      try {
        debugPrint('Attempting to create Stripe session via: $url');
        final postResponse = await _apiHelper.postApiWithoutAuthToken(url);
        lastStatusCode = postResponse.statusCode;
        debugPrint(
          'POST Stripe response status: ${postResponse.statusCode}, body: ${postResponse.body}',
        );
        if (postResponse.statusCode == 200) {
          final order = _tryParseOrder(postResponse.body, fallbackCurrency: currency);
          if (order != null) return order;
        }

        final getResponse = await _apiHelper.getApi(url);
        lastStatusCode = getResponse.statusCode;
        if (getResponse.statusCode == 200) {
          final order = _tryParseOrder(getResponse.body, fallbackCurrency: currency);
          if (order != null) return order;
        }
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      throw Exception('Unable to create Stripe checkout session: $lastError');
    }
    throw Exception(
      'Unable to create Stripe checkout session (status: ${lastStatusCode ?? 500}).',
    );
  }

  PaymentOrder? _tryParseOrder(String bodyString, {String fallbackCurrency = 'USD'}) {
    try {
      final body = jsonDecode(bodyString);
      if (body is! Map<String, dynamic>) return null;

      if (body['success'] == true && body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        return PaymentOrder.fromJson({
          'orderId': data['orderId'] ?? data['id'] ?? data['sessionId'],
          'sessionId': data['sessionId'] ?? data['id'] ?? data['orderId'],
          'amount': data['amount'],
          'currency': data['currency'] ?? fallbackCurrency,
          'receipt': data['receipt'] ?? '',
          'checkoutUrl': data['checkoutUrl'] ?? data['url'] ?? data['sessionUrl'],
          'publishableKey': data['publishableKey'],
          'clientSecret': data['clientSecret'],
        });
      }

      if (body.containsKey('id') || body.containsKey('sessionId') || body.containsKey('url')) {
        return PaymentOrder.fromJson({
          'orderId': body['orderId'] ?? body['id'] ?? body['sessionId'],
          'sessionId': body['sessionId'] ?? body['id'] ?? body['orderId'],
          'amount': body['amount'],
          'currency': body['currency'] ?? fallbackCurrency,
          'receipt': body['receipt'] ?? '',
          'checkoutUrl': body['checkoutUrl'] ?? body['url'] ?? body['sessionUrl'],
          'publishableKey': body['publishableKey'],
          'clientSecret': body['clientSecret'],
        });
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<PaymentResult> openCheckout({
    required PaymentOrder order,
    required double amount,
    String description = 'Add Money to Wallet',
    int plan = 0,
  }) async {
    if (!isSupportedPlatform) {
      return const PaymentResult(
        success: false,
        message: 'Stripe checkout is only available on web, Android, and iOS.',
        gateway: PaymentGatewayType.stripe,
      );
    }

    final user = await _getUser();
    if (user?.id == null) {
      return const PaymentResult(
        success: false,
        message: 'User not found',
        gateway: PaymentGatewayType.stripe,
      );
    }

    final checkoutUrl = order.checkoutUrl?.trim() ?? '';
    if (checkoutUrl.isEmpty) {
      return const PaymentResult(
        success: false,
        message: 'Invalid Stripe checkout URL returned from server.',
        gateway: PaymentGatewayType.stripe,
      );
    }

    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
      return const PaymentResult(
        success: false,
        message: 'Invalid Stripe checkout link.',
        gateway: PaymentGatewayType.stripe,
      );
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
      );

      if (!launched) {
        return const PaymentResult(
          success: false,
          message: 'Unable to launch Stripe checkout.',
          gateway: PaymentGatewayType.stripe,
        );
      }

      // Verify payment with the backend after the checkout interaction
      return await verifyPayment(
        sessionId: order.sessionId ?? order.orderId,
        amount: amount,
        userId: user!.id!,
        plan: plan,
        currency: order.currency,
      );
    } catch (error) {
      return PaymentResult(
        success: false,
        message: 'Stripe checkout error: $error',
        sessionId: order.sessionId ?? order.orderId,
        gateway: PaymentGatewayType.stripe,
      );
    }
  }

  Future<PaymentResult> verifyPayment({
    required String sessionId,
    required double amount,
    required int userId,
    int plan = 0,
    String currency = StripeConfig.defaultCurrency,
  }) async {
    debugPrint(
      'Stripe verification request: ${ApiConstant.verifyStripePayment}, body: ${{
        'amount': amount,
        'currency': currency,
        'plan': plan,
        'sessionId': sessionId,
        'userId': userId,
      }}',
    );

    final response = await _apiHelper.postApiWithBody(
      ApiConstant.verifyStripePayment,
      {
        'amount': amount,
        'currency': currency,
        'plan': plan,
        'sessionId': sessionId,
        'userId': userId,
      },
    );

    debugPrint(
      'Stripe verification response status: ${response.statusCode}, body: ${response.body}',
    );

    final body = _decodeResponseBody(response.body);
    final success = response.statusCode == 200 && body['success'] == true;
    final message = body['message']?.toString();

    return PaymentResult(
      success: success,
      message: message ??
          (success
              ? 'Payment verified successfully.'
              : 'Payment verification failed. Please contact support if money was deducted.'),
      orderId: sessionId,
      sessionId: sessionId,
      paymentId: body['paymentIntentId']?.toString() ?? body['transactionId']?.toString() ?? sessionId,
      gateway: PaymentGatewayType.stripe,
    );
  }

  Map<String, dynamic> _decodeResponseBody(String bodyString) {
    try {
      final body = jsonDecode(bodyString);
      if (body is Map<String, dynamic>) {
        return body;
      }
    } catch (_) {}

    return {
      'success': false,
      'message':
          'Payment verification returned an invalid response. Please contact support if money was deducted.',
    };
  }

  void dispose() {}
}
