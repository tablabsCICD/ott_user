import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/l10n/app_localizations.dart';
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
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 900;
    final steps = [
      lang.createAccountMobileOtp,
      lang.browseMoviesAndSeries,
      lang.payOnlyContentChoose,
      lang.giftMoviesFriendsFamily,
      lang.buildWatchlistContinueWatching,
      lang.watchAcrossDevices,
    ];
    final features = [
      lang.payPerMovie,
      lang.movieGifting,
      lang.watchlist,
      lang.continueWatching,
      lang.multiDeviceAccess,
      lang.regionalContent,
      lang.securePlayback,
    ];

    return Container(
      margin: EdgeInsets.fromLTRB(
        width < 600 ? 16 : (width < 1024 ? 32 : 56),
        8,
        width < 600 ? 16 : (width < 1024 ? 32 : 56),
        width < 600 ? 46 : 70,
      ),
      padding: EdgeInsets.all(width < 600 ? 20 : 34),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.075),
            theme.primaryColor.withOpacity(0.12),
            Colors.white.withOpacity(0.045),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Flex(
        direction: compact ? Axis.vertical : Axis.horizontal,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            fit: FlexFit.loose,
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.howFilmytellWorks,
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  lang.viewersEntertainmentTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width < 600 ? 30 : 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  lang.viewersEntertainmentDescription,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final feature in features)
                      _UserFeatureBadge(
                        label: feature,
                        color: theme.primaryColor,
                      ),
                  ],
                ),
                const SizedBox(height: 30),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: onGetStarted,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 26,
                          vertical: 17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(lang.getStarted),
                    ),
                    OutlinedButton(
                      onPressed: onExplorePlans,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.30)),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 17,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(lang.exploreContent),
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
          ),
          SizedBox(width: compact ? 0 : 42, height: compact ? 30 : 0),
          Flexible(
            fit: FlexFit.loose,
            flex: 9,
            child: Column(
              children: [
                for (int i = 0; i < steps.length; i++)
                  _UserTimelineRow(
                    index: i + 1,
                    label: steps[i],
                    color: theme.primaryColor,
                    isLast: i == steps.length - 1,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserTimelineRow extends StatefulWidget {
  const _UserTimelineRow({
    required this.index,
    required this.label,
    required this.color,
    required this.isLast,
  });

  final int index;
  final String label;
  final Color color;
  final bool isLast;

  @override
  State<_UserTimelineRow> createState() => _UserTimelineRowState();
}

class _UserTimelineRowState extends State<_UserTimelineRow> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    const cardHeight = 54.0;
    const circleSize = 34.0;
    const rowGap = 18.0;
    const circleTop = (cardHeight - circleSize) / 2;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: circleSize,
            height: widget.isLast ? cardHeight : cardHeight + rowGap,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Positioned(
                  top: circleTop + circleSize,
                  child: widget.isLast
                      ? const SizedBox.shrink()
                      : Container(
                          height: rowGap,
                          width: 1,
                          color: Colors.white.withOpacity(0.14),
                        ),
                ),
                Positioned(
                  top: circleTop,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: circleSize,
                    width: circleSize,
                    decoration: BoxDecoration(
                      color: _hovered
                          ? widget.color
                          : Colors.white.withOpacity(0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: widget.color.withOpacity(0.55)),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: cardHeight,
              margin: EdgeInsets.only(bottom: widget.isLast ? 0 : rowGap),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_hovered ? 0.42 : 0.26),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: Colors.white.withOpacity(_hovered ? 0.18 : 0.08),
                ),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UserFeatureBadge extends StatelessWidget {
  const _UserFeatureBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.82),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
