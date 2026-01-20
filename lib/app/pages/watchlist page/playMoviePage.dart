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

class PlayMediaPage extends StatefulWidget {
  final String title;
  final int mediaId; // movieId or episodeId
  final String videoUrl;
  final Content? content; // optional (movie or parent series)

  const PlayMediaPage({
    super.key,
    required this.title,
    required this.mediaId,
    required this.videoUrl,
    this.content,
  });

  @override
  State<PlayMediaPage> createState() => _PlayMediaPageState();
}

class _PlayMediaPageState extends State<PlayMediaPage> {
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
    if (widget.content != null) {
      await Provider.of<DashboardProvider>(context, listen: false)
          .getContentById(widget.content!.id!);
    }

    await Provider.of<VideoProvider>(context, listen: false)
        .getRatingReview(widget.mediaId);
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
      deviceOrientationsAfterFullScreen: const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ],
      deviceOrientationsOnEnterFullScreen: const [
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
    return DateFormat('yyyy-MM-dd')
        .format(DateTime.fromMillisecondsSinceEpoch(ms));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context).getTheme;

    if (_chewieController == null) {
      _setupPlayer(widget.videoUrl);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: ResponsiveWidget.isDesktop(context)
            ? const Text('')
            : Text(widget.title, style: TextStyle(color: theme.canvasColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveWidget.isMobile(context)
              ? _mobileUI(context)
              : _desktopUI(context),
    );
  }

  Widget _mobileUI(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : const SizedBox(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _ratingReviewSection(),
          ),
        ),
      ],
    );
  }

  Widget _desktopUI(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : const SizedBox(),
                ),
                _ratingReviewSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingReviewSection() {
    final theme = Theme.of(context);
    return Consumer<VideoProvider>(builder: (context, provider, child) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (provider.reviewController.text.trim().isEmpty) {
                CustomToast.show(context, "Write a comment", isSuccess: false);
                return;
              }

              final result = await provider.saveRatingReview(widget.mediaId);
              if (result['success'] == true) {
                provider.reviewController.clear();
                CustomToast.show(context, "Review submitted", isSuccess: true);
                await provider.getRatingReview(widget.mediaId);
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
                      Text(_formatEpoch(r.createdAt),
                          style: const TextStyle(fontSize: 12)),
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
