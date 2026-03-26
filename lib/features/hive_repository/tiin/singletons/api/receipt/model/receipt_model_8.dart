
import 'package:objectbox/objectbox.dart';

@Entity()
class ReceiptModel8 {
  int id = 0;
  String name;
  String client;
  int cashback;

  /// 0 - sale;
  ///
  /// 1 - refund;
  int type;
  String createdDate;

  /// 0 - not uploaded;
  ///
  /// 1 - uploaded;
  ///
  /// 2 - returned with error;
  int uploaded;
  final items = ToMany<ReceiptModelItem8>();

  ReceiptModel8({
    required this.name,
    required this.client,
    required this.cashback,
    required this.type,
    required this.createdDate,
    required this.uploaded,
  });

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> itemsMap = [];
    for (var e in items) {
      itemsMap.add(e.toJson());
    }

    Map<String, dynamic> json = {
      "name": name,
      "type": type,
      "created_date": createdDate,
      "client": client == "-1" ? 0 : client,
      "cashback": cashback,
      "item": itemsMap,
    };

    return json;
  }
}

@Entity()
class ReceiptModelItem8 {
  int id = 0;
  int sku;
  String name;
  double qty;
  int pricePosition;
  double value;

  ReceiptModelItem8({
    required this.name,
    required this.sku,
    required this.qty,
    required this.pricePosition,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      "name": name,
      "qty": qty,
      "price_position": pricePosition,
      "SKU": sku,
      "value": value,
    };

    return json;
  }
}
