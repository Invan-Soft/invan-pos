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
*/

import 'package:intl/intl.dart';

import '../../../utils/constants/pref_keys.dart';
import '../../../utils/helpers/prefs.dart';

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

  const SyncFetchResult._(this.ok, this.received, this.truncated);

  const SyncFetchResult.failed() : this._(false, 0, false);

  const SyncFetchResult.done(int received, {bool truncated = false})
      : this._(true, received, truncated);
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

  /// Backend `start_date`/`end_date` ni shu formatda kutadi (UTC).
  static final DateFormat fmt = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Har bir oyna oldingisidan shuncha ortga cho'ziladi — kassa va server
  /// soatlari orasidagi farq tufayli chegaradagi notification tushib
  /// qolmasligi uchun. Takror kelgan notification zarar qilmaydi: barcha
  /// qo'llash amallari id bo'yicha `put`/`delete` — idempotent.
  static const Duration overlap = Duration(minutes: 2);

  /// Bundan eski kursor bilan notification so'rash ma'nosiz (server
  /// tarixni cheksiz saqlamaydi) — bunday holda to'liq qayta yuklanadi.
  static const Duration maxLookback = Duration(days: 14);

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

  /// Notification tarixiga ishonib bo'lmaydigan ikki holat — to'liq qayta
  /// yuklash kerak:
  ///
  ///  1. Kursor umuman yo'q. Bu — yangi o'rnatish yoki shu tuzatish
  ///     chiqqan versiyaga yangilanish. Aynan shu ikkinchi holat muhim:
  ///     yangilanishdan oldin o'tkazib yuborilgan o'zgarishlarni
  ///     notification'dan tiklab bo'lmaydi, shuning uchun kassa bir marta
  ///     to'liq qayta yuklab, boshqalar bilan bir xil holatga keladi.
  ///  2. Kursor [maxLookback] dan eskirgan — server bunchalik uzoq
  ///     tarixni saqlashiga ishonch yo'q.
  static bool needsFullReload(SyncStream stream, DateTime end) =>
      !has(stream) || raw(stream, end).isBefore(end.subtract(maxLookback));

  static Future<void> commit(SyncStream stream, DateTime upTo) =>
      Pref.setInt(stream.prefKey, upTo.millisecondsSinceEpoch);
}
