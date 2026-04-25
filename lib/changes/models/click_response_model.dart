// ignore_for_file: unnecessary_getters_setters

import 'dart:convert';

decodeClickResponseModel(String data) =>
    ClickResponseModel.fromJson(jsonDecode(data));

class ClickResponseModel {
  int? _errorCode;
  String? _errorNote;
  String? _paymentId;
  int? _paymentStatus;
  bool? _confirmMode;
  String? _cardType;
  String? _cardNumber;
  String? _phoneNumber;

  ClickResponseModel({
    int? errorCode,
    String? errorNote,
    String? paymentId,
    int? paymentStatus,
    bool? confirmMode,
    String? cardType,
    String? cardNumber,
    String? phoneNumber,
  }) {
    if (errorCode != null) {
      _errorCode = errorCode;
    }
    if (errorNote != null) {
      _errorNote = errorNote;
    }
    if (paymentId != null) {
      _paymentId = paymentId;
    }
    if (paymentStatus != null) {
      _paymentStatus = paymentStatus;
    }
    if (confirmMode != null) {
      _confirmMode = confirmMode;
    }
    if (cardType != null) {
      _cardType = cardType;
    }
    if (cardNumber != null) {
      _cardNumber = cardNumber;
    }
    if (phoneNumber != null) {
      _phoneNumber = phoneNumber;
    }
  }

  int? get errorCode => _errorCode;
  set errorCode(int? errorCode) => _errorCode = errorCode;
  String? get errorNote => _errorNote;
  set errorNote(String? errorNote) => _errorNote = errorNote;
  String? get paymentId => _paymentId;
  set paymentId(String? paymentId) => _paymentId = paymentId;
  int? get paymentStatus => _paymentStatus;
  set paymentStatus(int? paymentStatus) => _paymentStatus = paymentStatus;
  bool? get confirmMode => _confirmMode;
  set confirmMode(bool? confirmMode) => _confirmMode = confirmMode;
  String? get cardType => _cardType;
  set cardType(String? cardType) => _cardType = cardType;
  String? get cardNumber => _cardNumber;
  set cardNumber(String? cardNumber) => _cardNumber = cardNumber;
  String? get phoneNumber => _phoneNumber;
  set phoneNumber(String? phoneNumber) => _phoneNumber = phoneNumber;

  ClickResponseModel.fromJson(Map<String, dynamic> json) {
    _errorCode = json['error_code'];
    _errorNote = json['error_note'];
    _paymentId = json['payment_id'];
    _paymentStatus = json['payment_status'];
    _confirmMode = json['confirm_mode'];
    _cardType = json['card_type'];
    _cardNumber = json['card_number'];
    _phoneNumber = json['phone_number'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['error_code'] = _errorCode;
    data['error_note'] = _errorNote;
    data['payment_id'] = _paymentId;
    data['payment_status'] = _paymentStatus;
    data['confirm_mode'] = _confirmMode;
    data['card_type'] = _cardType;
    data['card_number'] = _cardNumber;
    data['phone_number'] = _phoneNumber;
    return data;
  }
}
