import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/pages/DisplayTrailer.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/pages/watchlist%20page/playMoviePage.dart';
import 'package:ott/app/pages/wallet%20page/MovieBillingPage.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'package:ott/data/models/content.dart';

class MovieCard extends StatefulWidget {
  final Content movie;

  const MovieCard({super.key, required this.movie});

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  VideoPlayerController? _videoController;
  bool _isHovered = false;
  bool _isMuted = false;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<BookmarkProvider>()
          .isBookmarked(widget.movie.id ?? 0)
          .then((value) {
        if (value) {
          context.read<BookmarkProvider>().addBookmark(widget.movie.id ?? 0);
        }
      });
    });
  }

  bool get _hasWatchProgress =>
      (widget.movie.watchedPercentage ?? 0) > 0 &&
          (widget.movie.watchedPercentage ?? 0) < 100;

  Widget _watchProgressBar() {
    final progress = (widget.movie.watchedPercentage ?? 0) / 100;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 4,
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: AlwaysStoppedAnimation<Color>(
            Colors.blue, // Netflix-style
          ),
        ),
      ),
    );
  }

  void _toggleMute() {
    final controller = _videoController;
    if (controller == null) return;

    setState(() {
      _isMuted = !_isMuted;
      controller.setVolume(_isMuted ? 0 : 1);
    });
  }

  Future<void> _initializeVideo() async {
    final trailerUrl = widget.movie.trailerUrl;
    if (trailerUrl?.isNotEmpty == true) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(trailerUrl!));

      try {
        await _videoController!.initialize();
        _videoController!
          ..setLooping(true)
          ..setVolume(1.0);

        if (mounted) {
          setState(() => _isVideoInitialized = true);
        }
      } catch (e) {
        debugPrint("Video init failed: $e");
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    setState(() => _isHovered = hovering);

    final controller = _videoController;
    if (controller == null || !_isVideoInitialized) return;

    hovering ? controller.play() : controller.pause();
    if (!hovering) controller.seekTo(Duration.zero);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final posterUrl = widget.movie.posterUrlList?.isNotEmpty == true
        ? widget.movie.posterUrlList!.first
        : null;

    return Stack(
      children: [
        MouseRegion(
          onEnter: (_) => _handleHover(true),
          onExit: (_) => _handleHover(false),
          child: GestureDetector(
            onTap: _openDetails,
            child: Container(
              width: 300,
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  /// 🎬 POSTER + PROGRESS BAR STACK
                  Expanded(
                    flex: 8,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: _buildMediaPreview(
                            posterUrl,
                            theme,
                            widget.movie,
                          ),
                        ),

                        /// 🔥 CONTINUE WATCHING BAR
                        if ((widget.movie.watchedPercentage ?? 0) > 0)
                          _watchProgressBar(),
                      ],
                    ),
                  ),

                  /// 📄 DETAILS SECTION
                  Expanded(
                    flex: 4,
                    child: _buildContentSection(theme, lang),
                  ),
                ],
              ),
            ),
          ),
        ),

        /// ⋮ OPTIONS BUTTON
        _optionButton(context, widget.movie),
      ],
    );
  }

  Widget _buildMediaPreview(
      String? posterUrl, ThemeData theme, Content content) {
    if (_isHovered && _isVideoInitialized && _videoController != null) {
      return AspectRatio(
        aspectRatio: 19 / 8,
        child: Stack(
          children: [
            Expanded(child: VideoPlayer(_videoController!)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _videoController!,
                allowScrubbing: true,
              ),
            ),
            Positioned(
              right: 5,
              bottom: 5,
              child: IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: _toggleMute,
              ),
            ),

          ],
        ),
      );
    }

    return posterUrl != null
        ? Image.network(
            posterUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Icon(
              Icons.broken_image,
              color: theme.canvasColor.withOpacity(0.3),
              size: 40,
            ),
          )
        : Icon(
            Icons.broken_image,
            color: theme.canvasColor.withOpacity(0.3),
            size: 40,
          );
  }

  Widget _buildContentSection(ThemeData theme, AppLocalizations lang) {
    final movie = widget.movie;

    final rating = movie.ratings ?? 0.0;
    final price = movie.price ?? 0;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StarRatingWidget(
                    rating: rating,
                  ),
                  Text(
                    " (${movie.ratingCount ?? 0})",
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.canvasColor.withOpacity(0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                movie.title ?? 'No Title',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.canvasColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text.rich(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                TextSpan(
                  style: TextStyle(
                    color: theme.canvasColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(text: movie.releaseDate ?? ''),
                    const TextSpan(text: ' | '),
                    TextSpan(
                      text: movie.genreList?.join(', ') ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: Row(
            children: [
              // _optionButton(context, movie),
              // SizedBox(
              //   width: 5,
              // ),
              movie.isFeatured == true
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 6, horizontal: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: theme.primaryColor.withOpacity(0.9),
                      ),
                      child: Text(
                        "Watch Trailer",
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : _buildPriceButton(theme, lang, price),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceButton(
      ThemeData theme, AppLocalizations lang, double price) {
    final movie = widget.movie;
    final isRental = movie.isRental ?? false;

    return GestureDetector(
      onTap: () => movie.type!.toLowerCase() == 'series'
          ? _openDetails()
          : isRental
              ? _playMovie()
              : _showCupertinoDialog(context, movie),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: theme.primaryColor.withOpacity(0.9),
        ),
        child: Text(
          movie.type!.toLowerCase() == 'series'
              ? isRental
                  ? "Watch Series"
                  : 'Rent Series'
              : isRental
                  ? movie.type?.toLowerCase() == "movie"
                      ? lang.watchMovie
                      : lang.watchSeries
                  : "₹ $price",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  void _openDetails() {
    final movie = widget.movie;

    if (movie.id == null || movie.type == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => movie.isFeatured == true
            ? TrailerPage(
                trailerUrl: movie.trailerUrl??"",
                isTrailerUrl: true,
                content: movie)
            : movie.type!.toLowerCase() == 'movie'
                ? MovieDetailsPage(movieId: movie.id!)
                : SeriesDetailsPage(seriesId: movie.id!, content: movie),
      ),
    );
  }

  void _playMovie() {
    final movie = widget.movie;
    if (movie.contentUrl == null || movie.id == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayMediaPage(
          videoUrl: movie.contentUrl!,
          content: movie,
          seasonIndex: 0,
          episodeIndex: 0,
          seasons: [],
        ),
      ),
    ).then((refresh) {
      if (refresh == true) {
        context.read<DashboardProvider>().getContinueWatchedMovieList();
      }
    });

  }

  void _showCupertinoDialog(BuildContext context, Content movie) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('₹ ${movie.price ?? 0}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Text(
              '${lang.rentDuration}: ${movie.rentlDuration ?? 'NA'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.canvasColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Do you want to rent ${movie.title ?? ''}?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            textStyle: TextStyle(color: theme.canvasColor),
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            textStyle: TextStyle(color: theme.primaryColor),
            child: const Text("Continue"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MovieBillingPage(movie: movie),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _optionButton(BuildContext context, Content movie) {
    final theme = Theme.of(context);
    final bool isSeries = movie.type?.toLowerCase() == "series";

    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bool isBookmarked =
        bookmarkProvider.isBookmarkedLocally(movie.id ?? 0);

    final ValueNotifier<bool> isDialOpen = ValueNotifier(false);
    final TextEditingController countController = TextEditingController();

    return Positioned(
      top: 12,
      right: 12,
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
          /// 🔖 Bookmark
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
                  bookmarkProvider.isBookmarkedLocally(movie.id ?? 0);

              await bookmarkProvider.toggleBookmark(movie);

              CustomToast.show(
                context,
                wasBookmarked
                    ? "${movie.title} removed from bookmarks"
                    : "${movie.title} added to bookmarks",
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
              _shareMovie(context, movie);
            },
          ),

          /// 🎁 Gift (movies only)
          if (!isSeries)
            SpeedDialChild(
              label: "Gift",
              labelBackgroundColor: theme.cardColor,
              labelStyle: TextStyle(
                color: theme.canvasColor,
                fontSize: 10,
              ),
              child:
                  const Icon(LucideIcons.gift, size: 14, color: Colors.white),
              backgroundColor: theme.primaryColor,
              onTap: () {
                isDialOpen.value = false;
                _showGiftDialog(context, movie, countController);
              },
            ),
        ],
      ),
    );
  }

  void _shareMovie(BuildContext context, Content movie) async {
    final String shareText = '''
🎬 ${movie.title ?? ''}

${movie.description ?? ''}

▶️ Watch here:
${movie.trailerUrl?.isNotEmpty == true ? movie.trailerUrl : movie.contentUrl ?? ''}

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
        subject: movie.title ?? "Movie",
      );
    }
  }

  void _showGiftDialog(
    BuildContext context,
    Content movie,
    TextEditingController countController,
  ) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          insetPadding: const EdgeInsets.all(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: ResponsiveWidget.isMobile(context) ? double.infinity : 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.gift,
                          color: theme.primaryColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        "Gift Movie",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "How many people do you want to gift this movie to?",
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.canvasColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    controller: countController,
                    hintText: "Recipients",
                    isDigits: true,
                    textInputType: TextInputType.number,
                    backgroundColor: theme.scaffoldBackgroundColor,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final count =
                              int.tryParse(countController.text.trim());
                          if (count == null || count <= 0) {
                            CustomToast.show(
                              context,
                              'Enter a valid number',
                              isSuccess: false,
                            );
                            return;
                          }

                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MovieBillingPage(
                                movie: movie,
                                giftCount: count,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Continue",
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
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
  }
}
