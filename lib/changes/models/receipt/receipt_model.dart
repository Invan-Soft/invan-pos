// ignore_for_file: unnecessary_getters_setters

import 'package:hive/hive.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/utils/utils.dart';

part 'receipt_model.g.dart';

@HiveType(typeId: 24)
class ReceiptModel {  
  @HiveField(0)
  String? _token;
  @HiveField(1)
  String? _method;
  @HiveField(2)
  String? _companyName;
  @HiveField(3)
  String? _companyAddress;
  @HiveField(4)
  String? _companyINN;
  @HiveField(5)
  String? _staffName;
  @HiveField(6)
  int? _printerSize;
  @HiveField(7)
  Params? _params;

  ReceiptModel({
    String? token,
    String? method,
    String? companyName,
    String? companyAddress,
    String? companyINN,
    String? staffName,
    int? printerSize,
    Params? params,
  }) {
    if (token != null) {
      _token = token;
    }
    if (method != null) {
      _method = method;
    }
    if (companyName != null) {
      _companyName = companyName;
    }
    if (companyAddress != null) {
      _companyAddress = companyAddress;
    }
    if (companyINN != null) {
      _companyINN = companyINN;
    }
    if (staffName != null) {
      _staffName = staffName;
    }
    if (printerSize != null) {
      _printerSize = printerSize;
    }
    if (params != null) {
      _params = params;
    }
  }

  String? get token => _token;
  set token(String? token) => _token = token;
  String? get method => _method;
  set method(String? method) => _method = method;
  String? get companyName => _companyName;
  set companyName(String? companyName) => _companyName = companyName;
  String? get companyAddress => _companyAddress;
  set companyAddress(String? companyAddress) =>
      _companyAddress = companyAddress;
  String? get companyINN => _companyINN;
  set companyINN(String? companyINN) => _companyINN = companyINN;
  String? get staffName => _staffName;
  set staffName(String? staffName) => _staffName = staffName;
  int? get printerSize => _printerSize;
  set printerSize(int? printerSize) => _printerSize = printerSize;
  Params? get params => _params;
  set params(Params? params) => _params = params;

  ReceiptModel.fromJson(Map<String, dynamic> json) {
    _token = json['token'];
    _method = json['method'];
    _companyName = json['companyName'];
    _companyAddress = json['companyAddress'];
    _companyINN = json['companyINN'];
    _staffName = json['staffName'];
    _printerSize = json['printerSize'];
    _params = json['params'] != null ? Params.fromJson(json['params']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['token'] = _token;
    data['method'] = _method;
    data['companyName'] = _companyName;
    data['companyAddress'] = _companyAddress;
    data['companyINN'] = _companyINN;
    data['staffName'] = _staffName;
    data['printerSize'] = _printerSize;
    if (_params != null) {
      data['params'] = _params!.toJson();
    }
    return data;
  }
}

@HiveType(typeId: 25)
class Params {
  @HiveField(0)
  DiscountCard? _discountCard;
  @HiveField(1)
  String? _paycheckNumber;
  @HiveField(2)
  List<ItemModel>? _items;
  @HiveField(3)
  int? _receivedCash;
  @HiveField(4)
  int? _receivedCard;

  Params({
    DiscountCard? discountCard,
    String? paycheckNumber,
    List<ItemModel>? items,
    int? receivedCash,
    int? receivedCard,
  }) {
    if (discountCard != null) {
      _discountCard = discountCard;
    }
    if (paycheckNumber != null) {
      _paycheckNumber = paycheckNumber;
    }
    if (items != null) {
      _items = items;
    }
    if (receivedCash != null) {
      _receivedCash = receivedCash;
    }
    if (receivedCard != null) {
      _receivedCard = receivedCard;
    }
  }

  DiscountCard? get discountCard => _discountCard;
  set discountCard(DiscountCard? discountCard) => _discountCard = discountCard;
  String? get paycheckNumber => _paycheckNumber;
  set paycheckNumber(String? paycheckNumber) =>
      _paycheckNumber = paycheckNumber;
  List<ItemModel>? get items => _items;
  set items(List<ItemModel>? items) => _items = items;
  int? get receivedCash => _receivedCash;
  set receivedCash(int? receivedCash) => _receivedCash = receivedCash;
  int? get receivedCard => _receivedCard;
  set receivedCard(int? receivedCard) => _receivedCard = receivedCard;

  Params.fromJson(Map<String, dynamic> json) {
    // Log.j(json, name: 'receipt_model');
    _discountCard = json['discountCard'] != null
        ? DiscountCard.fromJson(json['discountCard'])
        : null;
    _paycheckNumber = json['paycheckNumber'];
    if (json['items'] != null) {
      _items = <ItemModel>[];

      json['items'].forEach((v) {
        Log.d(v['barcode'].runtimeType, name: 'receipt_model');
        if (v['barcode'] is String) {
          v['barcode'] = v['barcode'].toString().split(',');
        }
        _items?.add(ItemModel.fromJson(v));
      });
    }

    _receivedCash = json['receivedCash']?.toInt();
    _receivedCard = json['receivedCard']?.toInt();
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (_discountCard != null) {
      data['discountCard'] = _discountCard!.toJson();
    }
    data['paycheckNumber'] = _paycheckNumber;
    if (_items != null) {
      data['items'] = _items!.map((v) => v.toJson()).toList();
    }
    data['receivedCash'] = _receivedCash;
    data['receivedCard'] = _receivedCard;

    return data;
  }
}

@HiveType(typeId: 26)
class DiscountCard {
  @HiveField(0)
  int? _available;
  @HiveField(1)
  int? _addition;
  @HiveField(2)
  int? _subtraction;
  @HiveField(3)
  int? _remainder;

  DiscountCard(
      {int? available, int? addition, int? subtraction, int? remainder}) {
    if (available != null) {
      _available = available;
    }
    if (addition != null) {
      _addition = addition;
    }
    if (subtraction != null) {
      _subtraction = subtraction;
    }
    if (remainder != null) {
      _remainder = remainder;
    }
  }

  int? get available => _available;
  set available(int? available) => _available = available;
  int? get addition => _addition;
  set addition(int? addition) => _addition = addition;
  int? get subtraction => _subtraction;
  set subtraction(int? subtraction) => _subtraction = subtraction;
  int? get remainder => _remainder;
  set remainder(int? remainder) => _remainder = remainder;

  DiscountCard.fromJson(Map<String, dynamic> json) {
    _available = json['available'];
    _addition = json['addition'];
    _subtraction = json['subtraction'];
    _remainder = json['remainder'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['available'] = _available;
    data['addition'] = _addition;
    data['subtraction'] = _subtraction;
    data['remainder'] = _remainder;
    return data;
  }
}
