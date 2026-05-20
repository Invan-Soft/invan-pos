import 'dart:convert';

/// TerminalID : "VG300750000021"
/// AppletVersion : "0322"
/// CurrentReceiptSeq : "114"
/// CurrentTime : "2022-05-27 15:27:12"
/// ReceiptCount : 0
/// ReceiptMaxCount : 600
/// ZReportCount : 7
/// ZReportMaxCount : 800
/// AvailablePersistentMemory : 32767
/// AvailableResetMemory : 3530
/// AvailableDeselectMemory : 3530

FiscalInfoModel fiscalInfoModelFromJson(String str) =>
    FiscalInfoModel.fromJson(json.decode(str));

String fiscalInfoModelToJson(FiscalInfoModel data) =>
    json.encode(data.toJson());

class FiscalInfoModel {
  FiscalInfoModel({
    String? terminalID,
    String? appletVersion,
    String? currentReceiptSeq,
    String? currentTime,
    int? receiptCount,
    int? receiptMaxCount,
    int? zReportCount,
    int? zReportMaxCount,
    int? availablePersistentMemory,
    int? availableResetMemory,
    int? availableDeselectMemory,
  }) {
    _terminalID = terminalID;
    _appletVersion = appletVersion;
    _currentReceiptSeq = currentReceiptSeq;
    _currentTime = currentTime;
    _receiptCount = receiptCount;
    _receiptMaxCount = receiptMaxCount;
    _zReportCount = zReportCount;
    _zReportMaxCount = zReportMaxCount;
    _availablePersistentMemory = availablePersistentMemory;
    _availableResetMemory = availableResetMemory;
    _availableDeselectMemory = availableDeselectMemory;
  }

  FiscalInfoModel.fromJson(dynamic json) {
    _terminalID = json['TerminalID'];
    _appletVersion = json['AppletVersion'];
    _currentReceiptSeq = json['CurrentReceiptSeq'];
    _currentTime = json['CurrentTime'];
    _receiptCount = json['ReceiptCount'];
    _receiptMaxCount = json['ReceiptMaxCount'];
    _zReportCount = json['ZReportCount'];
    _zReportMaxCount = json['ZReportMaxCount'];
    _availablePersistentMemory = json['AvailablePersistentMemory'];
    _availableResetMemory = json['AvailableResetMemory'];
    _availableDeselectMemory = json['AvailableDeselectMemory'];
  }

  String? _terminalID;
  String? _appletVersion;
  String? _currentReceiptSeq;
  String? _currentTime;
  int? _receiptCount;
  int? _receiptMaxCount;
  int? _zReportCount;
  int? _zReportMaxCount;
  int? _availablePersistentMemory;
  int? _availableResetMemory;
  int? _availableDeselectMemory;

  FiscalInfoModel copyWith({
    String? terminalID,
    String? appletVersion,
    String? currentReceiptSeq,
    String? currentTime,
    int? receiptCount,
    int? receiptMaxCount,
    int? zReportCount,
    int? zReportMaxCount,
    int? availablePersistentMemory,
    int? availableResetMemory,
    int? availableDeselectMemory,
  }) =>
      FiscalInfoModel(
        terminalID: terminalID ?? _terminalID,
        appletVersion: appletVersion ?? _appletVersion,
        currentReceiptSeq: currentReceiptSeq ?? _currentReceiptSeq,
        currentTime: currentTime ?? _currentTime,
        receiptCount: receiptCount ?? _receiptCount,
        receiptMaxCount: receiptMaxCount ?? _receiptMaxCount,
        zReportCount: zReportCount ?? _zReportCount,
        zReportMaxCount: zReportMaxCount ?? _zReportMaxCount,
        availablePersistentMemory:
            availablePersistentMemory ?? _availablePersistentMemory,
        availableResetMemory: availableResetMemory ?? _availableResetMemory,
        availableDeselectMemory:
            availableDeselectMemory ?? _availableDeselectMemory,
      );

  String get terminalID => _terminalID ?? "";

  String? get appletVersion => _appletVersion;

  String get currentReceiptSeq => _currentReceiptSeq ?? "";

  String get currentTime => _currentTime ?? "";

  int? get receiptCount => _receiptCount;

  int? get receiptMaxCount => _receiptMaxCount;

  int? get zReportCount => _zReportCount;

  int? get zReportMaxCount => _zReportMaxCount;

  int? get availablePersistentMemory => _availablePersistentMemory;

  int? get availableResetMemory => _availableResetMemory;

  int? get availableDeselectMemory => _availableDeselectMemory;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['TerminalID'] = _terminalID;
    map['AppletVersion'] = _appletVersion;
    map['CurrentReceiptSeq'] = _currentReceiptSeq;
    map['CurrentTime'] = _currentTime;
    map['ReceiptCount'] = _receiptCount;
    map['ReceiptMaxCount'] = _receiptMaxCount;
    map['ZReportCount'] = _zReportCount;
    map['ZReportMaxCount'] = _zReportMaxCount;
    map['AvailablePersistentMemory'] = _availablePersistentMemory;
    map['AvailableResetMemory'] = _availableResetMemory;
    map['AvailableDeselectMemory'] = _availableDeselectMemory;
    return map;
  }
}
