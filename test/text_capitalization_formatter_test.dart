import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ott/app/core/utils/text_capitalization_formatter.dart';

void main() {
  test('capitalizes the first letter of each word', () {
    final result = CapitalizeWordsTextInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: "john doe-smith/o'connor",
        selection: TextSelection.collapsed(offset: 23),
      ),
    );

    expect(result.text, "John Doe-Smith/O'Connor");
    expect(result.selection.extentOffset, result.text.length);
  });

  test('capitalizes sentence starts without changing other letters', () {
    final result = CapitalizeSentencesTextInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      const TextEditingValue(
        text: 'hello world. this is feedback! another line? yes',
      ),
    );

    expect(
      result.text,
      'Hello world. This is feedback! Another line? Yes',
    );
  });

  test('does not modify active IME composing text', () {
    const composing = TextEditingValue(
      text: 'john',
      composing: TextRange(start: 0, end: 4),
    );
    final result = CapitalizeWordsTextInputFormatter().formatEditUpdate(
      TextEditingValue.empty,
      composing,
    );
    expect(result, composing);
  });
}
