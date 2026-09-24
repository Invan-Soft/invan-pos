/*
    Bitta sinxron oqimini kursordan hozirgi vaqtgacha yetkazuvchi mantiq.

    Bu sinf ataylab UI va HTTP dan mustaqil: notification olish va to'liq
    qayta yuklash tashqaridan callback sifatida beriladi. Shu sababli
    kursor qachon suriladi, qachon surilmaydi degan asosiy kafolatni
    testda tekshirish mumkin (qarang: test/stream_sync_runner_test.dart).

    Kafolatlar:
      * kursor FAQAT oyna to'liq va xatosiz qo'llangandan keyin suriladi;
      * kursor hech qachon server vaqtidan oldinga o'tmaydi va oddiy commit
        bilan orqaga qaytmaydi;
      * bitta buzuq notification oqimni bloklamaydi — to'liq yuklash bilan
        qoplanadi;
      * timeout bo'lgan uzun oyna bo'linadi va keyingi safar kichikroq
        bo'lak ishlatiladi; eng kichik bo'lak ham sig'masa — to'liq yuklash;
      * qulf boshqa egaga o'tsa (`shouldContinue` false) run hech narsa
        yozmasdan to'xtaydi.
*/

import 'package:flutter/foundation.dart';

import '../log_helper.dart';
import 'server_clock.dart';
import 'sync_cursor.dart';

/// Bitta vaqt oynasidagi notification'larni olib qo'llaydi.
typedef FetchWindow = Future<SyncFetchResult> Function(
    String startDate, String endDate);

/// Notification tarixi yetarli bo'lmaganda oqimni to'liq qayta yuklaydi.
typedef FullReload = Future<bool> Function();

class StreamSyncRunner {
  /// Bitta so'rov qamrab oladigan maksimal oraliq (standart).
  static const Duration defaultChunk = Duration(hours: 6);

  /// Timeout'larda bo'lak shundan kichik bo'lmaydi.
  static const Duration minChunk = Duration(minutes: 15);

  /// Bitta chaqiruvda ko'pi bilan shuncha bo'lak (~30 kun). Qolgani keyingi
  /// chaqiruvda davom etadi — kursor bo'lak-bo'lak surilgani uchun
  /// bajarilgani qayta so'ralmaydi.
  static const int defaultMaxChunks = 120;

  /// Limitga urilgan oynani necha marta ikkiga bo'lib ko'rish mumkin.
  static const int defaultMaxSplitDepth = 3;

  /// Timeout bo'lgan oyna ko'pi bilan shuncha marta bo'linadi (bu yerda
  /// chuqur ketmaymiz: tarmoq umuman javob bermayotgan bo'lsa har urinish
  /// timeout'gacha kutadi).
  static const int timeoutSplitDepth = 1;

  /// Shundan qisqa oyna timeout bo'lsa bo'linmaydi va bo'lak
  /// kichraytirilmaydi — muammo hajmda emas, tarmoqda.
  static const Duration minSplitOnTimeout = Duration(minutes: 30);

  /// To'liq yuklash (43 MB) shundan uzoq cho'zilsa yiqilgan hisoblanadi —
  /// qulf abadiy band bo'lib qolmasin. `CatchUpSync.staleLock` dan qisqa.
  static const Duration fullReloadTimeout = Duration(minutes: 15);

  final SyncStream stream;
  final Duration chunk;
  final int maxChunksPerRun;
  final int maxSplitDepth;

  /// Oqim shu oraliqdan tez-tez so'ralmaydi.
  ///
  /// Mahsulot uchun nol — narx o'zgarishi imkon qadar tez yetib borishi
  /// kerak. Kategoriya va diskont sekinroq o'zgaradi, ularni har daqiqada
  /// so'rash backendga bekorga yuk.
  ///
  /// Cheklov `force: true` bilan va kursor umuman yo'q bo'lganda
  /// e'tiborga olinmaydi.
  final Duration minInterval;

