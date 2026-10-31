// Kaftpay to'lov oynasi mantig'i (KaftpayCheckout) — soxta skaner va
// imzoni tekshiradigan soxta server bilan.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_checkout.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';

import 'support/kaftpay_fake_server.dart';

class FakeScanner implements KaftpayScanner {
  FakeScanner({this.error, this.cancelledError = false});

  final String? error;
  final bool cancelledError;
  int captures = 0;
  int cancels = 0;

  @override
  String? get unavailableReason => null;

  @override
  Future<KaftpayPalmScan> capture({
    void Function(KaftpayScanStage stage, String message)? onStage,
  }) async {
    captures++;
    onStage?.call(KaftpayScanStage.waitingPalm, 'kaftni qo\'ying');
    if (cancelledError) {
      throw const KaftpayScannerException('Bekor qilindi', cancelled: true);
    }
    if (error != null) throw KaftpayScannerException(error!);
    return KaftpayPalmScan(ir: KaftpaySyntheticScanner.vector(42));
  }

  @override
  void cancel() => cancels++;
}

Map<String, dynamic> cand(String guid, String first, String last4) => {
      'consumerGuid': guid,
      'name': guid,
      'firstName': first,
      'phoneLast4': last4
    };

Map<String, dynamic> identifyData(String reason,
        {List<Map<String, dynamic>> candidates = const [],
        Map<String, dynamic>? suggestion}) =>
    {
      'requestId': kRequestId,
      'reason': reason,
      if (suggestion != null) 'suggestion': suggestion,
      'candidates': candidates,
      // envelope vaqtidan 2 daqiqa keyin
      'expiresAt': '01.08.2026 15:08:12',
    };

