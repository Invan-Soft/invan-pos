// KaftpayPaymentFlow — pul xavfsizligi (swagger §4).
//
// Nega kerak: kaft bilan to'lovda xato ikki xil qimmat:
//   - "pul ketmadi" deb noto'g'ri xulosa → kassir qayta yechadi → mijozdan
//     IKKI marta pul;
//   - "pul ketdi" deb noto'g'ri xulosa → tovar tekinga ketadi.
// Shuning uchun har stsenariyda (1) natija holati va (2) `/pay` necha marta
// chaqirilgani mixlanadi: oqim HECH QACHON `/pay` ni o'zi qayta yubormaydi.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_error.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';

import 'support/kaftpay_fake_server.dart';

const kStatusPath = '/api/v1/pay/status/$kKey';
const kRefundPath = '/api/v1/pay/$kTx/refund';

void main() {
  late FakeKaftpay server;
  late List<Duration> sleeps;

  KaftpayPaymentFlow flow({int statusAttempts = 3}) => KaftpayPaymentFlow(
        KaftpayApi(
          config:
              const KaftpayConfig(clientId: 'pos-test', secret: 'test-secret'),
          client: server.client,
          payTimeout: const Duration(milliseconds: 50),
          timeout: const Duration(milliseconds: 50),
        ),
        statusAttempts: statusAttempts,
        sleep: (d) async => sleeps.add(d),
      );

  const request = KaftpayPayRequest(
    requestId: kRequestId,
    consumerGuid: kConsumer,
    amount: 2500000,
    cashierId: 'c-17',
    cashierName: 'Nodira S.',
  );

  int payCalls() => server.calls('POST', '/api/v1/pay').length;
  int statusCalls() => server.calls('GET', kStatusPath).length;

  setUp(() {
    server = FakeKaftpay();
    sleeps = [];
    KaftpayApi.onHttpResponse = (_) {};
  });

  test('yangi kalit — UUID v4, har safar boshqa', () {
    final a = KaftpayPaymentFlow.newIdempotencyKey();
    final b = KaftpayPaymentFlow.newIdempotencyKey();
    expect(a, matches(RegExp(r'^[0-9a-f-]{36}$')));
    expect(a, isNot(b));
  });

  group('charge — to\'g\'ridan javob', () {
    test('200 → charged, status so\'ralmaydi', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.ok(payData()));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.charged);
      expect(o.transactionId, kTx);
      expect(o.amount, 2500000);
      expect(o.acquirerRef, 'STUB-OK-abcdef');
      expect(o.needsExternalReceipt, isTrue);
      expect(o.idempotencyKey, kKey);
      expect(payCalls(), 1);
      expect(statusCalls(), 0);
    });

    test('200 + status PENDING → charged EMAS: status so\'raladi', () async {
      server.on('POST', '/api/v1/pay',
          FakeKaftpay.ok({...payData(), 'status': 'PENDING'}));
      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.charged);
      expect(payCalls(), 1, reason: '/pay qayta yuborilmaydi');
      expect(statusCalls(), 1);
    });

    test('200 + status PENDING, status ham PENDING → unknown', () async {
      server.on('POST', '/api/v1/pay',
          FakeKaftpay.ok({...payData(), 'status': 'PENDING'}));
      server.on(
          'GET',
          kStatusPath,
          FakeKaftpay.ok(
              statusData(status: 'PENDING', requestStatus: 'CHARGING')));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.unknown);
      expect(payCalls(), 1);
    });

    test('200 + status yo\'q / noma\'lum → status orqali', () async {
      for (final st in [null, 'WEIRD']) {
        server = FakeKaftpay();
        server.on('POST', '/api/v1/pay',
            FakeKaftpay.ok({...payData(), 'status': st}));
        server.on('GET', kStatusPath, FakeKaftpay.fail('1210', 'none'));
        final o = await flow().charge(idempotencyKey: kKey, request: request);
        expect(o.state, KaftpayChargeState.notCharged, reason: '$st');
        expect(statusCalls(), 1, reason: '$st');
      }
    });

    test('200 + status FAILED → notCharged, status so\'ralmaydi', () async {
      server.on('POST', '/api/v1/pay',
          FakeKaftpay.ok({...payData(), 'status': 'FAILED'}));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.notCharged);
      expect(o.transactionId, kTx);
      expect(statusCalls(), 0);
    });

    test('ofdStatus PENDING (Kaftpay o\'zi fiskallaydi) → chek bizdan emas',
        () async {
      server.on(
          'POST', '/api/v1/pay', FakeKaftpay.ok(payData(ofdStatus: 'PENDING')));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.isCharged, isTrue);
      expect(o.needsExternalReceipt, isFalse);
      expect(o.ofdStatus, KaftpayOfdStatus.pending);
    });

    for (final code in [
      '1200', '1201', '1202', '1203', '1204', '1205', '1206', '1208', //
      '1211', '1212', '1213', '1214', '1052', '1053', '1054', '1055',
    ]) {
      test('$code → notCharged, status so\'ralmaydi', () async {
        server.on('POST', '/api/v1/pay', FakeKaftpay.fail(code, 'rad'));
        final o = await flow().charge(idempotencyKey: kKey, request: request);
        expect(o.state, KaftpayChargeState.notCharged);
        expect(o.error!.code, code);
        expect(o.message, KaftpayErrorCodes.describe(code));
        expect(payCalls(), 1);
        expect(statusCalls(), 0);
      });
    }

    test('auth (1100) → notCharged, status so\'ralmaydi', () async {
      server.on(
          'POST', '/api/v1/pay', FakeKaftpay.fail('1108', 'ip', status: 401));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.notCharged);
      expect(statusCalls(), 0);
    });

    test('validation → notCharged', () async {
      server.on('POST', '/api/v1/pay',
          FakeKaftpay.raw('{"amount":"must not be null"}', 400));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.notCharged);
      expect(statusCalls(), 0);
    });

    test('mahalliy xato → tarmoqqa umuman chiqmaydi', () async {
      final o = await flow().charge(
        idempotencyKey: kKey,
        request: const KaftpayPayRequest(
          requestId: kRequestId,
          consumerGuid: kConsumer,
          amount: 100,
          cashierId: '',
          cashierName: '',
        ),
      );
      expect(o.state, KaftpayChargeState.notCharged);
      expect(server.requests, isEmpty);
    });
  });

  group('charge — javob yo\'qoldi / noaniq → status', () {
    test('timeout → status SUCCESS → charged (karta niqobi bilan)', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.never());
      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.charged);
      expect(o.transactionId, kTx);
      expect(o.cardMask, '8600****1234');
      expect(o.needsExternalReceipt, isTrue);
      expect(payCalls(), 1);
      expect(statusCalls(), 1);
      // Status kalitni o'zgarishsiz so'radi.
      expect(server.calls('GET', kStatusPath).single.url.path,
          endsWith('/pay/status/$kKey'));
      expect(sleeps, isEmpty);
    });

    test('timeout → status 1210 → notCharged (pul ketmagan)', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.never());
      server.on('GET', kStatusPath, FakeKaftpay.fail('1210', 'No payment'));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.notCharged);
      expect(o.error!.isTimeout, isTrue, reason: 'sabab — asl timeout');
      expect(payCalls(), 1);
    });

    test('1215 → PENDING, PENDING, SUCCESS → charged (2 marta kutildi)',
        () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.fail('1215', 'lost'));
      server.on(
          'GET',
          kStatusPath,
          FakeKaftpay.ok(
              statusData(status: 'PENDING', requestStatus: 'CHARGING')));
      server.on(
          'GET',
          kStatusPath,
          FakeKaftpay.ok(
              statusData(status: 'PENDING', requestStatus: 'CHARGING')));
      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.charged);
      expect(payCalls(), 1);
      expect(statusCalls(), 3);
      expect(sleeps, [const Duration(seconds: 2), const Duration(seconds: 2)]);
    });

    test('1215 → hamma urinishda PENDING → unknown, /pay qayta YO\'Q',
        () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.fail('1215', 'lost'));
      for (var i = 0; i < 3; i++) {
        server.on(
            'GET',
            kStatusPath,
            FakeKaftpay.ok(
                statusData(status: 'PENDING', requestStatus: 'CHARGING')));
      }
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.unknown);
      expect(o.message, contains('QAYTA YECHMANG'));
      expect(o.message, contains('CHARGING'));
      expect(payCalls(), 1);
    });

    test('ulanish yo\'q, status ham javobsiz → unknown, /pay qayta YO\'Q',
        () async {
      server.on('POST', '/api/v1/pay', const SocketException('down'));
      for (var i = 0; i < 3; i++) {
        server.on('GET', kStatusPath, const SocketException('down'));
      }
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.unknown);
      expect(o.error!.kind, KaftpayErrorKind.network);
      expect(payCalls(), 1);
      expect(statusCalls(), 3);
    });

    test('HTTP 200 + 9999 → status → charged', () async {
      server.on('POST', '/api/v1/pay',
          FakeKaftpay.fail('9999', 'unexpected', status: 200));
      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.charged);
      expect(payCalls(), 1);
    });

    test('502 → status 502 → status SUCCESS → charged', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.raw('bad gateway', 502));
      server.on('GET', kStatusPath, FakeKaftpay.raw('bad gateway', 502));
      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.charged);
      expect(statusCalls(), 2);
    });

    test('noma\'lum biznes kod → aniqlash uchun status (1210 → notCharged)',
        () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.fail('1299', 'yangi'));
      server.on('GET', kStatusPath, FakeKaftpay.fail('1210', 'No payment'));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.notCharged);
      expect(o.error!.code, '1299');
      expect(statusCalls(), 1);
    });

    test(
        '1209 (kalit boshqa to\'lovda) — status boshqa requestId → unknown, '
        'charged deb aldanmaydi', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.fail('1209', 'used'));
      server.on('GET', kStatusPath,
          FakeKaftpay.ok(statusData(requestId: 'boshqa-request')));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.unknown);
      expect(o.error!.reason, contains('boshqa to\'lovga'));
    });

    test('status summasi boshqa → unknown', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.never());
      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData(amount: 1)));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.unknown);
    });

    test('1207 → status 1210 → notCharged', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.fail('1207', 'settled'));
      server.on('GET', kStatusPath, FakeKaftpay.fail('1210', 'No payment'));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.notCharged);
      expect(o.error!.code, '1207');
    });

    test('status REFUNDED → unknown (avtomatik xulosa yo\'q)', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.never());
      server.on(
          'GET', kStatusPath, FakeKaftpay.ok(statusData(status: 'REFUNDED')));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.unknown);
      expect(o.message, contains('REFUNDED'));
    });

    test('status FAILED → notCharged (server yakuniy holati)', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.never());
      server.on(
          'GET', kStatusPath, FakeKaftpay.ok(statusData(status: 'FAILED')));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.notCharged);
      expect(o.transactionId, kTx);
      expect(o.message, contains('FAILED'));
      expect(statusCalls(), 1);
    });

    test('status auth xatosi → qayta so\'ralmaydi, unknown', () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.never());
      server.on(
          'GET', kStatusPath, FakeKaftpay.fail('1202', 'other', status: 400));
      final o = await flow().charge(idempotencyKey: kKey, request: request);
      expect(o.state, KaftpayChargeState.unknown);
      expect(statusCalls(), 1);
    });
  });

  group('resolve — kassir keyinroq "Tekshirish" bosadi', () {
    test('birinchi resolve unknown, ikkinchisi charged — o\'sha kalit',
        () async {
      server.on('POST', '/api/v1/pay', FakeKaftpay.never());
      server.on('GET', kStatusPath, const SocketException('down'));
      final f = flow(statusAttempts: 1);
      final first = await f.charge(idempotencyKey: kKey, request: request);
      expect(first.state, KaftpayChargeState.unknown);

      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
      final second = await f.resolve(first.idempotencyKey, expected: request);
      expect(second.state, KaftpayChargeState.charged);
      expect(payCalls(), 1);
    });

    test('expected bermasdan ham ishlaydi (kassa qayta yongandan keyin)',
        () async {
      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
      final o = await flow().resolve(kKey);
      expect(o.state, KaftpayChargeState.charged);
      expect(o.amount, 2500000);
    });
  });

  group('refund', () {
    Future<KaftpayRefundOutcome> refund({String? key}) => flow().refund(
          transactionId: kTx,
          cashierId: 'c-17',
          cashierName: 'Nodira S.',
          reason: 'qaytarildi',
          paymentIdempotencyKey: key,
        );

    test('200 → refunded', () async {
      server.on(
          'POST',
          kRefundPath,
          FakeKaftpay.ok({
            'transactionId': kTx,
            'status': 'REFUNDED',
            'amount': 2500000,
            'refundAcquirerRef': 'R-1',
          }));
      final o = await refund(key: kKey);
      expect(o.state, KaftpayRefundState.refunded);
      expect(o.amount, 2500000);
      expect(o.refundAcquirerRef, 'R-1');
      expect(statusCalls(), 0);
    });

    test('1223 → unknown, QAYTA YUBORILMAYDI, status ham so\'ralmaydi',
        () async {
      server.on('POST', kRefundPath, FakeKaftpay.fail('1223', 'unconfirmed'));
      final o = await refund(key: kKey);
      expect(o.state, KaftpayRefundState.unknown);
      expect(o.retryAllowed, isFalse);
      expect(o.error!.message, contains('QAYTA YUBORMANG'));
      expect(statusCalls(), 0);
      expect(server.calls('POST', kRefundPath).length, 1);
    });

    for (final code in ['1224', '1221', '1217', '1216', '1222', '1211']) {
      test('$code → notRefunded', () async {
        server.on('POST', kRefundPath, FakeKaftpay.fail(code, 'rad'));
        final o = await refund(key: kKey);
        expect(o.state, KaftpayRefundState.notRefunded);
        expect(o.error!.code, code);
        expect(statusCalls(), 0);
      });
    }

    test('javob yo\'q + status REFUNDED → refunded', () async {
      server.on('POST', kRefundPath, FakeKaftpay.never());
      server.on(
          'GET', kStatusPath, FakeKaftpay.ok(statusData(status: 'REFUNDED')));
      final o = await refund(key: kKey);
      expect(o.state, KaftpayRefundState.refunded);
    });

    test('javob yo\'q + status hali SUCCESS → unknown, qayta yuborish mumkin',
        () async {
      server.on('POST', kRefundPath, FakeKaftpay.never());
      server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
      final o = await refund(key: kKey);
      expect(o.state, KaftpayRefundState.unknown);
      expect(o.retryAllowed, isTrue);
    });

    test('javob yo\'q, kalit noma\'lum → unknown, qayta yuborish mumkin',
        () async {
      server.on('POST', kRefundPath, FakeKaftpay.never());
      final o = await refund();
      expect(o.state, KaftpayRefundState.unknown);
      expect(o.retryAllowed, isTrue);
      expect(statusCalls(), 0);
    });

    test('status boshqa tranzaksiyaniki → refunded deb aldanmaydi', () async {
      server.on('POST', kRefundPath, FakeKaftpay.never());
      server.on(
          'GET',
          kStatusPath,
          FakeKaftpay.ok({
            ...statusData(status: 'REFUNDED'),
            'transactionId': 'boshqa-tx',
          }));
      final o = await refund(key: kKey);
      expect(o.state, KaftpayRefundState.unknown);
    });
  });

  test('har javob Alice hook\'iga boradi', () async {
    final seen = <http.Response>[];
    KaftpayApi.onHttpResponse = seen.add;
    server.on('POST', '/api/v1/pay', FakeKaftpay.fail('1215', 'lost'));
    server.on('GET', kStatusPath, FakeKaftpay.ok(statusData()));
    await flow().charge(idempotencyKey: kKey, request: request);
    expect(seen.map((r) => r.statusCode), [400, 200]);
  });
}
