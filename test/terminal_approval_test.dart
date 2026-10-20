// Terminal (Arcus) to'lov tasdiqini aniqlash — TerminalReceiptParser.isTerminalApproved.
//
// Sabab: 2026-10-20 da SKappay terminali (UZCARD, 100 so'm) "Одобрено" deb
// kichik harflarda yozdi, eski tekshiruv faqat "ОДОБРЕНО" ni qidirgani uchun
// pul yechilgan bo'lsa ham dastur "To'lov amalga oshmadi" dedi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/terminal/terminal_receipt_parser.dart';

bool approved(String log) => TerminalReceiptParser.isTerminalApproved(log);

void main() {
  group('isTerminalApproved', () {
    test('SKappay: STORERC:000 va "Одобрено" (haqiqiy log) — tasdiqlandi', () {
      const log = '''
2026/10/20 13:02:09 SEND -> 11860100.00
2026/10/20 13:02:09 RECV <- GETTAGS:
2026/10/20 13:02:14 ERROR: recive message: empty
2026/10/20 13:02:14 SEND -> NAK
2026/10/20 13:02:15 RECV <- STORERC:000
2026/10/20 13:02:16 RECV <- PRINT:Тип:                          UZCARD
2026/10/20 13:02:16 RECV <- PRINT:               Оплата
2026/10/20 13:02:16 RECV <- PRINT:             100.00 UZS
2026/10/20 13:02:17 RECV <- PRINT:              Одобрено
2026/10/20 13:02:17 RECV <- PRINT:          Код ответа:000
2026/10/20 13:02:17 RECV <- ENDTR
''';
      expect(approved(log), isTrue);
    });

    test('TezQR: STORERC bo\'sh, keyingi qatorda sana, "Одобрено" — tasdiqlandi',
        () {
      const log = '''
2026/10/20 13:19:54 SEND -> NAK
2026/10/20 13:19:59 RECV <- STORERC:
2026/10/20 13:19:59 SEND -> OK
2026/10/20 13:20:00 RECV <- PRINT:Тип:                          Tez QR
2026/10/20 13:20:01 RECV <- PRINT:          Оплата по TezQR
2026/10/20 13:20:01 RECV <- PRINT:            100.00  UZS
2026/10/20 13:20:01 RECV <- PRINT:              Одобрено
2026/10/20 13:20:01 RECV <- PRINT:Операция подтверждена приложением PA
2026/10/20 13:20:01 RECV <- ENDTR
''';
      expect(approved(log), isTrue);
    });

    test('STORERC bo\'sh va tasdiq so\'zi yo\'q — rad', () {
      const log = '''
2026/10/20 13:19:59 RECV <- STORERC:
2026/10/20 13:19:59 RECV <- ENDTR
''';
      expect(approved(log), isFalse);
    });

    test('STORERC nolga teng bo\'lmasa — matnda "Одобрено" bo\'lsa ham rad', () {
      const log = '''
RECV <- STORERC:051
RECV <- PRINT:Одобрено
''';
      expect(approved(log), isFalse);
    });

    test('STORERC yo\'q, katta harfli "ОДОБРЕНО" (eski terminal) — tasdiqlandi',
        () {
      expect(approved('RECV <- PRINT:      ОДОБРЕНО'), isTrue);
    });

    test('STORERC yo\'q, "TASDIQLANDI" — tasdiqlandi', () {
      expect(approved('RECV <- PRINT: TASDIQLANDI'), isTrue);
    });

    test('"Не одобрено" — rad', () {
      expect(approved('RECV <- PRINT: Не одобрено'), isFalse);
    });

    test('ulanish xatosi — rad', () {
      const log = '''
2026/10/16 17:33:47 ITPos
2026/10/16 17:33:48 COM10
2026/10/16 17:33:48 Connection ERROR
''';
      expect(approved(log), isFalse);
    });

    test('terminal jim (faqat NAK) — rad', () {
      const log = '''
SEND -> 11860100.00
ERROR: recive message: empty
SEND -> NAK
''';
      expect(approved(log), isFalse);
    });
  });
}
