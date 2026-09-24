// ignore_for_file: use_build_context_synchronously

/*
    Yagona "yetib olish" (catch-up) sinxroni.

    Ilgari sinxron 5 xil joydan, 5 xil vaqt oynasi bilan chaqirilardi va
    hech biri natijani tekshirmasdi. Endi barcha chaqiruvlar shu yagona
    nuqtadan o'tadi:

      startup (app.dart) ─┐
      har N daqiqa ───────┤
      qo'lda "Yangilash" ─┼──> CatchUpSync.run() ──> StreamSyncRunner
      tarmoq tiklandi ────┘                              └──> SyncCursor

    Bu sinf faqat "simlarni ulaydi": qaysi oqim qaysi API bilan olinadi va
    qaysi tartibda. Kursor mantig'i StreamSyncRunner ichida.

    Qulf: bir vaqtda bitta sinxron. Qo'lda to'liq yangilash (UpdBloc,
    SyncBloc, startup, "baza yangilanmagan" dialogi) va logout ham shu
    qulfdan o'tadi (`exclusive`) — aks holda to'liq yuklash `clearAndPutItems`
    bilan sinxron yozgan mahsulotni o'chirib, kursor esa o'tib ketishi mumkin
    edi. Qulf ticket asosida: majburan olingan yoki logout bo'lgan paytda
    hali ishlab turgan eski run `shouldContinue` orqali to'xtaydi va hech
    narsa yozmaydi. Qulf osilib qolsa (`staleLock`, monoton Stopwatch bilan
    o'lchanadi — kassa soati sakrasa ham) keyingi chaqiruv uni majburan oladi.
*/

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/get_categories/service/category_service.dart';
import '../../../features/hive_repository/hive_boxes.dart';
import '../../../features/home/bloc/home_bloc/home_bloc.dart';
import '../../../utils/constants/pref_keys.dart';
import '../../../utils/helpers/prefs.dart';
import '../catalog_refresh_notice.dart';
import '../discount_service.dart';
import '../log_helper.dart';
import '../web_socket_service/category/categories_ws_service.dart';
import '../web_socket_service/discount/discount_ws_service.dart';
import '../web_socket_service/product/products_ws_service.dart';
import 'server_clock.dart';
import 'stream_sync_runner.dart';
import 'sync_cursor.dart';

class CatchUpSync {
  CatchUpSync._();

  /// Kategoriya va diskont mahsulotga qaraganda ancha kam o'zgaradi —
  /// ularni har daqiqada so'rash backendga bekorga yuk. Narx (mahsulot
  /// oqimi) esa har chaqiruvda tekshiriladi.
  ///
  /// Bu cheklov faqat davriy avto-sinxronga tegishli: ilova ochilganda va
  /// qo'lda "Yangilash" bosilganda `force: true` bilan chetlab o'tiladi.
  static const Duration slowStreamInterval = Duration(minutes: 10);

  /// Qulf shundan uzoq ushlab turilsa — egasi osilib qolgan deb hisoblanadi.
  /// Har bir ichki qadam (notification so'rovi, to'liq yuklash) o'z
  /// timeout'iga ega va bundan qisqa.
  static const Duration staleLock = Duration(minutes: 20);

  /// Qo'lda to'liq yangilash joriy sinxron tugashini ko'pi bilan shuncha
  /// kutadi, keyin (`forceAfterWait`) baribir davom etadi.
  static const Duration exclusiveMaxWait = Duration(minutes: 3);

  static int _seq = 0;
  static int _ticket = 0;
  static Stopwatch? _lockAge;
  static String _lockReason = '';
  static int _lastBusyLoggedTicket = 0;

  /// Logout/yangi token bilan oshadi — o'sha paytda ishlab turgan run
  /// eski kompaniya natijalarini yozmasin.
  static int _epoch = 0;

  /// Mahsulot oqimi lokalda yo'q kategoriya id'sini ko'rdi — kategoriya
  /// oqimi keyingi safar 10 daqiqalik cheklovsiz so'raladi.
  static bool _categoriesRequested = false;

