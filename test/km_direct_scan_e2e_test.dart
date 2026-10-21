// KM (GS1 DataMatrix) kassada TO'G'RIDAN skanerlanganda — to'liq yo'l:
// `onBarcodeScanned` → tasnif → muddat → blok → `ScannedProductLookup` →
// `marking()` → `_markingCheck` (`MarkValidator`) → savat qatori.
//
// Do'kondagi bug (2026-10-21): "Ichimlik Fanta 355ml" (SKU 25619) KM i
// `0100049000033939 21…` to'g'ridan skanerlansa mahsulot topilmasdi —
// KM ichidagi GTIN-14 `00049000033939`, katalogda esa UPC-12
// `049000033939` / EAN-13 `0049000033939`. Avval oddiy shtrix-kod, keyin
// dialogda KM berilsa ishlardi. Bu test ikkala yo'lni ham mixlaydi.
//
// ONKM so'rovi o'chiq (`validation_onkm` = false) — tarmoq yo'q.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/markirovka_dialog.dart';
import 'package:invan2/changes/dialogs/not_found_product_dialog.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/singletons/discounts/discount_singleton.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

import 'support/provider_harness.dart';

const kShop = 'shop-1';
const kFantaId = 'fanta-25619';

/// Adminkadagi 8 ta shtrix-kod (hammasi bitta mahsulotda).
const kFantaBarcodes = [
  '049000014242',
  '0049000014242',
  '049000067729',
  '0049000067729',
  '049000033939',
  '0049000033939',
  '049000014273',
  '0049000014273',
];

const kGs = '\x1D';
const kKm1 = '0100049000033939217MG7fVVkzf5Y?${kGs}93abcd';
const kKm2 = '0100049000033939217/VG5xQ2pLm8a${kGs}93Wz1k';
const kKm1Clean = '0100049000033939217MG7fVVkzf5Y?';
const kKm2Clean = '0100049000033939217/VG5xQ2pLm8a';

/// Shirin ichimlik (02202 — markirovka ro'yxatida, alkogol emas).
const kMxik = '02202001001000000';

ItemModel fanta({
  List<String> barcodes = kFantaBarcodes,
  num price = 9000,
  bool? isMarking = true,
}) {
  final m = ItemModel();
  m.id = kFantaId;
  m.name = 'Ichimlik Fanta 355ml';
  m.sku = '25619';
  m.barcode = barcodes;
  m.mxikCode = kMxik;
  m.packageCode = '1501234';
  m.isMarking = isMarking;
  m.vat = Vat(percentage: 12);
  m.measurementUnit = MeasurementUnit(shortName: 'dona');
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: kShop, shopPriceTiers: [
      ShopPriceTiers(minQuantity: 1, retailPrice: price),
    ]),
  );
  return m;
}

/// Katalog: [products] — hammasi, [barcodeProducts] — narxi bor va
/// shtrix-kodli (skaner shu ro'yxatdan qidiradi, `storeProducts` qoidasi).
void useCatalog(List<ItemModel> items) {
  ItemsSingleton.products = items;
  ItemsSingleton.barcodeProducts = items
      .where((e) =>
          (e.barcode?.isNotEmpty ?? false) &&
          ItemsSingleton.onePrice(e.shopPrices) > 0)
      .toList();
}

Future<GlobalKey<ScaffoldState>> pumpApp(WidgetTester tester) async {
  final key = GlobalKey<ScaffoldState>();
  await tester.pumpWidget(MaterialApp(
    navigatorKey: AppNavigation.navigatorKey,
    locale: const Locale('uz'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
        key: key,
        body: Builder(builder: (c) {
          SizeConfig().init(c);
          return const SizedBox();
        })),
  ));
  return key;
}

Future<void> pumpFew(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Ochiq xabar dialogini kassir kabi "Ok" bilan yopadi.
Future<void> tapOk(WidgetTester tester) async {
  final ok = find.text('Ok');
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await pumpFew(tester);
  }
}

Future<void> scan(WidgetTester tester, OrderingProvider4 p,
    GlobalKey<ScaffoldState> key, String code) async {
  p.onBarcodeScanned(code, key);
  await pumpFew(tester);
}

