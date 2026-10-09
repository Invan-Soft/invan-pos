// Arzonlashuvchi (ulgurji) pog'ona — tuzatishdan keyingi REGRESSIYA testlari.
//
// KONTEKST (2026-10-08 tuzatishi): `useFreeProducts` (Buy X Get Y) shart
// bajarilganda qatorning narxini SHARTSIZ 1-talik narxga qaytarardi. Endi
// faqat pog'ona narxi 1-talikdan ARZON bo'lsagina qaytaradi (ulgurji +
// tekin ustma-ust tushmasin). Qimmatlashuvchi pog'ona alohida faylda
// (`tier_rising_price_test.dart`).
//
// Bu fayl ASL MAQSAD buzilmaganini tekshiradi — arzonlashuvchi pog'onada
// (1 → 5000, 3+ → 4500, 7+ → 4000):
//   * tekin bor bo'lsa — to'lanadigan donalar 1-talik narxda (5000);
//   * tekin yo'q bo'lsa — sof pog'ona narxi (4500 / 4000);
//   * diskont yo'q — har n da sof pog'ona.
//
// Kutilgan qiymatlar BIZNES QOIDADAN hisoblanadi (`expectedLine`), kod
// hozir nima chiqarayotganidan emas.
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
const kPid = 'tier-id';
const kGetId = 'get-id';
const kFlatId = 'flat-id';

// Qat'iy GUIDlar (discount_helpers.dart dan).
const gGroupBuyXGetY = '86951e75-960f-45d7-9505-9b9cd2ce17a7';
const gTypeBuyXGetY = 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b';
const gGroupBuyXGetX = '316b623e-3bb7-43e2-b6d5-1028c927caba';
const gTypeBuyXGetX = '90d1f774-44bd-49be-9bbf-2e9a44558377';

const kFalling = {1: 5000, 3: 4500, 7: 4000};

// ---------------------------------------------------------------------------
// Biznes qoida (kutilgan qiymatlar shundan hisoblanadi)
// ---------------------------------------------------------------------------

/// Pog'ona: [n] dan oshmaydigan eng katta minQuantity ning narxi.
num tierUnit(Map<int, num> tiers, num n) {
  int best = -1;
  num price = 0;
  tiers.forEach((minQ, p) {
    if (minQ <= n && minQ >= best) {
      best = minQ;
      price = p;
    }
  });
  return price;
}

/// 1-talik narx: eng kichik minQuantity ning narxi.
num onePiece(Map<int, num> tiers) {
  final minQ = tiers.keys.reduce((a, b) => a < b ? a : b);
  return tiers[minQ]!;
}

/// Tekin bor bo'lsa: pog'ona 1-talikdan arzon → 1-talik, aks holda pog'ona.
/// Tekin yo'q: sof pog'ona.
num expectedUnit(Map<int, num> tiers, num n, num free) {
  final tier = tierUnit(tiers, n);
  if (free <= 0) return tier;
  final one = onePiece(tiers);
  return tier < one ? one : tier;
}

num expectedLine(Map<int, num> tiers, num n, num free) =>
    expectedUnit(tiers, n, free) * (n - free);

// ---------------------------------------------------------------------------
// Yasovchilar
// ---------------------------------------------------------------------------

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
      id: 'bxgy-$buyId-$getId',
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

DiscountItem bxgx({required int buy, int get = 1, bool repeatable = false}) =>
    DiscountItem(
      id: 'bxgx',
      name: 'Buy X Get X',
      displayName: 'Buy X Get X',
      discountGroupType: DiscountGroupType(id: gGroupBuyXGetX),
      discountType: DiscountType(id: gTypeBuyXGetX),
      isExpirable: false,
      isForAllClients: true,
      isRepeatable: repeatable,
      shopIds: [ShopIds(id: kShop)],
      buyXGetX: BuyXGetX(
        productsToBuy: [ProductsToBuy(id: kPid, name: 'Tier')],
        buyProductsAmount: buy,
        getProductsAmount: get,
      ),
    );

