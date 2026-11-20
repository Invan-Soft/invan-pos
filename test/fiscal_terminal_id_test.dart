// Fiskal modul raqami (ONKM `terminalId`) — `FiscalTerminalId`.
//
// Soliq ONKM so'rovida fiskal modul raqamini talab qiladi. Raqam lokal fiskal
// drayverdan olinadi; drayver xatoda raqam o'rniga matn qaytaradi
// (`'no result'`, `'Unauthorized catch'`) — u soliqqa KETMASLIGI kerak.
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/fiscal_terminal_id.dart';

void main() {
  late String cache;
  late int calls;

  void driver(Future<String> Function() f) {
    FiscalTerminalId.fetcher = () {
      calls++;
      return f();
    };
  }

  setUp(() {
    cache = '';
    calls = 0;
    FiscalTerminalId.reset();
    FiscalTerminalId.readCache = () => cache;
    FiscalTerminalId.writeCache = (v) async => cache = v;
  });

  group('isValid', () {
    test('haqiqiy raqamlar', () {
      expect(FiscalTerminalId.isValid('UZ191211501012'), isTrue);
      expect(FiscalTerminalId.isValid('UZ00000000000000'), isTrue);
    });

    test('drayver xato satrlari, bo\'sh, null — raqam emas', () {
      for (final v in ['no result', 'Unauthorized catch', '', '   ', 'null']) {
        expect(FiscalTerminalId.isValid(v), isFalse, reason: '"$v"');
      }
      expect(FiscalTerminalId.isValid(null), isFalse);
    });
  });

  group('get', () {
    test('drayverdan oladi, keshga yozadi', () async {
      driver(() async => 'UZ191211501012');
      expect(await FiscalTerminalId.get(), 'UZ191211501012');
      expect(cache, 'UZ191211501012');
    });

    test('ikkinchi chaqiruvda drayverga bormaydi (har skanda emas)', () async {
      driver(() async => 'UZ191211501012');
      await FiscalTerminalId.get();
      await FiscalTerminalId.get();
      await FiscalTerminalId.get();
      expect(calls, 1);
    });

    test('drayver javobidagi bo\'shliq olib tashlanadi', () async {
      driver(() async => ' UZ191211501012\n');
      expect(await FiscalTerminalId.get(), 'UZ191211501012');
    });

    test('drayver xato satri → bo\'sh (soliqqa "no result" ketmaydi)',
        () async {
      for (final bad in ['no result', 'Unauthorized catch', '']) {
        FiscalTerminalId.reset();
        driver(() async => bad);
        expect(await FiscalTerminalId.get(), '', reason: '"$bad"');
        expect(cache, '');
      }
    });

    test('drayver xatosida oxirgi ma\'lum raqam (kesh) ishlatiladi', () async {
      cache = 'UZ191211501012';
      driver(() async => 'no result');
      expect(await FiscalTerminalId.get(), 'UZ191211501012');
    });

    test('drayver istisno tashlasa — kesh, u ham yo\'q bo\'lsa bo\'sh',
        () async {
      driver(() async => throw Exception('ulanmadi'));
      expect(await FiscalTerminalId.get(), '');
      cache = 'UZ191211501012';
      expect(await FiscalTerminalId.get(), 'UZ191211501012');
    });

    test('drayver osilib qolsa timeoutdan keyin kesh qaytadi', () async {
      cache = 'UZ191211501012';
      driver(() => Completer<String>().future);
      final sw = Stopwatch()..start();
      expect(await FiscalTerminalId.get(), 'UZ191211501012');
      expect(sw.elapsed, lessThan(const Duration(seconds: 5)));
    });

    test('keshdan olingan raqam xotiraga yozilmaydi — drayver tiklangach '
        'yangi raqam olinadi (modul almashgan)', () async {
      cache = 'UZ111111111111';
      driver(() async => 'no result');
      expect(await FiscalTerminalId.get(), 'UZ111111111111');
      driver(() async => 'UZ222222222222');
      expect(await FiscalTerminalId.get(), 'UZ222222222222');
      expect(cache, 'UZ222222222222');
    });

    test('keshdagi buzuq qiymat ishlatilmaydi', () async {
      cache = 'no result';
      driver(() async => 'Unauthorized catch');
      expect(await FiscalTerminalId.get(), '');
    });

    test('kesh o\'qish/yozish xatosi raqamni buzmaydi', () async {
      FiscalTerminalId.readCache = () => throw StateError('box yopiq');
      FiscalTerminalId.writeCache = (v) async => throw StateError('box yopiq');
      driver(() async => 'UZ191211501012');
      expect(await FiscalTerminalId.get(), 'UZ191211501012');
      FiscalTerminalId.reset();
      driver(() async => 'no result');
      expect(await FiscalTerminalId.get(), '');
    });
  });
}
