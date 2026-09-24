/*
    Server soati.

    Muammo: sinxron oynasi (`start_date`/`end_date`) ham, kursor ham
    kassaning O'Z soati bilan hisoblanardi. Kassa soati serverdan 2 daqiqadan
    ko'proq OLDINDA bo'lsa (Windows'da timezone noto'g'ri qo'yilib soat qo'lda
    "to'g'rilangan" — do'konlarda keng tarqalgan), kursor "server kelajagi"ga
    yoziladi va keyingi oyna o'sha kelajakdan (minus 2 daqiqa) boshlanadi:
    server vaqti bo'yicha oradagi notification'lar HECH QACHON so'ralmaydi.
    Kassa soati ORQADA bo'lsa — har o'zgarish shuncha kechikib keladi.

    Yechim: har HTTP javobidagi `date` sarlavhasidan server bilan farq
    (offset) o'rganiladi va butun sinxron faqat server vaqtida ishlaydi.
    Farq Pref'da saqlanadi — ilova qayta ochilganda birinchi so'rovdanoq
    to'g'ri vaqt ishlatiladi.

    Farq HOST bo'yicha alohida saqlanadi: sinxron soati — notification
    serverniki (ws.notification.7i.uz). API serveri (api.7i.uz) bilan
    ikkalasi soati bir-biridan farq qilsa, API farqi notification
    kursorini "kelajak"ka surib yubormasin. API farqi faqat notification
    farqi hali noma'lum bo'lganda zaxira sifatida ishlatiladi.
*/

import 'dart:async';
import 'dart:io' show HttpDate;

import '../../../utils/constants/pref_keys.dart';
import '../../../utils/helpers/prefs.dart';
import '../log_helper.dart';

class ServerClock {
  ServerClock._();

  static const String hostNotification = 'notification';
  static const String hostApi = 'api';
  static const String _hostPersisted = '_persisted';

  /// Mahalliy soat (UTC). Testlar almashtiradi.
  static DateTime Function() localNow = () => DateTime.now().toUtc();

  /// Shundan katta farq log'ga yoziladi — kassa soatini tuzatish kerakligi
  /// belgisi (fiskal chek vaqtlariga ham ta'sir qiladi).
  static const Duration warnSkew = Duration(minutes: 2);

  /// Pref'ga faqat shundan katta o'zgarishda yoziladi — har daqiqada Hive'ga
  /// yozib o'tirmaslik uchun.
  static const Duration persistThreshold = Duration(seconds: 2);

  static final Map<String, Duration> _offsets = <String, Duration>{};
  static bool _loaded = false;
  static Duration? _lastWarned;
  static bool _missingDateLogged = false;

  static void _load() {
    if (_loaded) return;
    _loaded = true;
    try {
      final Object? v = Pref.getObject(PrefKeys.serverClockOffsetMs);
      if (v is int) _offsets[_hostPersisted] = Duration(milliseconds: v);
    } catch (_) {
      // Pref box hali ochilmagan (juda erta chaqiruv) — noma'lum deb qolamiz,
      // keyingi javobda o'rganiladi.
      _loaded = false;
    }
  }

  /// Server bilan farq kamida bir marta o'lchanganmi (yoki saqlanganmi).
  static bool get isKnown {
    _load();
    return _offsets.isNotEmpty;
  }

  /// Sinxron uchun `server - kassa`: notification serveri; u yo'q bo'lsa
  /// API; u ham yo'q bo'lsa saqlangan qiymat; hech biri yo'q — nol.
  static Duration get offset {
    _load();
    return _offsets[hostNotification] ??
        _offsets[hostApi] ??
        _offsets[_hostPersisted] ??
        Duration.zero;
  }

  /// Hozirgi vaqt — server soati bo'yicha (UTC).
  static DateTime nowUtc() => localNow().add(offset);

  /// Mahalliy vaqtni server vaqtiga o'tkazadi.
  static DateTime toServer(DateTime local) => local.toUtc().add(offset);

  /// HTTP javob sarlavhalaridan server vaqtini o'qiydi va farqni yangilaydi.
  ///
  /// Qaytadi: server vaqti (UTC) yoki sarlavha bo'lmasa/buzuq bo'lsa null.
  static DateTime? observeHeaders(Map<String, String> headers,
      {String host = hostNotification}) {
    final String? raw = headers['date'] ?? headers['Date'];
    DateTime? server;
    if (raw != null && raw.isNotEmpty) {
      try {
        server = HttpDate.parse(raw).toUtc();
      } catch (_) {
        server = null;
      }
    }
    if (server == null) {
      if (!_missingDateLogged) {
        // Proxy sarlavhani olib tashlagan/buzgan — kassa soatiga tayanib
        // qolamiz; buni bir marta ko'rinadigan qilamiz.
        _missingDateLogged = true;
        unawaited(LogHelper.activity(
            'SYNC_SERVER_DATE_MISSING', {'host': host, 'raw': raw}));
      }
      return null;
    }
    observe(server, host: host);
    return server;
  }

  /// Server vaqti ma'lum bo'lganda farqni yangilaydi.
  ///
  /// [local] — javob olingan mahalliy vaqt; berilmasa hozir. Bir soniyalik
  /// aniqlik yetarli: sinxron oynasida 2 daqiqalik overlap bor.
  static void observe(DateTime serverUtc,
      {DateTime? local, String host = hostNotification}) {
    _load();
    final DateTime at = (local ?? localNow()).toUtc();
    final Duration fresh = serverUtc.toUtc().difference(at);
    final Duration before = offset;
    _offsets[host] = fresh;
    final Duration after = offset;
    if ((after - before).abs() >= persistThreshold ||
        !_offsets.containsKey(_hostPersisted)) {
      _offsets[_hostPersisted] = after;
      unawaited(_persist(after));
    }
    _maybeWarn(after);
  }

  static Future<void> _persist(Duration value) async {
    try {
      await Pref.setInt(PrefKeys.serverClockOffsetMs, value.inMilliseconds);
    } catch (_) {
      // Ilova yopilayotganda (Hive.close) yozuv yiqilishi mumkin — bu
      // sinxronga ta'sir qilmasligi kerak.
    }
  }

  static void _maybeWarn(Duration skew) {
    if (skew.abs() < warnSkew) {
      _lastWarned = null;
      return;
    }
    // Bir xil farqni har daqiqada yozmaymiz — faqat o'zgarganda.
    final Duration? last = _lastWarned;
    if (last != null && (skew - last).abs() < const Duration(minutes: 1)) {
      return;
    }
    _lastWarned = skew;
    unawaited(LogHelper.activity('SYNC_CLOCK_SKEW', {
      // Musbat = kassa soati serverdan OLDINDA.
      'kassa_minus_server_s': -skew.inSeconds,
      'note': 'kassa soati/timezone tekshirilsin',
    }));
  }

  /// Faqat testlar uchun: xotiradagi holatni tozalaydi (Pref'ga tegmaydi).
  static void reset() {
    _offsets.clear();
    _loaded = false;
    _lastWarned = null;
    _missingDateLogged = false;
  }
}
