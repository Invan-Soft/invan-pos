
import 'package:objectbox/objectbox.dart';

@Entity()
class ClearReceiptModel8 {
  int id = 0;
  String cashierName;
  String cashierPhone;
  String content;
  int total;
  bool uploaded;

  ClearReceiptModel8({
    required this.cashierName,
    required this.cashierPhone,
    required this.content,
    required this.total,
    required this.uploaded,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    json["cashier_name"] = cashierName;
    json["cashier_phone"] = cashierPhone;
    json["content"] = content;
    json["total"] = total;
    return json;
  }
}
