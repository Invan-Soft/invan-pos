// Pog'onali narx (tier) — qator SHAKLLARI bo'yicha: blok (saleType 2),
// markirovkali (har skan alohida qator) va kilolik mahsulot.
//
// Tekshirilayotgan tuzatish (2026-10-08): `useFreeProducts` Buy X Get Y shart
// bajarilganda narxni endi faqat pog'ona 1-talikdan ARZON bo'lsa 1-talikka
// ko'taradi (blok qatorida 1-talik × boxValue bilan solishtiriladi). Pog'ona
// QIMMAT bo'lsa (1 → 25 000, 7+ → 27 000) pog'ona narxi saqlanadi.
//
// Biznes qoidalar (kutilgan qiymatlar shulardan, koddan emas):
//   * pog'ona = savatdagi shu mahsulot JAMI donasi (dona qatorlari value +
//     blok qatorlari value × boxValue) dan oshmaydigan eng katta minQuantity;
//     barcha qatorlar shu dona narxini oladi (blok = dona × boxValue);
//   * Buy X Get Y: pog'ona 1-talikdan ARZON bo'lsa to'lanadigan donalar
//     1-talik narxda (ulgurji + tekin ustma-ust tushmaydi); QIMMAT bo'lsa
//     pog'ona narxi qoladi;
//   * diskont yo'q → sof pog'ona narxi.
//
// Kirish yo'llari: blok — real skan (`onBarcodeScanned` → `_addBoxProduct`);
// marka — `addSeperatedProduct` (KM tekshiruvidan keyingi real yo'l);
// kg — `addProduct(isTarozi: true)` (tarozi yo'li, OPD dialogi ochilmaydi);
// OPD / o'chirish / guruh tahriri — `pressDialogSaveButton` /
// `pressDialogDeleteButton` (savat to'g'ridan-to'g'ri quriladi).
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
const kPid = 'tier-blok-id';
const kBoxEan = '4780000000017';
// Sut mahsuloti (alkogol emas) — markirovka qatori `mxikCode!` ni o'qiydi.
const kMxik = '04011001001000000';

// Buy X Get Y uchun qat'iy GUIDlar (discount_helpers.dart dan).
const gGroupBuyXGetY = '86951e75-960f-45d7-9505-9b9cd2ce17a7';
const gTypeBuyXGetY = 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b';

/// Prod sozlamasi: 1 ta → 25 000, 7+ ta → 27 000 (ko'p olsa QIMMAT).
const kRising = {1: 25000, 7: 27000};

/// Odatiy ulgurji: 1 → 5000, 3+ → 4500, 7+ → 4000 (ko'p olsa ARZON).
const kFalling = {1: 5000, 3: 4500, 7: 4000};

ItemModel tierProduct(
  Map<int, num> tiers, {
  int boxValue = 6,
  String unit = 'dona',
  bool isMarking = false,
}) {
  final m = ItemModel();
  m.id = kPid;
  m.name = 'Saryog\' blok';
  m.sku = '1';
  m.barcode = [kPid];
  m.packageCode = 'PACK-1';
  m.mxikCode = kMxik;
  m.isMarking = isMarking;
  m.vat = Vat(percentage: 12);
  m.measurementUnit = MeasurementUnit(shortName: unit);
  m.hasBoxBarcode = true;
  m.boxBarcode = kBoxEan;
  m.boxBarcodeQuantity = boxValue;
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: kShop, shopPriceTiers: [
      for (final t in tiers.entries)
        ShopPriceTiers(minQuantity: t.key, retailPrice: t.value)
    ]),
  );
  return m;
}

/// Katalogga qo'yadi — blok skan `barcodeProducts` dan qidiradi.
void useCatalog(ItemModel m) {
  ItemsSingleton.products = [m];
  ItemsSingleton.barcodeProducts = [m];
}

DiscountItem buyXGetY({
  required int buy,
  int get = 1,
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
        productsToBuy: [ProductsToBuy(id: kPid, name: 'Saryog\'')],
        buyProductsAmount: buy,
        productToGet: ProductsToGet(id: kPid, name: 'Saryog\''),
        getProductsAmount: get,
      ),
    );

/// Prod'dagi aniq aksiya: o'sha mahsulot, 1 olsa 1 tekin, repeatable.
DiscountItem prodPromo() => buyXGetY(buy: 1, repeatable: true);

/// testWidgets ichida Hive IO faqat `runAsync` orqali.
Future<void> addDiscount(WidgetTester tester, DiscountItem d) =>
    tester.runAsync(() => HiveBoxes.getDiscounts().add(d));

