import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:provider/provider.dart';

import 'package:ott/app/provider/ThemeProvider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/data/models/content.dart';
import '../../provider/playMediaProvider.dart';

class PlayMediaPage extends StatefulWidget {
  final Content? content;
  final int? seasonIndex;
  final int? episodeIndex;
  final List<SeasonEntity>? seasons;
  final String videoUrl;

  const PlayMediaPage({
    super.key,
    required this.videoUrl,
    this.content,
    this.seasonIndex,
    this.episodeIndex,
    this.seasons,
  });

  @override
  State<PlayMediaPage> createState() => _PlayMediaPageState();
}

class _PlayMediaPageState extends State<PlayMediaPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Timer? _progressTimer;

  bool _loading = true;
  bool _handlingEnd = false;
  Duration _lastSavedPosition = Duration.zero;
  bool _wakelockEnabled = false;
  bool _isDisposed = false;
  bool _isExiting = false;
  int _setupToken = 0;

  bool get _isSeries =>
      widget.content?.type?.toLowerCase() == "series" &&
      widget.seasons != null &&
      widget.episodeIndex != null;

  @override
  void initState() {
    super.initState();
    _setupPlayer(widget.videoUrl);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _addView();
    });
  }

  // ================= ADD VIEW =================

  void _addView() {
    if (widget.content?.id == null) return;

    context.read<PlayMediaProvider>().addView(
          mediaId: _isSeries ? widget.episodeIndex! : widget.content!.id!,
          isSeries: _isSeries,
        );
  }

  // ================= PLAYER SETUP =================

  Future<void> _setupPlayer(String url) async {
    final token = ++_setupToken;

    if (mounted) {
      setState(() => _loading = true);
    }

    _progressTimer?.cancel();
    await _disposePlayer(saveProgress: false);
    if (_isDisposed || !mounted || token != _setupToken) return;

    // 🔑 Give MIUI time to release decoder
    await Future.delayed(const Duration(milliseconds: 500));
    if (_isDisposed || !mounted || token != _setupToken) return;

    debugPrint("VIDEO URL => $url");

    final controller = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await controller.initialize();
    } catch (e) {
      debugPrint("VIDEO INIT ERROR => $e");
      await controller.dispose();
      return;
    }

    if (_isDisposed || !mounted || token != _setupToken) {
      await controller.dispose();
      return;
    }

    if (controller.value.hasError) {
      debugPrint(
        "VIDEO ERROR => ${controller.value.errorDescription}",
      );
    }

    controller.addListener(_videoListener);
    _videoController = controller;

    _chewieController = ChewieController(
      videoPlayerController: controller,
      autoPlay: false, // we already call play()
      looping: false,
      allowFullScreen: true,
      allowPlaybackSpeedChanging: false,
      deviceOrientationsOnEnterFullScreen: const [
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ],
      deviceOrientationsAfterFullScreen: const [
        DeviceOrientation.portraitUp,
      ],
    );

    if (mounted && token == _setupToken) {
      setState(() => _loading = false);
    }

    await _resumeAndPlay(token);
  }

  Future<void> _resumeAndPlay(int token) async {
    if (_videoController == null || !mounted) return;
    if (_isDisposed || token != _setupToken) return;

    await _videoController!.setVolume(1.0);

    final provider = context.read<PlayMediaProvider>();
    final resumeSeconds = _isSeries
        ? provider.getLocalResume(
            contentId: widget.content!.id!,
            seasonId: widget.seasonIndex,
            episodeId: widget.episodeIndex,
          )
        : widget.content?.watchedSeconds ?? 0;

    if (resumeSeconds > 5) {
      await _videoController!.seekTo(Duration(seconds: resumeSeconds));
    }

    await _videoController!.play();
    if (_isDisposed || token != _setupToken) return;

    _progressTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _saveProgress(),
    );
  }

  // ================= VIDEO LISTENER =================
  void _videoListener() {
    if (_isDisposed || !mounted) return;
    if (_videoController == null || _handlingEnd) return;

    final value = _videoController!.value;

    // 🔋 wakelock
    if (value.isPlaying && !_wakelockEnabled) {
      WakelockPlus.enable();
      _wakelockEnabled = true;
    } else if (!value.isPlaying && _wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }

    // ▶ SAVE EVERY 15s WHILE PLAYING
    if (value.isPlaying &&
        (value.position - _lastSavedPosition).inSeconds >= 15) {
      _saveProgress();
    }

    // ▶ SAVE WHEN PAUSED
    if (!value.isPlaying &&
        value.position > Duration.zero &&
        value.position != _lastSavedPosition) {
      _saveProgress();
    }

    // ▶ AUTO NEXT EPISODE
    if (_isSeries &&
        value.duration.inSeconds > 0 &&
        value.position >= value.duration) {
      _handlingEnd = true;
      _playNextEpisode();
    }
  }

  // ================= SAVE PROGRESS =================

  void _saveProgress() {
    if (_videoController == null || widget.content?.id == null) return;

    final position = _videoController!.value.position;
    final duration = _videoController!.value.duration;

    if (duration.inSeconds == 0) return;

    _lastSavedPosition = position;

    debugPrint(
      "SAVE PROGRESS => ${position.inSeconds}s / ${duration.inSeconds}s",
    );

    context.read<PlayMediaProvider>().saveLocalResume(
          contentId: widget.content!.id!,
          seasonId: _isSeries ? widget.seasonIndex : null,
          episodeId: _isSeries ? widget.episodeIndex : null,
          seconds: position.inSeconds,
        );

    context.read<PlayMediaProvider>().saveContinueWatching(
          contentId: widget.content!.id!,
          seasonId: _isSeries ? widget.seasonIndex : null,
          episodeId: _isSeries ? widget.episodeIndex : null,
          position: position,
          duration: duration,
        );
  }

  // ================= AUTO NEXT =================

  Future<void> _playNextEpisode() async {
    if (!_isSeries ||
        widget.seasons == null ||
        widget.seasonIndex == null ||
        widget.episodeIndex == null) {
      return;
    }

    final provider = context.read<PlayMediaProvider>();

    final next = provider.getNextEpisode(
      seasons: widget.seasons!,
      seasonId: widget.seasonIndex!,
      episodeId: widget.episodeIndex!,
    );

    if (next == null) {
      Navigator.pop(context);
      return;
    }

    _handlingEnd = false;
    await _setupPlayer(next.videoUrl ?? "");
  }

  // ================= DISPOSE =================

  @override
  void dispose() {
    _isDisposed = true;
    _setupToken++;
    _disposePlayerSync(saveProgress: true);
    super.dispose();
  }

  Future<void> _disposePlayer({bool saveProgress = true}) async {
    if (saveProgress) {
      _saveProgress();
    }
    _progressTimer?.cancel();
    _progressTimer = null;

    final controller = _videoController;
    _videoController = null;

    if (controller != null) {
      controller.removeListener(_videoListener);
      try {
        await controller.pause();
      } catch (_) {}
      try {
        await controller.setVolume(0.0);
      } catch (_) {}
      await controller.dispose();
    }

    _chewieController?.dispose();
    _chewieController = null;

    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
  }

  void _disposePlayerSync({bool saveProgress = true}) {
    if (saveProgress) {
      _saveProgress();
    }
    _progressTimer?.cancel();
    _progressTimer = null;

    final controller = _videoController;
    _videoController = null;

    if (controller != null) {
      controller.removeListener(_videoListener);
      try {
        controller.pause();
      } catch (_) {}
      try {
        controller.setVolume(0.0);
      } catch (_) {}
      controller.dispose();
    }

    _chewieController?.dispose();
    _chewieController = null;

    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
  }

  Future<void> _handleExit() async {
    if (_isExiting) return;
    _isExiting = true;
    await _disposePlayer(saveProgress: true);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().getTheme;

    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black, // important for video
        appBar: ResponsiveWidget.isDesktop(context)
            ? null
            : AppBar(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                title: Text(
                  widget.content?.title ?? "",
                  style: const TextStyle(color: Colors.white),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _handleExit,
                ),
              ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ResponsiveWidget.isDesktop(context)
                ? _desktopPlayer()
                : _mobilePlayer(),
      ),
    );
  }

  Widget _mobilePlayer() {
    return SizedBox.expand(
      child: _playerSurface(),
    );
  }

  Widget _desktopPlayer() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox.expand(
        child: _playerSurface(),
      ),
    );
  }

  Widget _playerSurface() {
    if (_videoController == null ||
        !_videoController!.value.isInitialized ||
        _chewieController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SizedBox.expand(
      // 🔥 CRITICAL
      child: Chewie(controller: _chewieController!),
    );
  }
}
