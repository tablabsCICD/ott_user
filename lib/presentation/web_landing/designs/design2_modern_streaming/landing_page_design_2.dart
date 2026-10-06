import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_action_handler.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_common_footer.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_common_header.dart';
import 'package:ott/presentation/web_landing/designs/common/motion_particle_field.dart';
import 'package:ott/presentation/web_landing/designs/common/scroll_reveal_wrapper.dart';
import 'package:ott/presentation/web_landing/designs/design2_modern_streaming/modern_floating_grid_section.dart';
import 'package:ott/presentation/web_landing/designs/design2_modern_streaming/modern_glass_device_section.dart';
import 'package:ott/presentation/web_landing/designs/design2_modern_streaming/modern_hero_section.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';
import 'package:ott/presentation/web_landing/models/web_landing_provider.dart';
import 'package:provider/provider.dart';

/// Design 2: Modern Streaming Platform Landing Page
/// Emphasizes clean modern UI, asymmetric floating card hero, interactive category filters, and glassmorphism.
class LandingPageDesign2 extends StatefulWidget {
  const LandingPageDesign2({
    super.key,
    this.customHeaderAction,
  });

  final Widget? customHeaderAction;

  @override
  State<LandingPageDesign2> createState() => _LandingPageDesign2State();
}

class _LandingPageDesign2State extends State<LandingPageDesign2> {
  final ScrollController _scrollController = ScrollController();
  late final WebLandingProvider _provider;
  bool _scrolled = false;
  String _activeCategory = 'All';

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

  void _handleCategoryChange(String category) {
    setState(() => _activeCategory = category);
    if (category == 'Movies') {
      _provider.loadLatestContentByType('MOVIE');
    } else if (category == 'Web Series') {
      _provider.loadLatestContentByType('SERIES');
    } else if (category == 'Short Films') {
      _provider.loadLatestContentByType('SHORT_FILM');
    } else if (category == 'Mini Series') {
      _provider.loadLatestContentByType('MINI SERIES');
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
            // Ambient particle glow
            Positioned.fill(
              child: MotionParticleField(
                primaryColor: const Color(0xFF3B82F6),
                secondaryColor: colors.primaryAccent,
                particleCount: 18,
              ),
            ),

            Consumer<WebLandingProvider>(
              builder: (context, provider, _) {
                final topTen = provider.topTen;
                final allContent = [
                  ...topTen,
                  ...provider.latestContent.where(
                    (item) => !topTen.any((t) => t.id == item.id),
                  ),
                ];

                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    // Modern Asymmetric Hero Section
                    SliverToBoxAdapter(
                      child: ModernHeroSection(
                        items: topTen,
                        onGetStarted: () => LandingActionHandler.openLogin(context),
                        onExploreCatalog: () {
                          _scrollController.animateTo(
                            480,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOutCubic,
                          );
                        },
                        onContentTap: _openContent,
                      ),
                    ),

                    // Interactive Category Filter & Floating Card Grid
                    SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: const Duration(milliseconds: 200),
                        child: ModernFloatingGridSection(
                          items: allContent,
                          selectedCategory: _activeCategory,
                          onCategoryChanged: _handleCategoryChange,
                          onContentTap: _openContent,
                          onPlayTrailer: _openTrailer,
                        ),
                      ),
                    ),

                    // Modern Glassmorphism Feature & Device Showcase
                    SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: const Duration(milliseconds: 300),
                        child: ModernGlassDeviceSection(
                          onExplorePlans: () => LandingActionHandler.openLogin(context),
                        ),
                      ),
                    ),

                    // Modern Partner Gateway
                    SliverToBoxAdapter(
                      child: ScrollRevealWrapper(
                        delay: const Duration(milliseconds: 350),
                        child: _ModernPartnerBanner(
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
                activeNavLabel: _activeCategory == 'All' ? 'Home' : _activeCategory,
                customAction: widget.customHeaderAction,
                onLogin: () => LandingActionHandler.openLogin(context),
                onSignUp: () => LandingActionHandler.openLogin(context),
                onNavigate: (item) {
                  if (item == 'Home') {
                    _handleCategoryChange('All');
                  } else {
                    _handleCategoryChange(item);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernPartnerBanner extends StatelessWidget {
  const _ModernPartnerBanner({
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
        vertical: 36,
      ),
      padding: EdgeInsets.all(isMobile ? 24 : 40),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPartnerItem(
                  colors,
                  title: 'Production House Hub',
                  desc: 'Publish, distribute, and monetize your catalog directly with comprehensive transparent analytics.',
                  btnLabel: 'Access Studio Portal',
                  onTap: onProductionHouse,
                ),
                const SizedBox(height: 24),
                Divider(color: colors.border),
                const SizedBox(height: 24),
                _buildPartnerItem(
                  colors,
                  title: 'Filmytell Partner & Promoter',
                  desc: 'Join our elite partner network and earn monthly recurring revenue through referral links and campaigns.',
                  btnLabel: 'Join Promoter Network',
                  onTap: onPromoter,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildPartnerItem(
                    colors,
                    title: 'Production House Hub',
                    desc: 'Publish, distribute, and monetize your catalog directly with comprehensive transparent analytics.',
                    btnLabel: 'Access Studio Portal',
                    onTap: onProductionHouse,
                  ),
                ),
                Container(
                  height: 100,
                  width: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  color: colors.border,
                ),
                Expanded(
                  child: _buildPartnerItem(
                    colors,
                    title: 'Filmytell Partner & Promoter',
                    desc: 'Join our elite partner network and earn monthly recurring revenue through referral links and campaigns.',
                    btnLabel: 'Join Promoter Network',
                    onTap: onPromoter,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPartnerItem(
    LandingThemeColors colors, {
    required String title,
    required String desc,
    required String btnLabel,
    required VoidCallback onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.surfaceElevated,
            foregroundColor: colors.primaryAccent,
            elevation: 0,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            btnLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
