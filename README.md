# thousands_separator_formatter

A `TextInputFormatter` that inserts thousands separators into a `TextField` as
the user types — `1000000` becomes `1,000,000` — while keeping the caret next
to the same character.

```dart
TextField(
  keyboardType: TextInputType.number,
  inputFormatters: <TextInputFormatter>[
    FilteringTextInputFormatter.digitsOnly,
    const ThousandsSeparatorTextInputFormatter(),
  ],
)
```

## Why another formatter

Most hand-rolled thousands-separator formatters get the easy case right and the
editing cases wrong. This one handles:

- **Caret stability.** Editing in the middle of `1,234,567` keeps the caret next
  to the character you typed, instead of jumping to the end of the field.
- **Selections.** A non-collapsed selection keeps covering the same characters,
  and a reversed selection keeps its direction.
- **IME composition.** Reformatting is skipped while a composing region is
  active, so Korean, Japanese and Chinese input methods are not interrupted
  mid-composition.
- **Non-Western digits.** Persian and Arabic-Indic digits group correctly with
  no extra configuration, because anything that is not the separator is treated
  as a value character.

## Options

| Parameter | Default | Description |
| --- | --- | --- |
| `separator` | `','` | Character inserted between groups. |
| `groupSize` | `3` | Characters per group. |
| `allowDecimal` | `false` | When true, text at and after `decimalSeparator` is left ungrouped. |
| `decimalSeparator` | `'.'` | Character introducing the fractional part. |

```dart
// Space-separated groups of two: 100000 -> "10 00 00"
const ThousandsSeparatorTextInputFormatter(separator: ' ', groupSize: 2);

// Group only the integer part: 1234.5678 -> "1,234.5678"
const ThousandsSeparatorTextInputFormatter(allowDecimal: true);
```

## Locale

`separator`, `groupSize` and `decimalSeparator` are explicit parameters rather
than being derived from a locale, so this package has no dependency on `intl`.
Pick values appropriate for your user's locale. For locale-aware formatting of
values that are already committed (rather than being typed), use
[`NumberFormat`](https://pub.dev/documentation/intl/latest/intl/NumberFormat-class.html)
from the `intl` package.

## Composition

The formatter only groups; it does not restrict what can be entered. Compose it
with `FilteringTextInputFormatter.digitsOnly` — the filter first, so grouping
runs on the already-filtered value.

## Background

This started as [flutter/flutter#188243](https://github.com/flutter/flutter/pull/188243),
a proposal to add the formatter to `package:flutter/services.dart` for
[flutter/flutter#188152](https://github.com/flutter/flutter/issues/188152). Per
the Flutter
[style guide](https://github.com/flutter/flutter/blob/master/docs/contributing/Style-guide-for-Flutter-repo.md#deciding-where-to-put-code),
self-contained features are published as packages first, so it lives here.