  const StreamSyncRunner({
    required this.stream,
    this.chunk = defaultChunk,
    this.maxChunksPerRun = defaultMaxChunks,
    this.maxSplitDepth = defaultMaxSplitDepth,
    this.minInterval = Duration.zero,
  });

  /// Oqimni kursordan [end] gacha yetkazadi. [end] — SERVER vaqti.
  ///
  /// [force] — `minInterval` cheklovini va to'liq yuklash backoff'ini chetlab
  /// o'tadi (ilova ochilganda, qo'lda "Yangilash" bosilganda).
  /// [shouldContinue] — false qaytarsa (qulf boshqa egaga o'tdi, logout)
  /// run hech narsa yozmasdan to'xtaydi.
  /// [beforeCommit] — kursor yozilishidan oldin (ma'lumot boxlarini diskka
  /// flush qilish uchun).
  ///
  /// Qaytadi: to'liq yetkazildimi. `false` bo'lsa kursor eng oxirgi
  /// muvaffaqiyatli bo'lak joyida qoladi va keyingi chaqiruv o'sha yerdan
  /// davom etadi.
  Future<bool> run({
    required DateTime end,
    required FetchWindow fetch,
    required FullReload fullReload,
    bool force = false,
    bool Function()? shouldContinue,
    Future<void> Function()? beforeCommit,
  }) async {
    if (_throttled(end, force)) {
      if (kDebugMode) {
        print('⏱️ ${stream.label}: hali erta (minInterval), o\'tkazib yuborildi');
      }
      return true;
    }

    if (SyncCursor.needsFullReload(stream, end)) {
      return _fullReloadAndCommit(end, fullReload,
          why: SyncCursor.has(stream)
              ? 'kursor eskirgan yoki soat sakragan'
              : 'kursor yo\'q',
          force: force,
          shouldContinue: shouldContinue,
          beforeCommit: beforeCommit);
    }

    final DateTime start = SyncCursor.start(stream, end);
    final Duration effectiveChunk = SyncCursor.chunk(stream, chunk);
    final List<SyncWindow> windows = SyncWindow.split(
      start,
      end,
      effectiveChunk,
      maxChunks: maxChunksPerRun,
    );

    // Bo'lak (persist qilingan chunk) shundan qisqa oyna timeout bo'lsa
    // kichraytirilmaydi: oyna allaqachon minChunk'dan kichik bo'lsa,
    // muammo hajmda emas — tarmoqning o'zi (yoki server) javob bermayapti,
    // bo'lakni yanada kichraytirish foyda bermaydi.
    bool sawTimeout = false;
    for (int i = 0; i < windows.length; i++) {
      final SyncWindow window = windows[i];
      if (!_alive(shouldContinue, 'fetch')) return false;

      // Birinchi oynadan boshqalari oldingisining oxiridan overlap qadar
      // ortga cho'ziladi — run'lar orasidagi kabi. Server chegarani qat'iy
      // (strict) solishtirsa ham chegaradagi soniya tushib qolmaydi.
      final SyncFetchResult result =
          await _fetchDeep(fetch, window, overlapStart: i > 0);
      if (result.timedOut && window.length >= minChunk) sawTimeout = true;

      if (!result.ok) {
        if (result.unauthorized) {
          // Token yaroqsiz — qayta urinishning foydasi yo'q, kursor joyida.
          await LogHelper.activity('SYNC_UNAUTHORIZED', {'stream': stream.label});
          return false;
        }
        if (result.timedOut && effectiveChunk <= minChunk) {
          // Eng kichik bo'lak ham timeout'ga sig'madi (juda sekin internet
          // + og'ir payload'lar). Bo'lish/kichraytirish tugadi — to'liq
          // yuklash (u bo'lak-bo'lak, sukut-timeout'li) yagona yo'l.
          return _fullReloadAndCommit(end, fullReload,
              why: 'eng kichik oyna ham timeout',
              force: force,
              shouldContinue: shouldContinue,
              beforeCommit: beforeCommit);
        }
        // Kursor surilmaydi — shu oyna keyingi urinishda qaytadan olinadi.
        if (kDebugMode) {
          print('⚠️ ${stream.label}: oyna olinmadi, kursor joyida qoldi');
        }
        if (sawTimeout) await _shrinkChunk(effectiveChunk);
        return false;
      }

      if (result.fullReloadRequested) {
        return _fullReloadAndCommit(end, fullReload,
            why: 'server type 0',
            force: true,
            shouldContinue: shouldContinue,
            beforeCommit: beforeCommit);
      }

      if (result.truncated) {
        // Bo'lib ko'rish ham yordam bermadi: shuncha o'zgarish bo'lgan
        // bo'lsa, to'liq qayta yuklash ham arzonroq, ham ishonchliroq.
        return _fullReloadAndCommit(end, fullReload,
            why: 'oyna limitga urildi',
            force: force,
            shouldContinue: shouldContinue,
            beforeCommit: beforeCommit);
      }

      if (result.applyFailed) {
        // Oynadagi biror notification qo'llanmadi. Kursorni surib
        // yuborsak o'sha o'zgarish abadiy yo'qoladi; surmasak oyna abadiy
        // takrorlanadi (aynan shu bo'lgan). To'liq yuklash ikkalasini ham
        // yopadi: boshqa endpoint, boshqa parser.
        return _fullReloadAndCommit(end, fullReload,
            why: 'notification qo\'llanmadi',
            force: force,
            shouldContinue: shouldContinue,
            beforeCommit: beforeCommit);
      }

      if (!_alive(shouldContinue, 'commit')) return false;
      if (beforeCommit != null) await beforeCommit();
      final DateTime upTo = SyncCursor.clamp(window.end, result.serverTime);
      await SyncCursor.commit(stream, upTo);

      // Server "hozir"iga yetdik — qolgan oynalar server kelajagida
      // (kassa soati oldinda). Ularni so'rash bekor: bo'sh qaytadi, kursor
      // esa har javobdagi server vaqtiga surilib, so'ralmagan oraliq hosil
      // bo'lardi.
      if (result.serverTime != null && !window.end.isBefore(result.serverTime!)) {
        break;
      }
    }

    if (sawTimeout) {
      await _shrinkChunk(effectiveChunk);
    } else if (windows.isNotEmpty && effectiveChunk < chunk) {
      await _growChunk(effectiveChunk);
    }

    return true;
  }

