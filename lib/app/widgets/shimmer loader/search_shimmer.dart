import 'package:flutter/material.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class SearchShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildMovieListShimmer(context)),
      ],
    );
  }

  // 📌 Movie List Placeholder
  Widget _buildMovieListShimmer(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: ResponsiveWidget.isDesktop(context) ? 500 : 550,
        crossAxisSpacing: 18,
        mainAxisSpacing: 5,
        childAspectRatio: 7 / 3,
      ),
      itemCount: 16, // Simulating multiple shimmer items
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Row(
            children: [
              // Movie Poster Placeholder
              ShimmerLoader(width: 100, height: 140, borderRadius: 8),
              SizedBox(width: 12),
              // Movie Details Placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoader(
                        width: double.infinity,
                        height: 20), // Title Placeholder
                    SizedBox(height: 6),
                    ShimmerLoader(
                        width: 150, height: 16), // Director Placeholder
                    SizedBox(height: 6),
                    ShimmerLoader(width: 200, height: 16), // Cast Placeholder
                    SizedBox(height: 6),
                    Row(
                      children: [
                        ShimmerLoader(
                            width: 50, height: 16), // Rating Placeholder
                        SizedBox(width: 10),
                        ShimmerLoader(
                            width: 80, height: 16), // Rating Count Placeholder
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
