/*
    Shorebird patch'larini BITTA ochilishda qo'llash.

    Nima uchun kerak: Shorebird o'zi patch'ni fonda yuklaydi va faqat KEYINGI
    ishga tushirishda qo'llaydi — kassir dasturni ikki marta yopib ochishi
    kerak bo'lardi. Bu servis:

    1. `applyOnStartup` — main() boshida, oyna ko'rinmasidan va bazalar
       ochilmasidan OLDIN: yangi patch (yoki rollback) bo'lsa yuklab oladi va
       dasturni darhol qayta ishga tushiradi. Vaqt chegaralangan — internet
       yo'q/sekin bo'lsa dastur odatdagidek ochiladi.
    2. `start` — ish vaqtida davriy tekshiradi, internet (server) qaytgan
       zahoti ham — startup'da oflayn bo'lib o'tkazib yuborilgan patch shu
       yerda ushlanadi. Patch tayyor bo'lsa dastur
       O'ZI qayta yonmaydi (sotuv o'rtasida xavfli) — `readyToRestart` orqali
       yuqorida tugma chiqadi, kassir savat bo'shligida bosadi.

    Debug yoki `shorebird release` siz build'da `isAvailable == false` —
    hech narsa qilmaydi.
*/

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class PatchUpdater {
  PatchUpdater._();

  static final ShorebirdUpdater _updater = ShorebirdUpdater();

  /// Ish vaqtida patch yuklab bo'lindi — qayta ishga tushirish tugmasi.
  static final ValueNotifier<bool> readyToRestart = ValueNotifier<bool>(false);

  /// Startup'da kutishning yuqori chegarasi. Oyna shu vaqt ko'rinmaydi
  /// (BDW_HIDE_ON_STARTUP), shuning uchun qisqa bo'lishi shart.
  static const Duration _startupBudget = Duration(seconds: 8);
  static const Duration _interval = Duration(minutes: 10);

  static Timer? _timer;
  static bool _busy = false;

  /// main() boshida chaqiriladi. Patch tayyor bo'lsa QAYTMAYDI (jarayon
  /// yangisi bilan almashadi).
  static Future<void> applyOnStartup() async {
    if (!_updater.isAvailable) return;
    try {
      final bool ready = await _downloadIfAny().timeout(_startupBudget);
      if (ready) await _relaunch();
    } catch (_) {
      // Tarmoq/vaqt xatosi — dastur odatdagidek ochiladi, fon tekshiruvi
      // keyinroq qayta urinadi.
    }
  }

  /// runApp() dan keyin — fon tekshiruvini boshlaydi.
  static void start() {
    if (!_updater.isAvailable || _timer != null) return;
    _timer = Timer.periodic(_interval, (_) => _checkInBackground());
    Timer(const Duration(minutes: 1), _checkInBackground);
    BackendHealth.status.addListener(_onConnectivityChanged);
  }

  /// Oflayn → onlayn: 10 daqiqalik davrni kutmasdan darhol tekshiradi.
  static void _onConnectivityChanged() {
    if (BackendHealth.status.value == BackendStatus.up) _checkInBackground();
  }

  /// Kassir tugmani bosganda (savat bo'sh bo'lishi kerak — chaqiruvchi
  /// tekshiradi). Oyna yopilgandagi kabi holat saqlanadi, keyin qayta yonadi.
  static Future<void> restartNow() async {
    try {
      await Pref.setString(PrefKeys.appClosedTime,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
      await Pref.setBool(PrefKeys.isFirstTime, true);
      await Hive.close();
    } catch (_) {
      // Saqlash xatosi qayta ishga tushirishni to'xtatmasin.
    }
    await _relaunch();
  }

  static Future<void> _checkInBackground() async {
    if (_busy || readyToRestart.value) return;
    _busy = true;
    try {
      if (await _downloadIfAny()) readyToRestart.value = true;
    } catch (_) {
      // Keyingi davrda qayta uriniladi.
    } finally {
      _busy = false;
    }
  }

  /// `true` — yangi patch diskda (yoki joriy patch rollback qilingan) va
  /// qayta ishga tushirish kerak.
  ///
  /// Shorebird'ning avtomatik yuklovchisi ishga tushganda parallel ishlaydi;
  /// u holda `update()` darhol qaytadi (UPDATE_IN_PROGRESS), shuning uchun
  /// holat `outdated` dan chiqquncha qayta so'raladi.
  static Future<bool> _downloadIfAny() async {
    // ~40 × 0.7 s — avtomatik yuklovchi osilib qolsa ham cheksiz aylanmaydi.
    for (int attempt = 0; attempt < 40; attempt++) {
      final UpdateStatus status = await _updater.checkForUpdate();
      switch (status) {
        case UpdateStatus.restartRequired:
          return true;
        case UpdateStatus.upToDate:
        case UpdateStatus.unavailable:
          return false;
        case UpdateStatus.outdated:
          await _updater.update();
          await Future<void>.delayed(const Duration(milliseconds: 700));
      }
    }
    return false;
  }

  static Future<void> _relaunch() async {
    await Process.start(
      Platform.resolvedExecutable,
      const <String>[],
      mode: ProcessStartMode.detached,
      workingDirectory: File(Platform.resolvedExecutable).parent.path,
    );
    exit(0);
  }
}
