// GS1 sana tahlili — test.
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
}
