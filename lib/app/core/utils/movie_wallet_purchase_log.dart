import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug-only purchase diagnostics. Defaults to the movie "Proceed to Pay"
/// wallet purchase prefix; other flows pass their own [prefix]
/// (e.g. `[MINI_SERIES_GIFT]`, `[MINI_SERIES_FULL_PURCHASE]`).
///
/// Uses [debugPrint] so lines appear in the `flutter run` terminal as well as
/// the IDE debug console. Nothing is printed in profile/release builds.
/// Authorization headers and token/secret-like fields are masked.
abstract final class MovieWalletPurchaseLog {
  static const defaultPrefix = '[MOVIE_WALLET_PURCHASE]';
  static const miniSeriesGift = '[MINI_SERIES_GIFT]';
  static const miniSeriesGiftPurchase = '[MINI_SERIES_GIFT_PURCHASE]';
  static const miniSeriesGiftClaim = '[MINI_SERIES_GIFT_CLAIM]';
  static const miniSeriesGiftHistory = '[MINI_SERIES_GIFT_HISTORY]';
  static const miniSeriesGiftReceived = '[MINI_SERIES_GIFT_RECEIVED]';
  static const miniSeriesFullPurchase = '[MINI_SERIES_FULL_PURCHASE]';

  static void _line(String text, [String prefix = defaultPrefix]) {
    if (!kDebugMode) return;
    debugPrint('$prefix $text', wrapWidth: 1024);
  }

  /// Free-form debug line (e.g. Mini Series ID, quantity, price details).
  static void info(String text, {String prefix = defaultPrefix}) =>
      _line(text, prefix);

  /// Purchase context computed on the billing page before any API call.
  static void context({
    required int? movieId,
    required double originalAmount,
    required String? couponCode,
    required double? discountAmount,
    required double finalAmount,
    required double walletBalance,
    required int giftCount,
  }) {
    if (!kDebugMode) return;
    _line('CONTEXT');
    _line('MOVIE_ID: $movieId');
    _line('ORIGINAL_AMOUNT: ${originalAmount.toStringAsFixed(2)}');
    _line('COUPON_CODE: ${couponCode ?? '<none>'}');
    _line('DISCOUNT_AMOUNT: ${(discountAmount ?? 0).toStringAsFixed(2)}');
    _line('FINAL_AMOUNT: ${finalAmount.toStringAsFixed(2)}');
    _line('WALLET_BALANCE: ${walletBalance.toStringAsFixed(2)}');
    _line('GIFT_COUNT: $giftCount');
    _line('PAYMENT_METHOD: WALLET');
  }

  static void request({
    required String step,
    required String method,
    required String url,
    required Map<String, String> headers,
    Object? body,
    String prefix = defaultPrefix,
  }) {
    if (!kDebugMode) return;
    void l(String t) => _line(t, prefix);
    l('REQUEST ($step)');
    l('METHOD: $method');
    l('URL: $url');
    l('HEADERS: ${jsonEncode(_maskHeaders(headers))}');
    l('REQUEST_BODY: ${body == null ? '<none>' : jsonEncode(_mask(body))}');
  }

  static void response({
    required String step,
    required int statusCode,
    required String body,
    required Duration elapsed,
    String prefix = defaultPrefix,
  }) {
    if (!kDebugMode) return;
    void l(String t) => _line(t, prefix);
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {}
    final map = decoded is Map ? decoded : null;
    final data = map?['data'];
    final dataMap = data is Map ? data : null;
    l('RESPONSE ($step)');
    l('STATUS_CODE: $statusCode');
    l('RESPONSE_TIME_MS: ${elapsed.inMilliseconds}');
    l('RESPONSE_BODY: ${decoded == null ? body : jsonEncode(_mask(decoded))}');
    l('SUCCESS: ${map?['success'] ?? map?['isSuccess'] ?? '<not in body>'}');
    final message = map?['message'] ?? map?['error'];
    if (message != null) l('MESSAGE: $message');
    final errorCode = map?['errorCode'] ?? dataMap?['errorCode'];
    if (errorCode != null) l('ERROR_CODE: $errorCode');
    final transactionId = dataMap?['transactionId'] ??
        dataMap?['id'] ??
        map?['transactionId'] ??
        map?['orderId'];
    if (transactionId != null) l('TRANSACTION_ID: $transactionId');
  }

  static void exception({
    required String step,
    required Object error,
    required StackTrace stackTrace,
    required Duration elapsed,
    String prefix = defaultPrefix,
  }) {
    if (!kDebugMode) return;
    void l(String t) => _line(t, prefix);
    final kind = error is TimeoutException
        ? 'TIMEOUT'
        : error is SocketException || error is HandshakeException
            ? 'CONNECTIVITY'
            : 'OTHER';
    l('EXCEPTION ($step)');
    l('EXCEPTION_TYPE: ${error.runtimeType}');
    l('EXCEPTION_KIND: $kind');
    l('EXCEPTION_MESSAGE: $error');
    l('ELAPSED_MS: ${elapsed.inMilliseconds}');
    l('STACK_TRACE: ${stackTrace.toString().split('\n').take(8).join(' | ')}');
  }

  static Map<String, String> _maskHeaders(Map<String, String> headers) =>
      headers.map((key, value) => MapEntry(
            key,
            _isSensitiveKey(key) ? '<redacted>' : value,
          ));

  static Object? _mask(Object? value) {
    if (value is Map) {
      return value.map((key, v) => MapEntry(
            key.toString(),
            _isSensitiveKey(key.toString()) ? '<redacted>' : _mask(v),
          ));
    }
    if (value is List) return value.map(_mask).toList();
    return value;
  }

  static bool _isSensitiveKey(String key) {
    final k = key.toLowerCase().replaceAll(RegExp(r'[-_]'), '');
    return k == 'authorization' ||
        k.contains('token') ||
        k.contains('password') ||
        k.contains('secret') ||
        k.contains('signature') ||
        k.contains('cookie') ||
        k == 'cardnumber' ||
        k == 'cvv' ||
        k.contains('email') ||
        k.contains('mobile') ||
        k.contains('phone');
  }
}
