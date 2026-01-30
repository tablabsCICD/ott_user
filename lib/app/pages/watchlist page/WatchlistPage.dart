import 'package:flutter/material.dart';
import 'package:ott/app/pages/watchlist%20page/playMoviePage.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/app/widgets/shimmer%20loader/comming_soon_shimmer.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({super.key});

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  bool isLoading = true;
  bool showExpired = false;

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
        centerTitle: true,
        title: Text(
          lang.watchlist,
          style: TextStyle(
            color: theme.canvasColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? ComingSoonShimmer()
          : Consumer<PurchaseContentProvider>(
              builder: (_, provider, __) {
                final items = provider.userContentList
                    .where((e) => showExpired ? !e.active! : e.active!)
                    .toList();

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
                          childAspectRatio: 16 / 9, // 🔒 fixed
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

  // 🔁 Netflix-style segmented control
  Widget _segmentedToggle(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        height: 40,
        width: ResponsiveWidget.isMobile(context) ? double.infinity : 400,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            _segment(theme, false, "Available"),
            _segment(theme, true, "Expired"),
          ],
        ),
      ),
    );
  }

  Widget _segment(ThemeData theme, bool value, String label) {
    final selected = showExpired == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => showExpired = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          decoration: BoxDecoration(
            color: selected ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : theme.canvasColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🎬 Netflix / Hotstar Card
  Widget _netflixCard(BuildContext context, dynamic content) {
    final theme = Theme.of(context);
    final item = content.movie;
    if (item == null) return const SizedBox();

    return GestureDetector(
      onTap: content.active
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlayMediaPage(
                    title: item.title ?? '',
                    mediaId: item.id ?? 0,
                    videoUrl: item.contentUrl ?? '',
                    content: item,
                  ),
                ),
              );
            }
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // 🎞 Poster
            Positioned.fill(
              child: Image.network(
                item.posterUrlList?.first ?? '',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black26),
              ),
            ),

            // 🌑 Gradient overlay
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

            // 📄 Title + Duration
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
            if (!content.active)
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
            Positioned(
              child: content.isGifted
                  ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text('Gifted'),
                    )
                  : SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _segmentedToggle(theme),
          Spacer(),
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
          Spacer(),
        ],
      ),
    );
  }
}
