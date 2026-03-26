import 'dart:convert';

import 'package:invan2/changes/models/ofd/incom_response_model.dart';

class CommunicatorRESPONSE {
  CommunicatorRESPONSE({
    this.mxikError,
    this.error,
    this.paycheck,
    this.info,
    this.itemInfo,
    this.method,
  });
  MxikError? mxikError;
  bool? error;
  String? paycheck;
  Info? info;
  List<ItemInfo>? itemInfo;
  String? method;

  factory CommunicatorRESPONSE.fromJson(Map<dynamic, dynamic> json) =>
      CommunicatorRESPONSE(
        error: json["error"],
        paycheck: json["paycheck"],
        method: json["method"],
        info: json["info"] != null ? Info.fromJson(json["info"]) : null,
        itemInfo: List<ItemInfo>.from(
          json['items'].map(
            (model) => ItemInfo.fromJson(jsonDecode(jsonEncode(model))),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
        "error": error,
        "paycheck": paycheck,
        "method": method,
        "info": info == null ? "null" : info!.toJson(),
        "items": itemInfo?.first.toJson(),
      };
}

class Info {
  Info({
    this.qrCodeUrl,
    this.terminalId,
    this.receiptSeq,
    this.dateTime,
    this.fiscalSign,
  });
  String? id;
  String? qrCodeUrl;
  String? terminalId;
  String? receiptSeq;
  String? dateTime;
  String? fiscalSign;

  factory Info.fromJson(Map<dynamic, dynamic> json) {
    return Info(
      qrCodeUrl: json["qrCodeURL"],
      terminalId: json["terminalId"],
      receiptSeq: json["receiptSeq"],
      dateTime: json["dateTime"],
      fiscalSign: json["fiscalSign"],
    );
  }
  Map<String, dynamic> toJson() => {
        "qrCodeURL": qrCodeUrl,
        "terminalId": terminalId,
        "receiptSeq": receiptSeq,
        "dateTime": dateTime,
        "fiscalSign": fiscalSign,
      };
}

class ItemInfo {
  ItemInfo({
    this.id,
    this.barcode,
    this.mxikCode,
    this.packageCode,
    this.packageName,
  });
  String? id;
  String? barcode;
  String? mxikCode;
  String? packageCode;
  String? packageName;

  factory ItemInfo.fromJson(Map<dynamic, dynamic> json) {
    return ItemInfo(
      id: json["id"],
      barcode: json["barcode"],
      mxikCode: json["mxikCode"],
      packageCode: json["packageCode"],
      packageName: json["packageName"],
    );
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "barcode": barcode,
        "mxikCode": mxikCode,
        "packageCode": packageCode,
        "packageName": packageName,
      };
}
