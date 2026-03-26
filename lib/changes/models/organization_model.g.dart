// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OrganizationModelAdapter extends TypeAdapter<OrganizationModel> {
  @override
  final int typeId = 35;

  @override
  OrganizationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OrganizationModel(
      ibt: fields[0] as String?,
      id: fields[1] as String?,
      legalAddress: fields[2] as String?,
      legalName: fields[3] as String?,
      name: fields[4] as String?,
      taxPayerId: fields[5] as String?,
      zipCode: fields[6] as String?,
      autoGenerate: fields[7] as bool?,
      soliqValidation: fields[8] as bool?,
      companyActive: fields[9] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, OrganizationModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.ibt)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.legalAddress)
      ..writeByte(3)
      ..write(obj.legalName)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.taxPayerId)
      ..writeByte(6)
      ..write(obj.zipCode)
      ..writeByte(7)
      ..write(obj.autoGenerate)
      ..writeByte(8)
      ..write(obj.soliqValidation)
      ..writeByte(9)
      ..write(obj.companyActive);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PaymentAdapter extends TypeAdapter<Payment> {
  @override
  final int typeId = 37;

  @override
  Payment read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Payment(
      name: fields[0] as String?,
      id: fields[4] as String?,
      title: fields[1] as String?,
      enable: fields[2] as bool?,
      isAdded: fields[3] as bool?,
      merchantId: fields[5] as String?,
      merchantUserId: fields[6] as String?,
      password: fields[9] as String?,
      secretKey: fields[7] as String?,
      serviceId: fields[8] as int?,
      type: fields[10] as int?,
      value: fields[11] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, Payment obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.enable)
      ..writeByte(3)
      ..write(obj.isAdded)
      ..writeByte(4)
      ..write(obj.id)
      ..writeByte(5)
      ..write(obj.merchantId)
      ..writeByte(6)
      ..write(obj.merchantUserId)
      ..writeByte(7)
      ..write(obj.secretKey)
      ..writeByte(8)
      ..write(obj.serviceId)
      ..writeByte(9)
      ..write(obj.password)
      ..writeByte(10)
      ..write(obj.type)
      ..writeByte(11)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
