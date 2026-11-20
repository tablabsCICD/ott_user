import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Choice chip used by the Home page content-type filter (Movies, Series, …).
/// Shared so other filter rows (e.g. My Bookmarks) look and behave the same.
class ContentTypeChip extends StatelessWidget {
  const ContentTypeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? theme.primaryColor : theme.cardColor,
          border: Border.all(
            color: selected
                ? theme.primaryColor
                : theme.dividerColor.withValues(alpha: 0.2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : theme.canvasColor,
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
