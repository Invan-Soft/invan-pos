// Kaftpay oynalari: to'lov (tanlash → to'lash → natija) va ro'yxatdan
// o'tkazish (QR + qo'l → kaft → /enroll).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_checkout.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_qr_reader.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_enroll_dialog.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_pay_dialog.dart';

import 'support/kaftpay_fake_server.dart';

class _Scanner implements KaftpayScanner {
  _Scanner({this.hand = KaftpayHand.right});

  /// SDK `palm_type` dan aniqlangan qo'l.
  final KaftpayHand hand;
  int captures = 0;
  @override
  String? get unavailableReason => null;
  @override
  Future<KaftpayPalmScan> capture({
    void Function(KaftpayScanStage stage, String message)? onStage,
  }) async {
    captures++;
    return KaftpayPalmScan(ir: KaftpaySyntheticScanner.vector(42), hand: hand);
  }

  @override
  void cancel() {}
}

class _EventScanner extends _Scanner {
  _EventScanner(this.events);
  final List<String> events;

  @override
  Future<KaftpayPalmScan> capture({
    void Function(KaftpayScanStage stage, String message)? onStage,
  }) {
    events.add('capture');
    return super.capture(onStage: onStage);
  }
}

/// VP930 kamerasi o'rniga: [show] — mijoz telefonni ko'rsatdi.
class _QrReader implements KaftpayQrReader {
  _QrReader(this.events, {this.why});
  final List<String> events;
  final String? why;
  Completer<String?>? _pending;

  @override
  String? get unavailableReason => why;

  @override
  Future<String?> read({Duration timeout = const Duration(seconds: 60)}) {
    events.add('qr.read');
    return (_pending = Completer<String?>()).future;
  }

  void show(String text) => _pending!.complete(text);

  void fail(String message) =>
      _pending!.completeError(KaftpayScannerException(message));

  @override
  Future<void> stop() async {
    events.add('qr.stop');
    final p = _pending;
    if (p != null && !p.isCompleted) p.complete(null);
  }
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

