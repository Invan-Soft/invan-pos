// Buy X Get Y (tekin mahsulot) oqimi — xarakteristik test.
//
// MAQSAD: `findFreeProducts` + `useFreeProducts` hozirgi xatti-harakatini
// MUZLATISH. Bu metodlar Faza 4 da ko'chiriladi, lekin shu paytgacha
// UMUMAN test bilan qoplanmagan edi (discount_apply_test faqat
// DiscountSingleton.addDiscountOnProduct ni tekshiradi — u boshqa fayl).
//
// Oqim:
//   findFreeProducts() -> DiscountSingleton.buyXGetYOrFreeGifts(...)
//     -> _returnedProducts to'ladi
//   useFreeProducts()  -> savat qatorlariga tekin ulush qo'llanadi
//
// MUHIM: "to'g'rimi?" emas, "hozir nima bo'lyapti?" yoziladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_discounts/model/discounts_response.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStoreId = 'shop-1';
const kBuyId = 'coca-id'; // sotib olinadigan
const kGetId = 'chips-id'; // tekin beriladigan

// Buy X Get Y uchun qat'iy GUIDlar (discount_helpers.dart dan).
const gGroupBuyXGetY = '86951e75-960f-45d7-9505-9b9cd2ce17a7';
const gTypeBuyXGetY = 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b';

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

DiscountItem buyXGetYDiscount({
  required int buyAmount,
  required int getAmount,
  String buyId = kBuyId,
  String getId = kGetId,
  bool isRepeatable = false,
}) {
  return DiscountItem(
    id: 'bxgy-1',
    name: 'Buy X Get Y',
    displayName: '2 olsang 1 tekin',
    discountGroupType: DiscountGroupType(id: gGroupBuyXGetY),
    discountType: DiscountType(id: gTypeBuyXGetY),
    isExpirable: false,
    isForAllClients: true,
    isRepeatable: isRepeatable,
    shopIds: [ShopIds(id: kStoreId)],
    buyXGetY: BuyXGetY(
      productsToBuy: [ProductsToBuy(id: buyId, name: 'Coca')],
      buyProductsAmount: buyAmount,
      productToGet: ProductsToGet(id: getId, name: 'Chips'),
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
    await setUpPosTestEnv('discount_free_products_test');
    await Pref.setString(PrefKeys.storeId, kStoreId);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [
      productWithPrice(kBuyId, 'Coca 1L', 12000),
      productWithPrice(kGetId, 'Chips', 6000),
    ];
  });

  tearDown(() => HiveBoxes.getDiscounts().clear());

  /// Savatga "sotib olinadigan" va "tekin" qatorlarni qo'yadi.
  OrderingProvider4 cartWith({
    required double buyQty,
    required double getQty,
  }) {
    final p = freshProvider();
    if (buyQty > 0) {
      p.getCurrentClient.orderedProducts.add(
        makeSoldItem(productId: kBuyId, name: 'Coca 1L', price: 12000,
            value: buyQty),
      );
    }
    if (getQty > 0) {
      p.getCurrentClient.orderedProducts.add(
        makeSoldItem(productId: kGetId, name: 'Chips', price: 6000,
            value: getQty),
      );
    }
    return p;
  }

  group('Diskont yo\'q holati', () {
    test('box bo\'sh: useFreeProducts savatni o\'zgartirmaydi', () async {
      await seed([]);
      final p = cartWith(buyQty: 2, getQty: 1);

      p.findFreeProducts();
      p.useFreeProducts();

      final chips =
          p.getCurrentClient.orderedProducts.firstWhere((e) => e.productId == kGetId);
      expect(chips.price, 6000);
      expect(chips.singleDiscount, 0);
    });
  });

  group('Buy 2 Get 1 — shart bajarilgan', () {
    test('tekin mahsulot narxi 0 ga tushadi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = cartWith(buyQty: 2, getQty: 1);

      p.findFreeProducts();
      p.useFreeProducts();

      final chips = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGetId);
      expect(chips.price, 0);
      expect(chips.discountPercent, 100);
    });

    test('sotib olinadigan mahsulotga tegilmaydi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = cartWith(buyQty: 2, getQty: 1);

      p.findFreeProducts();
      p.useFreeProducts();

      final coca = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kBuyId);
      expect(coca.price, 12000);
      expect(coca.singleDiscount, 0);
    });

    test('tekin qatorga productDiscount yozuvi qo\'shiladi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = cartWith(buyQty: 2, getQty: 1);

      p.findFreeProducts();
      p.useFreeProducts();

      final chips = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGetId);
      expect(chips.productDiscount, isNotEmpty);
      expect(chips.productDiscount.first.typeName, 'Buy X Get Y');
    });
  });

  group('Shart bajarilmagan', () {
    test('1 dona olingan (2 kerak): tekin berilmaydi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = cartWith(buyQty: 1, getQty: 1);

      p.findFreeProducts();
      p.useFreeProducts();

      final chips = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGetId);
      expect(chips.price, chips.realPrice);
      expect(chips.singleDiscount, 0);
    });

    test('tekin mahsulot savatda yo\'q: xato bermaydi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = cartWith(buyQty: 2, getQty: 0);

      expect(() {
        p.findFreeProducts();
        p.useFreeProducts();
      }, returnsNormally);
      expect(p.getCurrentClient.orderedProducts.length, 1);
    });
  });

  group('Qisman tekin (qty tekin sondan katta)', () {
    test('2 dona chips, 1 tasi tekin -> narx yarmiga tushadi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = cartWith(buyQty: 2, getQty: 2);

      p.findFreeProducts();
      p.useFreeProducts();

      final chips = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGetId);
      // 2 donadan 1 tasi tekin -> ratio = 1/2
      expect(chips.price, chips.realPrice * 0.5);
      expect(chips.discountPercent, 50);
    });
  });

  group('Qo\'lda narx o\'zgartirilgan qator (isPriceOnlyChanged)', () {
    test('tekin hisobga kirmaydi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.addAll([
        makeSoldItem(productId: kBuyId, price: 12000, value: 2),
        makeSoldItem(
            productId: kGetId, price: 6000, value: 1, isPriceOnlyChanged: true),
      ]);

      p.findFreeProducts();
      p.useFreeProducts();

      final chips = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGetId);
      // Qo'lda tuzatilgan narx saqlanadi — tekin qilinmaydi
      expect(chips.price, 6000);
    });
  });

  group('clearAllDiscountEffects — tekin ulushni bekor qiladi', () {
    test('narx asl holatiga qaytadi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = cartWith(buyQty: 2, getQty: 1);
      p.findFreeProducts();
      p.useFreeProducts();

      p.clearAllDiscountEffects();

      final chips = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGetId);
      expect(chips.price, chips.realPrice);
      expect(chips.singleDiscount, 0);
      expect(chips.productDiscount, isEmpty);
    });
  });

  group('notifyListeners', () {
    test('useFreeProducts listenerni uyg\'otadi', () async {
      await seed([buyXGetYDiscount(buyAmount: 2, getAmount: 1)]);
      final p = cartWith(buyQty: 2, getQty: 1);
      p.findFreeProducts();

      var notified = 0;
      p.addListener(() => notified++);
      p.useFreeProducts();

      expect(notified, greaterThan(0));
    });
  });
}
