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
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/changes/services/patch_reporter.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
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

  /// Startup'dagi bitta server tekshiruvining chegarasi. Odatda ~0.4 s;
  /// shundan uzoq — tarmoq osilgan (Wi-Fi bor, internet yo'q).
  static const Duration _checkCap = Duration(seconds: 3);
  static const Duration _interval = Duration(minutes: 10);

  static Timer? _timer;
  static bool _busy = false;
  static bool _restarting = false;

  /// Qayta ishga tushirilgan jarayonga beriladi — u startup tekshiruvini
  /// takrorlamaydi (patch "kutilmoqda" bo'lib qolsa cheksiz qayta yonish va
  /// har safar 8 s yashirin oyna bo'lmasin).
  static const String relaunchedEnv = 'INVAN_PATCH_RELAUNCHED';

  /// Shu jarayon yangilanish uchun O'ZI qayta ishga tushirilganmi (startup'da
  /// patch qo'llanganda yoki "Yangilanish tayyor" tugmasi bosilganda) —
  /// kassirga "Dastur yangilandi" deb aytish uchun.
  static bool get relaunchedForUpdate =>
      Platform.environment[relaunchedEnv] == '1';

  /// main() boshida chaqiriladi. Patch tayyor bo'lsa QAYTMAYDI (jarayon
  /// yangisi bilan almashadi).
  ///
  /// Muhim: dastur ochilganda Shorebird'ning O'Z avtomatik yuklovchisi ham
  /// (shorebird.yaml `auto_update`) xuddi shu patch'ni parallel yuklaydi.
  /// Ilgari bu poyga paytida tekshiruv tsikli birinchi muvaffaqiyatsiz
  /// chaqiruvdayoq to'xtardi — patch yuklanardi-yu, dastur qayta yonmasdi
  /// (Mac sinovi, 2026-10-02: kassir ikki marta ochishi yoki tugmani bosishi
  /// kerak bo'lardi). Endi tsikl vaqt chegarasigacha davom etadi, har bir
  /// chaqiruv xatosi qayta urinish bilan o'tkaziladi va diskdagi tayyor patch
  /// tarmoqsiz aniqlanadi.
  static Future<void> applyOnStartup() async {
    if (!_updater.isAvailable) {
      _log('startup: Shorebird updater mavjud emas');
      return;
    }
    if (Platform.environment[relaunchedEnv] == '1') {
      _log('startup: qayta ishga tushirilgan jarayon — tekshiruv yo\'q, '
          'boot patch=${await _bootPatchText()}');
      return;
    }
    final Stopwatch sw = Stopwatch()..start();
    _busy = true;
    try {
      _log('startup: boshlandi, boot patch=${await _bootPatchText()}');
      final bool ready = await _waitForPatchOnStartup(sw);
      _log('startup: ${ready ? "patch tayyor — QAYTA ISHGA TUSHIRILADI" : "yangi patch yo'q"} '
          '(${sw.elapsedMilliseconds} ms)');
      if (ready) await _relaunch();
    } catch (e) {
      // Kutilmagan xato — dastur odatdagidek ochiladi, fon tekshiruvi
      // keyinroq qayta urinadi.
      _log('startup: xato $e (${sw.elapsedMilliseconds} ms)');
      PatchReporter.error('startup', e);
    } finally {
      _busy = false;
    }
  }

  /// Startup byudjeti ichida patch'ni kutadi. `true` — patch diskda,
  /// qayta ishga tushirish kerak.
  static Future<bool> _waitForPatchOnStartup(Stopwatch sw) async {
    int errorsInARow = 0;
    while (sw.elapsed < _startupBudget) {
      // 1) Tarmoqsiz: avtomatik yuklovchi patch'ni allaqachon diskka
      //    yozib bo'lganmi.
      if (await _restartNeededLocally()) return true;

      // 2) Server bilan. Har tekshiruv [_checkCap] bilan cheklanadi: Wi-Fi
      //    bor-u internet "osilgan" bo'lsa so'rov javobsiz qoladi — startup
      //    byudjet oxirigacha kutmasin.
      final Duration left = _startupBudget - sw.elapsed;
      final Duration cap = left < _checkCap ? left : _checkCap;
      final Stopwatch call = Stopwatch()..start();
      final UpdateStatus? status = await _safeCheck(timeout: cap);
      _log('startup: holat=${status?.name ?? "xato"} '
          '(${sw.elapsedMilliseconds} ms)');
      switch (status) {
        case UpdateStatus.restartRequired:
          return true;
        case UpdateStatus.unavailable:
          return false;
        case UpdateStatus.outdated:
          errorsInARow = 0;
          // Avtomatik yuklovchi ishlayotgan bo'lsa darhol qaytadi.
          await _safeUpdate(timeout: _startupBudget - sw.elapsed);
          break;
        case UpdateStatus.upToDate:
          // Yangi patch yo'q (internet yo'q bo'lsa ham Shorebird shunday
          // deydi). Avtomatik yuklovchi patch'ni hozirgina diskka yozgan
          // bo'lishi mumkin — ikkinchi TARMOQ so'rovi o'rniga qisqa lokal
          // tekshiruv (oddiy ochilish ~0.8 s tezroq).
          await Future<void>.delayed(const Duration(milliseconds: 300));
          return await _restartNeededLocally();
        case null:
          // Vaqt tugadi — tarmoq osilgan: qayta urinish ma'nosiz.
          if (call.elapsed >= cap) return await _restartNeededLocally();
          // Chaqiruv xatosi. Bittasi — avtomatik yuklovchi bilan poyga
          // bo'lishi mumkin, qayta urinamiz. Ketma-ket ikkinchisi — kutish
          // ma'nosiz, kassa darhol ochilsin.
          if (++errorsInARow >= 2) return await _restartNeededLocally();
          break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 400));
    }
    return await _restartNeededLocally();
  }

  /// Diskdagi keyingi patch joriysidan farq qiladimi (yangi patch yuklangan
  /// yoki joriy patch bekor qilingan). Tarmoqqa chiqmaydi.
  static Future<bool> _restartNeededLocally() async {
    try {
      final Patch? current = await _updater.readCurrentPatch();
      final Patch? next = await _updater.readNextPatch();
      return current?.number != next?.number;
    } catch (e) {
      _log('lokal patch holatini o\'qib bo\'lmadi: $e');
      PatchReporter.error('readPatch', e);
      return false;
    }
  }

  /// [timeout] — startup byudjetidan qolgan vaqt (fon tekshiruvida yo'q).
  /// Vaqt tugasa xato deb hisoblanadi.
  static Future<UpdateStatus?> _safeCheck({Duration? timeout}) async {
    try {
      final Future<UpdateStatus> check = _updater.checkForUpdate();
      return timeout == null ? await check : await check.timeout(timeout);
    } catch (e) {
      _log('checkForUpdate xatosi: $e');
      // Startup'dagi xato odatda avtomatik yuklovchi bilan poyga — kanalga
      // faqat fon tekshiruvidagisi.
      if (_timer != null) PatchReporter.error('checkForUpdate', e);
      return null;
    }
  }

  static Future<void> _safeUpdate({Duration? timeout}) async {
    try {
      final Future<void> update = _updater.update();
      await (timeout == null ? update : update.timeout(timeout));
    } catch (e) {
      _log('update xatosi: $e');
      // Avtomatik yuklovchi shu patch'ni yuklayapti — kutilgan poyga, xato
      // emas: kanalga yuborilmaydi.
      if (!isUpdateInProgress(e)) PatchReporter.error('update', e);
    }
  }

  /// Shorebird'ning o'z yuklovchisi ishlayotgan paytdagi `update()` javobi.
  /// shorebird_code_push 2.0.7 buni zararsiz deb qaytarishi kerak edi, lekin
  /// Flutter 3.41.3 dvigateli uni umumiy xato kodi bilan beradi:
  /// `UpdateException: Update already in progress (unknown)` (Mac, 2026-10-02).
  @visibleForTesting
  static bool isUpdateInProgress(Object error) =>
      error is UpdateException &&
      error.message.toLowerCase().contains('already in progress');

  static Future<String> _bootPatchText() async {
    try {
      final Patch? current = await _updater.readCurrentPatch();
      final Patch? next = await _updater.readNextPatch();
      return '${current?.number ?? "-"} (keyingi: ${next?.number ?? "-"})';
    } catch (_) {
      return '?';
    }
  }

  static void _log(String message) {
    // Konsolga ham — dasturni terminaldan ishga tushirib kuzatish uchun
    // (macOS'da Documents'dagi log faylini boshqa dastur o'qiy olmaydi).
    debugPrint('[PATCH] $message');
    unawaited(LogHelper.write(LogLevel.info, '[PATCH] $message'));
  }

  /// runApp() dan keyin — fon tekshiruvini boshlaydi.
  static void start() {
    if (!_updater.isAvailable || _timer != null) return;
    _timer = Timer.periodic(_interval, (_) => _checkInBackground());
    Timer(const Duration(minutes: 1), _checkInBackground);
    BackendHealth.status.addListener(_onConnectivityChanged);
    PatchReporter.start(_updater);
  }

  /// Oflayn → onlayn: 10 daqiqalik davrni kutmasdan darhol tekshiradi.
  static void _onConnectivityChanged() {
    if (BackendHealth.status.value == BackendStatus.up) _checkInBackground();
  }

  /// Kassir tugmani bosganda (savat bo'sh bo'lishi kerak — chaqiruvchi
  /// tekshiradi). Oyna yopilgandagi kabi holat saqlanadi, keyin qayta yonadi.
  static Future<void> restartNow() async {
    // Ikki marta bosilsa ikkita POS jarayoni bitta bazani ochmasin.
    if (_restarting) return;
    _restarting = true;
    readyToRestart.value = false; // tugma darhol yo'qoladi
    try {
      await Pref.setString(PrefKeys.appClosedTime,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()));
      await Pref.setBool(PrefKeys.isFirstTime, true);
      await Hive.close();
    } catch (_) {
      // Saqlash xatosi qayta ishga tushirishni to'xtatmasin.
    }
    // Cheklar bazasi (ObjectBox) yangi jarayon ochishidan OLDIN yopiladi.
    for (final void Function() close in <void Function()>[
      () => MyObjectbox.saleStore.close(),
      () => MyObjectbox.storee.close(),
    ]) {
      try {
        close();
      } catch (_) {
        // Ochilmagan (late) yoki allaqachon yopilgan — e'tiborsiz.
      }
    }
    await _relaunch();
  }

  static Future<void> _checkInBackground() async {
    if (_busy || readyToRestart.value) return;
    _busy = true;
    try {
      if (await _downloadIfAny()) {
        _log('fon: patch tayyor — "Yangilanish tayyor" tugmasi ko\'rsatiladi');
        readyToRestart.value = true;
      }
    } catch (e) {
      // Keyingi davrda qayta uriniladi.
      _log('fon: xato $e');
      PatchReporter.error('fon tekshiruvi', e);
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
    if (await _restartNeededLocally()) return true;
    // ~40 × 0.7 s — avtomatik yuklovchi osilib qolsa ham cheksiz aylanmaydi.
    for (int attempt = 0; attempt < 40; attempt++) {
      final UpdateStatus? status = await _safeCheck();
      switch (status) {
        case UpdateStatus.restartRequired:
          return true;
        case UpdateStatus.upToDate:
        case UpdateStatus.unavailable:
          return false;
        case UpdateStatus.outdated:
          if (attempt == 0) _log('fon: yangi patch topildi — yuklanmoqda');
          await _safeUpdate();
          break;
        case null:
          // Chaqiruv xatosi — qayta urinamiz.
          break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 700));
    }
    return await _restartNeededLocally();
  }

  static Future<void> _relaunch() async {
    // Jarayon darhol tugaydi — log diskka yozilishini kutamiz.
    await LogHelper.write(LogLevel.info,
        '[PATCH] qayta ishga tushirilmoqda, boot patch=${await _bootPatchText()}');
    await Process.start(
      Platform.resolvedExecutable,
      const <String>[],
      mode: ProcessStartMode.detached,
      workingDirectory: File(Platform.resolvedExecutable).parent.path,
      environment: const <String, String>{relaunchedEnv: '1'},
    );
    exit(0);
  }
}
