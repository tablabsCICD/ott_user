import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_action_handler.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_common_footer.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_common_header.dart';
import 'package:ott/presentation/web_landing/designs/common/motion_particle_field.dart';
import 'package:ott/presentation/web_landing/designs/common/scroll_reveal_wrapper.dart';
import 'package:ott/presentation/web_landing/designs/design1_cinematic_ott/cinematic_hero_section.dart';
import 'package:ott/presentation/web_landing/designs/design1_cinematic_ott/cinematic_rail_section.dart';
import 'package:ott/presentation/web_landing/designs/design1_cinematic_ott/cinematic_spotlight_section.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';
import 'package:ott/presentation/web_landing/models/web_landing_provider.dart';
import 'package:provider/provider.dart';

/// Design 1: Premium Cinematic OTT Landing Page
/// Emphasizes dramatic theatrical visuals, billboard hero rotation, ranked rails, and cinema spotlight.
class LandingPageDesign1 extends StatefulWidget {
  const LandingPageDesign1({
    super.key,
    this.customHeaderAction,
  });

  final Widget? customHeaderAction;

  @override
  State<LandingPageDesign1> createState() => _LandingPageDesign1State();
}

class _LandingPageDesign1State extends State<LandingPageDesign1> {
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
            // Ambient Motion Background
            Positioned.fill(
              child: MotionParticleField(
                primaryColor: colors.primaryAccent,
                secondaryColor: const Color(0xFF3B82F6),
                particleCount: 24,
              ),
            ),

            // Scrollable Content
            Consumer<WebLandingProvider>(
              builder: (context, provider, _) {
                final topTen = provider.topTen;
                final movies = topTen
                    .where((item) => (item.type ?? '').toUpperCase() == 'MOVIE')
                    .toList();
                final series = topTen
                    .where((item) => (item.type ?? '').toUpperCase() == 'SERIES')
                    .toList();
                final shortFilms = topTen
                    .where((item) =>
                        (item.type ?? '').toUpperCase() == 'SHORT_FILM' ||
                        (item.type ?? '').toUpperCase() == 'MINI SERIES')
                    .toList();

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Hero Billboard
                    SliverToBoxAdapter(
                      child: CinematicHeroSection(
                        items: topTen,
                        onWatchNow: _openContent,
                        onPlayTrailer: _openTrailer,
                      ),
                    ),

                    // Top 10 in India Ranked Rail
                    if (topTen.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ScrollRevealWrapper(
                          delay: const Duration(milliseconds: 150),
                          child: CinematicRailSection(
                            title: 'Top 10 in India Today',
                            subtitle: 'The most watched blockbusters right now',
                            items: topTen.take(10).toList(),
                            isRanked: true,
                            onContentTap: _openContent,
                            onPlayTrailer: _openTrailer,
                          ),
                        ),
                      ),

                    // Spotlight Premiere
                    if (topTen.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ScrollRevealWrapper(
                          delay: const Duration(milliseconds: 250),
                          child: CinematicSpotlightSection(
                            content: topTen.first,
                            onWatchNow: _openContent,
                            onPlayTrailer: _openTrailer,
                          ),
                        ),
                      ),

                    // Popular Movies Rail
                    if (movies.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ScrollRevealWrapper(
                          delay: const Duration(milliseconds: 300),
                          child: CinematicRailSection(
                            title: 'Critically Acclaimed Movies',
                            items: movies,
                            onContentTap: _openContent,
                            onPlayTrailer: _openTrailer,
                          ),
                        ),
                      ),

                    // Web Series Rail
                    if (series.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ScrollRevealWrapper(
                          delay: const Duration(milliseconds: 350),
                          child: CinematicRailSection(
                            title: 'Binge-Worthy Web Series',
                            items: series,
                            onContentTap: _openContent,
                            onPlayTrailer: _openTrailer,
                          ),
                        ),
                      ),

                    // Short Films & Mini Series Rail
                    if (shortFilms.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ScrollRevealWrapper(
                          delay: const Duration(milliseconds: 400),
                          child: CinematicRailSection(
                            title: 'Short Films & Mini Series',
                            items: shortFilms,
                            onContentTap: _openContent,
                            onPlayTrailer: _openTrailer,
                          ),
                        ),
                      ),

                    // Latest Loaded Content (if different from topTen)
                    if (provider.latestContent.isNotEmpty)
                      SliverToBoxAdapter(
                        child: ScrollRevealWrapper(
                          delay: const Duration(milliseconds: 450),
                          child: CinematicRailSection(
                            title: 'Recently Added on Filmytell',
                            items: provider.latestContent,
                            onContentTap: _openContent,
                            onPlayTrailer: _openTrailer,
                          ),
                        ),
                      ),

                    // Platform Devices Showcase
                    SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: const Duration(milliseconds: 500),
                        child: _CinematicDevicesBanner(
                          onGetStarted: () => LandingActionHandler.openLogin(context),
                        ),
                      ),
                    ),

