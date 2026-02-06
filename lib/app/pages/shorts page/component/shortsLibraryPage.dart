import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/shorts%20page/component/ShortsPlayerPage.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/shorts.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

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
    context.read<ShortProvider>().fetchShorts();
    context.read<BookmarkProvider>().getUserBookmarkShort();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ShortProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.shorts.isEmpty) {
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

        if (provider.shorts.isEmpty) {
          return Center(
            child: Text(
              "No short films available",
              style: TextStyle(
                color: theme.canvasColor.withOpacity(0.6),
              ),
            ),
          );
        }

        final shorts = provider.shorts;

        final useParentScroll = widget.useParentScroll;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: GridView.builder(
            shrinkWrap: useParentScroll,
            primary: !useParentScroll,
            physics: useParentScroll
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            itemCount: shorts.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: ResponsiveWidget.isDesktop(context)
                  ? 5
                  : ResponsiveWidget.isTablet(context)
                      ? 4
                      : 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 9 / 16, // Enforced 9:16 ratio
            ),
            itemBuilder: (context, index) {
              final short = shorts[index];

              return GestureDetector(
                onTap: () async {
                  final user = await LocalSharePreferences.localSharePreferences
                      .getUser();
                  await context
                      .read<ShortProvider>()
                      .fetchShortDetail(short.id, user?.id ?? 1);

                  if (mounted &&
                      context.read<ShortProvider>().shortDetail != null) {
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
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Poster
                      Image.network(
                        short.posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),

                      // Bottom gradient
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

                      // Trending badge
                      if (short.isTrending)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(8),
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

                      // Title & meta
                      Positioned(
                        left: 10,
                        right: 10,
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
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.play_arrow_outlined,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
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
            },
          ),
        );
      },
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
      top: 5,
      right: 5,
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
              _shareMovie(context, short);
            },
          ),
        ],
      ),
    );
  }

  void _shareMovie(BuildContext context, ShortModel short) async {
    final String shareText = '''
🎬 ${short.title ?? ''}

${short.description ?? ''}

▶️ Watch here:


📲 Download Filmytell App now!
'''
        .trim();

    if (kIsWeb) {
      // Flutter Web fallback → Copy to Clipboard
      await Clipboard.setData(ClipboardData(text: shareText));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Share text copied to clipboard"),
        ),
      );
    } else {
      // Android / iOS / Desktop
      await Share.share(
        shareText,
        subject: short.title ?? "",
      );
    }
  }
}