  static bool get isRunning => _ticket != 0;

  static bool owns(int ticket) => _ticket == ticket;

  static int get epoch => _epoch;

  static void bumpEpoch() => _epoch++;

  static void requestCategoriesRefresh() => _categoriesRequested = true;

  static int _take(String reason) {
    _ticket = ++_seq;
    _lockAge = Stopwatch()..start();
    _lockReason = reason;
    return _ticket;
  }

  static int? _tryAcquire(String reason) {
    if (_ticket != 0) {
      final Stopwatch? age = _lockAge;
      final bool stale = age != null && age.elapsed > staleLock;
      if (!stale) return null;
      unawaited(LogHelper.activity('SYNC_STALE_LOCK', {
        'held_by': _lockReason,
        'held_min': age.elapsed.inMinutes,
        'taken_by': reason,
      }));
    }
    return _take(reason);
  }

  static void _release(int ticket) {
    // Qulf osilib qolgani uchun boshqa ega olgan bo'lsa — unga tegmaymiz.
    if (_ticket != ticket) return;
    _ticket = 0;
    _lockAge = null;
    _lockReason = '';
  }

  /// Barcha oqimlarni kursordan hozirgi (SERVER) vaqtgacha yetkazadi.
  ///
  /// [force] — sekin oqimlarning 10 daqiqalik cheklovini va to'liq yuklash
  /// backoff'ini chetlab o'tadi.
  ///
  /// Qaytadi: hamma oqim to'liq sinxronlandimi. Hech qachon istisno
  /// tashlamaydi — aks holda avto-sinxron halqasi o'lib qolardi.
  static Future<bool> run(
    BuildContext context,
    bool mounted, {
    String reason = '',
    bool force = false,
  }) async {
    final int? ticket = _tryAcquire(reason);
    if (ticket == null) {
      if (kDebugMode) {
        print('⏭️ Sinxron allaqachon ketmoqda ($_lockReason), '
            'o\'tkazib yuborildi ($reason)');
      }
      // Har daqiqada emas — har bir qulf egasi uchun bir marta.
      if (_lastBusyLoggedTicket != _ticket) {
        _lastBusyLoggedTicket = _ticket;
        await LogHelper.activity('SYNC_SKIPPED_BUSY', {
          'held_by': _lockReason,
          'held_s': _lockAge?.elapsed.inSeconds,
          'skipped': reason,
        });
      }
      return false;
    }

    final int myEpoch = _epoch;
    bool alive() => owns(ticket) && _epoch == myEpoch;

    try {
      final String token = Pref.getString(PrefKeys.token, '');
      if (token.isEmpty || token == 'not initialized') {
        return false;
      }

      // Kompaniya/do'kon id'siz so'rov ma'nosiz (server hammasini yoki
      // hech narsani qaytaradi) va narx filtri ishlamaydi — kursor
      // surilmasin.
      final String orgId = Pref.getString(PrefKeys.orgID, '');
      final String storeId = Pref.getString(PrefKeys.storeId, '');
      if (orgId.isEmpty || storeId.isEmpty) {
        await LogHelper.activity('SYNC_CONFIG_MISSING', {
          'orgID': orgId.isEmpty ? 'BO\'SH' : 'ok',
          'storeId': storeId.isEmpty ? 'BO\'SH' : 'ok',
        });
        return false;
      }

      await healCatalogState();

      // Server vaqti. Kassa soati noto'g'ri bo'lsa ham oyna server
      // bo'yicha hisoblanadi (qarang: server_clock.dart).
      final DateTime end = ServerClock.nowUtc();
      final Stopwatch sw = Stopwatch()..start();

      if (kDebugMode) {
        print('🔄 CatchUpSync boshlandi ($reason)');
      }

      // Tartib muhim: mahsulot o'z kategoriyasini lokal bazadan qidiradi,
      // shuning uchun kategoriyalar birinchi yangilanadi.
      bool ok = await const StreamSyncRunner(
        stream: SyncStream.categories,
        minInterval: slowStreamInterval,
      ).run(
        end: end,
        force: force || _categoriesRequested,
        fetch: (s, e) =>
            CategoriesWsService.getReceivedWS(mounted, context, s, e),
        fullReload: () async => await CategoryService.category() == null,
        shouldContinue: alive,
        beforeCommit: flushCatalogBoxes,
      );
      if (ok) _categoriesRequested = false;

      // Narx o'zgarishi (type 13) shu oqimda — cheklovsiz, har chaqiruvda.
      ok = await const StreamSyncRunner(stream: SyncStream.products).run(
            end: end,
            force: force,
            fetch: (s, e) =>
                ProductsWsService.getReceivedWS(mounted, context, s, e),
            fullReload: () => ProductsWsService.import(context),
            shouldContinue: alive,
            beforeCommit: flushCatalogBoxes,
          ) &&
          ok;

      // Diskontni bundan tashqari DiscountAutoSyncService ham har 10
      // daqiqada to'liq ro'yxat bilan tenglashtiradi — bu yerdagi
      // notification oqimi uzilishlarni qoplash uchun qoladi.
      ok = await const StreamSyncRunner(
            stream: SyncStream.discounts,
            minInterval: slowStreamInterval,
          ).run(
            end: end,
            force: force,
            fetch: (s, e) =>
                DiscountWsService.getReceivedWS(mounted, context, s, e),
            fullReload: () async => await DiscountService.discounts() == null,
            shouldContinue: alive,
            beforeCommit: flushCatalogBoxes,
          ) &&
          ok;

      if (!alive()) return false;

      if (ok) {
        // Bosh ekrandagi "oxirgi yangilanish" ko'rsatkichi shu kalitni
        // o'qiydi — endi u haqiqatan muvaffaqiyatli sinxron vaqtini
        // ko'rsatadi.
        await Pref.setInt(PrefKeys.lastSyncTime, end.millisecondsSinceEpoch);
        // Katalog kursordan to'liq yetib olindi — startup'dagi yiqilish
        // sabab qo'yilgan "baza yangilanmagan" ogohlantirishi endi
        // asossiz (ilgari kassir baribir qo'lda 43 MB yuklashga majbur edi).
        await CatalogRefreshNotice.clearPending();
      } else {
        await LogHelper.activity('SYNC_RUN_INCOMPLETE',
            {'reason': reason, 'ms': sw.elapsedMilliseconds});
      }

      _refreshUi(context, mounted);

      if (kDebugMode) {
        print('${ok ? '✅' : '⚠️'} CatchUpSync tugadi ($reason), ok=$ok');
      }
      return ok;
    } catch (e, stack) {
      // Kutilmagan xato (masalan Hive yozuvi). Chaqiruvchiga yetkazmaymiz:
      // avto-sinxron halqasi shu yerda o'lib, internet o'zgarguncha
      // tirilmasdi.
      await LogHelper.activity(
          'SYNC_CRASH', {'reason': reason, 'error': e, 'stack': stack});
      return false;
    } finally {
      _release(ticket);

      // Startup'dagi to'liq yuklash yiqilgan bo'lsa kassirga ogohlantirish
      // chiqaramiz. Bu nuqta ilova ochilganda, tarmoq tiklanganda va har
      // davriy tsiklda o'tiladi — ya'ni internet qaytishi bilan ko'rinadi.
      //
      // Ataylab `await` qilinmaydi: dialog modal, kassir uni yopmaguncha
      // kutib turilsa qulf band bo'lib qolardi va sinxron shu vaqt
      // davomida butunlay to'xtab turardi.
      unawaited(CatalogRefreshNotice.maybeShow());
    }
  }

