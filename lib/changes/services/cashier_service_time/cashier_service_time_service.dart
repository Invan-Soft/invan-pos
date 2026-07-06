import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/cashier_service_time_model.dart';
import 'package:invan2/changes/services/cashier_service_time/cashier_service_time_api.dart';
import 'package:invan2/changes/services/cashier_service_time/cashier_service_time_tracker.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

/// Kassir xizmat vaqtini o'lchash facade'i — provider faqat shu klass
/// bilan gaplashadi (tracker va api ichki detallar).
///
/// Oqim:
///  - savatga mahsulot qo'shilganda `onProductAdded` → start belgilanadi;
///  - sotuv muvaffaqiyatli yakunlanganda `onSaleCompleted` → yozuv yig'ilib,
///    orqa fonda (fire-and-forget) API'ga jo'natiladi.
class CashierServiceTimeService {
  CashierServiceTimeService._(this._tracker, this._api);

  static final CashierServiceTimeService instance = CashierServiceTimeService._(
    CashierServiceTimeTracker.instance,
    const CashierServiceTimeApi(),
  );

  final CashierServiceTimeTracker _tracker;
  final CashierServiceTimeApi _api;

  void onProductAdded(int clientNumber) {
    _tracker.markStarted(clientNumber);
  }

  /// Chek yopilgach chaqiriladi (externalId allaqachon berilgan bo'lishi
  /// kerak — ya'ni ReceiptSingleton4.toOBJECTBOX'dan KEYIN).
  void onSaleCompleted({
    required int clientNumber,
    required ReceiptModel4 receipt,
  }) {
    final startedTime = _tracker.takeStartedTime(clientNumber);
    if (startedTime == null) {
      debugPrint(
          '🕒 KASSIR XIZMAT VAQTI: slot $clientNumber uchun start topilmadi, '
          'yozuv o\'tkazib yuborildi (chek: ${receipt.externalId})');
      return;
    }

    final record = CashierServiceTimeModel(
      startedTime: startedTime,
      closedTime: DateTime.now(),
      checkNumber: receipt.externalId,
      cashierId: receipt.cashierId,
      cashierName: receipt.cashierName,
      cashboxId: receipt.cashboxId,
      clientId: receipt.clientId,
      clientName: receipt.clientName,
      clientPhone: receipt.clientPhone,
    );

    // Sotuv oqimini kutdirmaymiz — orqa fonda jo'natiladi, xatolar
    // CashierServiceTimeApi ichida yutilib telegram'ga ketadi.
    unawaited(_api.send(record));
  }
}
