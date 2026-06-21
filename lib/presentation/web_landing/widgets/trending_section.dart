import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';
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
    final lang = AppLocalizations.of(context)!;

    return ContentCarousel(
      title: lang.trendingNow,
      items: items,
      numbered: true,
      onContentTap: onContentTap,
    );
  }
}
