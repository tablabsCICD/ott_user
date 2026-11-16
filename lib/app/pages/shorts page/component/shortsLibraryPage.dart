import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/shorts%20page/component/ShortsPlayerPage.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/content_share_sheet.dart';
import 'package:ott/app/widgets/filmytell_poster_image.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

class ShortsLibraryPage extends StatefulWidget {
  const ShortsLibraryPage({super.key, this.useParentScroll = false});

  final bool useParentScroll;

  @override
  State<ShortsLibraryPage> createState() => _ShortsLibraryPageState();
}

class _ShortsLibraryPageState extends State<ShortsLibraryPage> {
  @override
  void initState() {
    super.initState();
    _loadShortRows();
  }

  Future<void> _loadShortRows() async {
    await context.read<BookmarkProvider>().getUserBookmarkShort();

    // The persisted user is updated immediately after the language API succeeds.
    // Prefer it over a potentially stale in-memory UserProvider after navigation.
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    List<String> selectedLanguages =
        List<String>.from(user?.selectedLanguages ?? []);

    if (selectedLanguages.isEmpty && mounted) {
      selectedLanguages = List<String>.from(
        context.read<UserProvider>().userObject.selectedLanguages ?? [],
      );
    }

    if (selectedLanguages.isEmpty) {
      selectedLanguages = ["English"];
    }

    if (!mounted) return;
    await context
        .read<ShortProvider>()
        .fetchShortsByLanguages(selectedLanguages);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ShortProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.shortSections.isEmpty) {
          return Center(
              child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: theme.primaryColor,
              ),
            ],
          ));
        }

        if (provider.shortSections.isEmpty) {
          return Center(
            child: Column(
              children: [
                SizedBox(
                  height: ResponsiveWidget.isAndroidTv(context) ? 80 : 300,
                ),
                Text(
                  provider.errorMessage ?? "No Mini Series available",
                  style: TextStyle(
                    color: theme.canvasColor.withOpacity(0.6),
                  ),
                ),
                if (provider.errorMessage != null)
                  TextButton(
                    onPressed: _loadShortRows,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          );
        }

        final shortSections = provider.shortSections
            .where((section) => section.shorts.isNotEmpty)
            .toList();

        if (shortSections.isEmpty) {
          return Center(
            child: Column(
              children: [
                SizedBox(
                  height: ResponsiveWidget.isAndroidTv(context) ? 80 : 300,
                ),
                Text(
                  "No Mini Series available",
                  style: TextStyle(
                    color: theme.canvasColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        final useParentScroll = widget.useParentScroll;
        if (ResponsiveWidget.isAndroidTv(context)) {
          return _buildTvRows(context, shortSections, useParentScroll);
        }
        final cardWidth = ResponsiveWidget.isDesktop(context)
            ? 190.0
            : ResponsiveWidget.isTablet(context)
                ? 185.0
                : 175.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: ListView.builder(
            shrinkWrap: useParentScroll,
            primary: !useParentScroll,
            padding: EdgeInsets.zero,
            physics: useParentScroll
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: shortSections.length,
            itemBuilder: (context, sectionIndex) {
              final section = shortSections[sectionIndex];
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${section.language} - ${section.category}",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: ResponsiveWidget.isMobile(context) ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: theme.canvasColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    SizedBox(
                      height: cardWidth * (16 / 9),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: section.shorts.length,
                        itemBuilder: (context, index) {
                          final short = section.shorts[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: SizedBox(
                              width: cardWidth,
                              child: _shortCard(context, short),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _shortCard(BuildContext context, ShortModel short) {
    final theme = Theme.of(context);

    return OttTvFocus(
      borderRadius: 12,
      semanticLabel: 'Open ${short.title}',
      onTap: () => _openShort(context, short),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              short.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.55),
                    Colors.transparent,
                  ],
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                ),
              ),
            ),
            if (short.isTrending)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    "TRENDING",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    short.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "@${short.creatorName} · ${short.category}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    "₹ ${short.coinsPerPart} /part | ${(short.languageList.map((e) => e.language)).join(', ')}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.play_arrow_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        "${short.totalParts} Parts",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              bottom: 5,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.remove_red_eye,
                    color: Colors.white70,
                    size: 13,
                  ),
                  SizedBox(
                    width: 4,
                  ),
                  Text(
                    "${short.viewCount}",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                ],
              ),
            ),
            _optionButton(context, short),
          ],
        ),
      ),
    );
  }

  Widget _optionButton(BuildContext context, ShortModel short) {
    final theme = Theme.of(context);

    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bool isBookmarked =
        bookmarkProvider.isShortBookmarkedLocally(short.id ?? 0);
    final ValueNotifier<bool> isDialOpen = ValueNotifier(false);
    final TextEditingController countController = TextEditingController();

    return Positioned(
      top: 4,
      right: 4,
      child: SpeedDial(
        openCloseDial: isDialOpen,
        onPress: () => isDialOpen.value = !isDialOpen.value,
        icon: Icons.more_vert,
        activeIcon: Icons.close,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.3,
        elevation: 2,
        direction: SpeedDialDirection.down,
        buttonSize: const Size(30, 30),
        childrenButtonSize: const Size(30, 35),
        spacing: 2,
        children: [
          SpeedDialChild(
            label: isBookmarked ? "Remove Bookmark" : "Bookmark",
            labelBackgroundColor: theme.cardColor,
            labelStyle: TextStyle(
              color: theme.canvasColor,
              fontSize: 10,
            ),
            child: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              size: 14,
              color: Colors.white,
            ),
            backgroundColor: theme.primaryColor,
            onTap: () async {
              await _toggleShortBookmark(context, bookmarkProvider, short);

              isDialOpen.value = false;
            },
          ),

          /// 🔗 Share
          SpeedDialChild(
            label: "Share",
            labelBackgroundColor: theme.cardColor,
            labelStyle: TextStyle(
              color: theme.canvasColor,
              fontSize: 10,
            ),
            child: const Icon(Icons.share, size: 14, color: Colors.white),
            backgroundColor: theme.primaryColor,
            onTap: () {
              isDialOpen.value = false;
              _shareShortContent(context, short);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _openShort(BuildContext context, ShortModel short) async {
    final user = await LocalSharePreferences.localSharePreferences.getUser();
    await context.read<ShortProvider>().fetchShortDetail(short.id, user?.id ?? 1);

    if (mounted && context.read<ShortProvider>().shortDetail != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ShortsPlayerPage(
            short: context.read<ShortProvider>().shortDetail!,
          ),
        ),
      );
    }
  }

  Future<void> _toggleShortBookmark(
    BuildContext context,
    BookmarkProvider bookmarkProvider,
    ShortModel short,
  ) async {
    final bool wasBookmarked =
        bookmarkProvider.isShortBookmarkedLocally(short.id ?? 0);

    await bookmarkProvider.toggleBookmarkShort(short);

    CustomToast.show(
      context,
      wasBookmarked
          ? "${short.title} removed from bookmarks"
          : "${short.title} added to bookmarks",
      isSuccess: true,
    );
  }

  // ---------------- ANDROID TV ----------------

  /// Android TV: compact rows of 16:9 cards (the portrait 9:16 cards were
  /// taller than half the TV screen).
  Widget _buildTvRows(
    BuildContext context,
    List<ShortsSectionData> shortSections,
    bool useParentScroll,
  ) {
    const cardWidth = 200.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: ListView.builder(
        shrinkWrap: useParentScroll,
        primary: !useParentScroll,
        padding: EdgeInsets.zero,
        physics: useParentScroll
            ? const NeverScrollableScrollPhysics()
            : const BouncingScrollPhysics(),
        itemCount: shortSections.length,
        itemBuilder: (context, sectionIndex) {
          final section = shortSections[sectionIndex];
          final shorts = section.shorts;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TvSectionHeader("${section.language} - ${section.category}"),
                SizedBox(
                  // 16:9 artwork + three text lines, plus room for the
                  // focus lift above and the shadow below.
                  height: 202,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(6, 10, 6, 14),
                    itemCount: shorts.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: SizedBox(
                          width: cardWidth,
                          child: _tvShortCard(context, shorts[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Android TV card. The card is one focus stop (OK opens the mini series);
  /// Up selects the options button drawn on the artwork, OK on it opens the
  /// same Bookmark / Share actions as the mobile speed dial.
  Widget _tvShortCard(BuildContext context, ShortModel short) {
    final theme = Theme.of(context);
    final languages = short.languageList.map((e) => e.language).join(', ');

    return OttTvActionCard(
      borderRadius: TvDesign.cardRadius,
      scale: TvDesign.cardFocusScale,
      semanticLabel: 'Open ${short.title}',
      actionDirection: TraversalDirection.up,
      onTap: () => _openShort(context, short),
      onAction: () => _showTvShortOptions(context, short),
      builder: (context, actionSelected) => ClipRRect(
        borderRadius: BorderRadius.circular(TvDesign.cardRadius),
        child: ColoredBox(
          color: theme.cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: TvDesign.imageAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FilmytellPosterImage(
                      posterUrl: short.posterUrl,
                      fit: BoxFit.cover,
                      fallbackIconSize: 28,
                    ),
                    if (short.isTrending)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "TRENDING",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: OttTvActionHighlight(
                        selected: actionSelected,
                        borderRadius: 14,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: actionSelected
                                ? Colors.transparent
                                : Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_vert,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 5,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.remove_red_eye,
                            color: Colors.white70,
                            size: 12,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            "${short.viewCount}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(9, 6, 9, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      short.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "@${short.creatorName} · ${short.category}",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.canvasColor.withOpacity(0.65),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      "₹ ${short.coinsPerPart} /part | $languages · ${short.totalParts} Parts",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.canvasColor.withOpacity(0.65),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Android TV replacement for the speed dial (unreachable with a remote):
  /// the same Bookmark and Share actions as remote-friendly buttons.
  Future<void> _showTvShortOptions(BuildContext context, ShortModel short) {
    final theme = Theme.of(context);
    final isBookmarked =
        context.read<BookmarkProvider>().isShortBookmarkedLocally(short.id);

    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TvDesign.panelRadius),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  short.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TvDesign.sectionTitle(theme),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  autofocus: true,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _toggleShortBookmark(
                      context,
                      context.read<BookmarkProvider>(),
                      short,
                    );
                  },
                  icon: Icon(
                    isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    size: 18,
                  ),
                  label: Text(isBookmarked ? "Remove Bookmark" : "Bookmark"),
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 36),
                  ),
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _shareShortContent(context, short);
                  },
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text("Share"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareShortContent(BuildContext context, ShortModel short) {
    return showContentShareSheet(
      context,
      short.toShareContent(),
      contentType: DeepLinkContentType.short,
      unavailableMessage: "Mini series details are not available yet",
    );
  }
}
