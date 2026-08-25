// Savatdagi UMUMIY dona soni bo'yicha tier qayta-narxlash.
//
// Biznes qoida: tier savatdagi jami dona soniga qarab tanlanadi
// (dona qatorlari value + blok qatorlari value × boxValue). Dona qatoriga
// tierUnit, blok qatoriga tierUnit × boxValue qo'yiladi. Qo'lda narxi
// o'zgartirilgan qatorlar (isPriceOnlyChanged) tegilmaydi.
//
// Faza 9.1 da bu klaster alohida modulga ko'chiriladi — shuning uchun avval
// har bir shox (early-return, blok, aralash savat, VAT, diskont reset)
// muzlatiladi.
//
// Trigger: OPD dialogidagi "Saqlash" (`pressDialogSaveButton`) — real POS yo'li.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

const kPid = 'suv-id';
const kBoxValue = 12;

/// Tier'li katalog mahsuloti. [tiers] — minQuantity → retailPrice.
ItemModel tierProduct({
  String id = kPid,
  Map<int, num> tiers = const {1: 5000, 12: 4500, 36: 4000},
  int vatPercent = 12,
  String unit = 'dona',
}) {
  final m = ItemModel();
  m.id = id;
  m.name = 'Suv 1L';
  m.vat = Vat(percentage: vatPercent);
  m.measurementUnit = MeasurementUnit(shortName: unit);
  m.shopPrices = ShopPrices(
    shID: ShID(
      shopId: 'shop-1',
      shopPriceTiers: [
        for (final t in tiers.entries)
          ShopPriceTiers(minQuantity: t.key, retailPrice: t.value)
      ],
    ),
  );
  return m;
}

/// Tier reprice'ni ishga tushiradi: [index] qatorini o'zgartirmasdan saqlaydi.
/// (OPD "Saqlash" — real POS yo'li.)
Future<void> saveRow(OrderingProvider4 p, int index,
    {ReceiptModelSoldItem4? edited}) async {
  p.tapIndexToEdit(index);
  await p.pressDialogSaveButton(
      edited ?? p.getCurrentClient.orderedProducts[index]);
}

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

