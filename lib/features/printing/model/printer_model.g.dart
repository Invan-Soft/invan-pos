// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PrinterModelAdapter extends TypeAdapter<PrinterModel> {
  @override
  final int typeId = 5;

  @override
  PrinterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PrinterModel(
      name: fields[0] as String?,
      url: fields[1] as String?,
      model: fields[2] as String?,
      location: fields[3] as String?,
      comment: fields[4] as String?,
      paperSize: fields[5] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, PrinterModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.url)
      ..writeByte(2)
      ..write(obj.model)
      ..writeByte(3)
      ..write(obj.location)
      ..writeByte(4)
      ..write(obj.comment)
      ..writeByte(5)
      ..write(obj.paperSize);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrinterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
