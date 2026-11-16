/*
    Vozvratni BOSHLASHDAN OLDINGI tekshiruv (fiskal chekdan oldin).

    Nima uchun kerak: vozvrat sahifasi ochilganda qoldiq bir marta hisoblanadi
    va keyin yangilanmaydi. Sahifa ochiq turgan paytda shu chek bo'yicha boshqa
    vozvrat bajarilsa (ustma-ust ochilgan ikkinchi sahifa, boshqa kassa,
    adminka) — eskirgan sahifadan yana vozvrat qilinardi: fiskal chek chiqib,
    server "refund amount is greater than expected amount" bilan rad etardi.

    Bu yerda faqat sof hisob — tarmoq va ObjectBox `ReturnBlocDeps` orqali.
*/

import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class RefundPreflight {
  RefundPreflight._();

  static const double _eps = 1e-6;

  /// Sahifa ochilgandan KEYIN shu chek bo'yicha lokal vozvrat saqlanganmi.
  /// Ha bo'lsa sahifadagi qoldiq eskirgan.
  static bool isPageStale({
    required int? pageOpenedAt,
    required List<ReceiptModel4> localRefunds,
  }) {
    if (pageOpenedAt == null) return false;
    return localRefunds.any((r) => r.date >= pageOpenedAt);
  }

  /// So'ralgan miqdor server qoldig'idan oshgan birinchi qator (yo'q bo'lsa
  /// `null`).
  ///
  /// [serverRemaining] — `order item id → qoldiq (dona)`. Serverga hali
  /// yetmagan lokal vozvratlar ([localRefunds] ichida `uploaded == false`)
  /// qoldiqdan ayiriladi. Server ro'yxatida yo'q id tekshirilmaydi.
  static ReceiptModelSoldItem4? firstOverdrawn({
    required List<ReceiptModelSoldItem4> requested,
    required Map<String, double> serverRemaining,
    required List<ReceiptModel4> localRefunds,
  }) {
    final Map<String, double> pending = {};
    for (final refund in localRefunds) {
      if (refund.uploaded) continue;
      for (final it in refund.soldItemList) {
        final id = it.refundItemId ?? '';
        if (id.isEmpty) continue;
        pending[id] = (pending[id] ?? 0) + it.value;
      }
    }
    final Map<String, double> asked = {};
    for (final it in requested) {
      final id = it.refundItemId ?? '';
      if (id.isEmpty) continue;
      asked[id] = (asked[id] ?? 0) + it.value;
    }
    for (final it in requested) {
      final id = it.refundItemId ?? '';
      final double? remaining = serverRemaining[id];
      if (id.isEmpty || remaining == null) continue;
      if (asked[id]! > remaining - (pending[id] ?? 0) + _eps) return it;
    }
    return null;
  }
}
