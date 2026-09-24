/*
    Notification catch-up uchun turg'un (persistent) vaqt kursori.

    Muammo: ilgari har bir sinxron chaqiruvi o'z vaqt oynasini o'zi yasardi
    (`DateTime.now()`, `now - 2 daqiqa`, `lastSyncTime - 5 daqiqa`) va oyna
    so'rov muvaffaqiyatli bo'ldimi-yo'qmi tekshirilmasdan oldinga surilardi.
    Natijada kassa o'chiq turgan yoki internet uzilgan davrdagi o'zgarishlar
    (masalan mahsulot narxi — type 13) hech qachon so'ralmasdan qolib ketardi.

    Yechim: har bir oqim uchun bitta kursor Hive'da saqlanadi va u FAQAT
    o'sha oynadagi notification'lar muvaffaqiyatli olinib lokalga
    yozilgandan keyin oldinga suriladi. Shu sababli har qanday uzilish
    keyingi muvaffaqiyatli sinxronda avtomatik "yetib olinadi".

    Vaqt — SERVER vaqti (qarang: server_clock.dart). Kursor hech qachon
    server "hozir"idan oldinga o'tmaydi: kassa soati oldinda bo'lsa ham.
    Kursor monoton: oddiy commit uni ORQAGA surmaydi (parallel qolib ketgan
    eski run yangi kursorni buzmasin); faqat to'liq yuklash `force` bilan
    qayta o'rnatadi.
*/

import 'package:intl/intl.dart';

import '../../../utils/constants/pref_keys.dart';
import '../../../utils/helpers/prefs.dart';
import '../log_helper.dart';

/// Alohida kursorga ega sinxron oqimlari.
enum SyncStream { categories, products, discounts }

extension SyncStreamPref on SyncStream {
  String get prefKey {
    switch (this) {
      case SyncStream.categories:
        return PrefKeys.syncCursorCategories;
      case SyncStream.products:
        return PrefKeys.syncCursorProducts;
      case SyncStream.discounts:
        return PrefKeys.syncCursorDiscounts;
    }
  }

  /// Moslashuvchan bo'lak uzunligi saqlanadigan kalit (daqiqa).
  String get chunkPrefKey => '${prefKey}_chunk_min';

  /// Oxirgi muvaffaqiyatsiz to'liq yuklash vaqti (ms) — backoff uchun.
  String get reloadFailPrefKey => '${prefKey}_reload_fail_ms';

  String get label {
    switch (this) {
      case SyncStream.categories:
        return 'Category';
      case SyncStream.products:
        return 'Product';
      case SyncStream.discounts:
        return 'Discount';
    }
  }
}

/// Bitta `GET /notifications` chaqiruvining natijasi.
///
/// [ok] false bo'lsa kursor surilmaydi — o'sha oyna keyingi urinishda
/// qaytadan so'raladi.
class SyncFetchResult {
  final bool ok;
  final int received;

  /// Server `limit` ga teng miqdorda qaytardi — oyna to'liq qamralmagan
  /// bo'lishi mumkin, uni maydaroq bo'laklab qayta olish kerak.
  final bool truncated;

  /// Javob berilgan paytdagi server vaqti (HTTP `date`). Kursor bundan
  /// oldinga o'tmaydi — kassa soati serverdan oldinda bo'lsa ham.
  final DateTime? serverTime;

  /// Kamida bitta notification qo'llanmadi (parse yoki yozish xatosi).
  /// Bunday oyna kursorni surmaydi — oqim to'liq qayta yuklanadi. Ilgari
  /// bitta buzuq notification butun oynani ABADIY bloklab qo'yardi.
  final bool applyFailed;

  /// So'rov vaqt chegarasiga urildi — uzun oynani bo'lib qayta so'rash va
  /// keyingi safar kichikroq bo'lak ishlatish mumkin.
  final bool timedOut;

  /// Server 401/403 qaytardi — token yaroqsiz. Qayta urinish foydasiz,
  /// alohida log/ogohlantirish kerak.
  final bool unauthorized;

