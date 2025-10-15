import 'package:flutter/material.dart';
import 'package:ott/app/widgets/shimmer%20loader/shimmer_loader.dart';

class DownloadShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 4, // Simulating multiple shimmer items
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // 🎬 Movie Poster Placeholder
              ShimmerLoader(width: 60, height: 60, borderRadius: 8),
              SizedBox(width: 6),
              // 📝 Movie Details Placeholder
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerLoader(
                        width: double.infinity,
                        height: 20), // Title Placeholder
                    SizedBox(height: 6),
                    ShimmerLoader(width: 100, height: 16), // Size Placeholder
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
