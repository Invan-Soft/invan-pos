import 'dart:convert';
import 'package:invan2/fiscal_service/fiscal.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'item/fiscal_item_model.dart';
import 'location/location.dart';
import 'receipt_data_model.dart';

FiscalReceiptModel fiscalreceiptModelFromJson(String str) =>
    FiscalReceiptModel.fromJson(json.decode(str));

String fiscalreceiptModelToJson(FiscalReceiptModel data) =>
    json.encode(data.toJson());
// String fiscalreceiptModelToJson(FiscalReceiptModel data) =>
//     json.encode([data.toJson()]);
class FiscalReceiptModel {
  FiscalReceiptModel({
    String? method,
    num? id,
    FiscalParams? params,
    String? jsonrpc,
  }) {
    _method = method;
    _id = id;
    _params = params;
    _jsonrpc = jsonrpc;
  }

  FiscalReceiptModel.fromJson(dynamic json) {
    _method = json['method'];
    _id = json['id'];
    _params =
        json['params'] != null ? FiscalParams.fromJson(json['params']) : null;
    _jsonrpc = json['jsonrpc'];
  }

  FiscalReceiptModel.fromRequest(
    RequestSaleModel model,
    ReceiptDataModel receiptData,
    DateTime dateTime,
    ExtraInfo extraInfo,
  ) {
    ParamsRequest param = model.params!;
    List<FiscalItems> items = param.items!;
    RequestRefundInfo? refundInfo = model.refundInfo;
    _id = 45;
    _jsonrpc = '2.0';
    _method = getMethod(model.method);

    _params = FiscalParams(
      factoryID: receiptData.factoryID,
      receipt: method == 'Api.SendRefundReceipt'
          ? FiscalReceipt(
              time: AppFormatter.formatTime(dateTime),
              receivedCard: param.receivedCard?.toInt(),
              receivedCash: param.receivedCash?.toInt(),
              location: receiptData.location,
              extraInfo: extraInfo,
              senderInfo: model.senderInfo,
              refundInfo: FiscalRefundInfo(
                terminalID: refundInfo?.terminalID,
                receiptSeq: refundInfo?.receiptSeq,
                dateTime: refundInfo?.dateTime,
                fiscalSign: refundInfo?.fiscalSign,
              ),
              items: items
                  .map(
                    (e) => FiscalItemModel(
                        amount: e.amount?.toInt(),
                        barcode: e.barcode,
                        label: e.label,
                        ownerType: e.ownerType,
                        commissionTIN: e.tin,
                        discount: e.discount!.toInt(),
                        other: e.other != null ? e.other?.toInt() : 0,
                        name: e.name,
                        price: e.price?.toInt(),
                        spic: e.classCode,
                        vat: e.vat?.toInt(),
                        vatPercent: e.vatPercent!.toInt(),
                        units: 0,
                        commissionInfo: CommissionInfo(
                            tin: e.tin?.length == 9 ? e.tin : "",
                            pinFl: e.tin?.length == 14 ? e.tin : ""),
                        packageCode: e.packageCode),
                  )
                  .toList(),
            )
          : FiscalReceipt(
              time: AppFormatter.formatTime(dateTime),
              receivedCard: param.receivedCard?.toInt(),
              receivedCash: param.receivedCash?.toInt(),
              location: receiptData.location,
              extraInfo: extraInfo,
              senderInfo: model.senderInfo,
              items: items
                  .map(
                    (e) => FiscalItemModel(
                        amount: e.amount?.toInt(),
                        barcode: e.barcode,
                        label: e.label,
                        commissionTIN: e.tin,
                        ownerType: e.ownerType,
                        discount: e.discount!.toInt(),
                        other: e.other != null ? e.other?.toInt() : 0,
                        name: e.name,
                        price: e.price?.toInt(),
                        spic: e.classCode,
                        vat: e.vat?.toInt(),
                        vatPercent: e.vatPercent!.toInt(),
                        units: 0,
                        commissionInfo: CommissionInfo(
                            tin: e.tin?.length == 9 ? e.tin : "",
                            pinFl: e.tin?.length == 14 ? e.tin : ""),
                        packageCode: e.packageCode),
                  )
                  .toList(),
            ),
    );
  }

  String? _method;
  num? _id;
  FiscalParams? _params;
  String? _jsonrpc;

