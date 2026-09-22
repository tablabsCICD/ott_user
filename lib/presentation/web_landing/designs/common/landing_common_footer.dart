import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/app_constant.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/presentation/web_landing/designs/common/landing_action_handler.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// Universal responsive footer for Filmytell landing pages.
class LandingCommonFooter extends StatelessWidget {
  const LandingCommonFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);
    final isDark = colors.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    return Container(
      width: double.infinity,
      color: colors.footerBackground,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 24 : 64,
        vertical: isMobile ? 40 : 64,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Brand + Columns
          if (isMobile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrandColumn(context, colors),
                const SizedBox(height: 32),
                _buildLinksSection(context, colors, isMobile: true),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _buildBrandColumn(context, colors),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 5,
                  child: _buildLinksSection(context, colors, isMobile: false),
                ),
              ],
            ),

          const SizedBox(height: 48),
          Divider(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.white.withOpacity(0.12),
          ),
          const SizedBox(height: 24),

          // Bottom Bar: Copyright + Store Badges + Social Icons
          Wrap(
            spacing: 20,
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '© ${DateTime.now().year} Filmytell. All rights reserved.',
                style: TextStyle(
                  color: colors.textMuted.withOpacity(0.8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SocialIcon(
                    icon: Icons.facebook,
                    onTap: () => LandingActionHandler.openExternal(
                      context,
                      AppConstant.facebookUrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SocialIcon(
                    icon: Icons.camera_alt_outlined,
                    onTap: () => LandingActionHandler.openExternal(
                      context,
                      AppConstant.instagramUrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SocialIcon(
                    icon: Icons.play_circle_outline,
                    onTap: () => LandingActionHandler.openExternal(
                      context,
                      AppConstant.youtubeUrl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SocialIcon(
                    icon: Icons.alternate_email,
                    onTap: () => LandingActionHandler.openExternal(
                      context,
                      AppConstant.xUrl,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBrandColumn(BuildContext context, LandingThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          ImageConstant.webFullScreenLogo,
          height: 40,
          errorBuilder: (_, __, ___) => Image.asset(
            ImageConstant.fullScreenLogo,
            height: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Your ultimate streaming destination for blockbuster movies, exclusive web series, regional masterpieces, and short films.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 13,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _StoreButton(
              label: 'Google Play',
              icon: Icons.android_rounded,
              onTap: () => LandingActionHandler.openExternal(
                context,
                AppConstant.playStoreLink,
              ),
            ),
            _StoreButton(
              label: 'App Store',
              icon: Icons.apple_rounded,
              onTap: () => LandingActionHandler.openExternal(
                context,
                AppConstant.appStoreLink,
              ),
            ),
            _StoreButton(
              label: 'Fire TV',
              icon: Icons.tv_rounded,
              onTap: () => LandingActionHandler.openExternal(
                context,
                AppConstant.amazonFireTvLink,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinksSection(
    BuildContext context,
    LandingThemeColors colors, {
    required bool isMobile,
  }) {
    final columns = [
      _FooterColumnData(
        title: 'Explore',
        links: [
          _FooterLink('Movies', () => LandingActionHandler.openLogin(context)),
          _FooterLink('Web Series', () => LandingActionHandler.openLogin(context)),
          _FooterLink('Short Films', () => LandingActionHandler.openLogin(context)),
          _FooterLink('Mini Series', () => LandingActionHandler.openLogin(context)),
        ],
      ),
      _FooterColumnData(
        title: 'Partners & Creators',
        links: [
          _FooterLink(
            'Production House Portal',
            () => LandingActionHandler.openExternal(
              context,
              AppConstant.productionHouseUrl,
            ),
          ),
          _FooterLink(
            'Promoter Portal',
            () => LandingActionHandler.openExternal(
              context,
              AppConstant.promoterPortalUrl,
            ),
          ),
          _FooterLink(
            'User Sign In',
            () => LandingActionHandler.openLogin(context),
          ),
        ],
      ),
      _FooterColumnData(
        title: 'Company & Legal',
        links: [
          _FooterLink(
            'About Us',
            () => LandingActionHandler.openInternalStaticPage(
              context,
              '/about-us.html',
            ),
          ),
          _FooterLink(
            'Contact Support',
            () => LandingActionHandler.openInternalStaticPage(
              context,
              '/contact.html',
            ),
          ),
          _FooterLink(
            'Privacy Policy',
            () => LandingActionHandler.openPrivacyPolicy(context),
          ),
          _FooterLink(
            'Terms & Conditions',
            () => LandingActionHandler.openTerms(context),
          ),
          _FooterLink(
            'Help Center / FAQ',
            () => LandingActionHandler.openInternalStaticPage(
              context,
              '/help-center.html',
            ),
          ),
        ],
      ),
    ];

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: columns
            .map((col) => Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: _buildColumnWidget(context, col, colors),
                ))
            .toList(),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns
          .map((col) => Expanded(
                child: _buildColumnWidget(context, col, colors),
              ))
          .toList(),
    );
  }

  Widget _buildColumnWidget(
    BuildContext context,
    _FooterColumnData col,
    LandingThemeColors colors,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          col.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 14),
        ...col.links.map(
          (link) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _HoverFooterLink(
              label: link.title,
              onTap: link.action,
            ),
          ),
        ),
      ],
    );
  }
}

class _FooterColumnData {
  _FooterColumnData({required this.title, required this.links});
  final String title;
  final List<_FooterLink> links;
}

class _FooterLink {
  _FooterLink(this.title, this.action);
  final String title;
  final VoidCallback action;
}

class _HoverFooterLink extends StatefulWidget {
  const _HoverFooterLink({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_HoverFooterLink> createState() => _HoverFooterLinkState();
}

class _HoverFooterLinkState extends State<_HoverFooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: TextStyle(
            color: _hovered ? const Color(0xFFE50914) : const Color(0xFF94A3B8),
            fontSize: 13,
            fontWeight: _hovered ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _SocialIcon extends StatefulWidget {
  const _SocialIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered ? const Color(0xFFE50914) : Colors.white.withOpacity(0.08),
            border: Border.all(
              color: _hovered ? const Color(0xFFE50914) : Colors.white.withOpacity(0.12),
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 18,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreButton extends StatefulWidget {
  const _StoreButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_StoreButton> createState() => _StoreButtonState();
}

class _StoreButtonState extends State<_StoreButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFE50914).withOpacity(0.15) : Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _hovered ? const Color(0xFFE50914) : Colors.white.withOpacity(0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: _hovered ? const Color(0xFFE50914) : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  color: _hovered ? Colors.white : const Color(0xFFCBD5E1),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
