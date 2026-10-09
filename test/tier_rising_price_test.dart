// Pog'onali narx (tier) — ko'p olsa narx OSHADIGAN holat ham ishlashi kerak.
//
// MUAMMO (2026-10-08): adminkada "1 ta → 5000, 3+ ta → 7000" qo'yilganda
// kassa 8 ta sotsa ham 5000 da qolib ketardi. Kassa mantig'i asosan
// "ko'p olsa arzonlashadi" deb yozilgan joylari bor edi:
//   * Buy X Get Y shart bajarilganda `useFreeProducts` narxni SHARTSIZ
//     1-talikka qaytarardi (qimmat pog'ona yo'qolardi);
//   * `onePrice` ro'yxatning birinchi elementini 1-talik deb olardi;
//   * type 13 notification `min_quantity: 3.0` da yiqilardi.
//
// Bu fayl ikkala yo'nalishni ham (arzonlashuvchi va qimmatlashuvchi) va
// barcha kirish yo'llarini (skan, x8, OPD) muzlatadi.
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
const kPid = 'tier-id';
const kOtherId = 'other-id';

// Buy X Get Y uchun qat'iy GUIDlar (discount_helpers.dart dan).
const gGroupBuyXGetY = '86951e75-960f-45d7-9505-9b9cd2ce17a7';
const gTypeBuyXGetY = 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b';

const kRising = {1: 5000, 3: 7000};
const kFalling = {1: 5000, 3: 4500, 7: 4000};

ItemModel tierProduct(Map<int, num> tiers, {String id = kPid}) {
  final m = ItemModel();
  m.id = id;
  m.name = 'Tier $id';
  m.sku = '1';
  m.barcode = [id];
  m.packageCode = 'PACK-1';
  m.vat = Vat(percentage: 12);
  m.measurementUnit = MeasurementUnit(shortName: 'dona');
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: kShop, shopPriceTiers: [
      for (final t in tiers.entries)
        ShopPriceTiers(minQuantity: t.key, retailPrice: t.value)
    ]),
  );
  return m;
}

