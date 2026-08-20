# Example

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:thousands_separator_formatter/thousands_separator_formatter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                const ThousandsSeparatorTextInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '1,000,000',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```
