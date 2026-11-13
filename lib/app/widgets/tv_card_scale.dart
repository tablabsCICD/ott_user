import 'package:flutter/material.dart';

/// Uniformly shrinks the existing movie cards on Android TV.
///
/// The card is laid out at its original design size and then scaled down as
/// a whole, so its aspect ratio, proportions and content stay exactly the
/// same — only the size changes. The scale is derived from the row width, so
/// the same number of cards is visible on 720p, 1080p and 4K TVs.
class TvCardScale {
  const TvCardScale._(this.scale);

  /// Number of cards visible in one row on TV. The fraction lets the next
  /// card peek in from the right edge, hinting that the row scrolls.
  static const double visibleCards = 4.5;

  /// Scale factor applied to the original card design.
  final double scale;

  /// Scale for a horizontal row [availableWidth] wide whose cards are
  /// [baseExtent] wide at their original size.
  factory TvCardScale.forRow(double availableWidth, double baseExtent) {
    final scale = (availableWidth / visibleCards) / baseExtent;
    return TvCardScale._(scale.clamp(0.3, 1.0));
  }

  /// Scale that fits a card of [baseWidth] into [targetWidth].
  factory TvCardScale.forWidth(double targetWidth, double baseWidth) {
    return TvCardScale._((targetWidth / baseWidth).clamp(0.3, 1.0));
  }

  double size(double base) => base * scale;

  /// Renders [child] at [baseWidth] x [baseHeight] and scales it down.
  Widget wrap({
    required double baseWidth,
    required double baseHeight,
    required Widget child,
  }) {
    return SizedBox(
      width: size(baseWidth),
      height: size(baseHeight),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: baseWidth,
          height: baseHeight,
          child: child,
        ),
      ),
    );
  }
}
