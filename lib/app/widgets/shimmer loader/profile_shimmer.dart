import 'package:flutter/material.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class ProfileShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: [
            // 🔵 Profile Header Shimmer
            Container(
              height: 280,
              width: ResponsiveWidget.isMobile(context) ? double.infinity : 600,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: ResponsiveWidget.isDesktop(context)
                    ? BorderRadius.circular(60)
                    : const BorderRadius.only(
                        bottomLeft: Radius.circular(70),
                        bottomRight: Radius.circular(70),
                      ),
              ),
              child: Column(
                children: [
                  Spacer(),
                  // Profile Image Shimmer
                  Hero(
                    tag: 'profile',
                    child: ShimmerLoader(
                      height: 100,
                      width: 100,
                      borderRadius: 100,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User Name Placeholder
                  ShimmerLoader(height: 16, width: 180, borderRadius: 8),
                  const SizedBox(height: 6),
                  ShimmerLoader(height: 16, width: 120, borderRadius: 8),
                  const SizedBox(height: 6),
                  // User Email Placeholder
                  ShimmerLoader(height: 15, width: 120, borderRadius: 8),
                  const SizedBox(height: 35),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 🔲 Profile Options List Shimmer
            for (int i = 0; i < 8; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ShimmerLoader(
                  height: 100,
                  width: 600,
                  borderRadius: 10,
                ),
              ),

            const SizedBox(height: 250),

            // 🔘 Referred By Placeholder
            ShimmerLoader(height: 14, width: 150, borderRadius: 8),
          ],
        ),
      ),
    );
  }
}