  /// Lokal katalog holati kursorga mos kelmasa kursorni tashlaydi —
  /// keyingi runner to'liq yuklaydi.
  ///
  /// Holatlar: to'liq yozuv (clearAndPutItems) o'rtada uzilgan (marker
  /// qolgan); items/categories box bo'sh (Hive buzilgan faylni jimgina
  /// bo'shatib ochadi) — kursor esa "hammasi bor" deb turardi.
  static Future<void> healCatalogState() async {
    try {
      if (Pref.getBool(PrefKeys.catalogWriteInProgress, false)) {
        await SyncCursor.reset(SyncStream.products,
            reason: 'to\'liq katalog yozuvi tugamagan');
        await Pref.setBool(PrefKeys.catalogWriteInProgress, false);
      }
      if (HiveBoxes.getProducts().isEmpty) {
        await SyncCursor.reset(SyncStream.products, reason: 'items box bo\'sh');
      }
      if (HiveBoxes.getCategories().isEmpty) {
        await SyncCursor.reset(SyncStream.categories,
            reason: 'categories box bo\'sh');
      }
    } catch (e) {
      await LogHelper.activity('SYNC_HEAL_ERROR', {'error': e});
    }
  }

  /// Kursor yozilishidan oldin ma'lumot diskka tushsin: kursor va
  /// ma'lumot turli fayllarda (prefs.hive / items.hive); Hive o'zi fsync
  /// qilmaydi — svet o'chsa kursor saqlanib, ma'lumot yo'qolishi mumkin edi.
  static Future<void> flushCatalogBoxes() async {
    try {
      await HiveBoxes.getProducts().flush();
      await HiveBoxes.getCategories().flush();
      await HiveBoxes.getDiscounts().flush();
    } catch (_) {
      // flush yiqilsa ham sinxron to'xtamasin — bu qo'shimcha himoya.
    }
  }

