import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:invan2/fiscal_service/fiscal.dart';
import '../returnedItems/returned_items.dart';

part 'last_receipt_model.g.dart';

LastReceiptModel resultFromJson(String str) =>
    LastReceiptModel.fromJson(json.decode(str));

String resultToJson(LastReceiptModel data) => json.encode(data.toJson());

@HiveType(
  typeId: 41,
  adapterName: "LastReceiptModelAdapter",
)
class LastReceiptModel extends HiveObject {
  @HiveField(0)
  String? _appletVersion;

  @HiveField(1)
  String? _qRCodeURL;

  @HiveField(2)
  String? _terminalID;

  @HiveField(3)
  String? _receiptSeq;

  @HiveField(4)
  String? _dateTime;

  @HiveField(5)
  String? _fiscalSign;

  @HiveField(6)
  bool _isSent = false;

  @HiveField(7)
  int? _dateMills;
  @HiveField(8)
  List<ReturnedItem>? _returnedItem;

  LastReceiptModel({
    String? appletVersion,
    String? qRCodeURL,
    String? terminalID,
    String? receiptSeq,
    String? dateTime,
    String? fiscalSign,
    bool isSent = false,
    int? dateMills,
    List<ReturnedItem>? returnedItem,
  }) {
    _appletVersion = appletVersion;
    _qRCodeURL = qRCodeURL;
    _terminalID = terminalID;
    _receiptSeq = receiptSeq;
    _dateTime = dateTime;
    _fiscalSign = fiscalSign;
    _dateMills = dateMills;
    _isSent = isSent;
    _returnedItem = returnedItem;
  }

  LastReceiptModel.fromJson(dynamic json) {
    _appletVersion = json['AppletVersion'];
    _qRCodeURL = json['QRCodeURL'];
    _terminalID = json['TerminalID'];
    _receiptSeq = json['ReceiptSeq'];
    _dateTime = json['DateTime'];
    _fiscalSign = json['FiscalSign'];
    _isSent = json['isSent'] ?? false;
    _dateMills = AppFormatter.formatDateFromStringToMills(json['DateTime']);
    _returnedItem = json['returnedItem'] != null
        ? List<ReturnedItem>.from(
            json["returnedItem"].map((x) => ReturnedItem.fromJson(x)))
        : null;
  }

  LastReceiptModel copyWith({
    String? appletVersion,
    String? qRCodeURL,
    String? terminalID,
    String? receiptSeq,
    String? dateTime,
    String? fiscalSign,
    bool isSent = false,
    int? dateMills,
    List<ReturnedItem>? returnedItem,
  }) =>
      LastReceiptModel(
        appletVersion: appletVersion ?? _appletVersion,
        qRCodeURL: qRCodeURL ?? _qRCodeURL,
        terminalID: terminalID ?? _terminalID,
        receiptSeq: receiptSeq ?? _receiptSeq,
        dateTime: dateTime ?? _dateTime,
        fiscalSign: fiscalSign ?? _fiscalSign,
        isSent: isSent,
        dateMills: dateMills ?? _dateMills,
        returnedItem: returnedItem ?? _returnedItem,
      );

  String? get appletVersion => _appletVersion;

  String get qRCodeURL => _qRCodeURL ?? "";

  String get terminalID => _terminalID ?? "";

  String get receiptSeq => _receiptSeq ?? "";

  String get dateTime => _dateTime ?? "";

  String get fiscalSign => _fiscalSign ?? "";

  int get dateMills => _dateMills ?? 0;

  bool get isSent => _isSent;

  set setIsSent(bool isSent) => _isSent = isSent;

  List<ReturnedItem>? get isreturnedItem => _returnedItem;
  set setreturnedItem(List<ReturnedItem> isreturnedItem) =>
      _returnedItem = isreturnedItem;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['appletVersion'] = _appletVersion;
    map['qrCodeURL'] = _qRCodeURL;
    map['terminalId'] = _terminalID;
    map['receiptSeq'] = _receiptSeq;
    map['dateTime'] = _dateTime;
    map['fiscalSign'] = _fiscalSign;
    map['returnedItem'] = _returnedItem;

    return map;
  }

  Map<String, dynamic> toHive() {
    final map = <String, dynamic>{};
    map['AppletVersion'] = _appletVersion;
    map['QRCodeURL'] = _qRCodeURL;
    map['TerminalId'] = _terminalID;
    map['ReceiptSeq'] = _receiptSeq;
    map['DateTime'] = _dateTime;
    map['FiscalSign'] = _fiscalSign;
    return map;
  }

  Map<String, dynamic> toApi() {
    final map = <String, dynamic>{};
    map['applet_version'] = _appletVersion;
    map['qr_code_url'] = _qRCodeURL;
    map['terminal_id'] = _terminalID;
    map['receipt_seq'] = _receiptSeq;
    map['date_time'] = _dateTime;
    map['fiscal_sign'] = _fiscalSign;
    map['date_mls'] = _dateMills;
    return map;
  }
}
