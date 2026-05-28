import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/core/constant/api_constant.dart';
import 'package:ott/app/core/network/api_helper.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/widgets/content_share_sheet.dart';
import 'package:ott/app/pages/watchlist%20page/component/DisplayTrailer.dart';
import 'package:ott/app/pages/wallet%20page/MovieBillingPage.dart';
import 'package:ott/app/pages/wallet%20page/SeriesBillingPage.dart';
import 'package:ott/app/pages/watchlist%20page/component/playMoviePage.dart';
import 'package:ott/app/pages/movie%20details%20page/component/actionButtonWidget.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/series_provider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/cast_member.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../provider/playMediaProvider.dart';
import '../movie details page/component/displayStar.dart';
import '../movie details page/component/starRating.dart';

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
  final TrailerPreviewController _teaserController = TrailerPreviewController();
  final ApiHelper _apiHelper = ApiHelper();
  List<CastMember> _seasonCastList = [];
  bool _isLoadingSeasonCast = false;
  int? _loadedSeasonId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      _loadInitialData();
      context.read<PlayMediaProvider>().loadLocalResumes();
    });
  }

  @override
  void dispose() {
    _trailerController.pause?.call();
    _teaserController.pause?.call();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final provider = context.read<SeriesProvider>();
    await provider.fetchSeriesDetails(widget.seriesId);
    await context
        .read<VideoProvider>()
        .getRatingReview(widget.content.id ?? widget.seriesId);

    if (!mounted) return;

    final seasons = provider.series?.seasons ?? [];
    if (seasons.isNotEmpty) {
      await _loadSeasonCast(seasons[_selectedSeasonIndex].seasonId);
    }
  }

  Future<void> _loadSeasonCast(int seasonId) async {
    if (_isLoadingSeasonCast && _loadedSeasonId == seasonId) {
      return;
    }

    setState(() {
      _isLoadingSeasonCast = true;
      _loadedSeasonId = seasonId;
    });

    try {
      final response = await _apiHelper.getApi(
        ApiConstant.getCastByContentIdAndSeasonId(widget.seriesId, seasonId),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final castData = responseBody['data']?['cast'] as List?;

        final castList = castData == null
            ? <CastMember>[]
            : castData
                .map(
                    (item) => CastMember.fromJson(item as Map<String, dynamic>))
                .where((cast) =>
                    cast.seasonId == null || cast.seasonId == seasonId)
                .toList();

        if (!mounted) return;
        setState(() {
          _seasonCastList = castList;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _seasonCastList = [];
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _seasonCastList = [];
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoadingSeasonCast = false;
      });
    }
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
          if (seasons.isEmpty) {
            if (ResponsiveWidget.isMobile(context)) {
              return _buildMobileSeriesView(
                series: series,
                seasons: seasons,
                season: null,
                theme: theme,
              );
            }

            return CustomScrollView(
              slivers: [
                _buildHero(series, theme),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResponsiveWidget.isDesktop(context) ? 72 : 16,
                      vertical: 28,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPrimeTabBar(theme, active: 'Episodes'),
                        const SizedBox(height: 24),
                        Text(
                          'No seasons available yet',
                          style: TextStyle(
                            color: theme.canvasColor.withOpacity(0.7),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 26),
                        _buildCastSection(context, null, theme),
                        const SizedBox(height: 32),
                        _buildRelatedRail(widget.content, theme),
                        const SizedBox(height: 32),
                        _buildDetailsSection(context, widget.content, theme),
                        const SizedBox(height: 32),
                        _buildGallery(widget.content),
                        const SizedBox(height: 32),
                        _buildRatingAndReviewsSection(context, widget.content),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (_selectedSeasonIndex >= seasons.length) {
            _selectedSeasonIndex = 0;
          }

          SeasonEntity season = seasons[_selectedSeasonIndex];

          if (_loadedSeasonId != season.seasonId && !_isLoadingSeasonCast) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _loadSeasonCast(season.seasonId);
              }
            });
          }

          if (ResponsiveWidget.isMobile(context)) {
            return _buildMobileSeriesView(
              series: series,
              seasons: seasons,
              season: season,
              theme: theme,
            );
          }

          return CustomScrollView(
            slivers: [
              _buildHero(
                series,
                theme,
                seasons: seasons,
                season: season,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveWidget.isDesktop(context) ? 72 : 16,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPrimeTabBar(theme, active: 'Episodes'),
                      const SizedBox(height: 24),
                      _buildSeasonSelector(seasons, theme),
                      const SizedBox(height: 20),
                      _buildSeasonInfo(context, season, theme),
                      const SizedBox(height: 18),
                      _buildEpisodeRail(context, season, theme),
                      const SizedBox(height: 32),
                      _buildCastSection(context, season, theme),
                      const SizedBox(height: 32),
                      _buildRelatedRail(widget.content, theme),
                      const SizedBox(height: 26),
                      _buildDetailsSection(context, widget.content, theme),
                      const SizedBox(height: 32),
                      _buildGallery(widget.content),
                      const SizedBox(height: 32),
                      _buildRatingAndReviewsSection(context, widget.content),
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

  Widget _buildMobileSeriesView({
    required SeriesEntity series,
    required List<SeasonEntity> seasons,
    required SeasonEntity? season,
    required ThemeData theme,
  }) {
    final episodes = season?.episodes ?? const <EpisodeEntity>[];

    return Container(
      color: Colors.black,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMobileSeriesPreview(series, theme),
              const SizedBox(height: 24),
              Text(
                series.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: theme.primaryColor,
                  fontSize: 34,
                  height: 1.02,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  StarRatingWidget(
                    rating: double.parse(
                      (widget.content.ratings ?? 0.0).toStringAsFixed(1),
                    ),
                    starSize: 20,
                    textSize: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${widget.content.ratingCount ?? 0})',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                series.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 21,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: ActionButtonWidget(
                      label: 'Share',
                      icon: Icons.qr_code_2_rounded,
                      onTap: () => showContentShareSheet(
                        context,
                        widget.content,
                        contentType: DeepLinkContentType.series,
                        unavailableMessage:
                            "Series details are not available yet",
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: _buildGifting(context, widget.content)),
                ],
              ),
              if (seasons.isNotEmpty) ...[
                const SizedBox(height: 28),
                _buildMobileSeasonChips(seasons, theme),
              ],
              if (season != null) ...[
                const SizedBox(height: 28),
                Text(
                  "Season ${season.seasonNumber}: ${season.title}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  season.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 20,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              _buildCastSection(context, season, theme),
              if (episodes.isNotEmpty) ...[
                const SizedBox(height: 26),
                _buildMobileEpisodeList(season!, episodes, theme),
              ],
              const SizedBox(height: 28),
              Divider(color: Colors.white.withValues(alpha: 0.18)),
              const SizedBox(height: 22),
              _buildDetailsSection(context, widget.content, theme),
              const SizedBox(height: 28),
              _buildRatingAndReviewsSection(context, widget.content),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileSeriesPreview(SeriesEntity series, ThemeData theme) {
    final poster = series.posterUrl.trim().isNotEmpty
        ? series.posterUrl
        : (widget.content.posterUrlList?.isNotEmpty == true
            ? widget.content.posterUrlList!.first
            : '');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                poster.isNotEmpty
                    ? Image.network(
                        poster,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade900),
                      )
                    : Container(color: Colors.grey.shade900),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  top: 18,
                  child: Icon(
                    Icons.volume_up_rounded,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 32,
                  ),
                ),
                Positioned(
                  right: 18,
                  top: 18,
                  child: Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white.withValues(alpha: 0.92),
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: -8,
          top: -42,
          child: IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileSeasonChips(
    List<SeasonEntity> seasons,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(seasons.length, (index) {
          final selected = index == _selectedSeasonIndex;
          return Padding(
            padding:
                EdgeInsets.only(right: index == seasons.length - 1 ? 0 : 14),
            child: Material(
              color: selected ? theme.primaryColor : theme.cardColor,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() => _selectedSeasonIndex = index);
                  _loadSeasonCast(seasons[index].seasonId);
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Text(
                    'Season ${seasons[index].seasonNumber}',
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMobileEpisodeList(
    SeasonEntity season,
    List<EpisodeEntity> episodes,
    ThemeData theme,
  ) {
    return Column(
      children: [
        for (final ep in episodes) ...[
          _buildMobileEpisodeCard(season, ep, theme),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildMobileEpisodeCard(
    SeasonEntity season,
    EpisodeEntity ep,
    ThemeData theme,
  ) {
    final canPlay = season.isSeasonPurchased || ep.isPurchased || ep.isFree;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap:
            canPlay ? () => _playEpisode(season, ep) : () => _rentEpisode(ep),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 135,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          ep.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade900),
                        ),
                        Center(
                          child: Icon(
                            canPlay
                                ? Icons.play_circle_fill_rounded
                                : Icons.lock_rounded,
                            color: Colors.white.withValues(alpha: 0.82),
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ep.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ep. ${ep.episodeNumber} • ${ep.runtime} min',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ep.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.25,
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

  // ---------------- HERO ----------------

  SliverAppBar _buildHero(
    SeriesEntity series,
    ThemeData theme, {
    List<SeasonEntity> seasons = const [],
    SeasonEntity? season,
  }) {
    final bool isMobile = ResponsiveWidget.isMobile(context);
    final bool isTablet = ResponsiveWidget.isTablet(context);
    final heroHeight = isMobile
        ? 520.0
        : isTablet
            ? 560.0
            : 640.0;

    return SliverAppBar(
      pinned: true,
      expandedHeight: heroHeight,
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
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black,
                    Colors.black.withValues(alpha: 0.94),
                    Colors.black.withValues(alpha: 0.46),
                    Colors.transparent,
                  ],
                  stops: const [0, 0.38, 0.72, 1],
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black45,
                    Colors.transparent,
                    Colors.black,
                  ],
                  stops: [0, 0.52, 1],
                ),
              ),
            ),

            /// ▶ Trailer Preview (Responsive)
            Positioned(
              left: isMobile ? 16 : 72,
              right: isMobile ? 16 : MediaQuery.of(context).size.width * 0.38,
              bottom: isMobile ? 34 : 58,
              child: _buildHeroCopy(
                series,
                theme,
                seasons: seasons,
                season: season,
              ),
            ),
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
              trailerUrl: widget.content.teaserOrTrailerUrl,
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
              trailerUrl: widget.content.teaserOrTrailerUrl,
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
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionButtonWidget(
              label: 'Share',
              icon: Icons.qr_code_2_rounded,
              onTap: () => showContentShareSheet(
                context,
                widget.content,
                contentType: DeepLinkContentType.series,
                unavailableMessage: "Series details are not available yet",
              ),
            ),
            _buildGifting(context, widget.content),
          ],
        ),
      ],
    );
  }

  Widget _buildGifting(BuildContext context, Content seriesContent) {
    final theme = Theme.of(context);
    final TextEditingController countController = TextEditingController();

    return ActionButtonWidget(
      label: 'Gift Series',
      icon: LucideIcons.gift,
      onTap: () {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Dialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 24,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: ResponsiveWidget.isMobile(dialogContext)
                      ? double.infinity
                      : 400,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Icon(
                          LucideIcons.gift,
                          size: 200,
                          color: theme.canvasColor.withOpacity(0.1),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.gift,
                                color: theme.primaryColor,
                                size: 28,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                "Gift This Series",
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Enter how many people you'd like to gift this series to.",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.canvasColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          CustomTextField(
                            backgroundColor: theme.scaffoldBackgroundColor,
                            isDigits: true,
                            controller: countController,
                            hintText: "Number of recipients",
                            textInputType: TextInputType.number,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(color: theme.canvasColor),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: theme.primaryColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                onPressed: () {
                                  final count =
                                      int.tryParse(countController.text);
                                  if (count == null || count <= 0) {
                                    CustomToast.show(
                                      dialogContext,
                                      'Please enter valid number',
                                      isSuccess: false,
                                    );
                                    return;
                                  }

                                  Navigator.pop(dialogContext);
                                  _trailerController.pause?.call();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MovieBillingPage(
                                        movie: seriesContent,
                                        giftCount: count,
                                      ),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Continue",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ).whenComplete(countController.dispose);
      },
    );
  }

  // ---------------- SEASON SELECTOR ----------------

  Widget _buildSeasonSelector(List<SeasonEntity> seasons, ThemeData theme) {
    return Row(
      children: [
        PopupMenuButton<int>(
          tooltip: 'Select season',
          color: theme.cardColor,
          onSelected: (index) {
            setState(() => _selectedSeasonIndex = index);
            _loadSeasonCast(seasons[index].seasonId);
          },
          itemBuilder: (context) => List.generate(
            seasons.length,
            (index) => PopupMenuItem<int>(
              value: index,
              child: Text(
                'Season ${seasons[index].seasonNumber}',
                style: TextStyle(
                  color: theme.canvasColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          child: OttTvFocus(
            borderRadius: BorderRadius.circular(12),
            scale: 1.04,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: theme.cardColor.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.canvasColor.withValues(alpha: 0.7),
                  width: 1.4,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_movies_rounded,
                    color: theme.primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Season ${seasons[_selectedSeasonIndex].seasonNumber}',
                    style: TextStyle(
                      color: theme.canvasColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: theme.canvasColor,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------- SEASON INFO ----------------

  Widget _buildSeasonInfo(
      BuildContext context, SeasonEntity season, ThemeData theme) {
    final hasPurchasedEpisode =
        season.episodes.any((EpisodeEntity ep) => ep.isPurchased);
    final canPurchaseSeason = !season.isSeasonPurchased && !hasPurchasedEpisode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.54),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.canvasColor.withValues(alpha: 0.08)),
      ),
      child: Row(
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
                widget.content.isFeatured == true
                    ? _buildReleaseDateHighlight(context, season)
                    : !season.isSeasonPurchased && canPurchaseSeason
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
                                        seriesTitle: widget.content.title,
                                        itemTitle: season.title,
                                        rentalDuration:
                                            widget.content.rentlDuration,
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
                                  "Rent complete Season ₹ ${season.price}",
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
      ),
    );
  }

  Widget _buildReleaseDateHighlight(
    BuildContext context,
    Object content, {
    bool centered = false,
  }) {
    final theme = Theme.of(context);
    final releaseDate = content is Content
        ? content.releaseDate
        : content is SeasonEntity
            ? _yearFromMillis(content.releaseDate)
            : null;
    final releaseDateText = releaseDate?.toString().trim();
    final displayText = (releaseDateText != null && releaseDateText.isNotEmpty)
        ? 'Release On: $releaseDateText'
        : 'Release On: Coming Soon';

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.primaryColor.withOpacity(0.65),
        ),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );

    if (!centered) {
      return child;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [child],
    );
  }

  Widget _buildCastSection(
    BuildContext context,
    SeasonEntity? season,
    ThemeData theme,
  ) {
    final fallbackCast = (widget.content.castList ?? const [])
        .where((name) => name.trim().isNotEmpty)
        .map((name) => CastMember(name: name.trim()))
        .toList();
    final castList =
        _seasonCastList.isNotEmpty ? _seasonCastList : fallbackCast;

    if (season != null &&
        _isLoadingSeasonCast &&
        _loadedSeasonId == season.seasonId) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.primaryColor,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cast and Crew",
          style: TextStyle(
            color: theme.canvasColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        castList.isEmpty
            ? const SizedBox.shrink()
            : SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: castList.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    if (castList.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return _buildCastCard(context, castList[index]);
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildCastCard(BuildContext context, CastMember cast) {
    final theme = Theme.of(context);
    final imageUrl = cast.image?.trim() ?? '';
    final displayName =
        (cast.name?.trim().isNotEmpty ?? false) ? cast.name!.trim() : 'N/A';
    final role =
        (cast.role?.trim().isNotEmpty ?? false) ? cast.role!.trim() : '';

    return OttTvFocus(
      borderRadius: BorderRadius.circular(14),
      scale: 1.06,
      child: SizedBox(
        width: 96,
        child: Column(
          children: [
            Container(
              height: 68,
              width: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.cardColor,
                border: Border.all(
                  color: theme.canvasColor.withValues(alpha: 0.08),
                ),
              ),
              child: ClipOval(
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _buildCastInitial(theme, displayName),
                      )
                    : _buildCastInitial(theme, displayName),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              displayName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.canvasColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            if (role.isNotEmpty)
              Text(
                role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.canvasColor.withOpacity(0.62),
                  fontSize: 10,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCastInitial(ThemeData theme, String displayName) {
    return Center(
      child: Text(
        displayName[0].toUpperCase(),
        style: TextStyle(
          color: theme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );
  }

  // ---------------- EPISODE TILE ----------------

  Widget _buildEpisodeRail(
    BuildContext context,
    SeasonEntity season,
    ThemeData theme,
  ) {
    if (season.episodes.isEmpty) {
      return Text(
        'No episodes available yet',
        style: TextStyle(
          color: theme.canvasColor.withOpacity(0.7),
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'Episodes'),
        const SizedBox(height: 14),
        SizedBox(
          height: ResponsiveWidget.isMobile(context) ? 278 : 302,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: season.episodes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 18),
            itemBuilder: (context, index) {
              return SizedBox(
                width: ResponsiveWidget.isMobile(context) ? 300 : 370,
                child: _episodePrimeCard(
                  context,
                  season,
                  season.episodes[index],
                  theme,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _episodePrimeCard(
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

    return OttTvFocus(
      onTap: canPlay ? () => _playEpisode(season, ep) : null,
      borderRadius: BorderRadius.circular(12),
      scale: 1.045,
      child: GestureDetector(
        onTap: canPlay ? () => _playEpisode(season, ep) : null,
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: theme.canvasColor.withValues(alpha: 0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      ep.posterUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade900,
                        child: const Icon(
                          Icons.broken_image,
                          color: Colors.white54,
                          size: 34,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.68),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    bottom: 10,
                    child: Icon(
                      canPlay ? Icons.play_circle_fill : Icons.lock_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 34,
                    ),
                  ),
                  if (progress > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                      ),
                    ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${ep.episodeNumber}. ${ep.title}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.canvasColor,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${ep.runtime} min  •  ${_yearFromMillis(ep.releaseDate) ?? ''}",
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.canvasColor.withOpacity(0.66),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ep.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: theme.canvasColor.withOpacity(0.7),
                      ),
                    ),
                    if (!canPlay) ...[
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ActionButtonWidget(
                          label: "Rent ₹ ${ep.price}",
                          icon: Icons.lock_open_rounded,
                          onTap: () => _rentEpisode(ep),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _rentEpisode(EpisodeEntity ep) async {
    _trailerController.pause?.call();
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SeriesBillingPage(
          seriesId: widget.seriesId,
          episodeId: ep.episodeId,
          amount: ep.price.toDouble(),
          isSeason: false,
          seriesTitle: widget.content.title,
          itemTitle: ep.title,
          rentalDuration: widget.content.rentlDuration,
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
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: TextStyle(
        color: theme.canvasColor,
        fontSize: ResponsiveWidget.isMobile(context) ? 20 : 24,
        fontWeight: FontWeight.w900,
      ),
    );
  }

  Widget _buildRelatedRail(Content content, ThemeData theme) {
    final posters = content.posterUrlList ?? const <String>[];
    if (posters.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPrimeTabBar(theme, active: 'Related'),
        const SizedBox(height: 20),
        _buildSectionHeader(theme, 'Related Series'),
        const SizedBox(height: 14),
        SizedBox(
          height: ResponsiveWidget.isMobile(context) ? 154 : 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: posters.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return OttTvFocus(
                borderRadius: BorderRadius.circular(12),
                scale: 1.045,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        posters[index],
                        width: ResponsiveWidget.isMobile(context) ? 250 : 320,
                        height: ResponsiveWidget.isMobile(context) ? 154 : 190,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: ResponsiveWidget.isMobile(context) ? 250 : 320,
                          color: theme.cardColor,
                          child: Icon(
                            Icons.broken_image,
                            color: theme.canvasColor.withOpacity(0.4),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

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
                                seriesTitle: widget.content.title,
                                itemTitle: ep.title,
                                rentalDuration: widget.content.rentlDuration,
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
                          "₹ ${ep.price}",
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
        //  border: Border.all(color: theme.canvasColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          /*   _buildTableRow(
              lang.cast,
              (movie.castList != null && movie.castList!.isNotEmpty)
                  ? movie.castList!.join(', ')
                  : 'N/A',
              titleStyle,
              contentStyle), */
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

  Widget _buildRatingAndReviewsSection(BuildContext context, Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRatingReviewSection(context, content),
        const SizedBox(height: 16),
        _buildReviewList(),
      ],
    );
  }

  Widget _buildRatingReviewSection(BuildContext context, Content content) {
    final selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;

    return Consumer<VideoProvider>(
      builder: (context, provider, child) => Column(
        children: [
          const Text(
            "Rate your experience",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          StarRating(
            rating: provider.rating,
            onRatingChanged: (rating) =>
                setState(() => provider.rating = rating),
          ),
          const SizedBox(height: 7),
          Container(
            height: 90,
            margin: const EdgeInsets.all(10.0),
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              maxLines: 9,
              style: const TextStyle(color: Colors.white),
              controller: provider.reviewController,
              decoration: const InputDecoration(
                hintText: "Your Feedback!",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 7),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedThemeData.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              final contentId = content.id ?? widget.seriesId;
              if (provider.rating == 0) {
                CustomToast.show(context, "Please select rating..",
                    isSuccess: false);
                return;
              }

              final result = await provider.saveRatingReview(contentId);
              if (!mounted) return;

              final message = result['message']?.toString().trim();
              if (result['success'] != true) {
                CustomToast.show(
                  context,
                  message != null && message.isNotEmpty
                      ? message
                      : "something went wrong to submit review",
                  isSuccess: false,
                );
                return;
              }

              CustomToast.show(
                context,
                message != null && message.isNotEmpty
                    ? message
                    : 'review submitted successfully',
                isSuccess: true,
              );
              await context.read<VideoProvider>().getRatingReview(contentId);
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child:
                  Text("Submit Review", style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCopy(
    SeriesEntity series,
    ThemeData theme, {
    required List<SeasonEntity> seasons,
    required SeasonEntity? season,
  }) {
    final isMobile = ResponsiveWidget.isMobile(context);
    final genreText = (widget.content.genreList ?? const [])
        .where((genre) => genre.trim().isNotEmpty)
        .take(3)
        .join('  •  ');
    final languageText = (widget.content.languageList ?? const [])
        .map((e) => e.language?.trim())
        .where((language) => language != null && language.isNotEmpty)
        .cast<String>()
        .take(2)
        .join(', ');
    final yearText = _yearFromMillis(season?.releaseDate) ??
        widget.content.releaseDate ??
        '';
    final runtimeText = widget.content.runtime != null
        ? '${widget.content.runtime} min'
        : season != null && season.episodes.isNotEmpty
            ? '${season.episodes.length} episodes'
            : '';
    final seasonText = seasons.isNotEmpty ? '${seasons.length} seasons' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          series.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white,
            fontSize: isMobile ? 34 : 54,
            height: 0.98,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _metadataPill(
              theme,
              'IMDb ${double.parse((widget.content.ratings ?? 0).toStringAsFixed(1))}/10',
              highlighted: true,
            ),
            if (yearText.trim().isNotEmpty) _metadataText(yearText),
            if (seasonText.isNotEmpty) _metadataText(seasonText),
            if (runtimeText.isNotEmpty) _metadataText(runtimeText),
            if ((widget.content.ageRating ?? '').trim().isNotEmpty)
              _metadataPill(theme, widget.content.ageRating!),
            if (genreText.isNotEmpty) _metadataText(genreText),
            if (languageText.isNotEmpty) _metadataText(languageText),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          series.description,
          maxLines: isMobile ? 4 : 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.88),
            height: 1.45,
            fontSize: isMobile ? 14 : 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ActionButtonWidget(
              label: 'Play Now',
              icon: Icons.play_arrow_rounded,
              onTap: () => _playFirstAvailableEpisode(season),
            ),
            ActionButtonWidget(
              label: 'Watch Trailer',
              icon: Icons.movie_filter_rounded,
              onTap: _openTrailer,
            ),
            _buildWatchlistButton(theme),
            ActionButtonWidget(
              label: 'Share',
              icon: Icons.qr_code_2_rounded,
              onTap: () => showContentShareSheet(
                context,
                widget.content,
                contentType: DeepLinkContentType.series,
                unavailableMessage: "Series details are not available yet",
              ),
            ),
            _buildGifting(context, widget.content),
          ],
        ),
      ],
    );
  }

  Widget _metadataText(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white70,
        fontWeight: FontWeight.w800,
        fontSize: 13,
      ),
    );
  }

  Widget _metadataPill(
    ThemeData theme,
    String text, {
    bool highlighted = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.primaryColor.withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildWatchlistButton(ThemeData theme) {
    return Consumer<BookmarkProvider>(
      builder: (context, bookmarkProvider, _) {
        final isBookmarked =
            bookmarkProvider.isBookmarkedLocally(widget.content.id ?? 0);
        return ActionButtonWidget(
          label: isBookmarked ? 'Watchlisted' : 'Add to Watchlist',
          icon: isBookmarked ? Icons.bookmark : Icons.bookmark_add_outlined,
          onTap: () async {
            await bookmarkProvider.toggleBookmark(widget.content);
            if (!mounted) return;
            CustomToast.show(
              context,
              isBookmarked
                  ? "${widget.content.title} removed from watchlist"
                  : "${widget.content.title} added to watchlist",
              isSuccess: true,
            );
          },
        );
      },
    );
  }

  void _openTrailer() {
    final trailerUrl =
        (widget.content.teaserOrTrailerUrl?.trim().isNotEmpty ?? false)
            ? widget.content.teaserOrTrailerUrl
            : widget.content.trailerUrl;

    if (trailerUrl == null || trailerUrl.trim().isEmpty) {
      CustomToast.show(context, "Trailer is not available", isSuccess: false);
      return;
    }

    _trailerController.pause?.call();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailerPage(
          trailerUrl: trailerUrl,
          isTrailerUrl: true,
          content: widget.content,
        ),
      ),
    );
  }

  Future<void> _playFirstAvailableEpisode(SeasonEntity? season) async {
    if (season == null || season.episodes.isEmpty) {
      CustomToast.show(context, "Episodes are not available", isSuccess: false);
      return;
    }

    EpisodeEntity? selectedEpisode;
    for (final episode in season.episodes) {
      if (season.isSeasonPurchased || episode.isPurchased || episode.isFree) {
        selectedEpisode = episode;
        break;
      }
    }

    if (selectedEpisode == null) {
      CustomToast.show(
        context,
        "Please rent this season or episode to watch",
        isSuccess: false,
      );
      return;
    }

    await _playEpisode(season, selectedEpisode);
  }

  Future<void> _playEpisode(SeasonEntity season, EpisodeEntity ep) async {
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
      context.read<DashboardProvider>().getContinueWatchedMovieList("SERIES");
    }
  }

  String? _yearFromMillis(int? millis) {
    if (millis == null || millis <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis).year.toString();
  }

  Widget _buildPrimeTabBar(ThemeData theme, {required String active}) {
    const tabs = ['Episodes', 'Related', 'Details'];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.cardColor.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Wrap(
        spacing: 28,
        runSpacing: 8,
        children: tabs.map((tab) {
          final selected = tab == active;
          return Text(
            tab,
            style: TextStyle(
              color: selected
                  ? theme.canvasColor
                  : theme.canvasColor.withOpacity(0.5),
              fontSize: 18,
              fontWeight: FontWeight.w900,
              decoration: selected ? TextDecoration.underline : null,
              decorationThickness: 3,
              decorationColor: theme.canvasColor,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewList() {
    return Consumer<VideoProvider>(
      builder: (context, provider, child) {
        if (provider.reviewList.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: provider.reviewList.length,
          itemBuilder: (BuildContext context, int index) {
            DateTime date = DateTime.now();
            if (provider.reviewList[index].createdAt != null) {
              date = DateTime.fromMillisecondsSinceEpoch(
                  provider.reviewList[index].createdAt!);
            }
            final formattedDate =
                DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
            final username = provider.reviewList[index].username;
            final displayName = username == null || username == "null null"
                ? "Anonymous User"
                : username;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        height: 40,
                        width: 40,
                        child: CircleAvatar(
                          backgroundImage:
                              provider.reviewList[index].userProfile != null
                                  ? NetworkImage(
                                      provider.reviewList[index].userProfile!)
                                  : null,
                          radius: 50,
                          child: provider.reviewList[index].userProfile == null
                              ? const Icon(Icons.person, size: 25)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      StarDisplay(
                          value: provider.reviewList[index].rating ?? 5),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    provider.reviewList[index].title.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.normal,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Divider(thickness: 2),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ---------------- GALLERY ----------------

  Widget _buildGallery(Content content) {
    final theme = Theme.of(context);
    final posters = content.posterUrlList ?? [];
    final teaserUrl = _galleryVideoUrl(content);
    final hasPosters = posters.isNotEmpty;
    final hasTeaser = teaserUrl.isNotEmpty;

    if (!hasPosters && !hasTeaser) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: posters.length + (hasTeaser ? 1 : 0),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              if (hasTeaser && index == 0) {
                return SizedBox(
                  width: 320,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: TrailerPreview(
                      trailerUrl: teaserUrl,
                      content: content,
                      controller: _teaserController,
                    ),
                  ),
                );
              }

              final posterIndex = hasTeaser ? index - 1 : index;
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  posters[posterIndex],
                  width: 320,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 320,
                    color: Colors.black26,
                    child: Icon(
                      Icons.broken_image,
                      color: theme.canvasColor.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _galleryVideoUrl(Content content) {
    final teaserUrl = content.teaserUrl?.trim() ?? '';
    if (teaserUrl.isNotEmpty) return teaserUrl;

    return content.trailerUrl?.trim() ?? '';
  }
}
