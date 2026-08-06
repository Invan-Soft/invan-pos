// Skaner kodini tasniflash (`BarcodeClassifier`) — test.
//
// Faza 7 da `onBarcodeScanned` dan ajratildi. Ilgari bu mantiq 273 qatorlik
// metod ichida, dialoglar bilan aralashib yotgan edi — testlab bo'lmasdi.
//
// TEKSHIRUVLAR TARTIBI MUHIM: masalan bo'sh joy tekshiruvi raqam
// tekshiruvidan oldin keladi. Quyidagi testlar tartibni ham qulflaydi.
//
// Sof funksiyalar — POS muhiti (Hive) kerak emas.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/barcode/barcode_classifier.dart';

ScannedCodeKind kindOf(String code, {int weight = 28, int piece = 21}) =>
    BarcodeClassifier.classify(
      code,
      taroziPrefix: weight,
      taroziPiecePrefix: piece,
    );

void main() {
  group('sanitize — skaner axlatini tozalash', () {
    test('private-use belgilar olib tashlanadi (U+F701)', () {
      final raw = '4780000000000${String.fromCharCode(0xF701)}';

      expect(BarcodeClassifier.sanitize(raw), '4780000000000');
    });

    test('atrofdagi probellar kesiladi', () {
      expect(BarcodeClassifier.sanitize('  12345  '), '12345');
    });

    test('oddiy kod o\'zgarmaydi', () {
      expect(BarcodeClassifier.sanitize('4780069000505'), '4780069000505');
    });

    test('faqat axlatdan iborat kod bo\'sh qoladi', () {
      expect(BarcodeClassifier.sanitize(String.fromCharCode(0xF701)), '');
    });
  });

  group('Mahsulot kodi', () {
    test('oddiy EAN-13', () {
      expect(kindOf('4780069000505'), ScannedCodeKind.product);
    });

    test('SKU (qisqa raqam)', () {
      expect(kindOf('10977'), ScannedCodeKind.product);
    });

    test('markirovka (01+GTIN+21+serial)', () {
      expect(kindOf('010478006900050521ABC123'), ScannedCodeKind.product);
    });
  });

  group('Rad etiladigan kodlar', () {
    test('bo\'sh', () {
      expect(kindOf(''), ScannedCodeKind.empty);
    });

    for (final url in [
      'http://example.com',
      'https://example.com',
      'ftp://files',
      'www.example.com',
      'tel:998901234567',
      'mailto:a@b.uz',
      'scheme://host',
    ]) {
      test('URL rad etiladi: $url', () {
        expect(kindOf(url), ScannedCodeKind.url);
      });
    }

    test('katta harfli URL ham rad etiladi', () {
      expect(kindOf('HTTP://EXAMPLE.COM'), ScannedCodeKind.url);
    });

    test('UUID (PayNet OTP) jim o\'tkaziladi', () {
      expect(
        kindOf('550e8400-e29b-41d4-a716-446655440000'),
        ScannedCodeKind.uuid,
      );
    });

    test('erkin matn (bo\'sh joy bor)', () {
      expect(kindOf('Toshkent shahar 5'), ScannedCodeKind.freeText);
    });

    test('yangi qator ham erkin matn hisoblanadi', () {
      expect(kindOf('abc\n123'), ScannedCodeKind.freeText);
    });

    test('faqat harflar — raqamsiz', () {
      expect(kindOf('ABCDEF'), ScannedCodeKind.noDigits);
    });
  });

  group('Utsenka QR (JSON)', () {
    test('{ bilan boshlanadi', () {
      expect(kindOf('{"id":"x","price":1000}'), ScannedCodeKind.utsenkaQr);
    });

    test('oldida probel bo\'lsa ham aniqlanadi', () {
      // sanitize dan keyin trim bo'ladi, lekin ichki probel bo'lsa ham
      // `{` tekshiruvi bo'sh joy tekshiruvidan OLDIN keladi
      expect(kindOf('{"a": 1}'), ScannedCodeKind.utsenkaQr);
    });
  });

  group('Tarozi yorliqlari', () {
    test('kilo prefiksi 28 + 13 uzunlik', () {
      expect(kindOf('2812345001234'), ScannedCodeKind.weightItem);
    });

    test('dona prefiksi 21 + 13 uzunlik', () {
      expect(kindOf('2112345001234'), ScannedCodeKind.pieceItem);
    });

    test('prefiks to\'g\'ri, lekin uzunlik 13 emas -> oddiy mahsulot', () {
      expect(kindOf('28123'), ScannedCodeKind.product);
      expect(kindOf('28123450012345'), ScannedCodeKind.product);
    });

    test('sozlamadagi prefiks o\'zgarsa unga ergashadi', () {
      expect(
        kindOf('2212345001234', weight: 22),
        ScannedCodeKind.weightItem,
      );
      // eski prefiks endi oddiy mahsulot
      expect(kindOf('2812345001234', weight: 22), ScannedCodeKind.product);
    });
  });

  group('Tekshiruvlar tartibi (regressiya himoyasi)', () {
    test('URL raqam tutsa ham URL bo\'lib qoladi', () {
      expect(kindOf('http://a.uz/123'), ScannedCodeKind.url);
    });

    test('bo\'sh joyli matn raqam tutsa ham freeText', () {
      // Aks holda matndan raqam ajratib olib noto'g'ri mahsulot topilardi
      expect(kindOf('kv 12'), ScannedCodeKind.freeText);
    });

    test('UUID da raqam va harf bor, lekin uuid ustun', () {
      expect(
        kindOf('550e8400-e29b-41d4-a716-446655440000'),
        ScannedCodeKind.uuid,
      );
    });

    test('13 uzunlikdagi tarozi kodi freeText dan keyin tekshiriladi', () {
      // Probelli 13 belgi -> tarozi emas, freeText
      expect(kindOf('28 234500123'), ScannedCodeKind.freeText);
    });
  });

  group('GS1 yaroqlilik muddati', () {
    test('qavsli AI 17', () {
      expect(
        BarcodeClassifier.parseExpiry('0104780069000505(17)261231'),
        DateTime(2026, 12, 31),
      );
    });

    test('qavsli AI 15 (17 yo\'q bo\'lsa)', () {
      expect(
        BarcodeClassifier.parseExpiry('0104780069000505(15)270115'),
        DateTime(2027, 1, 15),
      );
    });

    test('AI 17 AI 15 dan ustun', () {
      final d = BarcodeClassifier.parseExpiry(
          '0104780069000505(17)261231(15)270115');

      expect(d, DateTime(2026, 12, 31));
    });

    test('qavsiz: 01+GTIN(14) dan keyin 17YYMMDD', () {
      // 01 + 14 raqam = 16 belgi, keyin 17261231
      expect(
        BarcodeClassifier.parseExpiry('010478006900050517261231'),
        DateTime(2026, 12, 31),
      );
    });

    test('qavsiz: 17 yo\'q bo\'lsa 15YYMMDD', () {
      expect(
        BarcodeClassifier.parseExpiry('010478006900050515270115'),
        DateTime(2027, 1, 15),
      );
    });

    test('muddat yo\'q -> null', () {
      expect(BarcodeClassifier.parseExpiry('4780069000505'), isNull);
    });

    // ⚠️ QAYD ETILGAN XATTI-HARAKAT (tuzatilmadi)
    // Gs1.parseDate oy/kun chegarasini TEKSHIRMAYDI. `999999` -> yy=99,
    // mm=99, dd=99 va Dart'ning DateTime(1999, 99, 99) oshib ketishni
    // normallashtiradi -> 2007-06-07. Ya'ni null emas, "juda eski sana"
    // qaytadi va mahsulot "muddati o'tgan" deb belgilanadi.
    // Amalda bu xavfsiz tomonga xato (buzuq kod qabul qilinmaydi), lekin
    // sabab tasodifiy — alohida ko'rib chiqilishi kerak.
    test('QAYD: chegaradan oshgan sana null emas, normallashadi', () {
      final d = BarcodeClassifier.parseExpiry('0104780069000505(17)999999');

      expect(d, isNotNull);
      expect(d!.year, lessThan(2020)); // juda eski -> "muddati o'tgan"
    });

    test('raqam bo\'lmagan sana -> null', () {
      expect(BarcodeClassifier.parseExpiry('0104780069000505(17)abcdef'),
          isNull);
    });
  });

  group('isExpired', () {
    test('kecha -> muddati o\'tgan', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      expect(BarcodeClassifier.isExpired(yesterday), isTrue);
    });

    test('bugun -> o\'tmagan', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      expect(BarcodeClassifier.isExpired(today), isFalse);
    });

    test('ertaga -> o\'tmagan', () {
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      expect(BarcodeClassifier.isExpired(tomorrow), isFalse);
    });
  });
}
