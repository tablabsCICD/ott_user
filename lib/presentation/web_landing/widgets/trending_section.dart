import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/widgets/content_carousel.dart';

class TrendingSection extends StatelessWidget {
  const TrendingSection({
    super.key,
    required this.items,
    required this.onContentTap,
  });

  final List<Content> items;
  final ValueChanged<Content> onContentTap;

  @override
  Widget build(BuildContext context) {
    return ContentCarousel(
      title: 'Trending Now',
      items: items,
      numbered: true,
      onContentTap: onContentTap,
    );
  }
}
