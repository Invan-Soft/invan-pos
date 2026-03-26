// ignore_for_file: unnecessary_getters_setters, unnecessary_this

import 'dart:convert';

RequestSaleModel requestSaleModelFromJson(String str) =>
    RequestSaleModel.fromJson(json.decode(str));

String requestSaleModelToJson(RequestSaleModel data) =>
    json.encode(data.toJson());

class RequestSaleModel {
  RequestSaleModel({
    String? token,
    String? method,
    String? companyName,
    String? companyAddress,
    String? companyINN,
    String? staffName,
    num? printerSize,
    ParamsRequest? params,
    RequestRefundInfo? refundInfo,
    SenderInfo? senderInfo,
    OtherInfo? otherInfo,
  }) {
    _token = token;
    _method = method;
    _companyName = companyName;
    _companyAddress = companyAddress;
    _companyINN = companyINN;
    _staffName = staffName;
    _printerSize = printerSize;
    _params = params;
    _refundInfo = refundInfo;
    _senderInfo = senderInfo;
    _otherInfo = otherInfo;
  }

  RequestSaleModel.fromJson(dynamic json) {
    _token = json['token'];
    _method = json['method'];
    _companyName = json['companyName'];
    _companyAddress = json['companyAddress'];
    _companyINN = json['companyINN'];
    _staffName = json['staffName'];
    _printerSize = json['printerSize'];
    _params =
        json['params'] != null ? ParamsRequest.fromJson(json['params']) : null;
    if (json['refundInfo'] != null) {
      _refundInfo = RequestRefundInfo.fromJson(json['refundInfo']);
    }
    if (json['senderInfo'] != null) {
      _senderInfo = SenderInfo.fromJson(json['senderInfo']);
    }
    if (json['otherInfo'] != null) {
      _otherInfo = OtherInfo.fromJson(json['otherInfo']);
    }
  }

  String? _token;
  String? _method;
  String? _companyName;
  String? _companyAddress;
  String? _companyINN;
  String? _staffName;
  num? _printerSize;
  ParamsRequest? _params;
  RequestRefundInfo? _refundInfo;
  SenderInfo? _senderInfo;
  OtherInfo? _otherInfo;

  RequestSaleModel copyWith({
    String? token,
    String? method,
    String? companyName,
    String? companyAddress,
    String? companyINN,
    String? staffName,
    num? printerSize,
    ParamsRequest? params,
    RequestRefundInfo? refundInfo,
    SenderInfo? senderInfo,
    OtherInfo? otherInfo,
  }) =>
      RequestSaleModel(
        token: token ?? _token,
        method: method ?? _method,
        companyName: companyName ?? _companyName,
        companyAddress: companyAddress ?? _companyAddress,
        companyINN: companyINN ?? _companyINN,
        staffName: staffName ?? _staffName,
        printerSize: printerSize ?? _printerSize,
        params: params ?? _params,
        refundInfo: refundInfo ?? _refundInfo,
        senderInfo: senderInfo ?? _senderInfo,
        otherInfo: otherInfo ?? _otherInfo,
      );

  String? get token => _token;

  String? get method => _method;

  String? get companyName => _companyName;

  String? get companyAddress => _companyAddress;

  String? get companyINN => _companyINN;

  String? get staffName => _staffName;

  num? get printerSize => _printerSize;

  ParamsRequest? get params => _params;

  RequestRefundInfo? get refundInfo => _refundInfo;
  SenderInfo? get senderInfo => _senderInfo;
  OtherInfo? get otherInfo => _otherInfo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['token'] = _token;
    map['method'] = _method;
    map['companyName'] = _companyName;
    map['companyAddress'] = _companyAddress;
    map['companyINN'] = _companyINN;
    map['staffName'] = _staffName;
    map['printerSize'] = _printerSize;
    if (_params != null) {
      map['params'] = _params?.toJson();

      map['refundInfo'] = _refundInfo;
      map['senderInfo'] = _senderInfo;
      map['otherInfo'] = _otherInfo;
    }
    return map;
  }
}

ParamsRequest paramsFromJson(String str) =>
    ParamsRequest.fromJson(json.decode(str));

String paramsToJson(ParamsRequest data) => json.encode(data.toJson());

