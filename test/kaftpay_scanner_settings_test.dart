// Kaftpay: skaner (SDK natijalari, qayta urinish, bekor qilish) va
// sozlamalar / to'lovlar jurnali.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/payment/kaftpay.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';

List<double> goodIr() => KaftpaySyntheticScanner.vector(7);

KaftpayRawCapture okRaw({int palmType = 1}) => KaftpayRawCapture(
      stage: 'capture',
      code: 0,
      ir: goodIr(),
      rgb: List<double>.filled(516, 0),
      palmType: palmType,
    );

void main() {
  group('Kaftpay.isName', () {
    for (final n in [
      'Kaftpay',
      'KAFTPAY',
      'Kaft Pay',
      'kaft_pay',
      ' kaft-pay '
    ]) {
      test('"$n" → true', () => expect(Kaftpay.isName(n), isTrue));
    }
    for (final n in ['CARD', 'Kaft', 'Pay', '', null]) {
      test('"$n" → false', () => expect(Kaftpay.isName(n), isFalse));
    }
  });

  group('classifyKaftpayCapture (palm_wrapper.dll kodlari)', () {
    test('0 + vektor → ok', () {
      expect(classifyKaftpayCapture(okRaw()).verdict, KaftpayCaptureVerdict.ok);
    });
    test('capture 1 / 2 / -98 → qayta urinish', () {
      for (final c in [1, 2, -98]) {
        expect(
            classifyKaftpayCapture(KaftpayRawCapture(stage: 'capture', code: c))
                .verdict,
            KaftpayCaptureVerdict.retry,
            reason: '$c');
      }
    });
    test('open -1 → skaner topilmadi (drayver), fatal', () {
      final o = classifyKaftpayCapture(
          const KaftpayRawCapture(stage: 'open', code: -1));
      expect(o.verdict, KaftpayCaptureVerdict.fatal);
      expect(o.message, contains('WinUSB'));
    });
    test('DLL yuklanmadi / noma\'lum kod → fatal', () {
      expect(
          classifyKaftpayCapture(const KaftpayRawCapture(
                  stage: 'load', code: -1, loadError: 'no dll'))
              .verdict,
          KaftpayCaptureVerdict.fatal);
      expect(
          classifyKaftpayCapture(
                  const KaftpayRawCapture(stage: 'capture', code: -99))
              .verdict,
          KaftpayCaptureVerdict.fatal);
    });
  });

  group('KaftpaySdkScanner (soxta isolate)', () {
    KaftpaySdkScanner scanner(List<Object> script,
        {List<String>? stops, int attempts = 3}) {
      final s = KaftpaySdkScanner(
        sdkDir: r'C:\kaftpay',
        attempts: attempts,
        runOnce: (dir, timeout) async {
          final next = script.removeAt(0);
          if (next is Future<KaftpayRawCapture>) return next;
          return next as KaftpayRawCapture;
        },
        stop: (dir) => stops?.add(dir),
      )..skipAvailabilityCheck = true;
      return s;
    }

    test('timeout, -98, keyin ok → kaft; xabarlar kassirga', () async {
      final stages = <String>[];
      final s = scanner([
        const KaftpayRawCapture(stage: 'capture', code: 1),
        const KaftpayRawCapture(stage: 'capture', code: -98),
        okRaw(palmType: 0),
      ]);
      final scan = await s.capture(onStage: (_, m) => stages.add(m));
      expect(scan.ir, goodIr());
      expect(scan.hasUsableRgb, isFalse, reason: 'VP930 RGB — nollar');
      expect(scan.hand, KaftpayHand.left);
      expect(stages, hasLength(3));
      expect(stages[1], contains('yashil'));
      expect(stages[2], contains('tekis'));
    });

    test('3 urinishda ham kaft yo\'q → oxirgi sabab bilan xato', () async {
      final s = scanner([
        for (var i = 0; i < 3; i++)
          const KaftpayRawCapture(stage: 'capture', code: 1),
      ]);
      expect(
          () => s.capture(),
          throwsA(isA<KaftpayScannerException>()
              .having((e) => e.cancelled, 'cancelled', isFalse)
              .having(
                  (e) => e.message, 'message', contains('Kaft topilmadi'))));
    });

    test('skaner topilmadi → darhol xato (qayta urinmaydi)', () async {
      final script = <Object>[
        const KaftpayRawCapture(stage: 'open', code: -1),
        okRaw(),
      ];
      final s = scanner(script);
      await expectLater(s.capture(), throwsA(isA<KaftpayScannerException>()));
      expect(script, hasLength(1), reason: 'ikkinchi urinish bo\'lmadi');
    });

    test(
        'bekor qilish — darhol qaytadi, palm_stop chaqiriladi; keyingi skan '
        'oldingi isolate tugashini kutadi', () async {
      final first = Completer<KaftpayRawCapture>();
      final stops = <String>[];
      final script = <Object>[first.future, okRaw()];
      final s = scanner(script, stops: stops);

      final c1 = s.capture();
      await Future<void>.delayed(Duration.zero);
      s.cancel();
      await expectLater(
          c1,
          throwsA(isA<KaftpayScannerException>()
              .having((e) => e.cancelled, 'cancelled', isTrue)));
      expect(stops, [r'C:\kaftpay']);

      final stages = <KaftpayScanStage>[];
      final c2 = s.capture(onStage: (st, _) => stages.add(st));
      await Future<void>.delayed(Duration.zero);
      expect(stages, [KaftpayScanStage.waitingDevice]);
      expect(script, hasLength(1), reason: 'qurilma hali band');
      first.complete(const KaftpayRawCapture(stage: 'capture', code: 2));
      final scan = await c2;
      expect(scan.ir, goodIr());
    });

    test('Windows bo\'lmasa — sabab ko\'rsatiladi', () {
      final s = KaftpaySdkScanner(sdkDir: r'C:\kaftpay');
      expect(s.unavailableReason, isNotNull);
    });
  });

  test('sun\'iy vektor — namunadagi Python `_lcg_vec(42)` bilan bir xil', () {
    final v = KaftpaySyntheticScanner.vector(42);
    expect(v, hasLength(516));
    expect(v.take(3), [0.164615, 0.039637, -0.068047]);
    expect(v.last, 0.753878);
    expect(KaftpayPalmScan(ir: v).validate(), isNull);
  });

  group('KaftpaySettings.resolveConfig', () {
    test('adminkadagi kalitlar ustun', () {
      final c = KaftpaySettings.resolveConfig(
          adminClientId: ' TERM-1 ',
          adminSecret: 's1',
          localClientId: 'TERM-2',
          localSecret: 's2');
      expect(c!.clientId, 'TERM-1');
      expect(c.secret, 's1');
      expect(c.baseUrl, 'https://pos-api.kaftpay.uz/pp-pos-api');
    });
    test('adminkada bittasi bo\'sh → kassa sozlamasi', () {
      final c = KaftpaySettings.resolveConfig(
          adminClientId: 'TERM-1',
          adminSecret: '',
          localClientId: 'TERM-2',
          localSecret: 's2');
      expect(c!.clientId, 'TERM-2');
    });
    test('hech qayerda yo\'q → null', () {
      expect(KaftpaySettings.resolveConfig(localClientId: '', localSecret: ''),
          isNull);
    });
  });

  group('KaftpayJournal', () {
    late String raw;
    late KaftpayJournal j;
    setUp(() {
      raw = '';
      j = KaftpayJournal(read: () => raw, write: (v) async => raw = v);
    });

    KaftpayJournalEntry e(String key,
            {KaftpayJournalStatus status = KaftpayJournalStatus.charged}) =>
        KaftpayJournalEntry(
          key: key,
          requestId: 'r',
          consumerGuid: 'g',
          consumerName: 'Alisher',
          amount: 100,
          createdAt: DateTime(2026, 10, 30, 12),
          status: status,
          transactionId: 'tx-$key',
        );

    test('yangisi birinchi; kalit bo\'yicha yangilanadi; JSON qaytib o\'qiladi',
        () async {
      await j.put(e('a', status: KaftpayJournalStatus.pending));
      await j.put(e('b'));
      await j.put(e('a').copyWith(status: KaftpayJournalStatus.refunded));
      final all = j.all();
      expect(all.map((x) => x.key), ['a', 'b']);
      expect(all.first.status, KaftpayJournalStatus.refunded);
      expect(all.first.createdAt, DateTime(2026, 10, 30, 12));
      expect(all.first.consumerName, 'Alisher');
      expect(j.byKey('b')!.transactionId, 'tx-b');
      expect(j.unresolved(), isEmpty);
    });

    test('limitdan oshganda eski yozuvlar tushadi, tekshirilmaganlari QOLADI',
        () async {
      await j.put(e('old-unknown', status: KaftpayJournalStatus.unknown));
      for (var i = 0; i < KaftpayJournal.maxEntries + 5; i++) {
        await j.put(e('k$i'));
      }
      final all = j.all();
      expect(all, hasLength(KaftpayJournal.maxEntries + 1));
      expect(j.unresolved().single.key, 'old-unknown');
    });

    test('buzilgan JSON → bo\'sh (ilova yiqilmaydi)', () {
      raw = '{oops';
      expect(j.all(), isEmpty);
      raw = '[{"no":"key"}, 5]';
      expect(j.all(), isEmpty);
    });
  });
}
