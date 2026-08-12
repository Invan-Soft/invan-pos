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
*/

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../features/get_categories/service/category_service.dart';
import '../../../features/home/bloc/home_bloc/home_bloc.dart';
import '../../../utils/constants/pref_keys.dart';
import '../../../utils/helpers/prefs.dart';
import '../discount_service.dart';
import '../web_socket_service/category/categories_ws_service.dart';
import '../web_socket_service/discount/discount_ws_service.dart';
import '../web_socket_service/product/products_ws_service.dart';
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

  static bool _running = false;

  static bool get isRunning => _running;

  /// Barcha oqimlarni kursordan hozirgi vaqtgacha yetkazadi.
  ///
  /// [force] — sekin oqimlarning 10 daqiqalik cheklovini chetlab o'tadi.
  ///
  /// Qaytadi: hamma oqim to'liq sinxronlandimi.
  static Future<bool> run(
    BuildContext context,
    bool mounted, {
    String reason = '',
    bool force = false,
  }) async {
    if (_running) {
      if (kDebugMode) {
        print('⏭️ Sinxron allaqachon ketmoqda, o\'tkazib yuborildi ($reason)');
      }
      return false;
    }

    final String token = Pref.getString(PrefKeys.token, '');
    if (token.isEmpty || token == 'not initialized') {
      return false;
    }

    _running = true;
    final DateTime end = DateTime.now().toUtc();

    try {
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
        force: force,
        fetch: (s, e) =>
            CategoriesWsService.getReceivedWS(mounted, context, s, e),
        fullReload: () async => await CategoryService.category() == null,
      );

      // Narx o'zgarishi (type 13) shu oqimda — cheklovsiz, har chaqiruvda.
      ok = await const StreamSyncRunner(stream: SyncStream.products).run(
            end: end,
            force: force,
            fetch: (s, e) =>
                ProductsWsService.getReceivedWS(mounted, context, s, e),
            fullReload: () => ProductsWsService.import(context),
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
          ) &&
          ok;

      if (ok) {
        // Bosh ekrandagi "oxirgi yangilanish" ko'rsatkichi shu kalitni
        // o'qiydi — endi u haqiqatan muvaffaqiyatli sinxron vaqtini
        // ko'rsatadi.
        await Pref.setInt(PrefKeys.lastSyncTime, end.millisecondsSinceEpoch);
      }

      _refreshUi(context, mounted);

      if (kDebugMode) {
        print('${ok ? '✅' : '⚠️'} CatchUpSync tugadi ($reason), ok=$ok');
      }
      return ok;
    } finally {
      _running = false;
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
