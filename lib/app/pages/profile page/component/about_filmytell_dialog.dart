import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/constant/image_constant.dart';

class AboutFilmytellDialog {
  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => const _AboutFilmytellDialogBody(),
    );
  }
}

class _AboutFilmytellDialogBody extends StatefulWidget {
  const _AboutFilmytellDialogBody();

  @override
  State<_AboutFilmytellDialogBody> createState() =>
      _AboutFilmytellDialogBodyState();
}

class _AboutFilmytellDialogBodyState extends State<_AboutFilmytellDialogBody> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      if (!mounted) return;
      setState(() {
        _visible = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.canvasColor;
    final screenWidth = MediaQuery.of(context).size.width;
    final useParallelSections = screenWidth > 760;

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
        offset: _visible ? Offset.zero : const Offset(0, 0.06),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: _visible ? 1 : 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 980),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.14),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.cardColor.withOpacity(0.96),
                  theme.cardColor.withOpacity(0.88),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.24),
                  blurRadius: 36,
                  offset: const Offset(0, 24),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                  Positioned(
                    top: -80,
                    right: -30,
                    child: _GlowOrb(
                      size: 220,
                      color: theme.primaryColor.withOpacity(0.16),
                    ),
                  ),
                  Positioned(
                    bottom: -90,
                    left: -40,
                    child: _GlowOrb(
                      size: 240,
                      color: textColor.withOpacity(0.05),
                    ),
                  ),
                  Positioned(
                    top: 120,
                    left: 30,
                    right: 30,
                    child: Container(
                      height: 1,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                  SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHeader(context, textColor),
                          const SizedBox(height: 26),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            child: useParallelSections
                                ? Row(
                                    key: const ValueKey('parallel'),
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 11,
                                        child: _buildSectionOne(
                                          context,
                                          textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 20),
                                      Expanded(
                                        flex: 9,
                                        child: _buildSectionTwo(
                                          context,
                                          textColor,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    key: const ValueKey('stacked'),
                                    children: [
                                      _buildSectionOne(context, textColor),
                                      const SizedBox(height: 18),
                                      _buildSectionTwo(context, textColor),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                backgroundColor: theme.primaryColor,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Close',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Color textColor) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'About Us',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Filmytell',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.primaryColor.withOpacity(0.12),
                ),
                child: Text(
                  'App Version ${AppConstant.appVersion}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: textColor.withOpacity(0.08),
          ),
          icon: Icon(
            Icons.close_rounded,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionOne(BuildContext context, Color textColor) {
    final theme = Theme.of(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.96, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          alignment: Alignment.topLeft,
          child: child,
        );
      },
      child: _GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stories, series, and cinema that travel with you.',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: textColor,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Filmytell is a premium OTT platform bringing you movies, series, and exclusive content across multiple languages. Enjoy seamless streaming, smart recommendations, and a cinematic experience across all your devices.',
              style: TextStyle(
                fontSize: 14,
                height: 1.75,
                color: textColor.withOpacity(0.78),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.primaryColor.withOpacity(0.16),
                    theme.primaryColor.withOpacity(0.06),
                  ],
                ),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.18),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _HighlightMetric(
                      value: '24/7',
                      label: 'Entertainment access',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 44,
                    color: Colors.white.withOpacity(0.08),
                  ),
                  Expanded(
                    child: _HighlightMetric(
                      value: 'Multi',
                      label: 'Language experience',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Platform Preview',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    height: 230,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.primaryColor.withOpacity(0.20),
                          Colors.black.withOpacity(0.08),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              ImageConstant.logo,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Colors.black.withOpacity(0.24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.08),
                              ),
                            ),
                            child: const Text(
                              'A richer, smoother, cinematic viewing experience.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildSectionTwo(BuildContext context, Color textColor) {
    final theme = Theme.of(context);

    return _GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Filmytell feels premium',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 18),
          const _AboutFeatureTile(
            icon: Icons.movie_creation_outlined,
            title: 'Premium streaming',
            subtitle: 'Enjoy handpicked movies, series, and exclusive drops.',
          ),
          const SizedBox(height: 12),
          const _AboutFeatureTile(
            icon: Icons.language_rounded,
            title: 'Multi-language library',
            subtitle: 'Discover stories across languages and audiences.',
          ),
          const SizedBox(height: 12),
          const _AboutFeatureTile(
            icon: Icons.auto_awesome_outlined,
            title: 'Smart discovery',
            subtitle: 'Find content faster with a smooth curated experience.',
          ),
          const SizedBox(height: 12),
          const _AboutFeatureTile(
            icon: Icons.devices_outlined,
            title: 'Cross-device comfort',
            subtitle: 'A consistent experience built for all your screens.',
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: theme.primaryColor.withOpacity(0.10),
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Experience',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: theme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Designed to make browsing, discovering, and watching feel elevated from the first tap.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: textColor.withOpacity(0.82),
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

class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withOpacity(0.045),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: child,
    );
  }
}

class _HighlightMetric extends StatelessWidget {
  const _HighlightMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).canvasColor;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _AboutFeatureTile extends StatelessWidget {
  const _AboutFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.canvasColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: theme.primaryColor.withOpacity(0.12),
            ),
            child: Icon(
              icon,
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.55,
                    color: textColor.withOpacity(0.72),
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

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withOpacity(0),
            ],
          ),
        ),
      ),
    );
  }
}
