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
import '../../../changes/services/log_helper.dart';
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

  /// Qatorning fizik dona soni: blok qatorida value × boxValue, aks holda value
  static num _rowUnits(ReceiptModelSoldItem4 r) =>
      r.saleType == 2 && r.boxValue > 0 ? r.value * r.boxValue : r.value;

  /// Savatdagi shu productning umumiy dona soni (dona + blok donalari) —
  /// tier narx shu umumiy songa qarab tanlanadi
  static num _totalUnitsOf(
      String productId, List<ReceiptModelSoldItem4> products) {
    num total = 0;
    for (final r in products) {
      if (r.productId == productId && !(r.isDeleted ?? false)) {
        total += _rowUnits(r);
      }
    }
    return total;
  }

  static double getBaseTotalPrice(
      List<ReceiptModelSoldItem4> products, bool isMinimumPricedClient) {
    double baseTotalPrice = 0;
    for (int i = 0; i < products.length; i++) {
      if (!products[i].isDeleted!) {
        ItemModel? item = getProductById(products[i].productId);
        if (item != null) {
          final totalUnits = _totalUnitsOf(products[i].productId, products);
          double price =
              finalPrice(item, totalUnits.toInt(), products[i].isKg).toDouble();

          baseTotalPrice +=
              UtilFunctions.roundToNearest(price * _rowUnits(products[i]));
        }
      }
    }
    return UtilFunctions.roundToNearest(baseTotalPrice);
  }

  /// Qatorning bazaviy narxi. [allRows] berilsa tier savatdagi umumiy son
  /// bo'yicha tanlanadi (dona + blok donalari), aks holda qator o'z soni bo'yicha.
  /// Blok qatorida qaytariladigan qiymat = tierUnit × boxValue (butun blok narxi).
  static num getItemBasePrice(
      ReceiptModelSoldItem4 soldItem4, bool isMinimumPricedClient,
      {List<ReceiptModelSoldItem4>? allRows}) {
    ItemModel? item = getProductById(soldItem4.productId);
    if (item == null) return 0;

    final units = allRows != null
        ? _totalUnitsOf(soldItem4.productId, allRows)
        : _rowUnits(soldItem4);
    final unit =
        finalPrice(item, units.toInt(), soldItem4.isKg).toDouble();

    return soldItem4.saleType == 2 && soldItem4.boxValue > 0
        ? unit * soldItem4.boxValue
        : unit;
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

  // extractBarcode olib tashlandi (2026-07-08): ixtiyoriy satrdan raqamlar
  // ketma-ketligini ajratib olib qidirish taqiqlangan — noto'g'ri format
  // hech narsa topmasligi kerak. Barcha qidiruvlar 100% teng moslikda.

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

  
  /// [allowSkuFallback] false bo'lsa, qisqa (≤5 belgi) kiritish SKU deb
  /// taxmin qilinmaydi — faqat 100% teng barcode qidiriladi. Skaner kiritishi
  /// uchun ham true qoladi: do'konlar narx yorlig'iga SKU'ni barcode qilib
  /// chiqaradi va kassir uni skan qiladi. Fragment-himoya SKU branch'ning
  /// o'zida — faqat sof raqam, normalizatsiyasiz aynan teng moslik.
  static ItemModel? getProductByBarcode(String barcode,
      {bool allowSkuFallback = true}) {
    if (barcode.isEmpty) return null;

    final trimmed = barcode.trim();

    // SKU bo'yicha qidirish (5 belgidan qisqa).
    // SKU FAQAT raqamlardan iborat: harf/belgi aralashgan kiritish SKU emas —
    // ichidan raqam ajratib olinmaydi, normalizatsiya qilinmaydi.
    // Noto'g'ri format → null (kick). Qidiruv aynan kiritilganidek bajariladi.
    if (trimmed.length <= 5) {
      if (!allowSkuFallback) return null;
      if (!RegExp(r'^\d+$').hasMatch(trimmed)) return null;
      return products.firstWhereOrNull((p) => p.sku == trimmed);
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
    final List<ItemModel> prefixList = [];
    for (final product in products) {
      if (product.barcode == null || product.barcode!.isEmpty) continue;
      bool exact = false;
      bool prefix = false;
      for (final b in product.barcode!) {
        final bt = b.trim();
        if (bt == trimmed) {
          exact = true;
          break;
        }
        if (bt.startsWith(trimmed)) {
          prefix = true;
        }
      }
      if (exact) {
        exactList.add(product);
      } else if (prefix) {
        prefixList.add(product);
      }
    }
    return [...exactList, ...prefixList];
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

  /// Katalogni to'liq almashtiradi.
  ///
  /// Ilgari `box.clear()` + `putAll` edi: clear faylni 0 baytga qisqartirar,
  /// putAll o'rtada yiqilsa (fayl qulfi, disk to'lgan, ilova o'ldirildi,
  /// svet o'chdi) katalog bo'sh/yarim qolar, kursor esa "hammasi bor" deb
  /// turardi. Endi: avval hammasi ustidan yoziladi (eski fayl butun
  /// qoladi), keyin serverda yo'q qolgan yozuvlar o'chiriladi, oxirida
  /// diskka flush. Butun jarayon marker bilan o'raladi — ilova o'rtada
  /// o'lsa keyingi sinxron kursorni tashlab to'liq yuklashni qaytaradi
  /// (CatchUpSync.healCatalogState).
  ///
  /// [preserveIds] — bu safar parse bo'lmagan (shuning uchun [items] da
  /// yo'q) mahsulot id'lari (`parseCatalog().skippedIds`). Ular "serverda
  /// yo'q" deb O'CHIRILMAYDI — biz shunchaki bu safar ularni o'qiy olmadik.
  /// Aks holda bitta buzuq maydonli yozuv (masalan noto'g'ri son formati)
  /// o'sha mahsulotni har to'liq yuklashda kassadan yo'qotib turardi.
  static Future<void> clearAndPutItems(
    List<ItemModel> items, {
    Set<dynamic> preserveIds = const <dynamic>{},
  }) async {
    final box = HiveBoxes.getProducts();
    final Map<dynamic, ItemModel> map = {for (var e in items) (e).key: e};
    final List<dynamic> stale = box.keys
        .where((k) => !map.containsKey(k) && !preserveIds.contains(k))
        .toList();
    await Pref.setBool(PrefKeys.catalogWriteInProgress, true);
    await box.putAll(map);
    if (stale.isNotEmpty) await box.deleteAll(stale);
    await box.flush();
    await Pref.setBool(PrefKeys.catalogWriteInProgress, false);
  }

  /// To'liq katalog JSON ro'yxatini modelga o'tkazadi — har yozuv alohida
  /// himoyada. Ilgari bitta buzuq yozuv (masalan `min_quantity: 1.0`)
  /// butun importni yiqitar va sinxron abadiy muzlab qolardi.
  static Future<CatalogParseResult> parseCatalog(List<dynamic> raw) async {
    final List<ItemModel> items = <ItemModel>[];
    final Set<String> skippedIds = <String>{};
    int failed = 0;
    Object? firstError;
    for (final dynamic e in raw) {
      try {
        if (e is! Map) throw FormatException('yozuv obyekt emas: $e');
        items.add(ItemModel.fromJson(Map<String, dynamic>.from(e)));
      } catch (err) {
        failed++;
        firstError ??= err;
        // Id'ni bo'lak qismidan ham (kengroq himoyada) olishga urinamiz —
        // topilsa, `clearAndPutItems` bu mahsulotni o'chirmaydi.
        try {
          if (e is Map) {
            final dynamic id = e['id'];
            if (id != null) skippedIds.add(id.toString());
          }
        } catch (_) {}
      }
    }
    if (failed > 0) {
      await LogHelper.activity('SYNC_CATALOG_PARSE_SKIPPED', {
        'skipped': failed,
        'total': raw.length,
        'first_error': firstError,
        'skipped_ids_known': skippedIds.length,
      });
    }
    return CatalogParseResult(items, failed, firstError, skippedIds);
  }

  static Future<void> deleteProduct(List<String> items) async {
    Box<ItemModel> box = HiveBoxes.getProducts();
    for (var item in items) {
      await box.delete(item);
    }
    return;
  }

  /// Mahsulotlarni lokalga yozadi (id bo'yicha ustidan yozish).
  ///
  /// `is_active == false` bo'lsagina o'chiriladi. Ilgari `!(isActive ?? false)`
  /// edi — payload'da maydon bo'lmasa (null) mahsulot O'CHIRILARDI.
  ///
  /// [mergeWithExisting] — notification yo'li uchun: kelgan yozuv to'liq
  /// katalogdan kambag'alroq bo'lishi mumkin, shuning uchun
  ///  * `shop_prices` KALITI payload'da umuman bo'lmasa, lokaldagi mavjud
  ///    narx saqlanadi (ilgari mahsulot narxsiz qolib skanerda topilmasdi).
  ///    [priceKeyPresent] shu signalni beradi — FAQAT kalit yo'qligida
  ///    saqlanadi, kalit BOR-U natija 0/topilmadi bo'lsa (server ataylab
  ///    narxni olib tashlagan/0 qilgan) hurmat qilinadi, eski narx
  ///    ustidan yozilmasdan qolib ketmaydi;
  ///  * parser bilmaydigan/lokalda topilmagan maydonlar (ownerType,
  ///    commissionTin, mark, o'lchov birligi, QQS) mavjud yozuvdan olinadi —
  ///    aks holda fiskal chekda OwnerType/QQS noto'g'ri ketardi.
  static Future<void> putItems(
    List<ItemModel> items, {
    bool mergeWithExisting = false,
    bool priceKeyPresent = true,
  }) async {
    items = addPackageCodeAndMxikCode(
      items,
      Pref.getString(PrefKeys.mxikCode, ''),
      Pref.getString(PrefKeys.packageCode, ''),
    );
    Box<ItemModel> box = HiveBoxes.getProducts();
    Map<String, ItemModel> map = {};
    for (var item in items) {
      if (item.id == null) continue;
      if (item.isActive == false) {
        await deleteProduct([item.id!]);
      } else {
        final existing = box.get(item.id);
        if (existing != null) {
          // Mavjud productning isMarking qiymatini saqlash
          if (existing.isMarking == true) {
            item = item.copyWith(isMarking: true);
          }
          if (mergeWithExisting) {
            item = _mergeFromExisting(item, existing,
                priceKeyPresent: priceKeyPresent);
          }
        }
        map[item.id!] = item;
      }
    }
    await box.putAll(map);
    return;
  }

  static ItemModel _mergeFromExisting(ItemModel item, ItemModel existing,
      {required bool priceKeyPresent}) {
    if (!priceKeyPresent &&
        onePrice(item.shopPrices) <= 0 &&
        onePrice(existing.shopPrices) > 0) {
      item = item.copyWith(shopPrices: existing.shopPrices);
      LogHelper.activity('SYNC_PRICE_KEPT', {'id': item.id});
    }
    // copyWith `??` bilan ishlaydi: faqat kelgan qiymat null bo'lganda
    // mavjudini beramiz, aks holda kelgan qiymat ustun.
    if (item.ownerType == null && existing.ownerType != null) {
      item = item.copyWith(ownerType: existing.ownerType);
    }
    if (item.commissionTin == null && existing.commissionTin != null) {
      item = item.copyWith(commissionTin: existing.commissionTin);
    }
    if (item.mark == null && existing.mark != null) {
      item = item.copyWith(mark: existing.mark);
    }
    final bool unitMissing =
        item.measurementUnit == null || (item.measurementUnit!.id ?? '').isEmpty;
    if (unitMissing && existing.measurementUnit != null) {
      item = item.copyWith(measurementUnit: existing.measurementUnit);
    }
    final bool vatMissing = item.vat == null || (item.vat!.id ?? '').isEmpty;
    if (vatMissing && existing.vat != null) {
      item = item.copyWith(vat: existing.vat);
    }
    return item;
  }

  /// Narx o'zgarishi (notification type 13) — shu do'kon uchun narx
  /// pog'onalarini almashtiradi.
  ///
  /// Mahsulotda hali shu do'kon narxi BO'LMASA ham yaratiladi. Ilgari faqat
  /// mavjud `shopPriceTiers` ro'yxati yangilanardi: mahsulot avval boshqa
  /// do'kon uchun yaratilib, keyin shu do'konga narx qo'yilsa (yoki type 1
  /// payload'ida narx bo'lmasa) narx hech qachon yetib bormas, mahsulot
  /// to'liq yuklashgacha skanerda topilmasdi.
  ///
  /// Qaytadi: nechta mahsulot yangilandi.
  static Future<int> editItem(ProductPriceEdit priceEdit) async {
    final Box<ItemModel> box = HiveBoxes.getProducts();
    final String myShop = Pref.getString(PrefKeys.storeId, '');
    final List<ProductsValues>? productsValues = priceEdit.data?.productsValues;
    if (productsValues == null || productsValues.isEmpty) return 0;

    int changed = 0;
    for (final ProductsValues p in productsValues) {
      final String? productId = p.productId;
      if (productId == null || productId.isEmpty) continue;
      final ItemModel? item = box.get(productId);
      if (item == null) continue;

      final Price? price = p.price;
      final String targetShop = price?.shopId ?? '';
      if (price == null || price.shopPriceTiers == null || targetShop.isEmpty) {
        continue;
      }

      // Faqat shu kassaning do'koni (yoki mahsulotda allaqachon turgan
      // do'kon — eski xulq bilan mos). Boshqa do'kon narxi e'tiborsiz.
      final bool mine = targetShop == myShop ||
          targetShop == item.shopPrices?.shID?.shopId;
      if (!mine) continue;

      final List<ShopPriceTiers> tiers = price.shopPriceTiers!
          .map((sh) => ShopPriceTiers(
                minQuantity: sh.minQuantity,
                retailPrice: sh.retailPrice,
              ))
          .toList();
      final ShID? existing = item.shopPrices?.shID;
      item.shopPrices = ShopPrices(
        shID: ShID(
          shopId: targetShop,
          supplyPrice: price.supplyPrice ?? existing?.supplyPrice,
          shopPriceTiers: tiers,
        ),
      );
      await box.put(item.id, item);
      changed++;
    }
    return changed;
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

/// To'liq katalogni parse qilish natijasi.
class CatalogParseResult {
  final List<ItemModel> items;
  final int failed;
  final Object? firstError;

  /// Parse bo'lmagan, lekin id'si aniqlangan yozuvlar. `clearAndPutItems`
  /// ga `preserveIds` sifatida uzatilsa, bu mahsulotlar "serverda yo'q"
  /// deb o'chirilmaydi.
  final Set<String> skippedIds;

  const CatalogParseResult(
      this.items, this.failed, this.firstError, this.skippedIds);
}
