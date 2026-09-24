// ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/changes/services/catalog_refresh_notice.dart';
import 'package:invan2/changes/services/sync/catch_up_sync.dart';
import 'package:invan2/changes/services/sync/notification_fetch.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/mxik_updates.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/product_price_edit_response.dart';
import 'package:provider/provider.dart';
import '../../../../features/features.dart';
import '../../../../features/get_products/singletons/items_singleton.dart';
import '../../../../features/get_products/soliq/tasnif_service.dart';
import '../../../../features/hive_repository/hive_boxes.dart';
import '../../../../utils/constants/constants.dart';
import '../../../../utils/helpers/helpers.dart';
import '../../../models/organization_model.dart';
import '../../../models/product/item_model.dart';
import '../../../singletons/organization_singleton.dart';
import '../../api/result_http_model.dart';
import '../../get_items_service.dart';

/*
    Mahsulot oqimi: notification'lardan lokal katalogni yangilash.

    Turlari: 0 — hammasini qayta yukla, 1 — yangi mahsulot, 2 — yangilash,
    3 — o'chirish, 13 — narx, 20/21 — MXIK, 40 — to'lov turi (CLICK/UZUM/
    PAYME), 6 — e'tiborsiz.

    So'rov/tartiblash/xatoga chidamlilik NotificationFetch'da; bu yerda
    faqat bitta notification'ni qanday qo'llash yozilgan.
*/
class ProductsWsService {
  ProductsWsService._();

  static const int limit = NotificationFetch.limit;

  /// Mahsulot oqimi qamrab oladigan notification turlari.
  static const String types = '1,2,3,0,6,13,20,21,40';

  static Future<SyncFetchResult> getReceivedWS(bool mounted,
      BuildContext context, String startDate, String endDate) async {
    try {
      // Bitta oynada avval o'chirilgan mahsulotni keyinroq (yoki xuddi shu
      // soniyada) kelgan create/update qayta tiriltirmasin — id → o'chirish
      // vaqti.
      final Map<String, DateTime?> deletedInBatch = <String, DateTime?>{};
      return await NotificationFetch.run(
        label: 'Product',
        types: types,
        startDate: startDate,
        endDate: endDate,
        apply: (ws) => _apply(ws, context, mounted, deletedInBatch),
        afterBatch: refreshCaches,
      );
    } catch (e, stack) {
      // NotificationFetch o'zi hamma narsani ushlaydi; bu faqat oxirgi
      // himoya — kursor surilmasligi uchun muvaffaqiyatsiz qaytaramiz.
      if (kDebugMode) {
        print('❌ Product notification xatosi: $e');
      }
      await LogHelper.activity(
          'SYNC_FETCH_CRASH', {'stream': 'Product', 'error': e, 'stack': stack});
      return const SyncFetchResult.failed();
    }
  }

  /// Hive'dagi katalogni xotira keshiga qayta yuklaydi.
  ///
  /// Oyna oxirida BIR marta chaqiriladi. Ilgari har notification'dan keyin
  /// chaqirilardi: 500 ta narx o'zgarishi = 57 000 mahsulotni 500 marta
  /// qayta yuklash — UI o'nlab soniya qotardi.
  static Future<void> refreshCaches() async {
    await ItemsSingleton.storeProducts();
    CategorySingleton.init();
  }

  static Future<NotifyApply> _apply(Map<String, dynamic> ws, BuildContext context,
      bool mounted, Map<String, DateTime?> deletedInBatch) async {
    final int? type = _asInt(ws['type']);
    final Map<String, dynamic> data = _asMap(ws['data']);

    switch (type) {
      case 21:
        await ItemsSingleton.deleteMxik(_asList(data['mxik_codes']));
        return NotifyApply.applied;

      case 20:
        await ItemsSingleton.editMxik(MxikUpdates.fromJson(data).mxikCodes ?? []);
        return NotifyApply.applied;

      case 13:
        final ProductPriceEdit edit = ProductPriceEdit.fromJson(ws);
        if (data.isNotEmpty && edit.data?.productsValues == null) {
          // Payload bor-u, biz kutgan `product_values` yo'q — shakl
          // o'zgargan. Jimgina "qo'llandi" deyish narxni yo'qotardi.
          throw const FormatException('type 13: product_values yo\'q');
        }
        await ItemsSingleton.editItem(edit);
        return NotifyApply.applied;

      case 0:
        // Serverning "hammasini qayta yukla" buyrug'i — oyna ichida emas,
        // runner'ning yagona to'liq yuklash yo'li orqali (backoff, timeout,
        // kursor commit hammasi o'sha yerda).
        return NotifyApply.fullReload;

      case 1:
      case 2:
        return _upsert(ws, data, isUpdate: type == 2, deletedInBatch: deletedInBatch);

      case 3:
        final List<String> ids = _asList(data['ids'])
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList();
        if (ids.isEmpty) {
          throw const FormatException('type 3: ids bo\'sh yoki noto\'g\'ri shakl');
        }
        await ItemsSingleton.deleteProduct(ids);
        final DateTime? at = NotificationFetch.parseCreatedAt(ws['created_at']);
        for (final String id in ids) {
          deletedInBatch[id] = at;
        }
        return NotifyApply.applied;

      case 40:
        await _paymentToggle(data, context, mounted);
        return NotifyApply.ignored;

      default:
        return NotifyApply.ignored;
    }
  }

