// ignore: depend_on_referenced_packages

import 'package:collection/collection.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invan2/changes/models/discount_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/mxik_updates.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import '../../../changes/components/tranlator.dart';
import '../../../changes/providers/ordering_provider_4.dart';
import '../../../changes/services/web_socket_service/product/model/product_price_edit_response.dart';
import '../../../utils/util_functions.dart';
import '../../../utils/utils.dart';

class ItemsSingleton {
  static List<ItemModel> products = [];
  static List<ItemModel> barcodeProducts = [];

  static clearTheProducts() {
    products = <ItemModel>[];
    barcodeProducts = <ItemModel>[];
  }

  static double getNDS(List<ReceiptModelSoldItem4> products) {
    double n = 0;
    for (var i in products) {
      if (!i.isDeleted!) {
        n += (i.price * i.value * i.vatPercent) / (100 + i.vatPercent);
      }
    }
    return n;
  }

  static double getTotalPrice(List<ReceiptModelSoldItem4> products) {
    double t = 0;
    for (var e in products) {
      if (!e.isDeleted!) {
        t += UtilFunctions.roundToNearest(e.price * e.value);
      }
    }
    return t;
  }

  static double getRealTotalPrice(List<ReceiptModelSoldItem4> products) {
    double t = 0;
    for (var e in products) {
      if (!e.isDeleted!) {
        if (e.isPriceOnlyChanged) {
          t += e.onlyPrice * e.value;
        } else {
          t += e.realPrice * e.value;
        }
      }
    }
    return t;
  }

  static double getOfdTotalPrice(List<ReceiptModelSoldItem4> products) {
    double t = 0;
    for (var e in products) {
      t += UtilFunctions.roundToNearest(e.price * e.value);
    }
    return t;
  }

  static DiscountModel discounter({
    required num howMuch,
    required num quantity,
    required DiscountFromWhere where,
  }) {
    return DiscountModel(
      idd: "custom_discount",
      name: where.name,
      total: howMuch > 0 ? (howMuch * quantity + 0) : 0,
      type: "sum",
      value: howMuch > 0 ? howMuch + 0 : 0,
    );
  }

  static num finalPrice(ItemModel product, int value, bool isKg,
      {bool? isFirst}) {
    double price = 0;
    int min = 0;
    int index = 0;

    if (isKg && value < 1) {
      value = 1;
    }
    if (product.shopPrices != null &&
        product.shopPrices!.shID != null &&
        product.shopPrices!.shID!.shopPriceTiers != null &&
        product.shopPrices!.shID!.shopPriceTiers!.isNotEmpty) {
      for (int i = 0;
          i < product.shopPrices!.shID!.shopPriceTiers!.length;
          i++) {
        if (value >=
                (product.shopPrices!.shID!.shopPriceTiers![i].minQuantity ??
                    0) &&
            (product.shopPrices!.shID!.shopPriceTiers![i].minQuantity ?? 0) >=
                min) {
          price =
              (product.shopPrices!.shID!.shopPriceTiers![i].retailPrice ?? 0)
                  .toDouble();
          min = (product.shopPrices!.shID!.shopPriceTiers![i].minQuantity ?? 0);
          index = i;
        }
      }
    }
    if (isKg && min >= 1) {
      price = product.shopPrices!.shID!.shopPriceTiers![index].retailPrice!
          .toDouble();
    }
    return price;
  }

  static num onePrice(ShopPrices? shopPrices) {
    double price = 0;
    if (shopPrices != null &&
        shopPrices.shID != null &&
        shopPrices.shID!.shopPriceTiers != null &&
        shopPrices.shID!.shopPriceTiers!.isNotEmpty) {
      price = (shopPrices.shID!.shopPriceTiers![0].retailPrice ?? 0).toDouble();
    }
    return price;
  }

  static double getBaseTotalPrice(
      List<ReceiptModelSoldItem4> products, bool isMinimumPricedClient) {
    double baseTotalPrice = 0;
    for (int i = 0; i < products.length; i++) {
      if (!products[i].isDeleted!) {
        ItemModel? item = getProductById(products[i].productId);
        if (item != null) {
          double price =
              finalPrice(item, products[i].value.toInt(), products[i].isKg)
                  .toDouble();

          baseTotalPrice +=
              UtilFunctions.roundToNearest(price * products[i].value);
        }
      }
    }
    return UtilFunctions.roundToNearest(baseTotalPrice);
  }

