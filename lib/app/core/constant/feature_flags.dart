/// Compile-time feature flags.
///
/// Override with `--dart-define=<NAME>=true|false`.
abstract final class FeatureFlags {
  /// Mini Series gifting, one-time full purchase and the Profile
  /// "Mini Series Gifts" entry.
  ///
  /// On in every build mode. It previously defaulted to `kDebugMode`, so a
  /// plain `flutter build appbundle --release` compiled these features out and
  /// Play Store builds shipped without them. Pass
  /// `--dart-define=ENABLE_MINI_SERIES_COMMERCE=false` to switch them off.
  static const bool miniSeriesCommerce = bool.fromEnvironment(
    'ENABLE_MINI_SERIES_COMMERCE',
    defaultValue: true,
  );
}
