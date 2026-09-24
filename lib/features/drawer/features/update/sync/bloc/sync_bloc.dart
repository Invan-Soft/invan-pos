import 'dart:convert';
import 'package:invan2/changes/services/catalog_refresh_notice.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/get_items_service.dart';
import 'package:invan2/changes/services/sync/catch_up_sync.dart';
import 'package:invan2/changes/services/sync/server_clock.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';
import 'package:invan2/features/get_categories/get_categories.dart';
import 'package:invan2/features/get_categories/service/category_service.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/helpers.dart';

import '../../../../../get_products/soliq/tasnif_service.dart';

part 'sync_event.dart';

part 'sync_state.dart';

class SyncResult {
  List<ItemModel> items;
  bool result;

  SyncResult({required this.items, required this.result});
}

class SyncBloc extends Bloc<SyncEvent, SyncState> {
  SyncBloc() : super(SyncInitialState()) {
    on<SyncSyncEvent>(_sync);
    on<SyncInitialEvent>(_initial);
  }

  static _initial(SyncInitialEvent event, Emitter<SyncState> emit) async {
    emit(SyncInitialState());
  }

  static _sync(SyncSyncEvent event, Emitter<SyncState> emit) async {
    emit(SyncLoadingState());
    // Sinxron qulfi ostida: davriy CatchUpSync bilan bir vaqtda
    // `clearAndPutItems` bo'lmasligi uchun (yuklash o'rtasida kelgan
    // mahsulot o'chib, kursor esa o'tib ketishi mumkin edi).
    await CatchUpSync.exclusive(() => _syncLocked(emit),
        reason: 'drawer-sync');
  }

  static Future<void> _syncLocked(Emitter<SyncState> emit) async {
    DateTime time = DateTime.now();
    // Kursor yuklash BOSHLANGAN vaqtga suriladi — yuklash davomida bo'lgan
    // o'zgarishlar notification orqali kelishi kerak. Server vaqtiga
    // yuklashdan KEYIN o'tkaziladi (ServerClock shu paytda aniq).
    final DateTime startedAt = DateTime.now().toUtc();
    List<ItemModel> allProducts = [];
    final Set<String> skippedIds = <String>{};
    String getError = '';
    await TasnifService.setPackageCode();

    HttpResult httpResult = await OrdersService.getItems();

    if (httpResult.isSuccess) {
      try {
        final dynamic decodedJson = httpResult.result is String
            ? json.decode(httpResult.result)
            : httpResult.result;

        if (decodedJson is List) {
          final parsed = await ItemsSingleton.parseCatalog(decodedJson);
          skippedIds.addAll(parsed.skippedIds);
          List<ItemModel> i = ItemsSingleton.addPackageCodeAndMxikCode(
            parsed.items,
            Pref.getString(PrefKeys.mxikCode, ''),
            Pref.getString(PrefKeys.packageCode, ''),
          );
          allProducts.addAll(i);
          i.clear();
        } else {
          getError = "Ma'lumotlar formati noto'g'ri.";
        }
      } catch (e) {
        getError = "Ma'lumotlar o'qishda xatolik: $e";
      }
    } else {
      getError = httpResult.getError;
    }

    if (allProducts.isNotEmpty) {
      await toHive(allProducts, skippedIds);
      await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
      // Mahsulotlar to'liq qayta yuklandi — notification tarixiga ehtiyoj
      // qolmadi. Kategoriya kursoriga tegilmaydi: `toHive` ichidagi
      // `_category()` xatoni yutib yuboradi, ya'ni muvaffaqiyatiga
      // ishonib bo'lmaydi.
      await SyncCursor.commit(
          SyncStream.products, ServerClock.toServer(startedAt));
      // Katalog to'liq qayta yuklandi — "baza yangilanmagan" ogohlantirishi
      // qaysi yo'l bilan yangilanganidan qat'i nazar to'xtashi kerak.
      await CatalogRefreshNotice.markFresh();
      emit(
        SyncDoneState(
            SyncResult(
              items: allProducts,
              result: true,
            ),
            time),
      );
      allProducts.clear();
    } else {
      emit(SyncFailedState(getError));
      return;
    }

    // if (Pref.getBool(PrefKeys.withOFD, false)) {
    //   var res4 = await LocalService.getLabelsItemWithMxik(
    //     i.items,
    //     method: 'getLabelsMxik',
    //   );
    //   await ItemsSingleton.updateLabesWithMxik(res4);
    //   var res1 = await LocalService.sendUpdateItems(
    //     i.items,
    //     method: 'updateMxikByMxik',
    //   );
    //   var res2 = await LocalService.sendUpdateItems(
    //     i.items,
    //     method: 'updateMxikByBarcode',
    //   );
    //   await ItemsSingleton.updateMxiksWithBarcode(res2);
    //   await ItemsSingleton.updateMxiksWithMxik(res1);
    // }
    
  }

  /// [skippedIds] — bu safar parse bo'lmagan mahsulotlar; "serverda yo'q"
  /// deb o'chirilmasin (qarang: ItemsSingleton.parseCatalog).
  static Future<void> toHive(
      List<ItemModel> v, Set<String> skippedIds) async {
    // Ilgari bu yerda bevosita `box.putAll` edi: eski (serverda o'chirilgan)
    // mahsulotlar hech qachon o'chirilmasdi, `catalogWriteInProgress`
    // markeri va `box.flush()` yo'q edi — boshqa to'liq yuklash yo'llaridan
    // farqli o'laroq. Endi bitta umumiy, tekshirilgan metod ishlatiladi.
    await ItemsSingleton.clearAndPutItems(v, preserveIds: skippedIds);
    // Bu yerdagi kategoriya xatosi yutiladi — `_syncLocked` shu sabab
    // kategoriya kursoriga tegmaydi (muvaffaqiyatiga ishonib bo'lmaydi).
    await _category();
    await ItemsSingleton.storeProducts();
    CategorySingleton.init();
  }

  /// Kategoriyalarni to'liq qayta yuklaydi.
  ///
  /// Ilgari bu yerda alohida, tekislamaydigan (`children` ichkarida qolib
  /// ketadigan) implementatsiya bor edi — pastki kategoriyalar Hive'ga
  /// TOP-LEVEL qator sifatida yozilmasdi va ular ichidagi mahsulotlar
  /// keyingi "haqiqiy" kategoriya sinxronigacha katalog to'rida ko'rinmay
  /// qolardi. Endi boshqa barcha to'liq yuklash yo'llari bilan bir xil,
  /// tekshirilgan `CategoryService.category()` ishlatiladi.
  static Future<String?> _category() => CategoryService.category();
}
