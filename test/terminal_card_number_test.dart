// Terminal chekidan karta raqami — fiskal ExtraInfo.CardNumber manbai.
//
// Sabab (2026-10-20): yangi terminalda korporativ Uzcard to'lovida
// ExtraInfo.CardNumber bo'sh ketdi, Humo'da esa to'g'ri. Eski regex
// (2026-04) faqat "4916********3620", "986017******4357",
// "9860 **** **** 1220" ko'rinishlarini bilardi; BIN ichida bo'sh joy,
// faqat oxirgi 4 raqam yoki X niqobli raqamni topmasdi. Chekda topilmasa
// endi shu operatsiya logidagi `RECV <- PRINT:` qatorlaridan olinadi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/terminal/terminal_receipt_parser.dart';

String? pan(String text) =>
    TerminalReceiptParser.parseTerminalReceipt(text)['cardNumber'];

void main() {
  group('Eski formatlar — o\'zgarishsiz', () {
    test('4916********3620', () => expect(pan('KARTA: 4916********3620'), '4916********3620'));
    test('986017******4357', () => expect(pan('986017******4357'), '986017******4357'));
    test('"9860 **** **** 1220" → probelsiz',
        () => expect(pan('9860 **** **** 1220'), '9860********1220'));
    test('"8600 **** **** 1234"',
        () => expect(pan('8600 **** **** 1234'), '8600********1234'));
  });

  group('Yangi terminal formatlari', () {
    final cases = {
      'Карта: 8600 49** **** 1234': '860049******1234',
      'Карта:    8600 49** **** 1234': '860049******1234',
      'Номер карты: ************1234': '************1234',
      '**** **** **** 1234': '************1234',
      'PAN: 8600XXXXXXXX1234': '8600********1234',
      '8600 xxxx xxxx 1234': '8600********1234',
      '8600••••••••1234': '8600********1234',
      'Карта: 860049******1234   UZCARD': '860049******1234',
      '9860 06** **** 4357': '986006******4357',
      '4916 39** **** 3620 VISA': '491639******3620',
    };
    cases.forEach((line, expected) {
      test('"$line" → $expected', () => expect(pan(line), expected));
    });

    test('log qatori (RECV <- PRINT: prefiksi bilan)', () {
      expect(pan('2026/10/20 13:02:16 RECV <- PRINT:Карта:   8600 49** **** 1234'),
          '860049******1234');
    });
  });

  group('Karta raqami EMAS — olinmaydi', () {
    for (final line in [
      'RRN: 629308797462',
      'RRN :608610728951',
      'PPTID 031921779051',
      'TID: 12345678',
      'MID: 000000001234567',
      'Код авторизации: 123456',
      '20.10.2026 13:02:17',
      '2026/10/20 13:02:09 SEND -> 11860100.00',
      '100.00 UZS',
      'Код ответа:000',
      'RECV <- STORERC:000',
      '12 ****', // juda qisqa
    ]) {
      test('"$line" → null', () => expect(pan(line), isNull));
    }
  });

  group('parseTerminalResult — chek ustun, yetishmagani logdan', () {
    const log = '''
2026/10/20 13:02:09 SEND -> 11860100.00
2026/10/20 13:02:09 RECV <- GETTAGS:
2026/10/20 13:02:15 RECV <- STORERC:000
2026/10/20 13:02:16 RECV <- PRINT:Тип:                          UZCARD
2026/10/20 13:02:16 RECV <- PRINT:Карта:          8600 49** **** 1234
2026/10/20 13:02:16 RECV <- PRINT:               Оплата
2026/10/20 13:02:16 RECV <- PRINT:             100.00 UZS
2026/10/20 13:02:17 RECV <- PRINT:RRN:            629308797462
2026/10/20 13:02:17 RECV <- PRINT:              Одобрено
2026/10/20 13:02:17 RECV <- ENDTR
''';

    test('chekda karta raqami yo\'q — logdan olinadi, RRN chekdan', () {
      final r = TerminalReceiptParser.parseTerminalResult(
        receipt: 'UZCARD\nОплата\nRRN 032150038197\nОдобрено',
        log: log,
      );
      expect(r['cardNumber'], '860049******1234');
      expect(r['rrn'], '032150038197'); // chek ustun
      expect(r['cardType'], 'UZCARD');
    });

    test('chek bo\'sh (cheq.out yangilanmagan) — hammasi logdan', () {
      final r = TerminalReceiptParser.parseTerminalResult(receipt: '', log: log);
      expect(r['cardNumber'], '860049******1234');
      expect(r['rrn'], '629308797462');
    });

    test('chekda bor bo\'lsa logga qaralmaydi', () {
      final r = TerminalReceiptParser.parseTerminalResult(
        receipt: 'KARTA: 986017******4357\nRRN :608610728951\nHUMO',
        log: log,
      );
      expect(r['cardNumber'], '986017******4357');
      expect(r['rrn'], '608610728951');
    });

    test('log bo\'sh — faqat chek', () {
      final r = TerminalReceiptParser.parseTerminalResult(
          receipt: 'RRN :608610728951', log: '');
      expect(r['cardNumber'], isNull);
      expect(r['rrn'], '608610728951');
    });

    test('Arcus2 ishga tushmagan (ArcusResultReader matni) — karta raqami yo\'q',
        () {
      final r = TerminalReceiptParser.parseTerminalResult(
        receipt: '',
        log: 'Arcus2 bu operatsiya uchun log yozmadi (kod: 999).\n'
            'Arcus2 ishga tushmadi yoki sozlama (INI) topilmadi.\n'
            'Terminalga so\'rov yuborilmadi.\n'
            'Arcus2 не записал лог этой операции. НЕТ СВЯЗИ С ПИН-ПАДОМ',
      );
      expect(r['cardNumber'], isNull);
      expect(r['rrn'], isNull);
    });
  });
}
