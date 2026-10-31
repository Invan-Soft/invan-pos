/*
    Kaftpay (pp-pos-api) HTTP klienti — swagger 2026-10-29.
    https://pos-api.kaftpay.uz/pp-pos-api/swagger-ui/index.html

    Har metod [KaftpayResult] qaytaradi, exception tashlamaydi.
    Pul oqimining xavfsizligi (javob yo'qolsa nima qilish) bu yerda emas —
    `KaftpayPaymentFlow` da. Bu sinf faqat: imzolash, yuborish, javobni
    to'g'ri tasniflash.

    Jonli serverdan (2026-10-29) kelib chiqqan qoidalar:
      - Tana HAR DOIM UTF-8 deb o'qiladi: 401 javob
        `charset=ISO-8859-1` deb keladi, `response.body` uni latin1 qilib
        buzardi.
      - Kassa soati ±300 s dan ko'p farq qilsa server `1100`
        ("timestamp out of range") beradi. HTTP `Date` header'idan soat
        farqi o'rganiladi va shunday 401 bo'lsa so'rov BIR marta tuzatilgan
        vaqt bilan qayta yuboriladi (1100 da server hech narsa qilmagan —
        qayta yuborish xavfsiz; yangi nonce, palmDataEnc ham qayta
        shifrlanadi).
      - Biometrik ma'lumot logga yozilmaydi: identify/enroll tanasi
        log/Alice'da `palmDataEnc` qisqartirilgan holda.
*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:invan2/alice_service.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_crypto.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_error.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:uuid/uuid.dart';

class KaftpayConfig {
  static const String prodBaseUrl = 'https://pos-api.kaftpay.uz/pp-pos-api';

  /// Context path bilan, oxirida `/` siz.
  final String baseUrl;
  final String clientId;

  /// Onboarding'da bir marta beriladi. Aynan berilgandek (UTF-8) ishlatiladi.
  final String secret;

  /// `reason` tili: `uz` | `ru` | `cyrl` | `en`.
  final String language;

  const KaftpayConfig({
    this.baseUrl = prodBaseUrl,
    required this.clientId,
    required this.secret,
    this.language = 'uz',
  });

  bool get isComplete =>
      clientId.trim().isNotEmpty && secret.isNotEmpty && baseUrl.isNotEmpty;
}

typedef KaftpayBodyBuilder = Future<Map<String, dynamic>> Function(
    String timestamp, String nonce);

class KaftpayApi {
  KaftpayApi({
    required this.config,
    http.Client? client,
    DateTime Function()? now,
    String Function()? newNonce,
    List<int> Function()? newIv,
    this.timeout = const Duration(seconds: 20),
    this.payTimeout = const Duration(seconds: 40),
  })  : _client = client ?? http.Client(),
        _now = now ?? DateTime.now,
        _newNonce = newNonce ?? (() => const Uuid().v4()),
        _newIv = newIv ?? KaftpayPalmCipher.randomIv;

  final KaftpayConfig config;
  final http.Client _client;
  final DateTime Function() _now;
  final String Function() _newNonce;
  final List<int> Function() _newIv;

  final Duration timeout;

  /// `/pay` ekvayerga boradi — uzoqroq. Timeout bo'lsa bu "pul ketmadi"
  /// degani EMAS — `KaftpayPaymentFlow` status bilan aniqlaydi.
  final Duration payTimeout;

  /// Server ±300 s ruxsat beradi; shundan kichik chegarada tuzatamiz.
  static const Duration clockSkewThreshold = Duration(seconds: 30);

  /// Server soati − kassa soati (`Date` header'dan). Kichik farqda 0.
  Duration get clockOffset => _clockOffset;
  Duration _clockOffset = Duration.zero;

  /// Testda almashtiriladi; ishda Alice'ga.
  static void Function(http.Response response) onHttpResponse = _toAlice;

  static void _toAlice(http.Response res) {
    try {
      alice.onHttpResponse(res);
    } catch (_) {}
  }

  // ─── Endpointlar ───────────────────────────────────────────────────────────

  /// Kalit, secret, soat va imzo to'g'riligini tekshiradi. Hech narsa yechmaydi.
  Future<KaftpayResult<KaftpayTerminalInfo>> ping() => _send(
        method: 'GET',
        path: '/api/v1/ping',
        parse: KaftpayTerminalInfo.fromJson,
      );

  /// Kaft → `requestId` + nomzodlar. Hech narsa yechmaydi.
  ///
  /// Qo'l ([KaftpayPalmScan.hand]) yuborilmaydi — server ikkala qo'l bilan
  /// solishtiradi. SDK `palm_type` kodlanishi qarama-qarshi (Kaftpay
  /// `pp-pos-app`: "palm_arithmetic.h:125 va :282 teskari, qurilmada
  /// tasdiqlanmagan"); noto'g'ri qo'l yuborilsa server boshqa qo'lni
  /// qidirib haqiqiy mijozni `no_match` qilardi. [filterByHand] — faqat
  /// qurilmada tasdiqlangandan keyin.
  Future<KaftpayResult<KaftpayIdentifyResult>> identify(
    KaftpayPalmScan scan, {
    int k = 5,
    bool filterByHand = false,
  }) {
    final invalid = scan.validate();
    if (invalid != null) return _localFail(invalid);
    return _send(
      method: 'POST',
      path: '/api/v1/identify',
      sensitiveBody: true,
      body: (ts, nonce) async => {
        'palmDataEnc': await _encryptScan(scan, ts, nonce),
        if (filterByHand && scan.hand != KaftpayHand.unspecified)
          'hand': scan.hand.wire,
        'k': k,
        'scannerModel': scan.scannerModel,
      },
      parse: KaftpayIdentifyResult.fromJson,
    );
  }

  /// Mijoz ilovasidagi QR (`PPENROLL:<id>` yoki faqat id) + kaft. Har qo'l
  /// alohida chaqiriladi.
  ///
  /// Serverga faqat UUID ketadi ([enrollSessionId]): hujjatda "server
  /// prefiksni o'zi olib tashlaydi" deyilgan, lekin jonli serverda
  /// (2026-10-31) `PPENROLL:<uuid>` → HTTP 200 + `9999`, faqat `<uuid>` →
  /// to'g'ri javob (`1150` / ACTIVE).
  ///
  /// Qo'l (chap/o'ng) MAJBURIY va kassir tanlaydi: `UNSPECIFIED` da server
  /// adashtiruvchi `1104` qaytaradi, QR sessiyasi esa ochiq qoladi.
  Future<KaftpayResult<KaftpayEnrollResult>> enroll({
    required String qrSessionId,
    required KaftpayPalmScan scan,
  }) {
    final qr = enrollSessionId(qrSessionId);
    if (qr.isEmpty) return _localFail('QR kod skanerlanmagan');
    if (scan.hand == KaftpayHand.unspecified) {
      return _localFail('Qo\'lni tanlang: chap yoki o\'ng');
    }
    final invalid = scan.validate();
    if (invalid != null) return _localFail(invalid);
    return _send(
      method: 'POST',
      path: '/api/v1/enroll',
      sensitiveBody: true,
      body: (ts, nonce) async => {
        'qrSessionId': qr,
        'palmDataEnc': await _encryptScan(scan, ts, nonce),
        'hand': scan.hand.wire,
        'scannerModel': scan.scannerModel,
      },
      parse: KaftpayEnrollResult.fromJson,
    );
  }

  /// QR matnidan sessiya id'si: bo'sh joylar va `PPENROLL:` prefiksi
  /// (katta-kichik harfsiz) olib tashlanadi.
  static String enrollSessionId(String qrText) {
    final s = qrText.trim();
    const prefix = 'PPENROLL:';
    return s.toUpperCase().startsWith(prefix)
        ? s.substring(prefix.length).trim()
        : s;
  }

  /// PUL YECHADI. [idempotencyKey] — bitta niyat qilingan to'lovga bitta;
  /// qayta urinishda aynan o'sha kalit.
  Future<KaftpayResult<KaftpayPayResult>> pay({
    required String idempotencyKey,
    required KaftpayPayRequest request,
  }) {
    if (idempotencyKey.trim().isEmpty) {
      return _localFail('Idempotency-Key bo\'sh');
    }
    final invalid = request.validate();
    if (invalid != null) return _localFail(invalid);
    final json = request.toJson();
    return _send(
      method: 'POST',
      path: '/api/v1/pay',
      headers: {'Idempotency-Key': idempotencyKey},
      timeoutOverride: payTimeout,
      body: (_, __) async => json,
      parse: KaftpayPayResult.fromJson,
    );
  }

  /// Faqat `/pay` javobi yo'qolganda. 200 — pul ketgan; `1210` — ketmagan.
  /// Hech narsa yechmaydi, takrorlash xavfsiz.
  Future<KaftpayResult<KaftpayPaymentStatus>> payStatus(String idempotencyKey) {
    if (idempotencyKey.trim().isEmpty) {
      return _localFail('Idempotency-Key bo\'sh');
    }
    return _send(
      method: 'GET',
      path: '/api/v1/pay/status/${Uri.encodeComponent(idempotencyKey)}',
      parse: KaftpayPaymentStatus.fromJson,
    );
  }

  /// To'liq vozvrat. Faqat shu terminal qilgan to'lov (`1217`).
  /// `1223` — natija noma'lum, QAYTA YUBORILMAYDI.
  Future<KaftpayResult<KaftpayRefundResult>> refund({
    required String transactionId,
    required String cashierId,
    required String cashierName,
    String? reason,
  }) {
    if (transactionId.trim().isEmpty) {
      return _localFail('Kaftpay tranzaksiya id\'si yo\'q');
    }
    if (cashierId.trim().isEmpty || cashierName.trim().isEmpty) {
      return _localFail('Kassir ma\'lumoti (id/ism) yo\'q');
    }
    final json = <String, dynamic>{
      'cashierId': cashierId.trim(),
      'cashierName': cashierName.trim(),
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    return _send(
      method: 'POST',
      path: '/api/v1/pay/${Uri.encodeComponent(transactionId)}/refund',
      timeoutOverride: payTimeout,
      body: (_, __) async => json,
      parse: KaftpayRefundResult.fromJson,
    );
  }

  /// Merchant-fiscalized terminal (`ofdEnabled=false`): o'zimiz chiqargan
  /// fiskal chek havolasini bildiramiz. Aynan o'sha havola bilan qayta
  /// yuborish xavfsiz.
  Future<KaftpayResult<KaftpayOfdReceiptResult>> attachOfdReceipt({
    required String transactionId,
    required String ofdReceiptUrl,
  }) {
    if (transactionId.trim().isEmpty) {
      return _localFail('Kaftpay tranzaksiya id\'si yo\'q');
    }
    final q = Uri.tryParse(ofdReceiptUrl.trim())?.queryParameters ?? const {};
    if (!['t', 'r', 'c', 's'].every((k) => (q[k] ?? '').isNotEmpty)) {
      return _localFail('Fiskal chek havolasida t, r, c, s yo\'q');
    }
    final json = {'ofdReceiptUrl': ofdReceiptUrl.trim()};
    return _send(
      method: 'POST',
      path: '/api/v1/pay/${Uri.encodeComponent(transactionId)}/ofd-receipt',
      body: (_, __) async => json,
      parse: KaftpayOfdReceiptResult.fromJson,
    );
  }

  // ─── Ichki ─────────────────────────────────────────────────────────────────

  Future<String> _encryptScan(KaftpayPalmScan scan, String ts, String nonce) =>
      KaftpayPalmCipher.encryptBytes(
        secret: config.secret,
        timestamp: ts,
        nonce: nonce,
        plaintext: utf8.encode(jsonEncode(scan.vectorsJson())),
        iv: _newIv(),
      );

  Future<KaftpayResult<T>> _localFail<T>(String reason) =>
      Future.value(KaftpayResult<T>.fail(KaftpayError.local(reason)));

  Future<KaftpayResult<T>> _send<T>({
    required String method,
    required String path,
    required T Function(Map<String, dynamic>) parse,
    KaftpayBodyBuilder? body,
    Map<String, String> headers = const {},
    Duration? timeoutOverride,
    bool sensitiveBody = false,
    bool clockRetry = true,
  }) async {
    if (!config.isComplete) {
      return KaftpayResult.fail(const KaftpayError.local(
          'Kaftpay sozlanmagan (client_id / secret yo\'q)'));
    }

    final localNow = _now();
    final ts = ((localNow.add(_clockOffset)).millisecondsSinceEpoch ~/ 1000)
        .toString();
    final nonce = _newNonce();

    final List<int> bytes;
    try {
      bytes = body == null
          ? const <int>[]
          : utf8.encode(jsonEncode(await body(ts, nonce)));
    } catch (e) {
      return KaftpayResult.fail(
          KaftpayError.local('So\'rovni tayyorlab bo\'lmadi: $e'));
    }

    final req = http.Request(method, Uri.parse('${config.baseUrl}$path'))
      ..headers.addAll({
        'Accept': 'application/json',
        'Accept-Language': config.language,
        'X-Client-Id': config.clientId,
        'X-Timestamp': ts,
        'X-Nonce': nonce,
        'X-Signature': KaftpaySigner.sign(
          secret: config.secret,
          method: method,
          path: path,
          body: bytes,
          timestamp: ts,
          nonce: nonce,
        ),
        if (body != null) 'Content-Type': 'application/json',
        ...headers,
      });
    if (body != null) req.bodyBytes = bytes;

    final started = DateTime.now();
    http.Response res;
    try {
      res = await http.Response.fromStream(
          await _client.send(req).timeout(timeoutOverride ?? timeout));
    } catch (e) {
      final timedOut = e is TimeoutException;
      await _log(LogLevel.warn,
          'KAFTPAY $method $path → javob yo\'q (${timedOut ? 'timeout' : e})');
      return KaftpayResult.fail(KaftpayError(
        kind: KaftpayErrorKind.network,
        cause: e,
        isTimeout: timedOut,
      ));
    }

    _reportToAlice(req, res, sensitiveBody, bytes);
    final skew = _learnClock(res, localNow);
    final result = _classify(res, parse);
    final err = result.error;

    await _log(
      err == null ? LogLevel.info : LogLevel.warn,
      'KAFTPAY $method $path → ${res.statusCode}'
      '${err == null ? ' ok' : ' ${err.kind.name} ${err.code ?? ''} ${err.reason ?? ''}'}'
      ' (${DateTime.now().difference(started).inMilliseconds} ms)',
    );

    if (clockRetry &&
        err != null &&
        err.code == KaftpayErrorCodes.signature &&
        skew != null &&
        skew.abs() >= clockSkewThreshold) {
      await _log(
          LogLevel.warn,
          'KAFTPAY: kassa soati serverdan ${skew.inSeconds} s farq qiladi — '
          'tuzatilgan vaqt bilan qayta yuborilmoqda');
      return _send(
        method: method,
        path: path,
        parse: parse,
        body: body,
        headers: headers,
        timeoutOverride: timeoutOverride,
        sensitiveBody: sensitiveBody,
        clockRetry: false,
      );
    }
    return result;
  }

  /// `Date` header'idan soat farqini o'rganadi; farqni qaytaradi.
  Duration? _learnClock(http.Response res, DateTime localNow) {
    final raw = res.headers['date'];
    if (raw == null) return null;
    DateTime server;
    try {
      server = HttpDate.parse(raw);
    } catch (_) {
      return null;
    }
    final skew = server.difference(localNow);
    _clockOffset = skew.abs() >= clockSkewThreshold ? skew : Duration.zero;
    return skew;
  }

  KaftpayResult<T> _classify<T>(
    http.Response res,
    T Function(Map<String, dynamic>) parse,
  ) {
    final status = res.statusCode;
    final text = utf8.decode(res.bodyBytes, allowMalformed: true);
    Object? json;
    try {
      json = text.trim().isEmpty ? null : jsonDecode(text);
    } catch (_) {
      json = null;
    }

    if (json is Map<String, dynamic> && json['success'] is bool) {
      final serverTime = KaftpayTime.parse(json['timestamp']);
      if (json['success'] == true) {
        final data = json['data'];
        if (data is! Map<String, dynamic>) {
          return KaftpayResult.fail(
            KaftpayError(
              kind: KaftpayErrorKind.badResponse,
              httpStatus: status,
              reason: 'success:true, lekin data yo\'q',
            ),
            serverTime: serverTime,
          );
        }
        try {
          return KaftpayResult.ok(parse(data), serverTime: serverTime);
        } catch (e) {
          return KaftpayResult.fail(
            KaftpayError(
              kind: KaftpayErrorKind.badResponse,
              httpStatus: status,
              reason: 'data tahlil qilinmadi: $e',
            ),
            serverTime: serverTime,
          );
        }
      }
      final code = json['code']?.toString();
      return KaftpayResult.fail(
        KaftpayError(
          kind: _kindOf(status, code),
          code: code,
          reason: json['reason']?.toString(),
          httpStatus: status,
        ),
        serverTime: serverTime,
      );
    }

    // Bean validation: HTTP 400 + tekis {field: message}.
    if (status == 400 &&
        json is Map<String, dynamic> &&
        json.isNotEmpty &&
        json.values.every((v) => v is String)) {
      return KaftpayResult.fail(KaftpayError(
        kind: KaftpayErrorKind.validation,
        httpStatus: status,
        fieldErrors: json.map((k, v) => MapEntry(k, v as String)),
      ));
    }

    // Spring default xatosi ({"status":403,"error":"Forbidden"}) yoki HTML.
    final reason = json is Map ? json['error']?.toString() : null;
    final KaftpayErrorKind kind;
    if (status == 401 || status == 403) {
      kind = KaftpayErrorKind.auth;
    } else if (status >= 500) {
      kind = KaftpayErrorKind.server;
    } else {
      kind = KaftpayErrorKind.badResponse;
    }
    return KaftpayResult.fail(KaftpayError(
      kind: kind,
      httpStatus: status,
      reason: reason ?? (text.length > 200 ? text.substring(0, 200) : text),
    ));
  }

  static KaftpayErrorKind _kindOf(int status, String? code) {
    if (code == KaftpayErrorCodes.signature ||
        code == KaftpayErrorCodes.ipNotAllowed ||
        code == '1002' ||
        status == 401 ||
        status == 403) {
      return KaftpayErrorKind.auth;
    }
    if (code == KaftpayErrorCodes.unexpected || status >= 500) {
      return KaftpayErrorKind.server;
    }
    if (status == 400) return KaftpayErrorKind.business;
    // HTTP 200 + success:false + noma'lum kod — ehtiyot uchun server xatosi.
    return KaftpayErrorKind.server;
  }

  /// Alice'ga — identify/enroll tanasidagi shifrlangan vektor qisqartiriladi.
  static void _reportToAlice(
    http.Request sent,
    http.Response res,
    bool sensitive,
    List<int> bytes,
  ) {
    try {
      final shown = http.Request(sent.method, sent.url)
        ..headers.addAll(sent.headers)
        ..body = sensitive ? redactBody(bytes) : utf8.decode(bytes);
      onHttpResponse(http.Response.bytes(
        res.bodyBytes,
        res.statusCode,
        headers: res.headers,
        request: shown,
      ));
    } catch (_) {}
  }

  /// `palmDataEnc` / `ir` / `rgb` o'rniga uzunligi.
  static String redactBody(List<int> bytes) {
    try {
      final m = jsonDecode(utf8.decode(bytes));
      if (m is! Map<String, dynamic>) return '<${bytes.length} bayt>';
      return jsonEncode(m.map((k, v) {
        if (k == 'palmDataEnc' && v is String) {
          return MapEntry(k, '<${v.length} belgi>');
        }
        if ((k == 'ir' || k == 'rgb') && v is List) {
          return MapEntry(k, '<${v.length} float>');
        }
        return MapEntry(k, v);
      }));
    } catch (_) {
      return '<${bytes.length} bayt>';
    }
  }

  static Future<void> _log(LogLevel level, String msg) async {
    try {
      await LogHelper.write(level, msg);
    } catch (_) {}
  }
}
