/// A [TextInputFormatter] that inserts thousands separators as the user types.
///
/// See [ThousandsSeparatorTextInputFormatter].
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';

/// A [TextInputFormatter] that inserts a grouping [separator] between every
/// [groupSize] characters of the integer portion of the input, as you type.
///
/// This is commonly used to display large numbers with thousands separators,
/// for example formatting `1000000` as `1,000,000` while the user types. The
/// [TextEditingValue.selection] is adjusted so the caret stays next to the same
/// character after the separators are inserted or removed.
///
/// This formatter only performs grouping; it does not restrict which characters
/// the user may enter. Compose it with a [FilteringTextInputFormatter] to limit
/// input to digits. The grouping formatter should come after the filter so it
/// operates on the already-filtered value:
///
/// ```dart
/// TextField(
///   keyboardType: TextInputType.number,
///   inputFormatters: <TextInputFormatter>[
///     FilteringTextInputFormatter.digitsOnly,
///     const ThousandsSeparatorTextInputFormatter(),
///   ],
/// )
/// ```
///
/// Because the [separator], [groupSize] and [decimalSeparator] are explicit
/// parameters rather than being derived from a locale, this formatter has no
/// dependency on the `intl` package and the caller is responsible for choosing
/// values appropriate to the user's locale. For locale-aware number formatting
/// of already-committed values, see [`NumberFormat`](https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html)
/// from the `intl` package.
///
/// Any characters other than the [separator] are treated as part of the value,
/// so the formatter works with non-Western digits (such as Persian or
/// Arabic-Indic digits) without additional configuration.
///
/// See also:
///
///  * [FilteringTextInputFormatter], which can restrict input to digits.
class ThousandsSeparatorTextInputFormatter extends TextInputFormatter {
  /// Creates a formatter that groups the integer part of the input.
  ///
  /// The [separator] and [decimalSeparator] must each be a single UTF-16 code
  /// unit and must differ from each other. The [groupSize] must be greater than
  /// zero.
  const ThousandsSeparatorTextInputFormatter({
    this.separator = ',',
    this.groupSize = 3,
    this.allowDecimal = false,
    this.decimalSeparator = '.',
    this.indianGrouping = false,
  }) : assert(separator.length == 1),
       assert(decimalSeparator.length == 1),
       assert(separator != decimalSeparator),
       assert(groupSize > 0);

  /// The character inserted between groups of digits.
  ///
  /// Defaults to a comma (`,`).
  final String separator;

  /// The number of characters in each group.
  ///
  /// Defaults to 3, producing groups such as `1,000,000`. Ignored when
  /// [indianGrouping] is true, which uses a fixed 3-then-2 pattern.
  final int groupSize;

  /// Whether the input may contain a fractional part introduced by
  /// [decimalSeparator].
  ///
  /// When true, characters at and after the first [decimalSeparator] are left
  /// ungrouped. When false, the [decimalSeparator] is treated like any other
  /// value character. Defaults to false.
  final bool allowDecimal;

  /// The character that introduces the fractional part of the input.
  ///
  /// Only meaningful when [allowDecimal] is true. Defaults to a period (`.`).
  final String decimalSeparator;

  /// Whether to group using the Indian numbering system.
  ///
  /// When true, the last three characters form one group and everything before
  /// it is grouped in twos, formatting `12345678` as `1,23,45,678`. This
  /// pattern mixes group widths, so [groupSize] does not apply. Defaults to
  /// false.
  final bool indianGrouping;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Leave the value untouched while there is an active composing region (for
    // example, an IME mid-composition); reformat once composing ends.
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) {
      return newValue;
    }

    final String newText = newValue.text;

    // Strip any existing grouping separators so the value can be regrouped from
    // scratch. Everything that is not a [separator] is preserved verbatim.
    final String value = newText.replaceAll(separator, '');