void main() {
  setUpAll(() => setUpPosTestEnv('tier_reprice_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [tierProduct()];
  });

  group('Early return — hech narsa o\'zgarmaydi', () {
    test('productId bo\'sh bo\'lsa boshqa qatorlarga tegilmaydi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: '', price: 111))
        ..add(makeSoldItem(productId: kPid, price: 999));
      await saveRow(p, 0);
      expect(cart(p)[1].price, 999);
    });

    test('mahsulot katalogda topilmasa narx o\'zgarmaydi', () async {
      ItemsSingleton.products = [];
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 999));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 999);
    });

    test('tier ro\'yxati bo\'sh bo\'lsa (unitPrice = 0) narx o\'zgarmaydi',
        () async {
      ItemsSingleton.products = [tierProduct(tiers: const {})];
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 999));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 999);
    });

    test('barcha qatorlar o\'chirilgan bo\'lsa (totalUnits = 0) tegilmaydi',
        () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 999, isDeleted: true))
        ..add(makeSoldItem(productId: 'boshqa-id', price: 111));
      await saveRow(p, 1);
      expect(cart(p)[0].price, 999);
    });
  });

  group('Dona qatorlari — tier savatdagi umumiy son bo\'yicha', () {
    test('1 dona → 1-tier (5000)', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1, value: 1));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 5000);
    });

    test('12 dona → 2-tier (4500)', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1, value: 12));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 4500);
    });

    test('CHEGARA: 11 dona hali 1-tier (5000)', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1, value: 11));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 5000);
    });

    test('36 dona → 3-tier (4000)', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1, value: 36));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 4000);
    });

    test('ikki dona qatori jamlanadi: 6 + 6 = 12 → ikkalasi ham 4500',
        () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 1, value: 6))
        ..add(makeSoldItem(productId: kPid, price: 1, value: 6));
      await saveRow(p, 0);
      expect(cart(p).map((e) => e.price), [4500, 4500]);
    });

    test('boshqa mahsulot qatori hisobga olinmaydi va o\'zgarmaydi', () async {
      ItemsSingleton.products = [tierProduct(), tierProduct(id: 'boshqa-id')];
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 1, value: 6))
        ..add(makeSoldItem(productId: 'boshqa-id', price: 777, value: 6));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 5000, reason: '6 dona → 1-tier');
      expect(cart(p)[1].price, 777, reason: 'boshqa mahsulotga tegilmaydi');
    });

    test('o\'chirilgan qator jamiga kirmaydi va qayta narxlanmaydi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 1, value: 6))
        ..add(makeSoldItem(
            productId: kPid, price: 999, value: 30, isDeleted: true));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 5000, reason: 'faqat 6 dona → 1-tier');
      expect(cart(p)[1].price, 999, reason: 'o\'chirilgan qator tegilmaydi');
    });

    test('price, realPrice va onlyPrice birga yangilanadi', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1, value: 12));
      await saveRow(p, 0);
      final r = cart(p)[0];
      expect([r.price, r.realPrice, r.onlyPrice], [4500, 4500, 4500]);
    });
  });

  group('Blok qatorlari — tierUnit × boxValue', () {
    test('1 blok (12 dona) → dona 4500, blok narxi 54000', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(
          productId: kPid,
          price: 1,
          value: 1,
          saleType: 2,
          boxValue: kBoxValue));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 4500 * kBoxValue);
    });

    test('boxValue = 0 bo\'lsa blok emas, dona kabi hisoblanadi', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(
          productId: kPid, price: 1, value: 1, saleType: 2, boxValue: 0));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 5000, reason: '1 dona → 1-tier');
    });

    test('ARALASH: 3 blok (36) + 1 dona = 37 → hammasi 3-tier (4000)',
        () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(
            productId: kPid,
            price: 1,
            value: 3,
            saleType: 2,
            boxValue: kBoxValue))
        ..add(makeSoldItem(productId: kPid, price: 1, value: 1));
      await saveRow(p, 1);
      expect(cart(p)[0].price, 4000 * kBoxValue, reason: 'blok qatori');
      expect(cart(p)[1].price, 4000, reason: 'dona qatori');
    });

    test('2 blok (24 dona) → 2-tier (4500), blok 54000', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(
          productId: kPid,
          price: 1,
          value: 2,
          saleType: 2,
          boxValue: kBoxValue));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 4500 * kBoxValue);
    });
  });

  group('Qo\'lda o\'zgartirilgan narx (isPriceOnlyChanged) himoyalangan', () {
    test('manual qator tier reprice\'da o\'zgarmaydi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(
            productId: kPid, price: 3333, value: 12, isPriceOnlyChanged: true))
        ..add(makeSoldItem(productId: 'boshqa-id', price: 111));
      await saveRow(p, 1);
      expect(cart(p)[0].price, 3333);
    });

    test('manual qator UMUMIY songa baribir qo\'shiladi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(
            productId: kPid, price: 3333, value: 11, isPriceOnlyChanged: true))
        ..add(makeSoldItem(productId: kPid, price: 1, value: 1));
      await saveRow(p, 1);
      expect(cart(p)[0].price, 3333, reason: 'manual qator tegilmaydi');
      expect(cart(p)[1].price, 4500,
          reason: '11 + 1 = 12 dona → 2-tier; manual qator jamiga kiradi');
    });
  });

  group('VAT va diskont maydonlari', () {
    test('VAT yangi narxdan qayta hisoblanadi (12%)', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1, value: 12));
      await saveRow(p, 0);
      expect(cart(p)[0].vat, closeTo(4500 * 12 / 112, 0.001));
    });

    test('VAT mahsulot foizidan olinadi (0% → vat 0)', () async {
      ItemsSingleton.products = [tierProduct(vatPercent: 0)];
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1, value: 1));
      await saveRow(p, 0);
      expect(cart(p)[0].vat, 0);
    });

    test('dona qatorida singleDiscount nolga tushadi', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(
          productId: kPid, price: 1, value: 12, singleDiscount: 700));
      await saveRow(p, 0);
      expect(cart(p)[0].singleDiscount, 0);
    });

    test('QAYD: blok qatorida singleDiscount tozalanmaydi (saleType == 2)',
        () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(
        productId: kPid,
        price: 1,
        value: 1,
        saleType: 2,
        boxValue: kBoxValue,
        singleDiscount: 700,
      ));
      await saveRow(p, 0);
      expect(cart(p)[0].singleDiscount, 700);
    });
  });

  group('Kiloli mahsulot', () {
    test('0.5 kg → tier 1 narxi (finalPrice kg\'da value\'ni 1 ga ko\'taradi)',
        () async {
      ItemsSingleton.products = [tierProduct(unit: 'кг')];
      final p = freshProvider();
      cart(p)
          .add(makeSoldItem(productId: kPid, price: 1, value: 0.5, isKg: true));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 5000);
    });

    test('12.5 kg → 2-tier (4500)', () async {
      ItemsSingleton.products = [tierProduct(unit: 'kg')];
      final p = freshProvider();
      cart(p).add(
          makeSoldItem(productId: kPid, price: 1, value: 12.5, isKg: true));
      await saveRow(p, 0);
      expect(cart(p)[0].price, 4500);
    });
  });

  group('Tekin sovg\'a qatori', () {
    test('QAYD: free gift qatori ham qayta narxlanadi (filtr yo\'q)', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 1, value: 1))
        ..add(makeSoldItem(
            productId: kPid, price: 0, value: 1, isFreeGift: true));
      await saveRow(p, 0);
      expect(cart(p)[1].price, 5000,
          reason: 'hozirgi xatti-harakat: isFreeGift tekshirilmaydi');
    });
  });
}
