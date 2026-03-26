// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'package:hive/hive.dart';

part 'e_pay_model.g.dart';

@HiveType(typeId: 38)
class  EPayModel extends HiveObject {
  @override
  get key => type.value;

  @HiveField(0)
  String? _serviceId;

  @HiveField(1)
  String? _merchantId;

  @HiveField(2)
  String? _merchantUserId;

  @HiveField(3)
  String? _secretKey;

  @HiveField(4)
  String? _password;

  @HiveField(5)
  final EPayEnum type;

  @HiveField(6)
  bool? _enabled;

  EPayModel({
    String? serviceId,
    String? merchantId,
    String? merchantUserId,
    String? secretKey,
    String? password,
    bool? enabled,
    required this.type,
  }) {
    _merchantId = merchantId;
    _merchantUserId = merchantUserId;
    _password = password;
    _secretKey = secretKey;
    _serviceId = serviceId;
    _enabled = enabled;
  }

  EPayModel copyWith({
    String? serviceId,
    String? merchantId,
    String? merchantUserId,
    String? secretKey,
    String? password,
    bool? enabled,
  }) {
    return EPayModel(
      serviceId: serviceId ?? _serviceId,
      merchantId: merchantId ?? _merchantId,
      merchantUserId: merchantUserId ?? _merchantUserId,
      secretKey: secretKey ?? _secretKey,
      password: password ?? _password,
      type: type,
      enabled: enabled ?? _enabled,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'type': type.value,
      'serviceId': _serviceId,
      'merchantId': _merchantId,
      'merchantUserId': _merchantUserId,
      'secretKey': _secretKey,
      'password': _password,
      'enabled': _enabled,
    };
  }

  String toJson() => json.encode(toMap());

  String get serviceId => _serviceId ?? "";
  String get merchantId => _merchantId ?? "";
  String get merchantUserId => _merchantUserId ?? "";
  String get secretKey => _secretKey ?? "";
  String get password => _password ?? "";
  bool get enabled => _enabled ?? false;

  set setEnabled(bool enable) => _enabled = enable;

  @override
  String toString() {
    const JsonEncoder encoder = JsonEncoder.withIndent("  ");
    return encoder.convert(toMap());
  }

  @override
  bool operator ==(covariant EPayModel other) {
    if (identical(this, other)) return true;

    return other._serviceId == _serviceId &&
        other._merchantId == _merchantId &&
        other._merchantUserId == _merchantUserId &&
        other._secretKey == _secretKey &&
        other._password == _password &&
        other.type == type &&
        other._enabled == _enabled;
  }

  @override
  int get hashCode {
    return _serviceId.hashCode ^
        _merchantId.hashCode ^
        _merchantUserId.hashCode ^
        _secretKey.hashCode ^
        _password.hashCode ^
        _enabled.hashCode ^
        type.hashCode;
  }
}

@HiveType(typeId: 39)
enum EPayEnum {
  @HiveField(0)
  click('click'),

  @HiveField(1)
  payme('payme'),

  @HiveField(2)
  uzum('uzum'),

  @HiveField(3)
  humo('humo');

  final String value;
  const EPayEnum(this.value);
}
