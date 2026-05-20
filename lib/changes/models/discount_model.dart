import 'package:objectbox/objectbox.dart';

@Entity()
class DiscountModel {
  int id = 0;
  final String name;
  final double value;
  final double total;
  final String idd;
  final String type;
  DiscountModel({
    required this.idd,
    required this.name,
    required this.total,
    required this.type,
    required this.value,
  });
  toJson() {
    return {
      "_id": idd,
      "name": name,
      "total": total,
      "type": type,
      "value": value,
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return DiscountModel(
      idd: json["_id"],
      name: json["name"],
      total: json["total"],
      type: json["type"],
      value: json["value"],
    );
  }
}
