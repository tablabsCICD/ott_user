import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
                  height: 300,
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
                  height: 300,
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

    return GestureDetector(
      onTap: () async {
        final user =
            await LocalSharePreferences.localSharePreferences.getUser();
        await context
            .read<ShortProvider>()
            .fetchShortDetail(short.id, user?.id ?? 1);

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
      },
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

  Future<void> _shareShortContent(BuildContext context, ShortModel short) {
    return showContentShareSheet(
      context,
      short.toShareContent(),
      contentType: DeepLinkContentType.short,
      unavailableMessage: "Mini series details are not available yet",
    );
  }
}
