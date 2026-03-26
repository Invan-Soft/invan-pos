import 'dart:convert';

class UzumModel {
  String? paymentId;
  String? paymentStatus;
  int? errorCode;
  String? errorMessage;
  String? clientPhoneNumber;

  UzumModel({
    this.paymentId,
    this.paymentStatus,
    this.errorCode,
    this.errorMessage,
    this.clientPhoneNumber,
  });

  UzumModel.fromJson(Map<String, dynamic> json) {
    paymentId = json['payment_id'];
    paymentStatus = json['payment_status'];
    errorCode = json['error_code'];
    errorMessage = json['error_message'].toString();
    clientPhoneNumber = json['client_phone_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['payment_id'] = paymentId;
    data['payment_status'] = paymentStatus;
    data['error_code'] = errorCode;
    data['error_message'] = errorMessage.toString();
    data['client_phone_number'] = clientPhoneNumber.toString();
    return data;
  }

  @override
  String toString() {
    const JsonEncoder encoder = JsonEncoder.withIndent("  ");
    return encoder.convert(toJson());
  }
}
