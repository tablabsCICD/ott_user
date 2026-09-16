import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/payment/models/payment_gateway_type.dart';
import 'package:ott/app/core/payment/selector/payment_gateway_selector.dart';

void main() {
  group('PaymentGatewaySelector', () {
    test('routes India country codes and names to Razorpay', () {
      expect(PaymentGatewaySelector.isIndia('IN'), isTrue);
      expect(PaymentGatewaySelector.isIndia('in'), isTrue);
      expect(PaymentGatewaySelector.isIndia('IND'), isTrue);
      expect(PaymentGatewaySelector.isIndia('India'), isTrue);
      expect(PaymentGatewaySelector.isIndia('INDIA'), isTrue);
      expect(PaymentGatewaySelector.isIndia('+91'), isTrue);
      expect(PaymentGatewaySelector.isIndia('91'), isTrue);
      expect(PaymentGatewaySelector.isIndia('Bharat'), isTrue);

      expect(
        PaymentGatewaySelector.selectGateway(country: 'IN'),
        PaymentGatewayType.razorpay,
      );
      expect(
        PaymentGatewaySelector.selectGateway(country: 'India'),
        PaymentGatewayType.razorpay,
      );
      expect(
        PaymentGatewaySelector.getDefaultCurrency(country: 'India'),
        'INR',
      );
    });

    test('defaults to Razorpay and INR on null or empty country', () {
      expect(PaymentGatewaySelector.isIndia(null), isTrue);
      expect(PaymentGatewaySelector.isIndia(''), isTrue);
      expect(PaymentGatewaySelector.isIndia('   '), isTrue);

      expect(
        PaymentGatewaySelector.selectGateway(country: null),
        PaymentGatewayType.razorpay,
      );
      expect(
        PaymentGatewaySelector.selectGateway(country: ''),
        PaymentGatewayType.razorpay,
      );
      expect(
        PaymentGatewaySelector.getDefaultCurrency(country: null),
        'INR',
      );
    });

    test('routes all other countries to Stripe with USD default currency', () {
      final nonIndiaCountries = [
        'US',
        'USA',
        'United States',
        'GB',
        'UK',
        'United Kingdom',
        'CA',
        'Canada',
        'AU',
        'Australia',
        'DE',
        'Germany',
        'FR',
        'France',
        'JP',
        'Japan',
        'AE',
        'United Arab Emirates',
        'SG',
        'Singapore',
      ];

      for (final country in nonIndiaCountries) {
        expect(
          PaymentGatewaySelector.isIndia(country),
          isFalse,
          reason: '$country should NOT be detected as India',
        );
        expect(
          PaymentGatewaySelector.selectGateway(country: country),
          PaymentGatewayType.stripe,
          reason: '$country should route to Stripe',
        );
        expect(
          PaymentGatewaySelector.getDefaultCurrency(country: country),
          'USD',
          reason: '$country should default to USD',
        );
      }
    });
  });
}
