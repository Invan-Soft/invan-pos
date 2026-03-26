import 'dart:convert';
/// TerminalID : "VG300750000021"
/// AppletVersion : "0322"
/// CurrentReceiptSeq : "114"
/// CurrentTime : "2022-05-27 15:27:12"
/// AccumulatedSaleCash : 132852147
/// AccumulatedRefundCash : 380000
/// AccumulatedSaleCard : 300981506
/// AccumulatedRefundCard : 0
/// AccumulatedSaleVAT : 13377164
/// AccumulatedRefundVAT : 222009

FiscalMemoryModel fiscalMemoryModelFromJson(String str) => FiscalMemoryModel.fromJson(json.decode(str));
String fiscalMemoryModelToJson(FiscalMemoryModel data) => json.encode(data.toJson());
class FiscalMemoryModel {
  FiscalMemoryModel({
      String? terminalID, 
      String? appletVersion, 
      String? currentReceiptSeq, 
      String? currentTime, 
      int? accumulatedSaleCash, 
      int? accumulatedRefundCash, 
      int? accumulatedSaleCard, 
      int? accumulatedRefundCard, 
      int? accumulatedSaleVAT, 
      int? accumulatedRefundVAT,}){
    _terminalID = terminalID;
    _appletVersion = appletVersion;
    _currentReceiptSeq = currentReceiptSeq;
    _currentTime = currentTime;
    _accumulatedSaleCash = accumulatedSaleCash;
    _accumulatedRefundCash = accumulatedRefundCash;
    _accumulatedSaleCard = accumulatedSaleCard;
    _accumulatedRefundCard = accumulatedRefundCard;
    _accumulatedSaleVAT = accumulatedSaleVAT;
    _accumulatedRefundVAT = accumulatedRefundVAT;
}

  FiscalMemoryModel.fromJson(dynamic json) {
    _terminalID = json['TerminalID'];
    _appletVersion = json['AppletVersion'];
    _currentReceiptSeq = json['CurrentReceiptSeq'];
    _currentTime = json['CurrentTime'];
    _accumulatedSaleCash = json['AccumulatedSaleCash'];
    _accumulatedRefundCash = json['AccumulatedRefundCash'];
    _accumulatedSaleCard = json['AccumulatedSaleCard'];
    _accumulatedRefundCard = json['AccumulatedRefundCard'];
    _accumulatedSaleVAT = json['AccumulatedSaleVAT'];
    _accumulatedRefundVAT = json['AccumulatedRefundVAT'];
  }
  String? _terminalID;
  String? _appletVersion;
  String? _currentReceiptSeq;
  String? _currentTime;
  int? _accumulatedSaleCash;
  int? _accumulatedRefundCash;
  int? _accumulatedSaleCard;
  int? _accumulatedRefundCard;
  int? _accumulatedSaleVAT;
  int? _accumulatedRefundVAT;
FiscalMemoryModel copyWith({  String? terminalID,
  String? appletVersion,
  String? currentReceiptSeq,
  String? currentTime,
  int? accumulatedSaleCash,
  int? accumulatedRefundCash,
  int? accumulatedSaleCard,
  int? accumulatedRefundCard,
  int? accumulatedSaleVAT,
  int? accumulatedRefundVAT,
}) => FiscalMemoryModel(  terminalID: terminalID ?? _terminalID,
  appletVersion: appletVersion ?? _appletVersion,
  currentReceiptSeq: currentReceiptSeq ?? _currentReceiptSeq,
  currentTime: currentTime ?? _currentTime,
  accumulatedSaleCash: accumulatedSaleCash ?? _accumulatedSaleCash,
  accumulatedRefundCash: accumulatedRefundCash ?? _accumulatedRefundCash,
  accumulatedSaleCard: accumulatedSaleCard ?? _accumulatedSaleCard,
  accumulatedRefundCard: accumulatedRefundCard ?? _accumulatedRefundCard,
  accumulatedSaleVAT: accumulatedSaleVAT ?? _accumulatedSaleVAT,
  accumulatedRefundVAT: accumulatedRefundVAT ?? _accumulatedRefundVAT,
);
  String? get terminalID => _terminalID;
  String? get appletVersion => _appletVersion;
  String? get currentReceiptSeq => _currentReceiptSeq;
  String? get currentTime => _currentTime;
  int? get accumulatedSaleCash => _accumulatedSaleCash;
  int? get accumulatedRefundCash => _accumulatedRefundCash;
  int? get accumulatedSaleCard => _accumulatedSaleCard;
  int? get accumulatedRefundCard => _accumulatedRefundCard;
  int? get accumulatedSaleVAT => _accumulatedSaleVAT;
  int? get accumulatedRefundVAT => _accumulatedRefundVAT;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['TerminalID'] = _terminalID;
    map['AppletVersion'] = _appletVersion;
    map['CurrentReceiptSeq'] = _currentReceiptSeq;
    map['CurrentTime'] = _currentTime;
    map['AccumulatedSaleCash'] = _accumulatedSaleCash;
    map['AccumulatedRefundCash'] = _accumulatedRefundCash;
    map['AccumulatedSaleCard'] = _accumulatedSaleCard;
    map['AccumulatedRefundCard'] = _accumulatedRefundCard;
    map['AccumulatedSaleVAT'] = _accumulatedSaleVAT;
    map['AccumulatedRefundVAT'] = _accumulatedRefundVAT;
    return map;
  }

}