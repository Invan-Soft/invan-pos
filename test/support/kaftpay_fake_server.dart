// Kaftpay testlari uchun soxta pp-pos-api.
//
// Haqiqiy server kabi QATTIQ: har so'rovning imzosini o'zi (KaftpaySigner'ga
// tayanmasdan) qayta hisoblaydi va mos kelmasa 401/1100 qaytaradi. Javoblar
// `on(METHOD, path, ...)` bilan navbatga qo'yiladi; navbat bo'sh bo'lsa 599 —
// test kutmagan so'rov yuborilganini darhol ko'rsatadi.
import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeKaftpay {
  FakeKaftpay({this.secret = 'test-secret', this.clientId = 'pos-test'});

  final String secret;
  final String clientId;
  static const String contextPath = '/pp-pos-api';

  final List<http.Request> requests = [];
  final Map<String, List<Object>> _script = {};

  /// [response]: [http.Response], [Exception] (tashlanadi) yoki
  /// `Future<http.Response>` (masalan hech qachon tugamaydigan — timeout).
  void on(String method, String path, Object response) =>
      _script.putIfAbsent('$method $path', () => []).add(response);

  List<http.Request> calls(String method, String path) => requests
      .where((r) => r.method == method && pathOf(r) == path)
      .toList();

  static String pathOf(http.BaseRequest r) {
    final p = r.url.path;
    return p.startsWith(contextPath) ? p.substring(contextPath.length) : p;
  }

  Map<String, dynamic> jsonBody(http.Request r) =>
      jsonDecode(utf8.decode(r.bodyBytes)) as Map<String, dynamic>;

  /// Server tomonidagi imzo tekshiruvi — swagger §1 dan qayta yozilgan.
  bool signatureValid(http.Request r) {
    final h = r.headers;
    final ts = h['x-timestamp'];
    final nonce = h['x-nonce'];
    final sig = h['x-signature'];
    if (ts == null || nonce == null || sig == null) return false;
    if (h['x-client-id'] != clientId) return false;
    final bodyHash =
        base64.encode(crypto.sha256.convert(r.bodyBytes).bytes);
    final canon = '${r.method}\n${pathOf(r)}\n$bodyHash\n$ts\n$nonce';
    final expected = base64.encode(crypto.Hmac(crypto.sha256, utf8.encode(secret))
        .convert(utf8.encode(canon))
        .bytes);
    return expected == sig;
  }

  MockClient get client => MockClient((req) async {
        requests.add(req);
        if (!signatureValid(req)) {
          return fail('1100', 'signature mismatch', status: 401);
        }
        final queue = _script['${req.method} ${pathOf(req)}'];
        if (queue == null || queue.isEmpty) {
          return http.Response('kutilmagan so\'rov: ${req.method} ${pathOf(req)}',
              599);
        }
        final next = queue.removeAt(0);
        if (next is Exception) throw next;
        if (next is Future<http.Response>) return next;
        return next as http.Response;
      });

  // ─── Javob yasovchilar ─────────────────────────────────────────────────────

  static const Map<String, String> jsonHeaders = {
    'content-type': 'application/json',
  };

  static http.Response ok(
    Map<String, dynamic> data, {
    int status = 200,
    Map<String, String> headers = jsonHeaders,
  }) =>
      http.Response.bytes(
        utf8.encode(jsonEncode({
          'success': true,
          'timestamp': '01.08.2026 15:06:12',
          'data': data,
        })),
        status,
        headers: headers,
      );

  static http.Response fail(
    String code,
    String reason, {
    int status = 400,
    Map<String, String> headers = jsonHeaders,
    bool withTimestamp = true,
  }) =>
      http.Response.bytes(
        utf8.encode(jsonEncode({
          'success': false,
          if (withTimestamp) 'timestamp': '01.08.2026 15:06:12',
          'code': code,
          'reason': reason,
        })),
        status,
        headers: headers,
      );

  static http.Response raw(String body, int status,
          {Map<String, String> headers = const {}}) =>
      http.Response.bytes(utf8.encode(body), status, headers: headers);

  /// Hech qachon tugamaydigan javob — klient timeout'ini sinash uchun.
  static Future<http.Response> never() => Completer<http.Response>().future;
}

/// Swagger misollaridan.
const kRequestId = '7e9a4b21-3c8d-4f56-9a0b-2d4e6f8a1c33';
const kConsumer = '9c1f2a77-5d63-4a10-8f2b-1c0d5e6a7b88';
const kConsumer2 = '2b7d905c-11ae-4f2d-9c6b-8a3f0e5d4172';
const kTx = '5b1e0d84-6f2a-4c37-9b55-0e7a3c1d9f60';
const kKey = 'b8c5a1e2-40df-4d7a-9f31-6c2b0a94e7d5';

/// `gen_identify_curl.py` dagi soxta skan: 516 float, norma > 0.
List<double> fakeIr([int n = 516]) =>
    List<double>.generate(n, (i) => ((i % 23) - 11) / 11);

Map<String, dynamic> payData({
  String ofdStatus = 'AWAITING_EXTERNAL',
  int amount = 2500000,
}) =>
    {
      'transactionId': kTx,
      'status': 'SUCCESS',
      'amount': amount,
      'acquirerRef': 'STUB-OK-abcdef',
      'ofdStatus': ofdStatus,
    };

Map<String, dynamic> statusData({
  String status = 'SUCCESS',
  String requestStatus = 'CHARGED',
  String requestId = kRequestId,
  int amount = 2500000,
}) =>
    {
      'idempotencyKey': kKey,
      'requestId': requestId,
      'requestStatus': requestStatus,
      'transactionId': kTx,
      'status': status,
      'amount': amount,
      'currency': 'UZS',
      'consumerGuid': kConsumer,
      'cardMask': '8600****1234',
      'acquirerRef': 'STUB-OK-abcdef',
      'ofdStatus': 'AWAITING_EXTERNAL',
      'cashierId': 'c-17',
      'cashierName': 'Nodira S.',
      'paidAt': '01.08.2026 15:06:12',
    };