  static num getItemBasePrice(
      ReceiptModelSoldItem4 soldItem4, bool isMinimumPricedClient) {
    ItemModel? item = getProductById(soldItem4.productId);

    return item != null
        ? finalPrice(item, soldItem4.value.toInt(), soldItem4.isKg).toDouble()
        : 0;
  }

static Future<void> storeProducts() async {
  List<ItemModel> list =
      HiveBoxes.getProducts().values.cast<ItemModel>().toList();
  products = list.toList();
  barcodeProducts = list.where((element) {        
    double price = onePrice(element.shopPrices).toDouble();
    return element.barcode != null &&
        element.barcode!.isNotEmpty &&
        price > 0;
  }).toList();
}

  static ItemModel? getProductById(String soldItemProductId) {
    return products.firstWhereOrNull(
        (e) => e.id!.toLowerCase() == soldItemProductId.toLowerCase());
  }

  static List<ItemModel> collectProductsByCategory(String categoryId) {
    return products.where((e) {
      if (categoryId == "") {
        return e.categories?.lastOrNull?.id == null;
      } else {
        return e.categories?.lastOrNull?.id == categoryId;
      }
    }).toList();
  }

  static List<ItemModel> emptyCategoryIdByProduct(String categoryId) {
    return products.where((e) {
      if (categoryId == "") {
        return e.categories?.lastOrNull?.id == null;
      } else {
        return e.categories?.lastOrNull?.id == categoryId;
      }
    }).toList();
  }

  static List<ItemModel> collectProductsBySubategory(String subCategoryId) {
    return products.where((e) {
      return e.categories?.lastOrNull?.id == subCategoryId;
    }).toList();
  }

  static String extractBarcode(String input) {
    if (RegExp(r'^\d+\$').hasMatch(input)) {
      return input;
    }

    final match = RegExp(r'\d+').firstMatch(input);
    if (match != null) {
      return match.group(0)!.replaceFirst(RegExp(r'^0+'), '');
    }

    return "";
  }

  /*static List<ItemModel> getStaticProducts(int index) {
    List<String> skus = ['13874', '10977', '14271'];
    List<ItemModel> result = [];
    if (index == 1) {
      for (var sku in skus) {
        final matchedProducts = products.where((product) =>
            product.mxikCode != null &&
            product.mxikCode!.isNotEmpty &&
            product.packageCode != null &&
            product.packageCode!.isNotEmpty &&
            product.sku == sku);
        result.addAll(matchedProducts);
      }
    }
    return result;
  }*/

  static List<ItemModel> getDefaultProducts(int length) {
    return barcodeProducts
        .where((product) =>
            product.mxikCode != null &&
            product.mxikCode!.isNotEmpty &&
            product.packageCode != null &&
            product.packageCode!.isNotEmpty)
        .take(length)
        .toList();
  }

  
  static ItemModel? getProductByBarcode(String barcode) {
    if (barcode.isEmpty) return null;

    final trimmed = barcode.trim();

    // SKU bo'yicha qidirish (5 belgidan qisqa)
    if (trimmed.length <= 5) {
      var item = products.firstWhereOrNull((p) => p.sku == trimmed);
      if (item == null) {
        final skuInt = int.tryParse(trimmed);
        if (skuInt != null) {
          item = products.firstWhereOrNull((p) => p.sku == skuInt.toString());
        }
      }
      return item;
    }

    // Barcode bo'yicha qidirish
    return barcodeProducts.firstWhereOrNull((product) {
      if (product.hasBoxBarcode == true && product.boxBarcode == trimmed) {
        return true;
      }
      return product.barcode?.any((b) => b == trimmed) ?? false;
    });
  }

  static ItemModel? getProductByBoxBarcode(String pattern) {
    return barcodeProducts.firstWhereOrNull(
      (product) => product.barcode == pattern,
    );
  }

  static ItemModel? getProductByBoxBarcodeOnly(String gtin) {
    return barcodeProducts.firstWhereOrNull(
      (product) => product.hasBoxBarcode == true && product.boxBarcode == gtin,
    );
  }

