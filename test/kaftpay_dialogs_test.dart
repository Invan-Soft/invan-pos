// Kaftpay oynalari: to'lov (tanlash → to'lash → natija) va ro'yxatdan
// o'tkazish (QR + qo'l → kaft → /enroll).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_checkout.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_enroll_dialog.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_pay_dialog.dart';

import 'support/kaftpay_fake_server.dart';

class _Scanner implements KaftpayScanner {
  int captures = 0;
  @override
  String? get unavailableReason => null;
  @override
  Future<KaftpayPalmScan> capture({
    void Function(KaftpayScanStage stage, String message)? onStage,
  }) async {
    captures++;
    return KaftpayPalmScan(
        ir: KaftpaySyntheticScanner.vector(42), hand: KaftpayHand.right);
  }

  @override
  void cancel() {}
}

void main() {
  late FakeKaftpay server;
  setUp(() {
    server = FakeKaftpay();
    KaftpayApi.onHttpResponse = (_) {};
  });

  /// HTTP + shifrlash haqiqiy async'da tugashi uchun (indikator animatsiyasi
  /// sabab `pumpAndSettle` ishlatilmaydi).
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 12; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  KaftpayApi api() => KaftpayApi(
        config:
            const KaftpayConfig(clientId: 'pos-test', secret: 'test-secret'),
        client: server.client,
      );

  Future<void> open(
      WidgetTester tester, Future<void> Function(BuildContext) show) async {
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (ctx) => Scaffold(
          body: Center(
            child: TextButton(
                onPressed: () => show(ctx), child: const Text('open')),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
  }

  testWidgets(
      'to\'lov: ambiguous — tanlamaguncha "To\'lash" o\'chiq; tanlab '
      'to\'lasa oyna natija bilan yopiladi', (tester) async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok({
          'requestId': kRequestId,
          'reason': 'ambiguous',
          'candidates': [
            {
              'consumerGuid': kConsumer,
              'name': kConsumer,
              'firstName': 'Alisher',
              'phoneLast4': '4567'
            },
            {
              'consumerGuid': kConsumer2,
              'name': kConsumer2,
              'firstName': 'Aziz',
              'phoneLast4': '1234'
            },
          ],
          'expiresAt': '01.08.2026 15:08:12',
        }));
    server.on('POST', '/api/v1/pay', FakeKaftpay.ok(payData()));
    String raw = '';
    final a = api();
    final checkout = KaftpayCheckout(
      api: a,
      scanner: _Scanner(),
      journal: KaftpayJournal(read: () => raw, write: (v) async => raw = v),
      amount: 2500000,
      cashierId: 'c-17',
      cashierName: 'Nodira S.',
      flow: KaftpayPaymentFlow(a),
      now: () => DateTime(2026, 8, 1, 15, 6, 12),
    );
    KaftpayChargeOutcome? result;
    var closed = false;
    await open(tester, (ctx) async {
      result = await KaftpayPayDialog.show(ctx, checkout: checkout);
      closed = true;
    });

    expect(find.text('25,000 so\'m'), findsOneWidget);
    expect(find.text('Alisher'), findsOneWidget);
    expect(find.text('*** 1234'), findsOneWidget);
    expect(find.text(kConsumer), findsNothing, reason: 'GUID ko\'rsatilmaydi');
    final payBtn = find.byKey(const ValueKey('kaftpay_pay'));
    expect(tester.widget<ButtonStyleButton>(payBtn).onPressed, isNull);

    await tester.tap(find.byKey(ValueKey('kaftpay_cand_$kConsumer2')));
    await tester.pump();
    expect(tester.widget<ButtonStyleButton>(payBtn).onPressed, isNotNull);
    await tester.tap(payBtn);
    await settle(tester);

    // Natija ekrani: ✓, summa; "Tayyor" — yopiladi (yoki 3 s dan keyin o'zi).
    expect(find.byKey(const ValueKey('kaftpay_success')), findsOneWidget);
    expect(closed, isFalse);
    await tester.tap(find.byKey(const ValueKey('kaftpay_done')));
    await settle(tester);

    expect(closed, isTrue);
    expect(result!.isCharged, isTrue);
    expect(result!.transactionId, kTx);
    expect(
        server.jsonBody(
            server.calls('POST', '/api/v1/pay').single)['consumerGuid'],
        kConsumer2);
  });

  testWidgets('to\'lov: natija ekrani 3 s dan keyin o\'zi yopiladi',
      (tester) async {
    server.on(
        'POST',
        '/api/v1/identify',
        FakeKaftpay.ok({
          'requestId': kRequestId,
          'reason': 'confident',
          'suggestion': {'consumerGuid': kConsumer, 'firstName': 'Alisher'},
          'candidates': [
            {'consumerGuid': kConsumer, 'firstName': 'Alisher'}
          ],
          'expiresAt': '01.08.2026 15:08:12',
        }));
    server.on('POST', '/api/v1/pay', FakeKaftpay.ok(payData()));
    String raw = '';
    final a = api();
    final checkout = KaftpayCheckout(
      api: a,
      scanner: _Scanner(),
      journal: KaftpayJournal(read: () => raw, write: (v) async => raw = v),
      amount: 2500000,
      cashierId: 'c-17',
      cashierName: 'Nodira S.',
      flow: KaftpayPaymentFlow(a),
      now: () => DateTime(2026, 8, 1, 15, 6, 12),
    );
    KaftpayChargeOutcome? result;
    await open(tester, (ctx) async {
      result = await KaftpayPayDialog.show(ctx, checkout: checkout);
    });
    await tester.tap(find.byKey(const ValueKey('kaftpay_pay')));
    await settle(tester);
    expect(find.byKey(const ValueKey('kaftpay_success')), findsOneWidget);
    expect(find.text('Alisher'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const ValueKey('kaftpay_success')), findsNothing);
    expect(result?.isCharged, isTrue);
  });

  testWidgets('to\'lov: bekor qilish → null, pul yechilmaydi', (tester) async {
    server.on('POST', '/api/v1/identify',
        FakeKaftpay.ok({'requestId': kRequestId, 'reason': 'no_match'}));
    String raw = '';
    final checkout = KaftpayCheckout(
      api: api(),
      scanner: _Scanner(),
      journal: KaftpayJournal(read: () => raw, write: (v) async => raw = v),
      amount: 100,
      cashierId: 'c',
      cashierName: 'n',
    );
    KaftpayChargeOutcome? result;
    var closed = false;
    await open(tester, (ctx) async {
      result = await KaftpayPayDialog.show(ctx, checkout: checkout);
      closed = true;
    });
    expect(find.byKey(const ValueKey('kaftpay_rescan')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('kaftpay_cancel')));
    await settle(tester);
    expect(closed, isTrue);
    expect(result, isNull);
    expect(server.calls('POST', '/api/v1/pay'), isEmpty);
  });

  testWidgets(
      'ro\'yxatdan o\'tkazish: QR va qo\'l tanlanmaguncha boshlanmaydi; '
      'qo\'l kassir tanlagani ketadi', (tester) async {
    server.on(
        'POST',
        '/api/v1/enroll',
        FakeKaftpay.ok({
          'consumerGuid': kConsumer,
          'status': 'ACTIVE',
          'enrolledAt': '01.08.2026 15:04:22',
        }));
    final scanner = _Scanner();
    await open(tester,
        (ctx) => KaftpayEnrollDialog.show(ctx, api: api(), scanner: scanner));

    final start = find.byKey(const ValueKey('kaftpay_enroll_start'));
    expect(tester.widget<ButtonStyleButton>(start).onPressed, isNull);

    // Barcode skaner: matn + Enter.
    await tester.enterText(find.byKey(const ValueKey('kaftpay_enroll_qr')),
        'PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(tester.widget<ButtonStyleButton>(start).onPressed, isNull,
        reason: 'qo\'l tanlanmagan');

    await tester.tap(find.byKey(const ValueKey('kaftpay_enroll_LEFT')));
    await tester.pump();
    await tester.tap(start);
    await settle(tester);

    expect(scanner.captures, 1);
    final body = server.jsonBody(server.calls('POST', '/api/v1/enroll').single);
    expect(body['qrSessionId'], '3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    expect(body['hand'], 'LEFT', reason: 'SDK RIGHT dedi, kassir — LEFT');
    expect(find.textContaining('ro\'yxatdan o\'tdi'), findsOneWidget);
  });

  test('QR tekshiruvi', () {
    expect(
        KaftpayEnrollDialog.looksLikeQr(
            'PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f'),
        isTrue);
    expect(
        KaftpayEnrollDialog.looksLikeQr(
            ' 3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f '),
        isTrue);
    expect(KaftpayEnrollDialog.looksLikeQr('PPENROLL:'), isFalse);
    expect(KaftpayEnrollDialog.looksLikeQr('4780000000011'), isFalse);
  });
}
