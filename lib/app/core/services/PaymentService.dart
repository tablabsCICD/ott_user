import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/data/models/user.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:ott/app/core/services/razorpay_web_checkout.dart';

class PaymentOrder {
  PaymentOrder({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.receipt,
  });

  final String orderId;
  final int amount;
  final String currency;
  final String receipt;

  factory PaymentOrder.fromJson(Map<String, dynamic> json) {
    return PaymentOrder(
      orderId: json['orderId']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      currency: json['currency']?.toString() ?? 'INR',
      receipt: json['receipt']?.toString() ?? '',
    );
  }
}

class PaymentResult {
  PaymentResult({
    required this.success,
    required this.message,
    this.orderId,
    this.paymentId,
    this.signature,
    this.errorCode,
  });

  final bool success;
  final String message;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final int? errorCode;

  Map<String, Object?> toMap() {
    return {
      'success': success,
      'message': message,
      'orderId': orderId,
      'paymentId': paymentId,
      'signature': signature,
      'errorCode': errorCode,
    };
  }
}

class PaymentService {
  PaymentService({
    ApiHelper? apiHelper,
    LocalSharePreferences? preferences,
  })  : _apiHelper = apiHelper ?? ApiHelper(),
        _preferences =
            preferences ?? LocalSharePreferences.localSharePreferences;

  final ApiHelper _apiHelper;
  final LocalSharePreferences _preferences;
  Razorpay? _razorpay;

  static bool get isSupportedPlatform =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Completer<PaymentResult>? _paymentCompleter;
  PaymentOrder? _activeOrder;
  double? _activeAmount;
  int _activePlan = 0;

  Future<User?> _getUser() => _preferences.getUser();

