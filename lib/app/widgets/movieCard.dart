import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:video_player/video_player.dart' as native_video;
import 'package:ott/app/core/services/DeepLinkService.dart';
import 'package:ott/app/core/utils/direct_trailer_source.dart';
import 'package:ott/app/core/utils/content_type.dart';
import 'package:ott/app/core/utils/release_date_formatter.dart';
import 'package:ott/app/core/utils/security_debug_log.dart';
import 'package:ott/app/widgets/content_share_sheet.dart';
import 'package:ott/app/core/utils/sharepreferences.dart';
import 'package:ott/app/pages/movie%20details%20page/MovieDetailsPage.dart';
import 'package:ott/app/pages/series%20details%20page/seriesdetailspage.dart';
import 'package:ott/app/pages/watchlist%20page/component/playMoviePage.dart';
import 'package:ott/app/pages/wallet%20page/MovieBillingPage.dart';
import 'package:ott/app/provider/dashboardProvider.dart';
import 'package:ott/app/provider/bookmarkProvider.dart';
import 'package:ott/app/provider/onboarding_tour_provider.dart';
import 'package:ott/app/provider/userProvider.dart';
import 'package:ott/app/widgets/StarRatingWidget.dart';
import 'package:ott/app/widgets/customtextfield.dart';
import 'package:ott/app/widgets/feature_tour.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/app/widgets/filmytell_poster_image.dart';
import 'package:ott/app/widgets/ott_tv_app_shell.dart';
import 'package:ott/app/widgets/ott_tv_focus.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:ott/data/models/content.dart';

class MovieCard extends StatefulWidget {
  /// Height the redesigned card needs (poster + details); matches the 270px
  /// rows used on the home screen.
  static const double standardHeight = 270.0;
  static const double standardPosterAspectRatio = 16 / 9;
  static const double mobileCardWidth = 300.0;
  static const double tabletCardWidth = 300.0;
  static const double laptopCardWidth = 300.0;
  static const double desktopCardWidth = 300.0;
  static const double itemWidth = 300;
  static const double itemMargin = 5;
  static const double itemExtent = itemWidth + (itemMargin * 2);

  final Content movie;
  final ValueListenable<int?>? activeIndexListenable;
  final int? index;
  final double? cardWidth;
  final double? cardMargin;
  final ValueChanged<Content>? onContentUpdated;
  final bool isShortFilmTab;

  /// Android TV only: request focus when first shown (e.g. first grid item).
  final bool autofocus;

  const MovieCard({
    super.key,
    required this.movie,
    this.activeIndexListenable,
    this.index,
    this.cardWidth,
    this.cardMargin,
    this.onContentUpdated,
    this.isShortFilmTab = false,
    this.autofocus = false,
  });

  /// Resolves the standardized card width for the given context based on
  /// responsive viewport breakpoints.
  static double cardWidthFor(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth >= 1800) {
      return desktopCardWidth;
    } else if (screenWidth >= 1024) {
      return laptopCardWidth;
    } else if (screenWidth >= 600) {
      return tabletCardWidth;
    } else {
      return mobileCardWidth;
    }
  }

  /// Resolves the standardized item extent (card width + margins).
  static double cardExtentFor(BuildContext context,
      [double margin = itemMargin]) {
    return cardWidthFor(context) + (margin * 2);
  }

  @override
  State<MovieCard> createState() => _MovieCardState();
}

class _MovieCardState extends State<MovieCard> {
  static _MovieCardState? _activePreviewState;
  Player? _previewPlayer;
  VideoController? _videoController;
  native_video.VideoPlayerController? _androidPreviewController;
  final List<StreamSubscription<dynamic>> _previewSubscriptions = [];
  bool _isHovered = false;
  bool _isMuted = true;
  bool _isVideoInitialized = false;
  bool _isPreviewPlaying = false;
  bool _isAutoPlayActive = false;
  bool _isStartingPreview = false;
  int _previewGeneration = 0;
  Timer? _playDelayTimer;
  Future<void>? _previewStartFuture;

  // Android TV presentation state.
  bool _isTvMode = false;
  bool _tvSelectDown = false;
  bool _tvLongPressHandled = false;

  String? _directPreviewUrl(String? rawUrl) {
    final value = DirectTrailerSource.fromBackend(rawUrl);
    if (value == null) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) return null;

    final host = uri.host.toLowerCase();
    final isYoutube = host.contains('youtube.com') || host == 'youtu.be';
    if (isYoutube) return null;