/// `addProduct` / marka / blok yo'llari `AppNavigation.navigatorKey` ni o'qiydi.
/// [scaffoldKey] — tarozi yorlig'i yo'li `scaffoldKey.currentState!.context`
/// ni o'qiydi.
Future<BuildContext> appContext(WidgetTester tester,
    {GlobalKey<ScaffoldState>? scaffoldKey}) async {
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    navigatorKey: AppNavigation.navigatorKey,
    locale: const Locale('uz'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(key: scaffoldKey, body: Builder(builder: (c) {
      captured = c;
      SizeConfig().init(c);
      return const SizedBox();
    })),
  ));
  return captured;
}

/// "Aksiya bor" dialogini kassir kabi yopadi (bo'lsa).
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  final ok = find.text('Ok');
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Oddiy dona skan (shtrix-kod).
Future<void> scanPiece(WidgetTester tester, BuildContext ctx,
    OrderingProvider4 p,
    {double value = 1}) async {
  p.addProduct(
      value: value,
      product: ItemsSingleton.getProductById(kPid)!,
      where: 'test',
      context: ctx);
  await settle(tester);
}

int _boxSerial = 0;

/// Blok KM skani: `01` + GTIN-14 (0 + blok EAN-13) + `21` + seriya.
Future<void> scanBox(WidgetTester tester, OrderingProvider4 p) async {
  _boxSerial++;
  final code = '010${kBoxEan}21S${_boxSerial.toString().padLeft(6, '0')}';
  p.onBarcodeScanned(code, GlobalKey<ScaffoldState>());
  await settle(tester);
}

int _markSerial = 0;

/// Markirovkali dona: KM tekshiruvidan o'tgach chaqiriladigan real yo'l —
/// har skan ALOHIDA qator (value 1).
Future<void> scanMark(WidgetTester tester, OrderingProvider4 p) async {
  _markSerial++;
  final scanned = ItemModel()
    ..id = kPid
    ..mark = '0104780000000024215KM${_markSerial.toString().padLeft(6, '0')}';
  p.addSeperatedProduct(scanned);
  await settle(tester);
}

/// Tarozi yo'li — kg mahsulot qo'shilganda OPD dialogi ochilmaydi.
Future<void> addKg(WidgetTester tester, BuildContext ctx, OrderingProvider4 p,
    double kg) async {
  p.addProduct(
      value: kg,
      product: ItemsSingleton.getProductById(kPid)!,
      where: 'test',
      context: ctx,
      isTarozi: true);
  await settle(tester);
}

/// Tarozi yorlig'i: `28` + PLU(5) + og'irlik (gramm × 10, 6 xona).
/// PLU `00001` → katalogdagi SKU `1`.
String taroziLabel(double kg) =>
    '2800001${(kg * 10000).round().toString().padLeft(6, '0')}';

Future<void> scanScale(WidgetTester tester, OrderingProvider4 p,
    GlobalKey<ScaffoldState> key, double kg) async {
  p.onBarcodeScanned(taroziLabel(kg), key);
  await settle(tester);
}

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

List<ReceiptModelSoldItem4> active(OrderingProvider4 p) =>
    cart(p).where((e) => !(e.isDeleted ?? false)).toList();

ReceiptModelSoldItem4 boxRow(OrderingProvider4 p) =>
    active(p).firstWhere((e) => e.saleType == 2);

List<ReceiptModelSoldItem4> boxRows(OrderingProvider4 p) =>
    active(p).where((e) => e.saleType == 2).toList();

ReceiptModelSoldItem4 pieceRow(OrderingProvider4 p) =>
    active(p).firstWhere((e) => e.saleType != 2);

/// Savatning to'lanadigan summasi (yaxlitlashsiz): Σ price × value.
double payable(OrderingProvider4 p) =>
    active(p).fold<double>(0, (s, e) => s + e.price * e.value);

/// Jami dona (blok = value × boxValue).
num units(OrderingProvider4 p) => active(p).fold<num>(
    0, (s, e) => s + (e.saleType == 2 ? e.value * e.boxValue : e.value));

// ---- Savatni to'g'ridan-to'g'ri quruvchi yordamchilar (OPD testlari) ----

ReceiptModelSoldItem4 box(int boxValue, {double unit = 1}) => makeSoldItem(
      productId: kPid,
      price: unit * boxValue,
      value: 1,
      saleType: 2,
      boxValue: boxValue,
      boxQuantity: 1,
    );