    // Split off the fractional part, if any, so only the integer part is
    // grouped.
    final int decimalIndex = allowDecimal
        ? value.indexOf(decimalSeparator)
        : -1;
    final String integerPart = decimalIndex == -1
        ? value
        : value.substring(0, decimalIndex);
    final String fractionPart = decimalIndex == -1
        ? ''
        : value.substring(decimalIndex);

    final String formatted =
        (indianGrouping ? _groupIndian(integerPart) : _group(integerPart)) +
        fractionPart;

    if (formatted == newText) {
      return newValue;
    }

    // Keep the caret next to the same value character by counting the
    // non-separator characters before each end of the original selection and
    // mapping that count back onto the regrouped string. Both ends are mapped
    // so a non-empty selection (and its direction) is preserved rather than
    // collapsed to a single caret.
    final TextSelection selection = newValue.selection;
    final TextSelection newSelection;
    if (!selection.isValid) {
      newSelection = TextSelection.collapsed(offset: formatted.length);
    } else if (selection.isCollapsed) {
      newSelection = TextSelection.collapsed(
        offset: _offsetForValueCount(
          formatted,
          _valueCharsBefore(newText, selection.extentOffset),
        ),
      );
    } else {
      newSelection = selection.copyWith(
        baseOffset: _offsetForValueCount(
          formatted,
          _valueCharsBefore(newText, selection.baseOffset),
        ),
        extentOffset: _offsetForValueCount(
          formatted,
          _valueCharsBefore(newText, selection.extentOffset),
        ),
      );
    }

    return TextEditingValue(text: formatted, selection: newSelection);
  }

  // Counts the value (non-separator) characters before [offset] in [text].
  int _valueCharsBefore(String text, int offset) {
    final int end = math.min(offset, text.length);
    return text.substring(0, end).replaceAll(separator, '').length;
  }

  // Returns the offset in [formatted] that sits just after [valueCount] value
  // (non-separator) characters.
  int _offsetForValueCount(String formatted, int valueCount) {
    if (valueCount <= 0) {
      return 0;
    }
    var count = 0;
    for (var i = 0; i < formatted.length; i += 1) {
      if (formatted[i] != separator) {
        count += 1;
        if (count == valueCount) {
          return i + 1;
        }
      }
    }
    return formatted.length;
  }

  // Inserts [separator] between every [groupSize] characters of [digits],
  // counting from the right, preserving an optional leading sign character.
  String _group(String digits) {
    var start = 0;
    var sign = '';
    if (digits.isNotEmpty && (digits[0] == '-' || digits[0] == '+')) {
      sign = digits[0];
      start = 1;
    }
    final int length = digits.length - start;
    if (length <= groupSize) {
      return digits;
    }

    final buffer = StringBuffer(sign);
    final int firstGroup = length % groupSize == 0
        ? groupSize
        : length % groupSize;
    buffer.write(digits.substring(start, start + firstGroup));
    for (int i = start + firstGroup; i < digits.length; i += groupSize) {
      buffer.write(separator);
      buffer.write(digits.substring(i, i + groupSize));
    }
    return buffer.toString();
  }

  // Inserts [separator] using the Indian numbering system: the last three
  // characters form one group and everything before it is grouped in twos,
  // preserving an optional leading sign character.
  String _groupIndian(String digits) {
    var start = 0;
    var sign = '';
    if (digits.isNotEmpty && (digits[0] == '-' || digits[0] == '+')) {
      sign = digits[0];
      start = 1;
    }
    if (digits.length - start <= 3) {
      return digits;
    }

    // Everything before the trailing three characters is grouped in twos, so an
    // odd number of leading characters leaves one on its own in the first
    // group.
    final int split = digits.length - 3;
    final int firstGroup = (split - start).isOdd ? 1 : 2;

    final buffer = StringBuffer(sign);
    buffer.write(digits.substring(start, start + firstGroup));
    for (int i = start + firstGroup; i < split; i += 2) {
      buffer.write(separator);
      buffer.write(digits.substring(i, i + 2));
    }
    buffer.write(separator);
    buffer.write(digits.substring(split));
    return buffer.toString();
  }
}
