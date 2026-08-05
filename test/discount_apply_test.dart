// Diskont qo'llash matematikasi — xarakteristik test.
//
// MAQSAD: `DiscountSingleton.addDiscountOnProduct` hozirgi xatti-harakatini
// MUZLATISH. Bu savatga mahsulot qo'shilganda `_applyDiscounts` chaqiradigan
// haqiqiy hisob — POS'dagi eng ko'p bug chiqqan joy.
//
// Bu zona Faza 0-3 da KO'CHIRILMAYDI. Testlar kundalik bug-fix ishlarini
// himoya qilish va kelajakdagi Faza 4 (diskont ajratish) uchun poydevor.
//
// MUHIM: "to'g'rimi?" emas, "hozir nima bo'lyapti?" yoziladi.
//
// Diskont amal qilishi uchun (DiscountHelpers._checkOptions):
//   1) isExpirable = false  -> sana tekshiruvi o'tkazib yuboriladi
//   2) shopIds joriy storeId ni o'z ichiga olishi shart
//   3) isForAllClients = true  (yoki customerGroups mijoz guruhiga mos)
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/singletons/discounts/discount_singleton.dart';
import 'package:invan2/features/get_discounts/model/discounts_response.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStoreId = 'shop-1';
const kProductId = 'pepsi-id';
const kClientGroupId = 'vip-group';

// Diskont tizimidagi qat'iy GUIDlar (discount_helpers.dart dan).
const gGroupProduct = '22e778e1-e562-4649-b47e-b720a28d831c';
const gGroupCategory = '847808d6-5113-4235-a5aa-f5edb044f837';
const gTypePercentage = 'e908c52f-4c6f-46d8-b765-16e074425cd9';
const gTypeNumeric = 'b78fd1a6-38ed-45a6-b002-caac5de6ebe6';

DiscountItem discount({
  required String groupTypeId,
  required String typeId,
  required int value,
  bool isAllProducts = true,
  List<String> productIds = const [],
  bool isForAllClients = true,
  List<String> customerGroups = const [],
  String storeId = kStoreId,
}) {
  return DiscountItem(
    name: 'Test diskont',
    displayName: 'Test diskont',
    discountGroupType: DiscountGroupType(id: groupTypeId),
    discountType: DiscountType(id: typeId),
    discountValue: value,
    isExpirable: false,
    isAllProducts: isAllProducts,
    productIds: productIds.map((e) => ProductIds(id: e)).toList(),
    isForAllClients: isForAllClients,
    customerGroups: customerGroups.map((e) => CustomerGroups(id: e)).toList(),
    shopIds: [ShopIds(id: storeId)],
  );
}

