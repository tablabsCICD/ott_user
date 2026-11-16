import 'package:flutter/material.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/app/core/utils/release_date_formatter.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/responsive_poster_image.dart';
import 'package:ott/app/widgets/shimmer%20loader/comming_soon_shimmer.dart';
import 'package:ott/app/widgets/filmytell_poster_image.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

class UpcomingPage extends StatefulWidget {
  const UpcomingPage({super.key});

  @override
  State<UpcomingPage> createState() => _UpcomingPageState();
}

class _UpcomingPageState extends State<UpcomingPage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = Provider.of<VideoProvider>(context, listen: false);
    await provider.upcomingContent();
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    if (ResponsiveWidget.isAndroidTv(context)) {
      return _buildAndroidTv(context, theme, lang);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          lang.upcoming,
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? ComingSoonShimmer()
          : Consumer<VideoProvider>(
              builder: (_, provider, __) {
                if (provider.upcomingContentList.isEmpty) {
                  return _emptyState(theme);
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.upcomingContentList.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: ResponsiveWidget.isMobile(context) ? 1 : 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 16 / 9, // 🔒 fixed
                  ),
                  itemBuilder: (_, index) {
                    Content item = provider.upcomingContentList[index];
                    return _upcomingCard(context, item);
                  },
                );
              },
            ),
    );
  }

  /// Android TV: in-tab page with a compact title and four 16:9 tiles per
  /// row (same data, cards and actions as the other layouts).
  Widget _buildAndroidTv(
    BuildContext context,
    ThemeData theme,
    AppLocalizations lang,
  ) {
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                TvDesign.pageGutter,
                14,
                TvDesign.pageGutter,
                8,
              ),
              child: Text(
                lang.upcoming,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TvDesign.pageTitle(theme),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const ComingSoonShimmer()
                  : Consumer<VideoProvider>(
                      builder: (_, provider, __) {
                        final items = provider.upcomingContentList;
                        if (items.isEmpty) return _emptyState(theme);

                        return GridView.builder(
                          padding: const EdgeInsets.fromLTRB(
                            TvDesign.pageGutter,
                            10,
                            TvDesign.pageGutter,
                            TvDesign.pageGutter,
                          ),
                          itemCount: items.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 14,
                            childAspectRatio: TvDesign.imageAspectRatio,
                          ),
                          itemBuilder: (_, index) => _upcomingCard(
                            context,
                            items[index],
                            autofocus: index == 0,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(Content movie) {
    if (movie.id == null || movie.type == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => /* movie.isFeatured == true
            ? TrailerPage(
                trailerUrl: movie.trailerUrl ?? "",
                isTrailerUrl: true,
                content: movie)
            :  */
                ContentType.isMovieLike(movie.type)
                    ? MovieDetailsPage(
                        movieId: movie.id!,
                        contentType: movie.type,
                      )
                    : SeriesDetailsPage(seriesId: movie.id!, content: movie),
      ),
    );
  }

  // 🎬 Netflix-style upcoming card
  Widget _upcomingCard(
    BuildContext context,
    Content item, {
    bool autofocus = false,
  }) {
    final theme = Theme.of(context);
    // Android TV: compact type, badge and button for the 4-column grid.
    final isAndroidTv = ResponsiveWidget.isAndroidTv(context);
    final double radius = isAndroidTv ? TvDesign.cardRadius : 16;
    final double inset = isAndroidTv ? 10 : 12;

    void openDetails() => _openDetails(item);
    void notifyMe() {
      CustomToast.show(
        context,
        "You’ll be notified on release day",
        isSuccess: true,
      );
    }

    // `notifySelected`: the TV remote has the Notify Me button selected.
    Widget buildCard({bool notifySelected = false}) => ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              // 🎞 Poster
              Positioned.fill(
                child: FilmytellPosterImage(
                  posterUrl: item.posterUrlList?.first,
                  // Android TV: fill the 16:9 tile edge to edge.
                  fit: isAndroidTv ? BoxFit.cover : BoxFit.contain,
                  fallbackIconSize: 48,
                  fallbackIcon: Icons.movie,
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

              // 📄 Content
              Positioned(
                left: inset,
                right: inset,
                bottom: inset,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      item.title ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isAndroidTv ? 12.5 : 14,
                        fontWeight:
                            isAndroidTv ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),

                    SizedBox(height: isAndroidTv ? 2 : 4),

                    // Release date
                    Row(
                      children: [
                        Icon(Icons.date_range,
                            size: isAndroidTv ? 11 : 12, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          formatReleaseDate(item.releaseDate),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isAndroidTv ? 10.5 : 12,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isAndroidTv ? 6 : 8),

                    // 🔔 Notify Me button
                    OttTvActionHighlight(
                      selected: notifySelected,
                      borderRadius: 20,
                      child: SizedBox(
                        height: isAndroidTv ? 22 : 28,
                        child: ElevatedButton.icon(
                          onPressed: notifyMe,
                          icon: Icon(
                            Icons.notifications_active,
                            size: isAndroidTv ? 12 : 14,
                            color: Colors.white,
                          ),
                          label: Text(
                            AppLocalizations.of(context)!.notifyMe,
                            style: TextStyle(fontSize: isAndroidTv ? 10.5 : 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    if (ResponsiveWidget.isMobile(context)) {
      return InkWell(onTap: openDetails, child: buildCard());
    }

    // TV: Down from the card selects Notify Me (which the remote can't
    // otherwise reach), OK presses it, Up returns to the card.
    return OttTvActionCard(
      onTap: openDetails,
      onAction: notifyMe,
      actionDirection: TraversalDirection.down,
      borderRadius: radius,
      scale: isAndroidTv ? TvDesign.cardFocusScale : 1.04,
      semanticLabel: item.title,
      autofocus: autofocus,
      builder: (context, notifySelected) =>
          buildCard(notifySelected: notifySelected),
    );
  }

  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.upcoming_outlined,
              size: ResponsiveWidget.isAndroidTv(context) ? 48 : 80,
              color: theme.canvasColor.withOpacity(0.6)),
          const SizedBox(height: 12),
          Text(
            "No upcoming content",
            style: TextStyle(
              color: theme.canvasColor,
              fontSize: ResponsiveWidget.isAndroidTv(context) ? 13 : 16,
            ),
          ),
        ],
      ),
    );
  }
}
