import 'package:flutter/services.dart';

abstract final class AppTextInputFormatters {
  static List<TextInputFormatter> words({
    List<TextInputFormatter> additional = const [],
  }) =>
      [
        ...additional,
        CapitalizeWordsTextInputFormatter(),
      ];

  static List<TextInputFormatter> sentences({
    List<TextInputFormatter> additional = const [],
  }) =>
      [
        ...additional,
        CapitalizeSentencesTextInputFormatter(),
      ];
}

class CapitalizeWordsTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _capitalize(
      newValue,
      shouldStartNewCapital: (character) =>
          RegExp(r"[\s\-\/']").hasMatch(character),
    );
  }
}

class CapitalizeSentencesTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return _capitalize(
      newValue,
      shouldStartNewCapital: (character) =>
          character == '.' ||
          character == '!' ||
          character == '?' ||
          character == '\n',
    );
  }
}

TextEditingValue _capitalize(
  TextEditingValue value, {
  required bool Function(String character) shouldStartNewCapital,
}) {
  if (value.text.isEmpty || !value.composing.isCollapsed) return value;

  final buffer = StringBuffer();
  var capitalizeNext = true;
  for (final rune in value.text.runes) {
    final character = String.fromCharCode(rune);
    if (capitalizeNext && character.trim().isNotEmpty) {
      buffer.write(character.toUpperCase());
      capitalizeNext = false;
    } else {
      buffer.write(character);
    }
    if (shouldStartNewCapital(character)) capitalizeNext = true;
  }

  final formatted = buffer.toString();
  if (formatted == value.text) return value;
  return value.copyWith(
    text: formatted,
    selection: TextSelection(
      baseOffset: value.selection.baseOffset.clamp(0, formatted.length),
      extentOffset: value.selection.extentOffset.clamp(0, formatted.length),
      affinity: value.selection.affinity,
      isDirectional: value.selection.isDirectional,
    ),
    composing: TextRange.empty,
  );
}
