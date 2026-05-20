// ignore_for_file: unnecessary_getters_setters

import 'package:invan2/changes/models/discount_model.dart';

class SalingItemModel {
  String? _id;
  dynamic _discount;
  num? _price;
  String? _barcode;
  num? _amount;
  num? _vatPercent;
  num? _vat;
  String? _name;
  String? _label;
  String? _classCode;
  num? _other;
  String? _tin;
  String? _packageCode;
  String? _packageName;
  int? _ownerType;

  // Fiskal server uchun muhim maydon
  Map<String, dynamic>? _commissionInfo;

  SalingItemModel({
    dynamic discount,
    num? price,
    String? barcode,
    num? amount,
    num? vatPercent,
    num? vat,
    String? name,
    String? label,
    String? classCode,
    num? other,
    String? tin,
    String? id,
    String? packageCode,
    String? packageName,
    int? ownerType,
    Map<String, dynamic>? commissionInfo,
  }) {
    _id = id;
    _ownerType = ownerType;
    _discount = discount;
    _price = price;
    _barcode = barcode;
    _amount = amount;
    _vatPercent = vatPercent;
    _vat = vat;
    _name = name;
    _label = label;
    _classCode = classCode;
    _other = other;
    _tin = tin;
    _packageCode = packageCode;
    _packageName = packageName;
    _commissionInfo = commissionInfo;
  }

  // Getters & Setters
  List<DiscountModel>? get discount => _discount;
  set discount(dynamic discount) => _discount = discount;

  num? get price => _price;
  set price(num? price) => _price = price;

  String? get barcode => _barcode;
  set barcode(String? barcode) => _barcode = barcode;

  num? get amount => _amount;
  set amount(num? amount) => _amount = amount;

  num? get vatPercent => _vatPercent;
  set vatPercent(num? vatPercent) => _vatPercent = vatPercent;

  num? get vat => _vat;
  set vat(num? vat) => _vat = vat;

  String? get name => _name;
  set name(String? name) => _name = name;

  String? get label => _label;
  set label(String? label) => _label = label;

  String? get classCode => _classCode;
  set classCode(String? classCode) => _classCode = classCode;

  num? get other => _other;
  set other(num? other) => _other = other;

  String? get tin => _tin;
  set tin(String? tin) => _tin = tin;

  String? get id => _id;
  set id(String? id) => _id = id;

  int? get ownerType => _ownerType;
  set ownerType(int? ownerType) => _ownerType = ownerType;

  String? get packageCode => _packageCode;
  set packageCode(String? packageCode) => _packageCode = packageCode;

  String? get packageName => _packageName;
  set packageName(String? packageName) => _packageName = packageName;

  Map<String, dynamic>? get commissionInfo => _commissionInfo;
  set commissionInfo(Map<String, dynamic>? commissionInfo) => _commissionInfo = commissionInfo;

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};

    data['id'] = _id;
    data['discount'] = _discount;
    data['price'] = _price;
    data['barcode'] = _barcode;
    data['amount'] = _amount;
    data['vatPercent'] = _vatPercent;
    data['vat'] = _vat;
    data['name'] = _name;
    data['label'] = _label;
    data['classCode'] = _classCode;
    data['other'] = _other;
    data['ownerType'] = _ownerType;
    data['packageCode'] = _packageCode;
    data['packageName'] = _packageName;

    // ← ENG MUHIM O‘ZGARISH: CommissionInfo ARRAY bo‘lishi kerak!
    data['commissionInfo'] = _commissionInfo != null 
        ? [_commissionInfo] 
        : [{"TIN": _tin ?? "", "PINFL": ""}];

    // Eski commissionTIN ni ham saqlab qo‘yamiz (kerak bo‘lsa)
    if (_tin != null && _tin!.isNotEmpty) {
      data['commissionTIN'] = _tin;
    }

    return data;
  }
}