  /// Server "hammasini qayta yukla" (type 0) dedi — runner oynani
  /// qo'llash o'rniga bitta to'liq yuklash qiladi.
  final bool fullReloadRequested;

  const SyncFetchResult._(
    this.ok,
    this.received,
    this.truncated,
    this.serverTime,
    this.applyFailed,
    this.timedOut,
    this.unauthorized,
    this.fullReloadRequested,
  );

  const SyncFetchResult.failed({
    bool timedOut = false,
    DateTime? serverTime,
    bool unauthorized = false,
  }) : this._(false, 0, false, serverTime, false, timedOut, unauthorized, false);

  const SyncFetchResult.done(
    int received, {
    bool truncated = false,
    DateTime? serverTime,
    bool applyFailed = false,
    bool fullReloadRequested = false,
  }) : this._(true, received, truncated, serverTime, applyFailed, false, false,
            fullReloadRequested);

  /// Ikki ketma-ket bo'lakning (oyna ikkiga bo'linganda) umumiy natijasi.
  /// Birinchi yarimdagi bayroqlar yo'qolib ketmasligi kerak.
  SyncFetchResult followedBy(SyncFetchResult next) => SyncFetchResult._(
        next.ok,
        received + next.received,
        next.truncated,
        next.serverTime ?? serverTime,
        applyFailed || next.applyFailed,
        next.timedOut,
        unauthorized || next.unauthorized,
        fullReloadRequested || next.fullReloadRequested,
      );
}

/// Yopiq-ochiq vaqt oynasi (UTC).
class SyncWindow {
  final DateTime start;
  final DateTime end;

  const SyncWindow(this.start, this.end);

  Duration get length => end.difference(start);

  /// [start] dan [end] gacha bo'lgan oraliqni [chunk] uzunlikdagi
  /// bo'laklarga ajratadi.
  ///
  /// Bo'laklash ikki narsa uchun kerak:
  ///  1. juda uzun oyna serverning `limit` iga urilib qolmasligi uchun;
  ///  2. har bir bo'lakdan keyin kursor saqlanadi — sinxron yarmida uzilsa,
  ///     bajarilgan qismi qayta so'ralmaydi.
  ///
  /// [maxChunks] dan ortig'i qaytarilmaydi: qolgani keyingi chaqiruvga
  /// qoladi (kursor bo'lak-bo'lak oldinga surilgani uchun bu xavfsiz).
  static List<SyncWindow> split(
    DateTime start,
    DateTime end,
    Duration chunk, {
    int maxChunks = 120,
  }) {
    if (!end.isAfter(start) || chunk.inSeconds <= 0 || maxChunks <= 0) {
      return const <SyncWindow>[];
    }

    final List<SyncWindow> windows = <SyncWindow>[];
    DateTime cursor = start;
    while (cursor.isBefore(end) && windows.length < maxChunks) {
      DateTime next = cursor.add(chunk);
      if (next.isAfter(end)) next = end;
      windows.add(SyncWindow(cursor, next));
      cursor = next;
    }
    return windows;
  }
}

class SyncCursor {
  SyncCursor._();

  /// Kursor ma'nosi o'zgargan relizlar uchun. 2 — kursor server vaqtida
  /// (ilgari kassa soatida). Eski kursor kassa soati oldinda bo'lganda
  /// "kelajak"da bo'lishi mumkin va buni birinchi ishga tushishda (server
  /// farqi hali noma'lum) aniqlab bo'lmaydi — shuning uchun bir marta
  /// hamma kursor tashlanadi va uchala oqim to'liq yuklanadi.
  static const int schemaVersion = 2;

  /// Backend `start_date`/`end_date` ni shu formatda kutadi (UTC).
  static final DateFormat fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Har bir oyna oldingisidan shuncha ortga cho'ziladi — server ichidagi
  /// kechikishlar va soniyalik aniqlik tufayli chegaradagi notification
  /// tushib qolmasligi uchun. Takror kelgan notification zarar qilmaydi:
  /// barcha qo'llash amallari id bo'yicha `put`/`delete` — idempotent.
  static const Duration overlap = Duration(minutes: 2);

