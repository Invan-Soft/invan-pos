// Katalog (kategoriya/mahsulot) bo'ylab navigatsiya.
//
// OrderingProvider4 dan ajratildi (2026-08-05) — tanalar o'zgartirilmadi.
// Bu zona savat va to'lov holatiga UMUMAN bog'liq emas: faqat ko'rsatilayotgan
// ro'yxat (`_items`) va yo'l (`_pathList`) bilan ishlaydi, ma'lumotni
// CategorySingleton / ItemsSingleton statik ro'yxatlaridan oladi.
//
// MUHIM — bu sinf ATAYLAB `ChangeNotifier` EMAS.
// Agar u o'z listenerlariga ega bo'lsa, `OrderingProvider4` ni tinglayotgan
// UI qayta chizilmay qolardi (jimgina, ko'rinmasdan buziladigan xato).
// Shuning uchun konstruktorda `notify` callback oladi va unga provider'ning
// `notifyListeners` i uzatiladi.
//
// Testlar: test/catalog_navigation_test.dart

import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_categories/model/category.dart';
import 'package:invan2/features/get_categories/singleton/category_singleton.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/bottom_buttons/local_category/model/local_category_model.dart';

class CatalogNavigationController {
  CatalogNavigationController(this._notify);

  /// Provider'ning `notifyListeners` i. 2-qoidaga qarang.
  final void Function() _notify;

  List<dynamic> _items = CategorySingleton.topCategories;
  List<CategoryData> _pathList = [];

  List<dynamic> get getItems {
    List<CategoryData> categoryList =
        HiveBoxes.getCategories().values.toList().cast<CategoryData>();

    List<dynamic> list = [];

    List<CategoryData> categoryListForLength = [];
    for (var element in _items) {
      if (element is CategoryData) {
        categoryListForLength.add(element);
      } else {
        break;
      }
    }
    for (var element in _items) {
      if (element is LocalCategoryItemModel) {
        if (element.isCategory) {
          final category = CategorySingleton.getCategoryById(element.id);
          list.add(category);
        } else {
          final product = ItemsSingleton.getProductById(element.id);
          list.add(product);
        }
      } else if (element is CategoryData) {
        if (element.parentId == null || element.parentId!.isEmpty) {
          if (categoryListForLength.length == 1) {
            if (element.id != null &&
                element.id!.isEmpty &&
                categoryList.length < 2 &&
                _items.length == 1) {
              list.add(element);
            }
            for (CategoryData c in categoryList) {
              if (element.id != null &&
                  element.id!.isNotEmpty &&
                  element.id == c.parentId) {
                list.add(c);
              }
            }
          } else if (categoryListForLength.length > 1) {
            for (CategoryData c in categoryList) {
              if (c.id == element.id) {
                list.add(c);
              }
            }
          }
        } else {
          if (categoryListForLength.length == 1) {
            for (CategoryData c in categoryList) {
              if (element.id != null &&
                  element.id!.isNotEmpty &&
                  element.id == c.parentId) {
                list.add(c);
              }
            }
          }
        }
      } else if (element is ItemModel) {
        list.add(element);
      } else {
        list.add(null);
      }
    }

    return list;
  }

  List<CategoryData> get getPathList => _pathList;

  void pressCategory(CategoryData categoryData) {
    _collectItemsByCategory(categoryData.id!);
    _pathList.add(categoryData);
    _notify();
  }

  void pressSubCategory(SubCategoryModel subModel) {
    _collectItemsBySubCategory(subModel.id!);
    CategoryData categoryData = CategoryData(
      id: subModel.id,
      children: [],
      name: subModel.name,
    );
    _pathList.add(categoryData);
    _notify();
  }

  void pressPath(CategoryData categoryData) {
    _collectItemsByCategory(categoryData.id!);
    _pathList = _pathList.sublist(0, _pathList.indexOf(categoryData) + 1);
    _notify();
  }

  void pressAllPath() {
    _items = <dynamic>[];
    _items.addAll(CategorySingleton.topCategories);
    _pathList = [];
    _notify();
  }

  void clearPathList() {
    _pathList = [];
    _notify();
  }

  void changeGridviewItems(List<dynamic>? items) {
    if (items != null) {
      _items = items;
      _notify();
    } else {
      pressAllPath();
    }
  }

  void _collectItemsByCategory(String categoryId) {
    _items = <dynamic>[];

    _items.addAll(
      CategorySingleton.collectCategoryByParentCategory(categoryId),
    );
    _items.addAll(
      ItemsSingleton.collectProductsByCategory(categoryId),
    );
  }

  void _collectItemsBySubCategory(String subCategoryId) {
    _items = <dynamic>[];
    _items.addAll(
      ItemsSingleton.collectProductsBySubategory(subCategoryId),
    );
  }
}
