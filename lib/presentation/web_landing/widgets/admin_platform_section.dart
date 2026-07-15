import 'package:flutter/material.dart';

class AdminPlatformSection extends StatelessWidget {
  const AdminPlatformSection({
    super.key,
    required this.onLearnMore,
  });

  final VoidCallback onLearnMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final modules = const [
      'User Management',
      'Content Approval',
      'Subscription Management',
      'Revenue Reports',
      'Production House Management',
      'Promoter Management',
      'Analytics Dashboard',
      'Advertisement Management',
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 8, 56, 70),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: _AdminMockup(color: theme.primaryColor),
          ),
          const SizedBox(width: 44),
          Expanded(
            flex: 9,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OTT ADMIN PLATFORM',
                  style: TextStyle(
                    color: theme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Powerful OTT Management Platform',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Manage the complete OTT ecosystem from one place.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.68),
                    fontSize: 17,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final module in modules)
                      _AdminModule(label: module, color: theme.primaryColor),
                  ],
                ),
                const SizedBox(height: 30),
                OutlinedButton(
                  onPressed: onLearnMore,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: theme.primaryColor.withOpacity(0.75)),
                    padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 17),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Learn More'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminMockup extends StatelessWidget {
  const _AdminMockup({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 390,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.065),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 44,
            offset: const Offset(0, 24),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(height: 12, width: 80, color: color),
              const Spacer(),
              for (final opacity in [0.20, 0.14, 0.10])
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  height: 28,
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 118,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(child: _MetricBox(color: color)),
                            const SizedBox(width: 14),
                            Expanded(child: _MetricBox(color: Colors.white)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        flex: 2,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                for (final height in [68.0, 105.0, 82.0, 138.0, 118.0, 156.0])
                                  Expanded(
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 8),
                                      height: height,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.65),
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.28),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            color: color.withOpacity(0.24),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _AdminModule extends StatelessWidget {
  const _AdminModule({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18)),
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