  testWidgets('to\'lov: Esc — bekor qilish (pul yechilmaydi)', (tester) async {
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
    var closed = false;
    await open(tester, (ctx) async {
      await KaftpayPayDialog.show(ctx, checkout: checkout);
      closed = true;
    });
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(tester);
    expect(closed, isTrue);
    expect(server.calls('POST', '/api/v1/pay'), isEmpty);
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

  void enrollOk() => server.on(
      'POST',
      '/api/v1/enroll',
      FakeKaftpay.ok({
        'consumerGuid': kConsumer,
        'status': 'ACTIVE',
        'enrolledAt': '01.08.2026 15:04:22',
      }));

  testWidgets(
      'ro\'yxatdan o\'tkazish: QR skanerlanishi bilan kaft skaneri o\'zi '
      'boshlanadi; qo\'l SDK\'dan (kassir tanlamaydi)', (tester) async {
    enrollOk();
    final scanner = _Scanner(hand: KaftpayHand.left);
    await open(tester,
        (ctx) => KaftpayEnrollDialog.show(ctx, api: api(), scanner: scanner));
    expect(find.byKey(const ValueKey('kaftpay_enroll_LEFT')), findsNothing,
        reason: 'qo\'l tanlash yo\'q');
    expect(scanner.captures, 0);

    // Barcode skaner: matn + Enter.
    await tester.enterText(find.byKey(const ValueKey('kaftpay_enroll_qr')),
        'PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);

    expect(scanner.captures, 1);
    final body = server.jsonBody(server.calls('POST', '/api/v1/enroll').single);
    expect(body['qrSessionId'], '3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    expect(body['hand'], 'LEFT', reason: 'SDK palm_type');
    expect(find.textContaining('ro\'yxatdan o\'tdi'), findsOneWidget);
  });

  testWidgets(
      'ro\'yxatdan o\'tkazish: QR emas — skaner boshlanmaydi, xato ko\'rinadi',
      (tester) async {
    final scanner = _Scanner();
    await open(tester,
        (ctx) => KaftpayEnrollDialog.show(ctx, api: api(), scanner: scanner));
    await tester.enterText(
        find.byKey(const ValueKey('kaftpay_enroll_qr')), '4780000000011');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle(tester);
    expect(scanner.captures, 0);
    expect(find.byKey(const ValueKey('kaftpay_enroll_qr_invalid')),
        findsOneWidget);
    expect(server.calls('POST', '/api/v1/enroll'), isEmpty);
  });

  testWidgets(
      'ro\'yxatdan o\'tkazish: SDK qo\'lni aniqlay olmasa — kassir tanlaydi, '
      'kaft qayta skanerlanmaydi', (tester) async {
    enrollOk();
    final scanner = _Scanner(hand: KaftpayHand.unspecified);
    await open(tester,
        (ctx) => KaftpayEnrollDialog.show(ctx, api: api(), scanner: scanner));
    await tester.enterText(find.byKey(const ValueKey('kaftpay_enroll_qr')),
        '3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    await settle(tester);
    expect(server.calls('POST', '/api/v1/enroll'), isEmpty,
        reason: 'UNSPECIFIED yuborilmaydi (server 1104)');
    await tester.tap(find.byKey(const ValueKey('kaftpay_enroll_RIGHT')));
    await settle(tester);

    expect(scanner.captures, 1);
    final body = server.jsonBody(server.calls('POST', '/api/v1/enroll').single);
    expect(body['hand'], 'RIGHT');
    expect(find.textContaining('ro\'yxatdan o\'tdi'), findsOneWidget);
  });

  testWidgets(
      'ro\'yxatdan o\'tkazish: oyna ochiq turganda global skaner tinglovchisi '
      'o\'chiq (QR mahsulot deb qidirilmaydi), yopilganda qaytadi',
      (tester) async {
    final bl = BlBloc();
    addTearDown(bl.close);
    expect(bl.status, BLStatus.home);
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(BlocProvider<BlBloc>.value(
      value: bl,
      child: MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: TextButton(
                  onPressed: () => KaftpayEnrollDialog.show(ctx,
                      api: api(), scanner: _Scanner()),
                  child: const Text('open')),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(bl.status, BLStatus.other);

    await tester.tap(find.byKey(const ValueKey('kaftpay_enroll_close')));
    await settle(tester);
    expect(find.byType(KaftpayEnrollDialog), findsNothing);
    expect(bl.status, BLStatus.home);
  });

  testWidgets('ro\'yxatdan o\'tkazish: ruscha klaviaturada skanerlangan QR',
      (tester) async {
    server.on(
        'POST',
        '/api/v1/enroll',
        FakeKaftpay.ok({
          'consumerGuid': kConsumer,
          'status': 'ACTIVE',
          'enrolledAt': '01.08.2026 15:04:22',
        }));
    await open(
        tester,
        (ctx) =>
            KaftpayEnrollDialog.show(ctx, api: api(), scanner: _Scanner()));
    await tester.enterText(find.byKey(const ValueKey('kaftpay_enroll_qr')),
        'ЗЗУТКЩДДЖ3а1и8с2в-9ф4у-4с11-и6в5-77у0ф1с93и4а');
    await settle(tester);
    final body = server.jsonBody(server.calls('POST', '/api/v1/enroll').single);
    expect(body['qrSessionId'], '3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    expect(body['hand'], 'RIGHT');
  });

  testWidgets(
      'ro\'yxatdan o\'tkazish: QR\'ni VP930 kamerasi o\'qisa — kamera yopilib, '
      'kaft skaneri o\'zi boshlanadi', (tester) async {
    enrollOk();
    final events = <String>[];
    final qr = _QrReader(events);
    await open(
        tester,
        (ctx) => KaftpayEnrollDialog.show(ctx,
            api: api(), scanner: _EventScanner(events), qrReader: qr));
    expect(events, ['qr.read']);
    expect(find.textContaining('kaft skaneriga'), findsOneWidget);

    qr.show('PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    await settle(tester);

    expect(events, ['qr.read', 'qr.stop', 'capture'],
        reason: 'kamera yopilmaguncha kaft skaneri qurilmani olmaydi');
    final body = server.jsonBody(server.calls('POST', '/api/v1/enroll').single);
    expect(body['qrSessionId'], '3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    expect(find.textContaining('ro\'yxatdan o\'tdi'), findsOneWidget);
  });

  testWidgets(
      'ro\'yxatdan o\'tkazish: barcode skaner birinchi o\'qisa — kamera '
      'to\'xtatiladi, keyin kaft', (tester) async {
    enrollOk();
    final events = <String>[];
    final qr = _QrReader(events);
    await open(
        tester,
        (ctx) => KaftpayEnrollDialog.show(ctx,
            api: api(), scanner: _EventScanner(events), qrReader: qr));
    await tester.enterText(find.byKey(const ValueKey('kaftpay_enroll_qr')),
        'PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    await settle(tester);
    expect(events, ['qr.read', 'qr.stop', 'capture']);
    expect(server.calls('POST', '/api/v1/enroll'), hasLength(1));
  });

  testWidgets(
      'ro\'yxatdan o\'tkazish: kamera ochilmasa / palm_frame.dll yo\'q — '
      'barcode skaner ishlayveradi', (tester) async {
    enrollOk();
    final events = <String>[];
    final qr = _QrReader(events);
    await open(
        tester,
        (ctx) => KaftpayEnrollDialog.show(ctx,
            api: api(), scanner: _EventScanner(events), qrReader: qr));
    qr.fail('VP930 kamerasi ochilmadi (kod -2)');
    await settle(tester);
    expect(find.byKey(const ValueKey('kaftpay_enroll_camera_error')),
        findsOneWidget);
    expect(find.textContaining('Barcode skaner bilan'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('kaftpay_enroll_qr')),
        '3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    await settle(tester);
    expect(server.calls('POST', '/api/v1/enroll'), hasLength(1));
  });

  testWidgets(
      'ro\'yxatdan o\'tkazish: palm_frame.dll yo\'q — kamera ochilmaydi, '
      'sabab ko\'rinadi', (tester) async {
    final events2 = <String>[];
    await open(
        tester,
        (ctx) => KaftpayEnrollDialog.show(ctx,
            api: api(),
            scanner: _Scanner(),
            qrReader: _QrReader(events2, why: 'palm_frame.dll topilmadi')));
    expect(events2, isEmpty);
    expect(find.text('palm_frame.dll topilmadi'), findsOneWidget);
    expect(find.textContaining('Barcode skaner bilan'), findsOneWidget);
  });

  testWidgets('ro\'yxatdan o\'tkazish: yopilganda kamera to\'xtatiladi',
      (tester) async {
    final events = <String>[];
    await open(
        tester,
        (ctx) => KaftpayEnrollDialog.show(ctx,
            api: api(),
            scanner: _EventScanner(events),
            qrReader: _QrReader(events)));
    await tester.tap(find.byKey(const ValueKey('kaftpay_enroll_close')));
    await settle(tester);
    expect(events, ['qr.read', 'qr.stop']);
    expect(find.byType(KaftpayEnrollDialog), findsNothing);
  });

  test('QR tekshiruvi', () {
    expect(
        KaftpayEnrollDialog.normalizeQr(
            ' ЗЗУТКЩДДЖ3а1и8с2в-9ф4у-4с11-и6в5-77у0ф1с93и4а '),
        'PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f');
    expect(
        KaftpayEnrollDialog.looksLikeQr(
            'ЗЗУТКЩДДЖ3а1и8с2в-9ф4у-4с11-и6в5-77у0ф1с93и4а'),
        isTrue);
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
