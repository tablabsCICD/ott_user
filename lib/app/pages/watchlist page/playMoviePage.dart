// play_movie_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/videoProvider.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class PlayMoviePage extends StatefulWidget {
  final int movieId;
  const PlayMoviePage({Key? key, required this.movieId}) : super(key: key);

  @override
  State<PlayMoviePage> createState() => _PlayMoviePageState();
}

class _PlayMoviePageState extends State<PlayMoviePage> {
  bool _isLoading = true;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _fetchData();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  Future<void> _fetchData() async {
    await Provider.of<DashboardProvider>(context, listen: false)
        .getContentById(widget.movieId);

    await Provider.of<VideoProvider>(context, listen: false)
        .getRatingReview(widget.movieId);
  }

  void _setupPlayer(String url) {
    if (url.isEmpty) return;

    _videoController?.dispose();
    _chewieController?.dispose();

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));

    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoInitialize: true,
      autoPlay: true,
      looping: false,
      allowMuting: true,
      allowPlaybackSpeedChanging: true,
      zoomAndPan: true,

      // IMPORTANT FIXES:
      deviceOrientationsAfterFullScreen: [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      deviceOrientationsOnEnterFullScreen: [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      allowFullScreen: true,

      materialProgressColors: ChewieProgressColors(
        playedColor: Colors.redAccent,
        handleColor: Colors.white,
        backgroundColor: Colors.white12,
        bufferedColor: Colors.white24,
      ),
    );

    // CRITICAL: add this to rebuild gestures layer
    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String _formatEpoch(int? ms) {
    if (ms == null) return '';
    try {
      return DateFormat('yyyy-MM-dd')
          .format(DateTime.fromMillisecondsSinceEpoch(ms));
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;
    final content = Provider.of<DashboardProvider>(context).content;

    if (content == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Movie Details'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // keep your original URL logic EXACTLY
    final videoUrl = content.contentUrl ?? "";

    // Setup chewie/video_player
    if (_chewieController == null) {
      _setupPlayer(videoUrl);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        title: ResponsiveWidget.isDesktop(context)
            ? const Text('')
            : Text(
                content.title ?? "",
                style: TextStyle(color: theme.canvasColor),
              ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (ResponsiveWidget.isMobile(context)) {
                  return _mobileUI(context, content);
                }
                return _desktopUI(context, content);
              },
            ),
    );
  }

  // ----------------- MOBILE UI -----------------

  Widget _mobileUI(BuildContext context, Content content) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : _posterFallback(content),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _movieDetails(context, content),
          ),
        ),
      ],
    );
  }

  // ----------------- DESKTOP/TABLET UI -----------------

  Widget _desktopUI(BuildContext context, Content content) {
    final isDesktop = ResponsiveWidget.isDesktop(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AspectRatio(
                  aspectRatio: isDesktop ? 16 / 9 : 4 / 3,
                  child: _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : _posterFallback(content),
                ),
                _ratingReviewSection(content),
              ],
            ),
          ),
          SizedBox(
            width: 20,
          ),
          Expanded(
            flex: 9,
            child: SingleChildScrollView(
              child: _movieDetails(context, content),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
    );
  }

  // ----------------- POSTER FALLBACK -----------------

  Widget _posterFallback(Content content) {
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      child: content.posterUrlList != null && content.posterUrlList!.isNotEmpty
          ? Image.network(content.posterUrlList!.first, fit: BoxFit.cover)
          : Center(
              child: Icon(Icons.movie,
                  color: theme.canvasColor.withOpacity(0.7), size: 40),
            ),
    );
  }

  // ----------------- DETAILS SECTION -----------------

  Widget _movieDetails(BuildContext context, Content content) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            content.title ?? '',
            maxLines: 2,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              overflow: TextOverflow.ellipsis,
              color: theme.canvasColor,
            ),
          ),

          const SizedBox(height: 10),

          // Rating row
          Row(
            children: [
              StarRatingWidget(
                rating: double.parse(content.ratings!.toStringAsFixed(1)),
                starSize: 20,
                textSize: 14,
              ),
              const SizedBox(width: 6),
              Text(
                "(${content.ratingCount ?? 0})",
                style: TextStyle(color: theme.canvasColor),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _ageBadge(content.ageRating),

          const SizedBox(height: 16),
          Text(
            content.description ?? "No description available",
            maxLines: 8,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: theme.canvasColor),
          ),

          const SizedBox(height: 20),
          _quickInfo(context, content),

          const SizedBox(height: 20),
          _castSection(content),

          const SizedBox(height: 20),
          _detailsList(content),

          const SizedBox(height: 20),
          //_ratingReviewSection(content),
        ],
      ),
    );
  }

  // ----------------- AGE BADGE -----------------

  Widget _ageBadge(String? age) {
    final theme = Theme.of(context);
    if (age == null || age.isEmpty) return const SizedBox();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        age,
        style: TextStyle(color: theme.canvasColor),
      ),
    );
  }

  // ----------------- ACTION BUTTONS -----------------

  // ----------------- QUICK INFO -----------------

  Widget _quickInfo(BuildContext context, Content content) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (content.runtime != null) _pill("${content.runtime} min"),
        if (content.releaseDate != null) _pill(content.releaseDate!),
      ],
    );
  }

  Widget _pill(String text) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: TextStyle(color: theme.canvasColor)),
    );
  }

  // ----------------- CAST SECTION -----------------

  Widget _castSection(Content content) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;

    final cast = content.castList ?? [];
    if (cast.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Cast",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.canvasColor,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, i) {
              return Column(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: theme.cardColor,
                    child: Icon(
                      Icons.person,
                      color: theme.canvasColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 80,
                    child: Text(
                      cast[i],
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.canvasColor),
                    ),
                  )
                ],
              );
            },
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: cast.length,
          ),
        ),
      ],
    );
  }

  // ----------------- DETAILS LIST -----------------

  Widget _detailsList(Content content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _detail("Director", content.directorList?.join(", ") ?? "Unknown"),
        _detail("Genres", content.genreList?.join(", ") ?? "N/A"),
        _detail("Languages", content.languageList?.join(", ") ?? "N/A"),
        _detail("Age Rating", content.ageRating ?? "N/A"),
      ],
    );
  }

  Widget _detail(String title, String v) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text.rich(
        TextSpan(
          style: const TextStyle(color: Colors.white70),
          children: [
            TextSpan(
              text: '$title: ',
              style: TextStyle(
                color: theme.primaryColor,
              ),
            ),
            TextSpan(
              text: '$v',
              style: TextStyle(
                color: theme.canvasColor,
              ),
            ),
          ],
        ),
      ), //Text("$title: $v", style: const TextStyle(color: Colors.white70)),
    );
  }

  // ----------------- RATING / REVIEW SECTION -----------------

  Widget _ratingReviewSection(Content content) {
    final theme = Theme.of(context);
    return Consumer<VideoProvider>(builder: (context, provider, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rate your experience",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: theme.canvasColor,
            ),
          ),
          const SizedBox(height: 8),
          StarRatingWidget(rating: provider.rating, starSize: 22, textSize: 14),
          const SizedBox(height: 8),
          TextField(
            controller: provider.reviewController,
            maxLines: 3,
            style: TextStyle(color: theme.canvasColor),
            decoration: InputDecoration(
              hintText: "Write your feedback...",
              filled: true,
              fillColor: theme.cardColor,
              hintStyle: TextStyle(color: theme.canvasColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white, // Text/Icon color
            ),
            onPressed: () async {
              if (provider.reviewController.text.trim().isEmpty) {
                CustomToast.show(context, "Write a comment", isSuccess: false);
                return;
              }

              final result = await provider.saveRatingReview(content.id!);
              if (result['success'] == true) {
                provider.reviewController.clear();
                CustomToast.show(context, "Review submitted", isSuccess: true);
                await provider.getRatingReview(content.id!);
              } else {
                CustomToast.show(context, "Failed to submit", isSuccess: false);
              }
            },
            child: const Text("Submit Review"),
          ),
          const SizedBox(height: 16),
          ...provider.reviewList.map((r) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundImage: r.userProfile != null
                            ? NetworkImage(r.userProfile!)
                            : null,
                        child: r.userProfile == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        r.username ?? "User",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.canvasColor),
                      ),
                      const Spacer(),
                      Text(
                        _formatEpoch(r.createdAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  StarRatingWidget(
                      rating: (r.rating ?? 0).toDouble(),
                      starSize: 16,
                      textSize: 12),
                  const SizedBox(height: 8),
                  Text(r.title ?? "",
                      style: TextStyle(color: theme.canvasColor)),
                ],
              ),
            );
          })
        ],
      );
    });
  }
}
