import 'package:flutter/material.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class ComingSoonShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ResponsiveWidget.isMobile(context)
              ? 2
              : 5, // Adjust based on responsiveness
          mainAxisSpacing: 16.0,
          crossAxisSpacing: 16.0,
          childAspectRatio: 27 / 40,
        ),
        itemCount: 20, // Display shimmer for 6 items
        itemBuilder: (context, index) {
          return ShimmerLoader();
        },
      ),
    );
  }
}
