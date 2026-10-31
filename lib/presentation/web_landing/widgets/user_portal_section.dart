import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';
import 'package:ott/presentation/web_landing/widgets/play_store_button.dart';

class UserPortalSection extends StatelessWidget {
  const UserPortalSection({
    super.key,
    required this.onGetStarted,
    required this.onExplorePlans,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onExplorePlans;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final horizontalPadding = isMobile ? 18.0 : (isTablet ? 32.0 : 56.0);

    final steps = [
      (
        stepNum: 1,
        title: lang.browseMoviesAndSeries,
        subtitle: lang.createAccountMobileOtp,
        icon: Icons.movie_creation_rounded,
      ),
      (
        stepNum: 2,
        title: lang.payOnlyContentChoose,
        subtitle: lang.payPerMovie,
        icon: Icons.payments_rounded,
      ),
      (
        stepNum: 3,
        title: lang.giftMoviesFriendsFamily,
        subtitle: lang.buildWatchlistContinueWatching,
        icon: Icons.card_giftcard_rounded,
      ),
      (
        stepNum: 4,
        title: lang.watchAcrossDevices,
        subtitle: lang.multiDeviceAccess,
        icon: Icons.devices_rounded,
      ),
    ];

    final features = [
      lang.payPerMovie,
      lang.movieGifting,
      lang.watchlist,
      lang.continueWatching,
      lang.multiDeviceAccess,
      lang.regionalContent,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        12,
        horizontalPadding,
        isMobile ? 42 : 64,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            lang.viewersEntertainmentTitle,
            style: FilmytellTheme.font(
              color: Colors.white,
              fontSize: isMobile ? 24 : 32,
              height: 1.18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Text(
              lang.viewersEntertainmentDescription,
              style: FilmytellTheme.bodyLarge(
                isMobile: isMobile,
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Feature pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final feature in features) _UserFeatureBadge(label: feature),
            ],
          ),
          const SizedBox(height: 28),
          // 4-Step Netflix-Style Information Cards Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final fitsInRow = maxWidth >= 960;

              if (fitsInRow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < steps.length; i++) ...[
                      Expanded(
                        child: SizedBox(
                          height: 165,
                          child: _HowItWorksCard(
                            stepNum: steps[i].stepNum,
                            title: steps[i].title,
                            subtitle: steps[i].subtitle,
                            icon: steps[i].icon,
                          ),
                        ),
                      ),
                      if (i < steps.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                );
              }

              // Horizontal scrollable progression for tablet / mobile viewports
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (int i = 0; i < steps.length; i++) ...[
                      SizedBox(
                        width: isMobile ? 210 : 230,
                        height: 165,
                        child: _HowItWorksCard(
                          stepNum: steps[i].stepNum,
                          title: steps[i].title,
                          subtitle: steps[i].subtitle,
                          icon: steps[i].icon,
                        ),
                      ),
                      if (i < steps.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Action buttons & store badges
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _UserPortalPrimaryButton(
                label: lang.getStarted,
                onPressed: onGetStarted,
              ),
              const PlayStoreButton(
                appName: 'Filmytell',
                playStoreUrl: AppConstant.playStoreLink,
              ),
              const AppStoreButton(
                appName: 'Filmytell',
                appStoreUrl: AppConstant.appStoreLink,
              ),
              const AmazonFireTvButton(
                appName: 'Filmytell',
                amazonUrl: AppConstant.amazonFireTvLink,
              ),
              const JioStoreButton(
                appName: 'Filmytell',
                jioStoreUrl: AppConstant.jioStoreLink,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HowItWorksCard extends StatefulWidget {
  const _HowItWorksCard({
    required this.stepNum,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final int stepNum;
  final String title;
  final String subtitle;
  final IconData icon;

  @override
  State<_HowItWorksCard> createState() => _HowItWorksCardState();
}

class _HowItWorksCardState extends State<_HowItWorksCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _hovered ? FilmytellTheme.primary : FilmytellTheme.primary,
          border: Border.all(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.60)
                : Colors.white.withValues(alpha: 0.25),
            width: _hovered ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: FilmytellTheme.primary
                  .withValues(alpha: _hovered ? 0.45 : 0.25),
              blurRadius: _hovered ? 20 : 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Step Badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 3.5,
              ),
              decoration: BoxDecoration(
                //color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '${AppLocalizations.of(context)!.step} 0${widget.stepNum}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            const SizedBox(height: 7),
            // Step Action Title
            Text(
              widget.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: FilmytellTheme.font(
                color: Colors.white,
                fontSize: 14.5,
                height: 1.22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            // Step Description
            Expanded(
              child: Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: FilmytellTheme.font(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 12.5,
                  height: 1.32,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            // Bottom-Right Positioned Step Icon (Netflix "More reasons to join" layout)
            Align(
              alignment: Alignment.bottomRight,
              child: AnimatedScale(
                scale: _hovered ? 1.08 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        Colors.white.withValues(alpha: _hovered ? 0.28 : 0.18),
                    border: Border.all(
                      color: Colors.white
                          .withValues(alpha: _hovered ? 0.65 : 0.35),
                    ),
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserFeatureBadge extends StatelessWidget {
  const _UserFeatureBadge({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: FilmytellTheme.primary.withValues(alpha: 0.30),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.88),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _UserPortalPrimaryButton extends StatefulWidget {
  const _UserPortalPrimaryButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_UserPortalPrimaryButton> createState() =>
      _UserPortalPrimaryButtonState();
}

class _UserPortalPrimaryButtonState extends State<_UserPortalPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: _hovered
                ? const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFE50914)],
                  )
                : const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFE50914)],
                  ),
            boxShadow: [
              BoxShadow(
                color: FilmytellTheme.primary
                    .withValues(alpha: _hovered ? 0.45 : 0.24),
                blurRadius: _hovered ? 18 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              minimumSize: const Size(0, 54),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                letterSpacing: 0.3,
              ),
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}
