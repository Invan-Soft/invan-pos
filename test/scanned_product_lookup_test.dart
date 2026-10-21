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
import 'package:invan2/changes/domain/marking/mark_cleaner.dart';
import 'package:invan2/changes/domain/marking/mark_validator.dart';
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

// ---- 2026-10-21: KM to'g'ridan skanerlanganda GTIN boshidagi nollar ----
//
// Do'kondagi haqiqiy holat: "Ichimlik Fanta 355ml" (SKU 25619). KM ichida
// GTIN-14 `00049000033939`; katalogda UPC-12 / EAN-13 yozuvlari. Avval
// faqat nolsiz `49000033939` AYNAN qidirilardi — topilmasdi. Oddiy
// shtrix-kodni skanerlab, keyin dialogga KM berilsa ishlardi
// (`MarkValidator` ikkala tomondan nolni olib tashlaydi).

/// Adminkadagi 8 ta shtrix-kod (hammasi bitta mahsulotda).
const kFantaBarcodes = [
  '049000014242',
  '0049000014242',
  '049000067729',
  '0049000067729',
  '049000033939',
  '0049000033939',
  '049000014273',
  '0049000014273',
];

const kGs = '\x1D';

/// 01 + GTIN14 + 21 + seriya(13) + `<GS>` + 93 + kripto(4).
const kKm1 = '0100049000033939217MG7fVVkzf5Y?${kGs}93abcd';
const kKm2 = '0100049000033939217/VG5xQ2pLm8a${kGs}93Wz1k';

/// Skaner GS belgisini yubormasa.
const kKm1NoGs = '0100049000033939217MG7fVVkzf5Y?93abcd';

/// Qavsli (HRI) ko'rinish.
const kKm1Paren = '(01)00049000033939(21)7MG7fVVkzf5Y?(93)abcd';

const kKm1Clean = '0100049000033939217MG7fVVkzf5Y?';
const kKm2Clean = '0100049000033939217/VG5xQ2pLm8a';

const kAllKms = {
  'KM1 (GS bilan)': kKm1,
  'KM2 (GS bilan)': kKm2,
  'KM1 (GS siz)': kKm1NoGs,
  'KM1 (qavsli)': kKm1Paren,
};

ItemModel fanta({List<String> barcodes = kFantaBarcodes}) =>
    product(id: 'fanta', sku: '25619', barcodes: barcodes);