  void init() {
    if (!isSupportedPlatform) {
      return;
    }
    _razorpay ??= Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handleError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<PaymentOrder> createOrder({
    required double amount,
    required int userId,
  }) async {
    final normalizedAmount =
        amount == amount.truncateToDouble() ? amount.toInt() : amount;
    final paiseAmount = (amount * 100).round();

    final urls = <String>[
      ApiConstant.createWalletOrder(amount, userId),
      '${ApiConstant.baseUrl}api/razorpay/create-order?amount=$normalizedAmount&userId=$userId',
      '${ApiConstant.baseUrl}api/razorpay/create-order?amount=$paiseAmount&customerId=$userId',
      '${ApiConstant.baseUrl}api/razorpay/create-order?amount=$paiseAmount&userId=$userId',
    ];

    Object? lastError;
    int? lastStatusCode;

    for (final url in urls) {
      try {
        final postResponse = await _apiHelper.postApiWithoutAuthToken(url);
        lastStatusCode = postResponse.statusCode;
        if (postResponse.statusCode == 200) {
          final order = _tryParseOrder(postResponse.body);
          if (order != null) return order;
        }

        final getResponse = await _apiHelper.getApi(url);
        lastStatusCode = getResponse.statusCode;
        if (getResponse.statusCode == 200) {
          final order = _tryParseOrder(getResponse.body);
          if (order != null) return order;
        }
      } catch (error) {
        lastError = error;
      }
    }

    if (lastError != null) {
      throw Exception('Unable to create Razorpay order: $lastError');
    }
    throw Exception(
      'Unable to create Razorpay order (status: ${lastStatusCode ?? 500}).',
    );
  }

  PaymentOrder? _tryParseOrder(String bodyString) {
    try {
      final body = jsonDecode(bodyString);
      if (body is! Map<String, dynamic>) return null;

      // Format A: {success:true, data:{orderId, amount, currency, receipt}}
      if (body['success'] == true && body['data'] is Map<String, dynamic>) {
        final data = body['data'] as Map<String, dynamic>;
        return PaymentOrder.fromJson({
          'orderId': data['orderId'] ?? data['id'],
          'amount': data['amount'],
          'currency': data['currency'] ?? 'INR',
          'receipt': data['receipt'] ?? '',
        });
      }

      // Format B: direct Razorpay order payload {id, amount, currency, receipt}
      if (body.containsKey('id') || body.containsKey('orderId')) {
        return PaymentOrder.fromJson({
          'orderId': body['orderId'] ?? body['id'],
          'amount': body['amount'],
          'currency': body['currency'] ?? 'INR',
          'receipt': body['receipt'] ?? '',
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
    final activeCompleter = _paymentCompleter;
    if (activeCompleter != null && !activeCompleter.isCompleted) {
      return activeCompleter.future;
    }

    if (!isSupportedPlatform) {
      return PaymentResult(
        success: false,
        message:
            'Razorpay checkout is only available on web, Android, and iOS.',
      );
    }
    final user = await _getUser();
    if (user?.id == null) {
      return PaymentResult(
        success: false,
        message: 'User not found',
      );
    }

    final razorpayKey = AppConstant.razorpayKeyId.trim();
    if (razorpayKey.isEmpty) {
      return PaymentResult(
        success: false,
        message: 'Configure your Razorpay key before using checkout.',
      );
    }

    _activeOrder = order;
    _activeAmount = amount;
    _activePlan = plan;
    _paymentCompleter = Completer<PaymentResult>();

    final options = <String, Object?>{
      'key': razorpayKey,
      'order_id': order.orderId,
      'amount': order.amount,
      'currency': order.currency,
      'name': AppConstant.razorpayMerchantName,
      'description': description,
      'retry': {'enabled': true, 'max_count': 2},
      'timeout': 900,
      'prefill': {
        'name': '${user?.firstName ?? ''} ${user?.lastName ?? ''}'.trim(),
        'email': user?.emailId ?? '',
        'contact': user?.mobileNumber ?? '',
      },
      'notes': {
        'userId': user?.id?.toString() ?? '',
        'plan': plan.toString(),
        'receipt': order.receipt,
      },
      'theme': {'color': '#E50914'},
    };

    if (AppConstant.razorpayLogoUrl.isNotEmpty) {
      options['image'] = AppConstant.razorpayLogoUrl;
    }

    if (kIsWeb) {
      options['retry'] = {'enabled': true};
      options['modal'] = {
        'confirm_close': true,
        'ondismiss': true,
      };

      final webResult = await openRazorpayWebCheckout(options);
      if (webResult['success'] == true) {
        final orderId = webResult['orderId']?.toString() ?? order.orderId;
        final paymentId = webResult['paymentId']?.toString();
        final signature = webResult['signature']?.toString();

        if (paymentId == null || signature == null) {
          return PaymentResult(
            success: false,
            message: 'Payment completed, but verification data is incomplete.',
          );
        }

        try {
          return await verifyPayment(
            razorPayOrderId: orderId,
            transactionId: paymentId,
            signature: signature,
            amount: amount,
            userId: user!.id!,
            plan: plan,
          );
        } catch (error) {
          return PaymentResult(
            success: false,
            message: 'Payment verification failed: $error',
            orderId: orderId,
            paymentId: paymentId,
            signature: signature,
          );
        }
      }

      return PaymentResult(
        success: false,
        message:
            webResult['message']?.toString() ?? 'Payment cancelled or failed.',
        orderId: webResult['orderId']?.toString(),
        paymentId: webResult['paymentId']?.toString(),
        errorCode: webResult['errorCode'] is int
            ? webResult['errorCode'] as int
            : int.tryParse(webResult['errorCode']?.toString() ?? ''),
      );
    }

    init();
    try {
      debugPrint('Opening Razorpay checkout for order ${order.orderId}');
      _razorpay!.open(options);
    } catch (error) {
      debugPrint('Unable to open Razorpay checkout: $error');
      return PaymentResult(
        success: false,
        message: 'Unable to open Razorpay checkout: $error',
      );
    }

    return _paymentCompleter!.future;
  }

  Future<PaymentResult> verifyPayment({
    required String razorPayOrderId,
    required String transactionId,
    required String signature,
    required double amount,
    required int userId,
    int plan = 0,
  }) async {
    final response = await _apiHelper.postApiWithBody(
      ApiConstant.verifyWalletPayment,
      {
        'amount': amount,
        'plan': plan,
        'razorPayOrderId': razorPayOrderId,
        'signature': signature,
        'transactionId': transactionId,
        'userId': userId,
      },
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
      orderId: razorPayOrderId,
      paymentId: transactionId,
      signature: signature,
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

  Future<void> _handleSuccess(PaymentSuccessResponse response) async {
    final completer = _paymentCompleter;
    final order = _activeOrder;
    final amount = _activeAmount;
    final user = await _getUser();

    if (completer == null || completer.isCompleted) {
      return;
    }

    if (order == null ||
        amount == null ||
        user?.id == null ||
        response.orderId == null ||
        response.paymentId == null ||
        response.signature == null) {
      completer.complete(
        PaymentResult(
          success: false,
          message: 'Payment completed, but verification data is incomplete.',
        ),
      );
      return;
    }

    try {
      final result = await verifyPayment(
        razorPayOrderId: response.orderId!,
        transactionId: response.paymentId!,
        signature: response.signature!,
        amount: amount,
        userId: user!.id!,
        plan: _activePlan,
      );
      completer.complete(result);
    } catch (error) {
      completer.complete(
        PaymentResult(
          success: false,
          message:
              'Payment verification failed. Please contact support if money was deducted. ${error.toString()}',
          orderId: response.orderId,
          paymentId: response.paymentId,
          signature: response.signature,
        ),
      );
    }
  }

  void _handleError(PaymentFailureResponse response) {
    final completer = _paymentCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }

    completer.complete(
      PaymentResult(
        success: false,
        message: response.message ?? 'Payment cancelled or failed.',
        errorCode: response.code,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    final completer = _paymentCompleter;
    if (completer == null || completer.isCompleted) {
      return;
    }

    completer.complete(
      PaymentResult(
        success: false,
        message:
            'External wallet selected (${response.walletName ?? 'unknown'}). Verification is pending.',
      ),
    );
  }

  void dispose() {
    if (!isSupportedPlatform || kIsWeb) {
      _paymentCompleter = null;
      _activeOrder = null;
      _activeAmount = null;
      _activePlan = 0;
      return;
    }
    _razorpay?.clear();
    _razorpay = null;
    _paymentCompleter = null;
    _activeOrder = null;
    _activeAmount = null;
    _activePlan = 0;
  }
}
