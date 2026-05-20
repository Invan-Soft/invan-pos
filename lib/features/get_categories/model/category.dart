import 'package:hive/hive.dart';

import '../../hive_repository/hive_types.dart';

part 'category.g.dart';

class Category {
  int? statusCode;
  String? error;
  String? message;
  List<CategoryData>? data;

  Category({
    this.statusCode,
    this.error,
    this.message,
    this.data,
  });

  Category.fromJson(Map<String, dynamic> json) {
    statusCode = json['statusCode'];
    error = json['error'];
    message = json['message'];
    if (json['data'] != null) {
      data = [];
      json['data'].forEach((v) {
        data!.add(CategoryData.fromJson(v));
      });
    }
  }
}

// @HiveType(typeId: 9)
// class CategoryData extends HiveObject {
//   @HiveField(0)
//   String? type;

//   @HiveField(1)
//   bool? itemTree;

//   @HiveField(2)
//   String? position;

//   @HiveField(3)
//   List<dynamic>? parentCategories;

//   @HiveField(4)
//   String? color;

//   @HiveField(5)
//   bool? isOther;

//   @HiveField(6)
//   int? count;

//   @HiveField(7)
//   bool? showOnBot;

//   @HiveField(8)
//   List<dynamic>? showOnBotServices;

//   @HiveField(9)
//   String? presentType;

//   @HiveField(10)
//   String? sId;

//   @HiveField(11)
//   String? organization;

//   @HiveField(12)
//   String? section;

//   @HiveField(13)
//   String? sectionId;

//   @HiveField(14)
//   String? name;

//   @HiveField(15)
//   int? iV;

//   @HiveField(16)
//   String? image;

//   CategoryData({
//     this.type,
//     this.itemTree,
//     this.position,
//     this.parentCategories,
//     this.color,
//     this.isOther,
//     this.count,
//     this.showOnBot,
//     this.showOnBotServices,
//     this.presentType,
//     this.sId,
//     this.organization,
//     this.section,
//     this.sectionId,
//     this.name,
//     this.iV,
//     this.image,
//   });

//   CategoryData.fromJson(Map<String, dynamic> json) {
//     type = json['type'];
//     itemTree = json['item_tree'];
//     position = json['position'];
//     if (json['parent_categories'] != null) {
//       parentCategories = [];
//       // json['parent_categories'].forEach((v) {
//       //   parentCategories.add( Null.fromJson(v));
//       // });
//     }
//     color = json['color'];
//     isOther = json['is_other'];
//     count = json['count'];
//     showOnBot = json['show_on_bot'];
//     if (json['show_on_bot_services'] != null) {
//       showOnBotServices = [];
//       // json['show_on_bot_services'].forEach((v) {
//       //   showOnBotServices.add( Null.fromJson(v));
//       // });
//     }
//     presentType = json['present_type'];
//     sId = json['_id'];
//     organization = json['organization'];
//     section = json['section'];
//     sectionId = json['section_id'];
//     name = json['name'];
//     iV = json['__v'];
//     image = json['image'];
//   }
// }

///===========================================================================///

@HiveType(typeId: 9)
class CategoryData extends HiveObject {
  @override
  get key => id;
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? parentId;
  @HiveField(3)
  List<CategoryData>? children;

  CategoryData({this.id, this.name, this.parentId, this.children});

  CategoryData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    parentId = json['parent_id'];
    if (json['children'] != null) {
      children = <CategoryData>[];
      json['children'].forEach((v) {
        children!.add(CategoryData.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['parent_id'] = parentId;
    if (children != null) {
      data['children'] = children!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

@HiveType(typeId: HiveTypes.subCategoryModel)
class SubCategoryModel extends HiveObject {
  @override
  get key => id;
  @HiveField(0)
  String? id;
  @HiveField(1)
  String? name;
  @HiveField(2)
  String? parentId;

  SubCategoryModel({this.id, this.name, this.parentId});

  SubCategoryModel.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    parentId = json['parent_id'];
  }

  SubCategoryModel.fromJsonForWebSocket(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
    parentId = json['parent_id'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['id'] = id;
    data['name'] = name;
    data['parent_id'] = parentId;
    return data;
  }
}
