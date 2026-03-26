// To parse this JSON data, do
//
//     final orderModel = orderModelFromJson(jsonString);

import 'dart:convert';

List<OrderModel> orderModelFromJson(String str) =>
    List<OrderModel>.from(json.decode(str).map((x) => OrderModel.fromJson(x)));

String orderModelToJson(List<OrderModel> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class OrderModel {
  OrderModel({
    this.id,
    this.name,
    this.soldBy,
    this.countByType,
    this.prices,
    this.barcode,
    this.representation,
    this.sku,
    this.category,
    this.price,
    this.mxik,
    this.categoryName,
    this.categoryId,
    this.cost,
    this.ndsValue,
  });

  String? id;
  String? name;
  String? soldBy;
  int? countByType;
  List<dynamic>? prices;
  List<String>? barcode;
  String? representation;
  int? sku;
  String? category;
  int? price;
  String? mxik;
  String? categoryName;
  String? categoryId;
  int? cost;
  int? ndsValue;

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json["_id"],
        name: json["name"],
        soldBy: json["sold_by"],
        countByType: json["count_by_type"],
        prices: List<dynamic>.from(json["prices"].map((x) => x)),
        barcode: List<String>.from(json["barcode"].map((x) => x)),
        representation: json["representation"],
        sku: json["sku"],
        category: json["category"],
        price: json["price"],
        mxik: json["mxik"],
        categoryName: json["category_name"],
        categoryId: json["category_id"],
        cost: json["cost"],
        ndsValue: json["nds_value"],
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "name": name,
        "sold_by": soldBy,
        "count_by_type": countByType,
        "prices": List<dynamic>.from(prices!.map((x) => x)),
        "barcode": List<dynamic>.from(barcode!.map((x) => x)),
        "representation": representation,
        "sku": sku,
        "category": category,
        "price": price,
        "mxik": mxik,
        "category_name": categoryName,
        "category_id": categoryId,
        "cost": cost,
        "nds_value": ndsValue,
      };
}
