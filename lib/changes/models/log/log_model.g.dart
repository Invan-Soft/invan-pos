// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LogModelAdapter extends TypeAdapter<LogModel> {
  @override
  final int typeId = 27;

  @override
  LogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LogModel()
      .._dateTime = fields[0] as DateTime?
      .._isSent = fields[1] as bool?
      .._message = fields[2] as String?
      .._url = fields[3] as String?
      .._path = fields[4] as String?
      .._method = fields[5] as String?
      .._statusCode = fields[6] as int?
      .._phone = fields[7] as String?
      .._phoneModel = fields[8] as String?
      .._userName = fields[9] as String?
      .._version = fields[10] as String?
      .._type = fields[11] as bool?
      .._file = fields[12] as String?
      .._body = fields[13] as String?
      .._createdDate = fields[14] as String?
      .._checkNo = fields[15] as String?;
  }

  @override
  void write(BinaryWriter writer, LogModel obj) {
    writer
      ..writeByte(16)
      ..writeByte(0)
      ..write(obj._dateTime)
      ..writeByte(1)
      ..write(obj._isSent)
      ..writeByte(2)
      ..write(obj._message)
      ..writeByte(3)
      ..write(obj._url)
      ..writeByte(4)
      ..write(obj._path)
      ..writeByte(5)
      ..write(obj._method)
      ..writeByte(6)
      ..write(obj._statusCode)
      ..writeByte(7)
      ..write(obj._phone)
      ..writeByte(8)
      ..write(obj._phoneModel)
      ..writeByte(9)
      ..write(obj._userName)
      ..writeByte(10)
      ..write(obj._version)
      ..writeByte(11)
      ..write(obj._type)
      ..writeByte(12)
      ..write(obj._file)
      ..writeByte(13)
      ..write(obj._body)
      ..writeByte(14)
      ..write(obj._createdDate)
      ..writeByte(15)
      ..write(obj._checkNo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
