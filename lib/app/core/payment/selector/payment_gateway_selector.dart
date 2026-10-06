import 'package:ott/app/core/payment/models/payment_gateway_type.dart';

class PaymentGatewaySelector {
  PaymentGatewaySelector._();

  static const String defaultIndiaCurrency = 'INR';
  static const String defaultInternationalCurrency = 'USD';

  /// Returns true if the provided country code or name represents India.
  /// Defaults to true on null/empty/unspecified to guarantee backward compatibility for existing users.
  static bool isIndia(String? countryCodeOrName) {
    if (countryCodeOrName == null) return true;
    final normalized = countryCodeOrName.trim().toUpperCase();
    if (normalized.isEmpty) return true;

    return normalized == 'IN' ||
        normalized == 'IND' ||
        normalized == 'INDIA' ||
        normalized == '+91' ||
        normalized == '91' ||
        normalized == 'BHARAT';
  }

  /// Automatically resolves the payment gateway for a given country.
  static PaymentGatewayType selectGateway({String? country}) {
    return isIndia(country)
        ? PaymentGatewayType.razorpay
        : PaymentGatewayType.stripe;
  }

  /// Returns the recommended currency code for the payment gateway.
  static String getDefaultCurrency({String? country}) {
    return isIndia(country)
        ? defaultIndiaCurrency
        : defaultInternationalCurrency;
  }
}