  FiscalReceiptModel copyWith({
    String? method,
    num? id,
    FiscalParams? params,
    String? jsonrpc,
  }) =>
      FiscalReceiptModel(
        method: method ?? _method,
        id: id ?? _id,
        params: params ?? _params,
        jsonrpc: jsonrpc ?? _jsonrpc,
      );
  String? get method => _method;
  num? get id => _id;
  FiscalParams? get params => _params;
  String? get jsonrpc => _jsonrpc;
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['method'] = _method;
    map['id'] = _id;
    if (_params != null) {
      map['params'] = _params?.toJson();
    }
    map['jsonrpc'] = _jsonrpc;
    return map;
  }

  String getMethod(String? requestMethod) {
    switch (requestMethod) {
      case "sale":
        return ApiMethods.saleSendReceipt;

      case "refund":
        return ApiMethods.refundSaleReceipt;

      case "credit":
        return ApiMethods.creditReceipt;

      case "advance":
        return ApiMethods.advanceReceipt;

      default:
        return "";
    }
  }
}

FiscalParams paramsFromJson(String str) =>
    FiscalParams.fromJson(json.decode(str));

String paramsToJson(FiscalParams data) => json.encode(data.toJson());

class FiscalParams {
  FiscalParams({
    String? factoryID,
    FiscalReceipt? receipt,
  }) {
    _factoryID = factoryID;
    _receipt = receipt;
  }

  FiscalParams.fromJson(dynamic json) {
    _factoryID = json['FactoryID'];
    _receipt = json['Receipt'] != null
        ? FiscalReceipt.fromJson(json['Receipt'])
        : null;
  }

  String? _factoryID;
  FiscalReceipt? _receipt;

  FiscalParams copyWith({
    String? factoryID,
    FiscalReceipt? receipt,
  }) =>
      FiscalParams(
        factoryID: factoryID ?? _factoryID,
        receipt: receipt ?? _receipt,
      );

  String? get factoryID => _factoryID;

  FiscalReceipt? get receipt => _receipt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['FactoryID'] = _factoryID;
    if (_receipt != null) {
      map['Receipt'] = _receipt?.toJson();
    }
    return map;
  }
}

FiscalReceipt receiptFromJson(String str) =>
    FiscalReceipt.fromJson(json.decode(str));

String receiptToJson(FiscalReceipt data) => json.encode(data.toJson());

class FiscalReceipt {
  FiscalReceipt({
    num? receivedCash,
    num? receivedCard,
    String? time,
    FiscalRefundInfo? refundInfo,
    List<FiscalItemModel>? items,
    Location? location,
    ExtraInfo? extraInfo,
    SenderInfo? senderInfo,
  }) {
    _receivedCash = receivedCash;
    _receivedCard = receivedCard;
    _time = time;
    _refundInfo = refundInfo;
    _items = items;
    _location = location;
    _extraInfo = extraInfo;
    _senderInfo = senderInfo;
  }

  FiscalReceipt.fromJson(dynamic json) {
    _receivedCash = json['ReceivedCash'];
    _receivedCard = json['ReceivedCard'];
    _time = json['Time'];
    _refundInfo = json['FiscalRefundInfo'] != null
        ? FiscalRefundInfo.fromJson(json['FiscalRefundInfo'])
        : null;
    if (json['Items'] != null) {
      _items = [];
      json['Items'].forEach((v) {
        _items?.add(FiscalItemModel.fromJson(v));
      });
    }
    _location =
        json['Location'] != null ? Location.fromJson(json['Location']) : null;
    _extraInfo = json['ExtraInfo'] != null
        ? ExtraInfo.fromJson(json['ExtraInfo'])
        : null;
    _senderInfo = json['senderInfo'] != null
        ? SenderInfo.fromJson(json['senderInfo'])
        : null;
  }

  num? _receivedCash;
  num? _receivedCard;
  String? _time;
  FiscalRefundInfo? _refundInfo;
  List<FiscalItemModel>? _items;
  Location? _location;
  ExtraInfo? _extraInfo;
  SenderInfo? _senderInfo;

  FiscalReceipt copyWith({
    num? receivedCash,
    num? receivedCard,
    String? time,
    FiscalRefundInfo? refundInfo,
    List<FiscalItemModel>? items,
    Location? location,
    ExtraInfo? extraInfo,
    SenderInfo? senderInfo,
  }) =>
      FiscalReceipt(
        receivedCash: receivedCash ?? _receivedCash,
        receivedCard: receivedCard ?? _receivedCard,
        time: time ?? _time,
        refundInfo: refundInfo ?? _refundInfo,
        items: items ?? _items,
        location: location ?? _location,
        extraInfo: extraInfo ?? _extraInfo,
        senderInfo: senderInfo ?? _senderInfo,
      );

