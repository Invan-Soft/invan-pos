
import 'package:objectbox/objectbox.dart';

@Entity()
class RuleCashModel4 {
  int id = 0;
  String time;
  String cashierName;
  String note;
  double money;
  bool isIncome;

  /// 0 - paidIn
  ///
  /// 1 - paidOut
  ///
  /// 2 - inkassa
  int cashType;

  RuleCashModel4({
    required this.time,
    required this.cashierName,
    required this.note,
    required this.money,
    required this.isIncome,
    required this.cashType,
  });
}