class ParamsRequest {
  ParamsRequest({
    String? paycheckNumber,
    List<FiscalItems>? items,
    num? receivedCash,
    num? receivedCard,
  }) {
    _paycheckNumber = paycheckNumber;
    _items = items;
    _receivedCash = receivedCash;
    _receivedCard = receivedCard;
  }

  ParamsRequest.fromJson(dynamic json) {
    _paycheckNumber = json['paycheckNumber'];
    if (json['items'] != null) {
      _items = [];
      json['items'].forEach((v) {
        _items?.add(FiscalItems.fromJson(v));
      });
    }

    _receivedCash = json['receivedCash'];
    _receivedCard = json['receivedCard'];
  }

  String? _paycheckNumber;
  List<FiscalItems>? _items;
  num? _receivedCash;
  num? _receivedCard;

  ParamsRequest copyWith({
    String? paycheckNumber,
    List<FiscalItems>? items,
    num? receivedCash,
    num? receivedCard,
    RequestRefundInfo? refundInfo,
  }) =>
      ParamsRequest(
        paycheckNumber: paycheckNumber ?? _paycheckNumber,
        items: items ?? _items,
        receivedCash: receivedCash ?? _receivedCash,
        receivedCard: receivedCard ?? _receivedCard,
      );

  String? get paycheckNumber => _paycheckNumber;

  List<FiscalItems>? get items => _items;

  num? get receivedCash => _receivedCash;

  num? get receivedCard => _receivedCard;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['paycheckNumber'] = _paycheckNumber;
    if (_items != null) {
      map['items'] = _items?.map((v) => v.toJson()).toList();
    }
    map['receivedCash'] = _receivedCash;
    map['receivedCard'] = _receivedCard;
    return map;
  }
}

FiscalItems itemsFromJson(String str) => FiscalItems.fromJson(json.decode(str));

String itemsToJson(FiscalItems data) => json.encode(data.toJson());

class FiscalItems {
  FiscalItems(
      {String? id,
      num? discount,
      num? price,
      String? barcode,
      num? amount,
      num? vatPercent,
      num? vat,
      String? name,
      String? classCode,
      num? other,
      String? label,
      String? tin,
      String? packageCode,
      String? packageName,
      int? ownerType}) {
    _id = id;
    _ownerType = ownerType;
    _discount = discount;
    _price = price;
    _barcode = barcode;
    _amount = amount;
    _vatPercent = vatPercent;
    _vat = vat;
    _name = name;
    _classCode = classCode;
    _other = other;
    _label = label;
    _tin = tin;
    _packageCode = packageCode;
    _packageName = packageName;
  }

  FiscalItems.fromJson(dynamic json) {
    _discount = json['discount'];
    _price = json['price'];
    _ownerType = json['ownerType'];
    _barcode = json['barcode'];
    _amount = json['amount'];
    _vatPercent = json['vatPercent'];
    _vat = json['vat'];
    _name = json['name'];
    _classCode = json['classCode'];
    _other = json['other'];
    _label = json['label'];
    _tin = json['commissionTIN'];
    _packageCode = json['packageCode'];
    _id = json['id'];
    _packageName = json['packageName'];
  }

  num? _discount;
  num? _price;
  int? _ownerType;
  String? _barcode;
  num? _amount;
  num? _vatPercent;
  num? _vat;
  String? _name;
  String? _classCode;
  num? _other;
  String? _label;
  String? _tin;
  String? _packageCode;
  String? _id;
  String? _packageName;

  FiscalItems copyWith({
    num? discount,
    num? price,
    String? barcode,
    int? ownerType,
    num? amount,
    num? vatPercent,
    num? vat,
    String? name,
    String? classCode,
    num? other,
    String? tin,
    String? packageCode,
    String? id,
    String? packageName,
  }) =>
      FiscalItems(
        discount: discount ?? _discount,
        price: price ?? _price,
        ownerType: ownerType ?? _ownerType,
        barcode: barcode ?? _barcode,
        amount: amount ?? _amount,
        vatPercent: vatPercent ?? _vatPercent,
        vat: vat ?? _vat,
        name: name ?? _name,
        classCode: classCode ?? _classCode,
        other: other ?? _other,
        tin: tin ?? _tin,
        packageCode: packageCode ?? _packageCode,
        id: id ?? _id,
        packageName: packageName ?? _packageName,
      );

