import 'package:flutter/material.dart';
import 'package:ott/app/pages/watchlist%20page/component/DisplayTrailer.dart';
import 'package:ott/app/pages/wallet%20page/SeriesBillingPage.dart';
import 'package:ott/app/pages/watchlist%20page/component/playMoviePage.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../provider/playMediaProvider.dart';

class SeriesDetailsPage extends StatefulWidget {
  final int seriesId;
  final Content content;

  const SeriesDetailsPage({
    super.key,
    required this.seriesId,
    required this.content,
  });

  @override
  State<SeriesDetailsPage> createState() => _SeriesDetailsPageState();
}

class _SeriesDetailsPageState extends State<SeriesDetailsPage> {
  int _selectedSeasonIndex = 0;
  final TrailerPreviewController _trailerController =
      TrailerPreviewController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SeriesProvider>().fetchSeriesDetails(widget.seriesId);
      context.read<PlayMediaProvider>().loadLocalResumes();
    });
  }

  @override
  void dispose() {
    _trailerController.pause?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().getTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<SeriesProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          if (provider.error != null) {
            return Center(child: Text(provider.error!));
          }

          SeriesEntity? series = provider.series;
          if (series == null) return const SizedBox();

          List<SeasonEntity> seasons = series.seasons;
          if (_selectedSeasonIndex >= seasons.length) {
            _selectedSeasonIndex = 0;
          }

          SeasonEntity season = seasons[_selectedSeasonIndex];

          return CustomScrollView(
            slivers: [
              _buildHero(series, theme),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveWidget.isDesktop(context) ? 64 : 16,
                    vertical: 1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleBlock(series, theme),
                      const SizedBox(height: 20),
                      _buildSeasonSelector(seasons, theme),
                      const SizedBox(height: 20),
                      _buildSeasonInfo(context, season, theme),
                      const SizedBox(height: 16),
                      ...season.episodes
                          .map((e) => _episodeTile(context, season, e, theme)),
                      Divider(),
                      const SizedBox(height: 26),
                      _buildDetailsSection(context, widget.content, theme),
                      const SizedBox(height: 32),
                      _buildGallery(widget.content),
                      const SizedBox(height: 60),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------- HERO ----------------

  SliverAppBar _buildHero(series, ThemeData theme) {
    final bool isMobile = ResponsiveWidget.isMobile(context);
    final bool isTablet = ResponsiveWidget.isTablet(context);

    return SliverAppBar(
      pinned: true,
      expandedHeight: isMobile
          ? 250
          : isTablet
              ? 420
              : 560,
      forceMaterialTransparency: true,
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            /// 🎬 Background Poster
            Image.network(
              series.posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),

            /// 🌗 Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black87,
                    Colors.black87,
                    Colors.black,
                  ],
                ),
              ),
            ),

            /// ▶ Trailer Preview (Responsive)
            if (isMobile)
              _buildMobileTrailer()
            else
              _buildDesktopTabletTrailer(),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTrailer() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 12,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: TrailerPreview(
              trailerUrl: widget.content.trailerUrl,
              content: widget.content,
              controller: _trailerController,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopTabletTrailer() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Container(
        height: ResponsiveWidget.isTablet(context) ? 240 : 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.grey.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: TrailerPreview(
              trailerUrl: widget.content.trailerUrl,
              content: widget.content,
              controller: _trailerController,
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- TITLE BLOCK ----------------

  Widget _buildTitleBlock(series, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          series.title,
          style: TextStyle(
            fontSize: ResponsiveWidget.isDesktop(context) ? 32 : 24,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            StarRatingWidget(
              rating: double.parse(
                widget.content.ratings!.toStringAsFixed(2),
              ),
            ),
            Text(
              " (${widget.content.ratingCount ?? 0})",
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: theme.canvasColor.withOpacity(0.7), height: 1.4),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          series.description,
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
          style:
              TextStyle(color: theme.canvasColor.withOpacity(0.7), height: 1.4),
        ),
      ],
    );
  }

  // ---------------- SEASON SELECTOR ----------------

  Widget _buildSeasonSelector(List seasons, ThemeData theme) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: seasons.length,
        itemBuilder: (context, i) {
          final selected = i == _selectedSeasonIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSeasonIndex = i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? theme.primaryColor : theme.cardColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                "Season ${seasons[i].seasonNumber}",
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : theme.canvasColor.withOpacity(0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------- SEASON INFO ----------------

  Widget _buildSeasonInfo(BuildContext context, season, ThemeData theme) {
    final hasPurchasedEpisode =
        season.episodes.any((EpisodeEntity ep) => ep.isPurchased);
    final canPurchaseSeason = !season.isSeasonPurchased && !hasPurchasedEpisode;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Season ${season.seasonNumber}: ${season.title}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.canvasColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                season.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.canvasColor.withOpacity(0.7)),
              ),
              const SizedBox(height: 6),
              !season.isSeasonPurchased && canPurchaseSeason
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            disabledBackgroundColor:
                                theme.canvasColor.withOpacity(0.2),
                            disabledForegroundColor:
                                theme.canvasColor.withOpacity(0.6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () async {
                            _trailerController.pause?.call();
                            final result = await Navigator.push<bool>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => SeriesBillingPage(
                                  seriesId: widget.seriesId,
                                  seasonId: season.seasonId,
                                  amount: season.price.toDouble(),
                                  isSeason: true,
                                ),
                              ),
                            );

                            if (result == true && mounted) {
                              CustomToast.show(
                                context,
                                "Season unlocked! Enjoy watching 🎬",
                                isSuccess: true,
                              );
                            }
                          },
                          child: Text(
                            "Rent complete Season ₹${season.price}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const SizedBox()
              //: SizedBox(),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- EPISODE TILE ----------------

  Widget _episodeTile(
    BuildContext context,
    SeasonEntity season,
    EpisodeEntity ep,
    ThemeData theme,
  ) {
    final canPlay = season.isSeasonPurchased || ep.isPurchased || ep.isFree;
    final resumeSeconds = context.watch<PlayMediaProvider>().getLocalResume(
          contentId: widget.content.id!,
          seasonId: season.seasonId,
          episodeId: ep.episodeId,
        );

    final progress = ep.runtime > 0
        ? (resumeSeconds / (ep.runtime * 60)).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: () async {
        if (!canPlay) return;

        _trailerController.pause?.call();
        final shouldRefresh = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PlayMediaPage(
              videoUrl: ep.videoUrl ?? "",
              content: widget.content,
              seasonIndex: season.seasonId,
              episodeIndex: ep.episodeId,
              seasons: [season],
            ),
          ),
        );

        if (shouldRefresh == true && context.mounted) {
          context
              .read<DashboardProvider>()
              .getContinueWatchedMovieList("SERIES");
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            /// ================= MAIN CONTENT =================
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// 🎬 POSTER
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.network(
                          ep.posterUrl,
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 120,
                            height: 80,
                            color: Colors.grey.shade800,
                            child: const Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 30,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.play_circle_fill,
                          color: Colors.white70,
                          size: 28,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  /// 📄 DETAILS
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ep.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: theme.canvasColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Ep. ${ep.episodeNumber} • ${ep.runtime} min",
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.canvasColor.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          ep.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.canvasColor.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔐 PRICE BUTTON (if locked)
                  if (!canPlay)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          _trailerController.pause?.call();
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SeriesBillingPage(
                                seriesId: widget.seriesId,
                                episodeId: ep.episodeId,
                                amount: ep.price.toDouble(),
                                isSeason: false,
                              ),
                            ),
                          );

                          if (result == true && mounted) {
                            CustomToast.show(
                              context,
                              "Episode unlocked! Enjoy watching 🎬",
                              isSuccess: true,
                            );
                          }
                        },
                        child: Text(
                          "₹${ep.price}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            /// ================= WATCH PROGRESS =================
            if (progress > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: Colors.grey.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(
      BuildContext context, Content movie, ThemeData theme) {
    final lang = AppLocalizations.of(context)!;
    TextStyle titleStyle = TextStyle(
      color: theme.canvasColor,
      fontWeight: FontWeight.bold,
    );
    TextStyle contentStyle = TextStyle(
      color: theme.canvasColor.withOpacity(0.7),
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: theme.canvasColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        border: TableBorder.symmetric(
          inside:
              BorderSide(color: theme.canvasColor.withOpacity(0.3), width: 0.5),
        ),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          _buildTableRow(
              lang.director,
              (movie.directorList != null && movie.directorList!.isNotEmpty)
                  ? movie.directorList!.first
                  : 'Unknown',
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.cast,
              (movie.castList != null && movie.castList!.isNotEmpty)
                  ? movie.castList!.join(', ')
                  : 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.genres,
              (movie.genreList != null && movie.genreList!.isNotEmpty)
                  ? movie.genreList!.join(', ')
                  : 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(lang.runtime, "${movie.runtime ?? 0} min", titleStyle,
              contentStyle),
          _buildTableRow(lang.price, movie.price?.toString() ?? 'N/A',
              titleStyle, contentStyle),
          _buildTableRow(
              lang.rentDuration,
              movie.rentlDuration?.toString() ?? 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.mediaHouse,
              movie.mediaHouseName?.toString() ?? 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(lang.releaseDate, movie.releaseDate ?? 'N/A',
              titleStyle, contentStyle),
          _buildTableRow(
              lang.languages,
              (movie.languageList!.map((e) => e.language)).join(', '),
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.rating,
              '${double.parse(
                (movie.ratings ?? 0.0).toStringAsFixed(1),
              )} ⭐',
              titleStyle,
              contentStyle),
          _buildTableRow(lang.ageRating, movie.ageRating ?? 'N/A', titleStyle,
              contentStyle),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String title, String content, TextStyle titleStyle,
      TextStyle contentStyle) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text('$title:', style: titleStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Text(content, style: contentStyle),
        ),
      ],
    );
  }

  // ---------------- GALLERY ----------------

  Widget _buildGallery(Content content) {
    final theme = Theme.of(context);
    // Using poster as placeholder images
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (content.posterUrlList != null &&
            content.posterUrlList!.isNotEmpty) ...[
          Text(
            "Gallery",
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: content.posterUrlList!.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    content.posterUrlList![index],
                    width: 320,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
