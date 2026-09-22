import 'package:flutter/material.dart';
import 'package:ott/data/models/content.dart';
import 'package:ott/presentation/web_landing/designs/common/premium_content_card.dart';
import 'package:ott/presentation/web_landing/designs/theme/landing_theme.dart';

/// Horizontal poster carousel with smooth scrolling, arrow controls, and ranked badges.
class CinematicRailSection extends StatefulWidget {
  const CinematicRailSection({
    super.key,
    required this.title,
    required this.items,
    this.subtitle,
    this.isRanked = false,
    this.cardWidth = 190,
    this.cardHeight = 285,
    required this.onContentTap,
    required this.onPlayTrailer,
  });

  final String title;
  final String? subtitle;
  final List<Content> items;
  final bool isRanked;
  final double cardWidth;
  final double cardHeight;
  final ValueChanged<Content> onContentTap;
  final ValueChanged<Content> onPlayTrailer;

  @override
  State<CinematicRailSection> createState() => _CinematicRailSectionState();
}

class _CinematicRailSectionState extends State<CinematicRailSection> {
  final ScrollController _scrollController = ScrollController();
  bool _showLeftArrow = false;
  bool _showRightArrow = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateArrowState);
  }

  void _updateArrowState() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final hasLeft = currentScroll > 20;
    final hasRight = currentScroll < maxScroll - 20;
    if (hasLeft != _showLeftArrow || hasRight != _showRightArrow) {
      setState(() {
        _showLeftArrow = hasLeft;
        _showRightArrow = hasRight;
      });
    }
  }

  void _scroll(bool forward) {
    if (!_scrollController.hasClients) return;
    final delta = (widget.cardWidth + 20) * 3;
    final target = forward
        ? _scrollController.offset + delta
        : _scrollController.offset - delta;
    _scrollController.animateTo(
      target.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateArrowState);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final colors = LandingThemeColors.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final paddingHorizontal = isMobile ? 20.0 : 64.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.primaryAccent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: isMobile ? 20 : 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          style: TextStyle(
                            color: colors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (!isMobile && widget.items.length > 4)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ArrowButton(
                        icon: Icons.chevron_left_rounded,
                        enabled: _showLeftArrow,
                        onTap: () => _scroll(false),
                      ),
                      const SizedBox(width: 8),
                      _ArrowButton(
                        icon: Icons.chevron_right_rounded,
                        enabled: _showRightArrow,
                        onTap: () => _scroll(true),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Horizontal Content Rail
          SizedBox(
            height: widget.cardHeight + 24,
            child: ListView.builder(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(
                horizontal: paddingHorizontal,
                vertical: 8,
              ),
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                final item = widget.items[index];
                final rank = widget.isRanked ? index + 1 : null;

                if (widget.isRanked) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 28),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Giant Typography Rank Number in background
                        Positioned(
                          left: -20,
                          bottom: -10,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 110,
                              fontWeight: FontWeight.w900,
                              height: 1.0,
                              foreground: Paint()
                                ..style = PaintingStyle.stroke
                                ..strokeWidth = 3
                                ..color = colors.primaryAccent.withOpacity(0.35),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 36),
                          child: PremiumContentCard(
                            content: item,
                            width: widget.cardWidth,
                            height: widget.cardHeight,
                            rankNumber: rank,
                            onTap: () => widget.onContentTap(item),
                            onPlayTrailer: () => widget.onPlayTrailer(item),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(right: 18),
                  child: PremiumContentCard(
                    content: item,
                    width: widget.cardWidth,
                    height: widget.cardHeight,
                    onTap: () => widget.onContentTap(item),
                    onPlayTrailer: () => widget.onPlayTrailer(item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowButton extends StatefulWidget {
  const _ArrowButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_ArrowButton> createState() => _ArrowButtonState();
}

class _ArrowButtonState extends State<_ArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = LandingThemeColors.of(context);

    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.enabled
                ? (_hovered ? colors.primaryAccent : colors.surface)
                : colors.surface.withOpacity(0.4),
            border: Border.all(
              color: widget.enabled
                  ? (_hovered ? colors.primaryAccent : colors.border)
                  : colors.border.withOpacity(0.3),
            ),
          ),
          child: Center(
            child: Icon(
              widget.icon,
              size: 22,
              color: widget.enabled
                  ? (_hovered ? Colors.white : colors.textPrimary)
                  : colors.textMuted.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }
}
