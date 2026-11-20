import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Multi-line review box for the Rating & Review section.
///
/// All colours come from the active [ThemeData] so it adapts instantly to
/// Light/Dark theme switches (cardColor fill, canvasColor text — the app's
/// foreground colour — and primaryColor for focus/cursor).
class ReviewInputField extends StatelessWidget {
  const ReviewInputField({
    super.key,
    required this.controller,
    required this.hintText,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String hintText;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.canvasColor;
    final isDark = theme.brightness == Brightness.dark;

    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: const EdgeInsets.all(10),
      child: TextField(
        controller: controller,
        minLines: 3,
        maxLines: 5,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        inputFormatters: inputFormatters,
        cursorColor: theme.primaryColor,
        style: TextStyle(color: foreground),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: foreground.withValues(alpha: 0.5)),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: const EdgeInsets.all(14),
          border: border(foreground.withValues(alpha: isDark ? 0.24 : 0.16)),
          enabledBorder: border(foreground.withValues(alpha: isDark ? 0.24 : 0.16)),
          focusedBorder: border(theme.primaryColor, 1.5),
          errorBorder: border(theme.colorScheme.error),
          focusedErrorBorder: border(theme.colorScheme.error, 1.5),
          errorStyle: TextStyle(color: theme.colorScheme.error),
        ),
      ),
    );
  }
}
