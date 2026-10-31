import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';
import 'package:ott/presentation/web_landing/widgets/filmytell_movie_card.dart';
import 'package:ott/presentation/web_landing/widgets/filmytell_section_header.dart';

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
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final horizontalPadding = isMobile ? 18.0 : (isTablet ? 32.0 : 56.0);

    // Responsive card dimensions: wide landscape cards matching Hero Banner aspect ratio (1.38)
    final double cardWidth;
    if (width >= 1600) {
      cardWidth = 340.0; // Ultra-wide / 4K monitors (Height: 246px)
    } else if (width >= 1280) {
      cardWidth = 300.0; // Standard Full HD desktop (Height: 217px)
    } else if (width >= 1024) {
      cardWidth = 260.0; // Laptops / compact desktop (Height: 188px)
    } else if (width >= 768) {
      cardWidth = 225.0; // Tablets landscape / iPads (Height: 163px)
    } else if (width >= 480) {
      cardWidth = 195.0; // Large phones / small tablets (Height: 141px)
    } else if (width >= 360) {
      cardWidth = 170.0; // Standard mobile (Height: 123px)
    } else {
      cardWidth = 150.0; // Compact mobile (Height: 108px)
    }

    final cardHeight = cardWidth / 1.38; // Wide 1.38 aspect ratio matching Hero Banner
    final containerHeight = cardHeight + 36.0; // Clearance for 1.04x hover scale & shadows

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.only(bottom: isMobile ? 32 : 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reusable Section Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: FilmytellSectionHeader(
                title: widget.title,
                onPrev: () => _scrollBy(-cardWidth * 3.5),
                onNext: () => _scrollBy(cardWidth * 3.5),
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal Carousel List
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _scrollBy(event.scrollDelta.dy == 0
                      ? event.scrollDelta.dx
                      : event.scrollDelta.dy * 2.2);
                }
              },
              child: SizedBox(
                height: containerHeight,
                child: ListView.separated(
                  controller: _controller,
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 8.0,
                  ),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: widget.items.length +
                      (widget.isLoadingMore || widget.hasMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                      SizedBox(width: isMobile ? 12 : 16),
                  itemBuilder: (context, index) {
                    if (index >= widget.items.length) {
                      return SizedBox(
                        width: cardWidth,
                        child: _CarouselLoadingMore(
                          onLoadMore: widget.onLoadMore,
                          isLoading: widget.isLoadingMore,
                          height: cardHeight,
                        ),
                      );
                    }

                    final rank = widget.numbered ? index + 1 : null;
                    final isSmallMobile = cardWidth < 120;
                    final rankOffset = rank != null
                        ? (rank >= 10
                            ? (isSmallMobile ? 24.0 : (isMobile ? 28.0 : (cardWidth >= 170 ? 44.0 : 36.0)))
                            : (isSmallMobile ? 16.0 : (isMobile ? 20.0 : (cardWidth >= 170 ? 30.0 : 24.0))))
                        : 0.0;

                    return SizedBox(
                      width: cardWidth + rankOffset,
                      child: FilmytellMovieCard(
                        content: widget.items[index],
                        rank: rank,
                        width: cardWidth,
                        height: cardHeight,
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

class _CarouselLoadingMore extends StatelessWidget {
  const _CarouselLoadingMore({
    required this.onLoadMore,
    required this.isLoading,
    required this.height,
  });

  final VoidCallback? onLoadMore;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: isLoading ? null : onLoadMore,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    height: 26,
                    width: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.6,
                      color: FilmytellTheme.primary,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: FilmytellTheme.primary,
                        size: 30,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppLocalizations.of(context)!.loadMore,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
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
