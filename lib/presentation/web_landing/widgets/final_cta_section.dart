import 'package:flutter/material.dart';
import 'package:ott/l10n/app_localizations.dart';

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
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 700;
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
        color: const Color(0xFF101010),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.070),
            Colors.white.withOpacity(0.032),
            Colors.black.withOpacity(0.16),
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.11)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            lang.readyToStart,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            lang.startJourneyToday,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: width < 600 ? 30 : 40,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            lang.chooseHowUseFilmytell,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          if (compact)
            Column(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  _CtaCard(data: cards[i], color: theme.primaryColor),
                  if (i != cards.length - 1) const SizedBox(height: 16),
                ],
              ],
            )
          else
            Row(
              children: [
                for (int i = 0; i < cards.length; i++) ...[
                  Expanded(
                    child: _CtaCard(data: cards[i], color: theme.primaryColor),
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
  const _CtaCard({required this.data, required this.color});
  final _CtaCardData data;
  final Color color;

  @override
  State<_CtaCard> createState() => _CtaCardState();
}

class _CtaCardState extends State<_CtaCard> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.data.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 230,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(_hovered ? 0.42 : 0.26),
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
              color: _hovered
                  ? widget.color.withOpacity(0.44)
                  : Colors.white.withOpacity(0.10),
            ),
            boxShadow: [
              if (_hovered)
                BoxShadow(
                  color: widget.color.withOpacity(0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
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
                  color: widget.color.withOpacity(_hovered ? 0.24 : 0.14),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: widget.color.withOpacity(0.32)),
                ),
                child: Icon(widget.data.icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                widget.data.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.data.body,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.66),
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(_hovered ? 0.22 : 0.14),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: widget.color.withOpacity(0.28)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.data.action,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
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
