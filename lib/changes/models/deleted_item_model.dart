/// Savatdan o'chirilgan mahsulot yozuvi — order_pos body'sidagi
/// "deleted_items" massiviga ketadi. Chek bilan birga ObjectBox'da
/// JSON string sifatida saqlanadi (offline holatda ham yo'qolmaydi).
class DeletedItemModel4 {
  String deletedBy;
  String deletedTime;
  String productId;
  double quantity;
  double totalPrice;

  DeletedItemModel4({
    required this.deletedBy,
    required this.deletedTime,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
  });

  Map<String, dynamic> toJson() => {
        'deleted_by': deletedBy,
        'deleted_time': deletedTime,
        'product_id': productId,
        'quantity': quantity,
        'total_price': totalPrice,
      };

  factory DeletedItemModel4.fromJson(Map<String, dynamic> json) =>
      DeletedItemModel4(
        deletedBy: json['deleted_by'] ?? '',
        deletedTime: json['deleted_time'] ?? '',
        productId: json['product_id'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      );
}
