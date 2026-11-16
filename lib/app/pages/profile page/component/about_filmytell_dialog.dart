import 'package:flutter/material.dart';
import 'package:ott/app/pages/profile%20page/component/profile_detail_shell.dart';
import 'package:ott/app/provider/themeProvider.dart';
import 'package:ott/app/widgets/tv/tv_design.dart';
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

    // Android TV: compact two-column page that fits the 540 px canvas.
    if (ResponsiveWidget.isAndroidTv(context)) {
      return _buildTv(context, theme, selectedThemeData.primaryColor);
    }

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

  // ===========================================================================
  // ANDROID TV
  // ===========================================================================

  Widget _buildTv(BuildContext context, ThemeData theme, Color brand) {
    final body = TextStyle(
      color: theme.canvasColor.withValues(alpha: 0.82),
      fontSize: 12.5,
      height: 1.4,
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nothing else on this page is interactive, so Back takes focus.
          const TvDetailHeader(title: 'About Filmytell', autofocusBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                TvDesign.pageGutter,
                0,
                TvDesign.pageGutter,
                20,
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 860),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: TvPanel(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Filmytell – Rent Movies & Series',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.canvasColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'No ads. No subscriptions. Just pure cinema.',
                                style: TvDesign.caption(theme)
                                    .copyWith(fontSize: 12),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _Badge('Pay Per View', brand),
                                  _Badge('No Ads', brand),
                                  _Badge('Exclusive', brand),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Your personal theatre in your pocket.\n'
                                'Watch movies, web series & mini series anytime, anywhere.',
                                style: body,
                              ),
                              const SizedBox(height: 14),
                              Text('Watch', style: TvDesign.sectionTitle(theme)),
                              const SizedBox(height: 8),
                              const Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _Chip('Movies'),
                                  _Chip('Web Series'),
                                  _Chip('Mini Series'),
                                  _Chip('Regional'),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Cinema Ka Naya Ghar',
                                style: TextStyle(
                                  color: brand,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TvSectionHeader(
                              'Why Filmytell',
                              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
                            ),
                            TvPanel(
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 2),
                              child: Column(
                                children: [
                                  _FeatureTile(
                                    icon: Icons.payments_outlined,
                                    title: 'Pay Per View',
                                    subtitle: 'Only pay for what you watch',
                                    color: brand,
                                  ),
                                  _FeatureTile(
                                    icon: Icons.block,
                                    title: 'No Ads',
                                    subtitle: 'Uninterrupted experience',
                                    color: brand,
                                  ),
                                  _FeatureTile(
                                    icon: Icons.public,
                                    title: 'Exclusive Content',
                                    subtitle: 'Independent & unique stories',
                                    color: brand,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
    final isTv = ResponsiveWidget.isAndroidTv(context);
    return Container(
      padding: isTv
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withOpacity(0.15),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: isTv ? 11 : null,
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
    final isTv = ResponsiveWidget.isAndroidTv(context);
    final theme = Theme.of(context);
    return Container(
      padding: isTv
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isTv ? theme.scaffoldBackgroundColor : theme.cardColor,
      ),
      child: isTv
          ? Text(
              label,
              style: TextStyle(color: theme.canvasColor, fontSize: 11.5),
            )
          : Text(label),
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
    final isTv = ResponsiveWidget.isAndroidTv(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: isTv ? 18 : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: isTv
                        ? TextStyle(
                            color: theme.canvasColor,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          )
                        : const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  subtitle,
                  style: isTv
                      ? TvDesign.caption(theme)
                      : TextStyle(color: theme.hintColor),
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
    if (ResponsiveWidget.isAndroidTv(context)) {
      final theme = Theme.of(context);
      return TvPanel(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: theme.canvasColor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(content, style: TvDesign.caption(theme)),
          ],
        ),
      );
    }
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
