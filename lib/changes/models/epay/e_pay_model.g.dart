// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'e_pay_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EPayModelAdapter extends TypeAdapter<EPayModel> {
  @override
  final int typeId = 38;

  @override
  EPayModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EPayModel(
      type: fields[5] as EPayEnum,
    )
      .._serviceId = fields[0] as String?
      .._merchantId = fields[1] as String?
      .._merchantUserId = fields[2] as String?
      .._secretKey = fields[3] as String?
      .._password = fields[4] as String?
      .._enabled = fields[6] as bool?;
  }

  @override
  void write(BinaryWriter writer, EPayModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj._serviceId)
      ..writeByte(1)
      ..write(obj._merchantId)
      ..writeByte(2)
      ..write(obj._merchantUserId)
      ..writeByte(3)
      ..write(obj._secretKey)
      ..writeByte(4)
      ..write(obj._password)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj._enabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EPayModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class EPayEnumAdapter extends TypeAdapter<EPayEnum> {
  @override
  final int typeId = 39;

  @override
  EPayEnum read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EPayEnum.click;
      case 1:
        return EPayEnum.payme;
      case 2:
        return EPayEnum.uzum;
      case 3:
        return EPayEnum.humo;
      default:
        return EPayEnum.click;
    }
  }

  @override
  void write(BinaryWriter writer, EPayEnum obj) {
    switch (obj) {
      case EPayEnum.click:
        writer.writeByte(0);
        break;
      case EPayEnum.payme:
        writer.writeByte(1);
        break;
      case EPayEnum.uzum:
        writer.writeByte(2);
        break;
      case EPayEnum.humo:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EPayEnumAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
