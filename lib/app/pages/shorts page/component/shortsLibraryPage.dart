import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/shorts%20page/component/ShortsPlayerPage.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/content_share_sheet.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
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
    // Start loading after the first frame: getUserBookmarkShort() notifies
    // BookmarkProvider listeners synchronously, which is not allowed while
    // the parent Consumer<DashboardProvider> is still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadShortRows();
    });
  }

  Future<void> _loadShortRows() async {
    // Bookmarks are secondary: a failure here must not stop the mini series
    // rows from loading.
    try {
      await context.read<BookmarkProvider>().getUserBookmarkShort();
    } catch (error, stackTrace) {
      debugPrint('[MINI_SERIES_LIBRARY] Bookmark load failed: $error');
      debugPrintStack(stackTrace: stackTrace, maxFrames: 5);
    }
    if (!mounted) return;

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
    final lang = AppLocalizations.of(context)!;

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
                  height: 300,
                ),
                Text(
                  provider.errorMessage ?? lang.shortsNoMiniSeriesAvailable,
                  style: TextStyle(
                    color: theme.canvasColor.withOpacity(0.6),
                  ),
                ),
                if (provider.errorMessage != null)
                  TextButton(
                    onPressed: _loadShortRows,
                    child: Text(lang.retry),
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
                  height: 300,
                ),
                Text(
                  lang.shortsNoMiniSeriesAvailable,
                  style: TextStyle(
                    color: theme.canvasColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        }

        final useParentScroll = widget.useParentScroll;
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

  /// Mini Series card in the shared Filmytell card style (see MovieCard):
  /// bordered card, poster on top, details below, red price pill. Mini Series
  /// posters are portrait, so the poster keeps a portrait crop.
  Widget _shortCard(BuildContext context, ShortModel short) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final price = short.coinsPerPart == short.coinsPerPart.roundToDouble()
        ? short.coinsPerPart.toStringAsFixed(0)
        : short.coinsPerPart.toStringAsFixed(2);
    final languages = short.languageList.map((e) => e.language).join(', ');
    final meta = [
      if (short.creatorName.isNotEmpty) '@${short.creatorName}',
      if (short.category.isNotEmpty) short.category,
    ].join(' · ');

    Future<void> open() async {
      final user = await LocalSharePreferences.localSharePreferences.getUser();
      if (!mounted) return;
      await context
          .read<ShortProvider>()
          .fetchShortDetail(short.id, user?.id ?? 1);
      if (!mounted) return;
      final detail = context.read<ShortProvider>().shortDetail;
      if (detail != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ShortsPlayerPage(short: detail)),
        );
      }
    }

    return GestureDetector(
      onTap: open,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.brightness == Brightness.dark
                ? const Color(0xFF26262C)
                : Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(15)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: Colors.black,
                      child: Image.network(
                        short.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                    if (short.isTrending)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: _posterBadge(
                          text: lang.shortsTrending,
                          color: const Color(0xFFE50914),
                        ),
                      ),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: _posterBadge(
                        icon: Icons.play_arrow_rounded,
                        text: lang.shortsPartsCount(short.totalParts),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: _posterBadge(
                        icon: Icons.remove_red_eye,
                        text: '${short.viewCount}',
                      ),
                    ),
                    // Existing bookmark/share options menu (unchanged).
                    _optionButton(context, short),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    short.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: theme.canvasColor,
                      height: 1.15,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        color: theme.canvasColor.withValues(alpha: 0.7),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          languages,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: theme.canvasColor.withValues(alpha: 0.7),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Same red price pill as MovieCard.
                      Container(
                        padding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: const Color(0xFFE50914),
                        ),
                        child: Text(
                          lang.miniSeriesPricePerPart(price),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _posterBadge({required String text, IconData? icon, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: color ?? Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _optionButton(BuildContext context, ShortModel short) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

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
            label:
                isBookmarked ? lang.cardRemoveBookmark : lang.cardBookmark,
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
              final bool wasBookmarked =
                  bookmarkProvider.isShortBookmarkedLocally(short.id ?? 0);

              await bookmarkProvider.toggleBookmarkShort(short);

              CustomToast.show(
                context,
                wasBookmarked
                    ? lang.cardRemovedFromBookmarks(short.title)
                    : lang.cardAddedToBookmarks(short.title),
                isSuccess: true,
              );

              isDialOpen.value = false;
            },
          ),

          /// 🔗 Share
          SpeedDialChild(
            label: lang.cardShare,
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

  Future<void> _shareShortContent(BuildContext context, ShortModel short) {
    return showContentShareSheet(
      context,
      short.toShareContent(),
      contentType: DeepLinkContentType.short,
      unavailableMessage:
          AppLocalizations.of(context)!.shortsMiniSeriesDetailsUnavailable,
    );
  }
}
