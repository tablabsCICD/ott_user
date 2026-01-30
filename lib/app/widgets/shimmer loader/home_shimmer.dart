import 'package:flutter/material.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class HomeShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: ResponsiveWidget.isDesktop(context) ? 70 : 120),
          _buildShimmerFilters(),
          SizedBox(height: 30),
          _buildShimmerMovieSection(),
          SizedBox(height: 10),
          _buildShimmerMovieSection(),
          SizedBox(height: 10),
          _buildShimmerMovieSection(),
        ],
      ),
    );
  }

  // 📌 Filter Buttons Placeholder
  Widget _buildShimmerFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: List.generate(4, (index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ShimmerLoader(
                width: 70, height: 30, borderRadius: 15), // Filter Button
          );
        }),
      ),
    );
  }

  // 📌 Movie Section Placeholder
  Widget _buildShimmerMovieSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ShimmerLoader(
            width: 180,
            height: 20,
          ), // Section Title Placeholder
        ),
        SizedBox(height: 20),
        SizedBox(
          height: 300,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 10,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ShimmerLoader(
                  width: 300,
                  height: 200,
                ), // Movie Card Placeholder
              );
            },
          ),
        ),
      ],
    );
  }
}