  /// Yangi mahsulot (type 1) yoki yangilash (type 2).
  ///
  /// Parse xatosi istisno bo'lib chiqadi — NotificationFetch uni faqat shu
  /// notification uchun belgilaydi, oyna qolgan qismi qo'llanadi va oqim
  /// to'liq yuklash bilan tenglashtiriladi.
  static Future<NotifyApply> _upsert(
    Map<String, dynamic> ws,
    Map<String, dynamic> data, {
    required bool isUpdate,
    required Map<String, DateTime?> deletedInBatch,
  }) async {
    if (data.isEmpty) {
      throw const FormatException('notification data bo\'sh');
    }
    if (data['is_active'] != null && data['is_active'] is! bool) {
      throw FormatException('is_active bool emas: ${data['is_active']}');
    }
    final ItemModel item = isUpdate
        ? ItemModel.fromWebSocketJsonUpdate(data)
        : ItemModel.fromWebSocketJson(data);
    final String? id = item.id;
    if (id == null || id.isEmpty) {
      throw const FormatException('mahsulot id yo\'q');
    }

    // Shu oynada allaqachon o'chirilgan mahsulot: create/update o'chirishdan
    // qat'iy KEYIN yaratilgan bo'lsagina qo'llanadi. Bir soniya ichidagi
    // juftlik (server yangi-birinchi qaytarsa) o'chirilganini tiriltirmasin.
    if (deletedInBatch.containsKey(id)) {
      final DateTime? deletedAt = deletedInBatch[id];
      final DateTime? at = NotificationFetch.parseCreatedAt(ws['created_at']);
      if (deletedAt == null || at == null || !at.isAfter(deletedAt)) {
        await LogHelper.activity('SYNC_SKIP_RESURRECT', {'id': id});
        return NotifyApply.ignored;
      }
    }

    item.categories ??= categoriesFromIds(data['category_ids']);

    // Notification payload'i to'liq katalogdan kambag'alroq: `shop_prices`
    // KALITI umuman yo'q bo'lsa mavjud narx saqlanadi (ilgari mahsulot
    // to'liq ustidan yozilib narxsiz qolar, skanerda topilmay qolardi).
    // Kalit BOR-U natija 0 bo'lsa (server ataylab narxni olib
    // tashlagan/0 qilgan) — bu hurmat qilinadi, eski narx saqlanib
    // qolmaydi. Parser bilmaydigan/lokalda topilmagan boshqa maydonlar
    // (ownerType, commissionTin, o'lchov birligi/QQS) mavjud yozuvdan
    // saqlanadi.
    await ItemsSingleton.putItems(
      [item],
      mergeWithExisting: true,
      priceKeyPresent: data.containsKey('shop_prices'),
    );
    return NotifyApply.applied;
  }

  static Future<void> _paymentToggle(
      Map<String, dynamic> data, BuildContext context, bool mounted) async {
    final String name = data['name']?.toString() ?? '';
    final bool isUsed = data['is_used'] == true;
    final String id = data['id']?.toString() ?? '';

    if (name == 'CLICK') {
      await Pref.setBool(PrefKeys.clickEnable, isUsed);
      await Pref.setString(PrefKeys.clickId, id);
    } else if (name == 'UZUM') {
      await Pref.setBool(PrefKeys.uzumEnable, isUsed);
      await Pref.setString(PrefKeys.uzumId, id);
    } else if (name == 'PAYME') {
      await Pref.setBool(PrefKeys.paymeEnable, isUsed);
      await Pref.setString(PrefKeys.paymeId, id);
    }

    final box = await Hive.openBox<Payment>('other_payments');
    final payments = box.values.toList();
    for (int i = 0; i < payments.length; i++) {
      if (payments[i].name == name) {
        payments[i].isAdded = isUsed;
        await box.putAt(i, payments[i]);
        break;
      }
    }

    await OrganizationSingleton.setOtherPayments();
    if (mounted && context.mounted) {
      Provider.of<OrderingProvider4>(context, listen: false).notifyListeners();
    }
  }

