// Free Gift (summadan oshsa sovg'a) oqimi — xarakteristik test.
//
// MAQSAD: `findFreeProducts` + `useFreeGiftProducts` hozirgi xatti-harakatini
// MUZLATISH. Faza 4 da ko'chirilishi kerak, shu paytgacha testsiz edi.
//
// Free Gift shartlari (DiscountHelpers._getFreeGift):
//   buyAmount > _maxPrice  VA  buyAmount < totalPrice
//   (_maxPrice har `findFreeProducts()` da 0 ga tushadi)
//   totalPrice = savatdagi sum(price × value)
//
// Sovg'a berish sharti (useFreeGiftProducts):
//   nonGiftTotal + giftProductInCartValue - freeValue >= buyAmount
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
const kMainId = 'main-id'; // oddiy xarid
const kGiftId = 'gift-id'; // sovg'a mahsulot
const kGift2Id = 'gift2-id'; // pastki bosqich sovg'asi

const gGroupFreeGift = 'e13e3ed0-2d03-42f2-8c5f-43bcb3b3c8e9';

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

DiscountItem freeGiftDiscount({
  required int buyAmount,
  required int getProductAmount,
  String giftId = kGiftId,
  String id = 'fg-1',
}) {
  return DiscountItem(
    id: id,
    name: 'Free Gift',
    displayName: '100 mingdan oshsa sovg\'a',
    discountGroupType: DiscountGroupType(id: gGroupFreeGift),
    discountType: DiscountType(id: 'fg-type'),
    isExpirable: false,
    isForAllClients: true,
    shopIds: [ShopIds(id: kStoreId)],
    gifts: [
      Gifts(
        buyAmount: buyAmount,
        getProductAmount: getProductAmount,
        getProduct: ProductIds(id: giftId, name: 'Sovg\'a'),
      ),
    ],
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
    await setUpPosTestEnv('discount_free_gift_test');
    await Pref.setString(PrefKeys.storeId, kStoreId);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [
      productWithPrice(kMainId, 'Asosiy tovar', 50000),
      productWithPrice(kGiftId, 'Sovg\'a', 10000),
      productWithPrice(kGift2Id, 'Sovg\'a 2', 6000),
    ];
  });

  tearDown(() => HiveBoxes.getDiscounts().clear());

  OrderingProvider4 cart({
    required double mainQty,
    double giftQty = 0,
    double mainPrice = 50000,
    double giftPrice = 10000,
  }) {
    final p = freshProvider();
    if (mainQty > 0) {
      p.getCurrentClient.orderedProducts.add(makeSoldItem(
          productId: kMainId, name: 'Asosiy', price: mainPrice, value: mainQty));
    }
    if (giftQty > 0) {
      p.getCurrentClient.orderedProducts.add(makeSoldItem(
          productId: kGiftId, name: 'Sovg\'a', price: giftPrice, value: giftQty));
    }
    return p;
  }

  group('Diskont yo\'q holati', () {
    test('box bo\'sh: sovg\'a berilmaydi', () async {
      await seed([]);
      final p = cart(mainQty: 3, giftQty: 1);

      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, 10000);
    });
  });

  group('Threshold oshgan — sovg\'a beriladi', () {
    test('150k xarid, 100k shart: sovg\'a tekin bo\'ladi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      // asosiy 3×50000 = 150000, sovg'a 1×10000
      final p = cart(mainQty: 3, giftQty: 1);

      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, 0);
      expect(gift.discountPercent, 100);
      expect(gift.singleDiscount, 10000);
    });

    test('asosiy tovarga tegilmaydi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = cart(mainQty: 3, giftQty: 1);

      p.findFreeProducts();
      p.useFreeGiftProducts();

      final main = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kMainId);
      expect(main.price, 50000);
      expect(main.singleDiscount, 0);
    });

    test('sovg\'a qatoriga productDiscount yozuvi qo\'shiladi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = cart(mainQty: 3, giftQty: 1);

      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGiftId);
      expect(gift.productDiscount, isNotEmpty);
    });
  });

  group('Threshold oshmagan — sovg\'a berilmaydi', () {
    test('50k xarid, 100k shart: sovg\'a to\'liq narxda qoladi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      // asosiy 1×50000 = 50000 < 100000
      final p = cart(mainQty: 1, giftQty: 1);

      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, gift.realPrice);
      expect(gift.singleDiscount, 0);
    });
  });

  group('Sovg\'a kvotasi (getProductAmount)', () {
    test('2 dona sovg\'a savatda, 1 tasi tekin -> narx yarmiga', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = cart(mainQty: 3, giftQty: 2);

      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGiftId);
      // 2 donadan 1 tasi tekin
      expect(gift.price, gift.realPrice * 0.5);
      expect(gift.discountPercent, 50);
    });
  });

  group('Chetki holatlar', () {
    test('sovg\'a mahsulot savatda yo\'q: xato bermaydi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = cart(mainQty: 3);

      expect(() {
        p.findFreeProducts();
        p.useFreeGiftProducts();
      }, returnsNormally);
      expect(p.getCurrentClient.orderedProducts.length, 1);
    });

    test('qo\'lda narx o\'zgartirilgan sovg\'a qatoriga tegilmaydi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.addAll([
        makeSoldItem(productId: kMainId, price: 50000, value: 3),
        makeSoldItem(
            productId: kGiftId,
            price: 10000,
            value: 1,
            isPriceOnlyChanged: true),
      ]);

      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, 10000);
    });

    test('bo\'sh savat: xato bermaydi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = freshProvider();

      expect(() {
        p.findFreeProducts();
        p.useFreeGiftProducts();
      }, returnsNormally);
    });
  });

  group('clearAllDiscountEffects', () {
    test('sovg\'a bekor qilinadi, narx asl holatiga qaytadi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = cart(mainQty: 3, giftQty: 1);
      p.findFreeProducts();
      p.useFreeGiftProducts();

      p.clearAllDiscountEffects();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, gift.realPrice);
      expect(gift.singleDiscount, 0);
      expect(gift.productDiscount, isEmpty);
    });
  });

  // Regressiya: sovg'a bergan shart buzilgach sovg'a qatori to'liq narxga
  // qaytishi kerak.
  //
  // Eng nozik holat — bir nechta Free Gift bosqichi: eski kodda bekor qilish
  // faqat `returnedFreeGiftProducts` TO'LIQ bo'sh bo'lgandagina ishlardi.
  // Pastki bosqich hali amal qilib turgan bo'lsa ro'yxat bo'sh bo'lmasdi va
  // yuqori bosqichning sovg'asi tekinligicha qolib ketardi.
  group('Shart buzilgach sovg\'a bekor bo\'ladi', () {
    test('diskont bazadan o\'chirilsa sovg\'a pulli bo\'ladi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = cart(mainQty: 3, giftQty: 1);
      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, 0, reason: 'setup: sovg\'a tekin');

      await seed([]);
      p.findFreeProducts();
      p.useFreeGiftProducts();

      expect(gift.price, gift.realPrice);
      expect(gift.singleDiscount, 0);
    });

    test('asosiy tovar savatdan chiqarilsa sovg\'a pulli bo\'ladi', () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = cart(mainQty: 3, giftQty: 1);
      p.findFreeProducts();
      p.useFreeGiftProducts();

      final rows = p.getCurrentClient.orderedProducts;
      expect(rows.firstWhere((e) => e.productId == kGiftId).price, 0);

      rows.removeWhere((e) => e.productId == kMainId);
      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = rows.firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, gift.realPrice);
    });

    test('red-delete: asosiy tovar o\'chirilsa sovg\'a pulli bo\'ladi',
        () async {
      await seed([freeGiftDiscount(buyAmount: 100000, getProductAmount: 1)]);
      final p = cart(mainQty: 3, giftQty: 1);
      p.findFreeProducts();
      p.useFreeGiftProducts();

      final rows = p.getCurrentClient.orderedProducts;
      expect(rows.firstWhere((e) => e.productId == kGiftId).price, 0);

      rows.firstWhere((e) => e.productId == kMainId).isDeleted = true;
      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = rows.firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, gift.realPrice);
    });

    test('ikki bosqich: yuqori bosqich tushib qolsa o\'sha sovg\'a pulli bo\'ladi',
        () async {
      await seed([
        freeGiftDiscount(
            id: 'fg-low', giftId: kGift2Id, buyAmount: 50000,
            getProductAmount: 1),
        freeGiftDiscount(
            id: 'fg-high', giftId: kGiftId, buyAmount: 100000,
            getProductAmount: 1),
      ]);
      final p = freshProvider();
      final rows = p.getCurrentClient.orderedProducts;
      rows.add(makeSoldItem(productId: kMainId, price: 50000, value: 3));
      rows.add(makeSoldItem(productId: kGift2Id, price: 6000, value: 1));
      rows.add(makeSoldItem(productId: kGiftId, price: 10000, value: 1));

      p.findFreeProducts();
      p.useFreeGiftProducts();
      expect(rows.firstWhere((e) => e.productId == kGiftId).price, 0,
          reason: 'setup: yuqori bosqich sovg\'asi tekin');

      // 150k -> 50k: yuqori bosqich (100k) endi qondirilmaydi,
      // pastki bosqich (50k) hali ham amalda -> ro'yxat BO'SH EMAS.
      rows.firstWhere((e) => e.productId == kMainId).value = 1;
      p.findFreeProducts();
      p.useFreeGiftProducts();

      final gift = rows.firstWhere((e) => e.productId == kGiftId);
      expect(gift.price, gift.realPrice,
          reason: 'yuqori bosqich shartlari buzildi — sovg\'a pulli');
    });
  });
}
