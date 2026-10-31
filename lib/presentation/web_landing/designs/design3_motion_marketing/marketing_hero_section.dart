import 'package:flutter/material.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// High-impact marketing hero with animated headline, glowing CTA, and dynamic preview cards.
class MarketingHeroSection extends StatelessWidget {
  const MarketingHeroSection({
    super.key,
    required this.onGetStarted,
    required this.onWatchTrailers,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onWatchTrailers;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final isDark = colors.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        isMobile ? 24 : 64,
        isMobile ? 100 : 140,
        isMobile ? 24 : 64,
        isMobile ? 50 : 80,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Marketing Pill Tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.primaryAccent.withOpacity(0.18),
                  colors.secondaryAccent.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colors.primaryAccent.withOpacity(0.5),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primaryAccent.withOpacity(0.2),
                  blurRadius: 16,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: colors.goldAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  'INDIA’S FASTEST GROWING INDIE & REGIONAL OTT',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: isMobile ? 10 : 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Massive Hero Statement
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: isMobile ? 36 : 64,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.0,
                  height: 1.1,
                ),
                children: [
                  const TextSpan(text: 'Endless Stories.\n'),
                  TextSpan(
                    text: 'Infinite Cinema Magic.',
                    style: TextStyle(
                      foreground: Paint()
                        ..shader = LinearGradient(
                          colors: [
                            colors.primaryAccent,
                            colors.secondaryAccent,
                            colors.goldAccent,
                          ],
                        ).createShader(const Rect.fromLTWH(0, 0, 500, 70)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Subtitle
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Text(
              'Stream groundbreaking originals, uncut film festival winners, viral comedy shorts, and heart-pounding thrillers in breathtaking 4K HDR audio-visual quality.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: isMobile ? 15 : 18,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 36),

          // High-Conversion CTA Buttons
          Wrap(
            spacing: 16,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: onGetStarted,
                icon: const Icon(Icons.flash_on_rounded, size: 22),
                label: const Text('Start Watching Free'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primaryAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 36,
                    vertical: isMobile ? 16 : 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 12,
                  shadowColor: colors.primaryAccent.withOpacity(0.6),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onWatchTrailers,
                icon: const Icon(Icons.play_circle_outline_rounded, size: 22),
                label: const Text('Watch Free Trailers'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.textPrimary,
                  side: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.3) : colors.border,
                    width: 1.6,
                  ),
                  backgroundColor: colors.surface.withOpacity(0.6),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 22 : 30,
                    vertical: isMobile ? 16 : 20,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Guarantee badge
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: colors.goldAccent),
              const SizedBox(width: 6),
              Text(
                'No credit card required for free catalog • Instant access on any device',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