DiscountItem buyXGetY(
        {required int buy, required String getId, bool repeatable = false}) =>
    DiscountItem(
      id: 'bxgy',
      name: 'Buy X Get Y',
      displayName: 'Buy X Get Y',
      discountGroupType: DiscountGroupType(id: gGroupBuyXGetY),
      discountType: DiscountType(id: gTypeBuyXGetY),
      isExpirable: false,
      isForAllClients: true,
      isRepeatable: repeatable,
      shopIds: [ShopIds(id: kShop)],
      buyXGetY: BuyXGetY(
        productsToBuy: [ProductsToBuy(id: kPid, name: 'Tier')],
        buyProductsAmount: buy,
        productToGet: ProductsToGet(id: getId, name: getId),
        getProductsAmount: 1,
      ),
    );

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
    {double value = 1, String id = kPid}) async {
  p.addProduct(
      value: value,
      product: ItemsSingleton.getProductById(id)!,
      where: 'test',
      context: ctx);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // Aksiyali mahsulot birinchi qo'shilganda "aksiya bor" dialogi chiqadi —
  // kassir "Ok" bosmaguncha tekin qo'llanmaydi. Kassir kabi yopamiz.
  final ok = find.text('Ok');
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// OPD dialogidagi qty o'zgarishi: dialog qator NUSXASINI tahrirlaydi va
/// "Saqlash"da `pressDialogSaveButton` ga beradi (narx tahrirlanmagan).
Future<void> opdSetQty(OrderingProvider4 p, int index, double qty) async {
  final row = p.getCurrentClient.orderedProducts[index];
  p.tapIndexToEdit(index);
  await p.pressDialogSaveButton(makeSoldItem(
    productId: row.productId,
    price: row.price,
    realPrice: row.realPrice,
    onlyPrice: row.onlyPrice,
    value: qty,
  ));
}

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('tier_rising_price_test');
    await Pref.setString(PrefKeys.storeId, kShop);

    // type 13 → editItem Hive'dagi mahsulotlar box'ini o'qiydi.
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
    await Pref.setBool(PrefKeys.markCheckWithOfd, false);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
    await HiveBoxes.getDiscounts().clear();
    DiscountSingleton.resetAll();
  });

  group('Qimmatlashuvchi pog\'ona (1 → 5000, 3+ → 7000)', () {
    setUp(() => ItemsSingleton.products = [tierProduct(kRising)]);

    for (int n = 1; n <= 8; n++) {
      final expected = n >= 3 ? 7000.0 : 5000.0;
      testWidgets('bittadan $n marta skan → $expected', (tester) async {
        final ctx = await appContext(tester);
        final p = freshProvider();
        for (int i = 0; i < n; i++) {
          await scan(tester, ctx, p);
        }
        expect(cart(p), hasLength(1));
        expect(cart(p).first.value, n);
        expect(cart(p).first.price, expected);
        expect(cart(p).first.realPrice, expected);
      });
    }

    testWidgets('x8 bir martada → 7000', (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(cart(p).first.price, 7000);
    });

    testWidgets('1 ta + 7 ta → 7000', (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p);
      await scan(tester, ctx, p, value: 7);
      expect(cart(p).first.value, 8);
      expect(cart(p).first.price, 7000);
    });

    testWidgets('OPD: 1 → 8 → 7000, keyin 8 → 2 → yana 5000', (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p);
      await opdSetQty(p, 0, 8);
      expect(cart(p).first.price, 7000);
      await opdSetQty(p, 0, 2);
      expect(cart(p).first.price, 5000);
    });

    testWidgets('jami summa pog\'ona narxida: 8 × 7000', (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(ItemsSingleton.getTotalPrice(cart(p)), 56000);
    });
  });

  group('Arzonlashuvchi pog\'ona (regressiya: 1 → 5000, 3+ → 4500, 7+ → 4000)',
      () {
    setUp(() => ItemsSingleton.products = [tierProduct(kFalling)]);

    const cases = {1: 5000, 2: 5000, 3: 4500, 6: 4500, 7: 4000, 8: 4000};
    cases.forEach((n, expected) {
      testWidgets('$n marta skan → $expected', (tester) async {
        final ctx = await appContext(tester);
        final p = freshProvider();
        for (int i = 0; i < n; i++) {
          await scan(tester, ctx, p);
        }
        expect(cart(p).first.price, expected);
      });
    });
  });

  // Prod'dagi aniq sozlama (2026-10-08, "Saryog' Lora 200gr"): Buy X Get Y,
  // o'sha mahsulotning o'zi, 1 olsa 1 tekin, repeatable; 1 ta → 25 000,
  // 7+ ta → 27 000. Tekin soni = floor(n / 2). Pog'ona savatdagi JAMI dona
  // (tekinlari bilan) bo'yicha tanlanadi.
  group('PROD: Saryog\' Lora — 1+1 repeatable, 1 → 25 000, 7+ → 27 000', () {
    const tiers = {1: 25000, 7: 27000};

    for (int n = 1; n <= 9; n++) {
      final unit = n >= 7 ? 27000.0 : 25000.0;
      final free = n ~/ 2;
      final lineTotal = unit * (n - free);
      testWidgets('$n marta skan → dona $unit, $free tekin, jami $lineTotal',
          (tester) async {
        await tester.runAsync(() => HiveBoxes.getDiscounts()
            .add(buyXGetY(buy: 1, getId: kPid, repeatable: true)));
        ItemsSingleton.products = [tierProduct(tiers)];
        final ctx = await appContext(tester);
        final p = freshProvider();
        for (int i = 0; i < n; i++) {
          await scan(tester, ctx, p);
        }
        final row = cart(p).single;
        expect(row.value, n);
        expect(row.realPrice, unit, reason: 'pog\'ona narxi yo\'qolmasin');
        expect(row.price * row.value, closeTo(lineTotal, 0.01));
        expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(lineTotal, 1));
      });
    }

    testWidgets('x8 bir martada → 4 × 27 000 = 108 000', (tester) async {
      await tester.runAsync(() => HiveBoxes.getDiscounts()
          .add(buyXGetY(buy: 1, getId: kPid, repeatable: true)));
      ItemsSingleton.products = [tierProduct(tiers)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      final row = cart(p).single;
      expect(row.realPrice, 27000);
      expect(row.price * row.value, closeTo(108000, 0.01));
    });

    testWidgets('OPD: 8 → 6 ga tushirilsa yana 25 000 (3 × 25 000)',
        (tester) async {
      await tester.runAsync(() => HiveBoxes.getDiscounts()
          .add(buyXGetY(buy: 1, getId: kPid, repeatable: true)));
      ItemsSingleton.products = [tierProduct(tiers)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      await opdSetQty(p, 0, 6);
      final row = cart(p).single;
      expect(row.realPrice, 25000);
      expect(row.price * row.value, closeTo(75000, 0.01));
    });
  });

  group('Buy X Get Y + pog\'ona', () {
    testWidgets(
        'QIMMAT pog\'ona: shart bajarilganda ham 7000 saqlanadi '
        '(8 dan 1 tekin → 7000 × 7/8)', (tester) async {
      await tester.runAsync(() => HiveBoxes.getDiscounts()
          .add(buyXGetY(buy: 5, getId: kPid)));
      ItemsSingleton.products = [tierProduct(kRising)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      for (int i = 0; i < 8; i++) {
        await scan(tester, ctx, p);
      }
      final row = cart(p).single;
      expect(row.realPrice, 7000, reason: 'qimmat pog\'ona 1-talikka tushmasin');
      expect(row.price, closeTo(7000 * 7 / 8, 0.01));
    });

    testWidgets(
        'ARZON pog\'ona: avvalgi qoida saqlanadi — tekin bor bo\'lsa '
        '1-talik narx (5000)', (tester) async {
      await tester.runAsync(() => HiveBoxes.getDiscounts()
          .add(buyXGetY(buy: 5, getId: kPid)));
      ItemsSingleton.products = [tierProduct(kFalling)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      for (int i = 0; i < 8; i++) {
        await scan(tester, ctx, p);
      }
      final row = cart(p).single;
      expect(row.realPrice, 5000);
      expect(row.price, closeTo(5000 * 7 / 8, 0.01));
    });

    testWidgets('shart bajarilmasa pog\'ona narxi o\'zgarmaydi', (tester) async {
      await tester.runAsync(() => HiveBoxes.getDiscounts()
          .add(buyXGetY(buy: 20, getId: kPid)));
      ItemsSingleton.products = [tierProduct(kRising)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(cart(p).single.price, 7000);
    });
  });

  group('onePrice — 1-talik narx', () {
    test('tartibsiz pog\'onalar: eng kichik minQuantity olinadi', () {
      final m = tierProduct(const {3: 7000, 1: 5000});
      expect(ItemsSingleton.onePrice(m.shopPrices), 5000);
    });

    test('bitta pog\'ona', () {
      expect(ItemsSingleton.onePrice(tierProduct(const {1: 5000}).shopPrices),
          5000);
    });

    test('pog\'ona yo\'q → 0', () {
      expect(ItemsSingleton.onePrice(null), 0);
      expect(ItemsSingleton.onePrice(ShopPrices(shID: ShID(shopPriceTiers: []))),
          0);
    });

    test('finalPrice tartibsiz pog\'onalarda ham to\'g\'ri', () {
      final m = tierProduct(const {3: 7000, 1: 5000});
      expect(ItemsSingleton.finalPrice(m, 1, false), 5000);
      expect(ItemsSingleton.finalPrice(m, 2, false), 5000);
      expect(ItemsSingleton.finalPrice(m, 3, false), 7000);
      expect(ItemsSingleton.finalPrice(m, 8, false), 7000);
    });
  });

  group('type 13 notification → savat', () {
    ProductPriceEdit edit(List<Map<String, dynamic>> tiers) =>
        ProductPriceEdit.fromJson({
          'id': 'n-1',
          'type': 13,
          'data': {
            'product_values': [
              {
                'product_id': kPid,
                'price': {
                  'shop_id': kShop,
                  'retail_price': 5000,
                  'supply_price': 4000,
                  'shop_price_tiers': tiers,
                },
              },
            ],
          },
        });

    test('min_quantity 3.0 / "3" — yiqilmaydi', () {
      final e = edit([
        {'min_quantity': 1.0, 'retail_price': 5000},
        {'min_quantity': '3', 'retail_price': '7000'},
      ]);
      final tiers = e.data!.productsValues!.first.price!.shopPriceTiers!;
      expect(tiers[0].minQuantity, 1);
      expect(tiers[1].minQuantity, 3);
      expect(tiers[1].retailPrice, 7000);
    });

    testWidgets('adminkada pog\'ona qo\'shildi → keyingi sotuv 7000',
        (tester) async {
      await tester.runAsync(() async {
        final box = HiveBoxes.getProducts();
        await box.clear();
        await box.put(kPid, tierProduct(const {1: 5000}));
        await ItemsSingleton.storeProducts();
        expect(ItemsSingleton.finalPrice(
            ItemsSingleton.getProductById(kPid)!, 8, false), 5000);
        await ItemsSingleton.editItem(edit([
          {'min_quantity': 1, 'retail_price': 5000},
          {'min_quantity': 3.0, 'retail_price': 7000},
        ]));
        await ItemsSingleton.storeProducts();
      });
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(cart(p).single.price, 7000);
      await tester.runAsync(() => HiveBoxes.getProducts().clear());
    });
  });
}
