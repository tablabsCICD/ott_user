import 'package:flutter/material.dart';

class PromoterSection extends StatelessWidget {
  const PromoterSection({
    super.key,
    required this.onJoin,
  });

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = const [
      _PromoterStep(Icons.person_add_alt_1, 'Register as Promoter',
          'Create your promoter profile.'),
      _PromoterStep(Icons.link_rounded, 'Share Referral Links',
          'Promote content and plans.'),
      _PromoterStep(Icons.account_balance_wallet_outlined, 'Earn Commission',
          'Track earnings and performance.'),
    ];
    final features = const [
      'Referral Tracking',
      'Performance Dashboard',
      'Earnings Reports',
      'Campaign Analytics',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 8, 56, 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Become a Filmytell Promoter',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Earn by promoting content and subscriptions.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.68),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              for (int i = 0; i < steps.length; i++) ...[
                Expanded(
                  child:
                      _PromoterCard(step: steps[i], color: theme.primaryColor),
                ),
                if (i != steps.length - 1) const SizedBox(width: 16),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final feature in features)
                      _SmallFeature(label: feature, color: theme.primaryColor),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onJoin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 17),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Join As Promoter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoterStep {
  const _PromoterStep(this.icon, this.title, this.body);
  final IconData icon;
  final String title;
  final String body;
}

class _PromoterCard extends StatefulWidget {
  const _PromoterCard({required this.step, required this.color});
  final _PromoterStep step;
  final Color color;

  @override
  State<_PromoterCard> createState() => _PromoterCardState();
}

class _PromoterCardState extends State<_PromoterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 190),
        height: 70,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_hovered ? 0.10 : 0.065),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: Colors.white.withOpacity(_hovered ? 0.20 : 0.08)),
          boxShadow: [
            if (_hovered)
              BoxShadow(
                color: widget.color.withOpacity(0.22),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.step.icon, color: widget.color, size: 34),
            const SizedBox(width: 20),
            Text(
              widget.step.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            /*  const SizedBox(width: 10),
            Text(
              widget.step.body,
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                height: 1.42,
                fontWeight: FontWeight.w600,
              ),
            ), */
          ],
        ),
      ),
    );
  }
}

class _SmallFeature extends StatelessWidget {
  const _SmallFeature({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
    );
  }
}
