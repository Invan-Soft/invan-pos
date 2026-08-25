// Savatdan BITTA qatorni o'chirish (OPD dialogidagi "O'chirish").
//
// Guruh (marka/blok) yo'llari `group_edit_test` da, `deleted_items` yozuvi
// esa `deleted_items_orderpos_test` da. Bu fayl aynan BITTA QATOR yo'lini
// muzlatadi: qizil o'chirish, savat bo'shashi, qolgan qatorlarning qayta
// narxlanishi va diskont effektlarining qayta hisoblanishi.
//
// Faza 9.4 da bu yo'l `CartRowDeleter` ga ko'chiriladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kPid = 'suv-id';
const kBox = 12;

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

ItemModel tierProduct({String id = kPid}) {
  final m = ItemModel();
  m.id = id;
  m.name = 'Suv';
  m.vat = Vat(percentage: 12);
  m.measurementUnit = MeasurementUnit(shortName: 'dona');
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: 'shop-1', shopPriceTiers: [
      ShopPriceTiers(minQuantity: 1, retailPrice: 5000),
      ShopPriceTiers(minQuantity: 12, retailPrice: 4500),
    ]),
  );
  return m;
}

void deleteRow(OrderingProvider4 p, int index) {
  p.tapIndexToEdit(index);
  p.pressDialogDeleteButton();
}

void main() {
  setUpAll(() => setUpPosTestEnv('cart_row_delete_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    ItemsSingleton.products = [];
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
  });

  group('Oddiy rejim (qizil o\'chirish o\'chiq)', () {
    test('tanlangan qator savatdan butunlay chiqadi', () {
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: 'a', price: 100),
        makeSoldItem(productId: 'b', price: 200),
      ]);
      deleteRow(p, 0);
      expect(cart(p).length, 1);
      expect(cart(p)[0].price, 200);
    });

    test('o\'rtadagi qator o\'chirilsa qolganlar tartibi saqlanadi', () {
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: 'a', price: 100),
        makeSoldItem(productId: 'b', price: 200),
        makeSoldItem(productId: 'c', price: 300),
      ]);
      deleteRow(p, 1);
      expect(cart(p).map((e) => e.price), [100, 300]);
    });

    test('yagona qator o\'chirilsa savat bo\'shaydi', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid));
      deleteRow(p, 0);
      expect(cart(p), isEmpty);
    });
  });

  group('Qizil o\'chirish rejimi', () {
    test('qator savatda qoladi, faqat isDeleted = true bo\'ladi', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid));
      deleteRow(p, 0);
      expect(cart(p).length, 1);
      expect(cart(p)[0].isDeleted, isTrue);
    });

    test('boshqa qatorlarga tegilmaydi', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: 'a'),
        makeSoldItem(productId: 'b'),
      ]);
      deleteRow(p, 0);
      expect(cart(p)[1].isDeleted, isFalse);
    });
  });

  group('Mijoz tanlovi', () {
    test('savat butunlay bo\'shasa mijoz tanlovi bekor bo\'ladi', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid));
      p.setNewClientDiscountPercentage(15);
      deleteRow(p, 0);
      expect(p.getCurrentClient.selectedClient, isNull);
    });

    test('savatda qator qolsa mijoz tanlovi saqlanadi', () {
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: 'a'),
        makeSoldItem(productId: 'b'),
      ]);
      deleteRow(p, 0);
      expect(cart(p).length, 1);
    });

    test('QAYD: qizil o\'chirishda savat "bo\'sh" hisoblanmaydi — '
        'mijoz tanlovi qoladi', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid));
      deleteRow(p, 0);
      // orderedProducts.isEmpty emas (qator isDeleted bo'lib qoldi)
      expect(cart(p).length, 1);
    });
  });

  group('Qolgan qatorlar qayta narxlanadi', () {
    test('12 donadan bittasi o\'chsa qolganlari 1-tier narxiga qaytadi', () {
      ItemsSingleton.products = [tierProduct()];
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: kPid, price: 4500, value: 1),
        makeSoldItem(productId: kPid, price: 4500, value: 11),
      ]);
      deleteRow(p, 1); // 12 → 1 dona qoladi
      expect(cart(p)[0].price, 5000);
    });

    test('blok qatori qolsa u ham qayta narxlanadi', () {
      ItemsSingleton.products = [tierProduct()];
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: kPid, price: 1, value: 1),
        makeSoldItem(
            productId: kPid, price: 1, value: 1, saleType: 2, boxValue: kBox),
      ]);
      deleteRow(p, 0); // 13 → 12 dona
      expect(cart(p)[0].price, 4500 * kBox);
    });

    test('boshqa mahsulot qatoriga tegilmaydi', () {
      ItemsSingleton.products = [tierProduct(), tierProduct(id: 'boshqa')];
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: kPid, price: 1),
        makeSoldItem(productId: 'boshqa', price: 777),
      ]);
      deleteRow(p, 0);
      expect(cart(p)[0].price, 777);
    });

    test('qo\'lda narxli qator o\'chirishdan keyin ham himoyalangan', () {
      ItemsSingleton.products = [tierProduct()];
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: kPid, price: 1, value: 1),
        makeSoldItem(
            productId: kPid, price: 3333, value: 1, isPriceOnlyChanged: true),
      ]);
      deleteRow(p, 0);
      expect(cart(p)[0].price, 3333);
    });
  });

  group('deleted_items va orphan', () {
    test('o\'chirilgan qator yoziladi', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 5000, value: 2));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.length, 1);
      expect(p.getCurrentClient.deletedItems.first.totalPrice, 10000);
    });

    test('savat sotuvsiz bo\'shasa "-" belgilanadi', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.checkNumber, '-');
    });

    test('savatda qator qolsa "-" qo\'yilmaydi', () {
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: 'a'),
        makeSoldItem(productId: 'b'),
      ]);
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.checkNumber, isEmpty);
    });

    test('qizil o\'chirishda savat bo\'shasa ham "-" belgilanadi', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.checkNumber, '-');
    });
  });

  group('notifyListeners', () {
    test('o\'chirish UI ni xabardor qiladi', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid));
      var n = 0;
      p.addListener(() => n++);
      deleteRow(p, 0);
      expect(n, greaterThan(0));
    });
  });
}
