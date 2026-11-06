import 'dart:convert';

import 'package:ott/app/core/payment/models/payment_gateway_type.dart';

class PaymentResult {
  const PaymentResult({
    required this.success,
    required this.message,
    this.orderId,
    this.paymentId,
    this.signature,
    this.errorCode,
    this.gateway,
    this.sessionId,
    this.cancelled = false,
  });

  /// Message used for a cancelled payment when the gateway gives no reason.
  /// Screens replace it with the localized cancellation message.
  static const String defaultCancelledMessage = 'Payment cancelled.';

  final bool success;
  final String message;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final int? errorCode;
  final PaymentGatewayType? gateway;
  final String? sessionId;

  /// True when the user closed/cancelled checkout (not a failed or
  /// successful payment). A cancelled result is never verified.
  final bool cancelled;

  Map<String, Object?> toMap() {
    return {
      'success': success,
      'message': message,
      if (orderId != null) 'orderId': orderId,
      if (paymentId != null) 'paymentId': paymentId,
      if (signature != null) 'signature': signature,
      if (errorCode != null) 'errorCode': errorCode,
      if (gateway != null) 'gateway': gateway!.name,
      if (sessionId != null) 'sessionId': sessionId,
      'cancelled': cancelled,
    };
  }

  /// Extracts a human-readable reason from a gateway error message.
  ///
  /// Razorpay reports errors either as plain text or as a JSON string such as
  /// `{"error":{"description":"undefined","reason":"payment_cancelled"}}`.
  /// Returns null when there is no usable text (empty, "undefined", "null").
  static String? readableGatewayMessage(String? raw) {
    final text = raw?.trim();
    if (text == null || text.isEmpty) return null;

    if (text.startsWith('{')) {
      try {
        final decoded = jsonDecode(text);
        if (decoded is Map) {
          final error = decoded['error'] is Map ? decoded['error'] as Map : decoded;
          return readableGatewayMessage(
            (error['description'] ?? error['message'])?.toString(),
          );
        }
      } catch (_) {
        // Not JSON; fall through and treat as plain text.
      }
    }

    final lower = text.toLowerCase();
    if (lower == 'undefined' || lower == 'null' || lower == 'none') return null;
    return text;
  }

  /// True when a raw gateway error payload says the user cancelled.
  static bool looksCancelled(String? raw) {
    final lower = raw?.toLowerCase() ?? '';
    return lower.contains('cancel') || lower.contains('dismiss');
  }
}
