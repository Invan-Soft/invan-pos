// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mes_unit.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VatUnitModelAdapter extends TypeAdapter<VatUnitModel> {
  @override
  final int typeId = 114;

  @override
  VatUnitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VatUnitModel(
      id: fields[0] as String?,
      isDefault: fields[1] as bool?,
      name: fields[2] as String?,
      percentage: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, VatUnitModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isDefault)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.percentage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VatUnitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MesUnitModelAdapter extends TypeAdapter<MesUnitModel> {
  @override
  final int typeId = 115;

  @override
  MesUnitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MesUnitModel(
      id: fields[0] as String?,
      shortName: fields[1] as String?,
      longName: fields[2] as String?,
      percentage: fields[3] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, MesUnitModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shortName)
      ..writeByte(2)
      ..write(obj.longName)
      ..writeByte(3)
      ..write(obj.percentage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MesUnitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
