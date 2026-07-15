import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:ott/presentation/web_landing/widgets/content_carousel.dart';

class LatestContentSection extends StatelessWidget {
  const LatestContentSection({
    super.key,
    required this.items,
    required this.onContentTap,
    required this.onLoadMore,
    required this.isLoadingMore,
    required this.hasMore,
  });

  final List<Content> items;
  final ValueChanged<Content> onContentTap;
  final VoidCallback onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;

    return ContentCarousel(
      title: lang.latestContent,
      items: items,
      numbered: true,
      onContentTap: onContentTap,
      onLoadMore: onLoadMore,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
    );
  }
}
