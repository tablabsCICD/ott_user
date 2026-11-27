import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Debug-only, block-formatted request/response logging for Mini Series
/// gifting and ownership APIs. Prints with [debugPrint] so it shows in the
/// `flutter run` terminal and the IDE debug console. Nothing is printed in
/// profile/release builds. Authorization and personal fields are masked.
abstract final class MiniSeriesApiLog {
  static const giftDetails = 'MINI_SERIES_GIFT_DETAILS';
  static const giftPurchase = 'MINI_SERIES_GIFT_PURCHASE';
  static const giftClaim = 'MINI_SERIES_GIFT_CLAIM';
  static const giftHistory = 'MINI_SERIES_GIFT_HISTORY';
  static const giftReceived = 'MINI_SERIES_GIFT_RECEIVED';
  static const fullPurchaseDetails = 'MINI_SERIES_FULL_PURCHASE_DETAILS';
  static const purchaseStatus = 'MINI_SERIES_PURCHASE_STATUS';
  static const detailRefresh = 'MINI_SERIES_DETAIL_REFRESH';
  static const fullPurchase = 'MINI_SERIES_FULL_PURCHASE';

  /// One context line under an API name (IDs, amounts; no secrets).
  static void note(String apiName, String text) {
    if (!kDebugMode) return;
    debugPrint('[$apiName] $text', wrapWidth: 1024);
  }

  static const _encoder = JsonEncoder.withIndent('  ');

  static void _print(String block) {
    if (!kDebugMode) return;
    for (final line in block.split('\n')) {
      debugPrint(line, wrapWidth: 1024);
    }
  }

  static void request({
    required String apiName,
    required String method,
    required String url,
    required Map<String, String> headers,
    Object? body,
    DateTime? at,
  }) {
    if (!kDebugMode) return;
    final uri = Uri.tryParse(url);
    final b = StringBuffer()
      ..writeln('========== MINI SERIES GIFT API REQUEST ==========')
      ..writeln('API NAME: $apiName')
      ..writeln('METHOD: $method')
      ..writeln('URL: $url')
      ..writeln()
      ..writeln('HEADERS:');
    _maskHeaders(headers).forEach((k, v) => b.writeln('$k: $v'));
    b
      ..writeln()
      ..writeln('QUERY PARAMETERS:')
      ..writeln(_encoder.convert(uri?.queryParameters ?? const {}))
      ..writeln()
      ..writeln('REQUEST BODY:')
      ..writeln(body == null ? '<none>' : _encoder.convert(_mask(body)))
      ..writeln()
      ..writeln('REQUEST TIME: ${(at ?? DateTime.now()).toUtc().toIso8601String()}')
      ..write('==================================================');
    _print(b.toString());
  }

  /// Logs the raw response before any model parsing. A response is only a
  /// backend success when HTTP is 2xx **and** `success` is true.
  static void response({
    required String apiName,
    required String url,
    required int statusCode,
    required String body,
    required Duration elapsed,
    Map<String, String> headers = const {},
    Object? requestBody,
  }) {
    if (!kDebugMode) return;
    Object? decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {}
    final map = decoded is Map ? decoded : null;
    final backendSuccess = map?['success'];
    final message = map?['message'] ?? map?['error'];
    final isFailure =
        statusCode < 200 || statusCode >= 300 || backendSuccess != true;
    final b = StringBuffer()
      ..writeln(isFailure
          ? '========== MINI SERIES GIFT API ERROR =========='
          : '========== MINI SERIES GIFT API RESPONSE ==========')
      ..writeln('API NAME: $apiName')
      ..writeln('URL: $url')
      ..writeln()
      ..writeln('HTTP STATUS: $statusCode');
    final useful = {
      for (final k in const ['content-type', 'date', 'x-request-id'])
        if (headers[k] != null) k: headers[k]!,
    };
    if (useful.isNotEmpty) {
      b
        ..writeln()
        ..writeln('RESPONSE HEADERS:');
      useful.forEach((k, v) => b.writeln('$k: $v'));
    }
    if (isFailure && requestBody != null) {
      b
        ..writeln()
        ..writeln('REQUEST BODY:')
        ..writeln(_encoder.convert(_mask(requestBody)));
    }
    b
      ..writeln()
      ..writeln('RESPONSE BODY:')
      ..writeln(decoded == null
          ? (body.isEmpty ? '<empty>' : body)
          : _encoder.convert(_mask(decoded)))
      ..writeln()
      ..writeln('BACKEND SUCCESS: ${backendSuccess ?? '<not in body>'}')
      ..writeln('BACKEND MESSAGE: ${message ?? '<none>'}');
    if (map?['errorCode'] != null) b.writeln('ERROR CODE: ${map!['errorCode']}');
    b
      ..writeln('RESPONSE TIME: ${DateTime.now().toUtc().toIso8601String()}')
      ..writeln('API DURATION: ${elapsed.inMilliseconds} ms')
      ..write('===================================================');
    _print(b.toString());
  }

  static void exception({
    required String apiName,
    required String url,
    required Object error,
    required StackTrace stackTrace,
    required Duration elapsed,
    Object? requestBody,
  }) {
    if (!kDebugMode) return;
    final kind = error is TimeoutException
        ? 'TIMEOUT'
        : error is SocketException || error is HandshakeException
            ? 'CONNECTIVITY'
            : 'OTHER';
    final b = StringBuffer()
      ..writeln('========== MINI SERIES GIFT API EXCEPTION ==========')
      ..writeln('API NAME: $apiName')
      ..writeln('URL: $url')
      ..writeln('REQUEST BODY: ${requestBody == null ? '<none>' : jsonEncode(_mask(requestBody))}')
      ..writeln('EXCEPTION TYPE: ${error.runtimeType}')
      ..writeln('EXCEPTION KIND: $kind')
      ..writeln('EXCEPTION MESSAGE: $error')
      ..writeln('API DURATION: ${elapsed.inMilliseconds} ms')
      ..writeln('STACK TRACE:')
      ..writeln(stackTrace.toString().split('\n').take(10).join('\n'))
      ..write('====================================================');
    _print(b.toString());
  }

  static Map<String, String> _maskHeaders(Map<String, String> headers) =>
      headers.map((k, v) {
        if (k.toLowerCase() == 'authorization') {
          return MapEntry(k, v.startsWith('Bearer ') ? 'Bearer <MASKED>' : '<MASKED>');
        }
        return MapEntry(k, _isSensitiveKey(k) ? '<MASKED>' : v);
      });

  static Object? _mask(Object? value) {
    if (value is Map) {
      return value.map((k, v) {
        final key = k.toString();
        if (_isSensitiveKey(key)) return MapEntry(key, '<MASKED>');
        // Gift codes are single-use credentials: log only a short prefix.
        if (key.toLowerCase().replaceAll(RegExp(r'[-_]'), '') == 'giftcode' &&
            v != null) {
          final code = v.toString();
          return MapEntry(
              key, code.length <= 4 ? '****' : '${code.substring(0, 4)}****');
        }
        return MapEntry(key, _mask(v));
      });
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
        k.contains('email') ||
        k.contains('mobile') ||
        k.contains('phone') ||
        k == 'cardnumber' ||
        k == 'cvv';
  }
}