/// Real KM tozalovchi bilan — savatga aynan nima yozilishini ko'rish uchun.
ScannedProductMatch scanKm(String km, {bool markable = true}) =>
    ScannedProductLookup.find(
      km,
      isMarkable: (_) => markable,
      cleanMark: MarkCleaner.scanTime,
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

  // ===================================================================
  // KM to'g'ridan skan — GTIN boshidagi nollar (2026-10-21)
  // ===================================================================
  group('KM to\'g\'ridan skan — Fanta 355ml (do\'kondagi holat)', () {
    kAllKms.forEach((name, km) {
      test('$name → Fanta topiladi, KM biriktiriladi', () {
        seed([fanta()]);
        final m = scanKm(km);
        expect(m.item?.id, 'fanta');
        expect(m.item!.mark, MarkCleaner.scanTime(km));
      });
    });

    test('savatga yoziladigan KM: kripto qismsiz, 01/21 raqamlari bilan', () {
      seed([fanta()]);
      expect(scanKm(kKm1).item!.mark, kKm1Clean);
      expect(scanKm(kKm1NoGs).item!.mark, kKm1Clean);
      expect(scanKm(kKm1Paren).item!.mark, kKm1Clean);
      expect(scanKm(kKm2).item!.mark, kKm2Clean);
    });

    test('blok qidiruvi Fanta KM ini blok deb olmaydi', () {
      seed([fanta()]);
      expect(ScannedProductLookup.findBoxProduct(kKm1), isNull);
      expect(ScannedProductLookup.findBoxProduct(kKm2), isNull);
    });

    test('markirovkasiz mahsulotga KM biriktirilMAYDI', () {
      seed([fanta()]);
      final m = scanKm(kKm1, markable: false);
      expect(m.item?.id, 'fanta');
      expect(m.item!.mark, isNull);
    });

    test('isMarkable topilgan mahsulotning o\'zi bilan chaqiriladi', () {
      seed([fanta()]);
      ItemModel? asked;
      ScannedProductLookup.find(kKm1,
          isMarkable: (p) {
            asked = p;
            return true;
          },
          cleanMark: MarkCleaner.scanTime);
      expect(asked?.id, 'fanta');
    });

    test('ESKI KOD: nolsiz GTIN aynan qidirilsa katalogda yo\'q (bug sababi)',
        () {
      seed([fanta()]);
      expect(ItemsSingleton.getProductByBarcode('49000033939'), isNull);
    });
  });

  group('KM — har bir shtrix-kod yolg\'iz o\'zi bo\'lsa ham', () {
    // KM1/KM2 GTIN i 00049000033939 — faqat shu GTIN ning yozuvlari mos.
    for (final b in [
      '049000033939',
      '0049000033939',
      '49000033939',
      '00049000033939',
    ]) {
      for (final km in [kKm1, kKm2]) {
        test('katalogda faqat $b, KM ${km.substring(16, 22)}… → topiladi', () {
          seed([fanta(barcodes: [b])]);
          expect(scanKm(km).item?.id, 'fanta');
        });
      }
    }

    // Qolgan 6 ta (014242 / 067729 / 014273) — har biri O'Z GTIN i bilan.
    for (final b in kFantaBarcodes) {
      test('$b → o\'z GTIN-14 i bilan KM topadi', () {
        seed([fanta(barcodes: [b])]);
        final gtin14 = b.padLeft(14, '0');
        expect(scanKm('01${gtin14}21SERIAL0000001${kGs}93abcd').item?.id,
            'fanta');
      });
    }

    test('boshqa GTIN dagi shtrix-kod Fanta KM iga mos EMAS', () {
      // 049000014242 — Fanta'ning boshqa o'lchami; KM 00049000033939
      seed([fanta(barcodes: ['049000014242', '0049000014242'])]);
      expect(scanKm(kKm1).item, isNull);
    });
  });

  group('Avvalgi xatti-harakat o\'zgarmagan — aynan teng moslik ustun', () {
    test('nolsiz GTIN ga aynan teng mahsulot GS1 tengidan oldin', () {
      seed([
        product(id: 'ean13', barcodes: ['0049000033939']),
        product(id: 'nolsiz', barcodes: ['49000033939']),
      ]);
      expect(scanKm(kKm1).item?.id, 'nolsiz',
          reason: 'katalog tartibi emas — avval aynan teng qidiruv');
    });

    test('butun KM ga aynan teng barcode (eski "Yaratish") ustun, mark null',
        () {
      seed([
        fanta(),
        product(id: 'km-barcode', barcodes: [kKm1]),
      ]);
      final m = scanKm(kKm1);
      expect(m.item?.id, 'km-barcode');
      expect(m.item!.mark, isNull);
    });

    test('mavjud ishlagan holatlar: nolsiz / to\'liq EAN13', () {
      seed([product(id: 'suv', barcodes: ['4780000000001'])]);
      expect(scanKm('010478000000000121ABC').item?.id, 'suv');
      expect(scanKm('(01)04780000000001(21)ABC').item?.id, 'suv');
    });
  });

  group('Oddiy skan va SKU — normalizatsiya YO\'Q (o\'zgarishsiz)', () {
    test('oddiy "49000033939" skani 049000033939 ni topmaydi', () {
      seed([fanta(barcodes: ['049000033939'])]);
      expect(lookup('49000033939').item, isNull);
    });

    test('oddiy "049000033939" skani 0049000033939 ni topmaydi', () {
      seed([fanta(barcodes: ['0049000033939'])]);
      expect(lookup('049000033939').item, isNull);
    });

    test('oddiy GTIN-14 "00049000033939" skani (KM emas) topmaydi', () {
      seed([fanta(barcodes: ['0049000033939'])]);
      expect(lookup('00049000033939').item, isNull);
    });

    test('16 belgili "01"+GTIN14 (seriyasiz) KM hisoblanmaydi', () {
      seed([fanta()]);
      expect(lookup('0100049000033939').item, isNull);
      expect(ScannedProductLookup.findBoxProduct('0100049000033939'), isNull);
    });

    test('oddiy skanning o\'zi aynan teng bo\'lsa topiladi (o\'zgarmagan)', () {
      seed([fanta()]);
      for (final b in kFantaBarcodes) {
        final m = lookup(b, markable: true);
        expect(m.item?.id, 'fanta', reason: b);
        expect(m.item!.mark, isNull, reason: 'oddiy skanda KM yo\'q');
      }
    });

    test('oddiy skanda gtins bo\'sh — GS1 tengligi ishlamaydi', () {
      expect(lookup('49000033939').gtins, isEmpty);
      expect(lookup('49000033939').triedPatterns, ['49000033939']);
    });

    test('SKU bo\'yicha (25619) topiladi, "025619" topilmaydi', () {
      seed([fanta(barcodes: [])]);
      expect(lookup('25619').item?.id, 'fanta');
      expect(lookup('025619').item, isNull);
    });
  });

  group('KM boshqa mahsulotga ulanmaydi', () {
    test('KM GTIN i boshqa mahsulotniki → o\'sha mahsulot, Fanta emas', () {
      seed([
        fanta(),
        product(id: 'pepsi', barcodes: ['04780000000017']),
      ]);
      final m = scanKm('0104780000000017215KM000001${kGs}93abcd');
      expect(m.item?.id, 'pepsi');
    });

    test('GTIN da bitta raqam farq → topilmaydi', () {
      seed([fanta()]);
      expect(scanKm('0100049000033946217MG7fVVkzf5Y?${kGs}93abcd').item,
          isNull);
    });

    test('indikator raqamli GTIN-14 (10049000033939, karton) dona emas', () {
      seed([fanta()]);
      expect(scanKm('0110049000033939217MG7fVVkzf5Y?${kGs}93abcd').item,
          isNull);
    });

    test('harf aralash shtrix-kod normalizatsiya qilinmaydi', () {
      seed([
        fanta(barcodes: ['049000033939A', 'O49000033939', ' 049000033939'])
      ]);
      expect(scanKm(kKm1).item, isNull);
    });

    test('fragment: oxiri yetishmaydigan / ortiqcha / boshqa prefiksli kod',
        () {
      seed([
        fanta(barcodes: ['4900003393', '490000339390', '149000033939'])
      ]);
      expect(scanKm(kKm1).item, isNull);
    });

    test('14 xonadan uzun shtrix-kod GTIN emas — qatnashmaydi', () {
      seed([fanta(barcodes: ['000049000033939'])]);
      expect(scanKm(kKm1).item, isNull);
    });

    test('8 xonadan qisqa kod nol bilan to\'ldirilmaydi', () {
      // GTIN-14 00000000012345 → kalit 12345 (SKU uzunligi)
      seed([product(id: 'ichki', barcodes: ['0012345'])]);
      expect(scanKm('0100000000012345' '21SERIAL${kGs}93ab').item, isNull);
    });

    test('GTIN-8 (8 xona) KM ichida 14 xonagacha to\'ldirilgan — topiladi', () {
      seed([product(id: 'gtin8', barcodes: ['40170725'])]);
      expect(scanKm('0100000040170725' '21SERIAL${kGs}93ab').item?.id, 'gtin8');
      // Boshida nol bor GTIN-8: nolsiz kalit 7 xona — faqat GS1 tengligi bilan
      seed([product(id: 'gtin8-0', barcodes: ['01234565'])]);
      expect(scanKm('0100000001234565' '21SERIAL${kGs}93ab').item?.id,
          'gtin8-0');
    });

    test('hammasi nol GTIN — hech narsa topilmaydi', () {
      seed([product(id: 'nol', barcodes: ['00000000'])]);
      final m = scanKm('0100000000000000' '21SERIAL');
      expect(m.item, isNull);
      expect(m.gtins, isEmpty);
    });

    test('narxi bor mahsulotlar ro\'yxatidan (barcodeProducts) qidiriladi', () {
      ItemsSingleton.products = [fanta()];
      ItemsSingleton.barcodeProducts = [];
      expect(scanKm(kKm1).item, isNull, reason: 'narxi 0 — alohida yo\'l');
    });
  });

  group('Blok shtrix-kodi — GS1 tengligi', () {
    // Blok GTIN-14 = 00049000099991
    const kBoxKm = '0100049000099991' '21BLOK00000001';

    test('blok kodi UPC-12 (049000099991) → topiladi', () {
      seed([product(id: 'blok', boxBarcode: '049000099991')]);
      expect(ScannedProductLookup.findBoxProduct(kBoxKm)?.id, 'blok');
    });

    for (final b in ['0049000099991', '49000099991', '00049000099991']) {
      test('blok kodi $b (aynan teng variant) → topiladi', () {
        seed([product(id: 'blok', boxBarcode: b)]);
        expect(ScannedProductLookup.findBoxProduct(kBoxKm)?.id, 'blok');
      });
    }

    test('aynan teng variant GS1 tengidan oldin', () {
      seed([
        product(id: 'upc12', boxBarcode: '049000099991'),
        product(id: 'ean13', boxBarcode: '0049000099991'),
      ]);
      expect(ScannedProductLookup.findBoxProduct(kBoxKm)?.id, 'ean13');
    });

    test('oddiy shtrix-kod blok qidiruviga tushmaydi', () {
      seed([product(id: 'dona', barcodes: ['049000099991'])]);
      expect(ScannedProductLookup.findBoxProduct(kBoxKm), isNull);
    });

    test('hasBoxBarcode false bo\'lsa blok kodi hisobga olinmaydi', () {
      final m = product(id: 'blok', boxBarcode: '049000099991')
        ..hasBoxBarcode = false;
      seed([m]);
      expect(ScannedProductLookup.findBoxProduct(kBoxKm), isNull);
    });

    test('harf aralash / 14 dan uzun blok kodi qatnashmaydi', () {
      seed([
        product(id: 'a', boxBarcode: 'B49000099991'),
        product(id: 'b', boxBarcode: '000049000099991'),
      ]);
      expect(ScannedProductLookup.findBoxProduct(kBoxKm), isNull);
    });
  });

  group('Narxi 0 mahsulot — GS1 tengligi', () {
    void seedZeroPrice(List<ItemModel> items) {
      ItemsSingleton.products = items;
      ItemsSingleton.barcodeProducts = []; // narxi 0 — skaner ro'yxatida yo'q
    }

    test('KM → narxi 0 Fanta topiladi (gtins bilan)', () {
      seedZeroPrice([fanta()]);
      final m = scanKm(kKm1);
      expect(m.item, isNull);
      expect(m.gtins, ['49000033939']);
      expect(
          ScannedProductLookup.findZeroPriceProduct(m.triedPatterns,
                  gtins: m.gtins)
              ?.id,
          'fanta');
    });

    test('gtins berilmasa — eski xatti-harakat (topilmaydi)', () {
      seedZeroPrice([fanta()]);
      final m = scanKm(kKm1);
      expect(ScannedProductLookup.findZeroPriceProduct(m.triedPatterns),
          isNull);
    });

    test('oddiy skan (gtins bo\'sh) — normalizatsiya yo\'q', () {
      seedZeroPrice([fanta(barcodes: ['049000033939'])]);
      final m = lookup('49000033939');
      expect(
          ScannedProductLookup.findZeroPriceProduct(m.triedPatterns,
              gtins: m.gtins),
          isNull);
    });

    test('aynan teng variant GS1 tengidan oldin', () {
      seedZeroPrice([
        product(id: 'upc12', barcodes: ['049000033939']),
        product(id: 'nolsiz', barcodes: ['49000033939']),
      ]);
      final m = scanKm(kKm1);
      expect(
          ScannedProductLookup.findZeroPriceProduct(m.triedPatterns,
                  gtins: m.gtins)
              ?.id,
          'nolsiz');
    });

    test('katalog kodidagi bo\'shliqlar e\'tiborga olinmaydi (trim)', () {
      seedZeroPrice([fanta(barcodes: [' 049000033939 '])]);
      final m = scanKm(kKm1);
      expect(
          ScannedProductLookup.findZeroPriceProduct(m.triedPatterns,
                  gtins: m.gtins)
              ?.id,
          'fanta');
    });
  });

  group('gtins — KM/GS1 dan ajratilgan GTIN lar', () {
    test('qavssiz KM', () {
      expect(scanKm(kKm1).gtins, ['49000033939']);
    });

    test('qavsli KM', () {
      expect(scanKm(kKm1Paren).gtins, ['49000033939']);
    });

    test('triedPatterns avvalgidek: asl kod + nolsiz GTIN', () {
      expect(scanKm(kKm1).triedPatterns, [kKm1, '49000033939']);
    });

    test('topilgan holatda ham gtins to\'ldiriladi', () {
      seed([fanta()]);
      expect(scanKm(kKm1).gtins, ['49000033939']);
    });
  });

  group('MarkValidator bilan muvofiqlik (dialog yo\'li)', () {
    // Skaner topgan mahsulot `_markingCheck` dagi `MarkValidator` dan o'tishi
    // shart — aks holda "boshqa mahsulotga tegishli" xatosi chiqardi.
    for (final b in [
      ...kFantaBarcodes.where((b) => b.endsWith('33939')),
      '49000033939',
      '00049000033939',
    ]) {
      kAllKms.forEach((name, km) {
        test('katalogda $b, $name: topiladi VA tekshiruvdan o\'tadi', () {
          seed([fanta(barcodes: [b])]);
          final found = scanKm(km).item;
          expect(found?.id, 'fanta');
          final v = MarkValidator.validate(found!.mark!, found);
          expect(v.issue, MarkIssue.none);
          expect(v.gtin, '49000033939');
        });
      });
    }

    test('dialog yo\'li (avval ham ishlagan) o\'zgarmagan', () {
      expect(MarkValidator.validate(kKm1Clean, fanta()).issue, MarkIssue.none);
      expect(
          MarkValidator.validate(kKm1Clean, fanta(barcodes: ['049000014242']))
              .issue,
          MarkIssue.wrongProduct);
    });
  });

  group('Unumdorlik — katta katalog', () {
    test('30 000 mahsulot, Fanta oxirida: KM qidiruvi tez', () {
      final items = [
        for (var i = 0; i < 30000; i++)
          product(id: 'p$i', barcodes: [
            '478${i.toString().padLeft(10, '0')}',
            'X$i',
          ], boxBarcode: i.isEven ? '1478${i.toString().padLeft(10, '0')}' : null),
        fanta(),
      ];
      seed(items);
      final sw = Stopwatch()..start();
      final box = ScannedProductLookup.findBoxProduct(kKm1);
      final m = scanKm(kKm1);
      sw.stop();
      // ignore: avoid_print
      print('30 000 katalog: blok + KM qidiruvi ${sw.elapsedMilliseconds} ms');
      expect(box, isNull);
      expect(m.item?.id, 'fanta');
      // Odatda bir necha o'n ms; chegara CI uchun keng.
      expect(sw.elapsedMilliseconds, lessThan(1500));
    });
  });
}
