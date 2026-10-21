// Skan vaqtidagi markirovka tozalash (`MarkCleaner.scanTime`) — test.
//
// Faza 1 da OrderingProvider4 dan ko'chirildi. Ilgari `private`
// (`_markirovka`) bo'lgani uchun testlab bo'lmasdi — faqat to'lov vaqtidagi
// juftligi (`cleanMarkForFiscal`) qoplangan edi
// (test/marking_paren_strip_test.dart).
//
// scanTime va forFiscal ATAYLAB har xil:
//   * scanTime  — Unicode tozalash + markersiz kod uchun fallback bor
//   * forFiscal — fallback YO'Q (u serialni buzardi)
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/marking/mark_cleaner.dart';

const gtin = '04780069000505';
final gs = String.fromCharCode(0x1D);

void main() {
  group('Qavsli (bracketed) skaner kodi', () {
    test('(01)/(21) raqami SAQLANADI, qavs olinadi', () {
      final out = MarkCleaner.scanTime('(01)$gtin(21)ABC123(93)XXXX');

      expect(out, '01${gtin}21ABC123');
      expect(out.startsWith('01'), isTrue);
      expect(out.startsWith('04'), isFalse); // eski buzuq forma EMAS
    });

    test('(93) va undan keyingi kripto kesiladi', () {
      final out = MarkCleaner.scanTime('(01)$gtin(21)SERIAL(93)SECRET');

      expect(out.contains('SECRET'), isFalse);
      expect(out.contains('93'), isFalse);
    });

    test('serial ichidagi qavs buzilmaydi', () {
      final out = MarkCleaner.scanTime('(01)$gtin(21)7r(DW>E(93)gNEx');

      expect(out, '01${gtin}217r(DW>E');
    });
  });

  group('GS ajratuvchili skaner kodi', () {
    test('<GS>93 tail kesiladi', () {
      final out = MarkCleaner.scanTime('01${gtin}21SERIAL${gs}93SECRET');

      expect(out, '01${gtin}21SERIAL');
    });

    test('boshqa boshqaruv belgilari o\'chiriladi', () {
      final out = MarkCleaner.scanTime('01${gtin}21AB\x1DCD');

      expect(out.contains('\x1D'), isFalse);
    });
  });

  group('Markersiz (yalang\'och) kod — fallback ishlaydi', () {
    test('01+GTIN+21 dan keyingi birinchi 93 gacha olinadi', () {
      // Marker yo'q: (93) ham, <GS>93 ham yo'q
      final out = MarkCleaner.scanTime('01${gtin}21SERIAL93SECRET');

      expect(out, '01${gtin}21SERIAL');
    });

    test('bu forFiscal dan FARQ qiladi — u kesmaydi', () {
      const raw = '010478006900050521SERIAL93SECRET';

      expect(MarkCleaner.scanTime(raw), isNot(MarkCleaner.forFiscal(raw)));
    });
  });

  group('Unicode tozalash (faqat scanTime da)', () {
    test('replacement belgilari o\'chiriladi', () {
      final out = MarkCleaner.scanTime('01${gtin}21AB￼CD�');

      expect(out.contains('￼'), isFalse);
      expect(out.contains('�'), isFalse);
    });

    test('C1 diapazoni (0x80-0x9F) o\'chiriladi', () {
      final out = MarkCleaner.scanTime('01${gtin}21ABCD');

      expect(out.contains(''), isFalse);
    });
  });

  group('Chetki holatlar', () {
    test('bo\'sh satr o\'zgarmaydi', () {
      expect(MarkCleaner.scanTime(''), '');
    });

    test('faqat probel o\'zgarmaydi', () {
      expect(MarkCleaner.scanTime('   '), '   ');
    });

    test('idempotent: ikkinchi tozalash natijani o\'zgartirmaydi', () {
      final once = MarkCleaner.scanTime('(01)$gtin(21)ABC(93)XX');
      final twice = MarkCleaner.scanTime(once);

      expect(twice, once);
    });
  });

  // 2026-10-21: skaner KM boshiga `-` qo'yadi — dialogga kiritilgan KM ham
  // scanTime dan o'tadi, soliqqa `-` siz ketishi kerak.
  group('Skaner prefiksi (`-` = FNC1, AIM ]d2)', () {
    const km = '0100049000033939217MG7fVVkzf5Y?';

    test('`-` + haqiqiy GS93 → toza KM', () {
      expect(MarkCleaner.scanTime('-$km${gs}93abcd'), km);
    });

    test('`-` rejimi: `-93` ajratuvchi → toza KM (oxirida `-` yo\'q)', () {
      expect(MarkCleaner.scanTime('-$km-93abcd'), km);
    });

    test('`-` rejimi, tamaki: narx (8005) saqlanadi, `-` lar yo\'q', () {
      expect(MarkCleaner.scanTime('-0104780069000505218AbCdEf-8005012345-93ab'),
          '0104780069000505218AbCdEf8005012345');
    });

    test(']d2 + KM → toza KM', () {
      expect(MarkCleaner.scanTime(']d2$km${gs}93abcd'), km);
    });

    test('prefikssiz KM natijasi o\'zgarmagan', () {
      expect(MarkCleaner.scanTime('$km${gs}93abcd'), km);
    });
  });
}
