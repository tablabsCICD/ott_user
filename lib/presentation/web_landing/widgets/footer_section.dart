import 'package:flutter/material.dart';
import 'package:ott/app/core/constant/image_constant.dart';

class FooterSection extends StatelessWidget {
  const FooterSection({
    super.key,
    required this.onOpenLink,
  });

  final ValueChanged<String> onOpenLink;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                          title: 'Explore',
                          links: const [
                            'Home',
                            'Movies',
                            'Series',
                          ],
                          onOpenLink: onOpenLink,
                        ),
                        _FooterColumn(
                          title: 'Portals',
                          links: const [
                            'User Portal',
                            'Production House',
                          ],
                          onOpenLink: onOpenLink,
                        ),
                        _FooterColumn(
                          title: 'Shortcuts',
                          links: const [
                            'About Us',
                            'Contact Us',
                            'FAQ',
                          ],
                          onOpenLink: onOpenLink,
                        ),
                        _FooterColumn(
                          title: 'Legal',
                          links: const [
                            'Privacy Policy',
                            'Terms & Conditions',
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
                    '@Filmytell. All Rights Reserved.',
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
            width: 100,
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _TrustBadge(label: 'Pay per movie'),
              _TrustBadge(label: 'Gift access'),
              _TrustBadge(label: 'Download offline'),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SocialButton(label: 'Facebook', onTap: onOpenLink),
              _SocialButton(label: 'Instagram', onTap: onOpenLink),
              _SocialButton(label: 'YouTube', onTap: onOpenLink),
              _SocialButton(label: 'X (Twitter)', onTap: onOpenLink),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.24)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mail_outline_rounded, color: color, size: 18),
                const SizedBox(width: 10),
                const Text(
                  'support@filmytell.com',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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
  final List<String> links;
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
              label: link,
              onTap: () => onOpenLink(link),
            ),
        ],
      ),
    );
  }
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final letter = widget.label == 'X (Twitter)' ? 'X' : widget.label[0];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => widget.onTap(widget.label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 40,
          width: 40,
          decoration: BoxDecoration(
            color:
                _hovered ? theme.primaryColor : Colors.white.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.12)),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.32),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