ReceiptModelSoldItem4 piece(double value, {double unit = 1}) =>
    makeSoldItem(productId: kPid, price: unit, value: value);

ReceiptModelSoldItem4 markRow(String km, {double unit = 1}) => makeSoldItem(
    productId: kPid, price: unit, value: 1, marking: true, mark: km);

/// OPD "Saqlash" — qator o'zgarishsiz (tier + diskont effektlari qayta).
Future<void> saveRow(OrderingProvider4 p, int index) async {
  p.tapIndexToEdit(index);
  await p.pressDialogSaveButton(cart(p)[index]);
}

/// OPD dialogidagi qty o'zgarishi (dialog qator NUSXASINI beradi).
Future<void> opdSetQty(OrderingProvider4 p, int index, double qty) async {
  final row = cart(p)[index];
  p.tapIndexToEdit(index);
  await p.pressDialogSaveButton(makeSoldItem(
    productId: row.productId,
    price: row.price,
    realPrice: row.realPrice,
    onlyPrice: row.onlyPrice,
    value: qty,
    isKg: row.isKg,
  ));
}

void deleteRow(OrderingProvider4 p, int index) {
  p.tapIndexToEdit(index);
  p.pressDialogDeleteButton();
}

int indexWhere(OrderingProvider4 p, bool Function(ReceiptModelSoldItem4) f) =>
    cart(p).indexWhere(f);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('tier_cases_box_marking_kg_test');
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
  });

  // ===================================================================
  // A. BLOK SKAN — diskontsiz, sof pog'ona
  // ===================================================================
  group('Blok skan — qimmatlashuvchi pog\'ona (1 → 25 000, 7+ → 27 000)', () {
    testWidgets('1 blok (6 dona) → dona 25 000, blok 150 000', (tester) async {
      useCatalog(tierProduct(kRising, boxValue: 6));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      final b = boxRow(p);
      expect(b.saleType, 2);
      expect(b.boxValue, 6);
      expect(b.price, 25000 * 6);
      expect(b.realPrice, 25000 * 6);
    });

    testWidgets('1 blok (8 dona) — blokning o\'zi 7+ pog\'onaga yetadi → '
        'blok 8 × 27 000', (tester) async {
      useCatalog(tierProduct(kRising, boxValue: 8));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).price, 27000 * 8);
      expect(ItemsSingleton.getTotalPrice(cart(p)), 216000);
    });

    testWidgets('2 blok (6 + 6 = 12) → ikkala blok ham 6 × 27 000',
        (tester) async {
      useCatalog(tierProduct(kRising, boxValue: 6));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).price, 25000 * 6, reason: '6 dona — hali 1-pog\'ona');
      await scanBox(tester, p);
      expect(boxRows(p), hasLength(2));
      for (final b in boxRows(p)) {
        expect(b.price, 27000 * 6);
      }
      expect(payable(p), 27000 * 12);
    });

    testWidgets('ARALASH: blok (6) + 1 dona = 7 → blok 162 000, dona 27 000',
        (tester) async {
      useCatalog(tierProduct(kRising, boxValue: 6));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanPiece(tester, ctx, p);
      expect(active(p), hasLength(2));
      expect(boxRow(p).price, 27000 * 6);
      expect(pieceRow(p).price, 27000);
      expect(payable(p), 27000 * 7);
    });

    testWidgets('ARALASH teskari tartib: 1 dona, keyin blok (6) → '
        'dona qatori ham 27 000 ga ko\'tariladi', (tester) async {
      useCatalog(tierProduct(kRising, boxValue: 6));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanPiece(tester, ctx, p);
      expect(pieceRow(p).price, 25000);
      await scanBox(tester, p);
      expect(pieceRow(p).price, 27000);
      expect(pieceRow(p).realPrice, 27000);
      expect(boxRow(p).price, 27000 * 6);
    });

    testWidgets('ARALASH: blok (4) + 2 dona = 6 → 25 000; +1 dona = 7 → 27 000',
        (tester) async {
      useCatalog(tierProduct(kRising, boxValue: 4));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanPiece(tester, ctx, p, value: 2);
      expect(units(p), 6);
      expect(boxRow(p).price, 25000 * 4);
      expect(pieceRow(p).price, 25000);
      await scanPiece(tester, ctx, p);
      expect(units(p), 7);
      expect(boxRow(p).price, 27000 * 4);
      expect(pieceRow(p).price, 27000);
    });
  });

  group('Blok skan — arzonlashuvchi pog\'ona (1 → 5000, 3+ → 4500, 7+ → 4000)',
      () {
    testWidgets('1 blok (6) → dona 4500, blok 27 000', (tester) async {
      useCatalog(tierProduct(kFalling, boxValue: 6));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).price, 4500 * 6);
    });

    testWidgets('1 blok (2) → 1-pog\'ona, blok 10 000', (tester) async {
      useCatalog(tierProduct(kFalling, boxValue: 2));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).price, 5000 * 2);
    });

    testWidgets('ARALASH: blok (6) + 1 dona = 7 → blok 24 000, dona 4000',
        (tester) async {
      useCatalog(tierProduct(kFalling, boxValue: 6));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanPiece(tester, ctx, p);
      expect(boxRow(p).price, 4000 * 6);
      expect(pieceRow(p).price, 4000);
      expect(payable(p), 4000 * 7);
    });

    testWidgets('2 blok (6 + 6 = 12) → ikkalasi 24 000', (tester) async {
      useCatalog(tierProduct(kFalling, boxValue: 6));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanBox(tester, p);
      for (final b in boxRows(p)) {
        expect(b.price, 4000 * 6);
      }
    });
  });

  // ===================================================================
  // B. BLOK + BUY X GET Y (tuzatishning blok shoxi: 1-talik × boxValue)
  // ===================================================================
  group('Blok + Buy X Get Y (prod: 1+1 repeatable)', () {
    testWidgets(
        'QIMMAT: 1 blok (8) → blok 216 000 saqlanadi, 4 tekin → 108 000',
        (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 8));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      final b = boxRow(p);
      expect(b.realPrice, 27000 * 8,
          reason: 'qimmat pog\'ona 1-talik × 8 ga tushmasin');
      expect(payable(p), closeTo(4 * 27000, 0.01));
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(108000, 1));
    });

    testWidgets('QIMMAT: 1 blok (6) — 7 ga yetmaydi → 25 000, 3 tekin → 75 000',
        (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 6));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).realPrice, 25000 * 6);
      expect(payable(p), closeTo(3 * 25000, 0.01));
    });

    testWidgets(
        'QIMMAT ARALASH: blok (6) + 2 dona = 8 → 27 000, 4 tekin → 108 000',
        (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 6));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanPiece(tester, ctx, p);
      await scanPiece(tester, ctx, p);
      expect(units(p), 8);
      expect(boxRow(p).realPrice, 27000 * 6);
      expect(pieceRow(p).realPrice, 27000);
      expect(payable(p), closeTo(4 * 27000, 0.01));
    });

    testWidgets(
        'QIMMAT ARALASH oraliq: blok (6) + 1 dona = 7 → 27 000, '
        '3 tekin → 4 × 27 000', (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 6));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(payable(p), closeTo(3 * 25000, 0.01), reason: '6 dona, 3 tekin');
      await scanPiece(tester, ctx, p);
      expect(boxRow(p).realPrice, 27000 * 6);
      expect(pieceRow(p).realPrice, 27000);
      expect(payable(p), closeTo(4 * 27000, 0.01));
    });

    testWidgets('QIMMAT: 2 blok (6 + 6) → 12 dona, 6 tekin → 6 × 27 000',
        (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 6));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanBox(tester, p);
      for (final b in boxRows(p)) {
        expect(b.realPrice, 27000 * 6);
      }
      expect(payable(p), closeTo(6 * 27000, 0.01));
    });

    testWidgets(
        'ARZON: 1 blok (8) → 4000 emas, 1-talik × 8 = 40 000; '
        '4 tekin → 4 × 5000', (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kFalling, boxValue: 8));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).realPrice, 5000 * 8,
          reason: 'ulgurji + tekin ustma-ust tushmasin');
      expect(payable(p), closeTo(4 * 5000, 0.01));
    });

    testWidgets(
        'ARZON ARALASH: blok (6) + 2 dona = 8 → hammasi 1-talik, '
        '4 tekin → 4 × 5000', (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kFalling, boxValue: 6));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanPiece(tester, ctx, p);
      await scanPiece(tester, ctx, p);
      expect(boxRow(p).realPrice, 5000 * 6);
      expect(pieceRow(p).realPrice, 5000);
      expect(payable(p), closeTo(4 * 5000, 0.01));
    });

    testWidgets(
        'repeatable EMAS (5 olsa 1 tekin), QIMMAT {1: 5000, 3: 7000}, '
        'blok 12 → 11 × 7000', (tester) async {
      await addDiscount(tester, buyXGetY(buy: 5));
      useCatalog(tierProduct(const {1: 5000, 3: 7000}, boxValue: 12));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).realPrice, 7000 * 12);
      expect(payable(p), closeTo(11 * 7000, 0.01));
    });

    testWidgets(
        'repeatable EMAS (5 olsa 1 tekin), ARZON, blok 12 → 11 × 5000',
        (tester) async {
      await addDiscount(tester, buyXGetY(buy: 5));
      useCatalog(tierProduct(kFalling, boxValue: 12));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).realPrice, 5000 * 12);
      expect(payable(p), closeTo(11 * 5000, 0.01));
    });

    testWidgets('shart bajarilmasa (20 olsa 1 tekin) blok sof pog\'onada',
        (tester) async {
      await addDiscount(tester, buyXGetY(buy: 20));
      useCatalog(tierProduct(kRising, boxValue: 8));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      expect(boxRow(p).price, 27000 * 8);
      expect(boxRow(p).singleDiscount, 0);
    });
  });

  // ===================================================================
  // C. BLOK — OPD / o'chirish / guruh tahriri (savat to'g'ridan-to'g'ri)
  // ===================================================================
  group('Blok qatorlari — OPD yo\'llari', () {
    test('OPD saqlash: blok (8) qimmat pog\'ona + aksiya → 4 × 27 000',
        () async {
      await HiveBoxes.getDiscounts().add(prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 8));
      final p = freshProvider();
      cart(p).add(box(8));
      await saveRow(p, 0);
      expect(cart(p).single.realPrice, 27000 * 8);
      expect(payable(p), closeTo(4 * 27000, 0.01));
    });

    test('OPD saqlash: blok (8) arzon pog\'ona + aksiya → 4 × 5000', () async {
      await HiveBoxes.getDiscounts().add(prodPromo());
      useCatalog(tierProduct(kFalling, boxValue: 8));
      final p = freshProvider();
      cart(p).add(box(8));
      await saveRow(p, 0);
      expect(cart(p).single.realPrice, 5000 * 8);
      expect(payable(p), closeTo(4 * 5000, 0.01));
    });

    test('dona qatori OPD da 1 → 3: blok (6) + 3 = 9 → blok ham 27 000 ga',
        () async {
      useCatalog(tierProduct(kRising, boxValue: 6));
      final p = freshProvider();
      cart(p)
        ..add(piece(1, unit: 25000))
        ..add(box(6, unit: 25000));
      await opdSetQty(p, 0, 3);
      expect(boxRow(p).price, 27000 * 6);
      expect(pieceRow(p).price, 27000);
    });

    test('dona qatori o\'chirilsa blok (6) yana 1-pog\'onaga tushadi',
        () async {
      useCatalog(tierProduct(kRising, boxValue: 6));
      final p = freshProvider();
      cart(p)
        ..add(piece(1, unit: 27000))
        ..add(box(6, unit: 27000));
      await saveRow(p, 0);
      expect(boxRow(p).price, 27000 * 6);
      deleteRow(p, indexWhere(p, (e) => e.saleType != 2));
      expect(active(p), hasLength(1));
      expect(boxRow(p).price, 25000 * 6);
    });

    test(
        'aksiya bilan: blok (6) + 2 dona → dona o\'chirilsa '
        '6 dona, 3 tekin → 3 × 25 000', () async {
      await HiveBoxes.getDiscounts().add(prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 6));
      final p = freshProvider();
      cart(p)
        ..add(piece(2))
        ..add(box(6));
      await saveRow(p, 0);
      expect(payable(p), closeTo(4 * 27000, 0.01));
      deleteRow(p, indexWhere(p, (e) => e.saleType != 2));
      expect(boxRow(p).realPrice, 25000 * 6);
      expect(payable(p), closeTo(3 * 25000, 0.01));
    });

    test('blok guruhi 2 → 1 (12 → 6 dona): 27 000 → 25 000', () async {
      useCatalog(tierProduct(kRising, boxValue: 6));
      final p = freshProvider();
      cart(p)
        ..add(box(6))
        ..add(box(6));
      await saveRow(p, 0);
      expect(boxRows(p).map((e) => e.price), [27000 * 6, 27000 * 6]);
      p.beginBoxGroupEdit(kPid);
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeSoldItem(
          productId: kPid,
          price: 27000 * 6,
          value: 1,
          saleType: 2,
          boxValue: 6));
      p.endBoxGroupEdit();
      expect(boxRows(p), hasLength(1));
      expect(boxRow(p).price, 25000 * 6);
    });

    test(
        'aksiya bilan blok guruhi 2 → 1: 6 × 27 000 → 3 × 25 000', () async {
      await HiveBoxes.getDiscounts().add(prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 6));
      final p = freshProvider();
      cart(p)
        ..add(box(6))
        ..add(box(6));
      await saveRow(p, 0);
      expect(payable(p), closeTo(6 * 27000, 0.01));
      p.beginBoxGroupEdit(kPid);
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeSoldItem(
          productId: kPid,
          price: 27000 * 6,
          value: 1,
          saleType: 2,
          boxValue: 6));
      p.endBoxGroupEdit();
      expect(boxRow(p).realPrice, 25000 * 6);
      expect(payable(p), closeTo(3 * 25000, 0.01));
    });
  });

  // ===================================================================
  // D. MARKIROVKA — har skan alohida qator (value 1)
  // ===================================================================
  group('Markirovkali qatorlar (har skan alohida qator)', () {
    setUp(() async {
      // Markirovka yoqiq: qatorlar `marking: true` va KM bilan tushadi.
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    });

    testWidgets('6 marka → hammasi 25 000; 7-marka → HAMMA qatorlar 27 000',
        (tester) async {
      useCatalog(tierProduct(kRising, isMarking: true));
      await appContext(tester);
      final p = freshProvider();
      for (int i = 0; i < 6; i++) {
        await scanMark(tester, p);
      }
      expect(active(p), hasLength(6));
      expect(active(p).every((e) => e.marking && e.value == 1), isTrue);
      expect(active(p).map((e) => e.price).toSet(), {25000});
      await scanMark(tester, p);
      expect(active(p), hasLength(7));
      expect(active(p).map((e) => e.price).toSet(), {27000},
          reason: 'pog\'ona JAMI qatorlar soni bo\'yicha');
      expect(payable(p), 7 * 27000);
    });

    testWidgets('arzon pog\'ona: 3 marka → 4500, 7 marka → 4000',
        (tester) async {
      useCatalog(tierProduct(kFalling, isMarking: true));
      await appContext(tester);
      final p = freshProvider();
      for (int i = 0; i < 3; i++) {
        await scanMark(tester, p);
      }
      expect(active(p).map((e) => e.price).toSet(), {4500});
      for (int i = 0; i < 4; i++) {
        await scanMark(tester, p);
      }
      expect(active(p).map((e) => e.price).toSet(), {4000});
    });

    for (final n in const [6, 7, 8, 9]) {
      final unit = n >= 7 ? 27000.0 : 25000.0;
      final free = n ~/ 2;
      testWidgets(
          'PROD aksiya, QIMMAT: $n marka → dona $unit, $free tekin, '
          'jami ${unit * (n - free)}', (tester) async {
        await addDiscount(tester, prodPromo());
        useCatalog(tierProduct(kRising, isMarking: true));
        await appContext(tester);
        final p = freshProvider();
        for (int i = 0; i < n; i++) {
          await scanMark(tester, p);
        }
        expect(active(p), hasLength(n));
        expect(active(p).map((e) => e.realPrice).toSet(), {unit},
            reason: 'qimmat pog\'ona 1-talikka tushmasin');
        expect(active(p).where((e) => e.price == 0), hasLength(free),
            reason: 'tekin qatorlar soni');
        expect(payable(p), closeTo(unit * (n - free), 0.01));
      });
    }

    testWidgets('PROD aksiya, ARZON: 8 marka → 1-talik, 4 × 5000',
        (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kFalling, isMarking: true));
      await appContext(tester);
      final p = freshProvider();
      for (int i = 0; i < 8; i++) {
        await scanMark(tester, p);
      }
      expect(active(p).map((e) => e.realPrice).toSet(), {5000});
      expect(payable(p), closeTo(4 * 5000, 0.01));
    });

    testWidgets('ARALASH: blok (6) + 1 marka = 7 → blok 162 000, marka 27 000',
        (tester) async {
      useCatalog(tierProduct(kRising, boxValue: 6, isMarking: true));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanMark(tester, p);
      expect(boxRow(p).price, 27000 * 6);
      expect(pieceRow(p).price, 27000);
      expect(pieceRow(p).marking, isTrue);
    });

    testWidgets(
        'ARALASH + aksiya: blok (6) + 2 marka = 8 → 27 000, 4 tekin → 108 000',
        (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kRising, boxValue: 6, isMarking: true));
      await appContext(tester);
      final p = freshProvider();
      await scanBox(tester, p);
      await scanMark(tester, p);
      await scanMark(tester, p);
      expect(units(p), 8);
      for (final r in active(p)) {
        expect(r.realPrice, r.saleType == 2 ? 27000 * 6 : 27000);
      }
      expect(payable(p), closeTo(4 * 27000, 0.01));
    });

    test('marka guruhi OPD 8 → 6: 27 000 → 25 000, aksiya 3 × 25 000',
        () async {
      await HiveBoxes.getDiscounts().add(prodPromo());
      useCatalog(tierProduct(kRising, isMarking: true));
      final p = freshProvider();
      for (int i = 0; i < 8; i++) {
        cart(p).add(markRow('KM-$i'));
      }
      await saveRow(p, 0);
      expect(active(p).map((e) => e.realPrice).toSet(), {27000});
      expect(payable(p), closeTo(4 * 27000, 0.01));

      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeSoldItem(
          productId: kPid, price: 27000, value: 6, marking: true));
      p.endMarkGroupEdit();
      expect(active(p), hasLength(6));
      expect(active(p).map((e) => e.realPrice).toSet(), {25000});
      expect(payable(p), closeTo(3 * 25000, 0.01));
    });

    test('bitta marka o\'chirilsa (7 → 6) qolganlar 25 000 ga tushadi',
        () async {
      useCatalog(tierProduct(kRising, isMarking: true));
      final p = freshProvider();
      for (int i = 0; i < 7; i++) {
        cart(p).add(markRow('KM-$i'));
      }
      await saveRow(p, 0);
      expect(active(p).map((e) => e.price).toSet(), {27000});
      deleteRow(p, 0);
      expect(active(p), hasLength(6));
      expect(active(p).map((e) => e.price).toSet(), {25000});
    });
  });

  group('Qizil o\'chirish (o\'chirilgan qator savatda qoladi)', () {
    test(
        '8 markadan 2 tasi qizil o\'chirilsa (6 aktiv) → 25 000, '
        'aksiya 3 × 25 000', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      await HiveBoxes.getDiscounts().add(prodPromo());
      useCatalog(tierProduct(kRising, isMarking: true));
      final p = freshProvider();
      for (int i = 0; i < 8; i++) {
        cart(p).add(markRow('KM-$i'));
      }
      await saveRow(p, 0);
      expect(payable(p), closeTo(4 * 27000, 0.01));
      deleteRow(p, 0);
      deleteRow(p, 1);
      expect(cart(p), hasLength(8), reason: 'qizil rejimda qator qoladi');
      expect(active(p), hasLength(6));
      expect(active(p).map((e) => e.realPrice).toSet(), {25000},
          reason: 'o\'chirilgan qator pog\'ona soniga kirmaydi');
      expect(payable(p), closeTo(3 * 25000, 0.01));
      expect(ItemsSingleton.getTotalPrice(cart(p)), closeTo(75000, 1));
    });

    test('blok (6) + 1 dona: dona qizil o\'chirilsa blok 150 000', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      useCatalog(tierProduct(kRising, boxValue: 6));
      final p = freshProvider();
      cart(p)
        ..add(piece(1))
        ..add(box(6));
      await saveRow(p, 0);
      expect(boxRow(p).price, 27000 * 6);
      deleteRow(p, 0);
      expect(cart(p), hasLength(2));
      expect(boxRow(p).price, 25000 * 6);
      expect(ItemsSingleton.getTotalPrice(cart(p)), 150000);
    });
  });

  // ===================================================================
  // E. KILOLIK MAHSULOT
  // ===================================================================
  group('Kilolik mahsulot (kg) — qimmatlashuvchi pog\'ona', () {
    final cases = <double, double>{
      0.5: 25000,
      1.0: 25000,
      6.99: 25000,
      7.0: 27000,
      7.5: 27000,
      12.25: 27000,
    };
    cases.forEach((kg, unit) {
      testWidgets('$kg kg → $unit', (tester) async {
        useCatalog(tierProduct(kRising, unit: 'kg'));
        final ctx = await appContext(tester);
        final p = freshProvider();
        await addKg(tester, ctx, p, kg);
        final r = cart(p).single;
        expect(r.isKg, isTrue);
        expect(r.value, kg);
        expect(r.price, unit);
        expect(r.realPrice, unit);
        expect(payable(p), closeTo(unit * kg, 0.01));
      });
    });

    testWidgets('0.5 kg + 7 kg (bitta qatorga qo\'shiladi) = 7.5 → 27 000',
        (tester) async {
      useCatalog(tierProduct(kRising, unit: 'kg'));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await addKg(tester, ctx, p, 0.5);
      expect(cart(p).single.price, 25000);
      await addKg(tester, ctx, p, 7);
      expect(cart(p).single.value, 7.5);
      expect(cart(p).single.price, 27000);
    });

    test('OPD: 0.5 kg → 7.5 kg → 27 000; keyin 2.25 kg → yana 25 000',
        () async {
      useCatalog(tierProduct(kRising, unit: 'kg'));
      final p = freshProvider();
      cart(p).add(makeSoldItem(
          productId: kPid, price: 25000, value: 0.5, isKg: true));
      await opdSetQty(p, 0, 7.5);
      expect(cart(p).single.price, 27000);
      await opdSetQty(p, 0, 2.25);
      expect(cart(p).single.price, 25000);
    });

    test('kirill "кг" birligi ham kg sifatida: 7.5 кг → 27 000', () async {
      useCatalog(tierProduct(kRising, unit: 'кг'));
      final p = freshProvider();
      cart(p).add(
          makeSoldItem(productId: kPid, price: 1, value: 7.5, isKg: true));
      await saveRow(p, 0);
      expect(cart(p).single.price, 27000);
    });

    testWidgets(
        'PROD aksiya, QIMMAT: 7.5 kg → 27 000 saqlanadi, 3 kg tekin → '
        '4.5 × 27 000', (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kRising, unit: 'kg'));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await addKg(tester, ctx, p, 7.5);
      expect(cart(p).single.realPrice, 27000);
      expect(payable(p), closeTo(4.5 * 27000, 0.01));
    });
  });

  group('Tarozi yorlig\'i (real skan, kg)', () {
    test('yorliq formati: 7.5 kg / 0.5 kg', () {
      expect(taroziLabel(7.5), '2800001075000');
      expect(taroziLabel(0.5), '2800001005000');
    });

    final cases = <double, double>{0.5: 25000, 6.5: 25000, 7.5: 27000};
    cases.forEach((kg, unit) {
      testWidgets('yorliq $kg kg → $unit', (tester) async {
        useCatalog(tierProduct(kRising, unit: 'kg'));
        final key = GlobalKey<ScaffoldState>();
        await appContext(tester, scaffoldKey: key);
        final p = freshProvider();
        await scanScale(tester, p, key, kg);
        final r = cart(p).single;
        expect(r.isKg, isTrue);
        expect(r.value, kg);
        expect(r.price, unit);
      });
    });

    testWidgets('ikki yorliq 0.5 + 7 kg = 7.5 → 27 000', (tester) async {
      useCatalog(tierProduct(kRising, unit: 'kg'));
      final key = GlobalKey<ScaffoldState>();
      await appContext(tester, scaffoldKey: key);
      final p = freshProvider();
      await scanScale(tester, p, key, 0.5);
      await scanScale(tester, p, key, 7);
      expect(cart(p).single.value, 7.5);
      expect(cart(p).single.price, 27000);
    });

    testWidgets('PROD aksiya: yorliq 7.5 kg → 27 000, 4.5 × 27 000',
        (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kRising, unit: 'kg'));
      final key = GlobalKey<ScaffoldState>();
      await appContext(tester, scaffoldKey: key);
      final p = freshProvider();
      await scanScale(tester, p, key, 7.5);
      expect(cart(p).single.realPrice, 27000);
      expect(payable(p), closeTo(4.5 * 27000, 0.01));
    });
  });

  group('Kilolik mahsulot (kg) — arzonlashuvchi pog\'ona', () {
    final cases = <double, double>{0.5: 5000, 3.2: 4500, 7.5: 4000};
    cases.forEach((kg, unit) {
      testWidgets('$kg kg → $unit', (tester) async {
        useCatalog(tierProduct(kFalling, unit: 'kg'));
        final ctx = await appContext(tester);
        final p = freshProvider();
        await addKg(tester, ctx, p, kg);
        expect(cart(p).single.price, unit);
      });
    });

    testWidgets('PROD aksiya, ARZON: 7.5 kg → 1-talik, 4.5 × 5000',
        (tester) async {
      await addDiscount(tester, prodPromo());
      useCatalog(tierProduct(kFalling, unit: 'kg'));
      final ctx = await appContext(tester);
      final p = freshProvider();
      await addKg(tester, ctx, p, 7.5);
      expect(cart(p).single.realPrice, 5000);
      expect(payable(p), closeTo(4.5 * 5000, 0.01));
    });
  });
}
