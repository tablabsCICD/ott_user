import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/watchlist%20page/component/DisplayTrailer.dart';
import 'package:ott/app/pages/wallet%20page/MovieBillingPage.dart';
import 'package:ott/app/pages/movie%20details%20page/component/actionButtonWidget.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/offline_download_provider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/app/widgets/content_share_sheet.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/data/models/cast_member.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../widgets/show_toast.dart';
import '../watchlist page/component/playMoviePage.dart';
import 'component/displayStar.dart';
import 'component/starRating.dart';

class MovieDetailsPage extends StatefulWidget {
  final int movieId;

  const MovieDetailsPage({super.key, required this.movieId});

  @override
  State<MovieDetailsPage> createState() => _MovieDetailsPageState();
}

class _MovieDetailsPageState extends State<MovieDetailsPage> {
  bool isLoading = true;
  bool _contentLoadCompleted = false;
  bool _contentLoadFailed = false;
  final TrailerPreviewController _trailerController =
      TrailerPreviewController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<void> _fetchData() async {
    final dashboardProvider =
        Provider.of<DashboardProvider>(context, listen: false);
    try {
      final content = await dashboardProvider.getContentById(widget.movieId);
      final hasValidContent = content?.id == widget.movieId;

      if (!hasValidContent) {
        if (mounted) {
          setState(() {
            _contentLoadFailed = true;
            _contentLoadCompleted = true;
            isLoading = false;
          });
        }
        return;
      }
      final loadedContent = content!;

      await dashboardProvider.getCastByContentId(widget.movieId);
      await Provider.of<VideoProvider>(context, listen: false)
          .getRatingReview(widget.movieId);
      if (mounted) {
        await Provider.of<OfflineDownloadProvider>(context, listen: false)
            .refreshStatus(loadedContent);
      }
    } catch (error) {
      debugPrint("Movie details fetch error: $error");
      if (mounted) {
        setState(() {
          _contentLoadFailed = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _contentLoadCompleted = true;
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _trailerController.pause?.call();
    super.dispose();
  }

  Future<void> _playMovie(Content movie) async {
    if (movie.id == null) return;

    Content contentToPlay = movie;
    var contentUrl = contentToPlay.contentUrl;

    if (contentUrl == null || contentUrl.trim().isEmpty) {
      final fetchedContent = await context
          .read<DashboardProvider>()
          .getContentById(movie.id!);
      if (!mounted) return;

      if (fetchedContent != null) {
        fetchedContent.watchedSeconds ??= movie.watchedSeconds;
        fetchedContent.watchedPercentage ??= movie.watchedPercentage;
        contentToPlay = fetchedContent;
        contentUrl = contentToPlay.contentUrl;
      }
    }

    if (contentUrl == null || contentUrl.trim().isEmpty) {
      CustomToast.show(
        context,
        "Video is not available",
        isSuccess: false,
      );
      return;
    }

    _trailerController.pause?.call();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayMediaPage(
          seasons: null,
          seasonIndex: 0,
          episodeIndex: 0,
          videoUrl: contentUrl!,
          content: contentToPlay,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      context.read<DashboardProvider>().getContinueWatchedMovieList("MOVIE");
    });
  }

  @override
  Widget build(BuildContext context) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;

    Content? movieContent =
        Provider.of<DashboardProvider>(context, listen: true).content;

    if (isLoading || !_contentLoadCompleted) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).primaryColor,
          ),
        ),
      );
    }

    if (_contentLoadFailed) {
      return _buildContentUnavailableScaffold(selectedThemeData);
    }

    return Scaffold(
      backgroundColor: selectedThemeData.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        forceMaterialTransparency: true,
        foregroundColor: Colors.white,
        title: ResponsiveWidget.isDesktop(context)
            ? const Text('')
            : StarRatingWidget(
                rating: double.parse(
                  (Provider.of<DashboardProvider>(context).content.ratings ??
                          0.0)
                      .toStringAsFixed(1),
                ),
                starSize: 20,
                textSize: 16,
              ),
        actions: [
          _ageRating(movieContent.ageRating),
          SizedBox(
            width: 5,
          )
        ],
        backgroundColor: Colors.transparent,
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: Consumer<DashboardProvider>(
          builder: (context, provider, child) {
            final content = provider.content;

            return Stack(
              children: [
                ResponsiveWidget.isDesktop(context)
                    ? _buildDesktopView(content, selectedThemeData)
                    : _buildMobileView(content, selectedThemeData),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentUnavailableScaffold(ThemeData selectedThemeData) {
    final lang = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: selectedThemeData.scaffoldBackgroundColor,
      appBar: AppBar(
        forceMaterialTransparency: true,
        foregroundColor: Colors.white,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.alertCircle,
                color: selectedThemeData.primaryColor,
                size: 46,
              ),
              const SizedBox(height: 14),
              Text(
                lang.noContentAvailable,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selectedThemeData.canvasColor,
                  fontSize: ResponsiveWidget.isMobile(context) ? 18 : 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This content is currently unavailable. Please try again later.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selectedThemeData.canvasColor.withOpacity(0.7),
                  fontSize: ResponsiveWidget.isMobile(context) ? 14 : 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopView(Content content, ThemeData selectedThemeData) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(
          content.posterUrlList != null && content.posterUrlList!.isNotEmpty
              ? content.posterUrlList![0]
              : null,
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
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
                              content.title ?? "",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: selectedThemeData.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        StarRatingWidget(
                          rating: double.parse(
                            (content.ratings ?? 0.0).toStringAsFixed(1),
                          ),
                          starSize: 20,
                          textSize: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${content.ratingCount ?? '0'} reviews)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const Spacer(),
                        _ageRating(content.ageRating ?? ""),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const SizedBox(height: 16),
                    content.isFeatured == true
                        ? _buildReleaseDateHighlight(
                            context,
                            content,
                            centered: true,
                          )
                        : Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildButtons(context, content),
                            ],
                          ),
                    const SizedBox(height: 16),
                    _buildCastSection(context, content),
                    const SizedBox(height: 16),
                    Text(
                      "  ${content.description ?? 'N/A'}",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDetailsSection(context, content),
                    const SizedBox(height: 16),
                    _buildRatingAndReviewsSection(context, content),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 100,
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: TrailerPreview(
                          trailerUrl: content.trailerUrl,
                          content: content,
                          controller: _trailerController,
                        ),
                      ),
                    ),
                    /*  SizedBox(
                      height: 100,
                    ),
                    if (content.posterUrlList != null &&
                        content.posterUrlList!.isNotEmpty) ...[
                      Text(
                        "Gallery",
                        style: TextStyle(
                          color: selectedThemeData.primaryColor,
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
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
                    ], */
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileView(Content content, ThemeData selectedThemeData) {
    final backgroundImage =
        content.posterUrlList != null && content.posterUrlList!.isNotEmpty
            ? content.posterUrlList!.first
            : null;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBackground(backgroundImage),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black.withOpacity(0.9),
              ],
            ),
          ),
        ),
        SingleChildScrollView(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 95),
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: TrailerPreview(
                    trailerUrl: content.trailerUrl,
                    content: content,
                    controller: _trailerController,
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text(
                content.title ?? "",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: selectedThemeData.primaryColor,
                ),
              ),
              Row(
                children: [
                  Text(
                    (content.genreList != null && content.genreList!.isNotEmpty)
                        ? content.genreList!.join(' | ')
                        : 'N/A',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                content.description ?? 'N/A',
                textAlign: TextAlign.left,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.normal,
                ),
              ),
              const SizedBox(height: 8),
              content.isFeatured == true
                  ? _buildReleaseDateHighlight(context, content)
                  : Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildButtons(context, content),
                      ],
                    ),
              const SizedBox(height: 12),
              _buildCastSection(context, content),
              const SizedBox(height: 10),
              _buildDetailsSection(context, content),
              const SizedBox(height: 16),
              _buildRatingAndReviewsSection(context, content),
              const SizedBox(height: 24),
              /*   const SizedBox(height: 35),
              if (content.posterUrlList != null &&
                  content.posterUrlList!.isNotEmpty) ...[
                Text(
                  "Gallery",
                  style: TextStyle(
                    color: selectedThemeData.primaryColor,
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
                const SizedBox(height: 35),
                content.isRental == true
                    ? _buildRatingReviewSection(context, content)
                    : SizedBox.shrink(),
                const SizedBox(height: 35),
              ], */
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBackground(String? imageUrl) {
    return imageUrl != null && imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey),
          )
        : Container(color: Colors.black);
  }

  Widget _buildReleaseDateHighlight(
    BuildContext context,
    Content content, {
    bool centered = false,
  }) {
    final theme = Theme.of(context);
    final releaseDateText = content.releaseDate?.toString().trim();
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

  Widget _ageRating(String? ageRating) {
    return ageRating != null && ageRating.isNotEmpty
        ? Tooltip(
            preferBelow: false,
            showDuration: const Duration(seconds: 2),
            waitDuration: const Duration(seconds: 1),
            message: ageRating == 'U'
                ? 'Universal Age'
                : ageRating == 'U/A'
                    ? 'Parental Guidance'
                    : 'Adults Only',
            child: Image.asset(
              height: 40,
              width: 60,
              ageRating == 'U'
                  ? ImageConstant.ageUniversal
                  : ageRating == 'U/A'
                      ? ImageConstant.ageParentalGuidance
                      : ImageConstant.ageAdultsOnly,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Container(color: Colors.grey),
            ),
          )
        : Container(color: Colors.black);
  }

  Widget _buildGifting(BuildContext context, Content movie,
      {bool iconOnly = false}) {
    final theme = Theme.of(context);
    final TextEditingController countController = TextEditingController();

    return Center(
      child: ActionButtonWidget(
        label: 'Gift Movie',
        icon: LucideIcons.gift,
        iconOnly: iconOnly,
        onTap: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return Dialog(
                backgroundColor: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                insetPadding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: ResponsiveWidget.isMobile(context)
                        ? double.infinity
                        : 400,
                    child: Stack(
                      children: [
                        Positioned(
                          top: 1,
                          left: 1,
                          right: 1,
                          bottom: 1,
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
                            // Header
                            Row(
                              children: [
                                Icon(LucideIcons.gift,
                                    color: theme.primaryColor, size: 28),
                                const SizedBox(width: 10),
                                Text(
                                  "Gift This Movie",
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Description
                            Text(
                              "Enter how many people you’d like to gift this movie to.",
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.canvasColor,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Input field
                            CustomTextField(
                              backgroundColor: theme.scaffoldBackgroundColor,
                              isDigits: true,
                              controller: countController,
                              hintText: "Number of recipients",
                              textInputType: TextInputType.number,
                            ),
                            const SizedBox(height: 24),

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
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
                                          context, 'Please enter valid number',
                                          isSuccess: false);
                                      return;
                                    }

                                    Navigator.pop(context);
                                    _trailerController.pause?.call();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => MovieBillingPage(
                                          movie: movie,
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
          );
        },
      ),
    );
  }

  Widget _buildButtons(BuildContext context, Content movie) {
    final lang = AppLocalizations.of(context)!;
    final contentType = (movie.type ?? '').toLowerCase();

    final canPlay = contentType.isNotEmpty;

    final canDownloadOffline = _canDownloadOffline(movie);
    final showIconOnlyButtons = canDownloadOffline;

    /// 👉 First Row Buttons
    final buttons = <Widget>[
      Expanded(
        child: movie.isRental == false
            ? ActionButtonWidget(
                label: '${lang.rent} ₹${movie.price}',
                icon: Icons.movie,
                iconOnly: showIconOnlyButtons,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => _buildConfirmationBox(context, movie),
                  );
                },
              )
            : ActionButtonWidget(
                label:
                    contentType == "movie" ? lang.watchMovie : lang.watchSeries,
                icon: Icons.play_circle_fill,
                iconOnly: showIconOnlyButtons,
                onTap: () {
                  if (!canPlay) {
                    CustomToast.show(
                      context,
                      "Video is not available",
                      isSuccess: false,
                    );
                    return;
                  }

                  _playMovie(movie);
                },
              ),
      ),
      if (canDownloadOffline) ...[
        const SizedBox(width: 12),
        Expanded(
          child: _buildDownloadActionButton(
            context,
            movie,
            iconOnly: showIconOnlyButtons,
          ),
        ),
      ],
    ];

    /// 👉 Second Row Buttons
    buttons.addAll([
      const SizedBox(width: 12),
      Expanded(
        child: _buildGifting(
          context,
          movie,
          iconOnly: showIconOnlyButtons,
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _buildShareActionButton(
          context,
          movie,
          iconOnly: showIconOnlyButtons,
        ),
      ),
    ]);

    return Row(children: buttons);
  }

  bool _canDownloadOffline(Content movie) {
    final contentType = (movie.type ?? '').toLowerCase();
    return movie.isRental == true &&
        movie.isDownloadable == true &&
        (contentType == 'movie' || contentType == 'series') &&
        (movie.contentUrl?.trim().isNotEmpty ?? false);
  }

  Widget _buildDownloadActionButton(BuildContext context, Content movie,
      {bool iconOnly = false}) {
    final contentId = movie.id;
    if (contentId == null) {
      return const SizedBox.shrink();
    }

    return Consumer<OfflineDownloadProvider>(
      builder: (context, offlineProvider, _) {
        final isDownloading = offlineProvider.isDownloading(contentId);
        final isDownloaded = offlineProvider.isDownloaded(contentId);
        final progress = offlineProvider.progressFor(contentId);

        return ActionButtonWidget(
          label: isDownloading
              ? 'Downloading ${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%'
              : isDownloaded
                  ? 'Remove Offline'
                  : 'Download',
          icon: isDownloaded ? Icons.delete_outline : Icons.download_rounded,
          iconOnly: iconOnly,
          onTap: () async {
            if (isDownloading) return;

            final result = isDownloaded
                ? await offlineProvider.deleteContent(movie)
                : await offlineProvider.downloadContent(movie);

            if (!mounted) return;
            CustomToast.show(
              context,
              result['message']?.toString() ?? 'Action completed.',
              isSuccess: result['success'] == true,
            );
          },
        );
      },
    );
  }

  Widget _buildCastSection(BuildContext context, Content content) {
    final theme = Theme.of(context);
    final provider = Provider.of<DashboardProvider>(context);
    final apiCastList = provider.castList;
    final fallbackCastList = (content.castList ?? const [])
        .where((name) => name.trim().isNotEmpty)
        .map((name) => CastMember(name: name.trim()))
        .toList();
    final castList = apiCastList.isNotEmpty ? apiCastList : fallbackCastList;

    if (provider.isLoadingCast) {
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
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        castList.isEmpty
            ? SizedBox.shrink()
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

                    final cast = castList[index];
                    return _buildCastCard(context, cast);
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

    return SizedBox(
      width: 84,
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardColor,
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
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 11, color: Colors.white),
          ),
          if (role.isNotEmpty)
            Text(
              "($role)",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: Colors.white),
            ),
        ],
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

  // Widget _buildShareButton(BuildContext context, Content movie) {
  //   return ActionButtonWidget(
  //     label: "Share",
  //     icon: Icons.share,
  //     onTap: () => _shareMovie(context, movie),
  //   );
  // }

  Widget _buildShareActionButton(BuildContext context, Content movie,
      {bool iconOnly = false}) {
    return ActionButtonWidget(
      label: 'Share',
      icon: Icons.qr_code_2_rounded,
      iconOnly: iconOnly,
      onTap: () => showContentShareSheet(
        context,
        movie,
        contentType: DeepLinkContentType.movie,
        unavailableMessage: "Movie details are not available yet",
      ),
    );
  }

  Widget _buildConfirmationBox(BuildContext context, Content movie) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;
    final lang = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: selectedThemeData.cardColor,
      title: Center(
        child: Text(
          movie.title ?? "",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color:
                selectedThemeData.primaryColor, // Apply text color from theme
          ),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${lang.price}: ${movie.price ?? 0.0}',
            style: TextStyle(
              fontSize: 14,
              color: selectedThemeData.secondaryHeaderColor, // Theme text color
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${lang.rentDuration}: ${movie.rentlDuration ?? ''}',
            style: TextStyle(
              fontSize: 14,
              color: selectedThemeData.secondaryHeaderColor, // Theme text color
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Do you want to rent this ${movie.type}?',
            style: TextStyle(
              fontSize: 14,
              color: selectedThemeData.primaryColor, // Theme text color
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: selectedThemeData.cardColor,
            foregroundColor: selectedThemeData.canvasColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            //_trailerController.pause?.call();
            Navigator.of(context).pop(); // Close the dialog
          },
          child: Text(lang.cancel),
        ),
        TextButton(
          style: TextButton.styleFrom(
            backgroundColor: selectedThemeData.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () async {
            _trailerController.pause?.call();
            Navigator.of(context).pop(); // Close the dialog
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (context) => MovieBillingPage(
                  movie: movie,
                ),
              ),
            );

            if (result == true && mounted) {
              await _fetchData();
            }
          },
          child: Text("Continue"),
        ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, Content movie) {
    final lang = AppLocalizations.of(context)!;
    final languages = (movie.languageList ?? const [])
        .map((e) => e.language?.trim())
        .where((language) => language != null && language.isNotEmpty)
        .cast<String>()
        .join(', ');
    TextStyle titleStyle = const TextStyle(
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );
    TextStyle contentStyle = const TextStyle(
      color: Colors.white70,
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          //  border: Border.all(color: Colors.white24),
          // borderRadius: BorderRadius.circular(8),
          ),
      child: Table(
        columnWidths: const {
          0: IntrinsicColumnWidth(),
          1: FlexColumnWidth(),
        },
        /*   border: TableBorder.symmetric(
          inside: BorderSide(color: Colors.white12, width: 0.5),
        ), */
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          /*    _buildTableRow(
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
          _buildTableRow(lang.runtime, movie.runtime?.toString() ?? 'N/A',
              titleStyle, contentStyle),
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
              languages.isNotEmpty ? languages : 'N/A',
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.rating,
              '${double.parse(
                (movie.ratings ?? 0.0).toStringAsFixed(1),
              )} ⭐',
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.audioFormat,
              (movie.audioFormatList ?? []).join(', '),
              titleStyle,
              contentStyle),
          _buildTableRow(
              lang.subtitle,
              (movie.subtitleLanguageList ?? []).join(', '),
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
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Text('$title:', style: titleStyle),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(content, style: contentStyle),
        ),
      ],
    );
  }

  Widget _buildRatingAndReviewsSection(BuildContext context, Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (content.isRental == true) ...[
          _buildRatingReviewSection(context, content),
          const SizedBox(height: 16),
        ],
        getChatList(),
      ],
    );
  }

  Widget _buildRatingReviewSection(BuildContext context, Content content) {
    var selectedThemeData =
        Provider.of<ThemeProvider>(context, listen: true).getTheme;
    return Consumer<VideoProvider>(
      builder: (context, provider, child) => Column(
        children: [
          Text(
            "Rate your experience",
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
          ),
          StarRating(
            rating: provider.rating,
            onRatingChanged: (rating) =>
                setState(() => provider.rating = rating),
          ),
          SizedBox(
            height: 7,
          ),
          Container(
            height: 90,
            margin: EdgeInsets.all(10.0),
            padding: EdgeInsets.only(bottom: 16.0),
            child: TextField(
              maxLines: 9,
              style: TextStyle(
                // Input text color
                color: Colors.white,
              ),
              controller: provider.reviewController,
              decoration: InputDecoration(
                hintText: "Your Feedback!",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SizedBox(
            height: 7,
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedThemeData.primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: () async {
              if (content.id == null) {
                CustomToast.show(context, "Movie details are not available yet",
                    isSuccess: false);
                return;
              }

              // if (provider.reviewController.text.isNotEmpty) {
              if (provider.rating == 0) {
                CustomToast.show(context, "Please select rating..",
                    isSuccess: false);
              } else {
                var result = await provider.saveRatingReview(content.id!);
                if (result['success'] == false) {
                  CustomToast.show(
                      context, "something went wrong to submit review",
                      isSuccess: false);
                } else {
                  CustomToast.show(context, 'review submitted successfully',
                      isSuccess: true);
                  await _fetchData();
                }
              }
              /* } else {
                CustomToast.show(context, "Please give some comments",
                    isSuccess: false);
              } */
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child:
                  Text("Submit Review", style: TextStyle(color: Colors.white)),
            ),
          ),
          /*  Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              getChatList(),
            ],
          ), */
        ],
      ),
    );
  }

  Widget getChatList() {
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
            String formattedDate =
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
                      const SizedBox(
                        width: 15,
                      ),
                      Expanded(
                        child: Text(
                          displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.white),
                        ),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      StarDisplay(
                          value: provider.reviewList[index].rating ?? 5),
                      const SizedBox(
                        width: 10,
                      ),
                      Flexible(
                        child: Text(formattedDate,
                            style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                fontSize: 12,
                                color: Colors.white)),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Text(provider.reviewList[index].title.toString(),
                      style: const TextStyle(
                          fontWeight: FontWeight.normal,
                          fontSize: 12,
                          color: Colors.white)),
                  const SizedBox(
                    height: 10,
                  ),
                  const Divider(
                    thickness: 2,
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
