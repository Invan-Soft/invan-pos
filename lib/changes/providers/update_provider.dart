// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
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
  Future<void> startPeriodicRequest(BuildContext context, bool mounted) async {
    if (!mounted) return;
    if ((await Connectivity().checkConnectivity()) == ConnectivityResult.none) {
      return;
    }
    if (!context.mounted) return;

    await CatchUpSync.run(context, mounted, reason: 'auto-sync');
  }

  Future<String?> fullUpdateItems() async =>
      await UtilFunctions.fullUpdateProduct();

  Future<String?> fullUpdateEmployee() async =>
      await UtilFunctions.fullUpdateEmployee();
}
