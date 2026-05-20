import 'package:flutter/services.dart';

class UpperCaseTextFormatterr extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    if (text.isNotEmpty) {
      String first = text[0];
      String end = '';
      if (text.length > 1) {
        end = text.substring(1, text.length);
      }

      text = first.toUpperCase() + end;
    }

    return TextEditingValue(
      text: text,
      selection: newValue.selection,
    );
  }
}
