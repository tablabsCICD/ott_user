import 'package:flutter/material.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class SearchShimmer extends StatelessWidget {
  const SearchShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    if (ResponsiveWidget.isMobile(context)) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: 10,
        itemBuilder: (_, __) => _movieCardPlaceholder(context),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: ResponsiveWidget.isDesktop(context) ? 500 : 550,
        crossAxisSpacing: 8,
        mainAxisSpacing: 5,
        childAspectRatio: 7 / 3,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => _movieCardPlaceholder(context),
    );
  }

  Widget _movieCardPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ShimmerLoader(
              width: 100,
              height: 140,
              borderRadius: 8,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ShimmerLoader(
                    width: double.infinity,
                    height: 18,
                  ),
                  const SizedBox(height: 8),
                  ShimmerLoader(
                    width: 140,
                    height: 14,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 6),
                  ShimmerLoader(
                    width: 180,
                    height: 14,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ShimmerLoader(
                        width: 50,
                        height: 12,
                        borderRadius: 6,
                      ),
                      const SizedBox(width: 10),
                      ShimmerLoader(
                        width: 80,
                        height: 12,
                        borderRadius: 6,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
