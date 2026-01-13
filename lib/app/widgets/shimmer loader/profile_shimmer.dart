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
              width: ResponsiveWidget.isMobile(context) ? double.infinity : 400,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(70),
                  bottomRight: Radius.circular(70),
                ),
              ),
              child: Column(
                children: [
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
                padding:
                    const EdgeInsets.symmetric(vertical: 5.0, horizontal: 16),
                child: ListTile(
                  leading: ShimmerLoader(
                    height: 50,
                    width: 50,
                    borderRadius: 50,
                  ),
                  title: ShimmerLoader(
                    height: 10,
                    width: 30,
                    borderRadius: 10,
                  ),
                  subtitle: ShimmerLoader(
                    height: 10,
                    width: 20,
                    borderRadius: 10,
                  ),
                  trailing: ShimmerLoader(
                    height: 20,
                    width: 20,
                    borderRadius: 50,
                  ),
                ),
                // ShimmerLoader(
                //     height: 50,
                //     width: ResponsiveWidget.isDesktop(context)
                //         ? 600
                //         : double.infinity,
                //     borderRadius: 10),
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
