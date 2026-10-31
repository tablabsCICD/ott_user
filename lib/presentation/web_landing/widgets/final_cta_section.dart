import 'package:flutter/material.dart';
import 'package:ott/l10n/app_localizations.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';

class FinalCtaSection extends StatelessWidget {
  const FinalCtaSection({
    super.key,
    required this.onWatchContent,
    required this.onPublishContent,
    required this.onEarnReferrals,
  });

  final VoidCallback onWatchContent;
  final VoidCallback onPublishContent;
  final VoidCallback onEarnReferrals;

  @override
  Widget build(BuildContext context) {
    final lang = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 720;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final horizontalPadding = isMobile ? 18.0 : (isTablet ? 32.0 : 56.0);

    final cards = [
      _CtaCardData(
        icon: Icons.play_circle_fill_rounded,
        title: lang.watchContent,
        body: lang.streamPremiumMoviesSeries,
        action: lang.userPortal,
        onTap: onWatchContent,
      ),
      _CtaCardData(
        icon: Icons.cloud_upload_rounded,
        title: lang.publishContent,
        body: lang.publishContentDescription,
        action: lang.productionHousePortal,
        onTap: onPublishContent,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        isMobile ? 42 : 64,
      ),
      child: Column(
        children: [
          Text(
            lang.startJourneyToday,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: width < 600 ? 28 : 38,
              height: 1.10,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 32),
          if (compact)
            Column(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  _CtaCard(data: cards[i]),
                  if (i != cards.length - 1) const SizedBox(height: 16),
                ],
              ],
            )
          else
            Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(
                    child: _CtaCard(data: cards[i]),
                  ),
                  if (i != cards.length - 1) const SizedBox(width: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _CtaCardData {
  const _CtaCardData({
    required this.icon,
    required this.title,
    required this.body,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final String action;
  final VoidCallback onTap;
}

class _CtaCard extends StatefulWidget {
  const _CtaCard({required this.data});
  final _CtaCardData data;

  @override
  State<_CtaCard> createState() => _CtaCardState();
}

class _CtaCardState extends State<_CtaCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.data.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 230,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _hovered ? const Color(0xFF222C5A) : const Color(0xFF192247),
                _hovered ? const Color(0xFF2E1523) : const Color(0xFF210E17),
              ],
            ),
            border: Border.all(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.35)
                  : Colors.white.withValues(alpha: 0.12),
              width: _hovered ? 1.4 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _hovered ? 0.70 : 0.50),
                blurRadius: _hovered ? 22 : 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: FilmytellTheme.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: FilmytellTheme.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(widget.data.icon, color: Colors.white, size: 26),
              ),
              const Spacer(),
              Text(
                widget.data.title,
                style: FilmytellTheme.font(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.data.body,
                style: FilmytellTheme.font(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: FilmytellTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: FilmytellTheme.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.data.action,
                          style: FilmytellTheme.font(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
