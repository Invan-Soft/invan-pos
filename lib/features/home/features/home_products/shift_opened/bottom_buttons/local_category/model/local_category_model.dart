import 'package:hive/hive.dart';

part 'local_category_model.g.dart';

@HiveType(typeId: 10)
class LocalCategoryModel extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<LocalCategoryItemModel?> list;

  LocalCategoryModel({
    required this.name,
    required this.list,
  });
}

@HiveType(typeId: 22)
class LocalCategoryItemModel {
  @HiveField(0)
  String id;

  @HiveField(1)
  bool isCategory;

  LocalCategoryItemModel({
    required this.id,
    required this.isCategory,
  });
}