  static ItemModel? getProductBySku(int sku) {
    return products
        .firstWhereOrNull((product) => product.sku == sku.toString());
  }

  static List<ItemModel> search(String query) {
    if (query.isEmpty) return [];

    query = translit.toTranslit(source: query).toLowerCase();

    return products.where((product) {
      String name =
          translit.toTranslit(source: product.name ?? "").toLowerCase();
      String sku = product.sku?.toLowerCase() ?? "";

      bool matchesBarcode =
          product.barcode?.any((b) => b.contains(query)) ?? false;

      return name.contains(query) || sku.contains(query) || matchesBarcode;
    }).toList();
  }

  static List<ItemModel> searchProductsBySku(String pattern) {
    final List<ItemModel> list = [];
    try {
      list.addAll(products.where((e) {
        return e.sku.toString() == pattern;
      }).toList());
    } catch (e) {
      return [];
    }
    return list;
  }

  static List<ItemModel> searchProductsByBarcode(String pattern) {
    final trimmed = pattern.trim();
    if (trimmed.isEmpty) return [];
    final List<ItemModel> exactList = [];
    for (final product in products) {
      if (product.barcode == null || product.barcode!.isEmpty) continue;
      for (final b in product.barcode!) {
        if (b.trim() == trimmed) {
          exactList.add(product);
          break;
        }
      }
    }
    return exactList;
  }

  static Translit translit = Translit();

// static List<ItemModel> searchProductsByName(String query) {
//   List<ItemModel> list = [];
//   if (query != '') {
//     list = products.where((e) {
//       String name = translit.toTranslit(source: e.name ?? "").toLowerCase();
//       query = translit.toTranslit(source: query).toLowerCase();
//       return name.contains(query);
//     }).toList();
//   }
//   return list;
// }

  /*static List<ItemModel> searchProductsByName(String query) {
    List<ItemModel> list = [];
    List<ItemModel> list2 = [];
    if (query != '') {
      String newQuery = translit.unTranslit(source: query).toLowerCase();
      String oldQuery = translit.toTranslit(source: query).toLowerCase();
      list = products
          .where((e) => e.name != null
              ? e.name!.toLowerCase().contains(oldQuery.toLowerCase())
              : false)
          .toList();

      if (newQuery != query) {
        list2 = products
            .where(
              (e) => e.name != null
                  ? e.name!.toLowerCase().contains(newQuery.toLowerCase())
                  : false,
            )
            .toList();
      }
    }
    list.addAll(list2);
    return list;
  }*/

  static List<ItemModel> searchProductsByName(String query) {
    if (query.trim().isEmpty) return [];

    String queryLower = query.toLowerCase();
    String queryTranslit = translit.toTranslit(source: queryLower);
    String queryUnTranslit = translit.unTranslit(source: queryLower);

    final result = <ItemModel>{};

    for (final e in products) {
      final name = e.name?.toLowerCase();
      if (name == null) continue;

      if (name.contains(queryLower) ||
          name.contains(queryTranslit) ||
          name.contains(queryUnTranslit)) {
        result.add(e);
      }
    }

    return result.toList();
  }

  // static Future<void> clearAndPutItems(List<ItemModel> items) async {
  //   Box<ItemModel> box = HiveBoxes.getProducts();
  //   await box.clear();
  //   Map<String, ItemModel> map = {};
  //   for (var item in items) {
  //     map[item.key] = item;
  //   }
  //   await box.putAll(map);
  //   return;
  // }

  static Future<void> clearAndPutItems(List<ItemModel> items) async {
    final box = HiveBoxes.getProducts();
    await box.clear();
    final map = {for (var e in items) (e).key: e};
    await box.putAll(map);
  }

  static Future<void> deleteProduct(List<String> items) async {
    Box<ItemModel> box = HiveBoxes.getProducts();
    for (var item in items) {
      await box.delete(item);
    }
    return;
  }

  static Future<void> putItems(List<ItemModel> items) async {
    items = addPackageCodeAndMxikCode(
      items,
      Pref.getString(PrefKeys.mxikCode, ''),
      Pref.getString(PrefKeys.packageCode, ''),
    );
    Box<ItemModel> box = HiveBoxes.getProducts();
    Map<String, ItemModel> map = {};
    for (var item in items) {
      if (item.id == null) continue;
      if (!(item.isActive ?? false)) {
        await deleteProduct([item.id!]);
      } else {
        // Mavjud productning isMarking qiymatini saqlash
        final existing = box.get(item.id);
        if (existing != null && (existing.isMarking == true)) {
          item = item.copyWith(isMarking: true);
        }
        map[item.id!] = item;
      }
    }
    await box.putAll(map);
    return;
  }

