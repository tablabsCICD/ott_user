import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// Modern streaming platform hero featuring asymmetric typography and
/// stacked floating poster cards with depth and glassmorphism.
class ModernHeroSection extends StatelessWidget {
  const ModernHeroSection({
    super.key,
    required this.items,
    required this.onGetStarted,
    required this.onExploreCatalog,
    required this.onContentTap,
  });

  final List<Content> items;
  final VoidCallback onGetStarted;
  final VoidCallback onExploreCatalog;
  final ValueChanged<Content> onContentTap;

  String? _posterFor(Content content) {
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
    final isMobile = screenWidth < 880;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 20 : 64,
        isMobile ? 90 : 120,
        isMobile ? 20 : 64,
        isMobile ? 40 : 60,
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeadline(context, colors, isMobile: true),
                const SizedBox(height: 36),
                _buildFloatingCardStack(context, colors, isMobile: true),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 5,
                  child: _buildHeadline(context, colors, isMobile: false),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 5,
                  child: _buildFloatingCardStack(context, colors, isMobile: false),
                ),
              ],
            ),
    );
  }

  Widget _buildHeadline(
    BuildContext context,
    LandingThemeColors colors, {
    required bool isMobile,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colors.primaryAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: colors.primaryAccent.withOpacity(0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primaryAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'NEXT-GEN STREAMING ARCHITECTURE',
                style: TextStyle(
                  color: colors.primaryAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Main Statement
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: isMobile ? 32 : 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              height: 1.15,
            ),
            children: [
              const TextSpan(text: 'Stream Without Limits.\n'),
              TextSpan(
                text: 'Stories That Move You.',
                style: TextStyle(
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        colors.primaryAccent,
                        colors.secondaryAccent,
                        const Color(0xFFFF8A00),
                      ],
                    ).createShader(const Rect.fromLTWH(0, 0, 350, 50)),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        Text(
          'Discover thousands of original movies, high-octane series, regional blockbusters, and indie gems streaming in high-fidelity 4K with spatial audio.',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: isMobile ? 14 : 16,
            height: 1.6,
          ),
        ),

        const SizedBox(height: 32),

        // CTA Row
        Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 14 : 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 10,
                shadowColor: colors.primaryAccent.withOpacity(0.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start Streaming Free',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
            OutlinedButton(
              onPressed: onExploreCatalog,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border, width: 1.4),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 26,
                  vertical: isMobile ? 14 : 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Browse Catalog',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingCardStack(
    BuildContext context,
    LandingThemeColors colors, {
    required bool isMobile,
  }) {
    if (items.isEmpty) {
      return Container(
        height: 320,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
      );
    }

    final topItems = items.take(3).toList();
    final cardWidth = isMobile ? 150.0 : 200.0;
    final cardHeight = isMobile ? 220.0 : 290.0;

    return SizedBox(
      height: cardHeight + 40,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Card Left
          if (topItems.length > 1)
            Positioned(
              left: isMobile ? 10 : 30,
              top: 25,
              child: Transform.rotate(
                angle: -0.12,
                child: _buildMiniCard(
                  topItems[1],
                  cardWidth * 0.9,
                  cardHeight * 0.9,
                  colors,
                  opacity: 0.75,
                ),
              ),
            ),

          // Background Card Right
          if (topItems.length > 2)
            Positioned(
              right: isMobile ? 10 : 30,
              top: 25,
              child: Transform.rotate(
                angle: 0.12,
                child: _buildMiniCard(
                  topItems[2],
                  cardWidth * 0.9,
                  cardHeight * 0.9,
                  colors,
                  opacity: 0.75,
                ),
              ),
            ),

          // Main Center Floating Card
          Positioned(
            child: GestureDetector(
              onTap: () => onContentTap(topItems[0]),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: colors.primaryAccent.withOpacity(0.35),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: _buildMiniCard(
                  topItems[0],
                  cardWidth,
                  cardHeight,
                  colors,
                  isCenter: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(
    Content item,
    double width,
    double height,
    LandingThemeColors colors, {
    double opacity = 1.0,
    bool isCenter = false,
  }) {
    final poster = _posterFor(item);
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCenter
                ? colors.primaryAccent.withOpacity(0.8)
                : colors.border.withOpacity(0.5),
            width: isCenter ? 2.0 : 1.0,
          ),
          color: colors.surface,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (poster != null)
                CachedNetworkImage(
                  imageUrl: poster,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(color: colors.surface),
                )
              else
                Container(color: colors.surface),
              if (isCenter)
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.title ?? 'Trending',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
