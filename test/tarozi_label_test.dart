// Tarozi yorlig'i formati — `TaroziLabel`.
//
// Do'kon tarozisi chop etadigan yorliqning tuzilishi: prefiks(2) + PLU(5) +
// gramm. Noto'g'ri o'qilsa mahsulot topilmaydi yoki NOTO'G'RI og'irlikda
// sotiladi — shuning uchun PLU qidiruvining nol-fallback qoidasi va
// og'irlik formulasi shu yerda muzlatiladi.
//
// Bu kod ilgari `scanWeightItem` / `scanPieceItem` ichida ikki nusxada edi
// va GlobalKey<ScaffoldState> talab qilgani uchun testlab bo'lmasdi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/barcode/tarozi_label.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

ItemModel product(String id, {String? sku, List<String> barcodes = const []}) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.sku = sku;
  m.barcode = barcodes;
  return m;
}

void seed(List<ItemModel> items) {
  ItemsSingleton.products = items;
  ItemsSingleton.barcodeProducts = items;
}

void main() {
  setUp(() => seed([]));

  group('plu — PLU qismini ajratish', () {
    test('3-7 belgilar olinadi', () {
      expect(TaroziLabel.plu('2800206012340'), '00206');
    });

    test('dona prefiksi (21) bilan ham bir xil', () {
      expect(TaroziLabel.plu('2100206000000'), '00206');
    });
  });

  group('weightKg — og\'irlik formulasi', () {
    test('012340 → 1.234 kg', () {
      expect(TaroziLabel.weightKg('2800206012340'), 1.234);
    });

    test('005000 → 0.5 kg', () {
      expect(TaroziLabel.weightKg('2800206005000'), 0.5);
    });

    test('4-xona pastga yaxlitlanadi (kesiladi)', () {
      // 012349 -> 1.2349 -> 1.234
      expect(TaroziLabel.weightKg('2800206012349'), 1.234);
    });

    test('nol gramm → 0', () {
      expect(TaroziLabel.weightKg('2800206000000'), 0);
    });

    test('gramm qismi raqam bo\'lmasa 0', () {
      expect(TaroziLabel.weightKg('2800206ABCDEF'), 0);
    });
  });

  group('findProduct — PLU bo\'yicha qidirish', () {
    test('aynan mos SKU topiladi', () {
      seed([product('p1', sku: '00206')]);
      expect(TaroziLabel.findProduct('00206')?.id, 'p1');
    });

    test('aynan topilmasa nolsiz ko\'rinishda qidiriladi', () {
      seed([product('p1', sku: '206')]);
      expect(TaroziLabel.findProduct('00206')?.id, 'p1');
    });

    test('aynan moslik nolsizdan USTUN', () {
      seed([product('nolsiz', sku: '206'), product('aynan', sku: '00206')]);
      expect(TaroziLabel.findProduct('00206')?.id, 'aynan');
    });

    test('hech biri topilmasa null', () {
      seed([product('p1', sku: '999')]);
      expect(TaroziLabel.findProduct('00206'), isNull);
    });

    test('faqat nollardan iborat PLU → null (bo\'sh qidiruv qilinmaydi)', () {
      seed([product('p1', sku: '206')]);
      expect(TaroziLabel.findProduct('00000'), isNull);
    });

    test('nolsiz shakl asl bilan bir xil bo\'lsa qayta qidirilmaydi', () {
      seed([product('p1', sku: '20600')]);
      expect(TaroziLabel.findProduct('20600')?.id, 'p1');
    });

    test('QAYD: yaqin/o\'xshash SKU urilmaydi ("0206" != "206")', () {
      seed([product('p1', sku: '2060')]);
      expect(TaroziLabel.findProduct('00206'), isNull);
    });
  });
}
