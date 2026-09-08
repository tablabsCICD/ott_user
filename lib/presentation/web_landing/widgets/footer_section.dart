import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:ott/app/core/constant/image_constant.dart';
import 'package:ott/l10n/app_localizations.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({
    super.key,
    required this.onOpenLink,
  });

  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lang = AppLocalizations.of(context)!;
    final width = MediaQuery.sizeOf(context).width;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF030303),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -160,
            bottom: -180,
            child: IgnorePointer(
              child: Container(
                height: 360,
                width: 360,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.primaryColor.withOpacity(0.11),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.12),
                      blurRadius: 120,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              width < 600 ? 20 : (width < 1024 ? 32 : 56),
              width < 600 ? 40 : 56,
              width < 600 ? 20 : (width < 1024 ? 32 : 56),
              30,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1180;
                    final linkColumns = Wrap(
                      spacing: compact ? 36 : 54,
                      runSpacing: 28,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        _FooterColumn(
                          title: lang.explore,
                          links: [
                            _FooterLinkData(lang.home, 'Home'),
                            _FooterLinkData(lang.movie, 'Movies'),
                            _FooterLinkData(lang.series, 'Series'),
                            _FooterLinkData(lang.minSeries, 'Mini Series'),
                            const _FooterLinkData('Short Film', 'Short Film'),
                          ],
                          onOpenLink: onOpenLink,
                        ),
                        _FooterColumn(
                          title: lang.portals,
                          links: [
                            _FooterLinkData(lang.userPortal, 'User Portal'),
                            _FooterLinkData(
                              lang.productionHouses,
                              'Production House',
                            ),
                          ],
                          onOpenLink: onOpenLink,
                        ),
                        _FooterColumn(
                          title: lang.shortcuts,
                          links: [
                            _FooterLinkData(
                              lang.aboutUs,
                              'About Us',
                              href: '/about-us.html',
                            ),
                            _FooterLinkData(
                              lang.contactUs,
                              'Contact Us',
                              href: '/contact.html',
                            ),
                            _FooterLinkData(
                              lang.faq,
                              'FAQ',
                              href: '/help-center.html',
                            ),
                          ],
                          onOpenLink: onOpenLink,
                        ),
                        _FooterColumn(
                          title: lang.legal,
                          links: [
                            _FooterLinkData(
                              lang.privacyPolicy,
                              'Privacy Policy',
                              href: '/privacy-policy.html',
                            ),
                            _FooterLinkData(
                              lang.termsConditions,
                              'Terms & Conditions',
                              href: '/terms-of-service.html',
                            ),
                            const _FooterLinkData(
                              'Cookies',
                              'Cookies',
                              href: '/cookies.html',
                            ),
                            _FooterLinkData(
                              'Account Deletion',
                              'Account Deletion',
                            ),
                          ],
                          onOpenLink: onOpenLink,
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BrandBlock(
                            color: theme.primaryColor,
                            onOpenLink: onOpenLink,
                          ),
                          const SizedBox(height: 34),
                          linkColumns,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _BrandBlock(
                            color: theme.primaryColor,
                            onOpenLink: onOpenLink,
                          ),
                        ),
                        const SizedBox(width: 64),
                        Expanded(flex: 7, child: linkColumns),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 42),
                Divider(color: Colors.white.withOpacity(0.08)),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    lang.allRightsReserved,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.50),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
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

class _BrandBlock extends StatelessWidget {
  const _BrandBlock({
    required this.color,
    required this.onOpenLink,
  });

  final Color color;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 430),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.asset(
            ImageConstant.logo,
            height: 100,
            width: 250,
            alignment: Alignment.centerLeft,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
          const SizedBox(height: 22),
          Builder(
            builder: (context) {
              final lang = AppLocalizations.of(context)!;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _TrustBadge(label: lang.payPerMovie),
                  _TrustBadge(label: lang.giftAccess),
                  _TrustBadge(label: lang.downloadOffline),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SocialButton(label: 'Facebook', onTap: onOpenLink),
              _SocialButton(label: 'Instagram', onTap: onOpenLink),
              _SocialButton(label: 'LinkedIn', onTap: onOpenLink),
              _SocialButton(label: 'YouTube', onTap: onOpenLink),
              _SocialButton(label: 'X (Twitter)', onTap: onOpenLink),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => onOpenLink('Contact Us'),
            icon: Icon(Icons.support_agent_rounded, color: color, size: 18),
            label: Builder(
              builder: (context) {
                return Text("connect@filmytell.com");
              },
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: color.withOpacity(0.34)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EcosystemCard extends StatelessWidget {
  const _EcosystemCard({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.045),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.28)),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'One OTT ecosystem for viewers and creators',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Secure streaming, pay-per-movie access, gifting, production house publishing, promoter growth tools, and multi-device entertainment.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.62),
                    height: 1.45,
                    fontWeight: FontWeight.w600,
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

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.76),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({
    required this.title,
    required this.links,
    required this.onOpenLink,
  });

  final String title;
  final List<_FooterLinkData> links;
  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 128),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.90),
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 15),
          for (final link in links)
            _FooterLink(
              label: link.label,
              onTap: () => onOpenLink(link.target),
              href: link.href,
            ),
        ],
      ),
    );
  }
}

