import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/shorts%20page/component/shortsSeriesPlayerPage.dart';
import 'package:ott/app/provider/shorts_provider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

class ShortsLibraryPage extends StatefulWidget {
  const ShortsLibraryPage({super.key});

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
    var theme = Theme.of(context);
    final crossAxisCount = ResponsiveWidget.isDesktop(context)
        ? 5
        : ResponsiveWidget.isTablet(context)
            ? 4
            : 2;

    final mainAxisExtent = ResponsiveWidget.isDesktop(context) ||
            ResponsiveWidget.isTablet(context)
        ? 300.0
        : 250.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<ShortProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.shorts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.shorts.isEmpty) {
            return Center(
              child: Text(
                "No short films available",
                style: TextStyle(
                    color: theme.scaffoldBackgroundColor.withOpacity(0.7)),
              ),
            );
          }

          final shorts = provider.shorts;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              itemCount: shorts.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisExtent: mainAxisExtent,
                crossAxisSpacing: 12,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (_, index) {
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
                        // Poster Image
                        Image.network(
                          short.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                              Icons.broken_image,
                              color: Colors.grey),
                        ),

                        // Bottom Gradient for Text
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.2),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),

                        // Trending Badge (if any)
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

                        // Title + Meta
                        Positioned(
                          left: 10,
                          right: 10,
                          bottom: 10,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                short.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
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
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Play Button Overlay
                        const Positioned(
                          bottom: 8,
                          right: 8,
                          child: Icon(Icons.play_circle_fill,
                              color: Colors.white70, size: 28),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