  bool _alive(bool Function()? shouldContinue, String where) {
    if (shouldContinue == null || shouldContinue()) return true;
    LogHelper.activity(
        'SYNC_RUN_PREEMPTED', {'stream': stream.label, 'at': where});
    return false;
  }

  /// Oqim yaqinda sinxronlangan bo'lsa `true`.
  ///
  /// Kursor yo'q bo'lsa hech qachon cheklanmaydi — birinchi to'liq yuklash
  /// kechikmasligi kerak.
  bool _throttled(DateTime end, bool force) {
    if (force || minInterval == Duration.zero) return false;
    if (SyncCursor.needsFullReload(stream, end)) return false;
    return end.difference(SyncCursor.raw(stream, end)) < minInterval;
  }

  Future<bool> _fullReloadAndCommit(
    DateTime end,
    FullReload fullReload, {
    required String why,
    bool force = false,
    bool Function()? shouldContinue,
    Future<void> Function()? beforeCommit,
  }) async {
    if (!force && SyncCursor.fullReloadBackoffActive(stream, end)) {
      // Yaqinda yiqilgan — 43 MB ni har daqiqada tortmaymiz.
      if (kDebugMode) {
        print('⏳ ${stream.label}: to\'liq yuklash backoff, o\'tkazib yuborildi');
      }
      return false;
    }
    if (!_alive(shouldContinue, 'full-reload')) return false;

    if (kDebugMode) {
      print('📦 ${stream.label}: to\'liq yuklash ($why)');
    }
    await LogHelper.activity(
        'SYNC_FULL_RELOAD', {'stream': stream.label, 'why': why});

    // Yuklash BOSHLANGAN mahalliy vaqt. Kursor tugagan vaqtga emas,
    // boshlangan vaqtga suriladi: yuklash davomidagi o'zgarishlar
    // notification orqali kelishi kerak. Server vaqtiga esa yuklashdan
    // KEYIN o'tkaziladi — yuklash davomida (javoblardan) server soati
    // farqi aniqlanib bo'lgan bo'ladi.
    final DateTime localStart = ServerClock.localNow();

    bool ok;
    try {
      ok = await fullReload().timeout(fullReloadTimeout);
    } catch (e) {
      if (kDebugMode) {
        print('❌ ${stream.label}: to\'liq yuklash xatosi: $e');
      }
      await LogHelper.activity(
          'SYNC_FULL_RELOAD_FAILED', {'stream': stream.label, 'error': e});
      ok = false;
    }
    if (!ok) {
      await LogHelper.activity(
          'SYNC_FULL_RELOAD_FAILED', {'stream': stream.label, 'why': why});
      await SyncCursor.markFullReloadFailed(stream, end);
      return false;
    }
    if (!_alive(shouldContinue, 'full-reload-commit')) return false;
    await SyncCursor.clearFullReloadFailed(stream);
    if (beforeCommit != null) await beforeCommit();
    await SyncCursor.commit(
      stream,
      SyncCursor.clamp(end, ServerClock.toServer(localStart)),
      force: true,
    );
    return true;
  }

