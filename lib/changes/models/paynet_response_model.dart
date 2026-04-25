import 'dart:convert';

PaynetResponseModel decodePaynetResponseModel(String data) =>
    PaynetResponseModel.fromJson(jsonDecode(data));

class PaynetResponseModel {
  int? errorCode;
  String? errorNote;
  int? paymentId;
  int? paymentStatus;
  int? confirmMode;
  String? cardType;
  String? cardNumber;
  String? phoneNumber;

  PaynetResponseModel({
    this.errorCode,
    this.errorNote,
    this.paymentId,
    this.paymentStatus,
    this.confirmMode,
    this.cardType,
    this.cardNumber,
    this.phoneNumber,
  });

  bool get isConfirmMode => confirmMode == 1;

  factory PaynetResponseModel.fromJson(Map<String, dynamic> json) {
    final cm = json['confirm_mode'];
    return PaynetResponseModel(
      errorCode: json['error_code'],
      errorNote: json['error_note'],
      paymentId: json['payment_id'] is int
          ? json['payment_id']
          : int.tryParse(json['payment_id']?.toString() ?? ''),
      paymentStatus: json['payment_status'],
      confirmMode: cm is bool ? (cm ? 1 : 0) : cm,
      cardType: json['card_type'],
      cardNumber: json['card_number'],
      phoneNumber: json['phone_number'],
    );
  }
}
