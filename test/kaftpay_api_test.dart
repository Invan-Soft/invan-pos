// KaftpayApi — imzo header'lari, har endpointning so'rov/javob shakli va
// xato tasnifi (swagger + 2026-10-29 da jonli serverda ko'rilgan shakllar).
//
// Soxta server (support/kaftpay_fake_server.dart) imzoni o'zi tekshiradi —
// imzosi noto'g'ri so'rov 401/1100 oladi, shuning uchun "ok" bilan o'tgan
// har test imzo to'g'riligini ham isbotlaydi.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_crypto.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_error.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';

import 'support/kaftpay_fake_server.dart';

/// 2030-01-01 00:00:00 UTC = 1893456000.
final kNow = DateTime.utc(2030, 1, 1);

void main() {
  late FakeKaftpay server;
  late List<http.Response> alice;
  var nonceSeq = 0;

  KaftpayApi api({
    DateTime Function()? now,
    String secret = 'test-secret',
    String clientId = 'pos-test',
    Duration timeout = const Duration(seconds: 5),
    Duration payTimeout = const Duration(seconds: 5),
    String language = 'uz',
  }) =>
      KaftpayApi(
        config: KaftpayConfig(
          baseUrl: 'https://pos-api.kaftpay.uz/pp-pos-api',
          clientId: clientId,
          secret: secret,
          language: language,
        ),
        client: server.client,
        now: now ?? () => kNow,
        newNonce: () => 'nonce-${++nonceSeq}',
        timeout: timeout,
        payTimeout: payTimeout,
      );

  KaftpayPayRequest payRequest({
    int amount = 2500000,
    List<KaftpayReceiptItem>? products,
    String cashierId = 'c-17',
    String cashierName = 'Nodira S.',
  }) =>
      KaftpayPayRequest(
        requestId: kRequestId,
        consumerGuid: kConsumer,
        amount: amount,
        cashierId: cashierId,
        cashierName: cashierName,
        products: products,
      );

  setUp(() {
    server = FakeKaftpay();
    alice = [];
    nonceSeq = 0;
    KaftpayApi.onHttpResponse = alice.add;
  });

  group('imzo header\'lari', () {
    test('GET /ping — to\'rt header, context path imzolanmaydi', () async {
      server.on(
          'GET', '/api/v1/ping', FakeKaftpay.ok({'clientId': 'pos-test'}));
      final r = await api().ping();
      expect(r.isOk, isTrue, reason: '${r.error}');

      final req = server.requests.single;
      expect(req.url.toString(),
          'https://pos-api.kaftpay.uz/pp-pos-api/api/v1/ping');
      expect(req.headers['x-client-id'], 'pos-test');
      expect(req.headers['x-timestamp'], '1893456000');
      expect(req.headers['x-nonce'], 'nonce-1');
      expect(req.headers['x-signature'], isNotEmpty);
      expect(req.headers['accept-language'], 'uz');
      expect(req.bodyBytes, isEmpty);
      expect(req.headers.containsKey('content-type'), isFalse);
    });

    test('har so\'rovga yangi nonce', () async {
      server.on('GET', '/api/v1/ping', FakeKaftpay.ok({}));
      server.on('GET', '/api/v1/ping', FakeKaftpay.ok({}));
      final a = api();
      await a.ping();
      await a.ping();
      expect(
          server.requests.map((r) => r.headers['x-nonce']).toSet().length, 2);
    });

    test('noto\'g\'ri secret → server 1100, auth', () async {
      final r = await api(secret: 'boshqa').ping();
      expect(r.isOk, isFalse);
      expect(r.error!.kind, KaftpayErrorKind.auth);
      expect(r.error!.code, '1100');
      expect(r.error!.message, contains('client_id/secret'));
    });

    test('Accept-Language sozlamadan', () async {
      server.on('GET', '/api/v1/ping', FakeKaftpay.ok({}));
      await api(language: 'ru').ping();
      expect(server.requests.single.headers['accept-language'], 'ru');
    });

    test('sozlama to\'liq emas → tarmoqqa chiqmaydi', () async {
      final r = await api(clientId: ' ').ping();
      expect(r.error!.kind, KaftpayErrorKind.local);
      expect(server.requests, isEmpty);
    });
  });

  group('javob tasnifi', () {
    test('/ping muvaffaqiyat — terminal ma\'lumoti', () async {
      server.on(
          'GET',
          '/api/v1/ping',
          FakeKaftpay.ok({
            'clientId': 'pos-7f3c1a9e',
            'terminalCode': 'TRM-0042',
            'committentTin': '313114554',
            'ofdEnabled': false,
            'isTest': true,
            'status': 'ACTIVE',
          }));
      final r = await api().ping();
      final d = r.data!;
      expect(d.clientId, 'pos-7f3c1a9e');
      expect(d.terminalCode, 'TRM-0042');
      expect(d.committentTin, '313114554');
      expect(d.ofdEnabled, isFalse);
      expect(d.isTest, isTrue);
      expect(d.isActive, isTrue);
      expect(r.serverTime, DateTime.utc(2026, 8, 1, 10, 6, 12));
    });

    test('401 charset=ISO-8859-1, tana UTF-8 — kirill matn buzilmaydi',
        () async {
      // Jonli server 401 ni aynan shu content-type bilan qaytaradi.
      server.on(
          'GET',
          '/api/v1/ping',
          FakeKaftpay.fail('1108', 'Ruxsat yo‘q — доступ запрещён',
              status: 401,
              withTimestamp: false,
              headers: {
                'content-type': 'application/json;charset=ISO-8859-1'
              }));
      final r = await api().ping();
      expect(r.error!.kind, KaftpayErrorKind.auth);
      expect(r.error!.code, '1108');
      expect(r.error!.reason, 'Ruxsat yo‘q — доступ запрещён');
      expect(r.error!.message, contains('IP'));
    });

    test('envelope\'siz Spring 403 (header\'larsiz so\'rov) → auth', () async {
      server.on(
          'GET',
          '/api/v1/ping',
          FakeKaftpay.raw(
              '{"timestamp":"2026-10-29T12:58:50.394Z","status":403,'
              '"error":"Forbidden","path":"/pp-pos-api/api/v1/ping"}',
              403,
              headers: FakeKaftpay.jsonHeaders));
      final r = await api().ping();
      expect(r.error!.kind, KaftpayErrorKind.auth);
      expect(r.error!.code, isNull);
      expect(r.error!.reason, 'Forbidden');
      expect(r.error!.httpStatus, 403);
    });

    test(
        'HTTP 200 + success:false + 9999 → server (status emas, success ustun)',
        () async {
      server.on('GET', '/api/v1/ping',
          FakeKaftpay.fail('9999', 'An unexpected error', status: 200));
      final r = await api().ping();
      expect(r.isOk, isFalse);
      expect(r.error!.kind, KaftpayErrorKind.server);
      expect(r.error!.code, '9999');
      expect(r.error!.httpStatus, 200);
    });

    test('HTTP 200 + 1002 → auth', () async {
      server.on('GET', '/api/v1/ping',
          FakeKaftpay.fail('1002', 'Permission denied', status: 200));
      final r = await api().ping();
      expect(r.error!.kind, KaftpayErrorKind.auth);
    });

    test('400 + kod → business, o\'zbekcha xabar', () async {
      server.on('POST', '/api/v1/pay',
          FakeKaftpay.fail('1203', 'The selected consumer is not among ...'));
      final r = await api().pay(idempotencyKey: kKey, request: payRequest());
      expect(r.error!.kind, KaftpayErrorKind.business);
      expect(r.error!.code, '1203');
      expect(
          r.error!.message, 'Tanlangan mijoz aniqlanganlar ro\'yxatida yo\'q');
    });

    test('noma\'lum kod — server matni ko\'rsatiladi', () async {
      server.on(
          'POST', '/api/v1/pay', FakeKaftpay.fail('1299', 'Yangi xato turi'));
      final r = await api().pay(idempotencyKey: kKey, request: payRequest());
      expect(r.error!.kind, KaftpayErrorKind.business);
      expect(r.error!.message, 'Yangi xato turi');
    });

    test('400 tekis {field: message} → validation', () async {
      server.on('POST', '/api/v1/pay',
          FakeKaftpay.raw('{"amount":"must not be null"}', 400));
      final r = await api().pay(idempotencyKey: kKey, request: payRequest());
      expect(r.error!.kind, KaftpayErrorKind.validation);
      expect(r.error!.fieldErrors, {'amount': 'must not be null'});
      expect(r.error!.message, contains('amount — must not be null'));
    });

    test('502 HTML (nginx) → server', () async {
      server.on('GET', '/api/v1/ping',
          FakeKaftpay.raw('<html>502 Bad Gateway</html>', 502));
      final r = await api().ping();
      expect(r.error!.kind, KaftpayErrorKind.server);
      expect(r.error!.httpStatus, 502);
    });

    test('200, lekin JSON emas → badResponse', () async {
      server.on('GET', '/api/v1/ping', FakeKaftpay.raw('OK', 200));
      final r = await api().ping();
      expect(r.error!.kind, KaftpayErrorKind.badResponse);
    });

    test('success:true, data yo\'q → badResponse', () async {
      server.on('GET', '/api/v1/ping',
          FakeKaftpay.raw('{"success":true,"timestamp":"x"}', 200));
      final r = await api().ping();
      expect(r.error!.kind, KaftpayErrorKind.badResponse);
    });

    test('ulanish yo\'q → network', () async {
      server.on(
          'GET', '/api/v1/ping', const SocketException('Failed host lookup'));
      final r = await api().ping();
      expect(r.error!.kind, KaftpayErrorKind.network);
      expect(r.error!.isTimeout, isFalse);
      expect(r.error!.message, contains('ulanib bo\'lmadi'));
    });

    test('javob kelmasa → network + isTimeout', () async {
      server.on('GET', '/api/v1/ping', FakeKaftpay.never());
      final r = await api(timeout: const Duration(milliseconds: 50)).ping();
      expect(r.error!.kind, KaftpayErrorKind.network);
      expect(r.error!.isTimeout, isTrue);
      expect(r.error!.message, contains('vaqtida javob bermadi'));
    });

    test('/pay o\'z timeout\'i bilan (payTimeout)', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.never());
      final sw = Stopwatch()..start();
      final r = await api(
        timeout: const Duration(seconds: 30),
        payTimeout: const Duration(milliseconds: 50),
      ).pay(idempotencyKey: kKey, request: payRequest());
      expect(r.error!.isTimeout, isTrue);
      expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
    });
  });

  group('kassa soati noto\'g\'ri', () {
    String dateHeader(DateTime t) => HttpDate.format(t);

    test('1100 + Date 10 daqiqa oldinda → bir marta tuzatilgan vaqt bilan',
        () async {
      final serverNow = kNow.add(const Duration(minutes: 10));
      server.on(
          'GET',
          '/api/v1/ping',
          FakeKaftpay.fail('1100', 'timestamp out of range',
              status: 401,
              headers: {
                ...FakeKaftpay.jsonHeaders,
                'date': dateHeader(serverNow)
              }));
      server.on(
          'GET',
          '/api/v1/ping',
          FakeKaftpay.ok({
            'status': 'ACTIVE'
          }, headers: {
            ...FakeKaftpay.jsonHeaders,
            'date': dateHeader(serverNow)
          }));
      final a = api();
      final r = await a.ping();
      expect(r.isOk, isTrue, reason: '${r.error}');
      expect(server.requests.length, 2);
      expect(server.requests[0].headers['x-timestamp'], '1893456000');
      expect(server.requests[1].headers['x-timestamp'], '${1893456000 + 600}');
      expect(server.requests[1].headers['x-nonce'],
          isNot(server.requests[0].headers['x-nonce']));
      expect(a.clockOffset, const Duration(minutes: 10));
    });

    test('o\'rganilgan farq keyingi so\'rovlarga ham qo\'llanadi', () async {
      final serverNow = kNow.subtract(const Duration(minutes: 7));
      server.on(
          'GET',
          '/api/v1/ping',
          FakeKaftpay.ok({}, headers: {
            ...FakeKaftpay.jsonHeaders,
            'date': dateHeader(serverNow)
          }));
      server.on('GET', '/api/v1/ping', FakeKaftpay.ok({}));
      final a = api();
      await a.ping();
      await a.ping();
      expect(server.requests[1].headers['x-timestamp'], '${1893456000 - 420}');
    });

    test('kichik farq (<30 s) — tuzatilmaydi, 1100 qayta yuborilmaydi',
        () async {
      server.on(
          'GET',
          '/api/v1/ping',
          FakeKaftpay.fail('1100', 'unknown or inactive terminal',
              status: 401,
              headers: {
                ...FakeKaftpay.jsonHeaders,
                'date': dateHeader(kNow.add(const Duration(seconds: 5)))
              }));
      final a = api();
      final r = await a.ping();
      expect(r.error!.code, '1100');
      expect(server.requests.length, 1);
      expect(a.clockOffset, Duration.zero);
    });

    test('qayta yuborish faqat bir marta', () async {
      final h = {
        ...FakeKaftpay.jsonHeaders,
        'date': dateHeader(kNow.add(const Duration(hours: 1)))
      };
      server.on('GET', '/api/v1/ping',
          FakeKaftpay.fail('1100', 'x', status: 401, headers: h));
      server.on('GET', '/api/v1/ping',
          FakeKaftpay.fail('1100', 'x', status: 401, headers: h));
      final r = await api().ping();
      expect(r.error!.code, '1100');
      expect(server.requests.length, 2);
    });

    test(
        'identify qayta yuborilganda palmDataEnc yangi TS/NONCE bilan '
        'qayta shifrlanadi', () async {
      final serverNow = kNow.add(const Duration(minutes: 10));
      server.on(
          'POST',
          '/api/v1/identify',
          FakeKaftpay.fail('1100', 'timestamp out of range',
              status: 401,
              headers: {
                ...FakeKaftpay.jsonHeaders,
                'date': dateHeader(serverNow)
              }));
      server.on(
          'POST',
          '/api/v1/identify',
          FakeKaftpay.ok({
            'requestId': kRequestId,
            'reason': 'no_match',
            'candidates': [],
          }));
      final r = await api().identify(KaftpayPalmScan(ir: fakeIr()));
      expect(r.isOk, isTrue, reason: '${r.error}');
      final second = server.requests[1];
      final enc = server.jsonBody(second)['palmDataEnc'] as String;
      final plain = await KaftpayPalmCipher.decryptBytes(
        secret: 'test-secret',
        timestamp: second.headers['x-timestamp']!,
        nonce: second.headers['x-nonce']!,
        palmDataEnc: enc,
      );
      expect((jsonDecode(utf8.decode(plain))['ir'] as List).length, 516);
    });
  });

  group('/identify', () {
    test('body: palmDataEnc (vektor ochiq emas), hand, k, scannerModel',
        () async {
      server.on(
          'POST',
          '/api/v1/identify',
          FakeKaftpay.ok({
            'requestId': kRequestId,
            'reason': 'confident',
            'suggestion': {
              'consumerGuid': kConsumer,
              'name': 'Alisher U.',
              'firstName': 'Alisher',
              'score': 0.981,
              'phoneLast4': '4567',
            },
            'candidates': [
              {
                'consumerGuid': kConsumer,
                'name': 'Alisher U.',
                'firstName': 'Alisher',
                'score': 0.981,
                'phoneLast4': '4567',
              }
            ],
            'expiresAt': '01.08.2026 15:08:12',
          }));
      final ir = fakeIr();
      final r = await api()
          .identify(KaftpayPalmScan(ir: ir, hand: KaftpayHand.right), k: 3);
      expect(r.isOk, isTrue, reason: '${r.error}');

      final req = server.requests.single;
      final body = server.jsonBody(req);
      // Qo'l yuborilmaydi (SDK kodlanishi tasdiqlanmagan) — server ikkala
      // qo'l bilan solishtiradi.
      expect(body.keys.toSet(), {'palmDataEnc', 'k', 'scannerModel'});
      expect(body['k'], 3);
      expect(body['scannerModel'], 'palm-VP930');
      expect(req.headers['content-type'], startsWith('application/json'));

      // Server nima ko'radi: shu so'rov TS/NONCE'i bilan ochiladi.
      final plain = jsonDecode(utf8.decode(await KaftpayPalmCipher.decryptBytes(
        secret: 'test-secret',
        timestamp: req.headers['x-timestamp']!,
        nonce: req.headers['x-nonce']!,
        palmDataEnc: body['palmDataEnc'] as String,
      ))) as Map<String, dynamic>;
      expect((plain['ir'] as List).cast<num>().map((e) => e.toDouble()),
          orderedEquals(ir));
      expect(plain['rgb'], isNull);

      final d = r.data!;
      expect(d.requestId, kRequestId);
      expect(d.reason, KaftpayIdentifyReason.confident);
      expect(d.suggested!.consumerGuid, kConsumer);
      // `firstName` — haqiqiy ism (`name` amalda GUID bo'lishi mumkin).
      expect(d.suggested!.label, 'Alisher · ***4567');
      expect(d.needsCashierChoice, isFalse);
      expect(d.isNoMatch, isFalse);
      expect(d.isCandidate(kConsumer), isTrue);
      expect(d.isCandidate(kConsumer2), isFalse);
      expect(d.expiresAt, DateTime.utc(2026, 8, 1, 10, 8, 12));
      expect(d.ttlFrom(r.serverTime), const Duration(minutes: 2));
    });

    test('ambiguous — avtomatik tanlov YO\'Q, kassir tanlaydi', () async {
      server.on(
          'POST',
          '/api/v1/identify',
          FakeKaftpay.ok({
            'requestId': kRequestId,
            'reason': 'ambiguous',
            'suggestion': null,
            'candidates': [
              {'consumerGuid': kConsumer, 'name': 'Alisher U.', 'score': 0.834},
              {'consumerGuid': kConsumer2, 'name': 'Aziz K.', 'score': 0.811},
            ],
          }));
      final d = (await api().identify(KaftpayPalmScan(ir: fakeIr()))).data!;
      expect(d.reason, KaftpayIdentifyReason.ambiguous);
      expect(d.suggested, isNull);
      expect(d.needsCashierChoice, isTrue);
      expect(d.candidates.map((c) => c.consumerGuid), [kConsumer, kConsumer2]);
      expect(d.candidates[1].label, 'Aziz K.');
    });

    test('no_match — HTTP 200 muvaffaqiyat, nomzod yo\'q', () async {
      server.on(
          'POST',
          '/api/v1/identify',
          FakeKaftpay.ok({
            'requestId': kRequestId,
            'reason': 'no_match',
            'suggestion': null,
            'candidates': [],
          }));
      final r = await api().identify(KaftpayPalmScan(ir: fakeIr()));
      expect(r.isOk, isTrue);
      expect(r.data!.isNoMatch, isTrue);
      expect(r.data!.suggested, isNull);
    });

    test('noma\'lum reason — yiqilmaydi, avtomatik tanlov yo\'q', () async {
      server.on(
          'POST',
          '/api/v1/identify',
          FakeKaftpay.ok({
            'requestId': kRequestId,
            'reason': 'weird',
            'candidates': [
              {'consumerGuid': kConsumer}
            ],
          }));
      final d = (await api().identify(KaftpayPalmScan(ir: fakeIr()))).data!;
      expect(d.reason, KaftpayIdentifyReason.unknown);
      expect(d.reasonRaw, 'weird');
      expect(d.suggested, isNull);
    });

    test(
        'RGB bo\'lsa shifr ichida; 0 / NaN / uzunligi xato bo\'lsa null '
        '(skan rad etilmaydi)', () async {
      final rgbs = [
        fakeIr().reversed.toList(),
        List<double>.filled(516, 0),
        [...fakeIr(515), double.nan],
        fakeIr(100),
      ];
      for (final rgb in rgbs) {
        server.on('POST', '/api/v1/identify',
            FakeKaftpay.ok({'requestId': kRequestId, 'reason': 'no_match'}));
        await api().identify(KaftpayPalmScan(ir: fakeIr(), rgb: rgb));
      }
      Future<Object?> rgbOf(http.Request req) async =>
          jsonDecode(utf8.decode(await KaftpayPalmCipher.decryptBytes(
              secret: 'test-secret',
              timestamp: req.headers['x-timestamp']!,
              nonce: req.headers['x-nonce']!,
              palmDataEnc:
                  server.jsonBody(req)['palmDataEnc'] as String)))['rgb'];
      expect((await rgbOf(server.requests[0])) as List, hasLength(516));
      for (var i = 1; i < rgbs.length; i++) {
        expect(await rgbOf(server.requests[i]), isNull, reason: 'rgb #$i');
      }
    });

    test('yaroqsiz skan tarmoqqa chiqmaydi', () async {
      final bad = <KaftpayPalmScan>[
        KaftpayPalmScan(ir: fakeIr(515)),
        KaftpayPalmScan(ir: [...fakeIr(515), double.nan]),
        KaftpayPalmScan(ir: [...fakeIr(515), double.infinity]),
        KaftpayPalmScan(ir: List<double>.filled(516, 0)),
      ];
      for (final s in bad) {
        final r = await api().identify(s);
        expect(r.error!.kind, KaftpayErrorKind.local, reason: s.validate());
      }
      expect(server.requests, isEmpty);
    });

    test('filterByHand — faqat aniq qo\'l bo\'lsa yuboriladi', () async {
      for (final h in [KaftpayHand.left, KaftpayHand.unspecified]) {
        server.on('POST', '/api/v1/identify',
            FakeKaftpay.ok({'requestId': kRequestId, 'reason': 'no_match'}));
        await api().identify(KaftpayPalmScan(ir: fakeIr(), hand: h),
            filterByHand: true);
      }
      expect(server.jsonBody(server.requests[0])['hand'], 'LEFT');
      expect(server.jsonBody(server.requests[1]).containsKey('hand'), isFalse);
    });

    test('nomzod ismi: name GUID bo\'lsa ko\'rsatilmaydi, firstName ustun', () {
      KaftpayCandidate c(Map<String, dynamic> j) =>
          KaftpayCandidate.fromJson({'consumerGuid': kConsumer, ...j});
      expect(c({'name': kConsumer, 'phoneLast4': '1234'}).label, '— · ***1234');
      expect(c({'name': '93834bf2-c7ee-498e-bd2f-bc0025dca145'}).displayName,
          isNull);
      expect(c({'name': kConsumer, 'firstName': 'Dilnoza'}).label, 'Dilnoza');
      expect(c({'name': 'Aziz K.'}).label, 'Aziz K.');
      expect(c({'firstName': '  '}).displayName, isNull);
    });

    test('SDK palm_type → hand', () {
      expect(KaftpayHand.fromSdk(0), KaftpayHand.left);
      expect(KaftpayHand.fromSdk(1), KaftpayHand.right);
      expect(KaftpayHand.fromSdk(null), KaftpayHand.unspecified);
      expect(KaftpayHand.fromSdk(5), KaftpayHand.unspecified);
    });

    test('Alice\'ga shifrlangan vektor ham qisqartirilib boradi', () async {
      server.on('POST', '/api/v1/identify',
          FakeKaftpay.ok({'requestId': kRequestId, 'reason': 'no_match'}));
      await api().identify(KaftpayPalmScan(ir: fakeIr()));
      final shown = alice.single.request as http.Request;
      final body = jsonDecode(shown.body) as Map<String, dynamic>;
      expect(body['palmDataEnc'], matches(RegExp(r'^<\d+ belgi>$')));
      expect(body.containsKey('hand'), isFalse);
    });
  });

  group('/enroll', () {
    test('QR matni o\'zgartirilmay yuboriladi (PPENROLL: prefiks bilan)',
        () async {
      server.on(
          'POST',
          '/api/v1/enroll',
          FakeKaftpay.ok({
            'consumerGuid': kConsumer,
            'status': 'ACTIVE',
            'enrolledAt': '01.08.2026 15:04:22',
          }));
      final r = await api().enroll(
        qrSessionId: ' PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f ',
        scan: KaftpayPalmScan(ir: fakeIr(), hand: KaftpayHand.left),
      );
      expect(r.isOk, isTrue, reason: '${r.error}');
      final body = server.jsonBody(server.requests.single);
      expect(
          body['qrSessionId'], 'PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
      expect(body['hand'], 'LEFT');
      expect(body.containsKey('palmDataEnc'), isTrue);
      expect(body.containsKey('ir'), isFalse);
      expect(r.data!.isActive, isTrue);
      expect(r.data!.enrolledAt, DateTime.utc(2026, 8, 1, 10, 4, 22));
    });

    test('1151 — QR eskirgan', () async {
      server.on('POST', '/api/v1/enroll',
          FakeKaftpay.fail('1151', 'Enrollment session has expired!'));
      final r = await api().enroll(
          qrSessionId: 'x',
          scan: KaftpayPalmScan(ir: fakeIr(), hand: KaftpayHand.right));
      expect(r.error!.code, '1151');
      expect(r.error!.message, contains('yangi QR'));
    });

    test('QR bo\'sh → tarmoqqa chiqmaydi', () async {
      final r = await api().enroll(
          qrSessionId: '  ',
          scan: KaftpayPalmScan(ir: fakeIr(), hand: KaftpayHand.left));
      expect(r.error!.kind, KaftpayErrorKind.local);
      expect(server.requests, isEmpty);
    });

    test('qo\'l tanlanmagan → tarmoqqa chiqmaydi (server 1104 berardi)',
        () async {
      final r = await api()
          .enroll(qrSessionId: 'x', scan: KaftpayPalmScan(ir: fakeIr()));
      expect(r.error!.kind, KaftpayErrorKind.local);
      expect(r.error!.message, contains('chap yoki o\'ng'));
      expect(server.requests, isEmpty);
    });
  });

  group('/pay', () {
    test('Idempotency-Key header + body + javob', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.ok(payData()));
      final r = await api().pay(
        idempotencyKey: kKey,
        request: payRequest(products: const [
          KaftpayReceiptItem(
            name: 'Kofe Latte 0.4L',
            spic: '10406001002000000',
            packageCode: '1508540',
            price: 2500000,
            discount: 200000,
            amount: 1,
            vatPercent: 12,
          ),
        ], amount: 2300000),
      );
      expect(r.isOk, isTrue, reason: '${r.error}');
      final req = server.requests.single;
      expect(req.headers['idempotency-key'], kKey);
      expect(server.jsonBody(req), {
        'requestId': kRequestId,
        'consumerGuid': kConsumer,
        'amount': 2300000,
        'cashierId': 'c-17',
        'cashierName': 'Nodira S.',
        'products': [
          {
            'name': 'Kofe Latte 0.4L',
            'price': 2500000,
            'spic': '10406001002000000',
            'packageCode': '1508540',
            'amount': 1,
            'vatPercent': 12,
            'discount': 200000,
          }
        ],
      });
      final d = r.data!;
      expect(d.transactionId, kTx);
      expect(d.status, KaftpayTxStatus.success);
      expect(d.ofdStatus, KaftpayOfdStatus.awaitingExternal);
      expect(d.acquirerRef, 'STUB-OK-abcdef');
    });

    test('products bo\'lmasa body\'da yo\'q (merchant-fiscalized)', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.ok(payData()));
      await api().pay(idempotencyKey: kKey, request: payRequest());
      expect(server.jsonBody(server.requests.single).containsKey('products'),
          isFalse);
    });

    test('ofdStatus TEST / noma\'lum', () async {
      server.on(
          'POST', '/api/v1/pay', FakeKaftpay.ok(payData(ofdStatus: 'TEST')));
      server.on(
          'POST', '/api/v1/pay', FakeKaftpay.ok(payData(ofdStatus: 'NEW')));
      final a = api();
      expect(
          (await a.pay(idempotencyKey: kKey, request: payRequest()))
              .data!
              .ofdStatus,
          KaftpayOfdStatus.test);
      final u =
          (await a.pay(idempotencyKey: kKey, request: payRequest())).data!;
      expect(u.ofdStatus, KaftpayOfdStatus.unknown);
      expect(u.ofdStatusRaw, 'NEW');
    });

    test('mahalliy tekshiruv — tarmoqqa chiqmaydi', () async {
      final a = api();
      final cases = <String, Future<dynamic>>{
        'kalit bo\'sh': a.pay(idempotencyKey: ' ', request: payRequest()),
        'summa 0': a.pay(idempotencyKey: kKey, request: payRequest(amount: 0)),
        'kassir yo\'q':
            a.pay(idempotencyKey: kKey, request: payRequest(cashierName: ' ')),
        'kassir id uzun': a.pay(
            idempotencyKey: kKey, request: payRequest(cashierId: 'x' * 65)),
        'jami mos emas (1204)': a.pay(
            idempotencyKey: kKey,
            request: payRequest(amount: 2500000, products: const [
              KaftpayReceiptItem(name: 'A', price: 2500000, discount: 1),
            ])),
      };
      for (final e in cases.entries) {
        final r = await e.value as KaftpayResult;
        expect(r.error?.kind, KaftpayErrorKind.local, reason: e.key);
      }
      expect(server.requests, isEmpty);
    });

    test('kassir ismi 128 belgiga qisqartiriladi', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.ok(payData()));
      await api().pay(
          idempotencyKey: kKey, request: payRequest(cashierName: 'N' * 200));
      expect(
          (server.jsonBody(server.requests.single)['cashierName'] as String)
              .length,
          128);
    });
  });

  group('/pay/status, /refund, /ofd-receipt', () {
    test('status — kalit path\'da, imzo shu path bilan', () async {
      server.on(
          'GET', '/api/v1/pay/status/$kKey', FakeKaftpay.ok(statusData()));
      final r = await api().payStatus(kKey);
      expect(r.isOk, isTrue, reason: '${r.error}');
      final d = r.data!;
      expect(d.requestStatus, 'CHARGED');
      expect(d.status, KaftpayTxStatus.success);
      expect(d.cardMask, '8600****1234');
      expect(d.cashierName, 'Nodira S.');
      expect(d.paidAt, DateTime.utc(2026, 8, 1, 10, 6, 12));
    });

    test('status — path\'ga xavfli belgili kalit percent-encode qilinadi',
        () async {
      server.on(
          'GET', '/api/v1/pay/status/a%2Fb%20c', FakeKaftpay.ok(statusData()));
      final r = await api().payStatus('a/b c');
      expect(r.isOk, isTrue, reason: '${r.error}');
    });

    test('status 1210 — pul yechilmagan', () async {
      server.on('GET', '/api/v1/pay/status/$kKey',
          FakeKaftpay.fail('1210', 'No payment was found'));
      final r = await api().payStatus(kKey);
      expect(r.error!.code, KaftpayErrorCodes.noPaymentForKey);
    });

    test('refund — body, bo\'sh sabab yuborilmaydi', () async {
      server.on(
          'POST',
          '/api/v1/pay/$kTx/refund',
          FakeKaftpay.ok({
            'transactionId': kTx,
            'status': 'REFUNDED',
            'amount': 2500000,
            'refundAcquirerRef': 'STUB-REFUND-abcdef',
            'refundedAt': '01.08.2026 15:09:40',
          }));
      final r = await api().refund(
          transactionId: kTx,
          cashierId: 'c-17',
          cashierName: 'Nodira S.',
          reason: ' ');
      expect(r.isOk, isTrue, reason: '${r.error}');
      expect(server.jsonBody(server.requests.single),
          {'cashierId': 'c-17', 'cashierName': 'Nodira S.'});
      expect(r.data!.status, KaftpayTxStatus.refunded);
      expect(r.data!.refundAcquirerRef, 'STUB-REFUND-abcdef');
      expect(r.data!.refundedAt, DateTime.utc(2026, 8, 1, 10, 9, 40));
    });

    test('refund — kassirsiz tarmoqqa chiqmaydi', () async {
      final r = await api()
          .refund(transactionId: kTx, cashierId: '', cashierName: 'X');
      expect(r.error!.kind, KaftpayErrorKind.local);
      expect(server.requests, isEmpty);
    });

    test('ofd-receipt — javob havolaga mosligi tekshiriladi', () async {
      const url = 'https://ofd.soliq.uz/check?t=UZ000000000001&r=1042'
          '&c=20260819120000&s=123456789012';
      server.on(
          'POST',
          '/api/v1/pay/$kTx/ofd-receipt',
          FakeKaftpay.ok({
            'transactionId': kTx,
            'ofdStatus': 'EXTERNAL',
            'terminalId': 'UZ000000000001',
            'receiptSeq': 1042,
            'fiscalDateTime': '20260819120000',
            'fiscalSign': '123456789012',
            'ofdReceiptUrl': url,
          }));
      final r =
          await api().attachOfdReceipt(transactionId: kTx, ofdReceiptUrl: url);
      expect(r.isOk, isTrue, reason: '${r.error}');
      expect(server.jsonBody(server.requests.single), {'ofdReceiptUrl': url});
      expect(r.data!.ofdStatus, KaftpayOfdStatus.external);
      expect(r.data!.matchesUrl(url), isTrue);
      expect(r.data!.matchesUrl(url.replaceAll('r=1042', 'r=1043')), isFalse);
    });

    test('ofd-receipt — t/r/c/s bo\'lmasa tarmoqqa chiqmaydi (1057)', () async {
      final r = await api().attachOfdReceipt(
          transactionId: kTx,
          ofdReceiptUrl: 'https://ofd.soliq.uz/check?t=UZ1&r=1&c=2');
      expect(r.error!.kind, KaftpayErrorKind.local);
      expect(server.requests, isEmpty);
    });
  });

  group('yordamchilar', () {
    test('so\'m → tiyin (float xatosiz)', () {
      expect(KaftpayMoney.toTiyin(25000), 2500000);
      expect(KaftpayMoney.toTiyin(12345.67), 1234567);
      expect(KaftpayMoney.toTiyin(0.1 + 0.2), 30);
      expect(KaftpayMoney.toTiyin(19999.99), 1999999);
      expect(KaftpayMoney.toSom(2500000), 25000);
    });

    test('vaqt: dd.MM.yyyy HH:mm:ss GMT+5 → UTC', () {
      expect(KaftpayTime.parse('01.08.2026 15:06:12'),
          DateTime.utc(2026, 8, 1, 10, 6, 12));
      expect(KaftpayTime.parse('01.01.2026 03:00:00'),
          DateTime.utc(2025, 12, 31, 22));
      expect(KaftpayTime.parse('2026-10-29T12:58:50.394Z'),
          DateTime.utc(2026, 10, 29, 12, 58, 50, 394));
      expect(KaftpayTime.parse('nonsense'), isNull);
      expect(KaftpayTime.parse(null), isNull);
    });

    test('redactBody — vektorlar logga tushmaydi', () {
      final s = KaftpayApi.redactBody(utf8.encode(jsonEncode({
        'palmDataEnc': 'A' * 5000,
        'ir': [1, 2, 3],
        'k': 5,
      })));
      expect(jsonDecode(s),
          {'palmDataEnc': '<5000 belgi>', 'ir': '<3 float>', 'k': 5});
      expect(KaftpayApi.redactBody(utf8.encode('xyz')), '<3 bayt>');
    });

    test('swagger\'dagi barcha xato kodlari o\'zbekcha izohga ega', () {
      const codes = [
        '1100', '1108', '1103', '1104', '1105', '1106', '1107', '1109', //
        '1150', '1151', '1152', '1153', '1200', '1201', '1202', '1203',
        '1204', '1205', '1206', '1207', '1208', '1209', '1210', '1211',
        '1212', '1213', '1214', '1215', '1216', '1217', '1218', '1219',
        '1221', '1222', '1223', '1224', '1050', '1051', '1052', '1053',
        '1054', '1055', '1057', '1058', '1002', '9999',
      ];
      for (final c in codes) {
        expect(KaftpayErrorCodes.isKnown(c), isTrue, reason: c);
      }
    });
  });
}
