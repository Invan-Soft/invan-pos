/// Savatdan o'chirilgan mahsulot yozuvi — order_pos body'sidagi
/// "deleted_items" massiviga ketadi. Chek bilan birga ObjectBox'da
/// JSON string sifatida saqlanadi (offline holatda ham yo'qolmaydi).
class DeletedItemModel4 {
  String deletedBy;
  String deletedTime;

  /// Mahsulot savatga qo'shilgan vaqt (UTC, "yyyy-MM-dd HH:mm:ss").
  /// Sold item'ning createdTime (epoch millis) dan olinadi.
  String addedTime;

  /// Chek raqami. Odatda o'chirish paytida hali bo'sh ("") bo'ladi —
  /// order_pos body tuzilayotganda ReceiptModel4.toJson ichida shu chekning
  /// externalId'si qo'yiladi. LEKIN savat SOTUVSIZ bo'shaganda (mahsulot
  /// qo'shilib-o'chirilib, chek yakunlanmaganda) bu maydon "-" ga o'rnatiladi
  /// va shu holicha qoladi — backend "sotilmasdan o'chirilgan" holatni ajratadi
  /// (kassir nazorati). "-" bo'lsa toJson uni saqlaydi, bo'sh bo'lsa externalId.
  String checkNumber;
  String productId;
  double quantity;
  double totalPrice;

  DeletedItemModel4({
    required this.deletedBy,
    required this.deletedTime,
    required this.productId,
    required this.quantity,
    required this.totalPrice,
    this.addedTime = '',
    this.checkNumber = '',
  });

  Map<String, dynamic> toJson() => {
        'deleted_by': deletedBy,
        'deleted_time': deletedTime,
        'added_time': addedTime,
        'check_number': checkNumber,
        'product_id': productId,
        'quantity': quantity,
        'total_price': totalPrice,
      };

  factory DeletedItemModel4.fromJson(Map<String, dynamic> json) =>
      DeletedItemModel4(
        deletedBy: json['deleted_by'] ?? '',
        deletedTime: json['deleted_time'] ?? '',
        addedTime: json['added_time'] ?? '',
        checkNumber: json['check_number'] ?? '',
        productId: json['product_id'] ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        totalPrice: (json['total_price'] as num?)?.toDouble() ?? 0,
      );
}
