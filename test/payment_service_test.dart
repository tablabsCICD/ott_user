import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/payment/models/payment_gateway_type.dart';
import 'package:ott/app/core/payment/models/payment_order.dart';
import 'package:ott/app/core/payment/models/payment_result.dart';

void main() {
  group('Payment Models Test', () {
    test('PaymentOrder parses direct and nested formats correctly', () {
      final jsonDirect = {
        'orderId': 'order_123',
        'amount': 50000,
        'currency': 'INR',
        'receipt': 'rcpt_1',
      };
      final orderDirect = PaymentOrder.fromJson(jsonDirect);
      expect(orderDirect.orderId, 'order_123');
      expect(orderDirect.amount, 50000);
      expect(orderDirect.currency, 'INR');
      expect(orderDirect.receipt, 'rcpt_1');

      final jsonStripe = {
        'sessionId': 'cs_test_abc123',
        'amount': 1000,
        'currency': 'USD',
        'checkoutUrl': 'https://checkout.stripe.com/pay/cs_test_abc123',
      };
      final orderStripe = PaymentOrder.fromJson(jsonStripe);
      expect(orderStripe.sessionId, 'cs_test_abc123');
      expect(orderStripe.checkoutUrl, 'https://checkout.stripe.com/pay/cs_test_abc123');
      expect(orderStripe.currency, 'USD');
    });

    test('PaymentResult converts toMap and preserves gateway metadata', () {
      const result = PaymentResult(
        success: true,
        message: 'Payment verified',
        orderId: 'order_123',
        paymentId: 'pay_123',
        signature: 'sig_123',
        gateway: PaymentGatewayType.razorpay,
      );

      final map = result.toMap();
      expect(map['success'], isTrue);
      expect(map['message'], 'Payment verified');
      expect(map['orderId'], 'order_123');
      expect(map['paymentId'], 'pay_123');
      expect(map['gateway'], 'razorpay');

      const stripeResult = PaymentResult(
        success: true,
        message: 'Stripe payment successful',
        sessionId: 'cs_test_123',
        gateway: PaymentGatewayType.stripe,
      );

      final stripeMap = stripeResult.toMap();
      expect(stripeMap['success'], isTrue);
      expect(stripeMap['sessionId'], 'cs_test_123');
      expect(stripeMap['gateway'], 'stripe');
    });
  });
}
