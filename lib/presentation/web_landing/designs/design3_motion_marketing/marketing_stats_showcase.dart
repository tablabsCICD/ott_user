import 'package:flutter/material.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// Live platform metrics and milestone counters showcase.
class MarketingStatsShowcase extends StatelessWidget {
  const MarketingStatsShowcase({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    final stats = [
      _StatItem(
        value: '100K+',
        label: 'Hours of Cinema',
        desc: 'Curated movies, series & shorts',
      ),
      _StatItem(
        value: '4K HDR',
        label: 'Master Quality',
        desc: 'Ultra HD with Dolby Atmos sound',
      ),
      _StatItem(
        value: '25+',
        label: 'Languages Supported',
        desc: 'Pan-Indian & international cinema',
      ),
      _StatItem(
        value: '99.9%',
        label: 'Buffer-Free CDN',
        desc: 'Lightning-fast global edge streaming',
      ),
    ];

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 20,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 32,
        vertical: isMobile ? 24 : 32,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: isMobile
          ? GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: stats.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 20,
                childAspectRatio: 1.4,
              ),
              itemBuilder: (context, index) => _buildStat(colors, stats[index]),
            )
          : Row(
              children: stats.map((s) {
                return Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: stats.last == s
                          ? null
                          : Border(
                              right: BorderSide(
                                color: colors.border.withOpacity(0.6),
                              ),
                            ),
                    ),
                    child: _buildStat(colors, s),
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _buildStat(LandingThemeColors colors, _StatItem stat) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          stat.value,
          style: TextStyle(
            color: colors.primaryAccent,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stat.label,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          stat.desc,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _StatItem {
  _StatItem({required this.value, required this.label, required this.desc});
  final String value;
  final String label;
  final String desc;
}
