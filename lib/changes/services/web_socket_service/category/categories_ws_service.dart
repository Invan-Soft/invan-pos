// ignore_for_file: use_build_context_synchronously, invalid_use_of_protected_member

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../features/features.dart';
import '../../log_helper.dart';
import '../../sync/notification_fetch.dart';
import '../../sync/sync_cursor.dart';
import '../product/products_ws_service.dart';

/*
    Kategoriya oqimi: 10 — yaratish, 11 — yangilash, 12 — o'chirish.
    So'rov/tartiblash/xatoga chidamlilik NotificationFetch'da.
*/
class CategoriesWsService {
  CategoriesWsService._();

  static const int limit = NotificationFetch.limit;

  static const String types = '10,11,12';

  static Future<SyncFetchResult> getReceivedWS(bool mounted,
      BuildContext context, String startDate, String endDate) async {
    try {
      return await NotificationFetch.run(
        label: 'Category',
        types: types,
        startDate: startDate,
        endDate: endDate,
        apply: _apply,
        afterBatch: ProductsWsService.refreshCaches,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        print('❌ Category notification xatosi: $e');
      }
      await LogHelper.activity('SYNC_FETCH_CRASH',
          {'stream': 'Category', 'error': e, 'stack': stack});
      return const SyncFetchResult.failed();
    }
  }

  static Future<NotifyApply> _apply(Map<String, dynamic> ws) async {
    final dynamic rawType = ws['type'];
    final int? type = rawType is int ? rawType : int.tryParse('$rawType');
    final dynamic data = ws['data'];

    switch (type) {
      case 10:
        await CategorySingleton.putCategories([CategoryData.fromJson(_asMap(data))]);
        return NotifyApply.applied;
      case 11:
        await CategorySingleton.editCategory(CategoryData.fromJson(_asMap(data)));
        return NotifyApply.applied;
      case 12:
        final String id = data is Map ? (data['id']?.toString() ?? '') : '';
        if (id.isEmpty) throw const FormatException('kategoriya id yo\'q');
        await CategorySingleton.deleteCategories(id);
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
