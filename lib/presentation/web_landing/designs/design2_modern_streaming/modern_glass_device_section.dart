import 'package:flutter/material.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// Modern glassmorphism section highlighting technical streaming excellence & device access.
class ModernGlassDeviceSection extends StatelessWidget {
  const ModernGlassDeviceSection({
    super.key,
    required this.onExplorePlans,
  });

  final VoidCallback onExplorePlans;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final paddingHorizontal = isMobile ? 20.0 : 64.0;

    final features = [
      _FeatureData(
        icon: Icons.high_quality_rounded,
        title: '4K Ultra HD & HDR10',
        desc: 'Experience razor-sharp clarity, vivid color dynamics, and deep contrast tuned for modern OLED & 4K displays.',
      ),
      _FeatureData(
        icon: Icons.surround_sound_rounded,
        title: 'Dolby Atmos Spatial Audio',
        desc: 'Immerse yourself in three-dimensional theater sound that moves around you with lifelike precision.',
      ),
      _FeatureData(
        icon: Icons.devices_other_rounded,
        title: 'Simultaneous Multi-Screen',
        desc: 'Stream across TV, mobile, tablet, and desktop without interrupting family or friends on other devices.',
      ),
      _FeatureData(
        icon: Icons.download_for_offline_rounded,
        title: 'Smart Offline Downloads',
        desc: 'Save your favorite movies and episodes to watch on flights, commutes, or remote getaways with zero data usage.',
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: 40,
      ),
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(colors.isDark ? 0.35 : 0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colors.primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FLAGSHIP STREAMING TECH',
                        style: TextStyle(
                          color: colors.primaryAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Engineered For Audiophiles & Cinephiles',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: isMobile ? 22 : 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                ElevatedButton(
                  onPressed: onExplorePlans,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Get Started Now',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 36),

          // Features 2x2 Grid or 1-column on mobile
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 20,
              childAspectRatio: isMobile ? 2.4 : 2.8,
            ),
            itemBuilder: (context, index) {
              final f = features[index];
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colors.border.withOpacity(0.6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colors.primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Icon(f.icon, color: colors.primaryAccent, size: 24),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            f.desc,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.textMuted,
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeatureData {
  _FeatureData({required this.icon, required this.title, required this.desc});
  final IconData icon;
  final String title;
  final String desc;
}
