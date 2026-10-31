import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/common/premium_content_card.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// Interactive category tabs and responsive floating content grid.
class ModernFloatingGridSection extends StatefulWidget {
  const ModernFloatingGridSection({
    super.key,
    required this.items,
    required this.onCategoryChanged,
    required this.onContentTap,
    required this.onPlayTrailer,
    this.selectedCategory = 'All',
  });

  final List<Content> items;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<Content> onContentTap;
  final ValueChanged<Content> onPlayTrailer;
  final String selectedCategory;

  @override
  State<ModernFloatingGridSection> createState() =>
      _ModernFloatingGridSectionState();
}

class _ModernFloatingGridSectionState extends State<ModernFloatingGridSection> {
  static const _categories = [
    'All',
    'Movies',
    'Web Series',
    'Short Films',
    'Mini Series',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final paddingHorizontal = isMobile ? 20.0 : 64.0;

    // Calculate grid columns dynamically
    final crossAxisCount = screenWidth > 1400
        ? 5
        : (screenWidth > 1100
            ? 4
            : (screenWidth > 768
                ? 3
                : 2));

    final displayItems = _filterItems(widget.items, widget.selectedCategory);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: 36,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title + Category Filter Pills
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Curated Streaming Library',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: isMobile ? 22 : 30,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Explore handpicked originals and top-rated regional cinema',
                      style: TextStyle(
                        color: colors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Horizontal Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = widget.selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (_) => widget.onCategoryChanged(cat),
                    selectedColor: colors.primaryAccent,
                    backgroundColor: colors.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : colors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: BorderSide(
                        color: isSelected
                            ? colors.primaryAccent
                            : colors.border,
                      ),
                    ),
                    elevation: isSelected ? 4 : 0,
                    shadowColor: colors.primaryAccent.withOpacity(0.4),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // Responsive Grid
          if (displayItems.isEmpty)
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: Text(
                  'No titles found in this category.',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isMobile ? 12 : 18,
                mainAxisSpacing: isMobile ? 16 : 24,
                childAspectRatio: 0.66,
              ),
              itemBuilder: (context, index) {
                final item = displayItems[index];
                return PremiumContentCard(
                  content: item,
                  width: double.infinity,
                  height: double.infinity,
                  onTap: () => widget.onContentTap(item),
                  onPlayTrailer: () => widget.onPlayTrailer(item),
                );
              },
            ),
        ],
      ),
    );
  }

  List<Content> _filterItems(List<Content> all, String category) {
    if (category == 'All') return all;
    if (category == 'Movies') {
      return all
          .where((i) => (i.type ?? '').toUpperCase() == 'MOVIE')
          .toList();
    }
    if (category == 'Web Series') {
      return all
          .where((i) => (i.type ?? '').toUpperCase() == 'SERIES')
          .toList();
    }
    if (category == 'Short Films') {
      return all
          .where((i) => (i.type ?? '').toUpperCase() == 'SHORT_FILM')
          .toList();
    }
    if (category == 'Mini Series') {
      return all
          .where((i) => (i.type ?? '').toUpperCase() == 'MINI SERIES')
          .toList();
    }
    return all;
  }
}
