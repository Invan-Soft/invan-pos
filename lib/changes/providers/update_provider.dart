// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:invan2/changes/services/sync/catch_up_sync.dart';
import 'package:invan2/utils/util_functions.dart';
import 'package:invan2/utils/utils.dart';
import 'package:flutter/material.dart';

class UpdateProvider extends ChangeNotifier {
  bool _autoUpdateRunning = false;

  /// Fon rejimidagi davriy sinxron.
  ///
  /// NetworkSuccess har safar kelganda chaqirilishi mumkin, shuning uchun
  /// bir vaqtda bittadan ortiq halqa ishlamasligi ta'minlangan (ilgari har
  /// bir qayta ulanishda yangi cheksiz halqa qo'shilib borardi).
  Future<void> autoUpdate(BuildContext context, bool mounted) async {
    if (_autoUpdateRunning) return;

    final int interval = Pref.getInt(PrefKeys.autoSyncInterval, 1);
    if (interval <= 0) return;

    _autoUpdateRunning = true;
    final Duration period = Duration(minutes: interval);

    try {
      while (true) {
        await Future.delayed(period);
        await startPeriodicRequest(context, mounted);
      }
    } finally {
      _autoUpdateRunning = false;
    }
  }

  /// Bir marta sinxron: qayerdan boshlashni SyncCursor hal qiladi,
  /// shuning uchun bu yerda vaqt oynasi hisoblanmaydi.
  ///
  /// Ilgari bu yerda `connectivity_plus` bilan oldindan tarmoq tekshiruvi bor
  /// edi. U olib tashlandi: Windows'da `checkConnectivity()` adapterni emas,
  /// Windows'ning NCSI hukmini (`IsConnectedToInternet`) qaytaradi. Do'kon
  /// tarmog'ida Microsoft probe'lari bloklangan bo'lsa (DNS filtri, firewall,
  /// proxy) Windows "internet yo'q" deydi, API esa mukammal ishlayveradi —
  /// natijada davriy sinxron shu mashinada jimgina, izsiz o'chib qolardi.
  ///
  /// Tekshiruv hech qanday himoya bermasdi: internet haqiqatan yo'q bo'lsa
  /// so'rov timeout bo'ladi va `SyncFetchResult.failed()` qaytadi, ya'ni
  /// kursor joyida qoladi va o'sha oyna keyingi urinishda qaytadan so'raladi.
  Future<void> startPeriodicRequest(BuildContext context, bool mounted) async {
    if (!mounted) return;
    if (!context.mounted) return;

    await CatchUpSync.run(context, mounted, reason: 'auto-sync');
  }

  Future<String?> fullUpdateItems() async =>
      await UtilFunctions.fullUpdateProduct();

  Future<String?> fullUpdateEmployee() async =>
      await UtilFunctions.fullUpdateEmployee();
}
