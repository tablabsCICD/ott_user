import 'package:flutter/material.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class ProfileShimmer extends StatelessWidget {
  const ProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveWidget.isMobile(context);
    final headerWidth = isMobile ? double.infinity : 500.0;
    final cardMaxWidth = isMobile ? double.infinity : 600.0;

    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            _buildHeader(context, headerWidth),
            const SizedBox(height: 18),
            _buildCardGroup(
              context,
              cardMaxWidth,
              titleWidth: 120,
              rows: 1,
              showSubtitle: true,
            ),
            _buildCardGroup(
              context,
              cardMaxWidth,
              titleWidth: 80,
              rows: 2,
            ),
            _buildCardGroup(
              context,
              cardMaxWidth,
              titleWidth: 140,
              rows: 5,
            ),
            _buildCardGroup(
              context,
              cardMaxWidth,
              titleWidth: 180,
              rows: 4,
            ),
            _buildCardGroup(
              context,
              cardMaxWidth,
              titleWidth: 0,
              rows: 1,
              showTitle: false,
            ),
            const SizedBox(height: 120),
            const ShimmerLoader(
              width: 64,
              height: 64,
              shape: BoxShape.circle,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double width) {
    final theme = Theme.of(context);
    final isDesktop = ResponsiveWidget.isDesktop(context);

    return Container(
      height: 280,
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.35),
        borderRadius: isDesktop
            ? BorderRadius.circular(60)
            : const BorderRadius.only(
                bottomLeft: Radius.circular(70),
                bottomRight: Radius.circular(70),
              ),
      ),
      child: Column(
        children: [
          const Spacer(),
          const ShimmerLoader(
            width: 100,
            height: 100,
            shape: BoxShape.circle,
          ),
          const SizedBox(height: 12),
          ShimmerLoader(height: 16, width: 180, borderRadius: 8),
          const SizedBox(height: 6),
          ShimmerLoader(height: 14, width: 140, borderRadius: 8),
          const SizedBox(height: 6),
          ShimmerLoader(height: 14, width: 120, borderRadius: 8),
          const SizedBox(height: 12),
          ShimmerLoader(height: 32, width: 120, borderRadius: 16),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildCardGroup(
    BuildContext context,
    double maxWidth, {
    required double titleWidth,
    required int rows,
    bool showTitle = true,
    bool showSubtitle = false,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(
          color: theme.cardColor.withOpacity(0.3),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showTitle) ...[
                  ShimmerLoader(
                    width: titleWidth,
                    height: 14,
                    borderRadius: 6,
                  ),
                  const SizedBox(height: 8),
                ],
                for (int i = 0; i < rows; i++)
                  _buildOptionRow(context, showSubtitle: showSubtitle && i == 0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow(
    BuildContext context, {
    bool showSubtitle = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          const ShimmerLoader(
            width: 24,
            height: 24,
            shape: BoxShape.circle,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerLoader(
                  width: double.infinity,
                  height: 12,
                ),
                if (showSubtitle) ...[
                  const SizedBox(height: 6),
                  ShimmerLoader(
                    width: 80,
                    height: 10,
                    borderRadius: 6,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ShimmerLoader(
            width: 14,
            height: 14,
            borderRadius: 4,
          ),
        ],
      ),
    );
  }
}
