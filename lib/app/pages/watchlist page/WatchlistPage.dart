import 'package:flutter/material.dart';
import 'package:ott/app/pages/watchlist%20page/playMoviePage.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/app/widgets/shimmer%20loader/comming_soon_shimmer.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum WatchlistFilter { available, gifted, expired }

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  bool isLoading = true;
  WatchlistFilter selectedFilter = WatchlistFilter.available;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider =
        Provider.of<PurchaseContentProvider>(context, listen: false);
    await provider.getPurchaseContent();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          lang.watchlist,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? ComingSoonShimmer()
          : Consumer<PurchaseContentProvider>(
              builder: (_, provider, __) {
                final items = provider.userContentList.where((e) {
                  final isActive = e.active ?? false;
                  final isGifted = e.isGifted ?? false;

                  switch (selectedFilter) {
                    case WatchlistFilter.available:
                      return isActive;
                    case WatchlistFilter.gifted:
                      return isGifted;
                    case WatchlistFilter.expired:
                      return !isActive;
                  }
                }).toList();

                if (items.isEmpty) {
                  return _emptyState(theme);
                }

                return Column(
                  children: [
                    _segmentedToggle(theme),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: items.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              ResponsiveWidget.isMobile(context) ? 1 : 3,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 16 / 9,
                        ),
                        itemBuilder: (_, i) => _netflixCard(context, items[i]),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  // 🔁 Segmented Toggle
  Widget _segmentedToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 40,
        width: ResponsiveWidget.isMobile(context) ? double.infinity : 520,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _segment(theme, WatchlistFilter.available, "Available"),
            _segment(theme, WatchlistFilter.gifted, "Gifted"),
            _segment(theme, WatchlistFilter.expired, "Expired"),
          ],
        ),
      ),
    );
  }

  Widget _segment(
    ThemeData theme,
    WatchlistFilter value,
    String label,
  ) {
    final selected = selectedFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: selected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : theme.canvasColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  // 🎬 Card
  Widget _netflixCard(BuildContext context, dynamic content) {
    final theme = Theme.of(context);
    final item = content.movie;
    if (item == null) return const SizedBox();

    return GestureDetector(
      onTap: content.active == true
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayMediaPage(
                    content: item,
                    seasons: null,
                    videoUrl: item.contentUrl ?? '',
                    seasonIndex: 0,
                    episodeIndex: 0,
                  ),
                ),
              );
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.network(
                item.posterUrlList?.first ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black26),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black54,
                      Colors.black87,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule,
                          size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        item.rentlDuration ?? 'NA',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ❌ Expired overlay
            if (content.active == false)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.55),
                  alignment: Alignment.center,
                  child: const Text(
                    "Expired",
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            // 🎁 Gifted badge
            if (content.isGifted == true)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Gifted',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Column(
      children: [
        _segmentedToggle(theme),
        const Spacer(),
        Icon(Icons.video_library_outlined,
            size: 80, color: theme.canvasColor.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text(
          "No content found",
          style: TextStyle(
            color: theme.canvasColor,
            fontSize: 16,
          ),
        ),
        const Spacer(),
      ],
    );
  }
}
