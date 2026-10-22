import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/playMediaProvider.dart';
import 'package:ott/app/pages/watchlist page/component/playMoviePage.dart';
import 'package:ott/app/pages/series details page/seriesdetailspage.dart';
import 'package:ott/app/widgets/show_toast.dart';

class IosContinueWatchBanner extends StatefulWidget {
  final List<Content> items;

  const IosContinueWatchBanner({
    super.key,
    required this.items,
  });

  @override
  State<IosContinueWatchBanner> createState() => _IosContinueWatchBannerState();
}

class _IosContinueWatchBannerState extends State<IosContinueWatchBanner> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _resumePlayback(BuildContext context, Content movie) async {
    if (movie.id == null) return;

    if (!ContentType.isMovieLike(movie.type)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SeriesDetailsPage(
            seriesId: movie.id ?? 0,
            content: movie,
          ),
        ),
      );
      return;
    }

    Content contentToPlay = movie;
    var contentUrl = contentToPlay.contentUrl;

    final localResumeSeconds = context.read<PlayMediaProvider>().getLocalResume(
          contentId: movie.id!,
          seasonId: movie.seasonId,
          episodeId: movie.episodeId,
        );
    final latestResumeSeconds = (movie.watchedSeconds ?? 0) > localResumeSeconds
        ? movie.watchedSeconds ?? 0
        : localResumeSeconds;

    if (contentUrl == null || contentUrl.trim().isEmpty) {
      final fetchedContent =
          await context.read<DashboardProvider>().getContentById(movie.id!);
      if (!mounted) return;

      if (fetchedContent != null) {
        if ((fetchedContent.watchedSeconds ?? 0) < latestResumeSeconds) {
          fetchedContent.watchedSeconds = latestResumeSeconds;
        }
        fetchedContent.watchedPercentage ??= movie.watchedPercentage;
        fetchedContent.seasonId ??= movie.seasonId;
        fetchedContent.episodeId ??= movie.episodeId;
        contentToPlay = fetchedContent;
        contentUrl = contentToPlay.contentUrl;
      }
    }

    if ((contentToPlay.watchedSeconds ?? 0) < latestResumeSeconds) {
      contentToPlay.watchedSeconds = latestResumeSeconds;
    }
    contentToPlay.watchedPercentage ??= movie.watchedPercentage;

    if (!mounted) return;
    if (contentUrl == null || contentUrl.trim().isEmpty) {
      CustomToast.show(this.context, "Video is not available",
          isSuccess: false);
      return;
    }

    Navigator.push(
      this.context,
      MaterialPageRoute(
        builder: (_) => PlayMediaPage(
          videoUrl: contentUrl!,
          content: contentToPlay,
          seasonIndex: contentToPlay.seasonId ?? 0,
          episodeIndex: contentToPlay.episodeId ?? 0,
          seasons: contentToPlay.type?.toLowerCase() == "series" ? [] : null,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      this.context.read<DashboardProvider>().getContinueWatchedMovieList(
            contentToPlay.type ?? "MOVIE",
            forceRefresh: true,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final items = widget.items;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = items[index];
              final posterUrl = item.posterUrlList?.isNotEmpty == true
                  ? item.posterUrlList!.first
                  : null;
              final watchedPercent =
                  (item.watchedPercentage ?? 0).clamp(0, 100);
              final genre = (item.genreList?.isNotEmpty == true)
                  ? item.genreList!.first
                  : 'Drama';

              return GestureDetector(
                onTap: () => _resumePlayback(context, item),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Artwork
                        if (posterUrl != null && posterUrl.isNotEmpty)
                          Image.network(
                            posterUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.centerRight,
                            errorBuilder: (_, __, ___) =>
                                Container(color: const Color(0xFF141414)),
                          )
                        else
                          Container(color: const Color(0xFF141414)),

                        // Left-to-right atmospheric gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.95),
                                Colors.black.withValues(alpha: 0.85),
                                Colors.black.withValues(alpha: 0.40),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 0.75, 1.0],
                            ),
                          ),
                        ),

                        // Bottom-to-top atmospheric gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.95),
                                Colors.black.withValues(alpha: 0.45),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.50, 1.0],
                            ),
                          ),
                        ),

                        // Text and controls content
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Continue Watching",
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                item.title ?? 'No Title',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "$watchedPercent% watched | $genre",
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Sleek Progress Indicator
                              SizedBox(
                                width: 150,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: watchedPercent / 100.0,
                                    minHeight: 3.5,
                                    backgroundColor: Colors.white24,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Resume Button Row
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.primaryColor,
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.primaryColor
                                              .withValues(alpha: 0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Resume",
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
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
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 10),

        // Page Indicator Dots
        if (items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              items.length > 6 ? 6 : items.length,
              (i) {
                final isActive = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? theme.primaryColor : Colors.grey.shade700,
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 14),
      ],
    );
  }
}
