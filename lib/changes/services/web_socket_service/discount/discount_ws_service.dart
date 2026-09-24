// ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/changes/services/sync/notification_fetch.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';

import '../../../../features/get_discounts/get_discounts.dart';

/*
    Diskont oqimi: 15 — yaratish, 16 — yangilash, 17 — o'chirish.
    So'rov/tartiblash/xatoga chidamlilik NotificationFetch'da.

    Bundan tashqari DiscountAutoSyncService har 10 daqiqada to'liq ro'yxat
    bilan tenglashtiradi — bu oqim uzilishlarni tezroq qoplash uchun.
*/
class DiscountWsService {
  DiscountWsService._();

  static const int limit = NotificationFetch.limit;

  static const String types = '15,16,17';

  static Future<SyncFetchResult> getReceivedWS(bool mounted,
      BuildContext context, String startDate, String endDate) async {
    try {
      return await NotificationFetch.run(
        label: 'Discount',
        types: types,
        startDate: startDate,
        endDate: endDate,
        apply: _apply,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Discount notification xatosi: $e');
      }
      await LogHelper.activity('SYNC_FETCH_CRASH',
          {'stream': 'Discount', 'error': e, 'stack': stack});
      return const SyncFetchResult.failed();
    }
  }

  static Future<NotifyApply> _apply(Map<String, dynamic> ws) async {
    final dynamic rawType = ws['type'];
    final int? type = rawType is int ? rawType : int.tryParse('$rawType');
    final dynamic data = ws['data'];

    // Ilgari bu chaqiruvlar `await`siz edi: Hive yozuvi yiqilsa xato
    // yutilar, kursor esa baribir surilardi.
    switch (type) {
      case 15:
        await DiscountService.createDiscount(DiscountItem.fromJson(_asMap(data)));
        return NotifyApply.applied;
      case 16:
        await DiscountService.updateDiscount(DiscountItem.fromJson(_asMap(data)));
        return NotifyApply.applied;
      case 17:
        final String id = data is Map ? (data['id']?.toString() ?? '') : '';
        if (id.isEmpty) throw const FormatException('diskont id yo\'q');
        await DiscountService.deleteDiscount(id);
        return NotifyApply.applied;
      default:
        return NotifyApply.ignored;
    }
  }

  static Map<String, dynamic> _asMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    throw const FormatException('notification data bo\'sh');
  }
}
