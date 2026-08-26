// Markirovka kodini (KM) mahalliy tekshirish — `MarkValidator`.
//
// Bu uch qoida sotuvni TO'XTATADI, shuning uchun har shoxi alohida
// muzlatiladi: format, mahsulot mosligi, muddat.
//
// Kod ilgari `_markingCheck` (258 qator, 12 dialog, ONKM so'rovi,
// BuildContext) ichida edi — umuman testlab bo'lmasdi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/marking/mark_validator.dart';
import 'package:invan2/changes/models/product/item_model.dart';

ItemModel product({List<String> barcodes = const ['04780000000017']}) {
  final m = ItemModel();
  m.id = 'suv-id';
  m.name = 'Suv';
  m.barcode = barcodes;
  return m;
}

/// Haqiqiy KM ga yaqin: (01)GTIN14 + (21)seriya.
const kValidMark = '(01)04780000000017(21)ABC123';

MarkValidation check(String mark, {ItemModel? p, DateTime? now}) =>
    MarkValidator.validate(mark, p ?? product(), now: now);

void main() {
  group('sanitize — boshqaruv belgilarini tozalash', () {
    test('GS (0x1D) olib tashlanadi', () {
      expect(MarkValidator.sanitize('0104780000000017\x1D21ABC'),
          '010478000000001721ABC');
    });

    test('FS/RS/US va boshqa ko\'rinmas kodlar ham', () {
      expect(MarkValidator.sanitize('AB\x1CC\x1ED\x1FE'), 'ABCDE');
    });

    test('almashtirish belgilari (￼, �) olib tashlanadi', () {
      expect(MarkValidator.sanitize('AB￼C�D'), 'ABCD');
    });

    test('(17)/(15) qavslari SAQLANADI', () {
      expect(MarkValidator.sanitize('(01)123(17)991231'),
          '(01)123(17)991231');
    });

    test('oddiy matn o\'zgarmaydi', () {
      expect(MarkValidator.sanitize('ABC123'), 'ABC123');
    });
  });

  group('extractGtin — GTIN ajratish', () {
    test('qavsli (01) dan', () {
      expect(MarkValidator.extractGtin('(01)04780000000017'),
          '4780000000017');
    });

    test('qavssiz 01 dan', () {
      expect(MarkValidator.extractGtin('010478000000001721ABC'),
          '4780000000017');
    });

    test('02 (yaqin qadoq) dan ham', () {
      expect(MarkValidator.extractGtin('0204780000000017'), '4780000000017');
    });

    test('AI yo\'q bo\'lsa har qanday 12-14 xonali raqamdan', () {
      expect(MarkValidator.extractGtin('XYZ478000000001Z'), '478000000001');
    });

    test('boshidagi nollar olib tashlanadi', () {
      expect(MarkValidator.extractGtin('(01)00004780000017')!.startsWith('0'),
          isFalse);
    });

    test('raqam yetarli emas → null', () {
      expect(MarkValidator.extractGtin('ABC12345'), isNull);
    });

    test('bo\'sh matn → null', () {
      expect(MarkValidator.extractGtin(''), isNull);
    });
  });

  group('FORMAT xatosi', () {
    test('http:// bilan boshlansa', () {
      expect(check('http://t.me/x').issue, MarkIssue.invalidFormat);
    });

    test('https:// bilan boshlansa', () {
      expect(check('https://tasnif.uz/1').issue, MarkIssue.invalidFormat);
    });

    test('GTIN topilmasa', () {
      expect(check('salom dunyo').issue, MarkIssue.invalidFormat);
    });

    test('bo\'sh KM', () {
      expect(check('').issue, MarkIssue.invalidFormat);
    });

    test('faqat boshqaruv belgilaridan iborat KM', () {
      expect(check('\x1D\x1C').issue, MarkIssue.invalidFormat);
    });
  });

  group('MAHSULOT mosligi', () {
    test('GTIN mahsulot shtrix-kodiga mos → o\'tadi', () {
      expect(check(kValidMark).issue, MarkIssue.none);
    });

    test('boshqa mahsulotning KM i → wrongProduct', () {
      expect(check('(01)09999999999990(21)A').issue, MarkIssue.wrongProduct);
    });

    test('mahsulot shtrix-kodi nol bilan, KM nolsiz — baribir mos', () {
      final p = product(barcodes: ['0004780000000017']);
      expect(check(kValidMark, p: p).issue, MarkIssue.none);
    });

    test('mahsulotda bir nechta shtrix-kod: biri mos bo\'lsa yetarli', () {
      final p = product(barcodes: ['1111111111111', '04780000000017']);
      expect(check(kValidMark, p: p).issue, MarkIssue.none);
    });

    test('mahsulotda shtrix-kod yo\'q → wrongProduct', () {
      expect(check(kValidMark, p: product(barcodes: [])).issue,
          MarkIssue.wrongProduct);
    });

    test('natijada ajratilgan GTIN qaytariladi', () {
      expect(check(kValidMark).gtin, '4780000000017');
    });
  });

  group('MUDDAT tekshiruvi', () {
    final bugun = DateTime(2026, 8, 26);

    test('qavsli (17): o\'tgan sana → expired', () {
      expect(check('(01)04780000000017(17)260101', now: bugun).issue,
          MarkIssue.expired);
    });

    test('qavsli (17): kelasi sana → o\'tadi', () {
      expect(check('(01)04780000000017(17)301231', now: bugun).issue,
          MarkIssue.none);
    });

    test('CHEGARA: aynan bugun → o\'tadi (isBefore qat\'iy)', () {
      expect(check('(01)04780000000017(17)260826', now: bugun).issue,
          MarkIssue.none);
    });

    test('CHEGARA: kecha → expired', () {
      expect(check('(01)04780000000017(17)260825', now: bugun).issue,
          MarkIssue.expired);
    });

    test('qavssiz "01"+GTIN14 dan keyingi 17', () {
      // 01 + 14 raqam = 16 belgi, keyin AI 17 + YYMMDD (6 xona)
      expect(check('010478000000001717260101', now: bugun).issue,
          MarkIssue.expired);
    });

    test('qavssiz 15 (ishlab chiqarish/muddat) ham o\'qiladi', () {
      expect(check('010478000000001715260101', now: bugun).issue,
          MarkIssue.expired);
    });

    test('qavsli (15) oxirgi variant sifatida', () {
      expect(check('(01)04780000000017(15)260101', now: bugun).issue,
          MarkIssue.expired);
    });

    test('muddat yo\'q KM → o\'tadi', () {
      expect(check(kValidMark, now: bugun).issue, MarkIssue.none);
    });

    test('o\'qilgan sana natijada qaytariladi', () {
      expect(check('(01)04780000000017(17)301231', now: bugun).expiry,
          DateTime(2030, 12, 31));
    });
  });

  group('Tekshiruvlar TARTIBI (birinchi muammo qaytadi)', () {
    test('URL — GTIN mos kelsa ham format xatosi', () {
      expect(check('https://x/(01)04780000000017').issue,
          MarkIssue.invalidFormat);
    });

    test('boshqa mahsulot — muddati o\'tgan bo\'lsa ham wrongProduct', () {
      expect(check('(01)09999999999990(17)200101').issue,
          MarkIssue.wrongProduct);
    });
  });

  group('Tozalangan KM natijada qaytariladi', () {
    test('savatga boshqaruv belgilarisiz yoziladi', () {
      final r = check('(01)04780000000017\x1D(21)ABC');
      expect(r.mark, '(01)04780000000017(21)ABC');
      expect(r.isOk, isTrue);
    });
  });
}
