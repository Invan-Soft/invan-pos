/*
    @author Suxrob Sattorov, 11/12/2024, 5:09 PM
*/

import 'dart:convert';

import 'package:invan2/changes/models/product/item_model.dart';

import '../../../changes/services/api/result_http_model.dart';
import '../../features.dart';
import '../../hive_repository/hive_boxes.dart';

class CategoryService {
  static List<CategoryData> flatCategories = [];

  static void _flattenCategories(List<CategoryData> categories) {
    for (CategoryData category in categories) {
      if (!flatCategories.any((c) => c.id == category.id)) {
        flatCategories.add(
          CategoryData(
            id: category.id,
            name: category.name,
            parentId: category.parentId,
            children: [],
          ),
        );
      }
      if (category.children != null && category.children!.isNotEmpty) {
        _flattenCategories(category.children!);
      }
    }
  }

  static void _flattenCategoriesCreate(List<CategoryData> categories) {
    for (CategoryData category in categories) {
      if (!flatCategories.any((c) => c.id == category.id)) {
        flatCategories.add(
          CategoryData(
            id: category.id,
            name: category.name,
            parentId: category.parentId,
            children: [],
          ),
        );
      }
    }
  }

  static Future<String?> category() async {
    List<CategoryData> categories = [];
    flatCategories = [];
    String? error;
    HttpResult httpResult = await CategoriesApi.categoryFind();
    if (httpResult.isSuccess) {
      if (httpResult.statusCode == 200) {
        categories = List<CategoryData>.from(
          httpResult.result['data'].map(
            (e) => CategoryData.fromJson(e),
          ),
        ).toList();

        _flattenCategories(categories);
        CategoryData noneCategory = CategoryData(
          children: [],
          parentId: "",
          id: "",
          name: "None",
        );
        _flattenCategories([noneCategory]);
        if (flatCategories.isNotEmpty) {
          final box = HiveBoxes.getCategories();
          await box.clear();
          await box.addAll(flatCategories);
        }
      } else {
        throw Exception(
            'Failed to load categories. Status code: ${httpResult.statusCode}');
      }
    } else {
      error = httpResult.getError;
    }
    return error;
  }

  static Future<String?> categoriesCreateForWebSocket(
      List<CategoryData> categoryList) async {
    final box = HiveBoxes.getCategories();
    flatCategories = [];
    String? error;
    if (categoryList.isNotEmpty) {
      _flattenCategoriesCreate(categoryList);
      if (flatCategories.isNotEmpty) {
        await box.addAll(flatCategories);
      }
    } else {
      error = 'Category list empty';
    }
    return error;
  }

  static Future<String?> categoriesUpdateForWebSocket(
      CategoryData? categoryData) async {
    String? error;
    if (categoryData != null) {
      final box = HiveBoxes.getCategories();
      List<CategoryData> categoryListLocal = box.values.toList();
      bool isUpdated = false;
      for (int i = 0; i < categoryListLocal.length; i++) {
        if (categoryListLocal[i].id == categoryData.id) {
          box.putAt(
            i,
            CategoryData(
              id: categoryData.id,
              name: categoryData.name,
              parentId: categoryData.parentId,
              children: [],
            ),
          );
          isUpdated = true;
          break;
        }
      }
      if (!isUpdated) {
        flatCategories = [];
        _flattenCategoriesCreate([categoryData]);
        if (flatCategories.isNotEmpty) {
          await box.addAll(flatCategories);
        }
      }
    } else {
      error = 'Category list empty';
    }
    return error;
  }

  static Future<String?> categoriesDeleteForWebSocket(String categoryId) async {
    String? error;
    if (categoryId.isNotEmpty) {
      bool isDeleted = false;
      final box = HiveBoxes.getCategories();
      final itemBox = HiveBoxes.getProducts();
      List<CategoryData> categoryList = box.values.toList();
      List<ItemModel> itemList = itemBox.values.toList();
      for (int i = 0; i < categoryList.length; i++) {
        if (categoryList[i].id == categoryId) {
          box.deleteAt(i);
          isDeleted = true;
        }
      }
      if (isDeleted) {
        for (int i = 0; i < itemList.length; i++) {
          if (itemList[i].categories != null &&
              itemList[i].categories!.isNotEmpty) {
            if (itemList[i].categories![0].id == categoryId) {
              itemList[i].categories = null;
              itemBox.putAt(i, itemList[i]);
            }
          }
        }
      }
    } else {
      error = 'Category list empty';
    }
    return error;
  }
}
