// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_category_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LocalCategoryModelAdapter extends TypeAdapter<LocalCategoryModel> {
  @override
  final int typeId = 10;

  @override
  LocalCategoryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalCategoryModel(
      name: fields[0] as String,
      list: (fields[1] as List).cast<LocalCategoryItemModel?>(),
    );
  }

  @override
  void write(BinaryWriter writer, LocalCategoryModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.list);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalCategoryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class LocalCategoryItemModelAdapter
    extends TypeAdapter<LocalCategoryItemModel> {
  @override
  final int typeId = 22;

  @override
  LocalCategoryItemModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LocalCategoryItemModel(
      id: fields[0] as String,
      isCategory: fields[1] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, LocalCategoryItemModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.isCategory);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocalCategoryItemModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
