class StripeConfig {
  StripeConfig._();

  static const String publishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static const String defaultCurrency = 'USD';
  static const String merchantDisplayName = 'Filmytell';
}
