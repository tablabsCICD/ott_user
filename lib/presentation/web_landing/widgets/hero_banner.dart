import 'dart:async';
import 'dart:developer' as developer;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/l10n/app_localizations.dart';

class HeroBanner extends StatefulWidget {
  const HeroBanner({
    super.key,
    required this.items,
    required this.onWatchNow,
    required this.onPlayTrailer,
  });

  final List<Content> items;
  final ValueChanged<Content> onWatchNow;
  final ValueChanged<Content> onPlayTrailer;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  Timer? _timer;
  int _index = 0;
  bool _loggedFirstContentRender = false;

  @override
  void initState() {
    super.initState();
    _startRotation();
  }

  @override
  void didUpdateWidget(covariant HeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _index = 0;
      _startRotation();
    }
    _logFirstContentRender();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _logFirstContentRender();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRotation() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.items.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;

    final item = widget.items.isEmpty ? null : widget.items[_index];
    final poster = item == null ? null : _posterFor(item);
    final collageItems = widget.items.take(6).toList();

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: isMobile ? 620 : 680),
      child: SizedBox(
        height: isMobile
            ? 680
            : (MediaQuery.of(context).size.height * 0.88)
                .clamp(680, 920)
                .toDouble(),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (poster != null)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 620),
                child: CachedNetworkImage(
                  key: ValueKey(poster),
                  imageUrl: poster,
                  fit: BoxFit.cover,
                  memCacheWidth: 1800,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (_, __) => _HeroFallback(theme: theme),
                  errorWidget: (_, __, ___) => _HeroFallback(theme: theme),
                ),
              )
            else
              _HeroFallback(theme: theme),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black,
                    Colors.black.withOpacity(0.82),
                    Colors.black.withOpacity(0.42),
                    Colors.black.withOpacity(0.78),
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.12),
                    Colors.transparent,
                    Colors.black,
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isMobile ? 20 : (isTablet ? 36 : 72),
                isMobile ? 92 : 118,
                isMobile ? 20 : (isTablet ? 36 : 72),
                isMobile ? 36 : 70,
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 11,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 520),
                      switchInCurve: Curves.easeOutCubic,
                      child: item == null
                          ? const _HeroCopySkeleton()
                          : _HeroCopy(
                              key: ValueKey(item.id ?? item.title),
                              item: item,
                              compact: isMobile,
                              onWatchNow: () => widget.onWatchNow(item),
                              onPlayTrailer: () => widget.onPlayTrailer(item),
                            ),
                    ),
                  ),
                  if (!isMobile) ...[
                    SizedBox(width: isTablet ? 24 : 42),
                    Expanded(
                      flex: isTablet ? 7 : 9,
                      child: _PosterCollage(items: collageItems),
                    ),
                  ],
                ],
              ),
            ),
          ],
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

  void _logFirstContentRender() {
    if (_loggedFirstContentRender || widget.items.isEmpty) return;
    _loggedFirstContentRender = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!kDebugMode) return;
      developer.log(
        'Hero section rendered with ${widget.items.length} items',
        name: 'WebLandingPerformance',
      );
    });
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    super.key,
    required this.item,
    required this.onWatchNow,
    required this.onPlayTrailer,
    required this.compact,
  });

  final Content item;
  final VoidCallback onWatchNow;
  final VoidCallback onPlayTrailer;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final genres = (item.genreList ?? const <String>[]).take(4).toList();
    final releaseYear = _releaseYear(item.releaseDate);
    final lang = AppLocalizations.of(context)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 24, end: 0),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: AnimatedOpacity(
            opacity: value == 0 ? 1 : 0.78,
            duration: const Duration(milliseconds: 420),
            child: child,
          ),
        );
      },
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              item.title ?? lang.filmytellOriginals,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 36 : 58,
                height: 1.02,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 0,
              runSpacing: 8,
              children: [
                _MetaBadge(label: '${(item.ratings ?? 0).toStringAsFixed(1)} '),
                _MetaBadge(label: item.ageRating ?? 'U/A'),
                if ((item.runtime ?? 0) > 0)
                  _MetaBadge(label: '${item.runtime} min'),
                if (releaseYear != null) _MetaBadge(label: releaseYear),
                _MetaBadge(label: item.type ?? 'Movie'),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              item.description ?? lang.premiumStoriesDefault,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 17,
                height: 1.55,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final genre in genres) _GenreChip(label: genre),
              ],
            ),
            const SizedBox(height: 22),
            if (item.price != null) ...[
              _HeroMoviePrice(
                price: item.price!,
                color: theme.primaryColor,
              ),
              const SizedBox(height: 28),
            ] else
              const SizedBox(height: 12),
            Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onWatchNow,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: Text(lang.watchNow),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, compact ? 54 : 62),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 20 : 28,
                      vertical: compact ? 15 : 19,
                    ),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onPlayTrailer,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 24),
                  label: Text(lang.playTrailer),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: Size(0, compact ? 54 : 62),
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 20 : 28,
                      vertical: compact ? 15 : 19,
                    ),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String? _releaseYear(dynamic releaseDate) {
    if (releaseDate == null) return null;
    if (releaseDate is DateTime) return '${releaseDate.year}';

    final value = releaseDate.toString().trim();
    if (value.length >= 4) {
      final firstFour = value.substring(0, 4);
      if (int.tryParse(firstFour) != null) return firstFour;
    }

    final parsed = DateTime.tryParse(value);
    return parsed == null ? null : '${parsed.year}';
  }
}

class _HeroMoviePrice extends StatelessWidget {
  const _HeroMoviePrice({
    required this.price,
    required this.color,
  });

  final double price;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.36),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withOpacity(0.42)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.13),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_rounded, color: color, size: 20),
          const SizedBox(width: 9),
          Text(
            AppLocalizations.of(context)!.rent,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rs ${price.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterCollage extends StatelessWidget {
  const _PosterCollage({required this.items});

  final List<Content> items;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.9,
        ),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 22, end: 0),
            duration: Duration(milliseconds: 380 + index * 70),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Opacity(opacity: value == 0 ? 1 : 0.65, child: child),
              );
            },
            child: _FloatingPoster(content: items[index]),
          );
        },
      ),
    );
  }
}

class _FloatingPoster extends StatefulWidget {
  const _FloatingPoster({required this.content});

  final Content content;

  @override
  State<_FloatingPoster> createState() => _FloatingPosterState();
}

class _FloatingPosterState extends State<_FloatingPoster> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final poster = _posterFor(widget.content);
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: AnimatedScale(
        scale: _hovered ? 1.06 : 1,
        duration: const Duration(milliseconds: 190),
        curve: Curves.easeOutCubic,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.42),
                blurRadius: 22,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: poster == null
                ? const _PosterFallback()
                : CachedNetworkImage(
                    imageUrl: poster,
                    fit: BoxFit.cover,
                    memCacheWidth: 420,
                    placeholder: (_, __) => const _PosterFallback(),
                    errorWidget: (_, __, ___) => const _PosterFallback(),
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

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.88),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HeroFallback extends StatelessWidget {
  const _HeroFallback({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            theme.primaryColor.withOpacity(0.30),
            Colors.black,
          ],
        ),
      ),
    );
  }
}

class _HeroCopySkeleton extends StatelessWidget {
  const _HeroCopySkeleton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(height: 260);
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      child: const Center(
        child: Icon(Icons.local_movies_outlined, color: Colors.white54),
      ),
    );
  }
}