Future<void> seedDiscounts(List<DiscountItem> items) async {
  final box = HiveBoxes.getDiscounts();
  await box.clear();
  await box.addAll(items);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('discount_apply_test');
    await Pref.setString(PrefKeys.storeId, kStoreId);
  });
  tearDownAll(tearDownPosTestEnv);

  tearDown(() => HiveBoxes.getDiscounts().clear());

  group('Diskont yo\'q holati', () {
    test('box bo\'sh: narx asl holida qoladi, diskont tozalanadi', () async {
      await seedDiscounts([]);
      final item = makeSoldItem(price: 5000, realPrice: 5000);
      item.singleDiscount = 999; // eski qoldiq

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 5000);
      expect(r.singleDiscount, 0);
      expect(r.discountPercent, 0);
      expect(r.productDiscount, isEmpty);
    });
  });

  group('Mahsulot foizli diskonti (%)', () {
    test('10% chegirma: 5000 -> 4500', () async {
      await seedDiscounts([
        discount(
            groupTypeId: gGroupProduct, typeId: gTypePercentage, value: 10),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000, value: 1);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 4500);
      expect(r.singleDiscount, 500);
      expect(r.discountPercent, closeTo(10, 0.001));
    });

    test('0% chegirma: narx o\'zgarmaydi', () async {
      await seedDiscounts([
        discount(groupTypeId: gGroupProduct, typeId: gTypePercentage, value: 0),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 5000);
      expect(r.singleDiscount, 0);
    });

    test('100% chegirma: narx 0 ga tushadi', () async {
      await seedDiscounts([
        discount(
            groupTypeId: gGroupProduct, typeId: gTypePercentage, value: 100),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 0);
      expect(r.singleDiscount, 5000);
      expect(r.discountPercent, 100);
    });

    test('productDiscount ro\'yxatiga yozuv qo\'shiladi', () async {
      await seedDiscounts([
        discount(
            groupTypeId: gGroupProduct, typeId: gTypePercentage, value: 10),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.productDiscount, isNotEmpty);
    });
  });

  group('Mahsulot summali diskonti (numeric)', () {
    test('1000 so\'m chegirma: 5000 -> 4000', () async {
      await seedDiscounts([
        discount(
            groupTypeId: gGroupProduct, typeId: gTypeNumeric, value: 1000),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000, value: 1);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 4000);
      expect(r.singleDiscount, 1000);
    });

    test('chegirma narxdan katta: narx 0, butun narx chegirma sifatida',
        () async {
      await seedDiscounts([
        discount(
            groupTypeId: gGroupProduct, typeId: gTypeNumeric, value: 9000),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000, value: 1);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 0);
      expect(r.singleDiscount, 5000);
    });
  });

  group('isAllProducts = false — faqat ro\'yxatdagi mahsulotga', () {
    test('mahsulot ro\'yxatda: chegirma qo\'llanadi', () async {
      await seedDiscounts([
        discount(
          groupTypeId: gGroupProduct,
          typeId: gTypePercentage,
          value: 20,
          isAllProducts: false,
          productIds: [kProductId],
        ),
      ]);
      final item =
          makeSoldItem(productId: kProductId, price: 5000, realPrice: 5000);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 4000);
    });

    test('mahsulot ro\'yxatda YO\'Q: chegirma qo\'llanmaydi', () async {
      await seedDiscounts([
        discount(
          groupTypeId: gGroupProduct,
          typeId: gTypePercentage,
          value: 20,
          isAllProducts: false,
          productIds: ['boshqa-mahsulot'],
        ),
      ]);
      final item =
          makeSoldItem(productId: kProductId, price: 5000, realPrice: 5000);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 5000);
      expect(r.singleDiscount, 0);
    });
  });

  group('Mijoz guruhi bo\'yicha cheklov', () {
    test('faqat VIP guruhga: mos mijozda qo\'llanadi', () async {
      await seedDiscounts([
        discount(
          groupTypeId: gGroupProduct,
          typeId: gTypePercentage,
          value: 10,
          isForAllClients: false,
          customerGroups: [kClientGroupId],
        ),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000);

      final r =
          DiscountSingleton.addDiscountOnProduct(item, '', kClientGroupId);

      expect(r.price, 4500);
    });

    test('faqat VIP guruhga: mijozsiz (bo\'sh guruh) qo\'llanmaydi', () async {
      await seedDiscounts([
        discount(
          groupTypeId: gGroupProduct,
          typeId: gTypePercentage,
          value: 10,
          isForAllClients: false,
          customerGroups: [kClientGroupId],
        ),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 5000);
    });
  });

  group('Do\'kon (shopId) bo\'yicha cheklov', () {
    test('boshqa do\'kon diskonti qo\'llanmaydi', () async {
      await seedDiscounts([
        discount(
          groupTypeId: gGroupProduct,
          typeId: gTypePercentage,
          value: 50,
          storeId: 'boshqa-dokon',
        ),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      expect(r.price, 5000);
    });
  });

  group('Bir nechta diskont ketma-ket', () {
    test('10% + 1000 so\'m: ketma-ket qo\'llanadi', () async {
      await seedDiscounts([
        discount(
            groupTypeId: gGroupProduct, typeId: gTypePercentage, value: 10),
        discount(
            groupTypeId: gGroupProduct, typeId: gTypeNumeric, value: 1000),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000, value: 1);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      // 5000 -> 4500 (10%) -> 3500 (-1000)
      expect(r.price, 3500);
      expect(r.singleDiscount, 1500);
    });
  });

  group('Miqdor (value) ta\'siri', () {
    test('value > 1 bo\'lsa singleDiscount YIG\'ILMAYDI (narx esa tushadi)',
        () async {
      await seedDiscounts([
        discount(
            groupTypeId: gGroupProduct, typeId: gTypePercentage, value: 10),
      ]);
      final item = makeSoldItem(price: 5000, realPrice: 5000, value: 3);

      final r = DiscountSingleton.addDiscountOnProduct(item, '', '');

      // Hozirgi xatti-harakat: singleDiscount faqat value == 1 da to'ldiriladi
      expect(r.price, 4500);
      expect(r.singleDiscount, 0);
    });
  });
}
