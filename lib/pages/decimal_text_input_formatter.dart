import 'package:flutter/services.dart';

class DecimalTextInputFormatter extends TextInputFormatter {
  DecimalTextInputFormatter({this.decimalSeparator = ','});

  final String decimalSeparator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String raw = newValue.text;
    if (raw.isEmpty) return newValue;

    final StringBuffer buffer = StringBuffer();
    bool hasSeparator = false;

    for (final rune in raw.runes) {
      final ch = String.fromCharCode(rune);
      final bool isDigit = ch.codeUnitAt(0) >= 48 && ch.codeUnitAt(0) <= 57;
      if (isDigit) {
        buffer.write(ch);
        continue;
      }
      if ((ch == ',' || ch == '.') && !hasSeparator) {
        hasSeparator = true;
        buffer.write(decimalSeparator);
      }
    }

    final String formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
