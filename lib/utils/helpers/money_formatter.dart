import 'package:intl/intl.dart';

class MoneyFormatter {
  static final inputMoneyFormatter = NumberFormat('#,###.###', 'en_US');
  static final formatter = NumberFormat('#,##0', 'en_US');
  static final formatVat = NumberFormat('#,##0', 'en_US');
  static String remover(String rowString) {
    if (rowString.isEmpty) return '';

    
    return rowString.replaceAll(RegExp(r'^\D+|(?<=\d),(?=\d)'), '');
  }
}
