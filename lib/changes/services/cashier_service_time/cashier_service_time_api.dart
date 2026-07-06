import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/cashier_service_time_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';

/// Xizmat vaqti yozuvini backend'ga yuboradi.
///
/// MUHIM: bu chaqiruv sotuv oqimini HECH QACHON to'xtatmaydi — barcha
/// xatolar shu yerda yutiladi va faqat telegram'ga (LogRepository orqali)
/// orqa fonda jo'natiladi.
class CashierServiceTimeApi {
  const CashierServiceTimeApi();

  Future<void> send(CashierServiceTimeModel record) async {
    try {
      final payload = jsonEncode(record.toJson());

      // TODO(API): endpoint tayyor bo'lganda shu yerga POST qo'shiladi:
      //   final result = await ApiProvider.postResponse(
      //     path: '<service-time-endpoint>', body: payload);
      //   if (result is Failure) throw Exception(result.message);
      // Hozircha API yo'q — payload debug console'ga chiqariladi.
      debugPrint('🕒 KASSIR XIZMAT VAQTI (API-ga tayyor payload): $payload');
    } catch (e) {
      await LogRepository.addLog(
        'Kassir xizmat vaqtini yuborishda xato: $e',
        where: 'cashier_service_time',
        file: 'cashier_service_time_api.dart',
        method: 'POST',
        checkNo: record.checkNumber,
      );
    }
  }
}