  /// [body] ni sinxron qulfi ostida bajaradi — qo'lda/startup to'liq
  /// yuklashlar va logout uchun. Davriy sinxron shu vaqtda o'tkazib
  /// yuboriladi.
  ///
  /// Joriy sinxron tugashini [exclusiveMaxWait] gacha kutadi; shundan
  /// keyin [forceAfterWait] true bo'lsa baribir davom etadi (kassir bosgan
  /// yangilash javobsiz qolmasin — eski run `shouldContinue` orqali
  /// to'xtaydi), false bo'lsa qulf bo'shaguncha kutaveradi (startup kabi
  /// odam kutmaydigan ishlar uchun).
  static Future<T> exclusive<T>(
    Future<T> Function() body, {
    String reason = 'manual-full-update',
    bool forceAfterWait = true,
  }) async {
    final Stopwatch sw = Stopwatch()..start();
    int? ticket = _tryAcquire(reason);
    while (ticket == null && (!forceAfterWait || sw.elapsed < exclusiveMaxWait)) {
      await Future.delayed(const Duration(milliseconds: 250));
      ticket = _tryAcquire(reason);
    }
    if (ticket == null) {
      await LogHelper.activity('SYNC_LOCK_FORCED',
          {'held_by': _lockReason, 'taken_by': reason});
      ticket = _take(reason);
    }
    try {
      return await body();
    } finally {
      _release(ticket);
    }
  }

  /// Qulf bo'sh bo'lsagina [body] ni bajaradi, band bo'lsa null (kutmaydi).
  /// Davriy fon ishlari uchun (masalan diskont avto-sinxroni).
  static Future<T?> tryExclusive<T>(
    Future<T> Function() body, {
    String reason = 'background',
  }) async {
    final int? ticket = _tryAcquire(reason);
    if (ticket == null) return null;
    try {
      return await body();
    } finally {
      _release(ticket);
    }
  }

  static void _refreshUi(BuildContext context, bool mounted) {
    if (!mounted || !context.mounted) return;
    try {
      context.read<HomeBloc>().add(HomeSyncEvent());
    } catch (_) {
      // HomeBloc bu context daraxtida bo'lmasligi mumkin — sinxronning
      // o'zi bundan to'xtamasligi kerak.
    }
  }
}
