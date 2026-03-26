// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'last_receipt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LastReceiptModelAdapter extends TypeAdapter<LastReceiptModel> {
  @override
  final int typeId = 41;

  @override
  LastReceiptModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LastReceiptModel()
      .._appletVersion = fields[0] as String?
      .._qRCodeURL = fields[1] as String?
      .._terminalID = fields[2] as String?
      .._receiptSeq = fields[3] as String?
      .._dateTime = fields[4] as String?
      .._fiscalSign = fields[5] as String?
      .._isSent = fields[6] as bool
      .._dateMills = fields[7] as int?
      .._returnedItem = (fields[8] as List?)?.cast<ReturnedItem>();
  }

  @override
  void write(BinaryWriter writer, LastReceiptModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj._appletVersion)
      ..writeByte(1)
      ..write(obj._qRCodeURL)
      ..writeByte(2)
      ..write(obj._terminalID)
      ..writeByte(3)
      ..write(obj._receiptSeq)
      ..writeByte(4)
      ..write(obj._dateTime)
      ..writeByte(5)
      ..write(obj._fiscalSign)
      ..writeByte(6)
      ..write(obj._isSent)
      ..writeByte(7)
      ..write(obj._dateMills)
      ..writeByte(8)
      ..write(obj._returnedItem);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastReceiptModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
