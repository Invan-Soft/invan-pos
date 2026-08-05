// Buy X Get X (bir xil mahsulotdan tekin) oqimi — xarakteristik test.
//
// MAQSAD: `findFreeProducts` + `useBuyXGetXProducts` hozirgi xatti-harakatini
// MUZLATISH. Faza 4 da ko'chirilishi kerak, shu paytgacha testsiz edi.
//
// Buy X Get Y dan farqi: bu yerda tekin beriladigan mahsulot sotib
// olinadigan mahsulotning O'ZI (masalan "3 olsang 1 tekin").
//
// Shart (DiscountHelpers._getBuyXGetXAsGift, forDialogOnly=true):
//   totalQty + 1 >= buyProductsAmount
// Qo'llash (useBuyXGetXProducts):
//   setSize = buy + get; totalQty >= setSize bo'lsa tekin beriladi
//   isRepeatable=true  -> nechta to'liq set bo'lsa shuncha
//   isRepeatable=false -> faqat bitta set
//
// MUHIM: "to'g'rimi?" emas, "hozir nima bo'lyapti?" yoziladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_discounts/model/discounts_response.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStoreId = 'shop-1';
const kProdId = 'suv-id';

const gGroupBuyXGetX = '316b623e-3bb7-43e2-b6d5-1028c927caba';
const gTypeBuyXGetX = '90d1f774-44bd-49be-9bbf-2e9a44558377';

ItemModel productWithPrice(String id, String name, num retailPrice) {
  final m = ItemModel();
  m.id = id;
  m.name = name;
  m.shopPrices = ShopPrices(
    shID: ShID(
      shopId: kStoreId,
      shopPriceTiers: [ShopPriceTiers(minQuantity: 1, retailPrice: retailPrice)],
    ),
  );
  return m;
}

DiscountItem buyXGetXDiscount({
  required int buyAmount,
  required int getAmount,
  bool isRepeatable = false,
}) {
  return DiscountItem(
    id: 'bxgx-1',
    name: 'Buy X Get X',
    displayName: '3 olsang 1 tekin',
    discountGroupType: DiscountGroupType(id: gGroupBuyXGetX),
    discountType: DiscountType(id: gTypeBuyXGetX),
    isExpirable: false,
    isForAllClients: true,
    isRepeatable: isRepeatable,
    shopIds: [ShopIds(id: kStoreId)],
    buyXGetX: BuyXGetX(
      productsToBuy: [ProductsToBuy(id: kProdId, name: 'Suv')],
      buyProductsAmount: buyAmount,
      getProductsAmount: getAmount,
    ),
  );
}

Future<void> seed(List<DiscountItem> discounts) async {
  final box = HiveBoxes.getDiscounts();
  await box.clear();
  await box.addAll(discounts);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('discount_bxgx_test');
    await Pref.setString(PrefKeys.storeId, kStoreId);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [productWithPrice(kProdId, 'Suv 1L', 5000)];
  });

  tearDown(() => HiveBoxes.getDiscounts().clear());

  OrderingProvider4 cart(double qty, {double price = 5000}) {
    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(
      makeSoldItem(productId: kProdId, name: 'Suv 1L', price: price, value: qty),
    );
    return p;
  }

  ReceiptModelSoldItem4 row(OrderingProvider4 p) =>
      p.getCurrentClient.orderedProducts.firstWhere((e) => e.productId == kProdId);

  group('Diskont yo\'q holati', () {
    test('box bo\'sh: narx o\'zgarmaydi', () async {
      await seed([]);
      final p = cart(4);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      expect(row(p).price, 5000);
      expect(row(p).singleDiscount, 0);
    });
  });

  group('3 olsang 1 tekin (buy=3, get=1) — takrorlanmaydigan', () {
    test('4 dona: 1 tasi tekin -> narx 3/4 ga tushadi', () async {
      await seed([buyXGetXDiscount(buyAmount: 3, getAmount: 1)]);
      final p = cart(4);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // setSize = 4, totalQty = 4 -> freeQty = 1, paid = 3, ratio = 3/4
      expect(row(p).price, 5000 * 0.75);
      expect(row(p).discountPercent, 25);
    });

    test('3 dona (setSize=4 dan kam): tekin berilmaydi', () async {
      await seed([buyXGetXDiscount(buyAmount: 3, getAmount: 1)]);
      final p = cart(3);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      expect(row(p).price, 5000);
      expect(row(p).singleDiscount, 0);
    });

    test('8 dona: takrorlanmagani uchun baribir 1 ta tekin', () async {
      await seed([buyXGetXDiscount(buyAmount: 3, getAmount: 1)]);
      final p = cart(8);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // isRepeatable=false -> faqat bitta set: 8 dan 1 tasi tekin
      expect(row(p).price, 5000 * (7 / 8));
      expect(row(p).discountPercent, closeTo(12.5, 0.001));
    });

    test('productDiscount yozuvi "Buy X Get X" nomi bilan', () async {
      await seed([buyXGetXDiscount(buyAmount: 3, getAmount: 1)]);
      final p = cart(4);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      expect(row(p).productDiscount, isNotEmpty);
      expect(row(p).productDiscount.first.typeName, 'Buy X Get X');
    });
  });

  group('Takrorlanadigan (isRepeatable = true)', () {
    test('8 dona: 2 ta set -> 2 tasi tekin', () async {
      await seed(
          [buyXGetXDiscount(buyAmount: 3, getAmount: 1, isRepeatable: true)]);
      final p = cart(8);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // setSize = 4, 8/4 = 2 set -> 2 tekin, paid = 6, ratio = 6/8
      expect(row(p).price, 5000 * 0.75);
      expect(row(p).discountPercent, 25);
    });

    test('to\'liq bo\'lmagan set hisobga kirmaydi (7 dona -> 1 tekin)',
        () async {
      await seed(
          [buyXGetXDiscount(buyAmount: 3, getAmount: 1, isRepeatable: true)]);
      final p = cart(7);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // 7/4 = 1 to'liq set -> 1 tekin, paid = 6, ratio = 6/7
      expect(row(p).price, closeTo(5000 * (6 / 7), 0.001));
    });
  });

  group('Chetki holatlar', () {
    test('mahsulot savatda yo\'q: xato bermaydi', () async {
      await seed([buyXGetXDiscount(buyAmount: 3, getAmount: 1)]);
      final p = freshProvider();

      expect(() {
        p.findFreeProducts();
        p.useBuyXGetXProducts();
      }, returnsNormally);
    });

    test('qo\'lda narx o\'zgartirilgan qatorga tegilmaydi', () async {
      await seed([buyXGetXDiscount(buyAmount: 3, getAmount: 1)]);
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(
          productId: kProdId, price: 5000, value: 4, isPriceOnlyChanged: true));

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      expect(row(p).price, 5000);
    });
  });

  group('clearAllDiscountEffects', () {
    test('tekin ulush bekor qilinadi', () async {
      await seed([buyXGetXDiscount(buyAmount: 3, getAmount: 1)]);
      final p = cart(4);
      p.findFreeProducts();
      p.useBuyXGetXProducts();

      p.clearAllDiscountEffects();

      expect(row(p).price, row(p).realPrice);
      expect(row(p).singleDiscount, 0);
      expect(row(p).productDiscount, isEmpty);
    });
  });
}
