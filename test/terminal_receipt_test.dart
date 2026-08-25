// Terminal (Arcus) chek matnini tahlil qilish — xarakteristik test.
//
// MAQSAD: `parseTerminalReceipt` hozirgi xatti-harakatini MUZLATISH.
// Faza 1 da bu funksiya `lib/changes/domain/terminal/` ga ko'chiriladi;
// bu testlar ko'chirish natijani o'zgartirmaganini isbotlaydi.
//
// Funksiyaning O'ZI sof: hech qanday maydonga, Hive'ga yoki tarmoqqa
// tegmaydi. Lekin u instans metodi bo'lgani uchun provider yaratish kerak,
// provider esa konstruktorda `HiveBoxes.getCurrentEmployee` ni o'qiydi —
// shuning uchun harness baribir zarur. Faza 1 da funksiya sinfdan chiqarilgach
// bu bog'liqlik yo'qoladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late OrderingProvider4 p;

  setUpAll(() async {
    await setUpPosTestEnv('terminal_receipt_test');
    p = OrderingProvider4();
  });
  tearDownAll(tearDownPosTestEnv);

  group('RRN ajratib olish', () {
    test('probel bilan: "RRN :608610728951"', () {
      final r = p.parseTerminalReceipt('RRN :608610728951');
      expect(r['rrn'], '608610728951');
    });

    test('probelsiz: "RRN:608610728951"', () {
      final r = p.parseTerminalReceipt('RRN:608610728951');
      expect(r['rrn'], '608610728951');
    });

    test('log prefiksi olib tashlanadi', () {
      final r = p.parseTerminalReceipt(
        '2026-08-05 RECV <- PRINT: RRN :123456789012',
      );
      expect(r['rrn'], '123456789012');
    });

    test('birinchi topilgani olinadi, keyingilari e\'tiborsiz', () {
      final r = p.parseTerminalReceipt('RRN :111111111111\nRRN :222222222222');
      expect(r['rrn'], '111111111111');
    });

    test('RRN yo\'q bo\'lsa null', () {
      final r = p.parseTerminalReceipt('Hech narsa yo\'q');
      expect(r['rrn'], isNull);
    });
  });

  group('Karta raqami', () {
    test('yulduzchali format: 4916********3620', () {
      final r = p.parseTerminalReceipt('KARTA: 4916********3620');
      expect(r['cardNumber'], '4916********3620');
    });

    test('6 raqamli BIN: 986017******4357', () {
      final r = p.parseTerminalReceipt('986017******4357');
      expect(r['cardNumber'], '986017******4357');
    });

    test('probelli format probelsiz qaytadi: "9860 **** **** 1220"', () {
      final r = p.parseTerminalReceipt('9860 **** **** 1220');
      // Probellar olib tashlanadi, yulduzchalar qoladi (4+4=8 ta)
      expect(r['cardNumber'], '9860********1220');
    });
  });

  group('Karta turi', () {
    test('HUMO', () {
      expect(p.parseTerminalReceipt('HUMO CARD')['cardType'], 'HUMO');
    });

    test('UZCARD', () {
      expect(p.parseTerminalReceipt('UZCARD')['cardType'], 'UZCARD');
    });

    test('VISA -> "VISA INT"', () {
      expect(p.parseTerminalReceipt('VISA')['cardType'], 'VISA INT');
    });

    test('HUMO va UZCARD birga bo\'lsa HUMO ustun', () {
      expect(
        p.parseTerminalReceipt('HUMO UZCARD')['cardType'],
        'HUMO',
      );
    });

    test('tanish tur yo\'q bo\'lsa null', () {
      expect(p.parseTerminalReceipt('MASTERCARD')['cardType'], isNull);
    });
  });

  group('Avtorizatsiya kodi, miqdor, sana', () {
    test('avtorizatsiya kodi', () {
      final r = p.parseTerminalReceipt('Avtorizatsiya kodi: A1B2C3');
      expect(r['authCode'], 'A1B2C3');
    });

    test('kichik harf bilan ham ishlaydi', () {
      final r = p.parseTerminalReceipt('avtorizatsiya kodi : XYZ789');
      expect(r['authCode'], 'XYZ789');
    });

    test('miqdor UZS bilan', () {
      final r = p.parseTerminalReceipt('MIQDOR : 150 000.00 UZS');
      expect(r['amount'], '150 000.00 UZS');
    });

    test('sana', () {
      final r = p.parseTerminalReceipt('Sana: 05.08.2026 14:30');
      expect(r['date'], '05.08.2026 14:30');
    });
  });

  group('To\'liq chek', () {
    test('barcha maydonlar bitta chekdan ajratiladi', () {
      const receipt = '''
TERMINAL CHEKI
UZCARD
8600 **** **** 1234
RRN :608610728951
Avtorizatsiya kodi: 123456
MIQDOR : 250 000.00 UZS
Sana: 05.08.2026 16:45
''';
      final r = p.parseTerminalReceipt(receipt);

      expect(r['cardType'], 'UZCARD');
      expect(r['cardNumber'], '8600********1234');
      expect(r['rrn'], '608610728951');
      expect(r['authCode'], '123456');
      expect(r['amount'], '250 000.00 UZS');
      expect(r['date'], '05.08.2026 16:45');
    });

    test('bo\'sh matn: hamma maydon null, xato bermaydi', () {
      final r = p.parseTerminalReceipt('');

      expect(r['rrn'], isNull);
      expect(r['cardNumber'], isNull);
      expect(r['authCode'], isNull);
      expect(r['amount'], isNull);
      expect(r['date'], isNull);
      expect(r['cardType'], isNull);
    });

    test('natija har doim 6 ta kalitli map', () {
      final r = p.parseTerminalReceipt('shunchaki matn');

      expect(
        r.keys.toSet(),
        {'rrn', 'cardNumber', 'authCode', 'amount', 'date', 'cardType'},
      );
    });
  });
}
