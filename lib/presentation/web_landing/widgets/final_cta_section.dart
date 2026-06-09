import 'package:flutter/material.dart';

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
    final cards = [
      _CtaCardData(
        icon: Icons.play_circle_fill_rounded,
        title: 'Watch Content',
        body: 'Stream premium movies, series and mini series.',
        action: 'User Portal',
        onTap: onWatchContent,
      ),
      _CtaCardData(
        icon: Icons.cloud_upload_rounded,
        title: 'Publish Content',
        body: 'Upload, manage and monetize your releases.',
        action: 'Production House Portal',
        onTap: onPublishContent,
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(56, 8, 56, 70),
      padding: const EdgeInsets.all(38),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.primaryColor.withOpacity(0.58),
            Colors.white.withOpacity(0.08),
            Colors.black,
          ],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withOpacity(0.22),
            blurRadius: 48,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Start Your Filmytell Journey Today',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 42,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Choose how you want to use Filmytell.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.74),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
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
            color: Colors.black.withOpacity(_hovered ? 0.42 : 0.28),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: Colors.white.withOpacity(_hovered ? 0.22 : 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(widget.data.icon, color: Colors.white, size: 38),
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
                  Text(
                    widget.data.action,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
