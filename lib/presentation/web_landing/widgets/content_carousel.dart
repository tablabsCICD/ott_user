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
    final cardWidth = isMobile
        ? (width < 380 ? 132.0 : 144.0)
        : (isTablet
            ? 164.0
            : (width >= 1360 ? 204.0 : 184.0));
    final cardHeight = cardWidth * 1.5; // Precise 2:3 cinematic poster ratio

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
                height: cardHeight + 24,
                child: ListView.separated(
                  controller: _controller,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
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
                    final rankOffset = rank != null
                        ? (rank >= 10
                            ? (isMobile ? 32.0 : 48.0)
                            : (isMobile ? 22.0 : 34.0))
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
