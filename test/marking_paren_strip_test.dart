// Markirovka qavs tozalash regressiya testi (2026-07-30).
//
// MUAMMO (real POS): skaner GS1 markirovkani qavsli beradi —
//   (01)04780069000505(21)7%G'2dE6p)QWf(93)DrFn
// Eski regex `\(\d{2,3}\)` qavs bilan birga (01)/(21)/(93) RAQAMINI ham o'chirardi,
// natijada KM `04...` (GTIN) dan boshlanib buzuq saqlanardi (chekda 01 yo'q edi).
//
// FIX:
//   1) `replaceAllMapped(RegExp(r'\((\d{2,3})\)'), (m) => m.group(1)!)` — faqat qavs
//      olinadi, ichidagi AI raqami (01/21) SAQLANADI.
//   2) (93) va undan keyingi kripto ANIQ marker ((93) yoki <GS>93) bo'yicha kesiladi —
//      sotuv/soliq/OFD ga hech qayerga yuborilmaydi.
//   3) Eski bare `(?=93)` fallback OLIB TASHLANDI — u serial ichidagi tasodifiy "93"
//      substringda serialni kesib yuborardi (data buzilishi).
//
// Bu test to'lov vaqti chaqiriladigan HAQIQIY static funksiyani tekshiradi:
//   OrderingProvider4.cleanMarkForFiscal(...)
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';

const gtin = '04780069000505'; // barcode 4780069000505 -> GTIN-14
final gs = String.fromCharCode(0x1D); // GS1 <GS> ajratuvchi (0x1D)

String clean(String raw) => OrderingProvider4.cleanMarkForFiscal(raw);

