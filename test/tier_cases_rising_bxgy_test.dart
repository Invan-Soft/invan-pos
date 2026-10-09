// QIMMATLASHUVCHI pog'ona (ko'p olsa narx OSHADI) + diskontlar — keng holatlar.
//
// Tuzatish (2026-10-08): `useFreeProducts` Buy X Get Y shart bajarilganda
// narxni SHARTSIZ 1-talikka qaytarardi. Endi faqat pog'ona 1-talikdan ARZON
// bo'lsa (ulgurji) 1-talik qo'yiladi; QIMMAT pog'ona saqlanadi.
//
// Biznes qoidalar (kutilgan qiymatlar shulardan hisoblanadi, koddan emas):
//   * pog'ona = savatdagi shu mahsulotning JAMI donasi (tekinlari bilan)
//     bo'yicha eng katta minQuantity <= jami;
//   * Buy X Get Y / Buy X Get X: pog'ona QIMMAT bo'lsa pog'ona narxi qoladi,
//     tekin donalar shu narxdan chiqariladi;
//   * diskont yo'q → sof pog'ona narxi.
//
// Qator jami = realPrice × to'lanadigan dona; row.price = realPrice × paid / qty.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
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
const kPid = 'lora-id'; // "Saryog' Lora 200gr"
const kOtherId = 'boshqa-id';

// Qat'iy GUIDlar (discount_helpers.dart dan).
const gGroupBuyXGetY = '86951e75-960f-45d7-9505-9b9cd2ce17a7';
const gTypeBuyXGetY = 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b';
const gGroupBuyXGetX = '316b623e-3bb7-43e2-b6d5-1028c927caba';
const gTypeBuyXGetX = '90d1f774-44bd-49be-9bbf-2e9a44558377';
const gGroupProduct = '22e778e1-e562-4649-b47e-b720a28d831c';
const gTypePercentage = 'e908c52f-4c6f-46d8-b765-16e074425cd9';

/// Prod'dagi pog'ona: 1 ta → 25 000, 7+ ta → 27 000.
const kProd = {1: 25000, 7: 27000};

/// Uch pog'ona: 1 → 25 000, 3+ → 26 000, 7+ → 27 000.
const kThree = {1: 25000, 3: 26000, 7: 27000};

/// Ikkinchi mahsulot (ham qimmatlashuvchi): 1 → 10 000, 3+ → 12 000.
const kOtherRising = {1: 10000, 3: 12000};

// ------------------------------------------------------------------------
// Biznes qoidalari (kutilgan qiymatlar uchun)
// ------------------------------------------------------------------------

/// Pog'ona: eng katta minQuantity <= [units].
num tierUnit(Map<int, num> tiers, num units) {
  num price = 0;
  int best = -1;
  tiers.forEach((minQ, p) {
    if (units >= minQ && minQ > best) {
      best = minQ;
      price = p;
    }
  });
  return price;
}

/// Bir xil mahsulotdan tekin: repeatable → har to'liq (buy+get) to'plam uchun
/// get; aks holda bitta to'plam.
int freeSame(int n, {required int buy, required int get, required bool rep}) {
  final set = buy + get;
  if (rep) return (n ~/ set) * get;
  return n >= set ? get : 0;
}

// ------------------------------------------------------------------------
// Katalog va diskont yasovchilar
// ------------------------------------------------------------------------

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

DiscountItem bxgy({
  required int buy,
  int get = 1,
  String buyId = kPid,
  String getId = kPid,
  bool repeatable = false,
}) =>
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
        productsToBuy: [ProductsToBuy(id: buyId, name: buyId)],
        buyProductsAmount: buy,
        productToGet: ProductsToGet(id: getId, name: getId),
        getProductsAmount: get,
      ),
    );

DiscountItem bxgx({
  required int buy,
  int get = 1,
  String productId = kPid,
  bool repeatable = false,
}) =>
    DiscountItem(
      id: 'bxgx',
      name: 'Buy X Get X',
      displayName: '$buy olsang $get tekin',
      discountGroupType: DiscountGroupType(id: gGroupBuyXGetX),
      discountType: DiscountType(id: gTypeBuyXGetX),
      isExpirable: false,
      isForAllClients: true,
      isRepeatable: repeatable,
      shopIds: [ShopIds(id: kShop)],
      buyXGetX: BuyXGetX(
        productsToBuy: [ProductsToBuy(id: productId, name: productId)],
        buyProductsAmount: buy,
        getProductsAmount: get,
      ),
    );

