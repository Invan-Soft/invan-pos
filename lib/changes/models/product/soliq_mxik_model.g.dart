// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'soliq_mxik_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SoliqMxikModelAdapter extends TypeAdapter<SoliqMxikModel> {
  @override
  final int typeId = 131;

  @override
  SoliqMxikModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SoliqMxikModel(
      mxik: fields[0] as String,
      mxikNameUz: fields[1] as String,
      mxikNameRu: fields[2] as String,
      mxikNameLat: fields[3] as String,
      internationalCode: fields[4] as String,
      usePackage: fields[5] as int,
      packages: (fields[6] as List).cast<dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, SoliqMxikModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.mxik)
      ..writeByte(1)
      ..write(obj.mxikNameUz)
      ..writeByte(2)
      ..write(obj.mxikNameRu)
      ..writeByte(3)
      ..write(obj.mxikNameLat)
      ..writeByte(4)
      ..write(obj.internationalCode)
      ..writeByte(5)
      ..write(obj.usePackage)
      ..writeByte(6)
      ..write(obj.packages);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SoliqMxikModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