  /// Oyna server limitiga urilsa (yoki timeout bo'lsa), uni ikkiga bo'lib
  /// qayta so'raydi. Takror kelgan notification zarar qilmaydi — qo'llash
  /// amallari id bo'yicha idempotent.
  ///
  /// [overlapStart] — so'rov boshlanishi oynadan [SyncCursor.overlap] qadar
  /// oldinroq (ketma-ket bo'laklar chegarasida tushib qolish bo'lmasin).
  Future<SyncFetchResult> _fetchDeep(
    FetchWindow fetch,
    SyncWindow window, {
    int depth = 0,
    bool overlapStart = false,
  }) async {
    final DateTime requestStart =
        overlapStart ? window.start.subtract(SyncCursor.overlap) : window.start;
    final SyncFetchResult result = await fetch(
      SyncCursor.format(requestStart),
      SyncCursor.format(window.end),
    );

    final bool shouldSplit;
    final int depthLimit;
    if (result.ok) {
      shouldSplit = result.truncated;
      depthLimit = maxSplitDepth;
    } else {
      shouldSplit = result.timedOut && window.length >= minSplitOnTimeout;
      depthLimit = timeoutSplitDepth;
    }
    if (!shouldSplit || depth >= depthLimit) {
      return result;
    }

    final DateTime mid = window.start.add(
      Duration(milliseconds: window.length.inMilliseconds ~/ 2),
    );
    if (!mid.isAfter(window.start) || !window.end.isAfter(mid)) {
      return result;
    }

    final SyncFetchResult first = await _fetchDeep(
      fetch,
      SyncWindow(window.start, mid),
      depth: depth + 1,
      overlapStart: overlapStart,
    );
    if (!first.ok || first.truncated) return first;

    final SyncFetchResult second = await _fetchDeep(
      fetch,
      SyncWindow(mid, window.end),
      depth: depth + 1,
      overlapStart: true,
    );
    return first.followedBy(second);
  }

  Future<void> _shrinkChunk(Duration current) async {
    Duration next = Duration(milliseconds: current.inMilliseconds ~/ 2);
    if (next < minChunk) next = minChunk;
    if (next == current) return;
    await SyncCursor.setChunk(stream, next);
    await LogHelper.activity('SYNC_CHUNK_SHRINK',
        {'stream': stream.label, 'minutes': next.inMinutes});
  }

  Future<void> _growChunk(Duration current) async {
    Duration next = current * 2;
    if (next > chunk) next = chunk;
    if (next == current) return;
    await SyncCursor.setChunk(stream, next);
  }
}
