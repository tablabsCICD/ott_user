import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/pages/sign%20in%20page/LoginCard.dart';
import 'package:ott/app/pages/watchlist%20page/component/DisplayTrailer.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/screens/about_filmytell_screen.dart';
import 'package:ott/presentation/web_landing/screens/faq_screen.dart';
import 'package:ott/presentation/web_landing/models/web_landing_provider.dart';
import 'package:ott/presentation/web_landing/widgets/admin_platform_section.dart';
import 'package:ott/presentation/web_landing/widgets/available_devices_section.dart';
import 'package:ott/presentation/web_landing/widgets/final_cta_section.dart';
import 'package:ott/presentation/web_landing/widgets/footer_section.dart';
import 'package:ott/presentation/web_landing/widgets/hero_banner.dart';
import 'package:ott/presentation/web_landing/widgets/landing_header.dart';
import 'package:ott/presentation/web_landing/widgets/production_house_section.dart';
import 'package:ott/presentation/web_landing/widgets/promoter_section.dart';
import 'package:ott/presentation/web_landing/widgets/statistics_section.dart';
import 'package:ott/presentation/web_landing/widgets/trending_section.dart';
import 'package:ott/presentation/web_landing/widgets/user_portal_section.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _liveTvKey = GlobalKey();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    final next = _scrollController.hasClients && _scrollController.offset > 18;
    if (next != _scrolled) {
      setState(() => _scrolled = next);
    }
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginCard()),
    );
  }

  void _scrollTo(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      alignment: 0.05,
    );
  }

  void _handleNav(String label) {
    switch (label) {
      case 'Home':
        _scrollTo(_homeKey);
        break;
      case 'Movies':
        _openLogin();
        break;
      case 'Series':
        _openLogin();
        break;
      case 'Live TV':
        _scrollTo(_liveTvKey);
        break;
      case 'Categories':
        _openLogin();
        break;
      default:
        _openLogin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WebLandingProvider()..loadLandingContent(),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Consumer<WebLandingProvider>(
              builder: (context, provider, _) {
                return CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: KeyedSubtree(
                        key: _homeKey,
                        child: HeroBanner(
                          items: provider.topTen,
                          onWatchNow: _openContent,
                          onPlayTrailer: _openTrailer,
                          onExplorePlans: _openLogin,
                        ),
                      ),
                    ),
                    if (provider.isLoading)
                      const SliverToBoxAdapter(child: _LandingLoader()),
                    if (provider.errorMessage != null)
                      SliverToBoxAdapter(
                        child: _LandingError(message: provider.errorMessage!),
                      ),
                    if (provider.topTen.isNotEmpty)
                      SliverToBoxAdapter(
                        child: TrendingSection(
                          items: provider.topTen,
                          onContentTap: _openContent,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: UserPortalSection(
                        onGetStarted: _openLogin,
                        onExplorePlans: _openLogin,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: AvailableDevicesSection(
                        onStartWatching: _openLogin,
                        onExplorePlans: _openLogin,
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: ProductionHouseSection(
                        key: _liveTvKey,
                        onRegister: () => _openExternal(
                          AppConstant.productionHouseUrl,
                        ),
                        onLearnMore: () => _openExternal(
                          AppConstant.productionHouseUrl,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FinalCtaSection(
                        onWatchContent: _openLogin,
                        onPublishContent: () => _openExternal(
                          AppConstant.productionHouseUrl,
                        ),
                        onEarnReferrals: () => _openExternal(
                          AppConstant.promoterPortalUrl,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: FooterSection(onOpenLink: _handleFooterLink),
                    ),
                  ],
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Consumer<WebLandingProvider>(
                builder: (context, provider, _) {
                  return LandingHeader(
                    scrolled: _scrolled,
                    onLogin: _openLogin,
                    onSignUp: _openLogin,
                    onNavigate: _handleNav,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openContent(Content content) {
    _openLogin();
  }

  Future<void> _openExternal(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );

    if (!opened && mounted) {
      CustomToast.show(context, 'Unable to open link', isSuccess: false);
    }
  }

  Future<void> _openDocumentInNewTab(String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.platformDefault,
      webOnlyWindowName: '_blank',
    );

    if (!opened && mounted) {
      CustomToast.show(context, 'Unable to open document', isSuccess: false);
    }
  }

  void _showContactDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const _ContactUsDialog(),
    );
  }

  void _handleFooterLink(String label) {
    const policyDocumentUrl = AppConstant.privacyPolicy;
    const termsAndConditionUrl = AppConstant.termsAndCondition;

    switch (label) {
      case 'Home':
        _scrollTo(_homeKey);
        return;
      case 'Movies':
      case 'Series':
      case 'User Portal':
        _openLogin();
        return;
      case 'Production House':
        _openExternal(
          AppConstant.productionHouseUrl,
        );
        return;
      case 'Promoter':
        _openExternal(
          AppConstant.promoterPortalUrl,
        );
        return;
      case 'OTT Admin':
        _openExternal(
          '',
        );
        return;
      case 'Privacy Policy':
        _openDocumentInNewTab(policyDocumentUrl);
        return;
      case 'Terms & Conditions':
        _openDocumentInNewTab(termsAndConditionUrl);
        return;
      case 'About Us':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AboutFilmytellScreen()),
        );
        return;
      case 'Contact Us':
        _showContactDialog();
        return;
      case 'FAQ':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FaqScreen()),
        );
        return;
    }

    final slug = switch (label) {
      'Refund Policy' => 'refund-policy',
      'Facebook' => 'facebook',
      _ => label.toLowerCase().replaceAll(' ', '-'),
    };
    _openExternal('https://filmytell.in/$slug/');
  }

  Future<void> _openTrailer(Content content) async {
    var playableContent = content;
    var trailerUrl = playableContent.teaserOrTrailerUrl?.trim() ?? '';

    if (trailerUrl.isEmpty) {
      final provider = context.read<WebLandingProvider>();
      playableContent = await provider.loadContentWithTrailer(content);
      trailerUrl = playableContent.teaserOrTrailerUrl?.trim() ?? '';
    }

    if (!mounted) return;
    if (trailerUrl.isEmpty) {
      CustomToast.show(
        context,
        'Trailer is not available',
        isSuccess: false,
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrailerPage(
          trailerUrl: trailerUrl,
          isTrailerUrl: true,
          content: playableContent,
        ),
      ),
    );
  }
}

class _ContactUsDialog extends StatelessWidget {
  const _ContactUsDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF101010),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.support_agent_rounded,
                      color: theme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Contact Filmytell',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withOpacity(0.72),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Need help with your account, payments, content access, or partner portal? Reach us here.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.64),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              const _ContactInfoRow(
                icon: Icons.mail_outline_rounded,
                label: 'Email',
                value: 'support@filmytell.com',
              ),
              const SizedBox(height: 12),
              const _ContactInfoRow(
                icon: Icons.call_outlined,
                label: 'Phone',
                value: '9112012291',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactInfoRow extends StatelessWidget {
  const _ContactInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.055),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Icon(icon, color: theme.primaryColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.48),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
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

class _LandingLoader extends StatelessWidget {
  const _LandingLoader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 34),
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

class _LandingError extends StatelessWidget {
  const _LandingError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(56, 16, 56, 34),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Text(
          message,
          style: TextStyle(
            color: Colors.white.withOpacity(0.72),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
