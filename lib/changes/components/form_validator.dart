import 'package:flutter/services.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class FormValidator {
  static String? general(value) {
    value as String;
    if (value.isEmpty) return "Please, Fill the field";
    return null;
  }

  static String? cardNumber(String? value) {
    if (value != null || value!.isNotEmpty) {
      // return "Please, fill the field";
      String cleanValue = value.replaceAll(' ', '');

      if (!RegExp(r'^\d+$').hasMatch(cleanValue)) {
        return "Please, enter only numbers";
      } else if (cleanValue.length != 16) {
        return "Please, enter exactly 16 digits";
      }
    }
    return null;
  }

  static String? phonee(value) {
    if (value.isEmpty) {
      return "Please, Fill the field";
    } else if (value.length < 14) {
      return "Enter valid phone number";
    }
    return null;
  }

  static String? code(value) {
    if (value.isEmpty) {
      return "Please, Fill the field";
    } else if (value.length < 4) {
      return "Code length must be 4";
    }
    return null;
  }

  // Phone number formatter
  static final phoneFormatter = MaskTextInputFormatter(
    mask: '(##) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  static final phoneFormatter2 = MaskTextInputFormatter(
    mask: '+998 (##) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  static final thousands = MaskTextInputFormatter(
    mask: '###,###.' '#',
    filter: {"#": RegExp('[0-9]+')},
  );

  // Code number formatter
  static final codeFormatter = MaskTextInputFormatter(
    mask: '#-#-#-#',
    filter: {"#": RegExp(r'[0-9]')},
  );
  static final cardFormatter = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  static final price = MaskTextInputFormatter(
    mask: '###,###,###,###,###,###,###,###' '#',
    filter: {"#": RegExp('[0-9]+')},
  );

  static final shtuka = FilteringTextInputFormatter.digitsOnly;

  static final kg = TextInputFormatter.withFunction((oldValue, newValue) {
    final text = newValue.text;
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
      return oldValue;
    }
    return newValue;
  });
}

// class ThousandsFormatter extends TextInputFormatter {
//   final bool allowFractions;
//   final int decimalPlaces;
//   final bool allowNegative;
//   final NumberFormat _formatter;

//   ThousandsFormatter({
//     this.allowFractions = false,
//     this.decimalPlaces = 2,
//     this.allowNegative = false,
//   }) : _formatter = NumberFormat('#,##0' + '#' * decimalPlaces);

//   @override
//   TextEditingValue formatEditUpdate(
//       TextEditingValue oldValue, TextEditingValue newValue) {
//     final String _decimalSeperator = _formatter.symbols.DECIMAL_SEP;
//     return textManipulation(oldValue, newValue,
//         textInputFormatter: allowFractions
//             ? (allowNegative
//                 ? FilteringTextInputFormatter.allow(
//                     RegExp('[0-9-]+([$_decimalSeperator])?'))
//                 : FilteringTextInputFormatter.allow(
//                     RegExp('[0-9]+([$_decimalSeperator])?')))
//             : (allowNegative
//                 ? FilteringTextInputFormatter.allow(RegExp('[0-9-]+'))
//                 : FilteringTextInputFormatter.digitsOnly),
//         formatPattern: (String filteredString) {
//       if (allowNegative) {
//         if ('-'.allMatches(filteredString).length >= 1) {
//           filteredString = (filteredString.startsWith('-') ? '-' : '');
//           filteredString.replaceAll('-', '');
//         }
//       }
//       if (filteredString.isEmpty) return '';
//       num number;
//       if (allowFractions) {
//         String decimalDigits = filteredString;
//         if (_decimalSeperator != '.') {
//           decimalDigits =
//               filteredString.replaceFirst(RegExp(_decimalSeperator), '.');
//         }
//         number = double.tryParse(decimalDigits) ?? 0;
//       } else {
//         number = int.tryParse(filteredString) ?? 0;
//       }
//       final result = _formatter.format(number);
//       if (allowFractions && filteredString.endsWith(_decimalSeperator)) {
//         return "$result$_decimalSeperator";
//       }

//       if (allowNegative) {
//         if (allowFractions) {
//           if (filteredString == '-' ||
//               filteredString == '-0' ||
//               filteredString == '-0.') {
//             return filteredString;
//           }
//         }
//         if (filteredString == '-') {
//           return filteredString;
//         }
//       }
//       if (allowFractions && filteredString.contains('.')) {
//         List<String> decimalPlacesValue = filteredString.split(".");
//         String decimalOnly = decimalPlacesValue[1];
//         String decimalTruncateted =
//             decimalOnly.substring(0, min(decimalPlaces, decimalOnly.length));
//         double digitsOnly = double.tryParse(decimalPlacesValue[0]) ?? 0;
//         String result = _formatter.format(digitsOnly);
//         result = result + '.' + '$decimalTruncateted';
//       }
//       return result;
//     });
//   }

//   TextEditingValue textManipulation(
//       TextEditingValue oldValue, TextEditingValue newValue,
//       {required TextInputFormatter textInputFormatter,
//       String Function(String filteredString)? formatPattern}) {
//     return ThousandsFormatter().textManipulation(oldValue, newValue,
//         textInputFormatter: textInputFormatter);
//   }
// }
