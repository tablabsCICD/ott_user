import 'package:flutter/material.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// "Why Filmytell" 4-pillar value proposition grid.
class WhyFilmytellSection extends StatelessWidget {
  const WhyFilmytellSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;
    final paddingHorizontal = isMobile ? 20.0 : 64.0;

    final pillars = [
      _PillarData(
        icon: Icons.movie_filter_rounded,
        title: 'Handpicked Regional & Indie Gems',
        desc: 'Discover powerful untold stories, festival-winning cinema, and breakout regional talents you won’t find on mainstream OTTs.',
        tag: 'EXCLUSIVE TITLES',
      ),
      _PillarData(
        icon: Icons.hd_rounded,
        title: 'Pristine 4K HDR & Spatial Sound',
        desc: 'Every title is encoded with dynamic bitrate algorithms to deliver cinema-grade clarity and Dolby Atmos audio even on modest connections.',
        tag: 'MASTER AUDIO/VISUAL',
      ),
      _PillarData(
        icon: Icons.workspace_premium_rounded,
        title: 'Direct Creator Empowerment',
        desc: 'We share transparent revenue with indie filmmakers and production houses, fueling the next generation of cinematic storytellers.',
        tag: 'ETHICAL STREAMING',
      ),
      _PillarData(
        icon: Icons.lock_open_rounded,
        title: 'Pure Freedom, Zero Lock-In',
        desc: 'Flexible pay-per-view and subscription plans. No hidden lock-in contracts, cancel anytime with a single click.',
        tag: 'USER FIRST',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: paddingHorizontal,
        vertical: 40,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: colors.primaryAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'THE FILMYTELL ADVANTAGE',
              style: TextStyle(
                color: colors.primaryAccent,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Why Audiences Love Filmytell',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: isMobile ? 24 : 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'A streaming platform designed from the ground up for movie lovers and passionate independent filmmakers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textMuted,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 36),

          // 2x2 Pillars Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: pillars.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 1 : 2,
              crossAxisSpacing: 24,
              mainAxisSpacing: 20,
              childAspectRatio: isMobile ? 2.1 : 2.5,
            ),
            itemBuilder: (context, index) {
              final p = pillars[index];
              return _PillarCard(pillar: p, colors: colors);
            },
          ),
        ],
      ),
    );
  }
}

class _PillarData {
  _PillarData({
    required this.icon,
    required this.title,
    required this.desc,
    required this.tag,
  });

  final IconData icon;
  final String title;
  final String desc;
  final String tag;
}

class _PillarCard extends StatefulWidget {
  const _PillarCard({required this.pillar, required this.colors});

  final _PillarData pillar;
  final LandingThemeColors colors;

  @override
  State<_PillarCard> createState() => _PillarCardState();
}

class _PillarCardState extends State<_PillarCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final p = widget.pillar;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _hovered ? colors.surfaceElevated : colors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? colors.primaryAccent.withOpacity(0.7)
                : colors.border,
            width: _hovered ? 1.6 : 1.0,
          ),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: colors.primaryAccent.withOpacity(0.18),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(p.icon, color: colors.primaryAccent, size: 26),
              ),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.tag,
                    style: TextStyle(
                      color: colors.primaryAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.title,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    p.desc,
                    maxLines: 3,
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
      ),
    );
  }
}
