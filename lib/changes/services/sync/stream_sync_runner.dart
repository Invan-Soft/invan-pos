/*
    Bitta sinxron oqimini kursordan hozirgi vaqtgacha yetkazuvchi mantiq.

    Bu sinf ataylab UI va HTTP dan mustaqil: notification olish va to'liq
    qayta yuklash tashqaridan callback sifatida beriladi. Shu sababli
    kursor qachon suriladi, qachon surilmaydi degan asosiy kafolatni
    testda tekshirish mumkin (qarang: test/stream_sync_runner_test.dart).
*/

import 'package:flutter/foundation.dart';

import 'sync_cursor.dart';

/// Bitta vaqt oynasidagi notification'larni olib qo'llaydi.
typedef FetchWindow = Future<SyncFetchResult> Function(
    String startDate, String endDate);

/// Notification tarixi yetarli bo'lmaganda oqimni to'liq qayta yuklaydi.
typedef FullReload = Future<bool> Function();

class StreamSyncRunner {
  /// Bitta so'rov qamrab oladigan maksimal oraliq.
  static const Duration defaultChunk = Duration(hours: 6);

  /// Bitta chaqiruvda ko'pi bilan shuncha bo'lak (~30 kun). Qolgani keyingi
  /// chaqiruvda davom etadi — kursor bo'lak-bo'lak surilgani uchun
  /// bajarilgani qayta so'ralmaydi.
  static const int defaultMaxChunks = 120;

  /// Limitga urilgan oynani necha marta ikkiga bo'lib ko'rish mumkin.
  static const int defaultMaxSplitDepth = 3;

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

  /// Oqimni kursordan [end] gacha yetkazadi.
  ///
  /// [force] — `minInterval` cheklovini chetlab o'tadi (ilova ochilganda,
  /// qo'lda "Yangilash" bosilganda).
  ///
  /// Qaytadi: to'liq yetkazildimi. `false` bo'lsa kursor eng oxirgi
  /// muvaffaqiyatli bo'lak joyida qoladi va keyingi chaqiruv o'sha yerdan
  /// davom etadi.
  Future<bool> run({
    required DateTime end,
    required FetchWindow fetch,
    required FullReload fullReload,
    bool force = false,
  }) async {
    if (_throttled(end, force)) {
      if (kDebugMode) {
        print('⏱️ ${stream.label}: hali erta (minInterval), o\'tkazib yuborildi');
      }
      return true;
    }

    if (SyncCursor.needsFullReload(stream, end)) {
      if (kDebugMode) {
        print('📦 ${stream.label}: kursor yo\'q/eskirgan → to\'liq yuklash');
      }
      return _fullReloadAndCommit(end, fullReload);
    }

    final DateTime start = SyncCursor.start(stream, end);
    final List<SyncWindow> windows = SyncWindow.split(
      start,
      end,
      chunk,
      maxChunks: maxChunksPerRun,
    );

    for (final SyncWindow window in windows) {
      final SyncFetchResult result = await _fetchDeep(fetch, window);

      if (!result.ok) {
        // Kursor surilmaydi — shu oyna keyingi urinishda qaytadan olinadi.
        if (kDebugMode) {
          print('⚠️ ${stream.label}: oyna olinmadi, kursor joyida qoldi');
        }
        return false;
      }

      if (result.truncated) {
        // Bo'lib ko'rish ham yordam bermadi: shuncha o'zgarish bo'lgan
        // bo'lsa, to'liq qayta yuklash ham arzonroq, ham ishonchliroq.
        if (kDebugMode) {
          print('📦 ${stream.label}: oyna limitga urildi → to\'liq yuklash');
        }
        return _fullReloadAndCommit(end, fullReload);
      }

      await SyncCursor.commit(stream, window.end);
    }

    return true;
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

  Future<bool> _fullReloadAndCommit(DateTime end, FullReload fullReload) async {
    bool ok;
    try {
      ok = await fullReload();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ${stream.label}: to\'liq yuklash xatosi: $e');
      }
      ok = false;
    }
    if (ok) await SyncCursor.commit(stream, end);
    return ok;
  }

  /// Oyna server limitiga urilsa, uni ikkiga bo'lib qayta so'raydi.
  /// Takror kelgan notification zarar qilmaydi — qo'llash amallari
  /// id bo'yicha idempotent.
  Future<SyncFetchResult> _fetchDeep(
    FetchWindow fetch,
    SyncWindow window, {
    int depth = 0,
  }) async {
    final SyncFetchResult result = await fetch(
      SyncCursor.format(window.start),
      SyncCursor.format(window.end),
    );

    if (!result.ok || !result.truncated || depth >= maxSplitDepth) {
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
    );
    if (!first.ok || first.truncated) return first;

    return _fetchDeep(fetch, SyncWindow(mid, window.end), depth: depth + 1);
  }
}
