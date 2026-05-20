import 'package:objectbox/objectbox.dart';

@Entity()
class ProductDiscountModel {
  int id = 0;
  final String idd;
  final String name;
  final String typeName;
  final double value;
  final double total;
  final String typeId;

  ProductDiscountModel({
    required this.idd,
    required this.typeId,
    required this.typeName,
    required this.name,
    required this.value,
    required this.total,
  });

  toJson() {
    return {
      "idd": idd,
      "name": name,
      "value": value,
      "total": total,
      "type_name": typeName,
      "type_id": typeId,
    };
  }

  static fromJson(Map<String, dynamic> json) {
    return ProductDiscountModel(
      idd: json["idd"],
      name: json["name"],
      typeName: json["type_name"],
      typeId: json["type_id"],
      value: json["value"],
      total: json["total"],
    );
  }
}
