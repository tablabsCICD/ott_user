import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:ott/app/pages/DisplayTrailer.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/pages/watchlist%20page/playMoviePage.dart';
import 'package:ott/app/pages/wallet%20page/MovieBillingPage.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
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

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: _openDetails,
        child: Container(
          width: 300,
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Expanded(
                flex: 8,
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: _buildMediaPreview(posterUrl, theme, widget.movie),
                ),
              ),
              Expanded(
                flex: 4,
                child: _buildContentSection(theme, lang),
              ),
            ],
          ),
        ),
      ),
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
              top: 5,
              child: IconButton(
                icon: Icon(
                  _isMuted ? Icons.volume_off : Icons.volume_up,
                  color: Colors.white.withOpacity(0.7),
                ),
                onPressed: _toggleMute,
              ),
            ),
            _actionButtons(context, content)
          ],
        ),
      );
    }

    return Stack(
      children: [
        posterUrl != null
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
              ),
        _actionButtons(context, content)
      ],
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
          child: movie.isFeatured == true
              ? Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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
                trailerUrl: movie.trailerUrl,
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
          title: movie.title ?? '',
          mediaId: movie.id!,
          videoUrl: movie.contentUrl!,
          content: movie,
        ),
      ),
    );
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

  Widget _actionButtons(BuildContext context, Content movie) {
    final theme = Theme.of(context);
    final TextEditingController _countController = TextEditingController();
    double iconSize = ResponsiveWidget.isMobile(context) ? 18 : 20;

    return Positioned(
        bottom: 5,
        right: 5,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _shareMovie(context, movie),
              child: Tooltip(
                message: "Share Movie",
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.share,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 5,
            ),
            movie.type!.toLowerCase() == "series"
                ? SizedBox()
                : GestureDetector(
                    onTap: () => showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) {
                        return Dialog(
                          backgroundColor: theme.cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          insetPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 24),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header
                                      Row(
                                        children: [
                                          Icon(LucideIcons.gift,
                                              color: theme.primaryColor,
                                              size: 28),
                                          const SizedBox(width: 10),
                                          Text(
                                            "Gift This Movie",
                                            style: theme.textTheme.titleLarge
                                                ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),

                                      // Description
                                      Text(
                                        "Enter how many people you’d like to gift this movie to.",
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                          color: theme.canvasColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),

                                      // Input field
                                      CustomTextField(
                                        backgroundColor:
                                            theme.scaffoldBackgroundColor,
                                        isDigits: true,
                                        controller: _countController,
                                        hintText: "Number of recipients",
                                        textInputType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 24),

                                      // Action buttons
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: Text(
                                              "Cancel",
                                              style: TextStyle(
                                                  color: theme.canvasColor),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  theme.primaryColor,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                            ),
                                            onPressed: () {
                                              final count = int.tryParse(
                                                  _countController.text);
                                              if (count == null || count <= 0) {
                                                CustomToast.show(context,
                                                    'Please enter valid number',
                                                    isSuccess: false);
                                                return;
                                              }

                                              Navigator.pop(context);
                                              // _trailerController.pause?.call();
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      MovieBillingPage(
                                                    movie: movie,
                                                    giftCount: count,
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              "Continue",
                                              style: TextStyle(
                                                  color: Colors.white),
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
                    ),
                    child: Tooltip(
                      message: "Gift Movie",
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          LucideIcons.gift,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
          ],
        ));
  }

  void _shareMovie(BuildContext context, Content movie) async {
    final String shareText = '''
🎬 ${movie.title ?? ''}

${movie.description ?? ''}

▶️ Watch here:
${movie.trailerUrl?.isNotEmpty == true ? movie.trailerUrl : movie.contentUrl ?? ''}

📲 Download OTT Media House App now!
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
}
