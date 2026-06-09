import 'package:flutter/material.dart';

class ProductionHouseSection extends StatelessWidget {
  const ProductionHouseSection({
    super.key,
    required this.onRegister,
    required this.onLearnMore,
  });

  final VoidCallback onRegister;
  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = const [
      'Register Production House',
      'Complete Verification',
      'Upload Movies, Series and Mini Series',
      'Submit For Approval',
      'Track Revenue & Performance',
      'Reach Global Audience',
    ];
    final modules = const [
      'Content Management',
      'Revenue Tracking',
      'Analytics Dashboard',
      'Approval Workflow',
      'Release Scheduling',
      'Secure Distribution',
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(56, 8, 56, 70),
      padding: const EdgeInsets.all(34),
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HOW PRODUCTION HOUSE WORKS',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'For Production Houses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Upload, manage and monetize your content.',
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
                    for (final module in modules)
                      _ModuleBadge(label: module, color: theme.primaryColor),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: onRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 17),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Register Production House'),
                    ),
                    const SizedBox(width: 14),
                    OutlinedButton(
                      onPressed: onLearnMore,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.30)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 17),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Learn More'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 42),
          Expanded(
            flex: 9,
            child: Column(
              children: [
                for (int i = 0; i < steps.length; i++)
                  _TimelineRow(
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

class _TimelineRow extends StatefulWidget {
  const _TimelineRow({
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
  State<_TimelineRow> createState() => _TimelineRowState();
}

class _TimelineRowState extends State<_TimelineRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        children: [
          Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  color:
                      _hovered ? widget.color : Colors.white.withOpacity(0.10),
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
              if (!widget.isLast)
                Container(
                  height: 38,
                  width: 1,
                  color: Colors.white.withOpacity(0.14),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.only(bottom: widget.isLast ? 0 : 14),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(_hovered ? 0.42 : 0.26),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: Colors.white.withOpacity(_hovered ? 0.18 : 0.08)),
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

class _ModuleBadge extends StatelessWidget {
  const _ModuleBadge({required this.label, required this.color});
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