    return value;
  }

  @override
  void initState() {
    super.initState();
    widget.activeIndexListenable?.addListener(_handleActiveIndexChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<BookmarkProvider>()
          .isBookmarked(widget.movie.id ?? 0)
          .then((value) {
        if (!mounted) return;
        if (value) {
          context.read<BookmarkProvider>().addBookmark(widget.movie.id ?? 0);
        }
      });

      if (mounted) {
        _handleActiveIndexChanged();
      }
    });
  }

  Widget _watchProgressBar(ThemeData theme) {
    final progress = (widget.movie.watchedPercentage ?? 0) / 100;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0.3,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 4,
          backgroundColor: theme.cardColor,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.primaryColor, // Netflix-style
          ),
        ),
      ),
    );
  }

  void _toggleMute() {
    final player = _previewPlayer;
    setState(() {
      _isMuted = !_isMuted;
    });
    player?.setVolume(_isMuted ? 0 : 100);
    _androidPreviewController?.setVolume(_isMuted ? 0 : 1);
  }

  Future<bool> _ensureVideoInitialized() async {
    if (_isVideoInitialized) return true;

    final trailerUrl = _directPreviewUrl(widget.movie.trailerUrl);
    if (trailerUrl == null) return false;
    final generation = _previewGeneration;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final controller = native_video.VideoPlayerController.networkUrl(
        Uri.parse(trailerUrl),
      );
      try {
        await controller.initialize();
        await controller.setLooping(true);
        await controller.setVolume(_isMuted ? 0 : 1);
        if (!mounted ||
            generation != _previewGeneration ||
            !_isPlayTriggerActive ||
            _activePreviewState != this) {
          await controller.dispose();
          return false;
        }
        _androidPreviewController = controller;
        setState(() => _isVideoInitialized = true);
        _logPreview('Android ExoPlayer trailer initialized');
        return true;
      } catch (error) {
        await controller.dispose();
        return false;
      }
    }

    final player = Player();

    try {
      _previewSubscriptions
        ..add(player.stream.completed.listen((completed) {
          if (completed && _isPreviewPlaying) {
            player.seek(Duration.zero);
            player.play();
          }
        }))
        ..add(player.stream.position.listen((_) {
          if (mounted) setState(() {});
        }))
        ..add(player.stream.duration.listen((_) {
          if (mounted) setState(() {});
        }))
        ..add(player.stream.error.listen((error) {
          _stopAndDisposePreview('stream error');
          if (_activePreviewState == this) {
            _activePreviewState = null;
          }
        }));

      SecurityDebugLog.event(
        'TRAILER',
        'MovieCard preview is using the direct backend trailer URL.',
      );
      await player.open(Media(trailerUrl), play: false);
      await player.setVolume(_isMuted ? 0 : 100);

      if (!mounted ||
          generation != _previewGeneration ||
          !_isPlayTriggerActive ||
          _activePreviewState != this) {
        for (final subscription in _previewSubscriptions) {
          unawaited(subscription.cancel());
        }
        _previewSubscriptions.clear();
        await player.dispose();
        _logPreview('Video Disposed stale init');
        return false;
      }

      final controller = VideoController(player);
      _previewPlayer = player;
      _videoController = controller;

      if (mounted) {
        setState(() => _isVideoInitialized = true);
      }
      _logPreview('Video Initialized');
      return true;
    } catch (e) {
      await player.dispose();
      _disposeVideoController();
      return false;
    }
  }

  void _disposeVideoController() {
    _previewGeneration++;
    for (final subscription in _previewSubscriptions) {
      unawaited(subscription.cancel());
    }
    _previewSubscriptions.clear();
    final player = _previewPlayer;
    final androidController = _androidPreviewController;
    _previewPlayer = null;
    _videoController = null;
    _androidPreviewController = null;
    _isVideoInitialized = false;
    _isPreviewPlaying = false;
    if (player != null) {
      unawaited(player.dispose());
      _logPreview('Video Disposed');
    }
    if (androidController != null) {
      unawaited(androidController.dispose());
      _logPreview('Android ExoPlayer trailer disposed');
    }
  }

  Future<void> _disposePreviewBeforeSecurePlayback() async {
    _playDelayTimer?.cancel();
    _previewGeneration++;
    await _previewStartFuture;
    for (final subscription in _previewSubscriptions) {
      await subscription.cancel();
    }
    _previewSubscriptions.clear();
    final player = _previewPlayer;
    final androidController = _androidPreviewController;
    _previewPlayer = null;
    _videoController = null;
    _androidPreviewController = null;
    _isVideoInitialized = false;
    _isPreviewPlaying = false;
    if (_activePreviewState == this) _activePreviewState = null;
    if (player != null) {
      SecurityDebugLog.event(
        'TRAILER',
        'Awaiting MovieCard preview disposal before secure playback.',
      );
      await player.dispose();
      SecurityDebugLog.event(
        'TRAILER',
        'MovieCard preview disposal completed before secure playback.',
      );
    }
    if (androidController != null) {
      await androidController.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant MovieCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.activeIndexListenable != widget.activeIndexListenable) {
      oldWidget.activeIndexListenable
          ?.removeListener(_handleActiveIndexChanged);
      widget.activeIndexListenable?.addListener(_handleActiveIndexChanged);
      _handleActiveIndexChanged();
    } else if (oldWidget.index != widget.index) {
      _handleActiveIndexChanged();
    }

    if (oldWidget.movie.trailerUrl != widget.movie.trailerUrl) {
      _playDelayTimer?.cancel();
      _stopAndDisposePreview('trailer url changed');
    }
  }

  @override
  void dispose() {
    if (_activePreviewState == this) {
      _activePreviewState = null;
    }
    widget.activeIndexListenable?.removeListener(_handleActiveIndexChanged);
    _playDelayTimer?.cancel();
    _disposeVideoController();
    super.dispose();
  }

  void _handleHover(bool hovering) {
    setState(() => _isHovered = hovering);

    if (hovering) {
      _schedulePreview();
    } else {
      _playDelayTimer?.cancel();
      _stopAndDisposePreview('hover lost');
      if (_activePreviewState == this) {
        _activePreviewState = null;
      }
    }
  }

  void _handleActiveIndexChanged() {
    final activeIndex = widget.activeIndexListenable?.value;
    final shouldAutoPlay = _isAutoPlayDevice &&
        widget.index != null &&
        activeIndex != null &&
        activeIndex == widget.index;

    if (shouldAutoPlay == _isAutoPlayActive) return;
    _isAutoPlayActive = shouldAutoPlay;

    if (shouldAutoPlay) {
      _schedulePreview();
    } else {
      _playDelayTimer?.cancel();
      _stopAndDisposePreview('visibility below threshold');
      if (_activePreviewState == this) {
        _activePreviewState = null;
      }
    }
  }

  bool get _isAutoPlayDevice {
    if (kIsWeb) {
      return true;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return true;
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  void _schedulePreview() {
    if (_playDelayTimer != null) return;
    if (_isStartingPreview || _isPreviewPlaying) return;
    if (!_isPlayTriggerActive) return;

    if (_isAutoPlayActive && !_isHovered) {
      _beginPreviewStart();
      return;
    }

    // Android TV: wait until the remote rests on a card before spinning up a
    // trailer player, so fast D-pad scrolling stays smooth.
    _playDelayTimer = Timer(
        _isTvMode
            ? const Duration(milliseconds: 1200)
            : const Duration(milliseconds: 250), () {
      _playDelayTimer = null;
      _beginPreviewStart();
    });
  }

  void _beginPreviewStart() {
    final future = _startPreviewIfEligible();
    _previewStartFuture = future;
    unawaited(future.whenComplete(() {
      if (identical(_previewStartFuture, future)) {
        _previewStartFuture = null;
      }
    }));
  }

  bool get _isPlayTriggerActive {
    return _isHovered || _isAutoPlayActive;
  }

  Future<void> _startPreviewIfEligible() async {
    if (!mounted) return;
    if (!_isPlayTriggerActive) return;
    if (_isStartingPreview || _isPreviewPlaying) return;

    _isStartingPreview = true;
    final generation = ++_previewGeneration;
    try {
      _activatePreview();

      final ready = await _ensureVideoInitialized();
      if (!ready || !mounted) {
        if (_activePreviewState == this) {
          _activePreviewState = null;
        }
        _stopAndDisposePreview('not ready');
        return;
      }

      if (!_isPlayTriggerActive ||
          generation != _previewGeneration ||
          _activePreviewState != this) {
        _stopAndDisposePreview('stale start');
        return;
      }

      _ensureMuted();

      final androidController = _androidPreviewController;
      if (androidController != null) {
        await androidController.play();
      } else {
        await _previewPlayer!.play();
      }
      if (!mounted ||
          generation != _previewGeneration ||
          _activePreviewState != this) {
        _stopAndDisposePreview('stale after play');
        return;
      }
      setState(() => _isPreviewPlaying = true);
      _logPreview('Video Started');
      _logPreview('Current Active Video ID ${widget.movie.id ?? widget.index}');
    } catch (e) {
      _stopAndDisposePreview('play failed');
      if (_activePreviewState == this) {
        _activePreviewState = null;
      }
    } finally {
      _isStartingPreview = false;
    }
  }

  void _activatePreview() {
    if (_activePreviewState == this) return;
    final previous = _activePreviewState;
    _activePreviewState = this;
    previous?._stopAndDisposePreview('replaced by ${widget.movie.id}');
  }

  void _ensureMuted() {
    final player = _previewPlayer;
    final androidController = _androidPreviewController;
    if (player == null && androidController == null) return;
    if (!_isMuted) {
      setState(() => _isMuted = true);
    }
    player?.setVolume(0);
    androidController?.setVolume(0);
  }

  void _stopPreview({bool external = false}) {
    final player = _previewPlayer;
    final androidController = _androidPreviewController;
    if ((player == null && androidController == null) || !_isVideoInitialized) {
      return;
    }

    try {
      player?.pause();
      player?.seek(Duration.zero);
      androidController?.pause();
      androidController?.seekTo(Duration.zero);
    } catch (e) {}

    if (!mounted) return;
    setState(() {
      _isPreviewPlaying = false;
    });
    _logPreview(external ? 'Video Paused external' : 'Video Paused');
  }

  void _stopAndDisposePreview(String reason) {
    _previewGeneration++;
    _stopPreview(external: true);
    _disposeVideoController();
    _logPreview('Video Stopped $reason');
  }

  void _logPreview(String message) {
    if (kDebugMode) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final posterUrl = widget.movie.posterUrlList?.isNotEmpty == true
        ? widget.movie.posterUrlList!.first
        : null;
    _isTvMode = ResponsiveWidget.isAndroidTv(context);
    if (_isTvMode) return _buildTvCard(theme, lang, posterUrl);
    final showPreview = _isPreviewPlaying;
    final cardWidth = widget.cardWidth ?? MovieCard.itemWidth;
    final cardMargin = widget.cardMargin ?? MovieCard.itemMargin;
    final isHighlighted = showPreview || _isHovered;
    final highlightColor = ResponsiveWidget.isTabletOrTv(context)
        ? theme.primaryColor
        : (theme.brightness == Brightness.light
            ? const Color.fromARGB(255, 185, 169, 169)
            : const Color.fromARGB(255, 58, 49, 49));

    return Stack(
      children: [
        Focus(
          canRequestFocus: ResponsiveWidget.isTabletOrTv(context),
          onFocusChange: (hasFocus) {
            if (ResponsiveWidget.isTabletOrTv(context)) {
              _handleHover(hasFocus);
            }
          },
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent) return KeyEventResult.ignored;
            final key = event.logicalKey;
            if (key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.select ||
                key == LogicalKeyboardKey.space ||
                key == LogicalKeyboardKey.gameButtonA) {
              _openDetails();
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: MouseRegion(
            onEnter: (_) => _handleHover(true),
            onExit: (_) => _handleHover(false),
            child: GestureDetector(
              onTap: _openDetails,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: cardWidth,
                margin: EdgeInsets.only(
                  left: cardMargin,
                  right: cardMargin,
                  bottom: cardMargin,
                  top: showPreview
                      ? 4
                      : 12, // 👈 selected card moves slightly up
                ),
                //    margin: EdgeInsets.all(cardMargin),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: showPreview
                        ? highlightColor
                        : theme.canvasColor.withValues(alpha: 0.2),
                    width: showPreview ? 2.5 : 1,
                  ),
                  /*  boxShadow: showPreview
                    ? [
                        BoxShadow(
                          color: highlightColor.withValues(alpha: 0.12),
                          blurRadius: 3,
                          spreadRadius: 0.5,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null, */
                ),
                // On TV also outline the focused card (not only while its
                // trailer plays) so the remote cursor is visible. Painted on
                // top so it never shrinks the card content.
                foregroundDecoration: ResponsiveWidget.isAndroidTv(context) &&
                        isHighlighted &&
                        !showPreview
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        // Thicker: the row scales the card down on TV.
                        border: Border.all(color: highlightColor, width: 4),
                      )
                    : null,
                child: Column(
                  children: [
                    /// 🎬 POSTER + PROGRESS BAR STACK
                    Expanded(
                      flex: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: theme.cardColor, width: 1),
                            left: BorderSide(color: theme.cardColor, width: 1),
                            right: BorderSide(color: theme.cardColor, width: 1),
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: _buildMediaPreview(
                            posterUrl,
                            theme,
                            widget.movie,
                            showPreview,
                          ),
                        ),
                      ),
                    ),

                    /// 📄 DETAILS SECTION
                    Expanded(
                      flex: 3,
                      child: _buildContentSection(theme, lang),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// ⋮ OPTIONS BUTTON
        _optionButton(context, widget.movie),
      ],
    );
  }

  // ===========================================================================
  // ANDROID TV PRESENTATION
  // Same horizontal card, same design size (MovieCard.itemWidth x 270 incl.
  // margins) and same content as on other platforms; the row scales it with
  // TvCardScale exactly as before. TV differences: a true 16:9 image, a
  // premium focus treatment, and remote actions — OK opens details, holding
  // OK (or Menu) opens the card's options (the speed-dial is unreachable).
  // ===========================================================================

  Widget _buildTvCard(
    ThemeData theme,
    AppLocalizations lang,
    String? posterUrl,
  ) {
    final movie = widget.movie;
    final focused = _isHovered;
    final cardWidth = widget.cardWidth ?? MovieCard.itemWidth;
    final cardMargin = widget.cardMargin ?? MovieCard.itemMargin;
    final rating = movie.ratings ?? 0.0;
    final meta = [
      formatReleaseDate(movie.releaseDate),
      movie.genreList?.join(', ') ?? 'N/A',
    ].where((e) => e.trim().isNotEmpty).join('  |  ');

    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        _handleHover(hasFocus);
        if (hasFocus) {
          TvDesign.revealFocused(context);
        } else {
          _tvSelectDown = false;
          _tvLongPressHandled = false;
        }
      },
      onKeyEvent: _handleTvKey,
      child: MouseRegion(
        onEnter: (_) => _handleHover(true),
        onExit: (_) => _handleHover(false),
        child: GestureDetector(
          onTap: _openDetails,
          onLongPress: _showTvOptions,
          child: Container(
            width: cardWidth,
            // Same slot as the original card (top margin = room for focus).
            margin: EdgeInsets.fromLTRB(cardMargin, 12, cardMargin, cardMargin),
            child: TvFocusFrame(
              focused: focused,
              color: theme.cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: TvDesign.imageAspectRatio,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildTvMedia(posterUrl),
                        if ((movie.watchedPercentage ?? 0) > 0)
                          _watchProgressBar(theme),
                        if (movie.isFeatured == true)
                          const Positioned(
                            top: 8,
                            left: 8,
                            child: _TvCardBadge(label: 'TRAILER'),
                          ),
                        AnimatedOpacity(
                          opacity: focused ? 1 : 0,
                          duration: TvDesign.focusDuration,
                          child: const Align(
                            alignment: Alignment.bottomCenter,
                            child: _TvOptionsHint(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  movie.title ?? 'No Title',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: theme.canvasColor,
                                    height: 1.15,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.star_rounded,
                                      size: 15,
                                      color: Color(0xFFFFC107),
                                    ),
                                    const SizedBox(width: 3),
                                    Flexible(
                                      child: Text(
                                        '${rating.toStringAsFixed(1)} (${movie.ratingCount ?? 0})',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                          color: theme.canvasColor
                                              .withValues(alpha: 0.75),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        meta,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: theme.canvasColor
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (movie.isFeatured != true) ...[
                            const SizedBox(width: 8),
                            _tourWrapDownloadTarget(
                              _TvActionChip(
                                label: _primaryActionLabel(lang),
                                rented: movie.isRental == true,
                                color: theme.primaryColor,
                              ),
                              movie,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// OK opens details on release; holding OK (key repeat) or pressing Menu
  /// opens the options sheet instead.
  KeyEventResult _handleTvKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (OttTvRemoteKey.menu.contains(key)) {
      if (event is KeyDownEvent) _showTvOptions();
      return KeyEventResult.handled;
    }
    if (!OttTvRemoteKey.activate.contains(key)) return KeyEventResult.ignored;

    if (event is KeyDownEvent) {
      _tvSelectDown = true;
      _tvLongPressHandled = false;
      return KeyEventResult.handled;
    }
    if (event is KeyRepeatEvent) {
      if (_tvSelectDown && !_tvLongPressHandled) {
        _tvLongPressHandled = true;
        _showTvOptions();
      }
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) {
      // Only act on a press that started on this card (not the release of a
      // press that closed a dialog or opened this screen).
      final shouldOpen = _tvSelectDown && !_tvLongPressHandled;
      _tvSelectDown = false;
      _tvLongPressHandled = false;
      if (shouldOpen) _openDetails();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 16:9 poster, or the trailer preview filling the same 16:9 frame.
  Widget _buildTvMedia(String? posterUrl) {
    final androidController = _androidPreviewController;
    if (_isPreviewPlaying &&
        _isVideoInitialized &&
        androidController != null &&
        androidController.value.isInitialized) {
      final size = androidController.value.size;
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: size.width <= 0 ? 16 : size.width,
            height: size.height <= 0 ? 9 : size.height,
            child: native_video.VideoPlayer(androidController),
          ),
        ),
      );
    }
    final videoController = _videoController;
    if (_isPreviewPlaying && _isVideoInitialized && videoController != null) {
      return Video(
          controller: videoController, fit: BoxFit.cover, controls: null);
    }
    return FilmytellPosterImage(
      posterUrl: posterUrl,
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      fallbackIconSize: 44,
    );
  }

  /// TV replacement for the speed-dial menu. Same actions, same handlers.
  Future<void> _showTvOptions() async {
    final movie = widget.movie;
    if (movie.id == null) return;
    final lang = AppLocalizations.of(context)!;
    final isSeries = movie.type?.toLowerCase() == "series";
    final isBookmarked =
        context.read<BookmarkProvider>().isBookmarkedLocally(movie.id ?? 0);

    final actions = <_TvCardAction>[
      _TvCardAction(Icons.info_outline_rounded, 'View details', _openDetails),
      if (movie.isFeatured != true)
        _TvCardAction(
          movie.isRental == true
              ? Icons.play_arrow_rounded
              : Icons.confirmation_number_outlined,
          _primaryActionLabel(lang),
          _runPrimaryAction,
        ),
      if (movie.isRental != true)
        _TvCardAction(
          isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border,
          isBookmarked ? 'Remove Bookmark' : 'Bookmark',
          () => unawaited(_toggleBookmark()),
        ),
      _TvCardAction(Icons.share_rounded, 'Share', () {
        showContentShareSheet(
          context,
          movie,
          contentType: _shareContentTypeFor(movie),
          unavailableMessage: "Content details are not available yet",
        );
      }),
      if (!isSeries)
        _TvCardAction(LucideIcons.gift, 'Gift', () {
          _showGiftDialog(context, movie, TextEditingController());
        }),
    ];

    final selected = await showDialog<_TvCardAction>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (_) => _TvCardOptionsDialog(movie: movie, actions: actions),
    );
    if (!mounted || selected == null) return;
    selected.onSelected();
  }

  Widget _buildMediaPreview(
      String? posterUrl, ThemeData theme, Content content, bool showPreview) {
    final androidController = _androidPreviewController;
    if (showPreview &&
        _isVideoInitialized &&
        androidController != null &&
        androidController.value.isInitialized) {
      return Stack(
        children: [
          Positioned.fill(
            child: native_video.VideoPlayer(androidController),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _previewProgress(),
          ),
          Positioned(
            right: 5,
            bottom: 5,
            child: Semantics(
              button: true,
              label: _isMuted ? 'Unmute trailer' : 'Mute trailer',
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                  iconSize: 12,
                  tooltip: _isMuted ? 'Unmute trailer' : 'Mute trailer',
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                  ),
                  onPressed: _toggleMute,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (showPreview && _isVideoInitialized && _videoController != null) {
      return Stack(
        children: [
          Positioned.fill(
            child: Video(
              controller: _videoController!,
              fit: BoxFit.fill,
              controls: null,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _previewProgress(),
          ),
          Positioned(
            right: 5,
            bottom: 5,
            child: Semantics(
              button: true,
              label: _isMuted ? 'Unmute trailer' : 'Mute trailer',
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: IconButton(
                  padding: const EdgeInsets.all(2),
                  constraints:
                      const BoxConstraints(minWidth: 25, minHeight: 25),
                  iconSize: 20,
                  tooltip: _isMuted ? 'Unmute trailer' : 'Mute trailer',
                  icon: Icon(
                    _isMuted ? Icons.volume_off : Icons.volume_up,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: _toggleMute,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FilmytellPosterImage(
          posterUrl: posterUrl,
          fallbackIconSize: 60,
        ),

        /// 🔥 CONTINUE WATCHING BAR
        if ((widget.movie.watchedPercentage ?? 0) > 0) _watchProgressBar(theme),
      ],
    );
  }

  Widget _buildContentSection(ThemeData theme, AppLocalizations lang) {
    final movie = widget.movie;

    final rating = movie.ratings ?? 0.0;
    final price = movie.price ?? 0;

    return Row(
      children: [
        Flexible(
          flex: 7,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const SizedBox(height: 2),
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
                      TextSpan(text: formatReleaseDate(movie.releaseDate)),
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
        ),
        Row(
          children: [
            // _optionButton(context, movie),
            // SizedBox(
            //   width: 5,
            // ),
            movie.isFeatured == true
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
                : _tourWrapDownloadTarget(
                    _buildPriceButton(theme, lang, price),
                    movie,
                  ),
            SizedBox(
              width: 5,
            )
          ],
        ),
      ],
    );
  }

  /// Label of the card's primary action chip (price, or watch when rented).
  String _primaryActionLabel(AppLocalizations lang) {
    final movie = widget.movie;
    final price = movie.price ?? 0;
    final isRental = movie.isRental ?? false;
    final isShortFilm = widget.isShortFilmTab ||
        ContentType.normalize(movie.type) == ContentType.shortFilm;
    return movie.type!.toLowerCase() == 'series'
        ? isRental
            ? (isShortFilm ? 'Watch Now' : 'Watch Series')
            : '₹ $price'
        : isRental
            ? isShortFilm
                ? 'Watch Now'
                : movie.type?.toLowerCase() == "movie"
                    ? lang.watchMovie
                    : lang.watchSeries
            : "₹ $price";
  }

  /// The card's primary action: open a series, play a rented title, or
  /// start the rent flow.
  void _runPrimaryAction() {
    final movie = widget.movie;
    final isRental = movie.isRental ?? false;
    movie.type!.toLowerCase() == 'series'
        ? _openDetails()
        : isRental
            ? _playMovie()
            : _showCupertinoDialog(context, movie);
  }

  Future<void> _toggleBookmark() async {
    final movie = widget.movie;
    final bookmarkProvider = context.read<BookmarkProvider>();
    final bool wasBookmarked =
        bookmarkProvider.isBookmarkedLocally(movie.id ?? 0);

    await bookmarkProvider.toggleBookmark(movie);
    if (!mounted) return;

    CustomToast.show(
      context,
      wasBookmarked
          ? "${movie.title} removed from bookmarks"
          : "${movie.title} added to bookmarks",
      isSuccess: true,
    );
  }

  Widget _buildPriceButton(
      ThemeData theme, AppLocalizations lang, double price) {
    return GestureDetector(
      onTap: _runPrimaryAction,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          color: theme.primaryColor.withOpacity(0.9),
        ),
        child: Text(
          _primaryActionLabel(lang),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _tourWrapDownloadTarget(Widget child, Content movie) {
    final canDownload = widget.index == 0 &&
        movie.isDownloadable == true &&
        (movie.contentUrl?.trim().isNotEmpty ?? false);
    if (!canDownload) return child;

    return FeatureTourTarget(
      id: FeatureTourStepId.download,
      child: child,
    );
  }

  void _openDetails() {
    final movie = widget.movie;

    if (movie.id == null || movie.type == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ContentType.isMovieLike(movie.type)
            ? MovieDetailsPage(
                movieId: movie.id!,
                contentType: movie.type,
              )
            : SeriesDetailsPage(seriesId: movie.id!, content: movie),
      ),
    ).then((_) => _refreshSingleContent());
  }

  Future<void> _playMovie() async {
    final movie = widget.movie;
    SecurityDebugLog.event(
      'ROUTE',
      'Watch Movie tapped on MovieCard.',
    );
    if (movie.id == null) {
      SecurityDebugLog.event(
        'ROUTE',
        'Playback route stopped because the content ID is missing.',
      );
      return;
    }

    Content contentToPlay = movie;
    var contentUrl = contentToPlay.contentUrl;

    if (contentUrl == null || contentUrl.trim().isEmpty) {
      SecurityDebugLog.event(
        'ROUTE',
        'Card has no media source; refreshing content details.',
      );
      final fetchedContent =
          await context.read<DashboardProvider>().getContentById(movie.id!);
      if (!mounted) return;

      if (fetchedContent != null) {
        fetchedContent.watchedSeconds ??= movie.watchedSeconds;
        fetchedContent.watchedPercentage ??= movie.watchedPercentage;
        contentToPlay = fetchedContent;
        contentUrl = contentToPlay.contentUrl;
      }
    }

    if (contentUrl == null || contentUrl.trim().isEmpty) {
      SecurityDebugLog.event(
        'ROUTE',
        'Playback route stopped because no media source is available.',
      );
      CustomToast.show(
        context,
        "Video is not available",
        isSuccess: false,
      );
      return;
    }

    SecurityDebugLog.event(
      'ROUTE',
      'Media source is available; opening PlayMediaPage with the URL redacted.',
    );
    await _disposePreviewBeforeSecurePlayback();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlayMediaPage(
          videoUrl: contentUrl!,
          content: contentToPlay,
          seasonIndex: 0,
          episodeIndex: 0,
          seasons: [],
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      context
          .read<DashboardProvider>()
          .getContinueWatchedMovieList(contentToPlay.type ?? "MOVIE");
    });
  }

  Widget _previewProgress() {
    final player = _previewPlayer;
    if (player == null) return const SizedBox.shrink();

    final duration = player.state.duration.inMilliseconds;
    if (duration <= 0) return const SizedBox.shrink();

    final value = (player.state.position.inMilliseconds / duration)
        .clamp(0.0, 1.0)
        .toDouble();

    return LinearProgressIndicator(
      value: value,
      minHeight: 3,
      color: Colors.red,
      backgroundColor: Colors.white24,
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
              ).then((result) {
                if (result == true) {
                  _refreshAfterPurchase();
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Future<void> _refreshAfterPurchase() async {
    final user = await LocalSharePreferences().getUser();
    if (!mounted || user == null) return;

    final userProvider = context.read<UserProvider>();
    final dashboardProvider = context.read<DashboardProvider>();

    final type = (widget.movie.type ?? "MOVIE").toUpperCase();
    final languages = userProvider.userObject.selectedLanguages ?? [];
    final langList = languages.isEmpty ? ["English"] : languages;

    await dashboardProvider.getDashboardData(type, langList, user.id!);

    final contentId = widget.movie.id;
    if (contentId == null) return;

    final refreshedContent = await dashboardProvider.getContentById(contentId);
    if (!mounted || refreshedContent == null) return;

    widget.onContentUpdated?.call(refreshedContent);
  }

  Future<void> _refreshSingleContent() async {
    final contentId = widget.movie.id;
    if (contentId == null || !mounted) return;

    final refreshedContent =
        await context.read<DashboardProvider>().getContentById(contentId);
    if (!mounted || refreshedContent == null) return;

    widget.onContentUpdated?.call(refreshedContent);
  }

  Widget _optionButton(BuildContext context, Content movie) {
    final theme = Theme.of(context);
    final bool isSeries = movie.type?.toLowerCase() == "series";
    final double cardWidth = widget.cardWidth ?? MovieCard.itemWidth;
    final bool compactOverlay =
        ResponsiveWidget.isMobile(context) || cardWidth <= MovieCard.itemWidth;
    final double buttonSize = compactOverlay ? 28 : 30;
    final double verticalInset = compactOverlay ? 8 : 12;
    final double horizontalInset = compactOverlay ? 8 : 12;

    final bookmarkProvider = context.watch<BookmarkProvider>();
    final bool isBookmarked =
        bookmarkProvider.isBookmarkedLocally(movie.id ?? 0);

    final ValueNotifier<bool> isDialOpen = ValueNotifier(false);
    final TextEditingController countController = TextEditingController();

    return Positioned(
      top: verticalInset,
      right: horizontalInset,
      child: _tourWrapMoreActionsTarget(
        SpeedDial(
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
          buttonSize: Size(buttonSize, buttonSize),
          childrenButtonSize: Size(buttonSize, compactOverlay ? 32 : 35),
          spacing: 2,
          children: [
            movie.isRental!
                ? SpeedDialChild()
                : SpeedDialChild(
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
                      await _toggleBookmark();
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
                showContentShareSheet(
                  context,
                  movie,
                  contentType: _shareContentTypeFor(movie),
                  unavailableMessage: "Content details are not available yet",
                );
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
      ),
    );
  }

  Widget _tourWrapMoreActionsTarget(Widget child) {
    if (widget.index != 0) return child;

    return FeatureTourTarget(
      id: FeatureTourStepId.moreActions,
      child: child,
    );
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

  DeepLinkContentType _shareContentTypeFor(Content movie) {
    switch ((movie.type ?? '').trim().toLowerCase()) {
      case 'short_film':
      case 'shortfilm':
        return DeepLinkContentType.shortFilm;
      case 'series':
        return DeepLinkContentType.series;
      case 'mini series':
      case 'mini_series':
      case 'miniseries':
        return DeepLinkContentType.miniSeries;
      case 'short':
      case 'shorts':
        return DeepLinkContentType.short;
      default:
        return DeepLinkContentType.movie;
    }
  }
}

// =============================================================================
// Android TV card helpers
// =============================================================================

class _TvCardAction {
  const _TvCardAction(this.icon, this.label, this.onSelected);

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
}

class _TvCardBadge extends StatelessWidget {
  const _TvCardBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Price / watch chip (the card's primary action, shown as a label on TV;
/// it runs from the options sheet or the details page).
class _TvActionChip extends StatelessWidget {
  const _TvActionChip({
    required this.label,
    required this.rented,
    required this.color,
  });

  final String label;
  final bool rented;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        color: rented ? const Color(0xFF1B8A3A) : color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rented ? Icons.play_arrow_rounded : Icons.confirmation_number,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            // Long (localised) labels ellipsize instead of squeezing the
            // title/rating column.
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown at the bottom of the focused image so the options are discoverable.
class _TvOptionsHint extends StatelessWidget {
  const _TvOptionsHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 22, 10, 7),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Color(0xD9000000)],
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.more_horiz_rounded, size: 16, color: Colors.white70),
          SizedBox(width: 5),
          Text(
            'Hold OK for options',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Remote-friendly options sheet for a card. Pops with the chosen action.
class _TvCardOptionsDialog extends StatelessWidget {
  const _TvCardOptionsDialog({required this.movie, required this.actions});

  final Content movie;
  final List<_TvCardAction> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final posterUrl = movie.posterUrlList?.isNotEmpty == true
        ? movie.posterUrlList!.first
        : null;

    return Dialog(
      backgroundColor: theme.cardColor,
      insetPadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(TvDesign.panelRadius),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: TvDesign.imageAspectRatio,
                  child: FilmytellPosterImage(
                    posterUrl: posterUrl,
                    fit: BoxFit.cover,
                    fallbackIconSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                movie.title ?? 'No Title',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TvDesign.pageTitle(theme).copyWith(fontSize: 15),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < actions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: OttTvFocus(
                    autofocus: i == 0,
                    borderRadius: 8,
                    scale: 1.0,
                    onTap: () => Navigator.of(context).pop(actions[i]),
                    child: Container(
                      height: 30,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.canvasColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(actions[i].icon,
                              size: 15, color: theme.canvasColor),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              actions[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: theme.canvasColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
