class FiscalItemModel {
  FiscalItemModel({
    String? spic,
    num? vatPercent,
    num? discount,
    num? price,
    CommissionInfo? commissionInfo,
    String? barcode,
    num? amount,
    String? label,
    num? vat,
    num? units,
    String? name,
    num? other,
    String? classCode,
    String? packageCode,
    String? commissionTIN,
    int? ownerType,
  }) {
    _spic = spic;
    _vATPercent = vatPercent;
    _discount = discount;
    _price = price;
    _commissionInfo = commissionInfo;
    _barcode = barcode;
    _amount = amount;
    _label = label;
    _vat = vat;
    _units = units;
    _name = name;
    _other = other;
    _packageCode = packageCode;
    _commissionTIN = commissionTIN;
    _ownerType = ownerType;
  }

  FiscalItemModel.fromJson(dynamic json) {
    _spic = json['SPIC'];
    _ownerType = json['owner_type'];
    _vATPercent = json['VATPercent'];
    _discount = json['Discount'];
    _price = json['Price'];
    _commissionInfo = json['CommissionInfo'] != null
        ? CommissionInfo.fromJson(json['CommissionInfo'])
        : null;
    _barcode = json['Barcode'];
    _amount = json['Amount'];
    _label = json['Label'];
    _vat = json['VAT'];
    _units = json['Units'];
    _name = json['Name'];
    _other = json['Other'];
    _packageCode = json['packageCode'];
    _commissionTIN = json['commissionTIN'];
  }

  String? _spic;
  num? _vATPercent;
  num? _discount;
  num? _price;
  CommissionInfo? _commissionInfo;
  String? _barcode;
  num? _amount;
  String? _label;
  num? _vat;
  num? _units;
  String? _name;
  num? _other;
  String? _packageCode;
  String? _commissionTIN;
  int? _ownerType;

  FiscalItemModel copyWith({
    String? spic,
    num? vATPercent,
    num? discount,
    num? price,
    CommissionInfo? commissionInfo,
    String? barcode,
    num? amount,
    String? label,
    num? vat,
    num? units,
    String? name,
    num? other,
    String? packageCode,
    String? commissionTIN,
    int? ownerType,
  }) =>
      FiscalItemModel(
        ownerType: ownerType ?? _ownerType,
        spic: spic ?? _spic,
        vatPercent: vATPercent ?? _vATPercent,
        discount: discount ?? _discount,
        price: price ?? _price,
        commissionInfo: commissionInfo ?? _commissionInfo,
        barcode: barcode ?? _barcode,
        amount: amount ?? _amount,
        label: label ?? _label,
        vat: vat ?? _vat,
        units: units ?? _units,
        name: name ?? _name,
        other: other ?? _other,
        packageCode: packageCode ?? _packageCode,
        commissionTIN: commissionTIN ?? _commissionTIN,
      );

  String get spic => _spic ?? "";

  int get ownerType => _ownerType ?? 1;

  num? get vATPercent => _vATPercent;

  num? get discount => _discount;

  num get price => _price ?? 0;

  CommissionInfo? get commissionInfo => _commissionInfo;

  String get barcode => _barcode ?? "";

  num get amount => _amount ?? 0;

  String? get label => _label;

  num? get vat => _vat;

  num? get units => _units;

  String get name => _name ?? "";

  num? get other => _other;
  String? get packageCode => _packageCode;
  String? get commissionTIN => _commissionTIN;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['SPIC'] = _spic;
    map['OwnerType'] = _ownerType;
    map['VATPercent'] = _vATPercent;
    map['Discount'] = _discount;
    map['Price'] = _price;
    if (_commissionInfo != null) {
      map['CommissionInfo'] = _commissionInfo?.toJson();
    }
    map['Barcode'] = _barcode;
    map['Amount'] = _amount;
    map['Label'] = _label;
    map['VAT'] = _vat;
    map['Units'] = _units;
    map['Name'] = _name;
    map['Other'] = _other;
    map['PackageCode'] = _packageCode;
    map['CommissionTIN'] = _commissionTIN;
    return map;
  }
}

/// TIN : "239223667"

class CommissionInfo {
  CommissionInfo({
    String? tin,
    String? pinFl,
  }) {
    _tin = tin;
    _pinFl = pinFl;
  }

  CommissionInfo.fromJson(dynamic json) {
    _tin = json['TIN'];
    _pinFl = json['PINFL'];
  }

  String? _tin;
  String? _pinFl;

  CommissionInfo copyWith({
    String? tin,
    String? pinFl,
  }) =>
      CommissionInfo(
        tin: tin ?? _tin,
        pinFl: pinFl ?? _pinFl,
      );

  String? get tin => _tin;

  String? get pinFl => _pinFl;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['TIN'] = _tin;
    map['PINFL'] = _pinFl;
    return map;
  }
}
