/*
    Bitta `GET /notifications` so'rovi va uning qo'llanishi — uchala oqim
    (mahsulot, kategoriya, diskont) uchun yagona kod.

    Ilgari uch xizmat bir xil kodni ko'chirib yurardi va hammasida bir xil
    tirqichlar bor edi:

      * bitta notification parse bo'lmasa (masalan `images: []`,
        `category_ids: null`) BUTUN oyna `failed` bo'lardi → kursor joyida
        qolardi → har daqiqa o'sha xato → 14 kungacha yoki qo'lda to'liq
        yangilashgacha HECH NARSA (narx ham) yangilanmasdi;
      * xato faqat debug'da print bo'lardi — do'konda izsiz;
      * notification'lar server bergan tartibda qo'llanardi (asc/desc
        noma'lum) — eski `create` yangi `update` ustidan yozishi mumkin edi;
      * server vaqti (HTTP `date`) o'qilmasdi — kassa soati oldinda bo'lsa
        kursor kelajakka ketardi;
      * 20 s UMUMIY timeout — sekin internetda katta javob hech qachon
        sig'masdi.

    Endi: har notification alohida himoyada, xatolik log'ga yoziladi va
    natijada `applyFailed` bayrog'i qaytadi (StreamSyncRunner to'liq yuklash
    bilan qoplaydi); `created_at` bo'yicha tartiblanadi; server vaqti
    natijada qaytadi; timeout — sarlavha kutish + bo'laklar orasidagi sukut
    (umumiy chegara yo'q, sekin bo'lsa ham oqib kelaveradi).
*/

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../alice_service.dart';
import '../../../utils/constants/pref_keys.dart';
import '../../../utils/helpers/prefs.dart';
import '../log_helper.dart';
import '../web_socket_service/urls/urls.dart';
import 'server_clock.dart';
import 'sync_cursor.dart';

/// Bitta notification'ni qo'llash natijasi.
enum NotifyApply {
  /// Lokal bazaga yozildi — oyna oxirida keshlar yangilanadi.
  applied,

  /// Bu turdagi notification bizga kerak emas (yoki keshga ta'sir qilmaydi).
  ignored,

  /// Qo'llab bo'lmadi va davom etishning ma'nosi yo'q. Oyna muvaffaqiyatsiz
  /// hisoblanadi, kursor surilmaydi, keyingi daqiqada qayta uriniladi.
  abort,

  /// Server "hammasini qayta yukla" dedi (type 0). Oynani qo'llash
  /// to'xtatiladi; runner bitta to'liq yuklash qiladi va kursorni suradi.
  fullReload,
}

typedef ApplyNotification = Future<NotifyApply> Function(
    Map<String, dynamic> ws);

class NotificationFetch {
  NotificationFetch._();

  static const int limit = 1000;

  /// Ulanish va javob sarlavhalarini kutish chegarasi.
  ///
  /// Testlar qisqartiradi (const emas).
  static Duration timeout = const Duration(seconds: 30);

  /// Javob tanasi oqimida ketma-ket ikki bo'lak orasidagi maksimal sukut.
  /// Umumiy chegara emas: sekin internetda katta javob uzoq oqishi mumkin,
  /// muhimi to'xtab qolmasin.
  static Duration idleTimeout = const Duration(seconds: 45);

  /// Log'ga yoziladigan javob tanasining maksimal uzunligi. To'liq tana
  /// (1000 mahsulot — MB'lar) 24 soatlik logni to'ldirib yuborardi;
  /// diagnostika uchun boshlanishi + `SYNC_WINDOW` hisobi yetarli.
  static const int logBodyLimit = 4000;

  /// Testlar uchun almashtiriladigan HTTP klient.
  static http.Client? client;

