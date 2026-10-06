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
  });

  final bool success;
  final String message;
  final String? orderId;
  final String? paymentId;
  final String? signature;
  final int? errorCode;
  final PaymentGatewayType? gateway;
  final String? sessionId;

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
    };
  }
}
