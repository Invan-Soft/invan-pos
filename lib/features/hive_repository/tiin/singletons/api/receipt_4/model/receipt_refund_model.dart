class RefundedReceipt {
  String? id;
  num? quantity;
  num? price;
  RefundedReceipt({
    this.id,
    required this.price,
    this.quantity,
  });
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      "id": id,
      "price": price,
      "quantity": quantity,
    };
    return json;
  }
}
