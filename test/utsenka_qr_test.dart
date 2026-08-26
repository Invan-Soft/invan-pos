// Utsenka (chegirmali tovar) QR kodi — `UtsenkaQr`.
//
// Do'kon muddati yaqinlashgan tovarga QR chop etadi. Noto'g'ri o'qilsa
// tovar noto'g'ri narxda sotiladi yoki umuman qo'shilmaydi, shuning uchun
// har bir rad etish sababi alohida muzlatiladi.
//
// Bu kod ilgari `_parseUtsenkaQr` ichida edi va faqat `onBarcodeScanned`
// orqali (GlobalKey<ScaffoldState> bilan) ishga tushardi — testlab bo'lmasdi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/barcode/utsenka_qr.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

ItemModel product({String sku = '206', num price = 10000}) {
  final m = ItemModel();
  m.id = 'suv-id';
  m.name = 'Suv';
  m.sku = sku;
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: 'shop-1', shopPriceTiers: [
      ShopPriceTiers(minQuantity: 1, retailPrice: price),
    ]),
  );
  return m;
}

void main() {
  setUp(() => ItemsSingleton.products = [product()]);

  group('Muvaffaqiyatli o\'qish', () {
    test('sku va price o\'qiladi, mahsulot topiladi', () {
      final o = UtsenkaQr.parse('{"sku":206,"price":8000}');
      expect(o, isNotNull);
      expect(o!.product.id, 'suv-id');
      expect(o.price, 8000);
    });

    test('asl narx katalogdan olinadi', () {
      expect(UtsenkaQr.parse('{"sku":206,"price":8000}')!.originalPrice, 10000);
    });

    test('chegirma = asl narx − QR narxi', () {
      expect(UtsenkaQr.parse('{"sku":206,"price":8000}')!.discount, 2000);
    });

    test('foiz to\'g\'ri hisoblanadi', () {
      expect(UtsenkaQr.parse('{"sku":206,"price":8000}')!.percent, 20);
    });

    test('sku matn ko\'rinishida bo\'lsa ham o\'qiladi', () {
      expect(UtsenkaQr.parse('{"sku":"206","price":8000}'), isNotNull);
    });

    test('kasrli narx qabul qilinadi', () {
      expect(UtsenkaQr.parse('{"sku":206,"price":8500.5}')!.price, 8500.5);
    });

    test('QR narxi ASL narxdan katta bo\'lsa chegirma 0 (manfiy emas)', () {
      final o = UtsenkaQr.parse('{"sku":206,"price":15000}')!;
      expect(o.discount, 0);
      expect(o.percent, 0);
    });

    test('asl narx 0 bo\'lsa foiz 0 (nolga bo\'linish yo\'q)', () {
      ItemsSingleton.products = [product(price: 0)];
      final o = UtsenkaQr.parse('{"sku":206,"price":8000}')!;
      expect(o.percent, 0);
      expect(o.discount, 0);
    });
  });

  group('Rad etish sabablari → null', () {
    test('JSON emas (oddiy shtrix-kod)', () {
      expect(UtsenkaQr.parse('4780000000001'), isNull);
    });

    test('buzilgan JSON', () {
      expect(UtsenkaQr.parse('{"sku":206,'), isNull);
    });

    test('JSON massiv (Map emas)', () {
      expect(UtsenkaQr.parse('[206,8000]'), isNull);
    });

    test('sku yo\'q', () {
      expect(UtsenkaQr.parse('{"price":8000}'), isNull);
    });

    test('price yo\'q', () {
      expect(UtsenkaQr.parse('{"sku":206}'), isNull);
    });

    test('sku raqam emas', () {
      expect(UtsenkaQr.parse('{"sku":"abc","price":8000}'), isNull);
    });

    test('narx 0', () {
      expect(UtsenkaQr.parse('{"sku":206,"price":0}'), isNull);
    });

    test('narx manfiy', () {
      expect(UtsenkaQr.parse('{"sku":206,"price":-100}'), isNull);
    });

    test('SKU katalogda yo\'q', () {
      expect(UtsenkaQr.parse('{"sku":999,"price":8000}'), isNull);
    });

    test('bo\'sh matn', () {
      expect(UtsenkaQr.parse(''), isNull);
    });
  });
}