  /// Bundan eski kursor bilan notification so'rash o'rniga to'liq qayta
  /// yuklash arzonroq (14 kun = 56 oyna × 3 oqim). Server tarixni saqlaydi
  /// (2026-08-12 da tasdiqlangan), ya'ni bu ishonchlilik emas, tezlik chegarasi.
  static const Duration maxLookback = Duration(days: 14);

  /// Yiqilgan to'liq yuklash shuncha vaqt qayta urinilmaydi (43 MB ni har
  /// daqiqada tortmaslik uchun). `force` (ilova ochilganda, qo'lda) chetlab
  /// o'tadi.
  static const Duration fullReloadBackoff = Duration(minutes: 5);

  static String format(DateTime utc) => fmt.format(utc);

  static bool has(SyncStream stream) => Pref.getInt(stream.prefKey, 0) > 0;

  /// Saqlangan xom kursor. Yo'q bo'lsa [end] qaytadi — bunday holatda
  /// [needsFullReload] allaqachon true, ya'ni notification tarixi o'rniga
  /// to'liq qayta yuklash ishlatiladi.
  static DateTime raw(SyncStream stream, DateTime end) {
    final int millis = Pref.getInt(stream.prefKey, 0);
    if (millis > 0) {
      return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
    }
    return end;
  }

  /// So'rov uchun boshlanish nuqtasi: xom kursor minus [overlap],
  /// [maxLookback] bilan cheklangan.
  static DateTime start(SyncStream stream, DateTime end) {
    final DateTime from = raw(stream, end).subtract(overlap);
    final DateTime floor = end.subtract(maxLookback);
    return from.isBefore(floor) ? floor : from;
  }

  /// Notification tarixiga ishonib bo'lmaydigan holatlar — to'liq qayta
  /// yuklash kerak:
  ///
  ///  1. Kursor umuman yo'q. Bu — yangi o'rnatish yoki shu tuzatish
  ///     chiqqan versiyaga yangilanish. Aynan shu ikkinchi holat muhim:
  ///     yangilanishdan oldin o'tkazib yuborilgan o'zgarishlarni
  ///     notification'dan tiklab bo'lmaydi, shuning uchun kassa bir marta
  ///     to'liq qayta yuklab, boshqalar bilan bir xil holatga keladi.
  ///  2. Kursor [maxLookback] dan eskirgan — notification'dan yig'ish qimmat.
  ///  3. Kursor [end] dan [overlap] dan ko'proq KEYINDA. Bu faqat soat
  ///     sakraganda bo'ladi: kassa soati oldinda bo'lgan paytda (yoki eski
  ///     versiya kassa soati bilan) yozilgan kursor. Oradagi o'zgarishlarni
  ///     notification'dan tiklab bo'lmaydi — to'liq yuklab, kursorni server
  ///     vaqtiga qaytaramiz.
  static bool needsFullReload(SyncStream stream, DateTime end) {
    if (!has(stream)) return true;
    final DateTime r = raw(stream, end);
    if (r.isBefore(end.subtract(maxLookback))) return true;
    if (r.isAfter(end.add(overlap))) return true;
    return false;
  }

  /// Kursor uchun xavfsiz qiymat: so'ralgan oyna oxiri, lekin server
  /// vaqtidan (javob paytidagi) oldinga emas.
  ///
  /// Kassa soati oldinda bo'lsa `upTo` server kelajagida bo'ladi; unga
  /// yozilsa keyingi oyna o'sha kelajakdan boshlanib, oradagi
  /// notification'lar tushib qoladi. Server vaqti bilan cheklash buni yopadi.
  static DateTime clamp(DateTime upTo, DateTime? serverTime) {
    if (serverTime != null && serverTime.isBefore(upTo)) return serverTime;
    return upTo;
  }