  static int? _asInt(dynamic v) =>
      v is int ? v : (v is num ? v.toInt() : int.tryParse('$v'));

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

  static List<dynamic> _asList(dynamic v) => v is List ? v : const <dynamic>[];

  /// `category_ids` dan mahsulot kategoriyasi. null yoki bo'sh bo'lsa null —
  /// ilgari `as List` bilan cast qilinib, null kelganda butun oyna yiqilardi.
  static List<CategoriesFromProducts>? categoriesFromIds(dynamic ids) {
    if (ids is! List || ids.isEmpty) return null;
    return getCategories(ids.first);
  }

  static Future<bool> import(BuildContext context) async {
    CatalogRefreshNotice.beginLoad();
    try {
      return await _import(context);
    } finally {
      CatalogRefreshNotice.endLoad();
    }
  }

  static Future<bool> _import(BuildContext context) async {
    DateTime time = DateTime.now();
    List<ItemModel> allProducts = [];
    final Set<String> skippedIds = <String>{};
    await TasnifService.setPackageCode();

    HttpResult httpResult = await OrdersService.getItems();

    if (httpResult.isSuccess) {
      try {
        final dynamic decodedJson = httpResult.result is String
            ? json.decode(httpResult.result)
            : httpResult.result;

        if (decodedJson is List) {
          // Bitta buzuq yozuv butun 43 MB importni yiqitmasin — u
          // o'tkazib yuboriladi va log'ga yoziladi (parseCatalog).
          final CatalogParseResult parsed =
              await ItemsSingleton.parseCatalog(decodedJson);
          skippedIds.addAll(parsed.skippedIds);
          List<ItemModel> i = ItemsSingleton.addPackageCodeAndMxikCode(
            parsed.items,
            Pref.getString(PrefKeys.mxikCode, ''),
            Pref.getString(PrefKeys.packageCode, ''),
          );
          allProducts.addAll(i);
          i.clear();
        } else {
          return false;
        }
      } catch (e) {
        await LogHelper.activity('SYNC_CATALOG_PARSE_FAILED', {'error': e});
        return false;
      }
    }

    if (allProducts.isNotEmpty) {
      // Faqat haqiqiy muvaffaqiyatda — ilgari yiqilgan yuklash ham
      // "oxirgi yangilanish" vaqtini surib qo'yardi.
      await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
      // `skippedIds`: bu safar parse bo'lmagan mahsulotlar "serverda yo'q"
      // deb o'chirilmaydi (parseCatalog dokumentatsiyasiga qarang).
      await ItemsSingleton.clearAndPutItems(allProducts,
          preserveIds: skippedIds);
      CategorySingleton.init();
      await ItemsSingleton.storeProducts();
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
      });
      allProducts.clear();
      // Bu ham to'liq katalog yuklashi — startup'dagi yiqilish qoplandi.
      await CatalogRefreshNotice.markFresh();
      return true;
    }
    return false;
  }

  /// Kategoriya id'sidan mahsulot uchun kategoriya yozuvi.
  ///
  /// Kategoriya hali lokalga kelmagan bo'lsa ham id SAQLANADI: UI mahsulotni
  /// kategoriya bo'yicha aynan id orqali filtrlaydi, nomi kategoriya oqimi
  /// bilan keladi (u darhol so'raladi — `requestCategoriesRefresh`). Ilgari
  /// bunday mahsulot kategoriyasiz qolar va to'liq yuklashgacha o'z
  /// kategoriyasida ko'rinmasdi.
  static List<CategoriesFromProducts>? getCategories(dynamic message) {
    final String id = message?.toString() ?? '';
    if (id.isEmpty) return null;

    CategoryData? local;
    final Box<CategoryData> categoriesModel = HiveBoxes.getCategories();
    for (CategoryData c in categoriesModel.values) {
      if (c.id == id) {
        local = c;
        break;
      }
    }
    if (local == null) CatchUpSync.requestCategoriesRefresh();
    return [CategoriesFromProducts(id: id, name: local?.name)];
  }
}
