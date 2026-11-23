import 'package:flutter/foundation.dart';

/// Compile-time feature flags.
///
/// Override with `--dart-define=<NAME>=true|false`.
abstract final class FeatureFlags {
  /// Mini Series gifting and one-time full purchase. The backend endpoints
  /// are not confirmed yet; see docs/mini_series_gift_and_full_purchase_backend.md.
  ///
  /// On by default in debug builds (for UI review), off in profile/release
  /// builds unless passed explicitly.
  static const bool miniSeriesCommerce = bool.fromEnvironment(
    'ENABLE_MINI_SERIES_COMMERCE',
    defaultValue: kDebugMode,
  );
}