  num? get receivedCash => _receivedCash;

  num? get receivedCard => _receivedCard;

  String? get time => _time;

  FiscalRefundInfo? get refundInfo => _refundInfo;

  List<FiscalItemModel> get items => _items ?? [];

  Location? get location => _location;

  ExtraInfo? get extraInfo => _extraInfo;
  SenderInfo? get senderInfo => _senderInfo;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['ReceivedCash'] = _receivedCash;
    map['ReceivedCard'] = _receivedCard;
    map['Time'] = _time;
    if (_refundInfo != null) {
      // map['FiscalRefundInfo'] = _refundInfo?.toJson();
      map['RefundInfo'] = _refundInfo?.toJson();
    }
    if (_items != null) {
      map['Items'] = _items?.map((v) => v.toJson()).toList();
    }
    if (_location != null) {
      map['Location'] = _location?.toJson();
    }
    if (_extraInfo != null) {
      map['ExtraInfo'] = _extraInfo?.toJson();
    }
    if (_senderInfo != null) {
      map['SenderInfo'] = _senderInfo?.toJson();
    }
    return map;
  }
}

ExtraInfo extraInfoFromJson(String str) => ExtraInfo.fromJson(json.decode(str));

String extraInfoToJson(ExtraInfo data) => json.encode(data.toJson());

// class ExtraInfo {
//   ExtraInfo({
//     String? pinfl,
//     String? carNumber,
//     String? tin,
//     String? phoneNumber,
//     num? cardType,
//     String? qrPaymentID,
//     int? qrPaymentProvider,
//   }) {
//     _pinfl = pinfl;
//     _carNumber = carNumber;
//     _tin = tin;
//     _phoneNumber = phoneNumber;
//     _cardType = cardType;
//     _qrPaymentProvider = qrPaymentProvider;
//     _qrPaymentID = qrPaymentID;
//   }
//
//   ExtraInfo.fromJson(dynamic json) {
//     _pinfl = json['PINFL'];
//     _carNumber = json['CarNumber'];
//     _tin = json['TIN'];
//     _phoneNumber = json['PhoneNumber'];
//     _cardType = json['CardType'];
//     _qrPaymentID = json['qrPaymentID'];
//     _qrPaymentProvider = json['qrPaymentProvider'];
//   }
//
//   String? _pinfl;
//   String? _carNumber;
//   String? _tin;
//   String? _phoneNumber;
//   num? _cardType;
//   String? _qrPaymentID;
//   int? _qrPaymentProvider;
//
//   ExtraInfo copyWith({
//     String? pinfl,
//     String? carNumber,
//     String? tin,
//     String? phoneNumber,
//     num? cardType,
//     String? qrPaymentID,
//     int? qrPaymentProvider,
//   }) =>
//       ExtraInfo(
//         pinfl: pinfl ?? _pinfl,
//         carNumber: carNumber ?? _carNumber,
//         tin: tin ?? _tin,
//         phoneNumber: phoneNumber ?? _phoneNumber,
//         cardType: cardType ?? _cardType,
//         qrPaymentID: qrPaymentID ?? _qrPaymentID,
//         qrPaymentProvider: qrPaymentProvider ?? _qrPaymentProvider,
//       );
//   String? get pinfl => _pinfl;
//   String? get carNumber => _carNumber;
//   String? get tin => _tin;
//   String? get phoneNumber => _phoneNumber;
//   num? get cardType => _cardType;
//   String? get qrPaymentID => _qrPaymentID;
//   int? get qrPaymentProvider => _qrPaymentProvider;
//
//   Map<String, dynamic> toJson() {
//     final map = <String, dynamic>{};
//     map['PINFL'] = _pinfl;
//     map['CarNumber'] = _carNumber;
//     map['TIN'] = _tin;
//     map['phoneNumber'] = _phoneNumber;
//     map['CardType'] = _cardType;
//     map['qrPaymentProvider'] = _qrPaymentProvider;
//     map['qrPaymentID'] = _qrPaymentID;
//
//     return map;
//   }
// }
class ExtraInfo {
  ExtraInfo({
    String? pinfl,
    String? carNumber,
    String? tin,
    String? phoneNumber,
    num? cardType,
    String? qrPaymentID,
    int? qrPaymentProvider,
    String? cardNumber,          // Yangi
    String? pptId,               // Yangi (RRN o'rniga)
    num? cashedOutFromCard,      // Yangi
  }) {
    _pinfl = pinfl;
    _carNumber = carNumber;
    _tin = tin;
    _phoneNumber = phoneNumber;
    _cardType = cardType;
    _qrPaymentID = qrPaymentID;
    _qrPaymentProvider = qrPaymentProvider;
    _cardNumber = cardNumber;          // Yangi
    _pptId = pptId;                    // Yangi
    _cashedOutFromCard = cashedOutFromCard; // Yangi
  }