  /// Kursorni suradi.
  ///
  /// Oddiy (`force: false`) commit MONOTON: saqlangan kursordan orqaga
  /// yozmaydi. Sabab: qulf majburan olingan yoki logout bo'lgan paytda hali
  /// ishlab turgan eski run o'z oynasining (eski) oxirini yozib, qo'lda
  /// to'liq yangilash surgan kursorni orqaga qaytarishi mumkin edi.
  ///
  /// [force] — to'liq yuklash: kursor qayta O'RNATILADI (soat sakraganda
  /// "kelajak"dagi kursorni server vaqtiga qaytarish uchun orqaga yozish
  /// shart).
  static Future<bool> commit(SyncStream stream, DateTime upTo,
      {bool force = false}) async {
    final int value = upTo.millisecondsSinceEpoch;
    if (!force) {
      final int stored = Pref.getInt(stream.prefKey, 0);
      if (stored > value) {
        await LogHelper.activity('SYNC_CURSOR_NOT_MOVED_BACK', {
          'stream': stream.label,
          'stored': stored,
          'attempted': value,
        });
        return false;
      }
    }
    await Pref.setInt(stream.prefKey, value);
    return true;
  }

  /// Kursorni tashlaydi — keyingi run to'liq yuklaydi.
  static Future<void> reset(SyncStream stream, {String reason = ''}) async {
    if (!has(stream)) return;
    await LogHelper.activity(
        'SYNC_CURSOR_RESET', {'stream': stream.label, 'reason': reason});
    await Pref.removeWithKey(stream.prefKey);
  }

  /// Sxema versiyasi o'zgargan bo'lsa barcha kursorlarni bir marta tashlaydi.
  /// main.dart'da, sinxronning har qanday chaqiruvidan OLDIN chaqiriladi.
  static Future<void> migrateIfNeeded() async {
    final int current = Pref.getInt(PrefKeys.syncCursorSchema, 0);
    if (current >= schemaVersion) return;
    for (final SyncStream s in SyncStream.values) {
      await reset(s, reason: 'schema $current -> $schemaVersion');
    }
    await Pref.setInt(PrefKeys.syncCursorSchema, schemaVersion);
  }

  // ——— Moslashuvchan bo'lak (timeout'ga qarshi) ———

  /// Oqim uchun joriy bo'lak uzunligi. Sekin internetda katta oyna har safar
  /// timeout bo'lib o'sha joyda qotib qolmasligi uchun timeout'da
  /// yarimlanadi, muvaffaqiyatda asta qaytadi.
  static Duration chunk(SyncStream stream, Duration fallback) {
    final int minutes = Pref.getInt(stream.chunkPrefKey, 0);
    if (minutes <= 0) return fallback;
    return Duration(minutes: minutes);
  }

  static Future<void> setChunk(SyncStream stream, Duration value) =>
      Pref.setInt(stream.chunkPrefKey, value.inMinutes);

  // ——— To'liq yuklash backoff ———

  static Future<void> markFullReloadFailed(SyncStream stream, DateTime now) =>
      Pref.setInt(stream.reloadFailPrefKey, now.millisecondsSinceEpoch);

  static Future<void> clearFullReloadFailed(SyncStream stream) =>
      Pref.removeWithKey(stream.reloadFailPrefKey);

  /// Yaqinda yiqilgan to'liq yuklash hali qayta urinilmasligi kerakmi.
  static bool fullReloadBackoffActive(SyncStream stream, DateTime now) {
    final int at = Pref.getInt(stream.reloadFailPrefKey, 0);
    if (at <= 0) return false;
    final DateTime failedAt = DateTime.fromMillisecondsSinceEpoch(at, isUtc: true);
    final Duration since = now.difference(failedAt);
    // Manfiy farq = soat orqaga sakragan — backoff'ni ushlab turmaymiz.
    return since >= Duration.zero && since < fullReloadBackoff;
  }
}
