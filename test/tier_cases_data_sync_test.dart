// Pog'onali narx — ma'lumot va sinxron (notification) chekka holatlari.
//
// Tekshiriladigan tuzatish (2026-10-08, "Saryog' Lora 200gr"):
//   * `useFreeProducts` qimmat pog'onani 1-talikka qaytarmaydi;
//   * `onePrice` eng kichik `minQuantity` li pog'onani oladi (tiers[0] emas);
//   * `ShopPriceTiersSub.fromJson` `min_quantity`/`retail_price` ni int /
//     double / satr ko'rinishida xavfsiz o'qiydi.
//
// Bu fayl ma'lumot shakli (tartibsiz, dublikat, null/0 pog'ona, satr/double
// JSON) va type 13 notification → Hive → kassa savati zanjirini tekshiradi.
// Prod sozlamasi: Buy X Get Y, o'sha mahsulotning o'zi, 1 olsa 1 tekin,
// repeatable; 1 ta → 25 000, 7+ ta → 27 000. Tekin = floor(n / 2).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/product_price_edit_response.dart';
import 'package:invan2/changes/singletons/discounts/discount_singleton.dart';
import 'package:invan2/features/get_discounts/model/discounts_response.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

import 'support/provider_harness.dart';

const kShop = 'shop-1';
const kOtherShop = 'shop-2';
const kPid = 'lora-id';
const kBarcode = '4780000000777';

// Buy X Get Y uchun qat'iy GUIDlar (discount_helpers.dart dan).
const gGroupBuyXGetY = '86951e75-960f-45d7-9505-9b9cd2ce17a7';
const gTypeBuyXGetY = 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b';

ShopPriceTiers t(int? q, num? p) =>
    ShopPriceTiers(minQuantity: q, retailPrice: p);

ShopPrices pricesOf(List<ShopPriceTiers> tiers, {String shop = kShop}) =>
    ShopPrices(
      shID: ShID(shopId: shop, supplyPrice: 20000, shopPriceTiers: tiers),
    );

/// Har chaqiruvda YANGI obyekt — HiveObject bir nechta box'ga/qayta
/// yozilganda xato bermasligi uchun.
ItemModel lora(List<ShopPriceTiers> tiers) {
  final m = ItemModel();
  m.id = kPid;
  m.name = 'Saryog\' Lora 200gr';
  m.sku = '1';
  m.isActive = true;
  m.isMarking = false;
  m.barcode = [kBarcode];
  m.packageCode = 'PACK-1';
  m.vat = Vat(percentage: 12);
  m.measurementUnit = MeasurementUnit(shortName: 'dona');
  m.shopPrices = pricesOf(tiers);
  return m;
}

/// Prod'dagi aniq aksiya: o'zi uchun 1 olsa 1 tekin, repeatable.
DiscountItem prodDiscount() => DiscountItem(
      id: 'bxgy-lora',
      name: 'Buy X Get Y',
      displayName: 'Buy X Get Y',
      discountGroupType: DiscountGroupType(id: gGroupBuyXGetY),
      discountType: DiscountType(id: gTypeBuyXGetY),
      isExpirable: false,
      isForAllClients: true,
      isRepeatable: true,
      shopIds: [ShopIds(id: kShop)],
      buyXGetY: BuyXGetY(
        productsToBuy: [ProductsToBuy(id: kPid, name: 'Lora')],
        buyProductsAmount: 1,
        productToGet: ProductsToGet(id: kPid, name: 'Lora'),
        getProductsAmount: 1,
      ),
    );

/// type 13 notification (server shakli).
ProductPriceEdit priceEdit(List<Map<String, dynamic>> tiers,
        {String shop = kShop, String pid = kPid}) =>
    ProductPriceEdit.fromJson(<String, dynamic>{
      'id': 'n-$pid-$shop',
      'type': 13,
      'data': <String, dynamic>{
        'product_values': [
          <String, dynamic>{
            'product_id': pid,
            'price': <String, dynamic>{
              'shop_id': shop,
              'retail_price': 25000,
              'supply_price': 20000,
              'shop_price_tiers': tiers,
            },
          },
        ],
      },
    });