  static Map<String, String> headers(String token) => <String, String>{
        "timezone": "-300",
        "Vary": "Origin",
        "Strict-Transport-Security": "Strict-Transport-Security",
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
        "Authorization": "Bearer $token",
        // Do'kon tarmog'idagi proxy eski javobni qaytarmasin.
        "Cache-Control": "no-cache, no-store, max-age=0",
        "Pragma": "no-cache",
      };

  /// `is_read=false` — 2026-08-21'da jonli tekshirilgan YAGONA konfiguratsiya
  /// (qarang: docs/sessions/archive/2026-08-21-price-sync-missing-on-some-kassas.md).
  /// Bu parametrni olib tashlash (masalan boshqa klient "o'qildi" deb
  /// belgilasa ham kassa ko'rishi uchun) jozibali, lekin server buni qanday
  /// talqin qilishi TEKSHIRILMAGAN — noto'g'ri taxmin aynan bizni
  /// yo'qotayotgan xato turini (jim, doimiy notification yo'qolishi)
  /// qaytarishi mumkin. Shuning uchun ataylab O'ZGARTIRILMAGAN.
  static String buildPath({
    required String companyId,
    required String types,
    required String startDate,
    required String endDate,
  }) {
    return "${Urls.baseNotificationUrl}notifications?company_id=$companyId&limit=$limit&offset=1&type=$types&is_read=false&start_date=$startDate&end_date=$endDate";
  }