void main() {
  late FakeKaftpay server;
  late String journalRaw;
  late KaftpayJournal journal;
  late DateTime now;

  setUp(() {
    server = FakeKaftpay();
    journalRaw = '';
    journal = KaftpayJournal(
        read: () => journalRaw, write: (v) async => journalRaw = v);
    now = DateTime(2026, 8, 1, 15, 6, 12);
    KaftpayApi.onHttpResponse = (_) {};
  });

  KaftpayCheckout checkout({
    KaftpayScanner? scanner,
    String cashierId = 'c-17',
    String cashierName = 'Nodira S.',
    int amount = 2500000,
  }) {
    final api = KaftpayApi(
      config: const KaftpayConfig(clientId: 'pos-test', secret: 'test-secret'),
      client: server.client,
      timeout: const Duration(milliseconds: 50),
      payTimeout: const Duration(milliseconds: 50),
    );
    return KaftpayCheckout(
      api: api,
      scanner: scanner ?? FakeScanner(),
      journal: journal,
      amount: amount,
      cashierId: cashierId,
      cashierName: cashierName,
      flow: KaftpayPaymentFlow(api, sleep: (_) async {}),
      now: () => now,
      newKey: () => kKey,
    );
  }

  int payCalls() => server.calls('POST', '/api/v1/pay').length;

  test('confident → mijoz tanlangan → to\'lash → charged, jurnal yangilanadi',
      () async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok(identifyData('confident',
            suggestion: cand(kConsumer, 'Alisher', '4567'),
            candidates: [cand(kConsumer, 'Alisher', '4567')])));
    server.on('POST', '/api/v1/pay', FakeKaftpay.ok(payData()));
    final c = checkout();
    await c.start();
    expect(c.step, KaftpayCheckoutStep.choosing);
    expect(c.selectedGuid, kConsumer);
    expect(c.candidates.single.label, 'Alisher · ***4567');
    expect(c.canPay, isTrue);
    expect(c.canCancel, isTrue);

    await c.pay();
    expect(c.step, KaftpayCheckoutStep.charged);
    expect(c.outcome!.transactionId, kTx);
    expect(c.outcome!.amount, 2500000);

    final body = server.jsonBody(server.calls('POST', '/api/v1/pay').single);
    expect(body['requestId'], kRequestId);
    expect(body['consumerGuid'], kConsumer);
    expect(body['amount'], 2500000);
    expect(body['cashierId'], 'c-17');
    expect(body['cashierName'], 'Nodira S.');
    expect(body.containsKey('products'), isFalse,
        reason: 'ofdEnabled=false — chekni o\'zimiz fiskallaymiz');
    expect(
        server.calls('POST', '/api/v1/pay').single.headers['idempotency-key'],
        kKey);

    final e = journal.byKey(kKey)!;
    expect(e.status, KaftpayJournalStatus.charged);
    expect(e.transactionId, kTx);
    expect(e.consumerName, 'Alisher');
    expect(e.canRefund, isTrue);
  });

  test(
      'ambiguous — avtomatik tanlov YO\'Q; nomzoddan tashqari guid qabul '
      'qilinmaydi', () async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok(identifyData('ambiguous', candidates: [
          cand(kConsumer, 'Alisher', '4567'),
          cand(kConsumer2, 'Aziz', '1234'),
        ])));
    final c = checkout();
    await c.start();
    expect(c.step, KaftpayCheckoutStep.choosing);
    expect(c.selectedGuid, isNull);
    expect(c.canPay, isFalse);
    await c.pay();
    expect(payCalls(), 0);

    c.select('begona-guid');
    expect(c.selectedGuid, isNull);
    c.select(kConsumer2);
    expect(c.selected!.displayName, 'Aziz');
    expect(c.canPay, isTrue);
  });

  test('no_match → noMatch, to\'lov yo\'q', () async {
    server.on(
        'POST', '/api/v1/identify', FakeKaftpay.ok(identifyData('no_match')));
    final c = checkout();
    await c.start();
    expect(c.step, KaftpayCheckoutStep.noMatch);
    expect(c.canPay, isFalse);
  });

  test('skaner xatosi → failed; bekor qilinsa holat o\'zgarmaydi', () async {
    final c = checkout(scanner: FakeScanner(error: 'Kaft skaneri topilmadi'));
    await c.start();
    expect(c.step, KaftpayCheckoutStep.failed);
    expect(c.message, contains('topilmadi'));
    expect(server.requests, isEmpty);

    final c2 = checkout(scanner: FakeScanner(cancelledError: true));
    await c2.start();
    expect(c2.step, KaftpayCheckoutStep.scanning);
    expect(server.requests, isEmpty);
  });

  test('identify server xatosi → failed (o\'zbekcha xabar)', () async {
    server.on('POST', '/api/v1/identify',
        FakeKaftpay.fail('1100', 'unknown or inactive terminal', status: 401));
    final c = checkout();
    await c.start();
    expect(c.step, KaftpayCheckoutStep.failed);
    expect(c.message, isNotEmpty);
  });

  test('aniqlash muddati o\'tgan → /pay yuborilmaydi, qayta skan', () async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok(identifyData('confident',
            suggestion: cand(kConsumer, 'Alisher', '4567'))));
    final c = checkout();
    await c.start();
    now = now.add(const Duration(seconds: 116)); // 120 − 5 s chegara
    expect(c.isExpired, isTrue);
    expect(c.canPay, isFalse);
    await c.pay();
    expect(c.step, KaftpayCheckoutStep.failed);
    expect(payCalls(), 0);
    expect(journal.all(), isEmpty);
  });

  test('kassir ma\'lumoti yo\'q → mahalliy xato, /pay ham jurnal ham yo\'q',
      () async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok(identifyData('confident',
            suggestion: cand(kConsumer, 'Alisher', '4567'))));
    final c = checkout(cashierId: '', cashierName: '');
    await c.start();
    await c.pay();
    expect(c.step, KaftpayCheckoutStep.failed);
    expect(payCalls(), 0);
    expect(journal.all(), isEmpty);
  });

  test('/pay javobi yo\'qoldi → status 1210 → failed (pul yechilmadi)',
      () async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok(identifyData('confident',
            suggestion: cand(kConsumer, 'Alisher', '4567'))));
    server.on('POST', '/api/v1/pay', FakeKaftpay.never());
    server.on(
        'GET', '/api/v1/pay/status/$kKey', FakeKaftpay.fail('1210', 'no'));
    final c = checkout();
    await c.start();
    await c.pay();
    expect(c.step, KaftpayCheckoutStep.failed);
    expect(c.message, contains('Pul yechilmadi'));
    expect(journal.byKey(kKey)!.status, KaftpayJournalStatus.notCharged);
    expect(payCalls(), 1);
  });

  test(
      'noma\'lum → bekor qilib bo\'lmaydi; "Holatni tekshirish" → charged; '
      '/pay qayta yuborilmaydi', () async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok(identifyData('confident',
            suggestion: cand(kConsumer, 'Alisher', '4567'))));
    server.on('POST', '/api/v1/pay', FakeKaftpay.fail('1215', 'unknown'));
    for (var i = 0; i < 3; i++) {
      server.on('GET', '/api/v1/pay/status/$kKey',
          FakeKaftpay.raw('bad gateway', 502));
    }
    server.on('GET', '/api/v1/pay/status/$kKey', FakeKaftpay.ok(statusData()));
    final c = checkout();
    await c.start();
    await c.pay();
    expect(c.step, KaftpayCheckoutStep.unknown);
    expect(c.canCancel, isFalse);
    expect(journal.byKey(kKey)!.status, KaftpayJournalStatus.unknown);
    expect(journal.unresolved().single.key, kKey);

    await c.checkStatus();
    expect(c.step, KaftpayCheckoutStep.charged);
    expect(c.outcome!.transactionId, kTx);
    expect(journal.byKey(kKey)!.status, KaftpayJournalStatus.charged);
    expect(journal.unresolved(), isEmpty);
    expect(payCalls(), 1);
  });

  test('kalit /pay dan OLDIN jurnalga yoziladi (kassa o\'chsa ham qoladi)',
      () async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok(identifyData('confident',
            suggestion: cand(kConsumer, 'Alisher', '4567'))));
    server.on('POST', '/api/v1/pay', FakeKaftpay.never());
    final c = checkout();
    await c.start();
    final paying = c.pay();
    await Future<void>.delayed(Duration.zero);
    expect(c.step, KaftpayCheckoutStep.charging);
    expect(c.canCancel, isFalse);
    expect(journal.byKey(kKey)!.status, KaftpayJournalStatus.pending);
    server.on(
        'GET', '/api/v1/pay/status/$kKey', FakeKaftpay.fail('1210', 'no'));
    await paying;
  });

  test('dispose skan paytida — skaner to\'xtatiladi', () async {
    final scanner = FakeScanner();
    final c = checkout(scanner: scanner);
    c.dispose();
    expect(scanner.cancels, 1);
  });
}
