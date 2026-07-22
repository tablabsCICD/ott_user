import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            padding: const EdgeInsets.fromLTRB(56, 56, 56, 30),
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
                            _FooterLinkData(lang.aboutUs, 'About Us'),
                            _FooterLinkData(lang.contactUs, 'Contact Us'),
                            _FooterLinkData(lang.faq, 'FAQ'),
                          ],
                          onOpenLink: onOpenLink,
                        ),
                        _FooterColumn(
                          title: lang.legal,
                          links: [
                            _FooterLinkData(
                                lang.privacyPolicy, 'Privacy Policy'),
                            _FooterLinkData(
                              lang.termsConditions,
                              'Terms & Conditions',
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
              _SocialButton(label: 'X (Twitter)', onTap: onOpenLink),
            ],
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => onOpenLink('Contact Us'),
            icon: Icon(Icons.support_agent_rounded, color: color, size: 18),
            label: Builder(
              builder: (context) {
                return Text("support@filmytell.com");
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
            ),
        ],
      ),
    );
  }
}

class _FooterLinkData {
  const _FooterLinkData(this.label, this.target);

  final String label;
  final String target;
}

class _FooterLink extends StatefulWidget {
  const _FooterLink({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

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
    final theme = Theme.of(context);
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
              child: SvgPicture.string(
                icon.svg,
                height: icon.size,
                width: icon.size,
                colorFilter: icon.useSourceColors
                    ? null
                    : ColorFilter.mode(icon.color, BlendMode.srcIn),
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
    required this.svg,
    required this.color,
    this.size = 18,
    this.useSourceColors = false,
  });

  final String svg;
  final Color color;
  final double size;
  final bool useSourceColors;

  static _SocialIconData forLabel(String label) {
    switch (label) {
      case 'Facebook':
        return const _SocialIconData(
          svg: _facebookSvg,
          color: Color(0xFF1877F2),
          size: 27,
          useSourceColors: true,
        );
      case 'Instagram':
        return const _SocialIconData(
          svg: _instagramSvg,
          color: Color(0xFFE4405F),
          size: 27,
          useSourceColors: true,
        );
      case 'X (Twitter)':
        return const _SocialIconData(
          svg: _xSvg,
          color: Colors.white,
          size: 27,
          useSourceColors: true,
        );
      default:
        return const _SocialIconData(
          svg: _linkSvg,
          color: Colors.white,
          size: 18,
        );
    }
  }
}

const String _facebookSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="11" fill="#1877F2"/>
  <path fill="#FFFFFF" d="M13.7 22v-7.7h2.6l.4-3h-3V9.4c0-.9.2-1.5 1.5-1.5h1.6V5.2c-.3 0-1.3-.1-2.4-.1-2.4 0-4 1.5-4 4.1v2.3H7.7v3h2.7V22h3.3z"/>
</svg>
''';

const String _instagramSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="instagramGradient" x1="3" y1="21" x2="21" y2="3" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#FEDA75"/>
      <stop offset="0.28" stop-color="#FA7E1E"/>
      <stop offset="0.52" stop-color="#D62976"/>
      <stop offset="0.74" stop-color="#962FBF"/>
      <stop offset="1" stop-color="#4F5BD5"/>
    </linearGradient>
  </defs>
  <rect x="2" y="2" width="20" height="20" rx="6" fill="url(#instagramGradient)"/>
  <path fill="#FFFFFF" fill-rule="evenodd" clip-rule="evenodd" d="M8 6.2h8c1 0 1.8.8 1.8 1.8v8c0 1-.8 1.8-1.8 1.8H8c-1 0-1.8-.8-1.8-1.8V8c0-1 .8-1.8 1.8-1.8zm8 1.6H8c-.1 0-.2.1-.2.2v8c0 .1.1.2.2.2h8c.1 0 .2-.1.2-.2V8c0-.1-.1-.2-.2-.2zM12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6zm0 1.6a1.4 1.4 0 1 1 0 2.8 1.4 1.4 0 0 1 0-2.8zm3.4-2.1a.8.8 0 1 0 0 1.6.8.8 0 0 0 0-1.6z"/>
</svg>
''';

const String _xSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="11" fill="#000000"/>
  <path fill="#FFFFFF" d="M13.7 10.6 19 4.5h-1.3l-4.6 5.3-3.6-5.3H5.2l5.5 8.1-5.5 6.4h1.3l4.8-5.6 3.9 5.6h4.3l-5.8-8.4zm-1.7 2-.6-.9L7 5.5h1.9l3.6 5.1.6.9 4.6 6.6h-1.9L12 12.6z"/>
</svg>
''';

const String _linkSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M10.6 13.4a1 1 0 0 1 0-1.4l3.4-3.4a3 3 0 0 1 4.2 4.2l-2 2a1 1 0 1 1-1.4-1.4l2-2a1 1 0 0 0-1.4-1.4L12 13.4a1 1 0 0 1-1.4 0zm2.8-2.8a1 1 0 0 1 0 1.4L10 15.4a3 3 0 1 1-4.2-4.2l2-2a1 1 0 1 1 1.4 1.4l-2 2a1 1 0 0 0 1.4 1.4l3.4-3.4a1 1 0 0 1 1.4 0z"/>
</svg>
''';
