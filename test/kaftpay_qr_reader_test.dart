// VP930 kamerasidan QR o'qish: kadrdan dekodlash (oddiy va ko'zgu tasvir)
// va o'qish sikli (ochish → kadrlar → yopish, to'xtatish, xatolar).
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_qr_reader.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:qr/qr.dart';

const kQr = 'PPENROLL:3f1b8c2d-9a4e-4c11-b6d5-77e0a1c93b4f';
const kW = 720, kH = 1024;

/// VP930 kadri kabi BGR888 rasm: kulrang fon, o'rtada QR (telefon ekrani).
Uint8List frameWithQr(String text,
    {int module = 7, bool mirrored = false, int bg = 150}) {
  final img = QrImage(
      QrCode.fromData(data: text, errorCorrectLevel: QrErrorCorrectLevel.M));
  final n = img.moduleCount;
  final buf = Uint8List(kW * kH * 3)..fillRange(0, kW * kH * 3, bg);
  const quiet = 4;
  final size = (n + quiet * 2) * module;
  final left = (kW - size) ~/ 2, top = (kH - size) ~/ 2;
  for (var y = 0; y < size; y++) {
    for (var x = 0; x < size; x++) {
      final my = y ~/ module - quiet, mx = x ~/ module - quiet;
      final dark = my >= 0 && mx >= 0 && my < n && mx < n && img.isDark(my, mx);
      final px = mirrored ? kW - 1 - (left + x) : left + x;
      final i = ((top + y) * kW + px) * 3;
      final v = dark ? 20 : 245;
      buf[i] = v;
      buf[i + 1] = v;
      buf[i + 2] = v;
    }
  }
  return buf;
}

void main() {
  group('decodeKaftpayQr', () {
    test('kadrdagi QR o\'qiladi', () {
      expect(decodeKaftpayQr(frameWithQr(kQr), kW, kH), kQr);
    });

    test('ko\'zgu tasvir (kamera teskari bersa) ham o\'qiladi', () {
      final f = frameWithQr(kQr, mirrored: true);
      expect(decodeKaftpayQr(f, kW, kH), kQr);
    });

    test('kichikroq QR (telefon uzoqroq) ham', () {
      expect(decodeKaftpayQr(frameWithQr(kQr, module: 5), kW, kH), kQr);
    });

    test('QR yo\'q / buzilgan kadr — null', () {
      final empty = Uint8List(kW * kH * 3)..fillRange(0, kW * kH * 3, 128);
      expect(decodeKaftpayQr(empty, kW, kH), isNull);
      expect(decodeKaftpayQr(Uint8List(10), kW, kH), isNull);
      expect(decodeKaftpayQr(empty, 0, 0), isNull);
    });
  });

  group('KaftpaySdkQrReader — o\'qish sikli', () {
    late List<String> calls;
    setUp(() => calls = []);

    KaftpaySdkQrReader reader({
      int openCode = 0,
      List<KaftpayQrFrame> frames = const [],
      Future<KaftpayQrFrame> Function()? grab,
      DateTime Function()? now,
    }) {
      var i = 0;
      return KaftpaySdkQrReader(
        sdkDir: 'C:\\sdk',
        open: (_) async {
          calls.add('open');
          return openCode;
        },
        grab: (_, __) async {
          calls.add('grab');
          if (grab != null) return grab();
          return i < frames.length ? frames[i++] : const KaftpayQrFrame(0);
        },
        close: (_) async => calls.add('close'),
        now: now,
      );
    }

    test('PPENROLL topilishi bilan qaytadi; kamera yopiladi', () async {
      final r = reader(frames: const [
        KaftpayQrFrame(0),
        KaftpayQrFrame(0, 'https://example.uz'), // boshqa QR — e'tiborsiz
        KaftpayQrFrame(0, '  $kQr '),
      ]);
      expect(await r.read(), kQr);
      expect(calls, ['open', 'grab', 'grab', 'grab', 'close']);
    });

    test('to\'xtatilsa — null; stop() kamera yopilgach tugaydi', () async {
      final frame = Completer<KaftpayQrFrame>();
      final r = reader(grab: () => frame.future);
      final result = r.read();
      await Future<void>.delayed(Duration.zero);
      var stopped = false;
      final stop = r.stop().then((_) => stopped = true);
      await Future<void>.delayed(Duration.zero);
      expect(stopped, isFalse, reason: 'joriy kadr tugamagan');
      frame.complete(const KaftpayQrFrame(0, kQr));
      expect(await result, isNull, reason: 'to\'xtatilgandan keyingi kadr');
      await stop;
      expect(stopped, isTrue);
      expect(calls.last, 'close');
    });

    test('o\'qimayotganda stop() darhol tugaydi', () async {
      await reader().stop();
      expect(calls, isEmpty);
    });

    test('kamera ochilmasa — xato, yopish chaqirilmaydi', () async {
      final r = reader(openCode: -2);
      await expectLater(
          r.read(),
          throwsA(isA<KaftpayScannerException>()
              .having((e) => e.message, 'message', contains('-2'))));
      expect(calls, ['open']);
    });

    test('vaqt tugasa — null', () async {
      var t = DateTime(2026, 10, 31, 12);
      final r = reader(
        grab: () async {
          t = t.add(const Duration(seconds: 1));
          return const KaftpayQrFrame(0);
        },
        now: () => t,
      );
      expect(await r.read(timeout: const Duration(seconds: 5)), isNull);
      expect(calls.where((c) => c == 'grab').length, 5);
      expect(calls.last, 'close');
    });

    test('oqim yo\'q (-6) — sikl tugaydi', () async {
      final r = reader(frames: const [KaftpayQrFrame(-6)]);
      expect(await r.read(), isNull);
      expect(calls, ['open', 'grab', 'close']);
    });

    test('ikkinchi read() avvalgisi yopilmaguncha kamerani ochmaydi', () async {
      final frame = Completer<KaftpayQrFrame>();
      var n = 0;
      final r = reader(grab: () {
        n++;
        return n == 1
            ? frame.future
            : Future.value(const KaftpayQrFrame(0, kQr));
      });
      final first = r.read();
      await Future<void>.delayed(Duration.zero);
      final stopping = r.stop();
      final second = r.read();
      await Future<void>.delayed(Duration.zero);
      expect(calls.where((c) => c == 'open').length, 1);
      frame.complete(const KaftpayQrFrame(0));
      expect(await first, isNull);
      await stopping;
      expect(await second, kQr);
      expect(calls, ['open', 'grab', 'close', 'open', 'grab', 'close']);
    });
  });
}
