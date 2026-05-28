import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:ott/data/models/seriesModel.dart';
import 'package:provider/provider.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart' as youtube;

import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import '../../../provider/offline_download_provider.dart';
import '../../../provider/playMediaProvider.dart';

String? _extractYoutubeId(String urlOrId) {
  final value = urlOrId.trim();
  if (value.isEmpty) return null;

  final converted = youtube.YoutubePlayer.convertUrlToId(value);
  if (converted != null && converted.isNotEmpty) return converted;

  final looksLikeVideoId = RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(value);
  return looksLikeVideoId ? value : null;
}

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

class _PlayMediaPageState extends State<PlayMediaPage>
    with WidgetsBindingObserver {
  Player? _player;
  VideoController? _videoController;
  youtube.YoutubePlayerController? _youtubeController;
  final List<StreamSubscription<dynamic>> _playerSubscriptions = [];
  Timer? _progressTimer;

  bool _loading = true;
  bool _hasPlaybackError = false;
  bool _handlingEnd = false;
  Duration _lastSavedPosition = Duration.zero;
  bool _wakelockEnabled = false;
  bool _isDisposed = false;
  bool _isExiting = false;
  int _setupToken = 0;
  bool _isOfflinePlayback = false;

  bool get _isSeries =>
      widget.content?.type?.toLowerCase() == "series" &&
      widget.seasons != null &&
      widget.episodeIndex != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_startFullscreenPlayback());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_player?.pause());
      _youtubeController?.pause();
      _saveProgress();
    }
  }

  Future<void> _enterLandscapePlayback() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restorePortraitPlayback() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  Future<void> _startFullscreenPlayback() async {
    await _enterLandscapePlayback();
    if (!mounted || _isDisposed) return;

    await _preparePlayback();
    if (!mounted || _isDisposed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        _addView();
      }
    });
  }

  void _addView() {
    if (widget.content?.id == null) return;

    context.read<PlayMediaProvider>().addView(
          mediaId: _isSeries ? widget.episodeIndex! : widget.content!.id!,
          isSeries: _isSeries,
        );
  }

  Future<void> _preparePlayback() async {
    String sourceUrl = widget.videoUrl.trim();
    if (sourceUrl.isEmpty) {
      _showPlaybackError();
      return;
    }

    final youtubeId = _extractYoutubeId(sourceUrl);

    if (youtubeId != null && youtubeId.isNotEmpty) {
      _isOfflinePlayback = false;
      await _setupYoutubePlayer(youtubeId);
      return;
    }

    final content = widget.content;
    if (content != null) {
      final offlinePath =
          await context.read<OfflineDownloadProvider>().getOfflinePath(content);
      if (offlinePath != null && offlinePath.isNotEmpty) {
        sourceUrl = offlinePath;
        _isOfflinePlayback = true;
      } else {
        _isOfflinePlayback = false;
      }
    }

    await _setupPlayer(sourceUrl, playFromFile: _isOfflinePlayback);
  }

  void _showPlaybackError() {
    if (!mounted || _isDisposed) return;

    setState(() {
      _loading = false;
      _hasPlaybackError = true;
    });
  }

  Future<void> _setupYoutubePlayer(String videoId) async {
    final token = ++_setupToken;

    if (mounted) {
      setState(() {
        _loading = true;
        _hasPlaybackError = false;
      });
    }

    _progressTimer?.cancel();
    await _disposePlayer(saveProgress: false);
    if (_isDisposed || !mounted || token != _setupToken) return;

    final provider = context.read<PlayMediaProvider>();
    final resumeSeconds = _isSeries
        ? provider.getLocalResume(
            contentId: widget.content!.id!,
            seasonId: widget.seasonIndex,
            episodeId: widget.episodeIndex,
          )
        : widget.content?.watchedSeconds ?? 0;

    final controller = youtube.YoutubePlayerController(
      initialVideoId: videoId,
      flags: youtube.YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        loop: false,
        startAt: resumeSeconds > 5 ? resumeSeconds : 0,
      ),
    );

    controller.addListener(() {
      if (_isDisposed || !mounted || token != _setupToken) return;

      final value = controller.value;
      _handlePlayingChanged(value.isPlaying);

      if (value.hasError) {
        setState(() => _hasPlaybackError = true);
      }

      if (value.playerState == youtube.PlayerState.ended) {
        _handlePlaybackCompleted();
      }

      setState(() {});
    });

    if (_isDisposed || !mounted || token != _setupToken) {
      controller.dispose();
      return;
    }

    _youtubeController = controller;

    if (mounted && token == _setupToken) {
      setState(() => _loading = false);
    }

    _progressTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _saveProgress(),
    );
  }

  Future<void> _setupPlayer(String url, {bool playFromFile = false}) async {
    final token = ++_setupToken;

    if (mounted) {
      setState(() {
        _loading = true;
        _hasPlaybackError = false;
      });
    }

    _progressTimer?.cancel();
    await _disposePlayer(saveProgress: false);
    if (_isDisposed || !mounted || token != _setupToken) return;

    await Future.delayed(const Duration(milliseconds: 250));
    if (_isDisposed || !mounted || token != _setupToken) return;

    debugPrint("MEDIA SOURCE => $url");

    final player = Player();
    final controller = VideoController(player);

    try {
      // media_kit is the underlying playback engine; the route keeps the
      // existing fullscreen, resume, continue-watching and auto-next behavior.
      await player.open(
        Media(playFromFile ? File(url).uri.toString() : url),
        play: false,
      );
      await player.setVolume(100);
    } catch (error) {
      debugPrint("MEDIA_KIT INIT ERROR => $error");
      await player.dispose();
      if (mounted && token == _setupToken) {
        setState(() {
          _loading = false;
          _hasPlaybackError = true;
        });
      }
      return;
    }

    if (_isDisposed || !mounted || token != _setupToken) {
      await player.dispose();
      return;
    }

    _player = player;
    _videoController = controller;
    _bindPlayerStreams(player);

    if (mounted && token == _setupToken) {
      setState(() => _loading = false);
    }

    await _resumeAndPlay(token);
  }

  void _bindPlayerStreams(Player player) {
    _playerSubscriptions
      ..add(player.stream.playing.listen((isPlaying) {
        _handlePlayingChanged(isPlaying);
        if (mounted) setState(() {});
      }))
      ..add(player.stream.position.listen((_) => _handlePositionChanged()))
      ..add(player.stream.duration.listen((_) {
        if (mounted) setState(() {});
      }))
      ..add(player.stream.completed.listen((completed) {
        if (completed) _handlePlaybackCompleted();
      }))
      ..add(player.stream.error.listen((error) {
        debugPrint("MEDIA_KIT PLAYBACK ERROR => $error");
        if (mounted) {
          setState(() => _hasPlaybackError = true);
        }
      }));
  }

  Future<void> _resumeAndPlay(int token) async {
    if (_player == null || !mounted) return;
    if (_isDisposed || token != _setupToken) return;

    final provider = context.read<PlayMediaProvider>();
    await _player!.setVolume(100);

    final resumeSeconds = _isSeries
        ? provider.getLocalResume(
            contentId: widget.content!.id!,
            seasonId: widget.seasonIndex,
            episodeId: widget.episodeIndex,
          )
        : widget.content?.watchedSeconds ?? 0;

    if (resumeSeconds > 5) {
      await _player!.seek(Duration(seconds: resumeSeconds));
    }

    await _player!.play();
    if (_isDisposed || token != _setupToken) return;

    _progressTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _saveProgress(),
    );
  }

  void _handlePlayingChanged(bool isPlaying) {
    if (_isDisposed || !mounted) return;

    if (isPlaying && !_wakelockEnabled) {
      WakelockPlus.enable();
      _wakelockEnabled = true;
    } else if (!isPlaying && _wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
  }

  void _handlePositionChanged() {
    if (_isDisposed || !mounted || _player == null || _handlingEnd) return;

    final state = _player!.state;

    if (state.playing &&
        (state.position - _lastSavedPosition).inSeconds >= 15) {
      _saveProgress();
    }

    if (!state.playing &&
        state.position > Duration.zero &&
        state.position != _lastSavedPosition) {
      _saveProgress();
    }

    if (mounted) setState(() {});
  }

  void _handlePlaybackCompleted() {
    if (_handlingEnd || !_isSeries) return;
    _handlingEnd = true;
    unawaited(_playNextEpisode());
  }

  void _saveProgress() {
    if (widget.content?.id == null) return;

    final position =
        _youtubeController?.value.position ?? _player?.state.position;
    final duration =
        _youtubeController?.value.metaData.duration ?? _player?.state.duration;

    if (position == null || duration == null) return;

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
      if (mounted) Navigator.pop(context);
      return;
    }

    _handlingEnd = false;
    final nextUrl = next.videoUrl?.trim() ?? "";
    if (nextUrl.isEmpty) {
      _showPlaybackError();
      return;
    }

    final youtubeId = _extractYoutubeId(nextUrl);
    if (youtubeId != null && youtubeId.isNotEmpty) {
      await _setupYoutubePlayer(youtubeId);
    } else {
      await _setupPlayer(nextUrl);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _setupToken++;
    WidgetsBinding.instance.removeObserver(this);
    _disposePlayerSync(saveProgress: true);
    unawaited(_restorePortraitPlayback());
    super.dispose();
  }

  Future<void> _disposePlayer({bool saveProgress = true}) async {
    if (saveProgress) {
      _saveProgress();
    }
    _progressTimer?.cancel();
    _progressTimer = null;

    for (final subscription in _playerSubscriptions) {
      await subscription.cancel();
    }
    _playerSubscriptions.clear();

    final player = _player;
    final youtubeController = _youtubeController;
    _player = null;
    _videoController = null;
    _youtubeController = null;

    if (player != null) {
      try {
        await player.pause();
      } catch (_) {}
      try {
        await player.setVolume(0);
      } catch (_) {}
      await player.dispose();
    }

    youtubeController?.pause();
    youtubeController?.dispose();

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

    for (final subscription in _playerSubscriptions) {
      unawaited(subscription.cancel());
    }
    _playerSubscriptions.clear();

    final player = _player;
    final youtubeController = _youtubeController;
    _player = null;
    _videoController = null;
    _youtubeController = null;

    if (player != null) {
      try {
        player.pause();
      } catch (_) {}
      try {
        player.setVolume(0);
      } catch (_) {}
      player.dispose();
    }

    youtubeController?.pause();
    youtubeController?.dispose();

    if (_wakelockEnabled) {
      WakelockPlus.disable();
      _wakelockEnabled = false;
    }
  }

  Future<void> _handleExit() async {
    if (_isExiting) return;
    _isExiting = true;
    await _disposePlayer(saveProgress: true);
    await _restorePortraitPlayback();
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  KeyEventResult _handlePlaybackKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.mediaPlayPause) {
      _togglePlayback();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.mediaTrackNext) {
      _seekBy(const Duration(seconds: 10));
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.mediaTrackPrevious) {
      _seekBy(const Duration(seconds: -10));
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace) {
      unawaited(_handleExit());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  void _togglePlayback() {
    final youtubeController = _youtubeController;
    if (youtubeController != null) {
      if (youtubeController.value.isPlaying) {
        youtubeController.pause();
      } else {
        youtubeController.play();
      }
      return;
    }

    final player = _player;
    if (player == null) return;
    if (player.state.playing) {
      unawaited(player.pause());
    } else {
      unawaited(player.play());
    }
  }

  void _seekBy(Duration delta) {
    final youtubeController = _youtubeController;
    if (youtubeController != null) {
      final current = youtubeController.value.position;
      final duration = youtubeController.value.metaData.duration;
      final target = _clampDuration(current + delta, duration);
      youtubeController.seekTo(target);
      return;
    }

    final player = _player;
    if (player == null) return;
    final target = _clampDuration(
      player.state.position + delta,
      player.state.duration,
    );
    unawaited(player.seek(target));
  }

  Duration _clampDuration(Duration value, Duration max) {
    if (value < Duration.zero) return Duration.zero;
    if (max > Duration.zero && value > max) return max;
    return value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().getTheme;

    return WillPopScope(
      onWillPop: () async {
        await _handleExit();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: null,
        body: Focus(
          autofocus: true,
          onKeyEvent: _handlePlaybackKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: _loading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: theme.primaryColor,
                        ),
                      )
                    : _hasPlaybackError
                        ? const Center(
                            child: Text(
                              'Video unavailable',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ResponsiveWidget.isDesktop(context)
                            ? _desktopPlayer()
                            : _mobilePlayer(),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: SafeArea(child: _backButton()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton() {
    return OttTvFocus(
      onTap: _handleExit,
      borderRadius: BorderRadius.circular(18),
      scale: 1.1,
      child: Material(
        color: Colors.black.withOpacity(0.45),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _handleExit,
          child: const SizedBox(
            height: 36,
            width: 36,
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _mobilePlayer() {
    return SizedBox.expand(
      child: _playerSurface(),
    );
  }

  Widget _desktopPlayer() {
    return SizedBox.expand(
      child: _playerSurface(),
    );
  }

  Widget _playerSurface() {
    final theme = Theme.of(context);

    if (_youtubeController != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          if (width <= 0 || height <= 0) return const SizedBox.expand();
          final aspectRatio = width / height;

          return SizedBox(
            width: width,
            height: height,
            child: youtube.YoutubePlayer(
              controller: _youtubeController!,
              width: width,
              aspectRatio: aspectRatio,
              showVideoProgressIndicator: true,
              progressIndicatorColor: theme.primaryColor,
            ),
          );
        },
      );
    }

    if (_player == null || _videoController == null) {
      if (_hasPlaybackError) {
        return const Center(
          child: Text(
            'Video unavailable',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
      return Center(
        child: CircularProgressIndicator(
          color: theme.primaryColor,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 || height <= 0) return const SizedBox.expand();

        return SizedBox(
          width: width,
          height: height,
          child: Video(
            controller: _videoController!,
            width: width,
            height: height,
            fit: BoxFit.cover,
            fill: Colors.black,
          ),
        );
      },
    );
  }
}
