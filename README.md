[![pub package](https://img.shields.io/pub/v/thousands_separator_formatter.svg)](https://pub.dev/packages/thousands_separator_formatter)
[![license: BSD-3-Clause](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](https://github.com/aiden30015/thousands_separator_formatter/blob/main/LICENSE)

A `TextInputFormatter` that inserts thousands separators into a `TextField` as
the user types — `1000000` becomes `1,000,000` — while keeping the caret next
to the same character.

Most hand-rolled grouping formatters get the display right and the editing
wrong: the caret jumps to the end of the field, selections collapse, and IME
input breaks mid-composition. This one handles those cases.

## Features

- **Caret stability.** Editing in the middle of `1,234,567` leaves the caret
  next to the character you typed instead of jumping to the end.
- **Selection preservation.** A non-collapsed selection keeps covering the same
  characters, and a reversed selection keeps its direction.
- **IME safe.** Reformatting is skipped while a composing region is active, so
  Korean, Japanese, and Chinese input methods are not interrupted
  mid-composition.
- **Non-Western digits.** Persian and Arabic-Indic digits group correctly with
  no extra configuration, because anything that is not the separator is treated
  as a value character.
- **Configurable grouping.** The separator, group size, and decimal handling
  are explicit parameters, with opt-in support for the Indian numbering
  system's `1,23,45,678` pattern.
- **No dependencies.** Pure Flutter; no `intl`.

## Getting started

Add the package:

```console
flutter pub add thousands_separator_formatter
```

Then import it:

```dart
import 'package:thousands_separator_formatter/thousands_separator_formatter.dart';
```

## Usage

Pass the formatter to `TextField.inputFormatters`. The formatter only groups
characters; it does not restrict what can be entered. Compose it with
`FilteringTextInputFormatter.digitsOnly` to limit input to digits, with the
filter first so grouping runs on the already-filtered value:

```dart
TextField(
  keyboardType: TextInputType.number,
  inputFormatters: <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    const ThousandsSeparatorTextInputFormatter(),
  ],
)
```

### Options

| Parameter | Default | Description |
| --- | --- | --- |
| `separator` | `','` | Character inserted between groups. |
| `groupSize` | `3` | Characters per group. |
| `allowDecimal` | `false` | When true, text at and after `decimalSeparator` is left ungrouped. |
| `decimalSeparator` | `'.'` | Character introducing the fractional part. |
| `indianGrouping` | `false` | When true, groups as `1,23,45,678`; `groupSize` does not apply. |

```dart
// Space-separated groups of two: 100000 -> "10 00 00"
const ThousandsSeparatorTextInputFormatter(separator: ' ', groupSize: 2);

// Group only the integer part: 1234.5678 -> "1,234.5678"
const ThousandsSeparatorTextInputFormatter(allowDecimal: true);

// Indian numbering system: 12345678 -> "1,23,45,678"
const ThousandsSeparatorTextInputFormatter(indianGrouping: true);
```

### Indian numbering system

Set `indianGrouping` to group the last three characters together and everything
before them in twos, the convention used for Indian rupee amounts:

| Input | Default | `indianGrouping: true` |
| --- | --- | --- |
| `99999` | `99,999` | `99,999` |
| `100000` | `100,000` | `1,00,000` |
| `12345678` | `12,345,678` | `1,23,45,678` |

The 3-then-2 widths are fixed, so `groupSize` is ignored when `indianGrouping`
is true. `separator`, `allowDecimal`, and `decimalSeparator` still apply.

A complete example is in the [`example/`][example] folder.

## Additional information

### Locale

`separator`, `groupSize`, and `decimalSeparator` are explicit parameters rather
than being derived from a locale, so this package has no dependency on `intl`.
Pick values appropriate for your user's locale.

### Not supported

- **Locale-aware defaults.** The formatter never inspects the ambient locale.
  For formatting values that are already committed rather than being typed, use
  [`NumberFormat`][numberformat] from the `intl` package.
- **Arbitrary variable group sizes.** Apart from `indianGrouping`, `groupSize`
  is a single value, so other conventions that mix group widths are out of
  scope.
- **Input filtering.** Use `FilteringTextInputFormatter` for that.

### Issues

File bugs and feature requests on the [issue tracker][tracker].

[example]: https://github.com/aiden30015/thousands_separator_formatter/tree/main/example
[numberformat]: https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html
[tracker]: https://github.com/aiden30015/thousands_separator_formatter/issues