  /// [types] — vergul bilan ajratilgan notification turlari.
  /// [apply] — bitta notification'ni lokalga qo'llaydi; istisno tashlasa
  /// faqat o'sha notification "qo'llanmadi" deb belgilanadi.
  /// [afterBatch] — kamida bitta notification qo'llangan bo'lsa oyna
  /// oxirida BIR marta chaqiriladi (keshlarni yangilash uchun).
  static Future<SyncFetchResult> run({
    required String label,
    required String types,
    required String startDate,
    required String endDate,
    required ApplyNotification apply,
    Future<void> Function()? afterBatch,
  }) async {
    final String token = Pref.getString(PrefKeys.token, 'not initialized');
    if (token.isEmpty || token == 'not initialized') {
      return const SyncFetchResult.failed();
    }

    final String comId = Pref.getString(PrefKeys.orgID, "");
    final String path = buildPath(
        companyId: comId, types: types, startDate: startDate, endDate: endDate);

    final _Fetched fetched = await _get(path, token, label, startDate, endDate);
    if (fetched.result != null) return fetched.result!;

    final http.Response response = fetched.response!;

    await LogHelper.logRequest(
        method: "GET",
        path: path,
        statusCode: response.statusCode,
        response: _shortBody(response.body));
    try {
      alice.onHttpResponse(response);
    } catch (_) {}

    // Server soati — kursor bundan oldinga o'tmaydi.
    final DateTime? serverTime =
        ServerClock.observeHeaders(response.headers, host: ServerClock.hostNotification);

    if (response.statusCode != 200) {
      final bool unauthorized =
          response.statusCode == 401 || response.statusCode == 403;
      await LogHelper.activity(unauthorized ? 'SYNC_UNAUTHORIZED' : 'SYNC_FETCH_HTTP',
          {'stream': label, 'status': response.statusCode});
      return SyncFetchResult.failed(
          serverTime: serverTime, unauthorized: unauthorized);
    }

    List<dynamic> notifications;
    int? totalCount;
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const FormatException('javob obyekt emas');
      }
      final dynamic raw = decoded['notifications'];
      if (raw == null &&
          !decoded.containsKey('notifications') &&
          (decoded.containsKey('error') || decoded.containsKey('message'))) {
        // 200 bilan kelgan xato tanasi — bo'sh oyna deb qabul qilinmasin.
        throw FormatException('server xato tanasi: ${_shortBody(response.body, 200)}');
      }
      notifications = raw is List ? raw : const <dynamic>[];
      final dynamic tc = decoded['total_count'];
      if (tc is num) totalCount = tc.toInt();
    } catch (e) {
      await LogHelper.activity(
          'SYNC_FETCH_PARSE', {'stream': label, 'error': e});
      return SyncFetchResult.failed(serverTime: serverTime);
    }

    int applied = 0;
    int ignored = 0;
    int noId = 0;
    bool applyFailed = false;
    bool fullReloadRequested = false;

    final _Sorted sorted = sortByCreatedAtDetailed(notifications);
    if (sorted.unparsed > 0) {
      await LogHelper.activity('SYNC_CREATED_AT_UNPARSED', {
        'stream': label,
        'count': sorted.unparsed,
        'sample': sorted.sample,
      });
    }

    for (final dynamic ws in sorted.list) {
      if (ws is! Map) {
        noId++;
        continue;
      }
      final Map<String, dynamic> m = Map<String, dynamic>.from(ws);
      if (m['id'] == null) {
        noId++;
        continue;
      }

      try {
        final NotifyApply outcome = await apply(m);
        if (outcome == NotifyApply.abort) {
          await LogHelper.activity('SYNC_APPLY_ABORT',
              {'stream': label, 'id': m['id'], 'type': m['type']});
          if (applied > 0 && afterBatch != null) await afterBatch();
          return SyncFetchResult.failed(serverTime: serverTime);
        }
        if (outcome == NotifyApply.fullReload) {
          fullReloadRequested = true;
          break;
        }
        if (outcome == NotifyApply.applied) {
          applied++;
        } else {
          ignored++;
        }
      } catch (e, stack) {
        // Faqat shu notification. Oyna oxirida `applyFailed` bilan
        // qaytadi — StreamSyncRunner to'liq yuklash bilan qoplaydi.
        applyFailed = true;
        await LogHelper.activity('SYNC_APPLY_FAILED', {
          'stream': label,
          'id': m['id'],
          'type': m['type'],
          'error': e,
          'stack': stack,
        });
      }
    }

    if (applied > 0 && afterBatch != null) await afterBatch();

    // Har oyna uchun bitta qisqa qator — "so'ralganmi, nechta kelgan,
    // nechta qo'llangan" savoliga 24 soatlik logdan javob topish uchun.
    await LogHelper.activity('SYNC_WINDOW', {
      'stream': label,
      'start': startDate,
      'end': endDate,
      'received': notifications.length,
      'applied': applied,
      'ignored': ignored,
      'no_id': noId,
      'failed': applyFailed,
      'full_reload': fullReloadRequested,
      'server_time': serverTime?.toIso8601String(),
    });

    // `total_count`: server sahifa hajmini `limit`dan kichik cheklagan
    // bo'lsa ham (masalan 500), qaytgan qator soni ondan kam bo'lib,
    // faqat `length >= limit` bilan aniqlanmaydigan yashirin kesish
    // (notification'lar jim yo'qolishi) shu bilan ushlanadi.
    final bool truncated = notifications.length >= limit ||
        (totalCount != null && totalCount > notifications.length);

    return SyncFetchResult.done(
      notifications.length,
      truncated: truncated,
      serverTime: serverTime,
      applyFailed: applyFailed,
      fullReloadRequested: fullReloadRequested,
    );
  }

  /// So'rovni yuboradi. Tarmoq/timeout xatosi bo'lsa tayyor natija,
  /// aks holda javob qaytadi (status tekshirilmaydi).
  static Future<_Fetched> _get(String path, String token, String label,
      String startDate, String endDate) async {
    http.Client? owned;
    try {
      final http.Client c = client ?? (owned = http.Client());
      final http.Request request = http.Request('GET', Uri.parse(path));
      request.headers.addAll(headers(token));
      final http.StreamedResponse streamed =
          await c.send(request).timeout(timeout);
      final List<int> bytes = await streamed.stream
          .timeout(idleTimeout, onTimeout: (EventSink<List<int>> s) {
            s.addError(TimeoutException(
                'javob oqimi to\'xtab qoldi', idleTimeout));
            s.close();
          })
          .expand((chunk) => chunk)
          .toList();
      final http.Response response = http.Response.bytes(
        bytes,
        streamed.statusCode,
        headers: streamed.headers,
        request: request,
        reasonPhrase: streamed.reasonPhrase,
      );
      return _Fetched(response: response);
    } on TimeoutException {
      await LogHelper.activity('SYNC_FETCH_TIMEOUT',
          {'stream': label, 'start': startDate, 'end': endDate});
      return const _Fetched(result: SyncFetchResult.failed(timedOut: true));
    } catch (e) {
      await LogHelper.activity('SYNC_FETCH_ERROR',
          {'stream': label, 'start': startDate, 'end': endDate, 'error': e});
      return const _Fetched(result: SyncFetchResult.failed());
    } finally {
      owned?.close();
    }
  }

  static String _shortBody(String body, [int max = logBodyLimit]) {
    if (body.length <= max) return body;
    return '${body.substring(0, max)}…(${body.length} belgi)';
  }

  /// `created_at` bo'yicha o'sish tartibida — eski o'zgarish avval, yangisi
  /// keyin qo'llanadi. Vaqti o'qilmaydiganlar asl tartibida oldinda.
  /// Tartiblash barqaror: teng vaqtlar asl tartibini saqlaydi.
  static List<dynamic> sortByCreatedAt(List<dynamic> list) =>
      sortByCreatedAtDetailed(list).list;

  static _Sorted sortByCreatedAtDetailed(List<dynamic> list) {
    final List<_Keyed> keyed = <_Keyed>[];
    int unparsed = 0;
    String? sample;
    for (int i = 0; i < list.length; i++) {
      final dynamic e = list[i];
      DateTime? at;
      if (e is Map) {
        at = parseCreatedAt(e['created_at']);
        if (at == null) {
          unparsed++;
          sample ??= '${e['created_at']}';
        }
      }
      keyed.add(_Keyed(i, at, e));
    }
    keyed.sort((a, b) {
      final DateTime? x = a.at;
      final DateTime? y = b.at;
      if (x == null && y == null) return a.index.compareTo(b.index);
      if (x == null) return -1;
      if (y == null) return 1;
      final int c = x.compareTo(y);
      return c != 0 ? c : a.index.compareTo(b.index);
    });
    return _Sorted(keyed.map((e) => e.value).toList(), unparsed, sample);
  }

  /// ISO 8601 (T yoki bo'sh joy bilan), epoch soniya/millisekund (raqam
  /// yoki raqamli satr).
  static final RegExp _digitsOnly = RegExp(r'^-?\d+$');

  static DateTime? parseCreatedAt(dynamic value) {
    if (value is num) return _fromEpoch(value);
    if (value is String && value.isNotEmpty) {
      // Sof raqamli satr avval epoch deb sinaladi: `DateTime.tryParse`
      // "1790000000" kabi satrni yil sifatida (kengaytirilgan ISO 8601,
      // 178999-11-30) noto'g'ri talqin qiladi — sana emas, chalkash natija.
      if (_digitsOnly.hasMatch(value)) {
        final num? n = num.tryParse(value);
        if (n != null) return _fromEpoch(n);
      }
      final DateTime? iso = DateTime.tryParse(value);
      if (iso != null) return iso;
    }
    return null;
  }

  static DateTime _fromEpoch(num v) {
    final int ms = v < 1e11 ? (v * 1000).round() : v.round();
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }
}

class _Fetched {
  final http.Response? response;
  final SyncFetchResult? result;

  const _Fetched({this.response, this.result});
}

class _Sorted {
  final List<dynamic> list;
  final int unparsed;
  final String? sample;

  const _Sorted(this.list, this.unparsed, this.sample);
}

class _Keyed {
  final int index;
  final DateTime? at;
  final dynamic value;

  const _Keyed(this.index, this.at, this.value);
}
