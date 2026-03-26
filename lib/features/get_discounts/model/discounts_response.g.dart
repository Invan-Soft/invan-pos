// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discounts_response.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DiscountsResponseAdapter extends TypeAdapter<DiscountsResponse> {
  @override
  final int typeId = 116;

  @override
  DiscountsResponse read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscountsResponse(
      data: (fields[0] as List?)?.cast<DiscountItem>(),
      total: fields[1] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, DiscountsResponse obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.data)
      ..writeByte(1)
      ..write(obj.total);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscountsResponseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscountItemAdapter extends TypeAdapter<DiscountItem> {
  @override
  final int typeId = 117;

  @override
  DiscountItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscountItem(
      id: fields[11] as String?,
      name: fields[0] as String?,
      displayName: fields[1] as String?,
      discountType: fields[2] as DiscountType?,
      discountGroupType: fields[3] as DiscountGroupType?,
      discountValue: fields[4] as int?,
      isExpirable: fields[5] as bool?,
      startDate: fields[6] as String?,
      expireDate: fields[7] as String?,
      isAllProducts: fields[8] as bool?,
      productIds: (fields[9] as List?)?.cast<ProductIds>(),
      categoryIds: (fields[10] as List?)?.cast<CategoryIds>(),
      discountSchedules: (fields[12] as List?)?.cast<DiscountSchedules>(),
      isWholeDay: fields[13] as bool?,
      customerGroups: (fields[14] as List?)?.cast<CustomerGroups>(),
      shopIds: (fields[15] as List?)?.cast<ShopIds>(),
      buyXGetY: fields[16] as BuyXGetY?,
      isRepeatable: fields[17] as bool?,
      isForAllClients: fields[18] as bool?,
      gifts: (fields[19] as List?)?.cast<Gifts>(),
      buyXGetX: fields[20] as BuyXGetX?,
    );
  }

  @override
  void write(BinaryWriter writer, DiscountItem obj) {
    writer
      ..writeByte(21)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.displayName)
      ..writeByte(2)
      ..write(obj.discountType)
      ..writeByte(3)
      ..write(obj.discountGroupType)
      ..writeByte(4)
      ..write(obj.discountValue)
      ..writeByte(5)
      ..write(obj.isExpirable)
      ..writeByte(6)
      ..write(obj.startDate)
      ..writeByte(7)
      ..write(obj.expireDate)
      ..writeByte(8)
      ..write(obj.isAllProducts)
      ..writeByte(9)
      ..write(obj.productIds)
      ..writeByte(10)
      ..write(obj.categoryIds)
      ..writeByte(11)
      ..write(obj.id)
      ..writeByte(12)
      ..write(obj.discountSchedules)
      ..writeByte(13)
      ..write(obj.isWholeDay)
      ..writeByte(14)
      ..write(obj.customerGroups)
      ..writeByte(15)
      ..write(obj.shopIds)
      ..writeByte(16)
      ..write(obj.buyXGetY)
      ..writeByte(17)
      ..write(obj.isRepeatable)
      ..writeByte(18)
      ..write(obj.isForAllClients)
      ..writeByte(19)
      ..write(obj.gifts)
      ..writeByte(20)
      ..write(obj.buyXGetX);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscountItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscountTypeAdapter extends TypeAdapter<DiscountType> {
  @override
  final int typeId = 118;

  @override
  DiscountType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscountType(
      id: fields[0] as String?,
      label: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DiscountType obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscountTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscountGroupTypeAdapter extends TypeAdapter<DiscountGroupType> {
  @override
  final int typeId = 119;

  @override
  DiscountGroupType read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscountGroupType(
      id: fields[0] as String?,
      label: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DiscountGroupType obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscountGroupTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DiscountSchedulesAdapter extends TypeAdapter<DiscountSchedules> {
  @override
  final int typeId = 120;

  @override
  DiscountSchedules read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiscountSchedules(
      dayOfWeek: fields[0] as int?,
      startTime: fields[1] as String?,
      endTime: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DiscountSchedules obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dayOfWeek)
      ..writeByte(1)
      ..write(obj.startTime)
      ..writeByte(2)
      ..write(obj.endTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscountSchedulesAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductIdsAdapter extends TypeAdapter<ProductIds> {
  @override
  final int typeId = 121;

  @override
  ProductIds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductIds(
      id: fields[0] as String?,
      name: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductIds obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductIdsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CategoryIdsAdapter extends TypeAdapter<CategoryIds> {
  @override
  final int typeId = 122;

  @override
  CategoryIds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CategoryIds(
      id: fields[0] as String?,
      name: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CategoryIds obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryIdsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class CustomerGroupsAdapter extends TypeAdapter<CustomerGroups> {
  @override
  final int typeId = 125;

  @override
  CustomerGroups read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CustomerGroups(
      id: fields[0] as String?,
      name: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CustomerGroups obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomerGroupsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ShopIdsAdapter extends TypeAdapter<ShopIds> {
  @override
  final int typeId = 124;

  @override
  ShopIds read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ShopIds(
      id: fields[0] as String?,
      name: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ShopIds obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShopIdsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BuyXGetYAdapter extends TypeAdapter<BuyXGetY> {
  @override
  final int typeId = 126;

  @override
  BuyXGetY read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BuyXGetY(
      productsToBuy: (fields[0] as List?)?.cast<ProductsToBuy>(),
      buyProductsAmount: fields[1] as num?,
      productToGet: fields[2] as ProductsToGet?,
      getProductsAmount: fields[3] as num?,
    );
  }

  @override
  void write(BinaryWriter writer, BuyXGetY obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.productsToBuy)
      ..writeByte(1)
      ..write(obj.buyProductsAmount)
      ..writeByte(2)
      ..write(obj.productToGet)
      ..writeByte(3)
      ..write(obj.getProductsAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuyXGetYAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BuyXGetXAdapter extends TypeAdapter<BuyXGetX> {
  @override
  final int typeId = 130;

  @override
  BuyXGetX read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BuyXGetX(
      productsToBuy: (fields[0] as List?)?.cast<ProductsToBuy>(),
      buyProductsAmount: fields[1] as num?,
      getProductsAmount: fields[2] as num?,
    );
  }

  @override
  void write(BinaryWriter writer, BuyXGetX obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.productsToBuy)
      ..writeByte(1)
      ..write(obj.buyProductsAmount)
      ..writeByte(2)
      ..write(obj.getProductsAmount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BuyXGetXAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductsToBuyAdapter extends TypeAdapter<ProductsToBuy> {
  @override
  final int typeId = 127;

  @override
  ProductsToBuy read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductsToBuy(
      id: fields[0] as String?,
      name: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductsToBuy obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductsToBuyAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ProductsToGetAdapter extends TypeAdapter<ProductsToGet> {
  @override
  final int typeId = 128;

  @override
  ProductsToGet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ProductsToGet(
      id: fields[0] as String?,
      name: fields[1] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ProductsToGet obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductsToGetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GiftsAdapter extends TypeAdapter<Gifts> {
  @override
  final int typeId = 129;

  @override
  Gifts read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Gifts(
      getProductAmount: fields[0] as int?,
      buyAmount: fields[1] as int?,
      getProduct: fields[2] as ProductIds?,
    );
  }

  @override
  void write(BinaryWriter writer, Gifts obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.getProductAmount)
      ..writeByte(1)
      ..write(obj.buyAmount)
      ..writeByte(2)
      ..write(obj.getProduct);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GiftsAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