List<ReceiptModelSoldItem4> active(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts
        .where((e) => !(e.isDeleted ?? false))
        .toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('km_direct_scan_e2e_test');
    await Pref.setString(PrefKeys.storeId, kShop);
  });
  tearDownAll(tearDownPosTestEnv);

  // testWidgets ichida Hive IO kutilsa osilib qoladi — sozlash shu yerda.
  setUp(() async {
    await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
    await Pref.setBool('validation_onkm', false);
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
    await Pref.setBool(PrefKeys.autoGenerate, false);
    await HiveBoxes.getDiscounts().clear();
    DiscountSingleton.resetAll();
  });

  group('KM to\'g\'ridan skan — Fanta 355ml', () {
    testWidgets('KM1 → Fanta qatori, KM bilan (dialogsiz)', (tester) async {
      useCatalog([fanta()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, kKm1);

      expect(find.byType(NotFoundProductDialog), findsNothing);
      expect(find.byType(MarkingDialog), findsNothing,
          reason: 'KM skan vaqtida berildi — dialog kerak emas');
      final rows = active(p);
      expect(rows, hasLength(1));
      expect(rows.single.productId, kFantaId);
      expect(rows.single.mark, kKm1Clean);
      expect(rows.single.marking, isTrue);
      expect(rows.single.value, 1);
    });

    testWidgets('KM1 + KM2 → ikki alohida marka qatori', (tester) async {
      useCatalog([fanta()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, kKm1);
      await scan(tester, p, key, kKm2);

      final marks = active(p).map((e) => e.mark).toSet();
      expect(marks, {kKm1Clean, kKm2Clean});
      expect(active(p).every((e) => e.productId == kFantaId), isTrue);
    });

    testWidgets('shu KM qayta skanerlansa — "oldin qo\'shilgan", qator yo\'q',
        (tester) async {
      useCatalog([fanta()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, kKm1);
      await scan(tester, p, key, kKm1);

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(1));
    });

    for (final b in ['049000033939', '0049000033939']) {
      testWidgets('katalogda faqat $b bo\'lsa ham topiladi', (tester) async {
        useCatalog([
          fanta(barcodes: [b])
        ]);
        final key = await pumpApp(tester);
        final p = freshProvider();

        await scan(tester, p, key, kKm1);

        expect(active(p).single.mark, kKm1Clean);
      });
    }

    testWidgets('muddati o\'tgan KM (17 = 250101) — xabar, savat bo\'sh',
        (tester) async {
      useCatalog([fanta()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, '0100049000033939172501012112345${kGs}93ab');

      expect(find.textContaining('Срок годности'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), isEmpty);
    });

    testWidgets('boshqa GTIN dagi KM — "topilmadi", savat bo\'sh',
        (tester) async {
      useCatalog([fanta()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, '0100049000033946217MG7fVVkzf5Y?${kGs}93ab');

      expect(find.byType(NotFoundProductDialog), findsOneWidget);
      await tapOk(tester);
      expect(active(p), isEmpty);
    });

    testWidgets(
        'oddiy "49000033939" skani (KM emas) — o\'zgarishsiz topilmaydi',
        (tester) async {
      useCatalog([fanta()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, '49000033939');

      expect(find.byType(NotFoundProductDialog), findsOneWidget);
      await tapOk(tester);
      expect(active(p), isEmpty);
    });

    testWidgets('OFD o\'chiq: KM bilan topiladi, oddiy qator, KM yozilmaydi',
        (tester) async {
      await tester
          .runAsync(() => Pref.setBool(PrefKeys.markCheckWithOfd, false));
      useCatalog([fanta()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, kKm1);

      final rows = active(p);
      expect(rows, hasLength(1));
      expect(rows.single.productId, kFantaId);
      expect(rows.single.mark, isNull);
      expect(rows.single.marking, isFalse);
    });
  });

  group('Avvalgi yo\'l: oddiy shtrix-kod, keyin dialogda KM (o\'zgarmagan)',
      () {
    testWidgets('0049000033939 → dialog → KM1 → marka qatori', (tester) async {
      useCatalog([fanta()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, '0049000033939');
      expect(find.byType(MarkingDialog), findsOneWidget);

      await tester.enterText(
          find.descendant(
              of: find.byType(MarkingDialog), matching: find.byType(TextField)),
          kKm1);
      await tester.tap(find.descendant(
          of: find.byType(MarkingDialog),
          matching: find.byType(ElevatedButton)));
      await pumpFew(tester);

      final rows = active(p);
      expect(rows, hasLength(1));
      expect(rows.single.productId, kFantaId);
      expect(rows.single.mark, kKm1Clean);
    });
  });

  group('Blok va narxi 0 yo\'llari', () {
    testWidgets('blok kodi UPC-12 (049000099991) → blok qatori',
        (tester) async {
      final blok = fanta(barcodes: ['0049000033939'])
        ..hasBoxBarcode = true
        ..boxBarcode = '049000099991'
        ..boxBarcodeQuantity = 24;
      useCatalog([blok]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, '010004900009999121BLOK00000001');

      final rows = active(p);
      expect(rows, hasLength(1));
      expect(rows.single.saleType, 2);
      expect(rows.single.boxValue, 24);
    });

    testWidgets('narxi 0 Fanta KM bilan — "topilmadi" emas, narx 0 yo\'li',
        (tester) async {
      useCatalog([fanta(price: 0)]);
      expect(ItemsSingleton.barcodeProducts, isEmpty);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, kKm1);

      expect(find.byType(NotFoundProductDialog), findsNothing,
          reason: 'narxi 0 mahsulot GS1 tengligi bilan topiladi');
      await tapOk(tester);
      expect(active(p), isEmpty, reason: 'narxi 0 — savatga tushmaydi');
    });
  });
}
