import 'package:flutter/material.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class ComingSoonShimmer extends StatelessWidget {
  final bool showSegmentedToggle;
  final bool showActionButton;

  const ComingSoonShimmer({
    super.key,
    this.showSegmentedToggle = false,
    this.showActionButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveWidget.isMobile(context) ? 1 : 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 16 / 9, // 🔒 fixed
      ),
      itemCount: 12,
      itemBuilder: (_, __) => _upcomingCardPlaceholder(context),
    );

    if (!showSegmentedToggle) {
      return grid;
    }

    return Column(
      children: [
        const SizedBox(height: 16),
        _segmentedTogglePlaceholder(context),
        const SizedBox(height: 8),
        Expanded(child: grid),
      ],
    );
  }

  Widget _segmentedTogglePlaceholder(BuildContext context) {
    final width = ResponsiveWidget.isMobile(context) ? double.infinity : 520.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 40,
        width: width,
        child: Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ShimmerLoader(
                  height: 32,
                  borderRadius: 16,
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _upcomingCardPlaceholder(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          const ShimmerLoader(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 0,
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoader(
                  width: double.infinity,
                  height: 14,
                ),
                const SizedBox(height: 6),
                ShimmerLoader(
                  width: 120,
                  height: 12,
                  borderRadius: 6,
                ),
                if (showActionButton) ...[
                  const SizedBox(height: 10),
                  ShimmerLoader(
                    width: 110,
                    height: 28,
                    borderRadius: 20,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
