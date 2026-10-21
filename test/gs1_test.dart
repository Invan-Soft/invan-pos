// GS1 sana tahlili va GTIN tengligi — test.
//
// Faza 1 da OrderingProvider4 dan `Gs1` ga ko'chirildi. Ilgari `private`
// (`_parseGS1Date`) bo'lgani uchun testlab bo'lmasdi.
//
// Sof funksiya — Hive yoki POS muhiti kerak emas.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/marking/gs1.dart';

void main() {
  group('Gs1.parseDate — YYMMDD', () {
    test('oddiy sana: 260805 -> 2026-08-05', () {
      expect(Gs1.parseDate('260805'), DateTime(2026, 8, 5));
    });

    test('YY <= 49 -> 2000-yillar', () {
      expect(Gs1.parseDate('490101'), DateTime(2049, 1, 1));
    });

    test('YY > 49 -> 1900-yillar', () {
      expect(Gs1.parseDate('500101'), DateTime(1950, 1, 1));
    });

    test('YY = 00 -> 2000', () {
      expect(Gs1.parseDate('001231'), DateTime(2000, 12, 31));
    });
  });

  group('DD = 00 -> oyning oxirgi kuni', () {
    test('fevral, kabisa bo\'lmagan yil: 260200 -> 2026-02-28', () {
      expect(Gs1.parseDate('260200'), DateTime(2026, 2, 28));
    });

    test('fevral, kabisa yili: 240200 -> 2024-02-29', () {
      expect(Gs1.parseDate('240200'), DateTime(2024, 2, 29));
    });

    test('31 kunli oy: 260100 -> 2026-01-31', () {
      expect(Gs1.parseDate('260100'), DateTime(2026, 1, 31));
    });

    test('30 kunli oy: 260400 -> 2026-04-30', () {
      expect(Gs1.parseDate('260400'), DateTime(2026, 4, 30));
    });

    test('dekabr: 261200 -> 2026-12-31', () {
      expect(Gs1.parseDate('261200'), DateTime(2026, 12, 31));
    });
  });

  group('Buzuq kirish', () {
    test('juda qisqa -> null', () {
      expect(Gs1.parseDate('2608'), isNull);
    });

    test('bo\'sh -> null', () {
      expect(Gs1.parseDate(''), isNull);
    });

    test('harflar -> null', () {
      expect(Gs1.parseDate('abcdef'), isNull);
    });

    test('6 belgidan uzun bo\'lsa birinchi 6 tasi olinadi', () {
      expect(Gs1.parseDate('260805123'), DateTime(2026, 8, 5));
    });
  });

  // 2026-10-21: KM ichidagi GTIN-14 `00049000033939` (Fanta 355ml) katalogdagi
  // UPC-12 / EAN-13 yozuvlariga mos kelmasdi.
  group('Gs1.isSameGtin — GS1 GTIN tengligi (chapdan nol bilan 14 xonagacha)',
      () {
    // KM dan: 00049000033939 → boshidagi nollarsiz kalit
    const key = '49000033939';

    for (final b in [
      '49000033939', // nollari tushib qolgan (11)
      '049000033939', // UPC-12
      '0049000033939', // EAN-13
      '00049000033939', // GTIN-14
    ]) {
      test('$b ↔ $key — bitta tovar', () {
        expect(Gs1.isSameGtin(b, key), isTrue);
      });
    }

    test('GTIN-8 (8 xona) ham qatnashadi', () {
      expect(Gs1.isSameGtin('40170725', '40170725'), isTrue);
      expect(Gs1.isSameGtin('01234565', '1234565'), isTrue);
    });

    test('8 xonadan qisqa kod qatnashmaydi (SKU / ichki kod)', () {
      expect(Gs1.isSameGtin('0012345', '12345'), isFalse);
      expect(Gs1.isSameGtin('206', '206'), isFalse);
    });

    test('14 xonadan uzun kod qatnashmaydi (GTIN emas)', () {
      expect(Gs1.isSameGtin('000049000033939', key), isFalse);
    });

    test('harf/belgi aralash kod normalizatsiya qilinmaydi', () {
      expect(Gs1.isSameGtin('0A49000033939', key), isFalse);
      expect(Gs1.isSameGtin('O49000033939', key), isFalse, reason: 'lotin O');
      expect(Gs1.isSameGtin(' 049000033939', key), isFalse);
      expect(Gs1.isSameGtin('049000033939 ', key), isFalse);
    });

    test('fragment moslik yo\'q: faqat BOSHIDAGI nollar ahamiyatsiz', () {
      expect(Gs1.isSameGtin('149000033939', key), isFalse,
          reason: 'boshida noldan boshqa raqam — boshqa GTIN');
      expect(Gs1.isSameGtin('4900003393', key), isFalse,
          reason: 'oxirgi raqam yetishmaydi');
      expect(Gs1.isSameGtin('490000339390', key), isFalse,
          reason: 'oxirida ortiqcha raqam');
      expect(Gs1.isSameGtin('049000033946', key), isFalse,
          reason: 'bitta raqam farq — boshqa tovar');
    });

    test('indikator raqami (GTIN-14 boshidagi 1..9) — boshqa tovar', () {
      // 14780000000001 (karton) ≠ 4780000000001 (dona)
      expect(Gs1.isSameGtin('4780000000001', '14780000000001'), isFalse);
      expect(Gs1.isSameGtin('14780000000001', '14780000000001'), isTrue);
    });

    test('bo\'sh kalit (hammasi nol GTIN) hech narsaga mos emas', () {
      expect(Gs1.isSameGtin('00000000', ''), isFalse);
      expect(Gs1.isSameGtin('049000033939', ''), isFalse);
    });

    test('kalit nollarsiz bo\'lishi shart (shartnoma)', () {
      expect(Gs1.isSameGtin('049000033939', '049000033939'), isFalse,
          reason: 'chaqiruvchi kalitni boshidagi nollarsiz beradi');
    });
  });

  // 2026-10-21: ba'zi skanerlar KM boshiga `-` qo'yadi (`-0100049…`) —
  // kod `01` bilan boshlanmagani uchun mahsulot topilmasdi.
  group('Gs1.stripScannerPrefix — skaner prefiksi', () {
    const gs = '\x1D';
    const km = '0100049000033939217MG7fVVkzf5Y?';

    test('boshidagi `-` olinadi, haqiqiy GS saqlanadi', () {
      expect(Gs1.stripScannerPrefix('-$km${gs}93abcd'), '$km${gs}93abcd');
    });

    test('bir nechta `-` ham olinadi', () {
      expect(Gs1.stripScannerPrefix('--$km${gs}93abcd'), '$km${gs}93abcd');
    });

    test('`-` rejimi: GS o\'rnidagi `-93` → GS93', () {
      expect(Gs1.stripScannerPrefix('-$km-93abcd'), '$km${gs}93abcd');
    });

    test('`-` rejimi, tamaki: `-8005` va `-93` → GS', () {
      expect(
          Gs1.stripScannerPrefix('-0104780069000505218AbCdEf-8005012345-93ab'),
          '0104780069000505218AbCdEf${gs}8005012345${gs}93ab');
    });

    test('`-` rejimi: seriyadagi boshqa `-` o\'zgarmaydi', () {
      expect(Gs1.stripScannerPrefix('-01000490000339392112-AB-CD-93ab'),
          '01000490000339392112-AB-CD${gs}93ab');
    });

    test('haqiqiy GS bo\'lsa ichki `-` ga tegilmaydi', () {
      expect(Gs1.stripScannerPrefix('-01000490000339392112-93XY${gs}93ab'),
          '01000490000339392112-93XY${gs}93ab');
    });

    test('qavsli (01) shakli: faqat `-` olinadi', () {
      expect(Gs1.stripScannerPrefix('-(01)00049000033939(21)AB-93(93)xy'),
          '(01)00049000033939(21)AB-93(93)xy');
    });

    test('AIM identifikatori ]d2 / ]C1 / ]Q3 olinadi', () {
      for (final aim in [']d2', ']C1', ']Q3']) {
        expect(Gs1.stripScannerPrefix('$aim$km${gs}93abcd'), '$km${gs}93abcd');
      }
    });

    test('GS1 01+GTIN14 bo\'lmasa hech narsa o\'zgarmaydi', () {
      for (final c in [
        '-123',
        '-4780069000505',
        '-010004900003393', // 01 + 13 raqam — GTIN14 emas
        '-02000490000339392112', // 02 — bu yerda qamralmagan
        ']d24780069000505',
        '4780069000505',
        '0100049000033939217MG7fVVkzf5Y?-93ab', // `-` boshida emas
        '',
      ]) {
        expect(Gs1.stripScannerPrefix(c), c, reason: c);
      }
    });

    test('ikki marta chaqirilsa natija bir xil (idempotent)', () {
      for (final c in ['-$km-93abcd', '-$km${gs}93abcd', ']d2$km${gs}93ab']) {
        final once = Gs1.stripScannerPrefix(c);
        expect(Gs1.stripScannerPrefix(once), once, reason: c);
      }
    });
  });
}
