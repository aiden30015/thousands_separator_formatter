import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thousands_separator_formatter/thousands_separator_formatter.dart';

void main() {
  group('ThousandsSeparatorTextInputFormatter', () {
    TextEditingValue format(
      ThousandsSeparatorTextInputFormatter formatter,
      String text, {
      int? selection,
      TextEditingValue old = TextEditingValue.empty,
    }) {
      return formatter.formatEditUpdate(
        old,
        TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: selection ?? text.length),
        ),
      );
    }

    test('groups the integer part with the default separator', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      expect(format(formatter, '1').text, '1');
      expect(format(formatter, '100').text, '100');
      expect(format(formatter, '1000').text, '1,000');
      expect(format(formatter, '1000000').text, '1,000,000');
      expect(format(formatter, '500000000').text, '500,000,000');
    });

    test('regroups when separators are already present', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      // Typing a digit at the end of an already-grouped value.
      expect(format(formatter, '1,0000').text, '10,000');
      // Deleting a digit from an already-grouped value.
      expect(format(formatter, '10,00').text, '1,000');
    });

    test('keeps the caret next to the same digit', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      // "1000|" -> "1,000|"
      expect(format(formatter, '1000', selection: 4).selection.baseOffset, 5);
      // Inserting a digit in the middle: "1|000" became "12|000" -> "12,000",
      // caret should sit right after the freshly typed "2".
      final TextEditingValue result = format(formatter, '12000', selection: 2);
      expect(result.text, '12,000');
      expect(result.selection.baseOffset, 2);
    });

    test('caret stays before the value when editing at the start', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      final TextEditingValue result = format(formatter, '1000', selection: 0);
      expect(result.text, '1,000');
      expect(result.selection.baseOffset, 0);
    });

    test('supports a custom separator and group size', () {
      const formatter = ThousandsSeparatorTextInputFormatter(
        separator: ' ',
        groupSize: 2,
      );
      expect(format(formatter, '100000').text, '10 00 00');
    });

    test('groups non-Western digits without extra configuration', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      // Persian digits ۵۰۰۰۰۰ -> ۵۰۰,۰۰۰
      expect(format(formatter, '۵۰۰۰۰۰').text, '۵۰۰,۰۰۰');
    });

    test('only groups the integer part when allowDecimal is true', () {
      const formatter = ThousandsSeparatorTextInputFormatter(
        allowDecimal: true,
      );
      expect(format(formatter, '1234.5678').text, '1,234.5678');
      expect(format(formatter, '1000.5').text, '1,000.5');
    });

    test(
      'treats the decimal separator as a value character when allowDecimal is false',
      () {
        const formatter = ThousandsSeparatorTextInputFormatter();
        // With allowDecimal false the '.' is grouped like any other character, so
        // the whole run is treated as the integer part. Callers that want digits
        // only should compose with FilteringTextInputFormatter.digitsOnly.
        expect(format(formatter, '1000.5').text, '100,0.5');
      },
    );

    test('preserves a leading sign', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      expect(format(formatter, '-1000').text, '-1,000');
      expect(format(formatter, '+1000000').text, '+1,000,000');
    });

    test('passes through empty input', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      expect(format(formatter, '').text, '');
    });

    test('preserves a non-collapsed selection and its direction', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      // Select the trailing "000" of "1[000]" and let it regroup to "1,000".
      // Each end is mapped past the same number of value characters, so the
      // selection still covers those three digits as "1[,000]".
      final TextEditingValue result = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1000',
          selection: TextSelection(baseOffset: 1, extentOffset: 4),
        ),
      );
      expect(result.text, '1,000');
      expect(result.selection.baseOffset, 1);
      expect(result.selection.extentOffset, 5);
      // The selection is not collapsed.
      expect(result.selection.isCollapsed, isFalse);
      // Direction (base > extent) is retained when the selection is reversed.
      final TextEditingValue reversed = formatter.formatEditUpdate(
        TextEditingValue.empty,
        const TextEditingValue(
          text: '1000',
          selection: TextSelection(baseOffset: 4, extentOffset: 1),
        ),
      );
      expect(reversed.selection.baseOffset, 5);
      expect(reversed.selection.extentOffset, 1);
    });

    test('does not reformat during composition', () {
      const formatter = ThousandsSeparatorTextInputFormatter();
      const composing = TextEditingValue(
        text: '1000',
        selection: TextSelection.collapsed(offset: 4),
        composing: TextRange(start: 0, end: 4),
      );
      expect(
        formatter.formatEditUpdate(TextEditingValue.empty, composing),
        composing,
      );
    });
  });
}