DiscountItem percent(int value, {List<String>? onlyFor}) => DiscountItem(
      id: 'pct',
      name: '$value%',
      displayName: '$value%',
      discountGroupType: DiscountGroupType(id: gGroupProduct),
      discountType: DiscountType(id: gTypePercentage),
      discountValue: value,
      isExpirable: false,
      isAllProducts: onlyFor == null,
      productIds: (onlyFor ?? const []).map((e) => ProductIds(id: e)).toList(),
      isForAllClients: true,
      shopIds: [ShopIds(id: kShop)],
    );

// ------------------------------------------------------------------------
// Kassa harakatlari
// ------------------------------------------------------------------------

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

/// testWidgets ichida Hive IO faqat runAsync orqali.
Future<void> seed(WidgetTester tester, List<DiscountItem> ds) =>
    tester.runAsync(() => HiveBoxes.getDiscounts().addAll(ds));

Future<void> scan(WidgetTester tester, BuildContext ctx, OrderingProvider4 p,
    {double value = 1, String id = kPid}) async {
  p.addProduct(
      value: value,
      product: ItemsSingleton.getProductById(id)!,
      where: 'test',
      context: ctx);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  // "Aksiya bor" dialogi — kassir "Ok" bosmaguncha tekin qo'llanmaydi.
  final ok = find.text('Ok');
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> scanN(WidgetTester tester, BuildContext ctx, OrderingProvider4 p,
    int n,
    {String id = kPid}) async {
  for (int i = 0; i < n; i++) {
    await scan(tester, ctx, p, id: id);
  }
}

/// OPD dialogidagi qty o'zgarishi (narx tahrirlanmagan).
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

/// OPD "Saqlash" o'zgarishsiz — tier + diskont effektlarini qayta hisoblaydi.
Future<void> saveRow(OrderingProvider4 p, int index) async {
  p.tapIndexToEdit(index);
  await p.pressDialogSaveButton(p.getCurrentClient.orderedProducts[index]);
}

/// OPD "O'chirish" — bitta qator.
Future<void> deleteRow(OrderingProvider4 p, int index) async {
  p.tapIndexToEdit(index);
  p.pressDialogDeleteButton();
  await Future<void>.delayed(Duration.zero);
}

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

List<ReceiptModelSoldItem4> rowsOf(OrderingProvider4 p, String id) => cart(p)
    .where((e) => e.productId == id && !(e.isDeleted ?? false))
    .toList();

ReceiptModelSoldItem4 rowOf(OrderingProvider4 p, String id) =>
    rowsOf(p, id).single;

/// Mahsulotning savatdagi to'lanadigan jami summasi.
double productTotal(OrderingProvider4 p, String id) =>
    rowsOf(p, id).fold<double>(0, (s, e) => s + e.price * e.value);

/// Markirovkali mahsulot qatori (har skan alohida qator, value = 1).
ReceiptModelSoldItem4 markRow(int i, {String id = kPid, double price = 25000}) =>
    makeSoldItem(
        productId: id,
        name: 'Lora',
        price: price,
        value: 1,
        marking: true,
        mark: 'KM-$id-$i');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('tier_cases_rising_bxgy_test');
    await Pref.setString(PrefKeys.storeId, kShop);
  });
  tearDownAll(tearDownPosTestEnv);

  // testWidgets ichida Hive IO kutilsa osilib qoladi — sozlash shu yerda.
  setUp(() async {
    await Pref.setBool(PrefKeys.markCheckWithOfd, false);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
    await HiveBoxes.getDiscounts().clear();
    DiscountSingleton.resetAll();
    ItemsSingleton.products = [
      tierProduct(kProd),
      tierProduct(kOtherRising, id: kOtherId),
    ];
  });

  // ======================================================================
  // 1. Prod sozlamasi
  // ======================================================================
  group('PROD: 1+1 repeatable (o\'zi tekin), 1 → 25 000, 7+ → 27 000', () {
    for (int n = 1; n <= 10; n++) {
      final unit = tierUnit(kProd, n).toDouble();
      final free = freeSame(n, buy: 1, get: 1, rep: true);
      final total = unit * (n - free);
      testWidgets('bittadan $n marta skan → dona $unit, $free tekin, jami $total',
          (tester) async {
        await seed(tester, [bxgy(buy: 1, repeatable: true)]);
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);

        final row = cart(p).single;
        expect(row.value, n);
        expect(row.realPrice, unit, reason: 'pog\'ona narxi yo\'qolmasin');
        expect(row.onlyPrice, unit);
        expect(row.price, closeTo(unit * (n - free) / n, 0.01));
        expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(total, 1));
      });
    }

    for (final n in const [7, 8, 14]) {
      final unit = tierUnit(kProd, n).toDouble();
      final free = freeSame(n, buy: 1, get: 1, rep: true);
      final total = unit * (n - free);
      testWidgets('x$n bir martada → $free tekin, jami $total', (tester) async {
        await seed(tester, [bxgy(buy: 1, repeatable: true)]);
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scan(tester, ctx, p, value: n.toDouble());

        final row = cart(p).single;
        expect(row.value, n);
        expect(row.realPrice, unit);
        expect(row.price * row.value, closeTo(total, 0.01));
        expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(total, 1));
      });
    }

    testWidgets('x6 + 1 skan → 7 ta: 27 000 × 4 = 108 000', (tester) async {
      await seed(tester, [bxgy(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 6);
      expect(productTotal(p, kPid), closeTo(75000, 0.01));
      await scan(tester, ctx, p);
      final row = cart(p).single;
      expect(row.value, 7);
      expect(row.realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
    });

    testWidgets('x7 + x7 → 14 ta: 27 000 × 7 = 189 000', (tester) async {
      await seed(tester, [bxgy(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      await scan(tester, ctx, p, value: 7);
      final row = cart(p).single;
      expect(row.value, 14);
      expect(row.realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(189000, 0.01));
    });
  });

  // ======================================================================
  // 2. Chegara 6 → 7 → 6
  // ======================================================================
  group('Chegara 6 → 7 → 6 (prod sozlamasi)', () {
    testWidgets('OPD: x6 → 7 → 6: 75 000 → 108 000 → 75 000', (tester) async {
      await seed(tester, [bxgy(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 6);
      expect(rowOf(p, kPid).realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(75000, 0.01));

      await opdSetQty(p, 0, 7);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));

      await opdSetQty(p, 0, 6);
      expect(rowOf(p, kPid).realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(75000, 0.01));
    });

    testWidgets('7 ta skan → OPD 6 → yana 1 skan → 7: narx qaytadi',
        (tester) async {
      await seed(tester, [bxgy(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 7);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));

      await opdSetQty(p, 0, 6);
      expect(rowOf(p, kPid).realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(75000, 0.01));

      await scan(tester, ctx, p);
      expect(rowOf(p, kPid).value, 7);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
    });

    testWidgets('OPD: x8 → 7 → 6 → 1 (tekin yo\'qoladi)', (tester) async {
      await seed(tester, [bxgy(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
      await opdSetQty(p, 0, 7);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
      await opdSetQty(p, 0, 6);
      expect(productTotal(p, kPid), closeTo(75000, 0.01));
      await opdSetQty(p, 0, 1);
      final row = rowOf(p, kPid);
      expect(row.realPrice, 25000);
      expect(row.price, 25000, reason: '1 ta — tekin yo\'q');
    });

    test('deleteRow: 7 ta markali qator → bittasi o\'chirilsa 6 → 25 000',
        () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 1, repeatable: true));
      final p = freshProvider();
      for (int i = 0; i < 7; i++) {
        cart(p).add(markRow(i));
      }
      await saveRow(p, 0);

      final rows7 = rowsOf(p, kPid);
      expect(rows7, hasLength(7));
      expect(rows7.every((e) => e.realPrice == 27000), isTrue,
          reason: '7 dona → hammasi 27 000');
      expect(rows7.where((e) => e.price == 0), hasLength(3),
          reason: 'floor(7/2) = 3 ta tekin');
      expect(productTotal(p, kPid), closeTo(108000, 0.01));

      // To'lanadigan qatorlardan birini o'chiramiz.
      final paidIdx = cart(p).indexWhere((e) => e.price > 0);
      await deleteRow(p, paidIdx);

      final rows6 = rowsOf(p, kPid);
      expect(rows6, hasLength(6));
      expect(rows6.every((e) => e.realPrice == 25000), isTrue,
          reason: '6 dona → 1-pog\'ona');
      expect(rows6.where((e) => e.price == 0), hasLength(3));
      expect(productTotal(p, kPid), closeTo(75000, 0.01));
    });

    test('deleteRow: tekin qator o\'chirilsa ham 6 → 3 × 25 000', () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 1, repeatable: true));
      final p = freshProvider();
      for (int i = 0; i < 7; i++) {
        cart(p).add(markRow(i));
      }
      await saveRow(p, 0);
      final freeIdx = cart(p).indexWhere((e) => e.price == 0);
      expect(freeIdx, isNot(-1));
      await deleteRow(p, freeIdx);

      final rows6 = rowsOf(p, kPid);
      expect(rows6.every((e) => e.realPrice == 25000), isTrue);
      expect(productTotal(p, kPid), closeTo(75000, 0.01));
    });

    test('deleteRow: ikki qator (6 + 1) → 1 talik o\'chirilsa 6 → 75 000',
        () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 1, repeatable: true));
      final p = freshProvider();
      cart(p)
        ..add(markRow(7)) // 0 — oxirgi qo'shilgan
        ..add(makeSoldItem(productId: kPid, price: 25000, value: 6));
      await saveRow(p, 0);
      expect(rowsOf(p, kPid).every((e) => e.realPrice == 27000), isTrue);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));

      await deleteRow(p, 0);
      final row = rowOf(p, kPid);
      expect(row.value, 6);
      expect(row.realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(75000, 0.01));
    });

    test('deleteRow: 6 talik qator o\'chirilsa 1 ta qoladi → 25 000, tekin yo\'q',
        () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 1, repeatable: true));
      final p = freshProvider();
      cart(p)
        ..add(markRow(7))
        ..add(makeSoldItem(productId: kPid, price: 25000, value: 6));
      await saveRow(p, 0);
      await deleteRow(p, 1);
      final row = rowOf(p, kPid);
      expect(row.value, 1);
      expect(row.realPrice, 25000);
      expect(row.price, 25000);
    });

    test('qizil o\'chirish: o\'chirilgan qator jamiga kirmaydi → 75 000',
        () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      await HiveBoxes.getDiscounts().add(bxgy(buy: 1, repeatable: true));
      final p = freshProvider();
      cart(p)
        ..add(markRow(7))
        ..add(makeSoldItem(productId: kPid, price: 25000, value: 6));
      await saveRow(p, 0);
      await deleteRow(p, 0);

      expect(cart(p), hasLength(2), reason: 'qator savatda qoladi');
      expect(cart(p)[0].isDeleted, isTrue);
      final row = rowOf(p, kPid);
      expect(row.realPrice, 25000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(75000, 1));
    });

    test('removeLastAdded (diskontsiz): 6 + 1 → 1 talik olib tashlansa 25 000',
        () async {
      final p = freshProvider();
      cart(p)
        ..add(markRow(7))
        ..add(makeSoldItem(productId: kPid, price: 25000, value: 6));
      await saveRow(p, 0);
      expect(rowsOf(p, kPid).every((e) => e.price == 27000), isTrue);

      p.getCurrentClient.lastAddedIndex = 0;
      p.removeLastAdded();
      final row = rowOf(p, kPid);
      expect(row.value, 6);
      expect(row.realPrice, 25000);
      expect(row.price, 25000);
    });

    test(
        'removeLastAdded (BXGY): 6 + 1 → 1 talik olib tashlansa '
        '3 tekin, 3 × 25 000', () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 1, repeatable: true));
      final p = freshProvider();
      cart(p)
        ..add(markRow(7))
        ..add(makeSoldItem(productId: kPid, price: 25000, value: 6));
      await saveRow(p, 0);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));

      p.getCurrentClient.lastAddedIndex = 0;
      p.removeLastAdded();
      final row = rowOf(p, kPid);
      expect(row.realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(75000, 0.01),
          reason: '6 dona → 3 tekin qayta hisoblanishi kerak');
    },
        skip: 'BUG: removeLastAdded tier qayta tanlaydi, lekin BXGY/BXGX '
            'tekinini qayta hisoblamaydi (cart_edit_controller.dart:393)');
  });

  // ======================================================================
  // 3. Takrorlanmaydigan 1+1
  // ======================================================================
  group('Takrorlanmaydigan 1+1 (o\'zi tekin) + qimmatlashuvchi pog\'ona', () {
    for (final n in const [1, 2, 3, 6, 7, 8]) {
      final unit = tierUnit(kProd, n).toDouble();
      final free = freeSame(n, buy: 1, get: 1, rep: false);
      final total = unit * (n - free);
      testWidgets('$n marta skan → $free tekin, jami $total', (tester) async {
        await seed(tester, [bxgy(buy: 1)]);
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);
        final row = cart(p).single;
        expect(row.realPrice, unit);
        expect(productTotal(p, kPid), closeTo(total, 0.01));
      });
    }

    testWidgets('x7 bir martada → 27 000 × 6 = 162 000', (tester) async {
      await seed(tester, [bxgy(buy: 1)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(162000, 0.01));
    });
  });

  // ======================================================================
  // 4. 2 olsa 1 tekin, repeatable
  // ======================================================================
  group('2 olsa 1 tekin, repeatable (o\'zi tekin) + qimmatlashuvchi pog\'ona',
      () {
    for (final n in const [2, 3, 5, 6, 7, 8, 9]) {
      final unit = tierUnit(kProd, n).toDouble();
      final free = freeSame(n, buy: 2, get: 1, rep: true);
      final total = unit * (n - free);
      testWidgets('$n marta skan → $free tekin, jami $total', (tester) async {
        await seed(tester, [bxgy(buy: 2, repeatable: true)]);
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);
        final row = cart(p).single;
        expect(row.realPrice, unit);
        expect(productTotal(p, kPid), closeTo(total, 0.01));
      });
    }

    testWidgets('x9 bir martada → 3 tekin, 27 000 × 6 = 162 000',
        (tester) async {
      await seed(tester, [bxgy(buy: 2, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 9);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(162000, 0.01));
    });
  });

  // ======================================================================
  // 5. Tekin sharti va pog'ona chegarasi bir vaqtda (6 olsa 1 tekin)
  // ======================================================================
  group('6 olsa 1 tekin (to\'plam = 7) — shart va pog\'ona bir chegarada', () {
    testWidgets('6 ta → tekin yo\'q, 25 000 × 6 = 150 000', (tester) async {
      await seed(tester, [bxgy(buy: 6)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 6);
      expect(rowOf(p, kPid).price, 25000);
      expect(productTotal(p, kPid), closeTo(150000, 0.01));
    });

    testWidgets('7 ta → 1 tekin, 27 000 × 6 = 162 000', (tester) async {
      await seed(tester, [bxgy(buy: 6)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 7);
      expect(rowOf(p, kPid).realPrice, 27000,
          reason: 'shart bajarilganda ham qimmat pog\'ona saqlanadi');
      expect(productTotal(p, kPid), closeTo(162000, 0.01));
    });

    testWidgets('OPD 7 → 6 → tekin ham, pog\'ona ham qaytadi', (tester) async {
      await seed(tester, [bxgy(buy: 6)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      await opdSetQty(p, 0, 6);
      final row = rowOf(p, kPid);
      expect(row.realPrice, 25000);
      expect(row.price, 25000);
      expect(productTotal(p, kPid), closeTo(150000, 0.01));
    });
  });

  // ======================================================================
  // 6. Tekin mahsulot BOSHQA mahsulot, ikkalasi ham qimmatlashuvchi
  // ======================================================================
  group('A olsa B tekin — A: 1 → 25 000, 7+ → 27 000; B: 1 → 10 000, 3+ → 12 000',
      () {
    testWidgets('1+1: A × 7, B × 4 → A 27 000 × 7, B 12 000 × 3',
        (tester) async {
      await seed(tester, [bxgy(buy: 1, getId: kOtherId)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 7);
      await scanN(tester, ctx, p, 4, id: kOtherId);

      final a = rowOf(p, kPid);
      expect(a.value, 7);
      expect(a.realPrice, 27000);
      expect(a.price, 27000, reason: 'A sotib olinadigan — chegirmasiz');
      expect(productTotal(p, kPid), closeTo(189000, 0.01));

      final b = rowOf(p, kOtherId);
      expect(b.value, 4);
      expect(b.realPrice, 12000, reason: 'B ning qimmat pog\'onasi saqlanadi');
      expect(b.price, closeTo(12000 * 3 / 4, 0.01));
      expect(productTotal(p, kOtherId), closeTo(36000, 0.01));
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(225000, 1));
    });

    testWidgets('1+1: A × 1, B × 2 → B 1-pog\'ona, 1 tekin: 10 000',
        (tester) async {
      await seed(tester, [bxgy(buy: 1, getId: kOtherId)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p);
      await scanN(tester, ctx, p, 2, id: kOtherId);
      expect(rowOf(p, kPid).price, 25000);
      final b = rowOf(p, kOtherId);
      expect(b.realPrice, 10000);
      expect(productTotal(p, kOtherId), closeTo(10000, 0.01));
    });

    testWidgets('avval B × 4, keyin A × 7 → B ga tekin keyin qo\'llanadi',
        (tester) async {
      await seed(tester, [bxgy(buy: 1, getId: kOtherId)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 4, id: kOtherId);
      expect(productTotal(p, kOtherId), closeTo(48000, 0.01),
          reason: 'A hali yo\'q — B to\'liq 12 000 × 4');
      await scanN(tester, ctx, p, 7);

      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(189000, 0.01));
      final b = rowOf(p, kOtherId);
      expect(b.realPrice, 12000);
      expect(productTotal(p, kOtherId), closeTo(36000, 0.01));
    });

    testWidgets('2 olsa 1 tekin repeatable: A × 7 → 3 ta B tekin; B × 4 → 12 000',
        (tester) async {
      await seed(tester, [bxgy(buy: 2, getId: kOtherId, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      await scanN(tester, ctx, p, 4, id: kOtherId);

      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(189000, 0.01));
      final b = rowOf(p, kOtherId);
      expect(b.realPrice, 12000);
      expect(productTotal(p, kOtherId), closeTo(12000, 0.01),
          reason: 'floor(7/2) = 3 tekin, 1 ta × 12 000');
    });

    testWidgets('OPD: B 4 → 2 → B 1-pog\'ona (10 000), A o\'zgarmaydi',
        (tester) async {
      await seed(tester, [bxgy(buy: 1, getId: kOtherId)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      await scan(tester, ctx, p, value: 4, id: kOtherId);
      final bIdx = cart(p).indexWhere((e) => e.productId == kOtherId);
      await opdSetQty(p, bIdx, 2);

      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(189000, 0.01));
      final b = rowOf(p, kOtherId);
      expect(b.realPrice, 10000);
      expect(productTotal(p, kOtherId), closeTo(10000, 0.01));
    });

    testWidgets('OPD: A 7 → 6 → A 25 000, B tekini qoladi (shart 1 ta A)',
        (tester) async {
      await seed(tester, [bxgy(buy: 1, getId: kOtherId)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      await scan(tester, ctx, p, value: 4, id: kOtherId);
      final aIdx = cart(p).indexWhere((e) => e.productId == kPid);
      await opdSetQty(p, aIdx, 6);

      expect(rowOf(p, kPid).realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(150000, 0.01));
      expect(rowOf(p, kOtherId).realPrice, 12000);
      expect(productTotal(p, kOtherId), closeTo(36000, 0.01));
    });

    test('deleteRow: A o\'chirilsa B tekini bekor, B pog\'onasi qoladi',
        () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 1, getId: kOtherId));
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kOtherId, price: 10000, value: 4))
        ..add(makeSoldItem(productId: kPid, price: 25000, value: 7));
      await saveRow(p, 1);
      await saveRow(p, 0);
      expect(productTotal(p, kOtherId), closeTo(36000, 0.01));

      await deleteRow(p, 1);
      final b = rowOf(p, kOtherId);
      expect(b.realPrice, 12000);
      expect(b.price, 12000);
      expect(productTotal(p, kOtherId), closeTo(48000, 0.01));
    });
  });

  // ======================================================================
  // 7. Uch pog'ona
  // ======================================================================
  group('Uch pog\'ona: 1 → 25 000, 3+ → 26 000, 7+ → 27 000', () {
    setUp(() => ItemsSingleton.products = [tierProduct(kThree)]);

    for (int n = 1; n <= 8; n++) {
      final unit = tierUnit(kThree, n).toDouble();
      testWidgets('diskontsiz: $n marta skan → $unit', (tester) async {
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);
        final row = cart(p).single;
        expect(row.price, unit);
        expect(row.realPrice, unit);
      });
    }

    for (int n = 1; n <= 8; n++) {
      final unit = tierUnit(kThree, n).toDouble();
      final free = freeSame(n, buy: 1, get: 1, rep: true);
      final total = unit * (n - free);
      testWidgets('1+1 repeatable: $n marta skan → dona $unit, jami $total',
          (tester) async {
        await seed(tester, [bxgy(buy: 1, repeatable: true)]);
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);
        final row = cart(p).single;
        expect(row.realPrice, unit);
        expect(productTotal(p, kPid), closeTo(total, 0.01));
      });
    }

    testWidgets('1+1 repeatable, OPD 8 → 3 → 2: 108 000 → 52 000 → 25 000',
        (tester) async {
      await seed(tester, [bxgy(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
      await opdSetQty(p, 0, 3);
      expect(rowOf(p, kPid).realPrice, 26000);
      expect(productTotal(p, kPid), closeTo(52000, 0.01));
      await opdSetQty(p, 0, 2);
      expect(rowOf(p, kPid).realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(25000, 0.01));
    });
  });

  // ======================================================================
  // 8. Ikki xil pog'onali mahsulot — bir-biriga ta'sir yo'q
  // ======================================================================
  group('Ikki xil pog\'onali mahsulot bitta savatda', () {
    testWidgets('diskontsiz, aralash skan: A 7 → 27 000, B 3 → 12 000',
        (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();
      // A, B, A, B, A, B, A, A, A, A — A = 7, B = 3
      for (final id in const [
        kPid, kOtherId, kPid, kOtherId, kPid, kOtherId, kPid, kPid, kPid, kPid
      ]) {
        await scan(tester, ctx, p, id: id);
      }
      expect(rowOf(p, kPid).value, 7);
      expect(rowOf(p, kPid).price, 27000);
      expect(rowOf(p, kOtherId).value, 3);
      expect(rowOf(p, kOtherId).price, 12000);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(189000 + 36000, 1));
    });

    testWidgets('A 6 da B 7 ta → A 25 000 qoladi (B soni A ga qo\'shilmaydi)',
        (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 6);
      await scan(tester, ctx, p, value: 7, id: kOtherId);
      expect(rowOf(p, kPid).price, 25000);
      expect(rowOf(p, kOtherId).price, 12000);
    });

    testWidgets('OPD: B 3 → 2 (B 10 000), keyin A 7 → 6 (A 25 000)',
        (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      await scan(tester, ctx, p, value: 3, id: kOtherId);

      await opdSetQty(p, cart(p).indexWhere((e) => e.productId == kOtherId), 2);
      expect(rowOf(p, kOtherId).price, 10000);
      expect(rowOf(p, kPid).price, 27000, reason: 'A ga tegilmaydi');

      await opdSetQty(p, cart(p).indexWhere((e) => e.productId == kPid), 6);
      expect(rowOf(p, kPid).price, 25000);
      expect(rowOf(p, kOtherId).price, 10000, reason: 'B ga tegilmaydi');
    });

    testWidgets('BXGY faqat A da (1+1 rep): A 7 → 108 000, B 3 → 36 000',
        (tester) async {
      await seed(tester, [bxgy(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 3, id: kOtherId);
      await scanN(tester, ctx, p, 7);

      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
      final b = rowOf(p, kOtherId);
      expect(b.realPrice, 12000);
      expect(b.price, 12000, reason: 'B ga aksiya yo\'q');
      expect(b.productDiscount, isEmpty);
      expect(productTotal(p, kOtherId), closeTo(36000, 0.01));
    });

    test('deleteRow: B o\'chirilsa A narxi/tekini o\'zgarmaydi', () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 1, repeatable: true));
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kOtherId, price: 10000, value: 3))
        ..add(makeSoldItem(productId: kPid, price: 25000, value: 7));
      await saveRow(p, 0);
      await saveRow(p, 1);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
      await deleteRow(p, 0);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
    });
  });

  // ======================================================================
  // 9. Foizli mahsulot chegirmasi + qimmatlashuvchi pog'ona (BXGY yo'q)
  // ======================================================================
  group('10% mahsulot chegirmasi + qimmatlashuvchi pog\'ona', () {
    for (int n = 1; n <= 8; n++) {
      final unit = tierUnit(kProd, n).toDouble();
      testWidgets('$n marta skan → realPrice $unit, narx ${unit * 0.9}',
          (tester) async {
        await seed(tester, [percent(10)]);
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);
        final row = cart(p).single;
        expect(row.realPrice, unit);
        expect(row.price, closeTo(unit * 0.9, 0.01));
        expect(row.discountPercent, closeTo(10, 0.001));
        expect(productTotal(p, kPid), closeTo(unit * 0.9 * n, 0.1));
      });
    }

    testWidgets('x7 bir martada → 24 300', (tester) async {
      await seed(tester, [percent(10)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      final row = rowOf(p, kPid);
      expect(row.realPrice, 27000);
      expect(row.price, closeTo(24300, 0.01));
    });

    testWidgets('OPD 7 → 6 → 22 500, 6 → 7 → 24 300', (tester) async {
      await seed(tester, [percent(10)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      await opdSetQty(p, 0, 6);
      expect(rowOf(p, kPid).realPrice, 25000);
      expect(rowOf(p, kPid).price, closeTo(22500, 0.01));
      await opdSetQty(p, 0, 7);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(rowOf(p, kPid).price, closeTo(24300, 0.01));
    });

    testWidgets('chegirma faqat B da: A 7 → 27 000 (chegirmasiz), B 3 → 10 800',
        (tester) async {
      await seed(tester, [percent(10, onlyFor: [kOtherId])]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 7);
      await scanN(tester, ctx, p, 3, id: kOtherId);
      final a = rowOf(p, kPid);
      expect(a.realPrice, 27000);
      expect(a.price, 27000);
      final b = rowOf(p, kOtherId);
      expect(b.realPrice, 12000);
      expect(b.price, closeTo(10800, 0.01));
    });
  });

  // ======================================================================
  // 10. Buy X Get X (bitta qator) + qimmatlashuvchi pog'ona
  // ======================================================================
  group('Buy X Get X (bitta qator) + qimmatlashuvchi pog\'ona', () {
    for (int n = 1; n <= 10; n++) {
      final unit = tierUnit(kProd, n).toDouble();
      final free = freeSame(n, buy: 1, get: 1, rep: true);
      final total = unit * (n - free);
      testWidgets('1+1 rep: $n marta skan → dona $unit, $free tekin, jami $total',
          (tester) async {
        await seed(tester, [bxgx(buy: 1, repeatable: true)]);
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);
        final row = cart(p).single;
        expect(row.value, n);
        expect(row.realPrice, unit, reason: 'pog\'ona narxi yo\'qolmasin');
        expect(productTotal(p, kPid), closeTo(total, 0.01));
      });
    }

    testWidgets('1+1 rep: x8 bir martada → 27 000 × 4 = 108 000',
        (tester) async {
      await seed(tester, [bxgx(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
    });

    testWidgets('1+1 rep: OPD 8 → 6 → 7: 108 000 → 75 000 → 108 000',
        (tester) async {
      await seed(tester, [bxgx(buy: 1, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      await opdSetQty(p, 0, 6);
      expect(rowOf(p, kPid).realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(75000, 0.01));
      await opdSetQty(p, 0, 7);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(108000, 0.01));
    });

    testWidgets('1+1 takrorlanmaydigan: 7 ta → 1 tekin, 27 000 × 6',
        (tester) async {
      await seed(tester, [bxgx(buy: 1)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 7);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(162000, 0.01));
    });

    testWidgets('2+1 rep: 7 ta → 2 tekin, 27 000 × 5 = 135 000',
        (tester) async {
      await seed(tester, [bxgx(buy: 2, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 7);
      expect(rowOf(p, kPid).realPrice, 27000);
      expect(productTotal(p, kPid), closeTo(135000, 0.01));
    });

    testWidgets('2+1 rep: 6 ta → 2 tekin, 25 000 × 4 = 100 000',
        (tester) async {
      await seed(tester, [bxgx(buy: 2, repeatable: true)]);
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 6);
      expect(rowOf(p, kPid).realPrice, 25000);
      expect(productTotal(p, kPid), closeTo(100000, 0.01));
    });
  });
}
