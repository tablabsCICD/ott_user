import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ott/app/core/utils/release_date_formatter.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';

class ContentCarousel extends StatefulWidget {
  const ContentCarousel({
    super.key,
    required this.title,
    required this.items,
    required this.onContentTap,
    this.numbered = false,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.hasMore = false,
  });

  final String title;
  final List<Content> items;
  final ValueChanged<Content> onContentTap;
  final bool numbered;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool hasMore;

  @override
  State<ContentCarousel> createState() => _ContentCarouselState();
}

class _ContentCarouselState extends State<ContentCarousel> {
  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!widget.hasMore ||
        widget.isLoadingMore ||
        widget.onLoadMore == null ||
        !_controller.hasClients) {
      return;
    }

    final remaining =
        _controller.position.maxScrollExtent - _controller.position.pixels;
    if (remaining < 520) {
      widget.onLoadMore!();
    }
  }

  void _scrollBy(double offset) {
    if (!_controller.hasClients) return;
    final target = (_controller.offset + offset).clamp(
      0.0,
      _controller.position.maxScrollExtent,
    );
    _controller.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = width < 600 ? 16.0 : (width < 1024 ? 32.0 : 56.0);
    final cardWidth = width < 600 ? 138.0 : (width >= 1360 ? 178.0 : 156.0);

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Spacer(),
                  if (width >= 600) ...[
                    _ArrowButton(
                      icon: Icons.chevron_left,
                      onTap: () => _scrollBy(-720),
                    ),
                    const SizedBox(width: 10),
                    _ArrowButton(
                      icon: Icons.chevron_right,
                      onTap: () => _scrollBy(720),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _scrollBy(event.scrollDelta.dy == 0
                      ? event.scrollDelta.dx
                      : event.scrollDelta.dy * 2.4);
                }
              },
              child: SizedBox(
                height: widget.numbered ? 292 : 270,
                child: ListView.separated(
                  controller: _controller,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  scrollDirection: Axis.horizontal,
                  itemCount: widget.items.length +
                      (widget.isLoadingMore || widget.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) => const SizedBox(width: 18),
                  itemBuilder: (context, index) {
                    if (index >= widget.items.length) {
                      return SizedBox(
                        width: widget.numbered ? cardWidth + 42 : cardWidth,
                        child: _CarouselLoadingMore(
                          onLoadMore: widget.onLoadMore,
                          isLoading: widget.isLoadingMore,
                        ),
                      );
                    }

                    return SizedBox(
                      width: widget.numbered ? cardWidth + 42 : cardWidth,
                      child: _LandingPosterCard(
                        content: widget.items[index],
                        rank: widget.numbered ? index + 1 : null,
                        width: cardWidth,
                        onTap: () => widget.onContentTap(widget.items[index]),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LandingPosterCard extends StatefulWidget {
  const _LandingPosterCard({
    required this.content,
    required this.width,
    required this.onTap,
    this.rank,
  });

  final Content content;
  final double width;
  final int? rank;
  final VoidCallback onTap;

  @override
  State<_LandingPosterCard> createState() => _LandingPosterCardState();
}

class _LandingPosterCardState extends State<_LandingPosterCard> {
  final LayerLink _previewLink = LayerLink();
  bool _hovered = false;
  OverlayEntry? _previewEntry;

  @override
  void dispose() {
    _previewEntry?.remove();
    _previewEntry = null;
    super.dispose();
  }

  void _showPreview() {
    if (!mounted) return;
    if (_previewEntry != null) return;
    if (MediaQuery.sizeOf(context).width < 1024) return;
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    setState(() => _hovered = true);
    _previewEntry = OverlayEntry(
      builder: (context) {
        return Positioned.fill(
          child: IgnorePointer(
            child: CompositedTransformFollower(
              link: _previewLink,
              showWhenUnlinked: false,
              offset: Offset(widget.rank == null ? -116 : -74, -44),
              child: Align(
                alignment: Alignment.topLeft,
                child: _HoverDetailPreview(
                  content: widget.content,
                  width: 442,
                ),
              ),
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    overlay.insert(_previewEntry!);
  }

  void _hidePreview() {
    _previewEntry?.remove();
    _previewEntry = null;
    if (mounted) {
      setState(() => _hovered = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final poster = _posterFor(widget.content);
    final hasRank = widget.rank != null;
    final price = widget.content.price;

    return CompositedTransformTarget(
      link: _previewLink,
      child: MouseRegion(
        onEnter: (_) => _showPreview(),
        onExit: (_) => _hidePreview(),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedOpacity(
            opacity: _hovered ? 0.18 : 1,
            duration: const Duration(milliseconds: 120),
            child: AnimatedScale(
              scale: _hovered ? 0.98 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (hasRank)
                    Positioned(
                      left: -10,
                      top: 18,
                      child: Text(
                        '${widget.rank}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: widget.rank! >= 10 ? 110 : 132,
                          height: 0.9,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.70),
                              blurRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    left: hasRank ? 42 : 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.34),
                                blurRadius: 16,
                                offset: const Offset(0, 13),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: SizedBox(
                              width: widget.width,
                              height: 226,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  poster == null
                                      ? const _PosterFallback()
                                      : CachedNetworkImage(
                                          imageUrl: poster,
                                          fit: BoxFit.cover,
                                          memCacheWidth: 420,
                                          placeholder: (_, __) =>
                                              const _PosterFallback(),
                                          errorWidget: (_, __, ___) =>
                                              const _PosterFallback(),
                                        ),
                                  Positioned(
                                    left: 8,
                                    bottom: 8,
                                    child: _RentCardButton(
                                      label: price == null
                                          ? lang.rent
                                          : '${lang.rent} Rs ${price.toStringAsFixed(0)}',
                                      onTap: widget.onTap,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: widget.width,
                          child: Text(
                            widget.content.title ?? 'Untitled',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(widget.content.ratings ?? 0).toStringAsFixed(1)} rating',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.62),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

  String? _posterFor(Content content) {
    for (final url in content.posterUrlList ?? const <String>[]) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}

class _RentCardButton extends StatelessWidget {
  const _RentCardButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: theme.primaryColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.36),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: 13,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
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

class _HoverDetailPreview extends StatelessWidget {
  const _HoverDetailPreview({
    required this.content,
    required this.width,
  });

  final Content content;
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final poster = _posterFor(content);
    final releaseDate = formatReleaseDate(content.releaseDate);
    final lang = AppLocalizations.of(context)!;
    final runtime =
        (content.runtime ?? 0) > 0 ? '${content.runtime} min' : null;
    final price = content.price;
    final rankGenre = (content.genreList ?? const <String>[]).isEmpty
        ? lang.trendingOnFilmytell
        : '${lang.trendingIn} ${(content.genreList ?? const <String>[]).first}';

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.86, end: 1),
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0).toDouble(),
          child: Transform.scale(
            scale: value,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.70),
                blurRadius: 36,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 248,
                  width: width,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (poster == null)
                        const _PosterFallback()
                      else
                        CachedNetworkImage(
                          imageUrl: poster,
                          fit: BoxFit.cover,
                          memCacheWidth: 820,
                          placeholder: (_, __) => const _PosterFallback(),
                          errorWidget: (_, __, ___) => const _PosterFallback(),
                        ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.12),
                              Colors.black.withOpacity(0.88),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 18,
                        child: Text(
                          content.title ?? 'Untitled',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _RoundAction(
                            icon:
                                content.teaserOrTrailerUrl?.trim().isNotEmpty ==
                                        true
                                    ? Icons.play_arrow_rounded
                                    : Icons.info_outline_rounded,
                            color: theme.primaryColor,
                          ),
                          const Spacer(),
                          if (price != null)
                            _PriceBadge(
                              label: 'Rs ${price.toStringAsFixed(0)}',
                              color: theme.primaryColor,
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      /*  Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: Colors.greenAccent.shade400,
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              rankGenre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.greenAccent.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14), */
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _MetaPill(
                            label:
                                '${(content.ratings ?? 0).toStringAsFixed(1)}',
                          ),
                          if ((content.ageRating ?? '').trim().isNotEmpty)
                            _MetaPill(label: content.ageRating!),
                          if (releaseDate.isNotEmpty)
                            _MetaPill(label: releaseDate),
                          if (runtime != null) _MetaPill(label: runtime),
                          _MetaPill(label: content.type ?? 'Movie'),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        content.description ?? lang.watchPremiumMoviesSeries,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.86),
                          fontSize: 15,
                          height: 1.28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _PreviewActionButton(
                            label: lang.watchNow,
                            icon: Icons.play_arrow_rounded,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 10),
                          _PreviewActionButton(
                            label: lang.moreDetails,
                            icon: Icons.info_outline_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String? _posterFor(Content content) {
    for (final url in content.posterUrlList ?? const <String>[]) {
      final trimmed = url.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }

}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.32),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _PreviewActionButton extends StatelessWidget {
  const _PreviewActionButton({
    required this.label,
    required this.icon,
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    this.color,
  });

  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withOpacity(0.16),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.13),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 38,
        width: 38,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.09),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _CarouselLoadingMore extends StatelessWidget {
  const _CarouselLoadingMore({
    required this.onLoadMore,
    required this.isLoading,
  });

  final VoidCallback? onLoadMore;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: InkWell(
        onTap: isLoading ? null : onLoadMore,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 226,
          width: 150,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: theme.primaryColor,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: theme.primaryColor,
                        size: 30,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.loadMore,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(Icons.movie_creation_outlined, color: Colors.white54),
      ),
    );
  }
}