  static Future<void> editItem(ProductPriceEdit priceEdit) async {
    Box<ItemModel> box = HiveBoxes.getProducts();

    List<ProductsValues>? productsValues = priceEdit.data?.productsValues;

    if (productsValues != null && productsValues.isNotEmpty) {
      for (ProductsValues p in productsValues) {
        ItemModel? item = box.get(p.productId);
        if (item != null) {
          if (item.shopPrices?.shID?.shopId == p.price?.shopId) {
            if (p.price != null &&
                p.price!.shopPriceTiers != null &&
                item.shopPrices != null &&
                item.shopPrices!.shID != null &&
                item.shopPrices!.shID!.shopPriceTiers != null) {
              item.shopPrices!.shID!.shopPriceTiers!.clear();
              for (ShopPriceTiersSub sh in p.price!.shopPriceTiers!) {
                item.shopPrices!.shID!.shopPriceTiers!.add(
                  ShopPriceTiers(
                    minQuantity: sh.minQuantity,
                    retailPrice: sh.retailPrice,
                  ),
                );
              }
            }
          }
          await box.put(item.id, item);
        }
      }
    }
    return;
  }

  static Future<void> editMxik(List<MxikCodes> mxikUpdates) async {
    Box<ItemModel> box = HiveBoxes.getProducts();
    List<ItemModel> productList = box.values.toList();

    if (mxikUpdates.isNotEmpty && productList.isNotEmpty) {
      for (MxikCodes m in mxikUpdates) {
        for (ItemModel item in productList) {
          if (m.oldMxik == item.mxikCode) {
            item.mxikCode = m.newMxik;
            item.packageCode = m.package?.packageCode ?? '';
            item.packageName = m.package?.packageName ?? '';
            item.packageType = m.package?.packageType ?? '';
            await box.put(item.id, item);
          }
        }
      }
    }
    return;
  }

  static Future<void> deleteMxik(List<dynamic> mxikCodes) async {
    Box<ItemModel> box = HiveBoxes.getProducts();
    List<ItemModel> productList = box.values.toList();

    if (mxikCodes.isNotEmpty && productList.isNotEmpty) {
      for (dynamic m in mxikCodes) {
        for (ItemModel item in productList) {
          if (m == item.mxikCode) {
            item.mxikCode = Pref.getString(PrefKeys.mxikCode, '');
            item.packageCode = Pref.getString(PrefKeys.packageCode, '');
            item.packageName = 'dona';
            item.packageType = '';
            await box.put(item.id, item);
          }
        }
      }
    }
    return;
  }

  static Future<void> updateMxiksWithBarcode(List items) async {
    Box<ItemModel> box = HiveBoxes.getProducts();
    Map<String, ItemModel> map = {};

    for (var item in items) {
      ItemModel? iModel = box.get(item['id']);
      iModel?.mxikCode = item["new_mxik"];
      map[iModel?.key] = iModel!;
    }
    await box.putAll(map);
    return;
  }

  static Future<void> updateLabesWithMxik(List<dynamic> items) async {
    Box<ItemModel> box = HiveBoxes.getProducts();
    Map<String, ItemModel> map = {};
    for (var item in items) {
      for (var itemM in box.values) {
        if (item['mxik'] == itemM.mxikCode) {
          if (item['label'] != 0) {
            itemM.isMarking = true;
            map[itemM.key] = itemM;
          }
        }
      }
    }

    await box.putAll(map);
    return;
  }

  static List<ItemModel> addPackageCodeAndMxikCode(
      List<ItemModel> i, String mxikCode, String packageCode) {
    for (int n = 0; n < i.length; n++) {
      if (i[n].mxikCode == null ||
          i[n].mxikCode!.isEmpty ||
          i[n].packageCode == null ||
          i[n].packageCode!.isEmpty) {
        i[n].mxikCode = mxikCode;
        i[n].packageCode = packageCode;
      }
    }
    return i;
  }
}
