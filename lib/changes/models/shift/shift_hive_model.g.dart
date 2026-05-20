// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ShiftModelHiveAdapter extends TypeAdapter<ShiftModelHive> {
  @override
  final int typeId = 30;

  @override
  ShiftModelHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShiftModelHive(
      isClosed: fields[20] as bool?,
      isWithOFD: fields[18] as bool?,
      cashDrawerHive: fields[0] as CashDrawerHive?,
      salesSummary: fields[1] as SalesSummaryHive?,
      byWhomName: fields[2] as String?,
      byWhomNameClose: fields[3] as String?,
      closingTime: fields[4] as int?,
      currency: fields[5] as String?,
      pays: (fields[6] as List?)?.cast<PaysHive>(),
      sId: fields[7] as String?,
      posId: fields[8] as String?,
      openingTime: fields[9] as int?,
      organization: fields[10] as String?,
      service: fields[11] as String?,
      pos: fields[12] as String?,
      byWhom: fields[13] as String?,
      createdAt: fields[14] as String?,
      updatedAt: fields[15] as String?,
      iV: fields[16] as int?,
      isUploaded: fields[17] as bool?,
      shiftId: fields[19] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShiftModelHive obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.cashDrawerHive)
      ..writeByte(1)
      ..write(obj.salesSummary)
      ..writeByte(2)
      ..write(obj.byWhomName)
      ..writeByte(3)
      ..write(obj.byWhomNameClose)
      ..writeByte(4)
      ..write(obj.closingTime)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.pays)
      ..writeByte(7)
      ..write(obj.sId)
      ..writeByte(8)
      ..write(obj.posId)
      ..writeByte(9)
      ..write(obj.openingTime)
      ..writeByte(10)
      ..write(obj.organization)
      ..writeByte(11)
      ..write(obj.service)
      ..writeByte(12)
      ..write(obj.pos)
      ..writeByte(13)
      ..write(obj.byWhom)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.iV)
      ..writeByte(17)
      ..write(obj.isUploaded)
      ..writeByte(18)
      ..write(obj.isWithOFD)
      ..writeByte(19)
      ..write(obj.shiftId)
      ..writeByte(20)
      ..write(obj.isClosed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShiftModelHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CashDrawerHiveAdapter extends TypeAdapter<CashDrawerHive> {
  @override
  final int typeId = 31;

  @override
  CashDrawerHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CashDrawerHive(
      startingCash: fields[0] as num?,
      cashPayment: fields[1] as num?,
      inkassa: fields[2] as num?,
      cashRefund: fields[3] as num?,
      paidIn: fields[4] as num?,
      paidOut: fields[5] as num?,
      expCashAmount: fields[6] as num?,
      actCashAmount: fields[7] as num?,
      withdrawal: fields[8] as num?,
      difference: fields[9] as num?,
    );
  }

  @override
  void write(BinaryWriter writer, CashDrawerHive obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.startingCash)
      ..writeByte(1)
      ..write(obj.cashPayment)
      ..writeByte(2)
      ..write(obj.inkassa)
      ..writeByte(3)
      ..write(obj.cashRefund)
      ..writeByte(4)
      ..write(obj.paidIn)
      ..writeByte(5)
      ..write(obj.paidOut)
      ..writeByte(6)
      ..write(obj.expCashAmount)
      ..writeByte(7)
      ..write(obj.actCashAmount)
      ..writeByte(8)
      ..write(obj.withdrawal)
      ..writeByte(9)
      ..write(obj.difference);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CashDrawerHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SalesSummaryHiveAdapter extends TypeAdapter<SalesSummaryHive> {
  @override
  final int typeId = 32;

  @override
  SalesSummaryHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SalesSummaryHive(
      grossSales: fields[0] as num?,
      refunds: fields[1] as num?,
      discounts: fields[2] as num?,
      netSales: fields[3] as num?,
      cash: fields[4] as num?,
      card: fields[5] as num?,
      click: fields[10] as num?,
      payme: fields[11] as num?,
      uzum: fields[12] as num?,
      clickQr: fields[13] as num?,
      paymeQr: fields[14] as num?,
      uzumQr: fields[15] as num?,
      debt: fields[6] as num?,
      taxes: fields[7] as num?,
      cashbackIn: fields[8] as num?,
      cashbackOut: fields[9] as num?,
      uzCard: fields[16] as num?,
      humoCard: fields[17] as num?,
      other: fields[18] as num?,
    );
  }

  @override
  void write(BinaryWriter writer, SalesSummaryHive obj) {
    writer
      ..writeByte(19)
      ..writeByte(0)
      ..write(obj.grossSales)
      ..writeByte(1)
      ..write(obj.refunds)
      ..writeByte(2)
      ..write(obj.discounts)
      ..writeByte(3)
      ..write(obj.netSales)
      ..writeByte(4)
      ..write(obj.cash)
      ..writeByte(5)
      ..write(obj.card)
      ..writeByte(6)
      ..write(obj.debt)
      ..writeByte(7)
      ..write(obj.taxes)
      ..writeByte(8)
      ..write(obj.cashbackIn)
      ..writeByte(9)
      ..write(obj.cashbackOut)
      ..writeByte(10)
      ..write(obj.click)
      ..writeByte(11)
      ..write(obj.payme)
      ..writeByte(12)
      ..write(obj.uzum)
      ..writeByte(13)
      ..write(obj.clickQr)
      ..writeByte(14)
      ..write(obj.paymeQr)
      ..writeByte(15)
      ..write(obj.uzumQr)
      ..writeByte(16)
      ..write(obj.uzCard)
      ..writeByte(17)
      ..write(obj.humoCard)
      ..writeByte(18)
      ..write(obj.other);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SalesSummaryHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaysHiveAdapter extends TypeAdapter<PaysHive> {
  @override
  final int typeId = 33;

  @override
  PaysHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PaysHive(
      time: fields[0] as int?,
      name: fields[1] as String?,
      createdShiftId: fields[2] as String?,
      shiftId: fields[3] as String?,
      comment: fields[4] as String?,
      value: fields[5] as num?,
      who: fields[6] as String?,
      type: (fields[7] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PaysHive obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.time)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.createdShiftId)
      ..writeByte(3)
      ..write(obj.shiftId)
      ..writeByte(4)
      ..write(obj.comment)
      ..writeByte(5)
      ..write(obj.value)
      ..writeByte(6)
      ..write(obj.who)
      ..writeByte(7)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaysHiveAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
