import 'dart:convert';
import '../../fiscal.dart';

ErrorModel errorFromJson(String str) => ErrorModel.fromJson(json.decode(str));

String errorToJson(ErrorModel data) => json.encode(data.toJson());

class ErrorModel {
  ErrorModel({
    int? code,
    String? message,
    String? data,
  }) {
    _code = code;
    _message = message;
    _data = data;
  }

  ErrorModel.fromJson(dynamic json) {
    _code = json['code'];
    _message = json['message'];
    _data = json['data'];
  }

  int? _code;
  String? _message;
  String? _data;

  ErrorModel copyWith({
    int? code,
    String? message,
    String? data,
  }) =>
      ErrorModel(
        code: code ?? _code,
        message: message ?? _message,
        data: data ?? _data,
      );

  int? get code => _code;

  String? get message => _message;

  String? get data => _data;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['code'] = _code;
    map['message'] = _message;
    map['data'] = _data;
    return map;
  }

  String toMessage() {
    switch (_code) {
      case 65274:
        return ApiErrorResponses.netwokError;

      case 65275:
        return ApiErrorResponses.badRefundInfoPassed;

      case 65276:
        return ApiErrorResponses.noRefundinfoPassed;

      case 65277:
        return ApiErrorResponses.notValidRefund;

      case 65278:
        return ApiErrorResponses.fiscalDriveFailure;

      case 65279:
        return ApiErrorResponses.fiscalDriceLocked;

      case 65524:
        return ApiErrorResponses.cannotReadEncyptedZReport;

      case 65525:
        return ApiErrorResponses.unsupportedAppletVersion;

      case 65528:
        return ApiErrorResponses.cannotSaveReceiptInStorage;

      case 65529:
        return ApiErrorResponses.cannotReadEncryptedRecaipt;

      case 65531:
        return ApiErrorResponses.cannotEncodeReceipt;

      case 65532:
        return ApiErrorResponses.illegalArgument;

      case 65533:
        return ApiErrorResponses.cannotSelectApplet;

      case 65534:
        return ApiErrorResponses.cannotConnectCard;

      case 65535:
        return ApiErrorResponses.cannotConnectCard;

      default:
        return message.toString();
    }
  }
}
