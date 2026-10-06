import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/app/widgets/show_toast.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';
import 'package:ott/presentation/web_landing/widgets/footer_section.dart';
import 'package:url_launcher/url_launcher.dart';

class ProducerLearnMoreScreen extends StatelessWidget {
  const ProducerLearnMoreScreen({super.key});

  static final Uri _whatsAppUri = Uri.parse('https://wa.me/919145451291');

  static const List<String> _features = [
    'Set and revise own rental price.',
    'Retain complete ownership of the content.',
    'Decide duration, how much time your content should be there on the platform.*',
    'Monitor performance through a transparent dashboard.',
    'Receive weekly payment settlements.',
    'Earn 70 to 60% of rental revenue, excluding applicable taxes.*',
    'Build an audience progressively instead of depending entirely on a conventional theatrical window.',
    'Share and Gift option makes it easy for marketing.',
    'User friendly interface of the platform.',
    'Wallet system simplifies purchase mechanism.',
    'Available on all alternate options like Android, iOS, Web and Google TV, Amazon fire tv, Jio app store.',
    'Filmytell enables content to travel beyond geographical and traditional distribution barriers.',
  ];

  Future<void> _openExternal(BuildContext context, String url) async {
    if (url.trim().isEmpty) return;
    try {
      final uri = Uri.parse(url);
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && context.mounted) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (context.mounted) {
        CustomToast.show(
          context,
          'Unable to open link right now.',
          isSuccess: false,
        );
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    try {
      final opened = await launchUrl(
        _whatsAppUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_blank',
      );
      if (!opened && context.mounted) {
        await launchUrl(_whatsAppUri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (context.mounted) {
        CustomToast.show(
          context,
          'Unable to open WhatsApp link.',
          isSuccess: false,
        );
      }
    }
  }

  void _handleFooterLink(BuildContext context, String label) {
    switch (label) {
      case 'Home':
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      case 'Production House':
        _openExternal(context, AppConstant.productionHouseUrl);
        return;
      case 'Promoter':
        _openExternal(context, AppConstant.promoterPortalUrl);
        return;
      case 'Account Deletion':
        _openExternal(context, AppConstant.accountDeletionUrl);
        return;
      case 'Facebook':
        _openExternal(context, AppConstant.facebookUrl);
        return;
      case 'Instagram':
        _openExternal(context, AppConstant.instagramUrl);
        return;
      case 'LinkedIn':
        _openExternal(context, AppConstant.linkedinUrl);
        return;
      default:
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 600;
    final isTablet = size.width >= 600 && size.width < 1024;
    final horizontalPadding = isMobile ? 18.0 : (isTablet ? 32.0 : 56.0);

    return Scaffold(
      backgroundColor: FilmytellTheme.background,
      body: CustomScrollView(
        slivers: [
          // Top Navigation Bar
          SliverToBoxAdapter(
            child: Container(
              height: isMobile ? 68 : 80,
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.85),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Back Button
                  InkWell(
                    onTap: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        Navigator.of(context).pushReplacementNamed('/');
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          if (!isMobile) ...[
                            const SizedBox(width: 6),
                            Text(
                              'Back to Home',
                              style: FilmytellTheme.font(
                                color: Colors.white,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Logo
                  Image.asset(
                    ImageConstant.logo,
                    height: isMobile ? 36 : 44,
                    width: isMobile ? 36 : 44,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      'FILMYTELL',
                      style: FilmytellTheme.font(
                        color: FilmytellTheme.primary,
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Header Register CTA
                  ElevatedButton(
                    onPressed: () => _openExternal(
                      context,
                      AppConstant.productionHouseUrl,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FilmytellTheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 22,
                        vertical: isMobile ? 10 : 14,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Register Now',
                      style: FilmytellTheme.font(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    isMobile ? 24 : 40,
                    horizontalPadding,
                    isMobile ? 48 : 64,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isMobile ? 20 : 36),
                    decoration: BoxDecoration(
                      color: const Color(0xFF121215),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.50),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Intro Text
                        Text(
                          'FILMYTELL is Producer / Creater friendly platform where,',
                          style: FilmytellTheme.font(
                            color: Colors.white,
                            fontSize: isMobile ? 17 : 20,
                            fontWeight: FontWeight.w800,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Movies, Web Series , Mini Series and Shortfilms Released and monitized.',
                          style: FilmytellTheme.font(
                            color: Colors.white.withValues(alpha: 0.90),
                            fontSize: isMobile ? 15 : 17,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Section Divider
                        Divider(
                          color: Colors.white.withValues(alpha: 0.10),
                          thickness: 1,
                        ),
                        const SizedBox(height: 24),

                        // Features of Filmytell Heading
                        Text(
                          'Features of Filmytell :',
                          style: FilmytellTheme.font(
                            color: Colors.white,
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Simple Sequential Feature List
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _features.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            final feature = _features[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 7,
                                    right: 12,
                                  ),
                                  child: Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: FilmytellTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: FilmytellTheme.font(
                                      color:
                                          Colors.white.withValues(alpha: 0.90),
                                      fontSize: isMobile ? 14 : 15.5,
                                      fontWeight: FontWeight.w400,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        // Conditions applied
                        Text(
                          '*conditions applied',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // Divider before CTAs
                        Divider(
                          color: Colors.white.withValues(alpha: 0.10),
                          thickness: 1,
                        ),
                        const SizedBox(height: 24),

                        // CTA Buttons
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _openExternal(
                                context,
                                AppConstant.productionHouseUrl,
                              ),
                              icon: const Icon(
                                Icons.app_registration_rounded,
                                size: 18,
                              ),
                              label: const Text('Register Production House'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FilmytellTheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 20 : 26,
                                  vertical: isMobile ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openWhatsApp(context),
                              icon: const Icon(
                                Icons.chat_bubble_outline_rounded,
                                size: 18,
                                color: Color(0xFF25D366),
                              ),
                              label: const Text('Chat on WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 18 : 24,
                                  vertical: isMobile ? 12 : 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Footer
          SliverToBoxAdapter(
            child: FooterSection(
              onOpenLink: (label) => _handleFooterLink(context, label),
            ),
          ),
        ],
      ),
    );
  }
}
