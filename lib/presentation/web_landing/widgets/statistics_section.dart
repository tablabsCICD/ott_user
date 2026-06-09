import 'package:flutter/material.dart';

class StatisticsSection extends StatelessWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = const [
      _StatItem(10000, '10K+', 'Users'),
      _StatItem(500, '500+', 'Movies'),
      _StatItem(100, '100+', 'Series'),
      _StatItem(50, '50+', 'Production Houses'),
      _StatItem(365, 'Growing', 'Every Day'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(56, 8, 56, 70),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.09)),
      ),
      child: Column(
        children: [
          const Text(
            'Filmytell By The Numbers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              for (final stat in stats)
                Expanded(
                  child: _CounterCard(
                    stat: stat,
                    color: theme.primaryColor,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem {
  const _StatItem(this.value, this.display, this.label);
  final int value;
  final String display;
  final String label;
}

class _CounterCard extends StatelessWidget {
  const _CounterCard({
    required this.stat,
    required this.color,
  });

  final _StatItem stat;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: stat.value.toDouble()),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        final label = stat.display == 'Growing'
            ? 'Growing'
            : stat.display.replaceFirst(
                RegExp(r'^\d+[K]?\+?'), _format(value, stat.display));
        return Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 36,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stat.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.68),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        );
      },
    );
  }

  String _format(double value, String display) {
    if (display.contains('K')) {
      return '${(value / 1000).clamp(0, 10).toStringAsFixed(0)}K+';
    }
    return '${value.toInt()}+';
  }
}
