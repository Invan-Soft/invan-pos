/*
    @author Suxrob Sattorov, 11/12/2024, 5:09 PM
*/


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
          // Avval yangilari yoziladi, keyin eskilar o'chiriladi — clear+addAll
          // o'rtasida ilova o'lsa kategoriyalar bo'sh qolmasin.
          final List<dynamic> oldKeys = box.keys.toList();
          await box.addAll(flatCategories);
          if (oldKeys.isNotEmpty) await box.deleteAll(oldKeys);
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

  /// Notification (type 10): kategoriya yaratish — id bo'yicha UPSERT.
  ///
  /// Ilgari `box.addAll` edi: sinxron oynalari 2 daqiqa overlap bilan
  /// qayta so'ralgani uchun bir xil kategoriya ikki-uch marta qo'shilib
  /// ketardi (gridda dublikat, keyin update faqat birinchisini o'zgartirardi).
  static Future<String?> categoriesCreateForWebSocket(
      List<CategoryData> categoryList) async {
    if (categoryList.isEmpty) return 'Category list empty';
    flatCategories = [];
    _flattenCategoriesCreate(categoryList);
    await upsertCategories(flatCategories);
    return null;
  }

  /// Notification (type 11): yangilash; lokalda bo'lmasa yaratiladi.
  static Future<String?> categoriesUpdateForWebSocket(
      CategoryData? categoryData) async {
    if (categoryData == null) return 'Category list empty';
    flatCategories = [];
    _flattenCategoriesCreate([categoryData]);
    if (flatCategories.isEmpty) {
      flatCategories = [
        CategoryData(
          id: categoryData.id,
          name: categoryData.name,
          parentId: categoryData.parentId,
          children: [],
        ),
      ];
    }
    await upsertCategories(flatCategories);
    return null;
  }

  /// Har bir kategoriya id bo'yicha bitta yozuv: bor bo'lsa ustidan
  /// yoziladi (dublikatlar ham yig'ishtiriladi), yo'q bo'lsa qo'shiladi.
  static Future<void> upsertCategories(List<CategoryData> list) async {
    final box = HiveBoxes.getCategories();
    for (final CategoryData c in list) {
      final String? id = c.id;
      final CategoryData row = CategoryData(
        id: id,
        name: c.name,
        parentId: c.parentId,
        children: [],
      );
      final List<dynamic> keys = id == null
          ? const <dynamic>[]
          : box.keys.where((k) => box.get(k)?.id == id).toList();
      if (keys.isEmpty) {
        await box.add(row);
      } else {
        await box.put(keys.first, row);
        if (keys.length > 1) await box.deleteAll(keys.skip(1).toList());
      }
    }
  }

  /// Notification (type 12): o'chirish. Yozuvlar kalit bo'yicha o'chiriladi
  /// (ilgari snapshot indeksi bilan `deleteAt` va `await`siz — ikkinchi
  /// dublikatda noto'g'ri qator o'chib, xato esa yutilardi).
  static Future<String?> categoriesDeleteForWebSocket(String categoryId) async {
    if (categoryId.isEmpty) return 'Category list empty';
    final box = HiveBoxes.getCategories();
    final List<dynamic> keys =
        box.keys.where((k) => box.get(k)?.id == categoryId).toList();
    if (keys.isEmpty) return null;
    await box.deleteAll(keys);

    final itemBox = HiveBoxes.getProducts();
    for (final ItemModel item in itemBox.values.toList()) {
      final List<CategoriesFromProducts>? cats = item.categories;
      if (cats != null && cats.isNotEmpty && cats[0].id == categoryId) {
        item.categories = null;
        await itemBox.put(item.id, item);
      }
    }
    return null;
  }
}
