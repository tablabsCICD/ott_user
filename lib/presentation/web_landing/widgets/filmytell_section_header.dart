import 'package:flutter/material.dart';
import 'package:ott/presentation/web_landing/utils/filmytell_theme.dart';

/// Reusable OTT Section Header with Crimson vertical accent bar and optional action controls.
class FilmytellSectionHeader extends StatelessWidget {
  const FilmytellSectionHeader({
    super.key,
    required this.title,
    this.eyebrow,
    this.action,
    this.onPrev,
    this.onNext,
  });

  final String title;
  final String? eyebrow;
  final Widget? action;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isMobile = width < 600;
    final isTablet = width >= 600 && width < 1024;
    final barHeight = isMobile ? 22.0 : (isTablet ? 26.0 : 28.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (eyebrow != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: FilmytellTheme.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: FilmytellTheme.primary.withValues(alpha: 0.35),
              ),
            ),
            child: Text(
              eyebrow!.toUpperCase(),
              style: const TextStyle(
                color: FilmytellTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            // Vertical crimson accent indicator (| Section Heading)
            Container(
              height: barHeight,
              width: 4,
              decoration: BoxDecoration(
                color: FilmytellTheme.primary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: FilmytellTheme.primary.withValues(alpha: 0.6),
                    blurRadius: 8,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: FilmytellTheme.sectionHeading(
                  isMobile: isMobile,
                  isTablet: isTablet,
                ),
              ),
            ),
            if (action != null) action!,
            if (onPrev != null && onNext != null && !isMobile) ...[
              const SizedBox(width: 12),
              _HeaderArrowButton(
                icon: Icons.chevron_left_rounded,
                onTap: onPrev!,
              ),
              const SizedBox(width: 8),
              _HeaderArrowButton(
                icon: Icons.chevron_right_rounded,
                onTap: onNext!,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeaderArrowButton extends StatefulWidget {
  const _HeaderArrowButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<_HeaderArrowButton> createState() => _HeaderArrowButtonState();
}

class _HeaderArrowButtonState extends State<_HeaderArrowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 36,
          width: 36,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.white.withValues(alpha: 0.20)
                : Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: _hovered ? 0.35 : 0.12),
            ),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
