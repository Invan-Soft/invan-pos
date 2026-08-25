// `ScannedProductLookup` — skan qilingan koddan mahsulot topish.
//
// Bu kod Faza 9.4 gacha `onBarcodeScanned` ichida edi va uni UMUMAN
// testlab bo'lmasdi: metod `GlobalKey<ScaffoldState>` oladi va yo'l-yo'lakay
// dialoglar ochadi. Ajratishning bevosita foydasi shu.
//
// Kod tasnifi (URL / tarozi / utsenka / UUID) `BarcodeClassifier` da va
// `barcode_classifier_test` bilan qoplangan — bu yerda faqat QIDIRUV.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/barcode/scanned_product_lookup.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

/// Katalog mahsuloti. [barcodes] — oddiy shtrix-kodlar,
/// [boxBarcode] — blok (yaqin qadoq) kodi.
ItemModel product({
  required String id,
  List<String> barcodes = const [],
  String? sku,
  String? boxBarcode,
}) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.sku = sku;
  m.barcode = barcodes;
  if (boxBarcode != null) {
    m.hasBoxBarcode = true;
    m.boxBarcode = boxBarcode;
  }
  return m;
}

void seed(List<ItemModel> items) {
  ItemsSingleton.products = items;
  ItemsSingleton.barcodeProducts = items;
}

/// Testlarda markirovka qoidalari sodda: hamma narsa markirovkali / emas.
ScannedProductMatch lookup(String barcode,
        {bool markable = false, String cleaned = 'TOZALANGAN'}) =>
    ScannedProductLookup.find(
      barcode,
      isMarkable: (_) => markable,
      cleanMark: (_) => cleaned,
    );

