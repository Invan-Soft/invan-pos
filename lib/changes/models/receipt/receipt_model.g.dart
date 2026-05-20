// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'receipt_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReceiptModelAdapter extends TypeAdapter<ReceiptModel> {
  @override
  final int typeId = 24;

  @override
  ReceiptModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReceiptModel()
      .._token = fields[0] as String?
      .._method = fields[1] as String?
      .._companyName = fields[2] as String?
      .._companyAddress = fields[3] as String?
      .._companyINN = fields[4] as String?
      .._staffName = fields[5] as String?
      .._printerSize = fields[6] as int?
      .._params = fields[7] as Params?;
  }

  @override
  void write(BinaryWriter writer, ReceiptModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj._token)
      ..writeByte(1)
      ..write(obj._method)
      ..writeByte(2)
      ..write(obj._companyName)
      ..writeByte(3)
      ..write(obj._companyAddress)
      ..writeByte(4)
      ..write(obj._companyINN)
      ..writeByte(5)
      ..write(obj._staffName)
      ..writeByte(6)
      ..write(obj._printerSize)
      ..writeByte(7)
      ..write(obj._params);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReceiptModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ParamsAdapter extends TypeAdapter<Params> {
  @override
  final int typeId = 25;

  @override
  Params read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Params()
      .._discountCard = fields[0] as DiscountCard?
      .._paycheckNumber = fields[1] as String?
      .._items = (fields[2] as List?)?.cast<ItemModel>()
      .._receivedCash = fields[3] as int?
      .._receivedCard = fields[4] as int?;
  }

  @override
  void write(BinaryWriter writer, Params obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj._discountCard)
      ..writeByte(1)
      ..write(obj._paycheckNumber)
      ..writeByte(2)
      ..write(obj._items)
      ..writeByte(3)
      ..write(obj._receivedCash)
      ..writeByte(4)
      ..write(obj._receivedCard);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParamsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscountCardAdapter extends TypeAdapter<DiscountCard> {
  @override
  final int typeId = 26;

  @override
  DiscountCard read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscountCard()
      .._available = fields[0] as int?
      .._addition = fields[1] as int?
      .._subtraction = fields[2] as int?
      .._remainder = fields[3] as int?;
  }

  @override
  void write(BinaryWriter writer, DiscountCard obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj._available)
      ..writeByte(1)
      ..write(obj._addition)
      ..writeByte(2)
      ..write(obj._subtraction)
      ..writeByte(3)
      ..write(obj._remainder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscountCardAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