  ExtraInfo.fromJson(dynamic json) {
    _pinfl = json['PINFL'];
    _carNumber = json['CarNumber'];
    _tin = json['TIN'];
    _phoneNumber = json['PhoneNumber'];
    _cardType = json['CardType'];
    _qrPaymentID = json['QRPaymentID'];
    _qrPaymentProvider = json['QRPaymentProvider'];
    _cardNumber = json['CardNumber'];           // Yangi
    _pptId = json['PPTID'];                     // Yangi
    _cashedOutFromCard = json['CashedOutFromCard']; // Yangi
  }

  String? _pinfl;
  String? _carNumber;
  String? _tin;
  String? _phoneNumber;
  num? _cardType;
  String? _qrPaymentID;
  int? _qrPaymentProvider;
  String? _cardNumber;           // Yangi
  String? _pptId;                // Yangi
  num? _cashedOutFromCard;       // Yangi

  ExtraInfo copyWith({
    String? pinfl,
    String? carNumber,
    String? tin,
    String? phoneNumber,
    num? cardType,
    String? qrPaymentID,
    int? qrPaymentProvider,
    String? cardNumber,          // Yangi
    String? pptId,               // Yangi
    num? cashedOutFromCard,      // Yangi
  }) =>
      ExtraInfo(
        pinfl: pinfl ?? _pinfl,
        carNumber: carNumber ?? _carNumber,
        tin: tin ?? _tin,
        phoneNumber: phoneNumber ?? _phoneNumber,
        cardType: cardType ?? _cardType,
        qrPaymentID: qrPaymentID ?? _qrPaymentID,
        qrPaymentProvider: qrPaymentProvider ?? _qrPaymentProvider,
        cardNumber: cardNumber ?? _cardNumber,           // Yangi
        pptId: pptId ?? _pptId,                         // Yangi
        cashedOutFromCard: cashedOutFromCard ?? _cashedOutFromCard, // Yangi
      );

  // Getters
  String? get pinfl => _pinfl;
  String? get carNumber => _carNumber;
  String? get tin => _tin;
  String? get phoneNumber => _phoneNumber;
  num? get cardType => _cardType;
  String? get qrPaymentID => _qrPaymentID;
  int? get qrPaymentProvider => _qrPaymentProvider;
  String? get cardNumber => _cardNumber;           // Yangi
  String? get pptId => _pptId;                     // Yangi
  num? get cashedOutFromCard => _cashedOutFromCard; // Yangi

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['PINFL'] = _pinfl;
    map['CarNumber'] = _carNumber;
    map['TIN'] = _tin;
    map['PhoneNumber'] = _phoneNumber;        // to'g'rilangan (oldingi xato edi)
    map['CardType'] = _cardType;
    map['QRPaymentID'] = _qrPaymentID;        // to'g'rilangan
    map['QRPaymentProvider'] = _qrPaymentProvider;
    map['CardNumber'] = _cardNumber;          // Yangi
    map['PPTID'] = _pptId;                    // Yangi
    map['CashedOutFromCard'] = _cashedOutFromCard; // Yangi
    return map;
  }
}
/// TerminalID : "VG300750000021"
/// ReceiptSeq : "108"
/// DateTime : "20220527151528"
/// FiscalSign : "696533213005"

FiscalRefundInfo refundInfoFromJson(String str) =>
    FiscalRefundInfo.fromJson(json.decode(str));

String refundInfoToJson(FiscalRefundInfo data) => json.encode(data.toJson());

class FiscalRefundInfo {
  FiscalRefundInfo({
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

  FiscalRefundInfo.fromJson(dynamic json) {
    _terminalID = json['TerminalID'];
    _receiptSeq = json['ReceiptSeq'];
    _dateTime = json['DateTime'];
    _fiscalSign = json['FiscalSign'];
  }

  String? _terminalID;
  String? _receiptSeq;
  String? _dateTime;
  String? _fiscalSign;

  FiscalRefundInfo copyWith({
    String? terminalID,
    String? receiptSeq,
    String? dateTime,
    String? fiscalSign,
  }) =>
      FiscalRefundInfo(
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
