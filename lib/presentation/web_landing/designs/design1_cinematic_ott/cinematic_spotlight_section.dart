import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// Exclusive Premiere spotlight card with widescreen poster and glowing accents.
class CinematicSpotlightSection extends StatelessWidget {
  const CinematicSpotlightSection({
    super.key,
    required this.content,
    required this.onWatchNow,
    required this.onPlayTrailer,
  });

  final Content content;
  final ValueChanged<Content> onWatchNow;
  final ValueChanged<Content> onPlayTrailer;

  String? get _posterUrl {
    final list = content.posterUrlList;
    if (list != null && list.isNotEmpty) {
      for (final url in list) {
        if (url.trim().isNotEmpty) return url.trim();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final isDark = colors.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final poster = _posterUrl;
    final title = content.title ?? 'Exclusive Spotlight';
    final desc = content.description ??
        'Watch the critically acclaimed original streaming only on Filmytell in pristine 4K HDR quality.';

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 36,
      ),
      padding: EdgeInsets.all(isMobile ? 20 : 36),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primaryAccent.withOpacity(isDark ? 0.35 : 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withOpacity(isDark ? 0.15 : 0.08),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (poster != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: CachedNetworkImage(
                        imageUrl: poster,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                _buildSpotlightDetails(context, colors, title, desc, isMobile: true),
              ],
            )
          : Row(
              children: [
                Expanded(
                  flex: 5,
                  child: _buildSpotlightDetails(context, colors, title, desc, isMobile: false),
                ),
                const SizedBox(width: 36),
                if (poster != null)
                  Expanded(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: poster,
                              fit: BoxFit.cover,
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () => onPlayTrailer(content),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primaryAccent,
                                    boxShadow: [
                                      BoxShadow(
                                        color: colors.primaryAccent.withOpacity(0.6),
                                        blurRadius: 20,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
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
    );
  }

  Widget _buildSpotlightDetails(
    BuildContext context,
    LandingThemeColors colors,
    String title,
    String desc, {
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: colors.primaryAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: colors.primaryAccent.withOpacity(0.5)),
              ),
              child: Text(
                'SPOTLIGHT PREMIERE',
                style: TextStyle(
                  color: colors.primaryAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.goldAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '★ 9.4 IMDb',
                style: TextStyle(
                  color: colors.goldAccent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: isMobile ? 24 : 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          desc,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: isMobile ? 13 : 15,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () => onWatchNow(content),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text('Watch Premiere'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => onPlayTrailer(content),
              icon: const Icon(Icons.videocam_outlined, size: 18),
              label: const Text('Play Trailer'),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.textPrimary,
                side: BorderSide(color: colors.border, width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