/// testWidgets ichida Hive IO faqat `runAsync` orqali (aks holda osiladi).
Future<void> addDiscount(WidgetTester tester, DiscountItem d) async {
  await tester.runAsync(() => HiveBoxes.getDiscounts().add(d));
}

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
  // "Aksiya bor" dialogi — kassir kabi "Ok" bosamiz.
  final ok = find.text('Ok');
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> scanN(
    WidgetTester tester, BuildContext ctx, OrderingProvider4 p, int n,
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

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

ReceiptModelSoldItem4 rowOf(OrderingProvider4 p, String id) =>
    cart(p).singleWhere((e) => e.productId == id && !(e.isDeleted ?? false));

int indexOf(OrderingProvider4 p, String id) =>
    cart(p).indexWhere((e) => e.productId == id && !(e.isDeleted ?? false));

double line(ReceiptModelSoldItem4 r) => r.price * r.value;

/// Bitta qatorli mahsulotni biznes qoidaga solishtiradi.
void expectRow(ReceiptModelSoldItem4 r, Map<int, num> tiers, num n, num free,
    {String why = ''}) {
  expect(r.value, n, reason: 'dona soni $why');
  expect(r.realPrice, expectedUnit(tiers, n, free),
      reason: 'dona narxi (n=$n, tekin=$free) $why');
  expect(line(r), closeTo(expectedLine(tiers, n, free), 0.01),
      reason: 'qator jami (n=$n, tekin=$free) $why');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('tier_cases_falling_regression_test');
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
      tierProduct(kFalling),
      tierProduct(kFalling, id: kGetId),
      tierProduct(const {1: 3000}, id: kFlatId),
    ];
  });

  // -------------------------------------------------------------------------
  group('Biznes qoida yordamchisi (o\'zini tekshirish)', () {
    test('tierUnit / expectedLine', () {
      expect(tierUnit(kFalling, 1), 5000);
      expect(tierUnit(kFalling, 2), 5000);
      expect(tierUnit(kFalling, 3), 4500);
      expect(tierUnit(kFalling, 6), 4500);
      expect(tierUnit(kFalling, 7), 4000);
      expect(tierUnit(kFalling, 100), 4000);
      expect(expectedLine(kFalling, 8, 4), 20000);
      expect(expectedLine(kFalling, 8, 0), 32000);
      expect(expectedLine(const {1: 25000, 7: 27000}, 8, 4), 108000);
    });
  });

  // -------------------------------------------------------------------------
  group(
      'Diskontsiz: sof arzonlashuvchi pog\'ona (1 → 5000, 3+ → 4500, 7+ → 4000)',
      () {
    for (int n = 1; n <= 8; n++) {
      final unit = tierUnit(kFalling, n);
      testWidgets('bittadan $n marta skan → dona $unit, jami ${unit * n}',
          (tester) async {
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);
        final r = cart(p).single;
        expectRow(r, kFalling, n, 0);
        expect(r.price, unit);
        expect(r.singleDiscount, 0);
        expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(unit * n, 1));
      });
    }

    for (final n in const [3, 7, 8]) {
      testWidgets('x$n bir martada → ${tierUnit(kFalling, n)}', (tester) async {
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scan(tester, ctx, p, value: n.toDouble());
        expectRow(cart(p).single, kFalling, n, 0);
      });
    }

    testWidgets('OPD: 1 → 8 → 4 → 2 → 7 — har safar pog\'ona qayta tanlanadi',
        (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p);
      for (final n in const [8, 4, 2, 7]) {
        await opdSetQty(p, 0, n.toDouble());
        expectRow(cart(p).single, kFalling, n, 0, why: 'OPD → $n');
        expect(cart(p).single.price, tierUnit(kFalling, n));
      }
    });
  });

  // -------------------------------------------------------------------------
  group('Buy X Get Y: o\'sha mahsulot, 1+1, takrorlanadigan', () {
    for (int n = 1; n <= 8; n++) {
      final free = n ~/ 2;
      testWidgets(
          '$n marta skan → $free tekin, to\'lanadigan dona '
          '${expectedUnit(kFalling, n, free)}, jami ${expectedLine(kFalling, n, free)}',
          (tester) async {
        await addDiscount(tester, bxgy(buy: 1, repeatable: true));
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, n);
        expectRow(cart(p).single, kFalling, n, free);
        expect(ItemsSingleton.getTotalPrice(cart(p)),
            closeTo(expectedLine(kFalling, n, free), 1));
      });
    }

    testWidgets('x8 bir martada → 4 × 5000 = 20 000 (4000 emas)',
        (tester) async {
      await addDiscount(tester, bxgy(buy: 1, repeatable: true));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      final r = cart(p).single;
      expect(r.realPrice, 5000, reason: 'ulgurji + tekin ustma-ust tushmasin');
      expect(line(r), closeTo(20000, 0.01));
      expect(r.singleDiscount * r.value, closeTo(4 * 5000, 0.01),
          reason: 'chegirma = 4 tekin dona × 1-talik narx');
    });
  });

  // -------------------------------------------------------------------------
  group('Buy X Get Y: o\'sha mahsulot, 2 olsa 1 tekin, takrorlanadigan', () {
    testWidgets('bittadan 1..9 skan — har qadamda biznes qoida',
        (tester) async {
      await addDiscount(tester, bxgy(buy: 2, repeatable: true));
      final ctx = await appContext(tester);
      final p = freshProvider();
      for (int n = 1; n <= 9; n++) {
        await scan(tester, ctx, p);
        expectRow(cart(p).single, kFalling, n, n ~/ 3, why: '(2+1, n=$n)');
      }
    });

    testWidgets('x9 bir martada → 3 tekin, 6 × 5000 = 30 000', (tester) async {
      await addDiscount(tester, bxgy(buy: 2, repeatable: true));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 9);
      expectRow(cart(p).single, kFalling, 9, 3);
      expect(line(cart(p).single), closeTo(30000, 0.01));
    });
  });

  // -------------------------------------------------------------------------
  group('Buy X Get Y: takrorlanmaydigan', () {
    testWidgets('1+1: bittadan 1..8 skan — faqat 1 ta tekin', (tester) async {
      await addDiscount(tester, bxgy(buy: 1));
      final ctx = await appContext(tester);
      final p = freshProvider();
      for (int n = 1; n <= 8; n++) {
        await scan(tester, ctx, p);
        expectRow(cart(p).single, kFalling, n, n >= 2 ? 1 : 0,
            why: '(1+1 bir martalik, n=$n)');
      }
      expect(line(cart(p).single), closeTo(7 * 5000, 0.01));
    });

    testWidgets('5+1: 5 ta → sof 4500 (tekin yo\'q), 6 ta → 5 × 5000',
        (tester) async {
      await addDiscount(tester, bxgy(buy: 5));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 5);
      expectRow(cart(p).single, kFalling, 5, 0, why: '(shart bajarilmagan)');
      expect(cart(p).single.price, 4500);

      await scan(tester, ctx, p);
      expectRow(cart(p).single, kFalling, 6, 1);
      expect(line(cart(p).single), closeTo(25000, 0.01));

      await scanN(tester, ctx, p, 2);
      expectRow(cart(p).single, kFalling, 8, 1);
      expect(line(cart(p).single), closeTo(35000, 0.01));
    });
  });

  // -------------------------------------------------------------------------
  group('Buy X Get Y: shart bajarilmasa — sof pog\'ona saqlanadi', () {
    testWidgets('20+1, bittadan 3 skan → 4500', (tester) async {
      await addDiscount(tester, bxgy(buy: 20));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 3);
      final r = cart(p).single;
      expectRow(r, kFalling, 3, 0);
      expect(r.price, 4500);
      expect(r.singleDiscount, 0);
    });

    testWidgets('20+1, bittadan 8 skan → 4000', (tester) async {
      await addDiscount(tester, bxgy(buy: 20));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 8);
      final r = cart(p).single;
      expectRow(r, kFalling, 8, 0);
      expect(r.price, 4000);
      expect(
          r.productDiscount.where((d) => d.typeName == 'Buy X Get Y'), isEmpty);
    });

    testWidgets('20+1, x8 bir martada → 4000', (tester) async {
      await addDiscount(tester, bxgy(buy: 20));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(cart(p).single.price, 4000);
      expect(cart(p).single.realPrice, 4000);
    });
  });

  // -------------------------------------------------------------------------
  group('Buy X Get Y: boshqa GET mahsulot (A olsa B tekin)', () {
    testWidgets('A × 3 + B × 1 → A sof 4500, B tekin (0)', (tester) async {
      await addDiscount(tester, bxgy(buy: 3, getId: kGetId));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 3);
      await scan(tester, ctx, p, id: kGetId);

      expectRow(rowOf(p, kPid), kFalling, 3, 0, why: '(A — sotib olinadigan)');
      expect(rowOf(p, kGetId).price, 0);
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(13500, 1));
    });

    testWidgets('A × 3 + B × 3 → B ning to\'lanadigan 2 donasi 5000 da',
        (tester) async {
      await addDiscount(tester, bxgy(buy: 3, getId: kGetId));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 3);
      await scanN(tester, ctx, p, 3, id: kGetId);

      expectRow(rowOf(p, kPid), kFalling, 3, 0, why: '(A)');
      expectRow(rowOf(p, kGetId), kFalling, 3, 1, why: '(B)');
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(13500 + 10000, 1));
    });

    testWidgets('takrorlanadigan: A × 6 + B × 3 → B dan 2 tekin',
        (tester) async {
      await addDiscount(tester, bxgy(buy: 3, getId: kGetId, repeatable: true));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 6);
      await scanN(tester, ctx, p, 3, id: kGetId);

      expectRow(rowOf(p, kPid), kFalling, 6, 0, why: '(A)');
      expectRow(rowOf(p, kGetId), kFalling, 3, 2, why: '(B)');
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(27000 + 5000, 1));
    });

    testWidgets('A × 2 (shart yo\'q) + B × 3 → B sof 4500', (tester) async {
      await addDiscount(tester, bxgy(buy: 3, getId: kGetId));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 2);
      await scanN(tester, ctx, p, 3, id: kGetId);

      expectRow(rowOf(p, kPid), kFalling, 2, 0, why: '(A)');
      expectRow(rowOf(p, kGetId), kFalling, 3, 0, why: '(B)');
      expect(rowOf(p, kGetId).price, 4500);
    });

    testWidgets(
      '[BUG] A OPD da 3 → 2 ga tushsa B tekinini yo\'qotadi va sof 4500 ga qaytadi '
      '(eski 5000 qolmasin)',
      (tester) async {
        await addDiscount(tester, bxgy(buy: 3, getId: kGetId));
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, 3);
        await scanN(tester, ctx, p, 3, id: kGetId);
        expect(rowOf(p, kGetId).realPrice, 5000,
            reason: 'setup: B tekin bilan');

        await opdSetQty(p, indexOf(p, kPid), 2);

        expectRow(rowOf(p, kPid), kFalling, 2, 0, why: '(A)');
        expectRow(rowOf(p, kGetId), kFalling, 3, 0,
            why: '(B — chegirma yo\'q, sof pog\'ona 4500 bo\'lishi kerak)');
      },
      // BUG (eski, tuzatishdan oldin ham bor): discount_effects_controller.dart:214 B ning realPrice'ini 1-talikka yozadi; A shartdan tushganda _clearStale → resetItemDiscount (:555) price = realPrice (5000) qiladi, B qayta pog'onalanmaydi (pressDialogSaveButton faqat A ni reprice qiladi).
      skip: true,
    );
  });

  // -------------------------------------------------------------------------
  group('OPD: chegaradan o\'tib, qaytib tushish — eski 5000 qolmasin', () {
    testWidgets('5+1 bir martalik: 1 → 8 → 5 → 2 → 6 → 3', (tester) async {
      await addDiscount(tester, bxgy(buy: 5));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p);

      const steps = {8: 1, 5: 0, 2: 0, 6: 1, 3: 0};
      for (final e in steps.entries) {
        await opdSetQty(p, 0, e.key.toDouble());
        final r = cart(p).single;
        expectRow(r, kFalling, e.key, e.value, why: '(OPD → ${e.key})');
        if (e.value == 0) {
          expect(r.price, tierUnit(kFalling, e.key),
              reason: 'tekin yo\'q — sof pog\'ona (OPD → ${e.key})');
          expect(r.singleDiscount, 0);
        }
      }
    });

    testWidgets('1+1 takrorlanadigan: x8 → OPD 3 → 1 → 7', (tester) async {
      await addDiscount(tester, bxgy(buy: 1, repeatable: true));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expectRow(cart(p).single, kFalling, 8, 4);

      for (final n in const [3, 1, 7]) {
        await opdSetQty(p, 0, n.toDouble());
        expectRow(cart(p).single, kFalling, n, n ~/ 2, why: '(OPD → $n)');
      }
    });

    testWidgets(
        'aksiya o\'chirilgach (WS type 17) o\'sha mahsulot OPD qilinsa — '
        'sof 4000', (tester) async {
      await addDiscount(tester, bxgy(buy: 1, repeatable: true));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(cart(p).single.realPrice, 5000, reason: 'setup');

      await tester.runAsync(() => HiveBoxes.getDiscounts().clear());
      await opdSetQty(p, 0, 8);

      expectRow(cart(p).single, kFalling, 8, 0);
      expect(cart(p).single.price, 4000);
    });

    testWidgets(
      '[BUG] aksiya o\'chirilgach (WS type 17) boshqa mahsulot skan qilinsa — '
      'tier mahsulot sof 4000 ga qaytadi',
      (tester) async {
        await addDiscount(tester, bxgy(buy: 1, repeatable: true));
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scan(tester, ctx, p, value: 8);
        expect(rowOf(p, kPid).realPrice, 5000, reason: 'setup');

        await tester.runAsync(() => HiveBoxes.getDiscounts().clear());
        await scan(tester, ctx, p, id: kFlatId);

        expectRow(rowOf(p, kPid), kFalling, 8, 0,
            why: '(aksiya yo\'q — 8 dona sof 4000)');
        expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(32000 + 3000, 1));
      },
      // BUG (eski): aksiya yo'qolgach _clearStale → resetItemDiscount (discount_effects_controller.dart:555) price = realPrice — realPrice esa :214 da 1-talik 5000 ga almashtirilgan; pog'ona 4000 faqat o'sha mahsulot qayta narxlanganda tiklanadi.
      skip: true,
    );
  });

  // -------------------------------------------------------------------------
  group('Buy X Get X: bitta qator, arzonlashuvchi pog\'ona', () {
    testWidgets('3+1 bir martalik, bittadan 8 skan → 7 × 5000 (4000 emas)',
        (tester) async {
      await addDiscount(tester, bxgx(buy: 3));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 8);
      expectRow(cart(p).single, kFalling, 8, 1);
      expect(line(cart(p).single), closeTo(35000, 0.01));
    });

    testWidgets('1+1 takrorlanadigan, x8 → 4 × 5000 = 20 000', (tester) async {
      await addDiscount(tester, bxgx(buy: 1, repeatable: true));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expectRow(cart(p).single, kFalling, 8, 4);
    });

    testWidgets('1+1 takrorlanadigan, x7 → 3 tekin, 4 × 5000', (tester) async {
      await addDiscount(tester, bxgx(buy: 1, repeatable: true));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 7);
      expectRow(cart(p).single, kFalling, 7, 3);
    });

    testWidgets('10+1: shart umuman yaqin emas (8 ta) → sof 4000',
        (tester) async {
      await addDiscount(tester, bxgx(buy: 10));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanN(tester, ctx, p, 8);
      expectRow(cart(p).single, kFalling, 8, 0);
      expect(cart(p).single.price, 4000);
    });

    testWidgets(
      '[BUG] 3+1: 3 ta (tekin hali yo\'q, set = 4) → sof 4500 bo\'lishi kerak',
      (tester) async {
        await addDiscount(tester, bxgx(buy: 3));
        final ctx = await appContext(tester);
        final p = freshProvider();
        await scanN(tester, ctx, p, 3);
        final r = cart(p).single;
        expectRow(r, kFalling, 3, 0, why: '(tekin 0 — sof pog\'ona)');
        expect(r.price, 4500);
      },
      // BUG (eski, tuzatish tegmagan useBuyXGetXProducts): discount_helpers.dart:383 (totalQty + 1 >= buy) ro'yxatga qo'shadi, discount_effects_controller.dart:403 tekin soni (0) hisoblanishidan OLDIN realPrice ni 1-talik 5000 ga ko'taradi.
      skip: true,
    );
  });

  // -------------------------------------------------------------------------
  group('Bitta pog\'onali mahsulot (faqat 1 → 5000) + BXGY 1+1 takrorlanadigan',
      () {
    const flat = {1: 5000};
    testWidgets('bittadan 1..8 skan → doim 5000, tekin = n ~/ 2',
        (tester) async {
      await addDiscount(tester, bxgy(buy: 1, repeatable: true));
      ItemsSingleton.products = [tierProduct(flat)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      for (int n = 1; n <= 8; n++) {
        await scan(tester, ctx, p);
        expectRow(cart(p).single, flat, n, n ~/ 2, why: '(n=$n)');
      }
    });

    testWidgets('x8 → 4 × 5000 = 20 000', (tester) async {
      await addDiscount(tester, bxgy(buy: 1, repeatable: true));
      ItemsSingleton.products = [tierProduct(flat)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expect(cart(p).single.realPrice, 5000);
      expect(line(cart(p).single), closeTo(20000, 0.01));
    });
  });

  // -------------------------------------------------------------------------
  group('Teng pog\'onalar (1 → 5000, 7 → 5000)', () {
    const equal = {1: 5000, 7: 5000};

    testWidgets('diskontsiz: bittadan 1..8 → doim 5000', (tester) async {
      ItemsSingleton.products = [tierProduct(equal)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      for (int n = 1; n <= 8; n++) {
        await scan(tester, ctx, p);
        expectRow(cart(p).single, equal, n, 0, why: '(n=$n)');
        expect(cart(p).single.price, 5000);
      }
    });

    testWidgets('BXGY 1+1 takrorlanadigan: bittadan 1..8 → 5000, tekin n ~/ 2',
        (tester) async {
      await addDiscount(tester, bxgy(buy: 1, repeatable: true));
      ItemsSingleton.products = [tierProduct(equal)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      for (int n = 1; n <= 8; n++) {
        await scan(tester, ctx, p);
        expectRow(cart(p).single, equal, n, n ~/ 2, why: '(n=$n)');
      }
    });

    testWidgets('BXGX 3+1: x8 → 7 × 5000', (tester) async {
      await addDiscount(tester, bxgx(buy: 3));
      ItemsSingleton.products = [tierProduct(equal)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expectRow(cart(p).single, equal, 8, 1);
    });
  });

  // -------------------------------------------------------------------------
  group('Tartibsiz pog\'onalar (7 → 4000, 3 → 4500, 1 → 5000) + BXGY', () {
    const unordered = {7: 4000, 3: 4500, 1: 5000};

    testWidgets(
        '1+1 takrorlanadigan, x8 → 1-talik 5000 (ro\'yxat boshi 4000 emas)',
        (tester) async {
      await addDiscount(tester, bxgy(buy: 1, repeatable: true));
      ItemsSingleton.products = [tierProduct(unordered)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scan(tester, ctx, p, value: 8);
      expectRow(cart(p).single, unordered, 8, 4);
      expect(line(cart(p).single), closeTo(20000, 0.01));
    });

    testWidgets('diskontsiz: bittadan 1..8 → sof pog\'ona', (tester) async {
      ItemsSingleton.products = [tierProduct(unordered)];
      final ctx = await appContext(tester);
      final p = freshProvider();
      for (int n = 1; n <= 8; n++) {
        await scan(tester, ctx, p);
        expectRow(cart(p).single, unordered, n, 0, why: '(n=$n)');
      }
    });
  });

  // -------------------------------------------------------------------------
  // Blok qatori: `adjustedFirstTierPrice = 1-talik × boxValue`. Qatorlar
  // to'g'ridan-to'g'ri quriladi (skan oqimi markirovka/blok shtrix-kodi talab
  // qiladi) va diskont effekti qo'llanadi.
  group('Blok qatori (boxValue = 6) + BXGY 5+1 — unit', () {
    test('1 blok (6 dona, pog\'ona 4500) → blok narxi 6 × 5000, 1 tekin',
        () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 5));
      final p = freshProvider();
      cart(p).add(makeSoldItem(
          productId: kPid,
          price: 4500 * 6,
          value: 1,
          saleType: 2,
          boxValue: 6));
      p.findFreeProducts();
      p.useFreeProducts();

      final box = cart(p).single;
      expect(box.realPrice, 5000 * 6);
      expect(line(box), closeTo(expectedLine(kFalling, 6, 1), 0.01));
    });

    test('1 blok + 2 dona (jami 8, pog\'ona 4000) → 7 × 5000', () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 5));
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(
            productId: kPid,
            price: 4000 * 6,
            value: 1,
            saleType: 2,
            boxValue: 6))
        ..add(makeSoldItem(productId: kPid, price: 4000, value: 2));
      p.findFreeProducts();
      p.useFreeProducts();

      final box = cart(p).firstWhere((e) => e.saleType == 2);
      final piece = cart(p).firstWhere((e) => e.saleType != 2);
      expect(box.realPrice, 5000 * 6);
      expect(piece.realPrice, 5000);
      expect(piece.price, 5000);
      expect(
          line(box) + line(piece), closeTo(expectedLine(kFalling, 8, 1), 0.01));
    });

    test('shart bajarilmasa (20+1) blok pog\'ona narxida qoladi', () async {
      await HiveBoxes.getDiscounts().add(bxgy(buy: 20));
      final p = freshProvider();
      cart(p).add(makeSoldItem(
          productId: kPid,
          price: 4500 * 6,
          value: 1,
          saleType: 2,
          boxValue: 6));
      p.findFreeProducts();
      p.useFreeProducts();
      expect(cart(p).single.price, 4500 * 6);
      expect(cart(p).single.realPrice, 4500 * 6);
    });
  });
}
