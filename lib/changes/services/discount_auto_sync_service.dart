import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invan2/changes/services/log_helper.dart';

import '../../features/get_discounts/get_discounts.dart';
import '../../features/hive_repository/hive_boxes.dart';
import '../../utils/utils.dart';

/// Kompaniya diskontlarini har 10 daqiqada fonda serverdan olib, lokal
/// Hive box bilan JIMGINA sinxronlaydi. Hech qanday dialog/UI ko'rsatmaydi,
/// sotuv oqimiga aralashmaydi.
///
/// Nega kerak: diskontlar odatda WebSocket (type 15/16/17) orqali jonli
/// keladi, lekin WS uzilib qolsa yoki xabar yo'qolsa, yangi diskont kassaga
/// yetib bormaydi. Bu servis 10 daqiqalik to'liq ro'yxat bilan buni qoplaydi.
///
/// Xavfsizlik qoidalari ("boshqa narsalarga ta'sir qilmasin"):
///  - `DiscountService.discounts()` dagi kabi `box.clear()` ISHLATILMAYDI —
///    diff-merge qilinadi: yangi → qo'shiladi, mavjud → yangilanadi,
///    serverda yo'q → o'chiriladi (WS type 17 semantikasi bilan bir xil).
///  - `onDiscountsCleared` (savatdagi chegirma effektlarini tozalaydigan
///    callback) ATAYIN chaqirilmaydi — joriy savat tegilmaydi.
///  - Serverdan muvaffaqiyatli javob kelganda lokal ro'yxat server bilan
///    AYNAN tenglashtiriladi: responseda qaytmagan diskont = o'chirilgan,
///    lokaldan ham o'chiriladi (bo'sh ro'yxat bo'lsa ham). Server bir marta
///    xato bo'sh qaytarsa, keyingi tsiklda diskontlar qaytadan yozib olinadi.
///  - Xatolar yutiladi va faqat logga yoziladi — keyingi tsiklda qayta urinadi.
class DiscountAutoSyncService {
  DiscountAutoSyncService._();

  static final DiscountAutoSyncService instance = DiscountAutoSyncService._();

  static const Duration _interval = Duration(minutes: 10);

  Timer? _timer;
  bool _syncing = false;

  /// Idempotent: qayta chaqirilsa ikkinchi timer yaratmaydi.
  /// Token hali yo'q bo'lsa ham xavfsiz — har tsikl boshida guard bor.
  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(_interval, (_) => _syncNow());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _syncNow() async {
    if (_syncing) {
      debugPrint('🔖 DISKONT AVTO-SYNC: oldingi tsikl hali tugamagan — skip');
      return;
    }

    final token = Pref.getString(PrefKeys.token, '');
    final shopId = Pref.getString(PrefKeys.storeId, '');
    if (token.isEmpty || shopId.isEmpty) {
      debugPrint('🔖 DISKONT AVTO-SYNC: token/shop hali yo\'q — skip');
      return;
    }

    debugPrint('🔖 DISKONT AVTO-SYNC: boshlandi (${DateTime.now()})');
    _syncing = true;
    try {
      final httpResult = await DiscountService.findDiscounts();
      if (!httpResult.isSuccess) {
        // jim — keyingi tsiklda yana urinadi
        debugPrint('🔖 DISKONT AVTO-SYNC: so\'rov muvaffaqiyatsiz — skip '
            '(${httpResult.getError})');
        return;
      }

      final discountsResponse = DiscountsResponse.fromJson(httpResult.result);
      final serverItems = discountsResponse.data ?? const <DiscountItem>[];
      final box = HiveBoxes.getDiscounts();

      // Serverdan kelgan javobni to'liq ko'rsatamiz
      debugPrint('🔖 DISKONT AVTO-SYNC: serverdan ${serverItems.length} ta diskont keldi:');
      for (final item in serverItems) {
        debugPrint('   📥 ${item.name ?? item.displayName ?? '(nomsiz)'} '
            '[id: ${item.id}]');
      }

      int added = 0;
      int updated = 0;
      final serverIds = <dynamic>{};
      for (final item in serverItems) {
        serverIds.add(item.id);
        final itemName = item.name ?? item.displayName ?? '(nomsiz)';
        if (box.containsKey(item.id)) {
          updated++;
        } else {
          added++;
          debugPrint('   🆕 "$itemName" bizda YO\'Q edi → localga yozildi '
              '[id: ${item.id}]');
        }
        await box.put(item.id, item);
      }

      int deleted = 0;
      for (final key in box.keys.toList()) {
        if (!serverIds.contains(key)) {
          final removed = box.get(key);
          debugPrint('   🗑 "${removed?.name ?? removed?.displayName ?? key}" '
              'serverda YO\'Q → localdan o\'chirildi [id: $key]');
          await box.delete(key);
          deleted++;
        }
      }

      debugPrint('🔖 DISKONT AVTO-SYNC: tugadi — serverdan ${serverItems.length} ta, '
          'yangi: $added, yangilandi: $updated, o\'chirildi: $deleted '
          '(lokalda jami: ${box.length})');

      if (added > 0 || deleted > 0) {
        LogHelper.activity('DISCOUNT_AUTO_SYNC',
            {'added': added, 'updated': updated, 'deleted': deleted});
      }
    } catch (e) {
      debugPrint('🔖 DISKONT AVTO-SYNC XATO: $e');
      LogHelper.activity('DISCOUNT_AUTO_SYNC_ERROR', {'error': e});
    } finally {
      _syncing = false;
    }
  }
}
