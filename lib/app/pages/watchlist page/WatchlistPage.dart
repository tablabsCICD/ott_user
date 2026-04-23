import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ott/app/pages/watchlist%20page/component/playMoviePage.dart';
import 'package:ott/app/provider/offline_download_provider.dart';
import 'package:ott/app/provider/purchaseContentProvider.dart';
import 'package:ott/app/widgets/shimmer%20loader/comming_soon_shimmer.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

enum WatchlistFilter { available, gifted, expired, downloaded }

class WatchlistPage extends StatefulWidget {
  const WatchlistPage({
    super.key,
    this.initialFilter = WatchlistFilter.available,
  });

  final WatchlistFilter initialFilter;

  @override
  State<WatchlistPage> createState() => _WatchlistPageState();
}

class _WatchlistPageState extends State<WatchlistPage> {
  bool isLoading = true;
  bool isOffline = false;
  late WatchlistFilter selectedFilter;

  @override
  void initState() {
    super.initState();
    selectedFilter = widget.initialFilter;
    _load();
  }

  Future<void> _load() async {
    final purchaseProvider =
        Provider.of<PurchaseContentProvider>(context, listen: false);
    final offlineProvider =
        Provider.of<OfflineDownloadProvider>(context, listen: false);
    final connectivityResults = await Connectivity().checkConnectivity();
    isOffline = !connectivityResults.any(
      (result) => result != ConnectivityResult.none,
    );
    await offlineProvider.loadDownloadedContents();
    await _fetchWatchlistContent(purchaseProvider, selectedFilter);
    if (mounted) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _onFilterSelected(WatchlistFilter filter) async {
    if (selectedFilter == filter) return;

    setState(() {
      selectedFilter = filter;
      isLoading = true;
    });

    final purchaseProvider =
        Provider.of<PurchaseContentProvider>(context, listen: false);
    await _fetchWatchlistContent(purchaseProvider, filter);

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  Future<void> _fetchWatchlistContent(
    PurchaseContentProvider purchaseProvider,
    WatchlistFilter filter,
  ) {
    final isGifted = filter == WatchlistFilter.gifted;
    final isExpired = filter == WatchlistFilter.expired;

    return purchaseProvider.getPurchaseContent(
      isGifted: isGifted,
      isExpired: isExpired,
    );
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
      body: Column(
        children: [
          _segmentedToggle(theme),
          Expanded(
            child: isLoading
                ? const ComingSoonShimmer(
                    showSegmentedToggle: false,
                    showActionButton: false,
                  )
                : Consumer2<PurchaseContentProvider, OfflineDownloadProvider>(
                    builder: (_, purchaseProvider, offlineProvider, __) {
                      final items = _buildEntries(
                        purchaseProvider: purchaseProvider,
                        offlineProvider: offlineProvider,
                      );

                      if (items.isEmpty) {
                        return _emptyState(theme, showSegmentedToggle: false);
                      }

                      return GridView.builder(
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 🔁 Segmented Toggle
  Widget _segmentedToggle(ThemeData theme) {
    final items = <({WatchlistFilter value, String label})>[
      (value: WatchlistFilter.available, label: "Available"),
      (value: WatchlistFilter.downloaded, label: "Downloaded"),
      (value: WatchlistFilter.gifted, label: "Gifted"),
      (value: WatchlistFilter.expired, label: "Expired"),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 35,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 7),
          itemBuilder: (_, index) {
            final item = items[index];
            return _filterChip(
              theme,
              item.value,
              item.label,
            );
          },
        ),
      ),
    );
  }

  Widget _filterChip(
    ThemeData theme,
    WatchlistFilter value,
    String label,
  ) {
    final selected = selectedFilter == value;

    return GestureDetector(
      onTap: () => _onFilterSelected(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),

          // ✅ Selected state (like your image)
          color: selected ? theme.primaryColor : Colors.transparent,

          border: Border.all(
            color: selected ? theme.primaryColor : Colors.grey.shade400,
          ),

          boxShadow: selected
              ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : theme.primaryColor,
          ),
        ),
      ),
    );
  }

  List<_WatchlistEntry> _buildEntries({
    required PurchaseContentProvider purchaseProvider,
    required OfflineDownloadProvider offlineProvider,
  }) {
    final entriesById = <int, _WatchlistEntry>{};

    for (final userContent in purchaseProvider.userContentList) {
      final movie = userContent.movie;
      final movieId = movie?.id;
      if (movie == null || movieId == null) continue;

      entriesById[movieId] = _WatchlistEntry(
        movie: movie,
        isActive: userContent.active ?? false,
        isGifted: userContent.isGifted ?? false,
        isDownloaded: offlineProvider.isDownloaded(movieId),
      );
    }

    if (selectedFilter == WatchlistFilter.downloaded) {
      for (final movie in offlineProvider.downloadedContents) {
        final movieId = movie.id;
        if (movieId == null) continue;

        entriesById[movieId] = _WatchlistEntry(
          movie: movie,
          isActive: true,
          isGifted: entriesById[movieId]?.isGifted ?? false,
          isDownloaded: true,
        );
      }
    }

    return entriesById.values.where((entry) {
      switch (selectedFilter) {
        case WatchlistFilter.available:
          return !(isOffline && entry.isDownloaded);
        case WatchlistFilter.downloaded:
          return entry.isDownloaded;
        case WatchlistFilter.gifted:
          return true;
        case WatchlistFilter.expired:
          return true;
      }
    }).toList();
  }

  Widget _netflixCard(BuildContext context, _WatchlistEntry content) {
    final theme = Theme.of(context);
    final item = content.movie;

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
              child: _posterBackground(item),
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
            if (content.isDownloaded)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.download_done_rounded,
                          color: Colors.white, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Offline',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _posterBackground(Content item) {
    final posterUrl =
        item.posterUrlList?.isNotEmpty == true ? item.posterUrlList!.first : '';
    if (posterUrl.isEmpty) {
      return _offlinePosterFallback(item);
    }

    return Image.network(
      posterUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _offlinePosterFallback(item),
    );
  }

  Widget _offlinePosterFallback(Content item) {
    return Container(
      color: Colors.black26,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.movie_creation_outlined,
              color: Colors.white70, size: 42),
          const SizedBox(height: 10),
          Text(
            item.title ?? 'Movie',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(ThemeData theme, {bool showSegmentedToggle = true}) {
    final emptyTitle = selectedFilter == WatchlistFilter.downloaded
        ? "No downloaded content found"
        : "No content found";
    return Column(
      children: [
        if (showSegmentedToggle) _segmentedToggle(theme),
        const Spacer(),
        Icon(Icons.video_library_outlined,
            size: 80, color: theme.canvasColor.withOpacity(0.6)),
        const SizedBox(height: 12),
        Text(
          emptyTitle,
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

class _WatchlistEntry {
  const _WatchlistEntry({
    required this.movie,
    required this.isActive,
    required this.isGifted,
    required this.isDownloaded,
  });

  final Content movie;
  final bool isActive;
  final bool isGifted;
  final bool isDownloaded;

  bool get active => isActive;
}