  num? get discount => _discount;

  num? get price => _price;
  int? get ownerType => _ownerType;

  String? get barcode => _barcode;

  num? get amount => _amount;

  num? get vatPercent => _vatPercent;

  num? get vat => _vat;

  String? get name => _name;

  String? get classCode => _classCode;
  set setClassCode(String? clasCode) => _classCode = clasCode;

  String? get packageCode => _packageCode;
  set setPackageCode(String? packageCode) => _packageCode = packageCode;
  num? get other => _other;

  String? get label => _label;

  String? get tin => _tin;
  String? get id => _id;
  String? get packageName => _packageName;
  set setPackageName(String? packageName) => _packageName = packageName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['discount'] = _discount;
    map['price'] = _price;
    map['barcode'] = _barcode;
    map['amount'] = _amount;
    map['vatPercent'] = _vatPercent;
    map['vat'] = _vat;
    map['name'] = _name;
    map['classCode'] = _classCode;
    map['other'] = _other;
    map['label'] = _label;
    map['commissionTIN'] = _tin;
    map['packageCode'] = _packageCode;
    map['id'] = _id;
    map['packageName'] = _packageName;
    map['owner_type'] = _ownerType;

    return map;
  }
}

RequestRefundInfo refundInfoFromJson(String str) =>
    RequestRefundInfo.fromJson(json.decode(str));

// String refundInfoToJson(RequestRefundInfo data) => json.encode(data.toJson());

class RequestRefundInfo {
  RequestRefundInfo({
    String? terminalID,
    String? receiptSeq,
    String? dateTime,
    String? fiscalSign,
  }) {
    _terminalID = terminalID;
    _receiptSeq = receiptSeq;
    _dateTime = dateTime;
    _fiscalSign = fiscalSign;
  }

  RequestRefundInfo.fromJson(dynamic json) {
    _terminalID = json['terminalId'].toString();
    _receiptSeq = json['receiptSeq'].toString();
    _dateTime = json['dateTime'].toString();
    _fiscalSign = json['fiscalSign'].toString();
  }

  String? _terminalID;
  String? _receiptSeq;
  String? _dateTime;
  String? _fiscalSign;

  RequestRefundInfo copyWith({
    String? terminalID,
    String? receiptSeq,
    String? dateTime,
    String? fiscalSign,
  }) =>
      RequestRefundInfo(
        terminalID: terminalID ?? _terminalID,
        receiptSeq: receiptSeq ?? _receiptSeq,
        dateTime: dateTime ?? _dateTime,
        fiscalSign: fiscalSign ?? _fiscalSign,
      );

  String? get terminalID => _terminalID;

  String? get receiptSeq => _receiptSeq;

  String? get dateTime => _dateTime;

  String? get fiscalSign => _fiscalSign;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['TerminalID'] = _terminalID;
    map['ReceiptSeq'] = _receiptSeq;
    map['DateTime'] = _dateTime;
    map['FiscalSign'] = _fiscalSign;
    return map;
  }
}

class SenderInfo {
  String? _name;
  String? _sn;
  String? _version;

  SenderInfo({String? name, String? sn, String? version}) {
    if (name != null) {
      this._name = name;
    }
    if (sn != null) {
      this._sn = sn;
    }
    if (version != null) {
      this._version = version;
    }
  }

  String? get name => _name;
  set name(String? name) => _name = name;
  String? get sn => _sn;
  set sn(String? sn) => _sn = sn;
  String? get version => _version;
  set version(String? version) => _version = version;

  SenderInfo.fromJson(Map<String, dynamic> json) {
    _name = json['name'];
    _sn = json['sn'];
    _version = json['version'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['name'] = _name;
    data['sn'] = _sn;
    data['version'] = _version;
    return data;
  }
}

class OtherInfo {
  String? _terminalID;

  OtherInfo({
    String? terminalID,
  }) {
    if (terminalID != null) {
      _terminalID = terminalID;
    }
  }

  String? get terminalID => _terminalID;
  set terminalID(String? terminalID) => _terminalID = terminalID;

  OtherInfo.fromJson(Map<String, dynamic> json) {
    _terminalID = json['terminalID'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['terminalID'] = _terminalID;
    return data;
  }
}
