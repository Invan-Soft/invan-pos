// ignore_for_file: unnecessary_this, unnecessary_getters_setters

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/services/app_constants.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/helpers.dart';

part 'log_model.g.dart';

@HiveType(typeId: 27)
class LogModel extends HiveObject {
  @HiveField(0)
  DateTime? _dateTime;
  @HiveField(1)
  bool? _isSent;
  @HiveField(2)
  String? _message;
  @HiveField(3)
  String? _url;
  @HiveField(4)
  String? _path;
  @HiveField(5)
  String? _method;
  @HiveField(6)
  int? _statusCode;
  @HiveField(7)
  String? _phone;
  @HiveField(8)
  String? _phoneModel;
  @HiveField(9)
  String? _userName;
  @HiveField(10)
  String? _version;
  @HiveField(11)
  bool? _type;
  @HiveField(12)
  String? _file;
  @HiveField(13)
  String? _body;
  @HiveField(14)
  String? _createdDate;
  @HiveField(15)
  String? _checkNo;

  LogModel({
    DateTime? dateTime,
    bool? isSent,
    String? message,
    String? url,
    String? path,
    String? method,
    int? statusCode,
    String? phone,
    String? phoneModel,
    String? userName,
    String? version,
    bool? type,
    String? file,
    String? body,
    String? createdDate,
    String? checkNo,
  }) {
    if (dateTime != null) {
      this._dateTime = dateTime;
    }
    if (isSent != null) {
      this._isSent = isSent;
    }
    if (message != null) {
      this._message = message;
    }
    if (url != null) {
      this._url = url;
    }
    if (path != null) {
      this._path = path;
    }
    if (method != null) {
      this._method = method;
    }
    if (statusCode != null) {
      this._statusCode = statusCode;
    }

    if (phone != null) {
      this._phone = phone;
    }
    if (phoneModel != null) {
      this._phoneModel = phoneModel;
    }
    if (userName != null) {
      this._userName = userName;
    }
    if (version != null) {
      this._version = version;
    }
    if (type != null) {
      this._type = type;
    }
    if (file != null) {
      this._file = file;
    }
    if (body != null) {
      this._body = body;
    }
    if (createdDate != null) {
      this._createdDate = createdDate;
    }
    if (checkNo != null) {
      this._checkNo = checkNo;
    }
  }

  DateTime? get dateTime => _dateTime;

  set dateTime(DateTime? dateTime) => _dateTime = dateTime;

  bool? get isSent => _isSent;

  set isSent(bool? isSent) => _isSent = isSent;

  String? get message => _message;

  set message(String? message) => _message = message;

  String? get url => _url;

  set url(String? url) => _url = url;

  String? get path => _path;

  set path(String? path) => _path = path;

  String? get method => _method;

  set method(String? method) => _method = method;

  int? get statusCode => _statusCode;

  set statusCode(int? statusCode) => _statusCode = statusCode;

  String? get phone => _phone;

  set phone(String? phone) => _phone = phone;

  String? get phoneModel => _phoneModel;

  set phoneModel(String? phoneModel) => _phoneModel = phoneModel;

  String? get userName => _userName;

  set userName(String? userName) => _userName = userName;

  String? get version => _version;

  set version(String? version) => _version = version;

  bool? get type => _type;

  set type(bool? type) => _type = type;

  String? get file => _file;

  set file(String? file) => _file = file;

  String? get body => _body;

  set body(String? body) => _body = body;

  String? get createdDate => _createdDate;

  set createdDate(String? createdDate) => _createdDate = createdDate;

  String? get checkNo => _checkNo;

  set checkNo(String? checkNo) => _checkNo = checkNo;

  LogModel.fromJson(Map<String, dynamic> json) {
    _dateTime = json['date_time'];
    _isSent = json['is_sent'];
    _message = json['message'];
    _url = json['url'];
    _path = json['path'];
    _method = json['method'];
    _statusCode = json['status_code'];
    _phone = json['phone'];
    _phoneModel = json['phone_model'];
    _userName = json['user_name'];
    _version = json['version'];
    _type = json['type'];
    _file = json['file'];
    _body = json['body'];
    _createdDate = json['created_date'];
    _checkNo = json['check_no'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['date_time'] = this._dateTime!.toIso8601String();
    data['is_sent'] = this._isSent;
    data['message'] = this._message;
    data['url'] = this._url;
    data['path'] = this._path;
    data['method'] = this._method;
    data['status_code'] = this._statusCode;
    data['phone'] = this._phone;
    data['phone_model'] = this._phoneModel;
    data['user_name'] = this._userName;
    data['version'] = this._version;
    data['type'] = this._type;
    data['file'] = this._file;
    data['body'] = this._body;
    data['created_date'] = this._createdDate;
    data['check_no'] = this._checkNo;
    return data;
  }

  String logToTxt({required int i, required LogModel log}) {
    // 📞🧨🕒📱

    const String mode = kDebugMode ? 'debug' : 'release';
    final String posName = Pref.getString(PrefKeys.posName, "");
    final String orgName = Pref.getString(PrefKeys.organizationName, "");

    final String logString = """
$i)   🕒${log.dateTime}

Employee....=> ${log.userName}
URL.........=> ${log.url}
Path........=> ${log.path}
Method......=> ${log.method}
Status Code.=> ${log.statusCode}
File........=> ${log.file}
Error.......=> ${log.message!}
Device......=> ${log.phone}
Pos Name....=> $posName
Org Name....=> $orgName
Type........=> "{log.type! ? "Success":"Fail"}"
Version ${AppConstants.version} $mode
==========================================================
""";
    return logString;
  }
}
