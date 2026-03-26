import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:hive/hive.dart';
import 'package:invan2/features/features.dart';

// ignore: depend_on_referenced_packages
import 'package:collection/collection.dart';
import 'package:invan2/features/get_categories/service/category_service.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:provider/provider.dart';

class CategorySingleton {
  static List<CategoryData> categories = [];
  static List<CategoryData> topCategories = [];

  static void init() {
    categories = HiveBoxes.getCategories().values.toList().cast<CategoryData>();
    topCategories = categories;
  }

  static void flattenCategories(List<CategoryData> categories) {
    for (CategoryData category in categories) {
      if (!topCategories.any((c) => c.id == category.id)) {
        topCategories.add(category);
      }
      if (category.children != null && category.children!.isNotEmpty) {
        flattenCategories(category.children!);
      }
    }
  }

  static List<CategoryData> collectCategoryByParentCategory(
    String categoryId,
  ) {
    return categories.where((e) => e.id == categoryId).toList();
  }

  static CategoryData? getCategoryById(String id) {
    return categories.firstWhereOrNull((e) => e.id == id);
  }

  static Future<void> deleteCategories(String categoryId) async {
    await CategoryService.categoriesDeleteForWebSocket(categoryId);
    return;
  }

  static Future<void> putCategories(List<CategoryData> categoryList) async {
    await CategoryService.categoriesCreateForWebSocket(categoryList);
  }

  static Future<void> editCategory(CategoryData? categoryData) async {
    await CategoryService.categoriesUpdateForWebSocket(categoryData);
  }

  static clearAndPut(List<CategoryData> v) async {
    CategoryData noneCategory = CategoryData(
      children: [],
      id: "",
      name: "None",
    );
    v.add(noneCategory);
    final box = HiveBoxes.getCategories();
    await box.clear();
    await box.addAll(v);
  }
}
