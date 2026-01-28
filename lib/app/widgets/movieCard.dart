import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/pages/DisplayTrailer.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/pages/watchlist%20page/playMoviePage.dart';
import 'package:ott/app/pages/wallet%20page/BillingPage.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
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
                  child: _buildMediaPreview(posterUrl, theme),
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

  Widget _buildMediaPreview(String? posterUrl, ThemeData theme) {
    if (_isHovered && _isVideoInitialized && _videoController != null) {
      return AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          children: [
            VideoPlayer(_videoController!),
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
            )
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
              StarRatingWidget(
                rating: rating,
                starSize: 16,
                textSize: 16,
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
                maxLines: 3,
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
              // Text(
              //   movie.genreList?.join(', ') ?? 'N/A',
              //   maxLines: 1,
              //   overflow: TextOverflow.ellipsis,
              // ),
              // const SizedBox(height: 4),
              // Text.rich(
              //   maxLines: 3,
              //   overflow: TextOverflow.ellipsis,
              //   TextSpan(
              //     style: TextStyle(
              //       color: theme.canvasColor.withOpacity(0.7),
              //       fontSize: 12,
              //     ),
              //     children: [
              //       TextSpan(text: movie.releaseDate ?? ''),
              //       const TextSpan(text: ' | '),
              //       TextSpan(text: movie.description ?? ''),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
        Positioned(
          right: 6,
          top: 6,
          child: movie.isFeatured == true
              ? SizedBox()
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
        child: Row(
          children: [
            //if (!isRental)
            // SizedBox(
            //   height: 14,
            //   width: 14,
            //   child: Image.asset(ImageConstant.coin),
            // ),
            //const SizedBox(width: 4),
            Text(
              movie.type!.toLowerCase() == 'series'
                  ? 'Watch Series'
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
          ],
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
                  builder: (_) => BillingPage(movie: movie),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
