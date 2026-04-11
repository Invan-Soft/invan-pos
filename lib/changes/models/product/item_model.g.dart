// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ItemModelAdapter extends TypeAdapter<ItemModel> {
  @override
  final int typeId = 23;

  @override
  ItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ItemModel(
      id: fields[0] as String?,
      sku: fields[1] as String?,
      name: fields[2] as String?,
      image: fields[3] as String?,
      isMarking: fields[4] as bool?,
      isActive: fields[5] as bool?,
      mxikCode: fields[6] as String?,
      parentId: fields[7] as String?,
      companyId: fields[8] as String?,
      description: fields[9] as String?,
      productTypeId: fields[10] as String?,
      shopPrices: fields[11] as ShopPrices?,
      categories: (fields[12] as List?)?.cast<CategoriesFromProducts>(),
      measurementUnit: fields[13] as MeasurementUnit?,
      vat: fields[14] as Vat?,
      packageCode: fields[15] as String?,
      packageType: fields[16] as String?,
      packageName: fields[17] as String?,
      commissionTin: fields[18] as String?,
      mark: fields[19] as String?,
      barcode: (fields[21] as List?)?.cast<String>(),
      ownerType: fields[20] as String?,
      boxBarcode: fields[22] as String?,
      boxBarcodeQuantity: fields[23] as num?,
      hasBoxBarcode: fields[24] as bool?,
      cashsale: fields[25] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, ItemModel obj) {
    writer
      ..writeByte(26)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.sku)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.image)
      ..writeByte(4)
      ..write(obj.isMarking)
      ..writeByte(5)
      ..write(obj.isActive)
      ..writeByte(6)
      ..write(obj.mxikCode)
      ..writeByte(7)
      ..write(obj.parentId)
      ..writeByte(8)
      ..write(obj.companyId)
      ..writeByte(9)
      ..write(obj.description)
      ..writeByte(10)
      ..write(obj.productTypeId)
      ..writeByte(11)
      ..write(obj.shopPrices)
      ..writeByte(12)
      ..write(obj.categories)
      ..writeByte(13)
      ..write(obj.measurementUnit)
      ..writeByte(14)
      ..write(obj.vat)
      ..writeByte(15)
      ..write(obj.packageCode)
      ..writeByte(16)
      ..write(obj.packageType)
      ..writeByte(17)
      ..write(obj.packageName)
      ..writeByte(18)
      ..write(obj.commissionTin)
      ..writeByte(19)
      ..write(obj.mark)
      ..writeByte(20)
      ..write(obj.ownerType)
      ..writeByte(21)
      ..write(obj.barcode)
      ..writeByte(22)
      ..write(obj.boxBarcode)
      ..writeByte(23)
      ..write(obj.boxBarcodeQuantity)
      ..writeByte(24)
      ..write(obj.hasBoxBarcode)
      ..writeByte(25)
      ..write(obj.cashsale);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShopPricesAdapter extends TypeAdapter<ShopPrices> {
  @override
  final int typeId = 109;

  @override
  ShopPrices read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopPrices(
      shID: fields[0] as ShID?,
    );
  }

  @override
  void write(BinaryWriter writer, ShopPrices obj) {
    writer
      ..writeByte(1)
      ..writeByte(0)
      ..write(obj.shID);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopPricesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShIDAdapter extends TypeAdapter<ShID> {
  @override
  final int typeId = 110;

  @override
  ShID read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShID(
      shopId: fields[0] as String?,
      supplyPrice: fields[1] as num?,
      shopPriceTiers: (fields[2] as List?)?.cast<ShopPriceTiers>(),
    );
  }

  @override
  void write(BinaryWriter writer, ShID obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.shopId)
      ..writeByte(1)
      ..write(obj.supplyPrice)
      ..writeByte(2)
      ..write(obj.shopPriceTiers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShIDAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShopPriceTiersAdapter extends TypeAdapter<ShopPriceTiers> {
  @override
  final int typeId = 123;

  @override
  ShopPriceTiers read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopPriceTiers(
      minQuantity: fields[0] as int?,
      retailPrice: fields[1] as num?,
    );
  }

  @override
  void write(BinaryWriter writer, ShopPriceTiers obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.minQuantity)
      ..writeByte(1)
      ..write(obj.retailPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopPriceTiersAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoriesFromProductsAdapter
    extends TypeAdapter<CategoriesFromProducts> {
  @override
  final int typeId = 111;

  @override
  CategoriesFromProducts read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoriesFromProducts(
      id: fields[0] as String?,
      name: fields[1] as String?,
      parentId: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoriesFromProducts obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.parentId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoriesFromProductsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class MeasurementUnitAdapter extends TypeAdapter<MeasurementUnit> {
  @override
  final int typeId = 112;

  @override
  MeasurementUnit read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MeasurementUnit(
      id: fields[0] as String?,
      shortName: fields[1] as String?,
      longName: fields[2] as String?,
      isDeletable: fields[3] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, MeasurementUnit obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.shortName)
      ..writeByte(2)
      ..write(obj.longName)
      ..writeByte(3)
      ..write(obj.isDeletable);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeasurementUnitAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class VatAdapter extends TypeAdapter<Vat> {
  @override
  final int typeId = 113;

  @override
  Vat read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vat(
      id: fields[0] as String?,
      name: fields[1] as String?,
      percentage: fields[2] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Vat obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.percentage);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VatAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
