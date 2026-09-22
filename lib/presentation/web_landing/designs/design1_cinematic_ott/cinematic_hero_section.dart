import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';
import 'package:shimmer/shimmer.dart';

/// Full-width rotating cinematic billboard hero with backdrop art, meta badges,
/// dynamic glowing gradient overlays, and animated entrance.
class CinematicHeroSection extends StatefulWidget {
  const CinematicHeroSection({
    super.key,
    required this.items,
    required this.onWatchNow,
    required this.onPlayTrailer,
  });

  final List<Content> items;
  final ValueChanged<Content> onWatchNow;
  final ValueChanged<Content> onPlayTrailer;

  @override
  State<CinematicHeroSection> createState() => _CinematicHeroSectionState();
}

class _CinematicHeroSectionState extends State<CinematicHeroSection>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _autoPlayTimer;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (widget.items.length > 1) {
      _autoPlayTimer = Timer.periodic(const Duration(seconds: 7), (_) {
        if (!mounted || widget.items.isEmpty) return;
        _selectSlide((_currentIndex + 1) % widget.items.length);
      });
    }
  }

  void _selectSlide(int index) {
    if (index == _currentIndex || widget.items.isEmpty) return;
    _animController.reset();
    setState(() => _currentIndex = index);
    _animController.forward();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String? _backdropFor(Content content) {
    for (final url in content.posterUrlList ?? const <String>[]) {
      if (url.trim().isNotEmpty) return url.trim();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final isDark = colors.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final heroHeight = isMobile ? 520.0 : (screenWidth < 1200 ? 620.0 : 720.0);

    if (widget.items.isEmpty) {
      return Container(
        height: heroHeight,
        color: colors.background,
        child: Center(
          child: CircularProgressIndicator(color: colors.primaryAccent),
        ),
      );
    }

    final currentItem = widget.items[_currentIndex % widget.items.length];
    final backdrop = _backdropFor(currentItem);
    final title = currentItem.title ?? 'Exclusive Premiere';
    final description = currentItem.description ??
        'Experience unmatched cinema streaming on Filmytell. Enjoy award-winning movies and viral web series in 4K Ultra HD.';
    final type = (currentItem.type ?? 'MOVIE').toUpperCase().replaceAll('_', ' ');
    final genres = currentItem.genreList?.take(3).toList() ?? ['Action', 'Drama'];

    return SizedBox(
      height: heroHeight,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Backdrop Image with Crossfade
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: backdrop != null
                ? CachedNetworkImage(
                    key: ValueKey<String>(backdrop),
                    imageUrl: backdrop,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    placeholder: (_, __) => Container(color: colors.surface),
                    errorWidget: (_, __, ___) => Container(color: colors.surface),
                  )
                : Container(
                    key: const ValueKey('placeholder'),
                    color: colors.surface,
                  ),
          ),

          // Multi-layer Cinematic Vignette Gradients
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    colors.background.withOpacity(isDark ? 0.35 : 0.2),
                    colors.background.withOpacity(isDark ? 0.65 : 0.5),
                    colors.background,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    colors.background.withOpacity(isDark ? 0.95 : 0.90),
                    colors.background.withOpacity(isDark ? 0.65 : 0.50),
                    Colors.transparent,
                  ],
                  stops: [0.0, isMobile ? 0.75 : 0.50, 1.0],
                ),
              ),
            ),
          ),

          // Glowing Spotlight Cone
          Positioned(
            left: -100,
            top: 0,
            width: 500,
            height: 500,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colors.primaryAccent.withOpacity(isDark ? 0.25 : 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Hero Content Details
          Positioned(
            left: isMobile ? 20 : 64,
            right: isMobile ? 20 : (screenWidth > 1200 ? screenWidth * 0.42 : screenWidth * 0.25),
            bottom: isMobile ? 40 : 80,
            child: AnimatedBuilder(
              animation: _animController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.translate(
                    offset: _slideAnimation.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Tag pills (Featured + Type + Quality)
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primaryAccent,
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: colors.primaryAccent.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Text(
                                'FEATURED PREMIERE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.surface.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: colors.border),
                              ),
                              child: Text(
                                type,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colors.goldAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: colors.goldAccent.withOpacity(0.5),
                                ),
                              ),
                              child: Text(
                                '★ 4K HDR • DOLBY 5.1',
                                style: TextStyle(
                                  color: colors.goldAccent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Title
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: isMobile ? 28 : (screenWidth < 1200 ? 42 : 52),
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Genres
                        if (genres.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            children: genres
                                .map((g) => Text(
                                      '• $g',
                                      style: TextStyle(
                                        color: colors.textSecondary,
                                        fontSize: isMobile ? 12 : 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ))
                                .toList(),
                          ),

                        const SizedBox(height: 14),

                        // Description
                        Text(
                          description,
                          maxLines: isMobile ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: isMobile ? 13 : 15,
                            height: 1.55,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // CTA Buttons
                        Wrap(
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => widget.onWatchNow(currentItem),
                              icon: const Icon(Icons.play_arrow_rounded, size: 24),
                              label: const Text('Watch Now'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colors.primaryAccent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 28,
                                  vertical: isMobile ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                                elevation: 8,
                                shadowColor: colors.primaryAccent.withOpacity(0.55),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => widget.onPlayTrailer(currentItem),
                              icon: const Icon(Icons.videocam_outlined, size: 20),
                              label: const Text('Watch Trailer'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colors.textPrimary,
                                side: BorderSide(
                                  color: colors.textPrimary.withOpacity(0.35),
                                  width: 1.4,
                                ),
                                backgroundColor: colors.surface.withOpacity(0.45),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 18 : 24,
                                  vertical: isMobile ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Slide Indicator Dots Bottom Right
          if (widget.items.length > 1)
            Positioned(
              right: isMobile ? 20 : 64,
              bottom: isMobile ? 20 : 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  widget.items.take(6).length,
                  (index) => GestureDetector(
                    onTap: () => _selectSlide(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 28 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? colors.primaryAccent
                            : colors.textMuted.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