                    // Creator Hub Callout
                    SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: const Duration(milliseconds: 550),
                        child: _CreatorPartnerHub(
                          onProductionHouse: () => LandingActionHandler.openExternal(
                            context,
                            AppConstant.productionHouseUrl,
                          ),
                          onPromoter: () => LandingActionHandler.openExternal(
                            context,
                            AppConstant.promoterPortalUrl,
                          ),
                        ),
                      ),
                    ),

                    // Footer
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

class _CinematicDevicesBanner extends StatelessWidget {
  const _CinematicDevicesBanner({required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 36,
      ),
      padding: EdgeInsets.all(isMobile ? 24 : 44),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.surface,
            colors.surfaceElevated,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'UNIVERSAL STREAMING',
                    style: TextStyle(
                      color: colors.primaryAccent,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Stream on Any Screen, Anywhere',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: isMobile ? 22 : 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enjoy seamless 4K playback across Android, iOS, Android TV, Amazon Fire TV, and web browsers. Pick up exactly where you left off.',
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: isMobile ? 13 : 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onGetStarted,
                  icon: const Icon(Icons.devices_rounded, size: 20),
                  label: const Text('Explore Supported Devices'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primaryAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 48),
            Expanded(
              flex: 4,
              child: Center(
                child: Icon(
                  Icons.tv_rounded,
                  size: 160,
                  color: colors.primaryAccent.withOpacity(0.2),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatorPartnerHub extends StatelessWidget {
  const _CreatorPartnerHub({
    required this.onProductionHouse,
    required this.onPromoter,
  });

  final VoidCallback onProductionHouse;
  final VoidCallback onPromoter;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isMobile ? 20 : 64,
        vertical: 24,
      ),
      child: isMobile
          ? Column(
              children: [
                _buildCard(
                  colors,
                  title: 'For Filmmakers & Studios',
                  desc: 'Publish your films directly to millions of viewers with automated monetization.',
                  btnLabel: 'Production House Portal',
                  icon: Icons.movie_creation_rounded,
                  onTap: onProductionHouse,
                ),
                const SizedBox(height: 16),
                _buildCard(
                  colors,
                  title: 'For Affiliates & Promoters',
                  desc: 'Earn high-tier recurring revenue with our official promoter and influencer program.',
                  btnLabel: 'Promoter Portal',
                  icon: Icons.monetization_on_rounded,
                  onTap: onPromoter,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildCard(
                    colors,
                    title: 'For Filmmakers & Studios',
                    desc: 'Publish your films directly to millions of viewers with automated monetization.',
                    btnLabel: 'Production House Portal',
                    icon: Icons.movie_creation_rounded,
                    onTap: onProductionHouse,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildCard(
                    colors,
                    title: 'For Affiliates & Promoters',
                    desc: 'Earn high-tier recurring revenue with our official promoter and influencer program.',
                    btnLabel: 'Promoter Portal',
                    icon: Icons.monetization_on_rounded,
                    onTap: onPromoter,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCard(
    LandingThemeColors colors, {
    required String title,
    required String desc,
    required String btnLabel,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.primaryAccent, size: 32),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: Text(btnLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primaryAccent,
              side: BorderSide(color: colors.primaryAccent.withOpacity(0.5)),
            ),
          ),
        ],
      ),
    );
  }
}
