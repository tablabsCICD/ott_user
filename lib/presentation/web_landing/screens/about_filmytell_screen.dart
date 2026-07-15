import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';

class AboutFilmytellScreen extends StatelessWidget {
  const AboutFilmytellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFD80D18);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Container(
            height: 56,
            color: red,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (!(kIsWeb || ResponsiveWidget.isTv(context))) ...[
                  IconButton(
                    onPressed: () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                const Text(
                  'About Filmytell',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 52),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Filmytell - Rent Movies & Series',
                    style: TextStyle(
                      color: Color(0xFFE8E8EE),
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'No ads. No subscriptions. Just pure cinema.',
                    style: TextStyle(
                      color: Color(0xFF9D9DA3),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _RedChip(label: 'Pay Per View'),
                      _RedChip(label: 'No Ads'),
                      _RedChip(label: 'Exclusive'),
                    ],
                  ),
                  SizedBox(height: 26),
                  Text(
                    'Your personal theatre in your pocket.\nWatch movies, web series anytime, anywhere.',
                    style: TextStyle(
                      color: Color(0xFFE8E8EE),
                      fontSize: 15,
                      height: 1.32,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 28),
                  Text(
                    'Why Filmytell',
                    style: TextStyle(
                      color: Color(0xFFE8E8EE),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 16),
                  _ReasonRow(
                    icon: Icons.payments_outlined,
                    title: 'Pay Per View',
                    subtitle: 'Only pay for what you watch',
                  ),
                  SizedBox(height: 16),
                  _ReasonRow(
                    icon: Icons.block_rounded,
                    title: 'No Ads',
                    subtitle: 'Uninterrupted experience',
                  ),
                  SizedBox(height: 16),
                  _ReasonRow(
                    icon: Icons.public_rounded,
                    title: 'Exclusive Content',
                    subtitle: 'Independent & unique stories',
                  ),
                  SizedBox(height: 38),
                  Text(
                    'Watch',
                    style: TextStyle(
                      color: Color(0xFFE8E8EE),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _DarkChip(label: 'Movies'),
                      _DarkChip(label: 'Web Series'),
                      _DarkChip(label: 'Regional'),
                    ],
                  ),
                  SizedBox(height: 26),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          title: 'Viewers',
                          lines: ['Watch anytime', 'No commitment'],
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          title: 'Creators',
                          lines: ['Reach global audience'],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: Text(
                      'Cinema Ka Naya Ghar',
                      style: TextStyle(
                        color: red,
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RedChip extends StatelessWidget {
  const _RedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF330407),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFFF1D28),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DarkChip extends StatelessWidget {
  const _DarkChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF242426),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFE8E8EE),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReasonRow extends StatelessWidget {
  const _ReasonRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 26,
          child: Icon(
            icon,
            color: const Color(0xFFFF1824),
            size: 22,
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFE8E8EE),
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: Color(0xFF9D9DA3),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.lines,
  });

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 84),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF242424),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE8E8EE),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Text(
              line,
              style: const TextStyle(
                color: Color(0xFFB4B4B8),
                fontSize: 15,
                height: 1.25,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}