void main() {
  group('cleanMarkForFiscal — qavs tozalash (01 saqlanadi)', () {
    test('bracketed kod -> KI (01+GTIN+21+serial), 01 dan boshlanadi', () {
      final out = clean("(01)04780069000505(21)7%G'2dE6p)QWf(93)DrFn");
      expect(out, "0104780069000505217%G'2dE6p)QWf");
      expect(out.startsWith('01$gtin'), isTrue);
      expect(out.startsWith('04'), isFalse); // eski buzuq forma EMAS
    });

    test('93 va keyingi kripto YO\'Q (hech qayerga ketmaydi)', () {
      final out = clean("(01)04780069000505(21)79FE%h_D0ha:p(93)Aqnn");
      expect(out.contains('(93)'), isFalse);
      expect(out.endsWith('Aqnn'), isFalse); // crypto tail kesilgan
      expect(out, "01${gtin}2179FE%h_D0ha:p");
    });

    test('serial ichida qavs "(" bo\'lsa buzilmaydi', () {
      final out = clean('(01)04780069000505(21)7r(DW>E&V59,L(93)gNEx');
      expect(out, '01${gtin}217r(DW>E&V59,L');
    });
  });

  group('cleanMarkForFiscal — GS ajratuvchili skaner', () {
    test('<GS>93 tail kesiladi', () {
      final out = clean('01${gtin}217y/6=JIDJmXk8${gs}93S5RB');
      expect(out, '01${gtin}217y/6=JIDJmXk8');
    });
  });

  group('cleanMarkForFiscal — serial ichidagi "93" (regressiya himoyasi)', () {
    // Eski (?=93) fallback bu holatlarda serialni kesib yuborardi.
    test('serial "7A93bcdefGHij" to\'liq saqlanadi', () {
      final out = clean('(01)04780069000505(21)7A93bcdefGHij(93)XXXX');
      expect(out, '01${gtin}217A93bcdefGHij');
    });

    test('serial "93QWERTYuiop1" (93 bilan boshlanadi) yo\'qolmaydi', () {
      final out = clean('(01)04780069000505(21)93QWERTYuiop1(93)ZZZZ');
      expect(out, '01${gtin}2193QWERTYuiop1');
      expect(out.length, greaterThan(18)); // serial mavjud, kesilmagan
    });

    test('serial "abc93def9312" o\'rtasida 93 bor', () {
      final out = clean('(01)04780069000505(21)abc93def9312(93)ZZZZ');
      expect(out, '01${gtin}21abc93def9312');
    });
  });

  group('cleanMarkForFiscal — idempotentlik va chetki holatlar', () {
    test('allaqachon toza KI qayta o\'tsa o\'zgarmaydi', () {
      const ki = '0104780069000505217y/6=JIDJmXk8';
      expect(clean(ki), ki);
      expect(clean(clean(ki)), ki); // ikki marta = bir marta
    });

    test('serial-93 li KI ikki marta o\'tsa ham buzilmaydi', () {
      const ki = '0104780069000505217A93bcdefGHij';
      expect(clean(ki), ki);
      expect(clean(clean(ki)), ki);
    });

    test('bo\'sh / probel', () {
      expect(clean(''), '');
      expect(clean('   '), '   ');
    });
  });

  // _markirovka PRIVAT metod — bu yerda aynan takrorlangan (skan vaqti dual-logikasi).
  // Agar lib/.../ordering_provider_4.dart :: _markirovka o'zgarsa, bu ham yangilansin.
  // Qoida: MARKER bor ((93)/<GS>93) -> aniq kesish (serial 93 saqlanadi);
  //        MARKER yo'q (yalang'och) -> eski logika (birinchi 93 gacha, serial 93 ham kesiladi).
  String markirovkaMirror(String rawMark) {
    if (rawMark.trim().isEmpty) return rawMark;
    final hasMarker = RegExp(r'\(93\)').hasMatch(rawMark) ||
        RegExp(r'[\x1D\x1C\x1E\x1F]93').hasMatch(rawMark);
    final clean = rawMark
        .replaceAll(RegExp(r'\(93\).*$'), '')
        .replaceAll(RegExp(r'[\x1D\x1C\x1E\x1F]93.*$'), '')
        .replaceAllMapped(RegExp(r'\((\d{2,3})\)'), (m) => m.group(1)!)
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '');
    if (!hasMarker) {
      final match = RegExp(r'(01\d{14}21.*?)(?=93)').firstMatch(clean);
      if (match != null) return match.group(1)!;
    }
    return clean;
  }

  group('_markirovka dual-logika — MARKER bor (serial 93 saqlanadi)', () {
    test('qavsli, serial ichida 93 -> saqlanadi', () {
      expect(markirovkaMirror('(01)04780069000505(21)7A93bcdefGH(93)XXXX'),
          '01${gtin}217A93bcdefGH');
    });
    test('qavsli, serial 93 bilan boshlanadi -> saqlanadi', () {
      expect(markirovkaMirror('(01)04780069000505(21)93QsVgXYZ12(93)ZZZZ'),
          '01${gtin}2193QsVgXYZ12');
    });
    test('GS ajratuvchili, serial ichida 93 -> saqlanadi', () {
      expect(markirovkaMirror('01${gtin}217A93bcdefGH${gs}93XXXX'),
          '01${gtin}217A93bcdefGH');
    });
  });

  group('_markirovka dual-logika — MARKER yo\'q (eski logika, birinchi 93 gacha)', () {
    test('yalang\'och normal -> 93 va keyin kesiladi', () {
      expect(markirovkaMirror('01${gtin}2179BON&OS;9TL,93QsVg'),
          '01${gtin}2179BON&OS;9TL,');
    });
    test('yalang\'och, serial ichida 93 -> ESKICHA kesiladi (talab)', () {
      expect(markirovkaMirror('01${gtin}217A93bcdefGH93XXXX'), '01${gtin}217A');
    });
    test('yalang\'och, serial 93 bilan boshlanadi -> ESKICHA kesiladi', () {
      expect(markirovkaMirror('01${gtin}2193QsVgXYZ1293ZZZZ'), '01${gtin}21');
    });
  });

  group('marking_names — to\'liq oqim (join/split invariantlari)', () {
    final scanned = <String>[
      "(01)04780069000505(21)7%G'2dE6p)QWf(93)DrFn",
      '(01)04780069000505(21)79FE%h_D0ha:p(93)Aqnn',
      '(01)04780069000505(21)79BON&OS;9TL,(93)QsVg',
      '(01)04780069000505(21)7rniS8S-pF8aR(93)+5YG',
      '(01)04780069000505(21)7S_X85J,+NHB6(93)/wAP',
    ];

    test('HAR BIR marking_name 01+GTIN dan boshlanadi, 93 yo\'q, unikal', () {
      // Har item.mark alohida tozalanadi, keyin \n bilan birlashadi (receipt_singleton),
      // keyin toJson da split bo'ladi (marking_names).
      final cleanedMarks = scanned.map(clean).toList();
      final joined = cleanedMarks.join('\n');
      final markingNames =
          joined.split('\n').where((m) => m.isNotEmpty).toList();

      expect(markingNames.length, scanned.length);
      expect(markingNames.every((m) => m.startsWith('01$gtin')), isTrue);
      expect(markingNames.any((m) => m.startsWith('04')), isFalse);
      expect(markingNames.any((m) => m.contains('(93)')), isFalse);
      expect(markingNames.toSet().length, markingNames.length); // takror yo'q
    });
  });
}
