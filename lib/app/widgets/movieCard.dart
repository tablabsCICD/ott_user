import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/pages/watchlist%20page/playMoviePage.dart';
import 'package:ott/app/pages/wallet%20page/BillingPage.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/data/models/response/saveUserContent.dart';
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

  void _initializeVideo() async {
    final trailerUrl = widget.movie.trailerUrl;
    if (trailerUrl != null && trailerUrl.isNotEmpty) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(trailerUrl));
      await _videoController!.initialize();
      _videoController!
        ..setLooping(true)
        ..setVolume(1.0); //(1.0);
      setState(() => _isVideoInitialized = true);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    setState(() => _isHovered = hovering);
    if (hovering) {
      _videoController?.play();
    } else {
      _videoController?.pause();
      _videoController?.seekTo(Duration.zero);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final posterUrl = widget.movie.posterUrlList?.firstOrNull;

    return MouseRegion(
      onEnter: (_) => _handleHover(true),
      onExit: (_) => _handleHover(false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => widget.movie.type!.toLowerCase() == 'movie'
                  ? MovieDetailsPage(
                      movieId: widget.movie.id!,
                    )
                  : SeriesDetailsPage(
                      seriesId: widget.movie.id!,
                      content: widget.movie,
                    ),
            ),
          );
        },
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
                flex: 6,
                child: SizedBox(
                  height: double.infinity,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: _isHovered && _isVideoInitialized
                        ? AspectRatio(
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
                                      allowScrubbing: true),
                                ),
                                Positioned(
                                  right: 1,
                                  top: 1,
                                  child: IconButton(
                                    icon: Icon(
                                      _isMuted
                                          ? Icons.volume_off
                                          : Icons.volume_up,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                    onPressed: _toggleMute,
                                  ),
                                )
                              ],
                            ),
                          )
                        : (posterUrl != null
                            ? Image.network(
                                posterUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.broken_image,
                                  color: theme.canvasColor.withOpacity(0.2),
                                  size: 40,
                                ),
                              )
                            : Icon(
                                Icons.broken_image,
                                color: theme.canvasColor.withOpacity(0.2),
                                size: 40,
                              )),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StarRatingWidget(
                            rating: double.parse(
                                    widget.movie.ratings!.toStringAsFixed(1)) ??
                                0.0,
                            starSize: 16,
                            textSize: 16,
                          ),
                          // Text.rich(
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          //   TextSpan(
                          //       style: TextStyle(
                          //         color: theme.canvasColor.withOpacity(0.7),
                          //         fontSize: 12,
                          //       ),
                          //       children: [
                          //         TextSpan(
                          //           text: '${widget.movie.ratings ?? '-'}',
                          //           style: TextStyle(
                          //               color: Colors.amber,
                          //               fontWeight: FontWeight.w600),
                          //         ),
                          //         TextSpan(
                          //           text:
                          //               ' (${widget.movie.ratingCount ?? '0'})',
                          //           style: TextStyle(
                          //             color: theme.canvasColor.withOpacity(0.7),
                          //             fontWeight: FontWeight.normal,
                          //             fontSize: 11,
                          //           ),
                          //         ),
                          //         // TextSpan(
                          //         //   text: ' | ',
                          //         //   style: TextStyle(
                          //         //     color: theme.canvasColor.withOpacity(0.7),
                          //         //     fontSize: 14,
                          //         //   ),
                          //         // ),
                          //         // TextSpan(
                          //         //   text: (widget.movie.genreList != null &&
                          //         //           widget.movie.genreList!.isNotEmpty)
                          //         //       ? widget.movie.genreList!.join(', ')
                          //         //       : 'N/A',
                          //         // )
                          //       ]),
                          // ),
                          const SizedBox(height: 4),
                          Text(
                            widget.movie.title ?? 'No Title',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.canvasColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            (widget.movie.genreList != null &&
                                    widget.movie.genreList!.isNotEmpty)
                                ? widget.movie.genreList!.join(', ')
                                : 'N/A',
                          ),
                          const SizedBox(height: 4),

                          // Text.rich(
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          //   TextSpan(
                          //       style: TextStyle(
                          //         color: theme.canvasColor.withOpacity(0.7),
                          //         fontSize: 12,
                          //       ),
                          //       children: [
                          //         TextSpan(
                          //           text: '${lang.director}: ',
                          //           style: TextStyle(
                          //             color: theme.primaryColor,
                          //             fontWeight: FontWeight.w600,
                          //           ),
                          //         ),
                          //         TextSpan(
                          //           text: (widget.movie.directorList != null &&
                          //                   widget
                          //                       .movie.directorList!.isNotEmpty)
                          //               ? widget.movie.directorList!.join(', ')
                          //               : 'N/A',
                          //         )
                          //       ]),
                          // ),
                          // const SizedBox(height: 1),
                          // Text.rich(
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          //   TextSpan(
                          //       style: TextStyle(
                          //         color: theme.canvasColor.withOpacity(0.7),
                          //         fontSize: 12,
                          //       ),
                          //       children: [
                          //         TextSpan(
                          //           text: '${lang.cast}: ',
                          //           style: TextStyle(
                          //             color: theme.primaryColor,
                          //             fontWeight: FontWeight.w600,
                          //           ),
                          //         ),
                          //         TextSpan(
                          //           text: (widget.movie.castList != null &&
                          //                   widget.movie.castList!.isNotEmpty)
                          //               ? widget.movie.castList!.join(', ')
                          //               : 'N/A',
                          //         )
                          //       ]),
                          // ),
                          // Text(
                          //   (widget.movie.directorList != null &&
                          //           widget.movie.directorList!.isNotEmpty)
                          //       ? "Director: ${widget.movie.directorList!.join(', ')}"
                          //       : 'N/A',
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     color: theme.canvasColor.withOpacity(0.7),
                          //   ),
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          // ),
                          // const SizedBox(height: 1),
                          // Text(
                          //   (widget.movie.castList != null &&
                          //           widget.movie.castList!.isNotEmpty)
                          //       ? "Cast: ${widget.movie.castList!.join(', ')}"
                          //       : 'N/A',
                          //   style: TextStyle(
                          //     fontSize: 12,
                          //     color: theme.canvasColor.withOpacity(0.7),
                          //   ),
                          //   maxLines: 1,
                          //   overflow: TextOverflow.ellipsis,
                          // ),
                          const SizedBox(height: 1),
                          Text.rich(
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            TextSpan(
                                style: TextStyle(
                                  color: theme.canvasColor.withOpacity(0.7),
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: widget.movie.releaseDate ?? '',
                                    style: TextStyle(
                                      color: theme.canvasColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' | ',
                                    style: TextStyle(
                                      color: theme.canvasColor.withOpacity(0.7),
                                      fontSize: 14,
                                    ),
                                  ),
                                  TextSpan(
                                    text: widget.movie.description ?? '',
                                    style: TextStyle(
                                      overflow: TextOverflow.ellipsis,
                                      fontSize: 12,
                                      color: theme.canvasColor.withOpacity(0.7),
                                    ),
                                  )
                                ]),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      right: 5,
                      top: 5,
                      child: GestureDetector(
                        onTap: () => widget.movie.isRental!
                            ? Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PlayMediaPage(
                                    title: widget.movie.title!,
                                    mediaId: widget.movie.id!,
                                    videoUrl: widget.movie.contentUrl!,
                                    content: widget.movie,
                                  ),
                                ),
                              )
                            : _showCupertinoDialog(context, widget.movie),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              10,
                            ),
                            color: theme.primaryColor.withOpacity(0.9),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 6.0,
                              horizontal: 10,
                            ),
                            child: Row(
                              children: [
                                widget.movie.isRental!
                                    ? SizedBox()
                                    : SizedBox(
                                        height: 15,
                                        width: 15,
                                        child: Image.asset(
                                          ImageConstant.coin,
                                        ),
                                      ),
                                SizedBox(
                                  width: 2,
                                ),
                                Text(
                                  widget.movie.isRental!
                                      ? widget.movie.type!.toLowerCase() ==
                                              "movie"
                                          ? lang.watchMovie
                                          : lang.watchSeries
                                      : "${widget.movie.price ?? 0}",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 15,
              width: 15,
              child: Image.asset(
                ImageConstant.coin,
              ),
            ),
            SizedBox(
              width: 2,
            ),
            Text('${movie.price}'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 10,
            ),
            Text(
              '${lang.rentDuration}: ${movie.rentlDuration ?? 'NA'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.canvasColor, // Theme text color
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Text(
              'Do you want to rent ${movie.title ?? ''}?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.primaryColor, // Theme text color
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            textStyle: TextStyle(color: theme.canvasColor),
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            textStyle: TextStyle(color: theme.primaryColor),
            child: const Text("Continue"),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BillingPage(
                    movie: movie,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
