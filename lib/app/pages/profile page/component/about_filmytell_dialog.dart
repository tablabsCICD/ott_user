import 'package:flutter/material.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/device/utils/ResponsiveWidget.dart';
import 'package:provider/provider.dart';

class AboutFilmytellScreen extends StatelessWidget {
  const AboutFilmytellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    final selectedThemeData = themeProvider.getTheme;
    final subText = theme.hintColor;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: const Text(
          'About Filmytell',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🎬 HERO
            Text(
              'Filmytell – Rent Movies & Series',
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),

            Text(
              'No ads. No subscriptions. Just pure cinema.',
              style: theme.textTheme.bodyMedium?.copyWith(color: subText),
            ),

            const SizedBox(height: 16),

            /// 🔴 BADGES
            Wrap(
              spacing: 8,
              children: [
                _Badge('Pay Per View', selectedThemeData.primaryColor),
                _Badge('No Ads', selectedThemeData.primaryColor),
                _Badge('Exclusive', selectedThemeData.primaryColor),
              ],
            ),

            const SizedBox(height: 24),

            /// 📝 INTRO
            Text(
              'Your personal theatre in your pocket.\n'
              'Watch movies, web series & mini series anytime, anywhere.',
              style: theme.textTheme.bodyMedium,
            ),

            const SizedBox(height: 24),

            /// ⭐ FEATURES
            _title(context, 'Why Filmytell'),

            const SizedBox(height: 12),

            _FeatureTile(
              icon: Icons.payments_outlined,
              title: 'Pay Per View',
              subtitle: 'Only pay for what you watch',
              color: selectedThemeData.primaryColor,
            ),
            _FeatureTile(
              icon: Icons.block,
              title: 'No Ads',
              subtitle: 'Uninterrupted experience',
              color: selectedThemeData.primaryColor,
            ),
            _FeatureTile(
              icon: Icons.public,
              title: 'Exclusive Content',
              subtitle: 'Independent & unique stories',
              color: selectedThemeData.primaryColor,
            ),

            const SizedBox(height: 24),

            /// 🎞 CONTENT
            _title(context, 'Watch'),

            const SizedBox(height: 10),

            ResponsiveWidget.isDesktop(context)
                ? Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _Chip('Movies'),
                      _Chip('Web Series'),
                      _Chip('Mini Series'),
                      _Chip('Regional'),
                    ],
                  )
                : Column(
                    children: const [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Chip('Movies'),
                          _Chip('Web Series'),
                        ],
                      ),
                      SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _Chip('Mini Series'),
                          _Chip('Regional'),
                        ],
                      ),
                    ],
                  ),

            const SizedBox(height: 24),

            /// 👥 CARDS
            Row(
              children: const [
                Expanded(
                  child: _MiniCard(
                    title: 'Viewers',
                    content: 'Watch anytime\nNo commitment',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _MiniCard(
                    title: 'Creators',
                    content: 'Reach global audience',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            /// 🎯 CTA
            Center(
              child: Text(
                'Cinema Ka Naya Ghar',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: selectedThemeData.primaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

/// =======================
/// COMPONENTS
/// =======================

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Text(label),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.hintColor),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _MiniCard extends StatelessWidget {
  final String title;
  final String content;

  const _MiniCard({
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(content, style: TextStyle(color: Theme.of(context).hintColor)),
        ],
      ),
    );
  }
}