void main() {
  setUp(() => seed([]));

  group('findBoxProduct — blok shtrix-kodi (GS1 "01" + GTIN14)', () {
    test('"01" bilan boshlanmasa null', () {
      seed([product(id: 'p', boxBarcode: '4780000000001')]);
      expect(ScannedProductLookup.findBoxProduct('4780000000001'), isNull);
    });

    test('juda qisqa kod (<= 16) null', () {
      expect(ScannedProductLookup.findBoxProduct('0112345678901234'.substring(0, 16)),
          isNull);
    });

    test('EAN13 varianti topiladi (GTIN14 dan birinchi raqam tashlanadi)', () {
      seed([product(id: 'blok', boxBarcode: '4780000000001')]);
      // GTIN14 = 0 + EAN13
      expect(ScannedProductLookup.findBoxProduct('0104780000000001x')?.id,
          'blok');
    });

    test('boshidagi nolsiz GTIN14 varianti topiladi', () {
      // GTIN14 = 00478000000001
      //   ean13          = 0478000000001  (birinchi belgi tashlanadi)
      //   nolsiz variant = 478000000001   (boshidagi nollar tashlanadi)
      // Katalogda faqat IKKINCHI variant bor — demak u ishlaydi.
      seed([product(id: 'blok', boxBarcode: '478000000001')]);
      expect(
          ScannedProductLookup.findBoxProduct('0100478000000001X')?.id, 'blok');
    });

    test('ean13 varianti nolsiz variantdan USTUN (birinchi sinaladi)', () {
      seed([
        product(id: 'nolsiz', boxBarcode: '478000000001'),
        product(id: 'ean13', boxBarcode: '0478000000001'),
      ]);
      expect(ScannedProductLookup.findBoxProduct('0100478000000001X')?.id,
          'ean13');
    });

    test('to\'liq GTIN14 varianti topiladi', () {
      seed([product(id: 'blok', boxBarcode: '14780000000001')]);
      expect(ScannedProductLookup.findBoxProduct('0114780000000001x')?.id,
          'blok');
    });

    test('katalogda blok kodi yo\'q bo\'lsa null', () {
      seed([product(id: 'p', barcodes: ['4780000000001'])]);
      expect(ScannedProductLookup.findBoxProduct('0104780000000001x'), isNull,
          reason: 'oddiy barcode blok qidiruviga tushmaydi');
    });

    test('GTIN14 raqam bo\'lmasa null', () {
      expect(ScannedProductLookup.findBoxProduct('01ABCDEFGHIJKLMNOP'), isNull);
    });
  });

  group('find — GS1 qavsli format "(01)"', () {
    test('(01) ichidan GTIN ajratiladi va boshidagi nol tashlanadi', () {
      seed([product(id: 'suv', barcodes: ['4780000000001'])]);
      final m = lookup('(01)04780000000001(17)991231');
      expect(m.item?.id, 'suv');
      expect(m.triedPatterns, contains('4780000000001'));
    });

    test('13 raqamli GTIN ham qabul qilinadi', () {
      seed([product(id: 'suv', barcodes: ['4780000000001'])]);
      expect(lookup('(01)4780000000001').item?.id, 'suv');
    });

    test('markirovkali mahsulotga tozalangan KM biriktiriladi', () {
      seed([product(id: 'suv', barcodes: ['4780000000001'])]);
      final m = lookup('(01)04780000000001(21)ABC', markable: true);
      expect(m.item?.mark, 'TOZALANGAN');
    });

    test('markirovkasiz mahsulotda mark null bo\'ladi', () {
      seed([product(id: 'suv', barcodes: ['4780000000001'])]);
      final m = lookup('(01)04780000000001(21)ABC', markable: false);
      expect(m.item?.mark, isNull);
    });
  });

  group('find — GS1 qavssiz format "01" + GTIN14', () {
    test('GTIN ajratiladi va mahsulot topiladi', () {
      seed([product(id: 'suv', barcodes: ['4780000000001'])]);
      final m = lookup('010478000000000121ABCDEF');
      expect(m.item?.id, 'suv');
    });

    test('markirovkali bo\'lsa KM biriktiriladi', () {
      seed([product(id: 'suv', barcodes: ['4780000000001'])]);
      expect(lookup('010478000000000121ABC', markable: true).item?.mark,
          'TOZALANGAN');
    });

    test('kod qisqa bo\'lsa (<= 16) bu shox ishlamaydi', () {
      seed([product(id: 'suv', barcodes: ['0104780000000001'])]);
      final m = lookup('0104780000000001');
      expect(m.item?.id, 'suv', reason: 'aynan teng moslik bilan topiladi');
    });
  });

  group('find — aynan teng moslik (fallback)', () {
    test('oddiy shtrix-kod topiladi', () {
      seed([product(id: 'pepsi', barcodes: ['4780000000009'])]);
      expect(lookup('4780000000009').item?.id, 'pepsi');
    });

    test('fallback yo\'lida mark HAR DOIM null', () {
      seed([product(id: 'pepsi', barcodes: ['4780000000009'])]);
      final m = lookup('4780000000009', markable: true);
      expect(m.item?.mark, isNull,
          reason: 'oddiy skanda KM bo\'lmaydi');
    });

    test('SKU bo\'yicha topiladi (narx yorlig\'idan skan)', () {
      seed([product(id: 'p', sku: '206')]);
      expect(lookup('206').item?.id, 'p');
    });

    test('SKU fragment sifatida topilmaydi ("0206" != "206")', () {
      seed([product(id: 'p', sku: '206')]);
      expect(lookup('0206').item, isNull);
    });

    test('topilmasa item null', () {
      seed([product(id: 'p', barcodes: ['1111111111111'])]);
      expect(lookup('9999999999999').found, isFalse);
    });

    test('bo\'sh katalogda null', () {
      expect(lookup('4780000000009').item, isNull);
    });
  });

  group('triedPatterns — narxi=0 tekshiruvi uchun', () {
    test('har doim asl kodni o\'z ichiga oladi', () {
      expect(lookup('4780000000009').triedPatterns, ['4780000000009']);
    });

    test('(01) formatida ajratilgan GTIN ham qo\'shiladi', () {
      final m = lookup('(01)04780000000001');
      expect(m.triedPatterns, ['(01)04780000000001', '4780000000001']);
    });

    test('qavssiz "01" formatida ham qo\'shiladi', () {
      final m = lookup('010478000000000121ABC');
      expect(m.triedPatterns.length, 2);
      expect(m.triedPatterns.last, '4780000000001');
    });

    test('mahsulot (01) orqali topilsa qavssiz shox ishlamaydi', () {
      seed([product(id: 'suv', barcodes: ['4780000000001'])]);
      final m = lookup('(01)04780000000001');
      expect(m.triedPatterns.length, 2, reason: 'faqat bitta variant qo\'shildi');
    });
  });

  group('findZeroPriceProduct', () {
    test('sinalgan variantlardan biri bo\'yicha topiladi', () {
      seed([product(id: 'tekin', barcodes: ['4780000000001'])]);
      expect(
        ScannedProductLookup.findZeroPriceProduct(
            ['boshqa-kod', '4780000000001'])?.id,
        'tekin',
      );
    });

    test('birinchi mos kelgan variant qaytadi', () {
      seed([
        product(id: 'birinchi', barcodes: ['aaa']),
        product(id: 'ikkinchi', barcodes: ['bbb']),
      ]);
      expect(
        ScannedProductLookup.findZeroPriceProduct(['aaa', 'bbb'])?.id,
        'birinchi',
      );
    });

    test('bo\'shliqlar e\'tiborga olinmaydi (trim)', () {
      seed([product(id: 'p', barcodes: ['  4780000000001  '])]);
      expect(ScannedProductLookup.findZeroPriceProduct(['4780000000001'])?.id,
          'p');
    });

    test('hech biri mos kelmasa null', () {
      seed([product(id: 'p', barcodes: ['aaa'])]);
      expect(ScannedProductLookup.findZeroPriceProduct(['zzz']), isNull);
    });

    test('bo\'sh ro\'yxatda null', () {
      expect(ScannedProductLookup.findZeroPriceProduct([]), isNull);
    });
  });
}