Map<String, dynamic> j(dynamic q, dynamic p) =>
    <String, dynamic>{'min_quantity': q, 'retail_price': p};

/// `addProduct` ichida `AppNavigation.navigatorKey.currentContext` o'qiladi.
Future<BuildContext> appContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    navigatorKey: AppNavigation.navigatorKey,
    locale: const Locale('uz'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: (c) {
      captured = c;
      SizeConfig().init(c);
      return const SizedBox();
    })),
  ));
  return captured;
}

Future<void> scan(WidgetTester tester, BuildContext ctx, OrderingProvider4 p,
    {double value = 1}) async {
  p.addProduct(
      value: value,
      product: ItemsSingleton.getProductById(kPid)!,
      where: 'test',
      context: ctx);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // "Aksiya bor" dialogini kassir kabi yopamiz.
  final ok = find.text('Ok');
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<OrderingProvider4> sellOneByOne(
    WidgetTester tester, BuildContext ctx, int n) async {
  final p = freshProvider();
  for (int i = 0; i < n; i++) {
    await scan(tester, ctx, p);
  }
  return p;
}

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

/// Hive'ga mahsulotni yozadi (+ ixtiyoriy prod aksiyasi) va keshni yangilaydi.
/// testWidgets ichida real IO faqat runAsync orqali.
Future<void> seed(WidgetTester tester, List<ShopPriceTiers> tiers,
    {bool withDiscount = true}) async {
  await tester.runAsync(() async {
    final box = HiveBoxes.getProducts();
    await box.clear();
    await box.put(kPid, lora(tiers));
    if (withDiscount) {
      await HiveBoxes.getDiscounts().add(prodDiscount());
    }
    await ItemsSingleton.storeProducts();
  });
}

/// Notification'ni qo'llaydi (ProductsWsService type 13 bilan bir xil:
/// editItem + oyna oxirida storeProducts).
Future<int> applyEdit(WidgetTester tester, ProductPriceEdit e) async {
  final changed = await tester.runAsync(() async {
    final c = await ItemsSingleton.editItem(e);
    await ItemsSingleton.storeProducts();
    return c;
  });
  return changed ?? -1;
}

/// Prod qoidasi bo'yicha kutilgan qator summasi: dona narx × to'lanadigan son.
double expectedLine(int n, {num tierFrom = 7}) {
  final unit = n >= tierFrom ? 27000.0 : 25000.0;
  return unit * (n - n ~/ 2);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('tier_cases_data_sync_test');
    await Pref.setString(PrefKeys.storeId, kShop);

    void reg<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
    }

    reg(ItemModelAdapter().typeId, ItemModelAdapter());
    reg(ShopPricesAdapter().typeId, ShopPricesAdapter());
    reg(ShIDAdapter().typeId, ShIDAdapter());
    reg(ShopPriceTiersAdapter().typeId, ShopPriceTiersAdapter());
    reg(CategoriesFromProductsAdapter().typeId,
        CategoriesFromProductsAdapter());
    reg(MeasurementUnitAdapter().typeId, MeasurementUnitAdapter());
    reg(VatAdapter().typeId, VatAdapter());
    await Hive.openBox<ItemModel>(HiveBoxNames.items);
  });
  tearDownAll(tearDownPosTestEnv);

  // testWidgets ichida Hive IO kutilsa osilib qoladi — sozlash shu yerda.
  setUp(() async {
    await Pref.setString(PrefKeys.storeId, kShop);
    await Pref.setBool(PrefKeys.markCheckWithOfd, false);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
    await HiveBoxes.getDiscounts().clear();
    await HiveBoxes.getProducts().clear();
    DiscountSingleton.resetAll();
    ItemsSingleton.clearTheProducts();
  });

  // ---------------------------------------------------------------------
  group('onePrice — ma\'lumot chekka holatlari', () {
    test('tartibsiz [7 → 27 000, 1 → 25 000] → 25 000 (1-talik narx)', () {
      final m = lora([t(7, 27000), t(1, 25000)]);
      expect(ItemsSingleton.onePrice(m.shopPrices), 25000);
      expect(ItemsSingleton.onePrice(m.shopPrices),
          ItemsSingleton.finalPrice(m, 1, false));
    });

    test('tartibsiz uch pog\'ona [7, 3, 1] → 1 ning narxi', () {
      final m = lora([t(7, 27000), t(3, 26000), t(1, 25000)]);
      expect(ItemsSingleton.onePrice(m.shopPrices), 25000);
    });

    test('arzonlashuvchi tartibsiz [7 → 4000, 1 → 5000, 3 → 4500] → 5000', () {
      final m = lora([t(7, 4000), t(1, 5000), t(3, 4500)]);
      expect(ItemsSingleton.onePrice(m.shopPrices), 5000);
    });

    test('bitta pog\'ona [1 → 25 000] → 25 000', () {
      expect(ItemsSingleton.onePrice(pricesOf([t(1, 25000)])), 25000);
    });

    test('bitta pog\'ona, minQuantity null → uning narxi', () {
      final m = lora([t(null, 25000)]);
      expect(ItemsSingleton.onePrice(m.shopPrices), 25000);
      expect(ItemsSingleton.finalPrice(m, 1, false), 25000);
    });

    test('asos minQuantity 0 [0 → 25 000, 7 → 27 000] → 25 000', () {
      final m = lora([t(0, 25000), t(7, 27000)]);
      expect(ItemsSingleton.onePrice(m.shopPrices), 25000);
      expect(ItemsSingleton.finalPrice(m, 1, false), 25000);
    });

    test('asos minQuantity null [null → 25 000, 7 → 27 000] → 25 000', () {
      final m = lora([t(null, 25000), t(7, 27000)]);
      expect(ItemsSingleton.onePrice(m.shopPrices), 25000);
      expect(ItemsSingleton.finalPrice(m, 1, false), 25000);
    });

    test('bo\'sh / null holatlar → 0, xato yo\'q', () {
      expect(ItemsSingleton.onePrice(null), 0);
      expect(ItemsSingleton.onePrice(ShopPrices()), 0);
      expect(ItemsSingleton.onePrice(ShopPrices(shID: ShID(shopId: kShop))), 0);
      expect(ItemsSingleton.onePrice(pricesOf([])), 0);
    });

    test('asos pog\'onaning narxi null → 0', () {
      expect(ItemsSingleton.onePrice(pricesOf([t(1, null), t(7, 27000)])), 0);
    });

    test('dublikat minQuantity [1, 1, 7] → 7+ narxi EMAS, 1-talik dan biri',
        () {
      final m = lora([t(1, 25000), t(1, 26000), t(7, 27000)]);
      expect(ItemsSingleton.onePrice(m.shopPrices), isIn([25000, 26000]));
    });

    test(
        'dublikat minQuantity: onePrice va finalPrice(1) bir xil pog\'onani '
        'tanlaydi', () {
      final m = lora([t(1, 26000), t(1, 25000), t(7, 27000)]);
      expect(ItemsSingleton.onePrice(m.shopPrices),
          ItemsSingleton.finalPrice(m, 1, false),
          reason: 'BXGY "1-talik narx" savatdagi 1 dona narxi bilan bir xil '
              'bo\'lishi kerak');
    });

    test(
        'buzuq pog\'ona (minQuantity null/0) haqiqiy 1-talikdan KEYIN kelsa '
        'ham 1-talik narx = 25 000', () {
      final withNull = lora([t(1, 25000), t(null, 27000)]);
      final withZero = lora([t(1, 25000), t(0, 30000)]);
      // Savatda 1 dona shu narxda sotiladi:
      expect(ItemsSingleton.finalPrice(withNull, 1, false), 25000);
      expect(ItemsSingleton.finalPrice(withZero, 1, false), 25000);
      // 1-talik narx ham shu bo'lishi kerak:
      expect(ItemsSingleton.onePrice(withNull.shopPrices), 25000);
      expect(ItemsSingleton.onePrice(withZero.shopPrices), 25000);
    });
  });

  // ---------------------------------------------------------------------
  group('finalPrice — tartibsiz pog\'onalar va minQuantity 0/null', () {
    void check(String name, List<ShopPriceTiers> tiers, Map<int, num> cases) {
      test(name, () {
        final m = lora(tiers);
        cases.forEach((n, expected) {
          expect(ItemsSingleton.finalPrice(m, n, false), expected,
              reason: '$n ta');
        });
      });
    }

    check('qimmatlashuvchi tartibsiz [7 → 27 000, 1 → 25 000]', [
      t(7, 27000),
      t(1, 25000)
    ], {
      1: 25000,
      2: 25000,
      6: 25000,
      7: 27000,
      8: 27000,
      100: 27000,
    });

    check('arzonlashuvchi tartibsiz [7 → 4000, 1 → 5000, 3 → 4500]', [
      t(7, 4000),
      t(1, 5000),
      t(3, 4500)
    ], {
      1: 5000,
      2: 5000,
      3: 4500,
      6: 4500,
      7: 4000,
      50: 4000,
    });

    check('asos minQuantity 0 [0 → 25 000, 7 → 27 000]',
        [t(0, 25000), t(7, 27000)], {1: 25000, 6: 25000, 7: 27000, 9: 27000});

    check('asos minQuantity null [7 → 27 000, null → 25 000]',
        [t(7, 27000), t(null, 25000)], {1: 25000, 6: 25000, 7: 27000});
  });

  // ---------------------------------------------------------------------
  group('ShopPriceTiersSub / ProductPriceEdit.fromJson', () {
    test('min_quantity int 7 → 7', () {
      final s = ShopPriceTiersSub.fromJson(j(7, 27000));
      expect(s.minQuantity, 7);
      expect(s.retailPrice, 27000);
    });

    test('min_quantity 3.0 (double) → 3 (int)', () {
      final s = ShopPriceTiersSub.fromJson(j(3.0, 27000));
      expect(s.minQuantity, 3);
      expect(s.minQuantity, isA<int>());
    });

    test('min_quantity "3" va "3.0" (satr) → 3', () {
      expect(ShopPriceTiersSub.fromJson(j('3', 27000)).minQuantity, 3);
      expect(ShopPriceTiersSub.fromJson(j('3.0', 27000)).minQuantity, 3);
    });

    test('min_quantity null yoki kalit yo\'q → null, xato yo\'q', () {
      expect(ShopPriceTiersSub.fromJson(j(null, 27000)).minQuantity, isNull);
      expect(
          ShopPriceTiersSub.fromJson(<String, dynamic>{'retail_price': 27000})
              .minQuantity,
          isNull);
    });

    test('min_quantity buzuq satr ("abc") → null, xato yo\'q', () {
      expect(ShopPriceTiersSub.fromJson(j('abc', 27000)).minQuantity, isNull);
    });

    test('retail_price kalit yo\'q / null → null', () {
      expect(
          ShopPriceTiersSub.fromJson(<String, dynamic>{'min_quantity': 7})
              .retailPrice,
          isNull);
      expect(ShopPriceTiersSub.fromJson(j(7, null)).retailPrice, isNull);
    });

    test('retail_price "27000" (satr) → 27000', () {
      final s = ShopPriceTiersSub.fromJson(j(7, '27000'));
      expect(s.retailPrice, 27000);
      expect(s.retailPrice, isA<num>());
    });

    test('retail_price double 27000.0 va "27000.50" → son', () {
      expect(ShopPriceTiersSub.fromJson(j(7, 27000.0)).retailPrice, 27000);
      expect(ShopPriceTiersSub.fromJson(j(7, '27000.50')).retailPrice, 27000.5);
    });

    test('toJson → fromJson aylanishi qiymatni saqlaydi', () {
      final s = ShopPriceTiersSub.fromJson(j('7', '27000'));
      final back = ShopPriceTiersSub.fromJson(s.toJson());
      expect(back.minQuantity, 7);
      expect(back.retailPrice, 27000);
    });

    test('ProductPriceEdit: aralash shakldagi pog\'onalar to\'liq o\'qiladi',
        () {
      final e = priceEdit([
        j(1, 25000),
        j(7.0, 27000),
        j('10', '28000'),
        j(null, 29000),
        <String, dynamic>{'min_quantity': 20},
      ]);
      final price = e.data!.productsValues!.single.price!;
      expect(price.shopId, kShop);
      expect(e.data!.productsValues!.single.productId, kPid);
      final tiers = price.shopPriceTiers!;
      expect(tiers.map((x) => x.minQuantity).toList(), [1, 7, 10, null, 20]);
      expect(tiers.map((x) => x.retailPrice).toList(),
          [25000, 27000, 28000, 29000, null]);
    });
  });

  // ---------------------------------------------------------------------
  group('Hive: type 13 qo\'llanishi va saqlanishi', () {
    test('7.0 / "27000" kelsa Hive\'ga int 7 va 27000 yoziladi', () async {
      await HiveBoxes.getProducts().put(kPid, lora([t(1, 25000)]));
      final changed = await ItemsSingleton.editItem(priceEdit([
        j(1, 25000),
        j(7.0, '27000'),
      ]));
      expect(changed, 1);
      final tiers =
          HiveBoxes.getProducts().get(kPid)!.shopPrices!.shID!.shopPriceTiers!;
      expect(tiers, hasLength(2));
      expect(tiers[1].minQuantity, 7);
      expect(tiers[1].minQuantity, isA<int>());
      expect(tiers[1].retailPrice, 27000);
    });

    test('box qayta ochilgandan keyin ham pog\'ona saqlanadi (restart)',
        () async {
      await HiveBoxes.getProducts().put(kPid, lora([t(1, 25000)]));
      await ItemsSingleton.editItem(priceEdit([j(1, 25000), j('7', 27000)]));
      await HiveBoxes.getProducts().close();
      await Hive.openBox<ItemModel>(HiveBoxNames.items);
      await ItemsSingleton.storeProducts();

      final m = ItemsSingleton.getProductById(kPid)!;
      expect(ItemsSingleton.onePrice(m.shopPrices), 25000);
      expect(ItemsSingleton.finalPrice(m, 6, false), 25000);
      expect(ItemsSingleton.finalPrice(m, 8, false), 27000);
      expect(m.shopPrices!.shID!.shopId, kShop);
      expect(m.shopPrices!.shID!.supplyPrice, 20000);
    });

    test('boshqa do\'kon type 13 → changed 0, pog\'onalar o\'zgarmaydi',
        () async {
      await HiveBoxes.getProducts().put(kPid, lora([t(1, 25000)]));
      final changed = await ItemsSingleton.editItem(
          priceEdit([j(1, 30000), j(7, 32000)], shop: kOtherShop));
      expect(changed, 0);
      final saved = HiveBoxes.getProducts().get(kPid)!;
      expect(saved.shopPrices!.shID!.shopId, kShop);
      expect(saved.shopPrices!.shID!.shopPriceTiers, hasLength(1));
      expect(ItemsSingleton.onePrice(saved.shopPrices), 25000);
    });

    test('type 13 dan keyin mahsulot barcode bo\'yicha topiladi', () async {
      await HiveBoxes.getProducts().put(kPid, lora([t(1, 25000)]));
      await ItemsSingleton.editItem(
          priceEdit([j(7, 27000), j(1, 25000)])); // tartibsiz
      await ItemsSingleton.storeProducts();
      expect(ItemsSingleton.getProductByBarcode(kBarcode)?.id, kPid);
    });

    test(
        'bo\'sh pog\'ona qatori {null, null} kelsa ham mahsulot skanerdan '
        'yo\'qolmaydi', () async {
      await HiveBoxes.getProducts().put(kPid, lora([t(1, 25000)]));
      await ItemsSingleton.editItem(priceEdit([
        j(1, 25000),
        j(7, 27000),
        <String, dynamic>{'min_quantity': null, 'retail_price': null},
      ]));
      await ItemsSingleton.storeProducts();
      // 1 dona hali ham 25 000 da sotiladi...
      expect(
          ItemsSingleton.finalPrice(
              ItemsSingleton.getProductById(kPid)!, 1, false),
          25000);
      // ...demak barcode skaneri ham uni topishi kerak.
      expect(ItemsSingleton.getProductByBarcode(kBarcode)?.id, kPid);
    });
  });

  // ---------------------------------------------------------------------
  group('type 13 → savat (prod: 1+1 repeatable, 1 → 25 000, 7+ → 27 000)', () {
    testWidgets(
        'faqat 1 → 25 000 bor edi, notification 7.0 → 27 000 qo\'shdi → '
        '8 ta: dona 27 000, jami 108 000', (tester) async {
      await seed(tester, [t(1, 25000)]);
      expect(
          ItemsSingleton.finalPrice(
              ItemsSingleton.getProductById(kPid)!, 8, false),
          25000);

      final changed = await applyEdit(
          tester,
          priceEdit([
            j(1, 25000),
            j(7.0, 27000),
          ]));
      expect(changed, 1);

      final ctx = await appContext(tester);
      final p = await sellOneByOne(tester, ctx, 8);
      final row = cart(p).single;
      expect(row.value, 8);
      expect(row.realPrice, 27000, reason: 'pog\'ona narxi yo\'qolmasin');
      expect(row.price * row.value, closeTo(108000, 0.01));
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(108000, 1));
    });

    // Notification'dan keyin 1..9 ta — butun jadval prod qoidasi bo'yicha.
    for (final n in [1, 2, 6, 7, 9]) {
      final unit = n >= 7 ? 27000.0 : 25000.0;
      final line = expectedLine(n);
      testWidgets(
          'notification\'dan keyin $n ta → dona $unit, ${n ~/ 2} tekin, '
          'jami $line', (tester) async {
        await seed(tester, [t(1, 25000)]);
        await applyEdit(tester, priceEdit([j(1, 25000), j(7.0, 27000)]));
        final ctx = await appContext(tester);
        final p = await sellOneByOne(tester, ctx, n);
        final row = cart(p).single;
        expect(row.value, n);
        expect(row.realPrice, unit);
        expect(row.price * row.value, closeTo(line, 0.01));
        expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(line, 1));
      });
    }

    testWidgets(
        'satr va tartibsiz pog\'onalar ("7" → "27000" birinchi) — 8 ta '
        '108 000, 1 ta 25 000', (tester) async {
      await seed(tester, [t(1, 25000)]);
      await applyEdit(tester, priceEdit([j('7', '27000'), j('1', 25000)]));
      final ctx = await appContext(tester);

      final p8 = await sellOneByOne(tester, ctx, 8);
      expect(cart(p8).single.realPrice, 27000);
      expect(ItemsSingleton.getTotalPrice(cart(p8)), closeTo(108000, 1));

      final p1 = await sellOneByOne(tester, ctx, 1);
      expect(cart(p1).single.realPrice, 25000);
      expect(ItemsSingleton.getTotalPrice(cart(p1)), closeTo(25000, 1));
    });

    testWidgets(
        'narx KAMAYDI: 27 000 pog\'onasi olib tashlandi → keyingi sotuv '
        '25 000 (8 ta → 100 000)', (tester) async {
      await seed(tester, [t(1, 25000), t(7, 27000)]);
      final ctx = await appContext(tester);

      final before = await sellOneByOne(tester, ctx, 8);
      expect(cart(before).single.realPrice, 27000);
      expect(ItemsSingleton.getTotalPrice(cart(before)), closeTo(108000, 1));

      final changed = await applyEdit(tester, priceEdit([j(1, 25000)]));
      expect(changed, 1);

      final after = await sellOneByOne(tester, ctx, 8);
      final row = cart(after).single;
      expect(row.realPrice, 25000);
      expect(row.price * row.value, closeTo(100000, 0.01));
      expect(ItemsSingleton.getTotalPrice(cart(after)), closeTo(100000, 1));
    });

    testWidgets(
        'narx KAMAYDI: 1-talik ham arzonladi (1 → 24 000) → 8 ta '
        '4 × 24 000 = 96 000', (tester) async {
      await seed(tester, [t(1, 25000), t(7, 27000)]);
      await applyEdit(tester, priceEdit([j(1, 24000)]));
      final ctx = await appContext(tester);
      final p = await sellOneByOne(tester, ctx, 8);
      expect(cart(p).single.realPrice, 24000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(96000, 1));
    });

    testWidgets(
        'boshqa do\'kon (shop-2) uchun 27 000 qo\'shilsa — bu kassa 25 000 da '
        'qoladi (8 ta → 100 000)', (tester) async {
      await seed(tester, [t(1, 25000)]);
      final changed = await applyEdit(
          tester, priceEdit([j(1, 25000), j(7, 27000)], shop: kOtherShop));
      expect(changed, 0);
      final ctx = await appContext(tester);
      final p = await sellOneByOne(tester, ctx, 8);
      expect(cart(p).single.realPrice, 25000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(100000, 1));
    });

    testWidgets(
        'boshqa do\'kon uchun pog\'ona olib tashlansa — bu kassa 27 000 da '
        'qoladi (8 ta → 108 000)', (tester) async {
      await seed(tester, [t(1, 25000), t(7, 27000)]);
      final changed =
          await applyEdit(tester, priceEdit([j(1, 20000)], shop: kOtherShop));
      expect(changed, 0);
      final ctx = await appContext(tester);
      final p = await sellOneByOne(tester, ctx, 8);
      expect(cart(p).single.realPrice, 27000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(108000, 1));
    });

    testWidgets(
        'savat ochiq turganda pog\'ona qo\'shildi → keyingi skan butun '
        'qatorni 27 000 ga o\'tkazadi (9 ta → 5 × 27 000)', (tester) async {
      await seed(tester, [t(1, 25000)]);
      final ctx = await appContext(tester);
      final p = await sellOneByOne(tester, ctx, 8);
      expect(cart(p).single.realPrice, 25000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(100000, 1));

      await applyEdit(tester, priceEdit([j(1, 25000), j(7, 27000)]));
      await scan(tester, ctx, p);

      final row = cart(p).single;
      expect(row.value, 9);
      expect(row.realPrice, 27000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(135000, 1));
    });

    testWidgets('aksiyasiz: notification\'dan keyin 8 ta → sof 8 × 27 000',
        (tester) async {
      await seed(tester, [t(1, 25000)], withDiscount: false);
      await applyEdit(tester, priceEdit([j(1, 25000), j(7.0, 27000)]));
      final ctx = await appContext(tester);
      final p = await sellOneByOne(tester, ctx, 8);
      expect(cart(p).single.realPrice, 27000);
      expect(cart(p).single.price, 27000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(216000, 1));
    });

    testWidgets(
        'buzuq pog\'ona (min_quantity: null) keyin kelsa 1+1 da 2 ta → '
        '1 × 25 000', (tester) async {
      await seed(tester, [t(1, 25000)]);
      await applyEdit(
          tester,
          priceEdit([
            j(1, 25000),
            j(null, 27000),
          ]));
      final ctx = await appContext(tester);
      final p = await sellOneByOne(tester, ctx, 2);
      final row = cart(p).single;
      // Aksiyasiz ham 2 dona 25 000 dan (finalPrice null pog'onani
      // e'tiborsiz qoldiradi) — tekin bilan 1 × 25 000.
      expect(row.realPrice, 25000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(25000, 1));
    });
  });
}
