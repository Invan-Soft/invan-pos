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
  }) {
    if (id != null) {
      _id = id;
    }
    if (ownerType != null) {
      _ownerType = ownerType;
    }
    if (discount != null) {
      _discount = discount;
    }
    if (price != null) {
      _price = price;
    }
    if (barcode != null) {
      _barcode = barcode;
    }
    if (amount != null) {
      _amount = amount;
    }
    if (vatPercent != null) {
      _vatPercent = vatPercent;
    }
    if (vat != null) {
      _vat = vat;
    }
    if (name != null) {
      _name = name;
    }
    if (label != null) {
      _label = label;
    }
    if (classCode != null) {
      _classCode = classCode;
    }
    if (other != null) {
      _other = other;
    }
    if (tin != null) {
      _tin = tin;
    }
    if (packageCode != null) {
      _packageCode = packageCode;
    }
    if (packageName != null) {
      _packageName = packageName;
    }
  }

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
  set tin(String? tin) => _tin;
  String? get id => _id;
  set id(String? id) => _id;

  int? get ownerType => _ownerType;
  set ownerType(int? ownerType) => _ownerType;

  String? get packageCode => _packageCode;
  set packageCode(String? packageCode) => _packageCode;

  String? get packageName => _packageName;
  set packageName(String? packageName) => _packageName;

  SalingItemModel.fromJson(Map<String, dynamic> json) {
    _discount = json['discount'];
    _price = json['price'];
    _barcode = json['barcode'];
    _amount = json['amount'];
    _vatPercent = json['vatPercent'];
    _vat = json['vat'];
    _name = json['name'];
    _label = json['label'];
    _classCode = json['classCode'];
    _other = json['other'];
    _tin = json['commissionTIN'];
    _id = json['id'];
    _packageCode = json['packageCode'];
    _packageName = json['packageName'];
    _ownerType = json['owner_type'];
  }

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
    // Log.d(_tin, name: 'sale_item_model');
    if (!(_tin?.isEmpty ?? true) || (_tin?.length != 9 || _tin?.length != 14)) {
      data['commissionTIN'] = _tin;
    }

    return data;
  }
}
