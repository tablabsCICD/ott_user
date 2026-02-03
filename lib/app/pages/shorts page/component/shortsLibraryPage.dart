import 'package:flutter/material.dart';
import 'package:ott/app/pages/shorts%20page/component/shortsSeriesPlayerPage.dart';
import 'package:ott/app/provider/shorts_provider.dart';
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
    context.read<ShortProvider>().fetchShorts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<ShortProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.shorts.isEmpty) {
          return const Center(child: CircularProgressIndicator());
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
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 9 / 16, // Enforced 9:16 ratio
            ),
            itemBuilder: (context, index) {
              final short = shorts[index];

              return GestureDetector(
                onTap: () async {
                  await context
                      .read<ShortProvider>()
                      .fetchShortDetail(short.id, 1);

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
                                short.likeCount.toString(),
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              )
                            ],
                          ))
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
}
