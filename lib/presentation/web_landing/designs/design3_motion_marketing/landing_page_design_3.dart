import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_action_handler.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_common_footer.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_common_header.dart';
import 'package:ott/presentation/web_landing/designs/common/motion_particle_field.dart';
import 'package:ott/presentation/web_landing/designs/common/scroll_reveal_wrapper.dart';
import 'package:ott/presentation/web_landing/designs/design1_cinematic_ott/cinematic_rail_section.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/marketing_app_ecosystem_section.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/marketing_hero_section.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/marketing_stats_showcase.dart';
import 'package:ott/presentation/web_landing/designs/design3_motion_marketing/why_filmytell_section.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';
import 'package:ott/presentation/web_landing/models/web_landing_provider.dart';
import 'package:provider/provider.dart';

/// Design 3: Premium Motion & Marketing Landing Page
/// High-impact tech-forward marketing landing page highlighting key value propositions,
/// live statistics counters, 4-pillar advantages, app QR downloads, and curated cinema.
class LandingPageDesign3 extends StatefulWidget {
  const LandingPageDesign3({
    super.key,
    this.customHeaderAction,
  });

  final Widget? customHeaderAction;

  @override
  State<LandingPageDesign3> createState() => _LandingPageDesign3State();
}

class _LandingPageDesign3State extends State<LandingPageDesign3> {
  final ScrollController _scrollController = ScrollController();
  late final WebLandingProvider _provider;
  bool _scrolled = false;
  String _activeNav = 'Home';

  @override
  void initState() {
    super.initState();
    _provider = WebLandingProvider();
    _provider.loadLandingContent();
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (!mounted) return;
    final next = _scrollController.hasClients && _scrollController.offset > 24;
    if (next != _scrolled) {
      setState(() => _scrolled = next);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _handleNav(String label) {
    setState(() => _activeNav = label);
    switch (label) {
      case 'Home':
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutCubic,
        );
        break;
      case 'Movies':
        _provider.loadLatestContentByType('MOVIE');
        break;
      case 'Series':
        _provider.loadLatestContentByType('SERIES');
        break;
      case 'Short Film':
        _provider.loadLatestContentByType('SHORT_FILM');
        break;
      case 'Mini Series':
        _provider.loadLatestContentByType('MINI SERIES');
        break;
    }
  }

  void _openContent(Content content) {
    LandingActionHandler.openLogin(context);
  }

  void _openTrailer(Content content) {
    LandingActionHandler.openTrailer(context, content);
  }

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: colors.background,
        body: Stack(
          children: [
            // Ambient animated particle field
            Positioned.fill(
              child: MotionParticleField(
                primaryColor: colors.primaryAccent,
                secondaryColor: colors.goldAccent,
                particleCount: 26,
              ),
            ),

            Consumer<WebLandingProvider>(
              builder: (context, provider, _) {
                final topTen = provider.topTen;
                final movies = topTen
                    .where((item) => (item.type ?? '').toUpperCase() == 'MOVIE')
                    .toList();
                final series = topTen
                    .where((item) => (item.type ?? '').toUpperCase() == 'SERIES')
                    .toList();

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // High-Impact Marketing Hero Section
                    SliverToBoxAdapter(
                      child: MarketingHeroSection(
                        onGetStarted: () => LandingActionHandler.openLogin(context),
                        onWatchTrailers: () {
                          if (topTen.isNotEmpty) {
                            _openTrailer(topTen.first);
                          } else {
                            LandingActionHandler.openLogin(context);
                          }
                        },
                      ),
                    ),

                    // Live Platform Statistics Ticker
                    const SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: Duration(milliseconds: 150),
                        child: MarketingStatsShowcase(),
                      ),
                    ),

                    // "Why Filmytell" 4-Pillar Advantage Matrix
                    const SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: Duration(milliseconds: 250),
                        child: WhyFilmytellSection(),
                      ),
                    ),

                    // Trending Blockbusters Carousel
                    if (topTen.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ScrollRevealWrapper(
                          delay: const Duration(milliseconds: 300),
                          child: CinematicRailSection(
                            title: 'Trending Exclusives & Premieres',
                            subtitle: 'Streamed by over 500,000+ film lovers',
                            items: topTen,
                            onContentTap: _openContent,
                            onPlayTrailer: _openTrailer,
                          ),
                        ),
                      ),

                    // Popular Web Series & Movies
                    if (series.isNotEmpty || movies.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ScrollRevealWrapper(
                          delay: const Duration(milliseconds: 350),
                          child: CinematicRailSection(
                            title: 'Acclaimed Series & Films',
                            items: series.isNotEmpty ? series : movies,
                            onContentTap: _openContent,
                            onPlayTrailer: _openTrailer,
                          ),
                        ),
                      ),

                    // App Ecosystem & QR Code Download Section
                    const SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: Duration(milliseconds: 400),
                        child: MarketingAppEcosystemSection(),
                      ),
                    ),

                    // Final VIP Call To Action Banner
                    SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: const Duration(milliseconds: 450),
                        child: _MarketingVipCta(
                          onGetStarted: () => LandingActionHandler.openLogin(context),
                          onProductionHouse: () => LandingActionHandler.openExternal(
                            context,
                            AppConstant.productionHouseUrl,
                          ),
                        ),
                      ),
                    ),

                    // Universal Footer
                    const SliverToBoxAdapter(
                      child: LandingCommonFooter(),
                    ),
                  ],
                );
              },
            ),

            // Top Adaptive Sticky Header
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LandingCommonHeader(
                scrolled: _scrolled,
                activeNavLabel: _activeNav,
                customAction: widget.customHeaderAction,
                onLogin: () => LandingActionHandler.openLogin(context),
                onSignUp: () => LandingActionHandler.openLogin(context),
                onNavigate: _handleNav,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketingVipCta extends StatelessWidget {
  const _MarketingVipCta({
    required this.onGetStarted,
    required this.onProductionHouse,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onProductionHouse;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final isDark = colors.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 40,
      ),
      padding: EdgeInsets.all(isMobile ? 28 : 56),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primaryAccent,
            const Color(0xFF99000D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.primaryAccent.withOpacity(isDark ? 0.45 : 0.25),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Ready To Experience Next-Level Cinema?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Text(
              'Join thousands of viewers watching award-winning regional movies and series in 4K HDR. Start streaming today.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: isMobile ? 14 : 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton(
                onPressed: onGetStarted,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFE50914),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24 : 36,
                    vertical: isMobile ? 14 : 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 8,
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                child: const Text('Get Started Free'),
              ),
              OutlinedButton(
                onPressed: onProductionHouse,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white, width: 1.5),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 28,
                    vertical: isMobile ? 14 : 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Filmmaker Portal'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