class _FooterLinkData {
  const _FooterLinkData(this.label, this.target, {this.href});

  final String label;
  final String target;
  final String? href;
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({
    required this.label,
    required this.onTap,
    this.href,
  });

  final String label;
  final VoidCallback onTap;
  final String? href;

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.only(
            left: _hovered ? 4 : 0,
            bottom: 10,
            top: 2,
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              color: _hovered
                  ? theme.primaryColor
                  : Colors.white.withOpacity(0.58),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final ValueChanged<String> onTap;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (!mounted) return;
    setState(() => _hovered = value);
  }

  @override
  Widget build(BuildContext context) {
    final icon = _SocialIconData.forLabel(widget.label);

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Tooltip(
        message: widget.label,
        child: GestureDetector(
          onTap: () => widget.onTap(widget.label),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 40,
            width: 40,
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withOpacity(0.16)
                  : Colors.white.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: _hovered
                  ? [
                      BoxShadow(
                        color: icon.color.withOpacity(0.32),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: _SocialIcon(
                label: widget.label,
                color: icon.color,
                size: icon.size,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialIconData {
  const _SocialIconData({
    required this.color,
    this.size = 18,
  });

  final Color color;
  final double size;

  static _SocialIconData forLabel(String label) {
    switch (label) {
      case 'Facebook':
        return const _SocialIconData(
          color: Color(0xFF1877F2),
          size: 27,
        );
      case 'Instagram':
        return const _SocialIconData(
          color: Color(0xFFE4405F),
          size: 27,
        );
      case 'LinkedIn':
        return const _SocialIconData(
          color: Color(0xFF0A66C2),
          size: 27,
        );
      case 'YouTube':
        return const _SocialIconData(
          color: Color(0xFFFF0000),
          size: 27,
        );
      case 'X (Twitter)':
        return const _SocialIconData(
          color: Colors.white,
          size: 27,
        );
      default:
        return const _SocialIconData(
          color: Colors.white,
          size: 18,
        );
    }
  }
}

class _SocialIcon extends StatelessWidget {
  const _SocialIcon({
    required this.label,
    required this.color,
    required this.size,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    switch (label) {
      case 'Facebook':
        return Container(
          height: size,
          width: size,
          decoration: const BoxDecoration(
            color: Color(0xFF1877F2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.bottomCenter,
          child: const Text(
            'f',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              height: 0.95,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case 'Instagram':
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: const LinearGradient(
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
              colors: [
                Color(0xFFFEDA75),
                Color(0xFFFA7E1E),
                Color(0xFFD62976),
                Color(0xFF962FBF),
                Color(0xFF4F5BD5),
              ],
            ),
          ),
          child: Center(
            child: Container(
              height: 15,
              width: 15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: Colors.white, width: 1.8),
              ),
              child: Align(
                alignment: Alignment.topRight,
                child: Container(
                  margin: const EdgeInsets.only(top: 2, right: 2),
                  height: 3,
                  width: 3,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        );
      case 'X (Twitter)':
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.16)),
          ),
          alignment: Alignment.center,
          child: const Text(
            'X',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case 'LinkedIn':
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: const Color(0xFF0A66C2),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'in',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        );
      case 'YouTube':
        return Container(
          height: size,
          width: size,
          decoration: BoxDecoration(
            color: const Color(0xFFFF0000),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_arrow_rounded,
            color: Colors.white,
            size: 20,
          ),
        );
      default:
        return Icon(Icons.link_rounded, color: color, size: size);
    }
  }
}
