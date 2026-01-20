import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/pages/DisplayTrailer.dart';
import 'package:ott/app/pages/wallet%20page/BillingPage.dart';
import 'package:ott/app/pages/movie%20details%20page/component/actionButtonWidget.dart';
import 'package:ott/app/pages/watchlist%20page/playMoviePage.dart';
import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

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
  int selectedSeasonIndex = 0;

  @override
  void initState() {
    super.initState();
    Provider.of<SeriesProvider>(context, listen: false)
        .loadSeries(widget.seriesId);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;

    return Consumer<SeriesProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Center(
              child: Text(provider.error!,
                  style: TextStyle(color: theme.canvasColor)),
            ),
          );
        }

        final data = provider.data;
        if (data == null) {
          return const Scaffold(body: Center(child: Text("No data")));
        }

        final series = data.series;
        final seasons = data.seasons;
        final currentSeason = seasons[selectedSeasonIndex];
        final episodes = currentSeason.episodes;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            forceMaterialTransparency: true,
            title: ResponsiveWidget.isDesktop(context)
                ? const Text('')
                : Text(
                    series.title,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: theme.primaryColor,
                    ),
                  ),
            backgroundColor: Colors.transparent,
            centerTitle: true,
            elevation: 0,
          ),
          body: Stack(
            fit: StackFit.expand,
            children: [
              _buildBackground(series.posterUrlList.isNotEmpty
                  ? series.posterUrlList.first
                  : null),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.black.withOpacity(0.95),
                    ],
                  ),
                ),
              ),
              ResponsiveWidget.isDesktop(context)
                  ? Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildLeftPane(
                            context,
                            theme,
                            series,
                            seasons,
                            currentSeason,
                            episodes,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Container(
                                  height: 400,
                                  child: TrailerPage(
                                    trailerUrl: series.trailerURL,
                                    isTrailerUrl: true,
                                    content: widget.content,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildMobileView(
                      context,
                      theme,
                      series,
                      seasons,
                      currentSeason,
                      episodes,
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeftPane(
    BuildContext context,
    ThemeData theme,
    dynamic series,
    List seasons,
    dynamic currentSeason,
    List episodes,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: _buildBody(
        context,
        theme,
        series,
        seasons,
        currentSeason,
        episodes,
        showTrailerButton: false,
      ),
    );
  }

  Widget _buildMobileView(
    BuildContext context,
    ThemeData theme,
    dynamic series,
    List seasons,
    dynamic currentSeason,
    List episodes,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 80),
          _buildBody(
            context,
            theme,
            series,
            seasons,
            currentSeason,
            episodes,
            showTrailerButton: true,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ThemeData theme,
    dynamic series,
    List seasons,
    dynamic currentSeason,
    List episodes, {
    required bool showTrailerButton,
  }) {
    final lang = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        ResponsiveWidget.isDesktop(context)
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: 6,
                        bottom: 6,
                      ),
                      child: Text(
                        series.title ?? "",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: theme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : SizedBox(),
        const SizedBox(height: 16),

        // Posters
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: series.posterUrlList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 8,
                child: Image.network(
                  series.posterUrlList[i],
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (showTrailerButton)
              ActionButtonWidget(
                label: lang.watchTrailer,
                icon: Icons.play_circle_fill,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TrailerPage(
                        trailerUrl: series.trailerURL,
                        isTrailerUrl: true,
                        content: widget.content,
                      ),
                    ),
                  );
                },
              ),
            ActionButtonWidget(
              label: '${lang.rent} ₹${series.price}',
              icon: Icons.movie,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => _buildConfirmationBox(context, series),
                );
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        // About
        Text(
          series.description,
          maxLines: ResponsiveWidget.isMobile(context) ? 3 : 5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),

        const SizedBox(height: 16),

        // Seasons
        SizedBox(
          height: 35,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: seasons.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isSelected = index == selectedSeasonIndex;
              return GestureDetector(
                onTap: () => setState(() => selectedSeasonIndex = index),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.primaryColor
                        : theme.cardColor.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    "Season ${seasons[index].season.seasonNumber}",
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.canvasColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        Text(
          currentSeason.season.description,
          maxLines: ResponsiveWidget.isMobile(context) ? 3 : 5,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withOpacity(0.7)),
        ),

        const SizedBox(height: 12),

        episodes.isEmpty
            ? SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    "Episodes will be available soon.",
                    style: TextStyle(color: Colors.white.withOpacity(0.7)),
                  ),
                ),
              )
            : SizedBox(
                height: 200,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: episodes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (context, index) {
                    final ep = episodes[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayMediaPage(
                              title: ep.title,
                              mediaId: ep.id,
                              videoUrl: ep.videoUrl,
                              content:
                                  widget.content, // parent Content if needed
                            ),
                          ),
                        );
                      },
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 16 / 8,
                                child: Image.network(ep.posterUrl,
                                    fit: BoxFit.cover),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "E${ep.episodeNumber} • ${ep.title}",
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
        const SizedBox(height: 20),

        _buildMetaTable(theme, series),
      ],
    );
  }

  Widget _buildMetaTable(ThemeData theme, dynamic series) {
    TextStyle title = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    TextStyle value = const TextStyle(color: Colors.white70);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white24),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.white12, width: 0.5),
        ),
        children: [
          _row("Genres", series.genreList.join(', '), title, value),
          _row("Directors", series.directorList.join(', '), title, value),
          _row("Cast", series.castList.join(', '), title, value),
          _row(
              "Languages",
              widget.content.languageList!.map((e) => e.language).join(', '),
              title,
              value),
          _row("Rating", "${series.ratings} ⭐", title, value),
          _row("Price", "₹${series.price}", title, value),
        ],
      ),
    );
  }

  TableRow _row(String k, String v, TextStyle t, TextStyle c) {
    return TableRow(children: [
      Padding(
        padding: const EdgeInsets.all(10),
        child: Text("$k:", style: t),
      ),
      Padding(
        padding: const EdgeInsets.all(10),
        child: Text(v, style: c),
      ),
    ]);
  }

  Widget _buildBackground(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(imageUrl, fit: BoxFit.cover)
        : Container(color: Colors.black);
  }

  Widget _buildConfirmationBox(BuildContext context, dynamic series) {
    final theme = Provider.of<ThemeProvider>(context, listen: true).getTheme;
    final lang = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Center(
        child: Text(
          series.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: theme.primaryColor,
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${lang.price}: ₹${series.price}',
              style: TextStyle(color: theme.secondaryHeaderColor)),
          const SizedBox(height: 10),
          Text(
            'Do you want to rent this series?',
            style: TextStyle(color: theme.primaryColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: theme.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BillingPage(movie: widget.content),
              ),
            );
          },
          child: const Text("Continue"),
        ),
      ],
    );
  }
}
