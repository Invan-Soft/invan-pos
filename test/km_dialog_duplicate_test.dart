// Bitta KM ikki yo'ldan kirsa ham savatga BIR MARTA tushadi.
//
// Do'kondagi bug (2026-11-16, Tiin, 1.1.2+130, video): "Ichimlik DR. PEPPER
// Canada Dry Ginger Ale 330ml" KM i to'g'ridan skanerlanib savatga tushgan.
// Shu KM yana to'g'ridan skanerlansa — "oldin qo'shilgan" (to'g'ri). Lekin
// avval oddiy shtrix-kod skanerlanib, ochilgan markirovka dialogiga O'SHA KM
// skanerlansa — ikkinchi marta qo'shilardi (19 → 20 dona).
//
// Sabab: asosiy ekran skani `MyBarcodeListener` dan o'tadi (rus tartibidagi
// harflar lotinga o'giriladi), dialog maydoni esa matnni to'g'ridan oladi —
// kassada rus tartibi yoqiq bo'lgani uchun KM kirill harflarda kelgan va
// savatdagi lotin KM ga teng chiqmagan. ONKM sozlamasiga bog'liq emas.
//
// ONKM so'rovi o'chiq (`validation_onkm` = false) — tarmoq yo'q; ONKM yoqiq
// yo'l ham shu `MarkedCart` tengligidan foydalanadi (pastdagi sof testlar).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/dialogs/markirovka_dialog.dart';
import 'package:invan2/changes/domain/barcode/barcode_classifier.dart';
import 'package:invan2/changes/domain/barcode/keyboard_layout.dart';
import 'package:invan2/changes/domain/marking/mark_cleaner.dart';
import 'package:invan2/changes/domain/marking/marked_cart.dart';
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
const kPid = 'dr-pepper-14216';
const kEan = '8435185954954';
const kGs = '\x1D';

/// Seriyada katta/kichik harf va rus tartibida harf tugmasiga tushadigan
/// belgi (`<` = Shift+Б) bor — videodagi KM shakli.
const kSerial1 = '7U7xnHK<eRt5w';
const kSerial2 = '7Qp3LmZk8vYd2';
const kClean1 = '010$kEan' '21$kSerial1';
const kClean2 = '010$kEan' '21$kSerial2';

/// Skaner yuboradigan xom kod — uch xil GS shakli.
const kRaw1Gs = '$kClean1${kGs}93dGVz'; // haqiqiy GS (0x1D)
const kRaw1NoGs = '${kClean1}93dGVz'; // GS umuman kelmagan
const kRaw1Gs029 = '${kClean1}02993dGVz'; // GS `029` raqamlari bo'lib kelgan
const kRaw2Gs = '$kClean2${kGs}93aBcD';

/// Kod rus (Windows ЙЦУКЕН) tartibi yoqiq kassada matn maydoniga skanerlansa
/// nima yoziladi (harf tugmalari).
String typedOnRu(String en) {
  const map = {
    'q': 'й', 'w': 'ц', 'e': 'у', 'r': 'к', 't': 'е', 'y': 'н', 'u': 'г',
    'i': 'ш', 'o': 'щ', 'p': 'з', '[': 'х', ']': 'ъ', 'a': 'ф', 's': 'ы',
    'd': 'в', 'f': 'а', 'g': 'п', 'h': 'р', 'j': 'о', 'k': 'л', 'l': 'д',
    ';': 'ж', "'": 'э', 'z': 'я', 'x': 'ч', 'c': 'с', 'v': 'м', 'b': 'и',
    'n': 'т', 'm': 'ь', ',': 'б', '.': 'ю', '`': 'ё',
    'Q': 'Й', 'W': 'Ц', 'E': 'У', 'R': 'К', 'T': 'Е', 'Y': 'Н', 'U': 'Г',
    'I': 'Ш', 'O': 'Щ', 'P': 'З', '{': 'Х', '}': 'Ъ', 'A': 'Ф', 'S': 'Ы',
    'D': 'В', 'F': 'А', 'G': 'П', 'H': 'Р', 'J': 'О', 'K': 'Л', 'L': 'Д',
    ':': 'Ж', '"': 'Э', 'Z': 'Я', 'X': 'Ч', 'C': 'С', 'V': 'М', 'B': 'И',
    'N': 'Т', 'M': 'Ь', '<': 'Б', '>': 'Ю', '~': 'Ё',
  };
  return en.split('').map((c) => map[c] ?? c).join();
}

/// Asosiy ekran skaneri zanjiri (`MyBarcodeListener` → `onBarcodeScanned`):
/// provayderga kod shu ko'rinishda keladi.
String viaListener(String typed) =>
    KeyboardLayout.ruLettersToEn(typed.trim());

ItemModel drPepper() {
  final m = ItemModel();
  m.id = kPid;
  m.name = 'Ichimlik DR. PEPPER Canada Dry Ginger Ale 330ml';
  m.sku = '14216';
  m.barcode = [kEan];
  m.mxikCode = '02202001001000000';
  m.packageCode = '1501234';
  m.isMarking = true;
  m.vat = Vat(percentage: 12);
  m.measurementUnit = MeasurementUnit(shortName: 'dona');
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: kShop, shopPriceTiers: [
      ShopPriceTiers(minQuantity: 1, retailPrice: 13950),
    ]),
  );
  return m;
}

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

Future<void> tapOk(WidgetTester tester) async {
  final ok = find.text('Ok');
  if (ok.evaluate().isNotEmpty) {
    await tester.tap(ok.first, warnIfMissed: false);
    await pumpFew(tester);
  }
}

/// To'g'ridan skan — asosiy ekran (dialog yo'q).
Future<void> scan(WidgetTester tester, OrderingProvider4 p,
    GlobalKey<ScaffoldState> key, String typed) async {
  p.onBarcodeScanned(viaListener(typed), key);
  await pumpFew(tester);
}

/// Oddiy shtrix-kod → markirovka dialogi → maydonga [typed] → "Qo'shish".
Future<void> scanIntoDialog(WidgetTester tester, OrderingProvider4 p,
    GlobalKey<ScaffoldState> key, String typed) async {
  await scan(tester, p, key, kEan);
  expect(find.byType(MarkingDialog), findsOneWidget);
  await tester.enterText(
      find.descendant(
          of: find.byType(MarkingDialog), matching: find.byType(TextField)),
      typed);
  await tester.tap(find.descendant(
      of: find.byType(MarkingDialog), matching: find.byType(ElevatedButton)));
  await pumpFew(tester);
}

List<ReceiptModelSoldItem4> active(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts
        .where((e) => !(e.isDeleted ?? false))
        .toList();

ReceiptModelSoldItem4 row({String? mark, bool deleted = false}) => makeSoldItem(
    productId: kPid, mark: mark, marking: mark != null, isDeleted: deleted);

void main() {
  group('MarkCleaner.fromDialog — dialog asosiy skaner bilan bir xil satr', () {
    String direct(String typed) =>
        MarkCleaner.scanTime(BarcodeClassifier.sanitize(viaListener(typed)));

    test('lotin tartibi: natija to\'g\'ridan skan bilan bir xil', () {
      for (final raw in [kRaw1Gs, kRaw1NoGs, kRaw1Gs029, kRaw2Gs]) {
        expect(MarkCleaner.fromDialog(raw), direct(raw), reason: raw);
      }
      expect(MarkCleaner.fromDialog(kRaw1Gs), kClean1);
    });

    test('rus tartibi: kirill harflar lotinga qaytadi', () {
      final typed = typedOnRu(kRaw1NoGs);
      expect(typed, isNot(kRaw1NoGs), reason: 'sinov kodi kirillga aylansin');
      expect(RegExp(r'[а-яА-ЯёЁ]').hasMatch(typed), isTrue);

      expect(MarkCleaner.fromDialog(typed), kClean1);
      expect(MarkCleaner.fromDialog(typed), direct(typed));
      expect(RegExp(r'[а-яА-ЯёЁ]').hasMatch(MarkCleaner.fromDialog(typed)),
          isFalse);
    });

    test('eski yo\'l (faqat scanTime) rus tartibida kirillni qoldirardi', () {
      final typed = typedOnRu(kRaw1NoGs);
      expect(MarkCleaner.scanTime(typed), isNot(kClean1));
    });

    test('atrofidagi bo\'sh joy, `-` prefiksi, AIM ]d2', () {
      expect(MarkCleaner.fromDialog('  $kRaw1Gs \n'), kClean1);
      expect(MarkCleaner.fromDialog('-$kClean1-93dGVz'), kClean1);
      expect(MarkCleaner.fromDialog(']d2$kRaw1Gs'), kClean1);
    });

    test('qavsli shakl', () {
      expect(MarkCleaner.fromDialog('(01)0$kEan(21)$kSerial1(93)dGVz'),
          kClean1);
    });

    test('bo\'sh satr o\'zgarmaydi', () {
      expect(MarkCleaner.fromDialog(''), '');
      expect(MarkCleaner.fromDialog('   '), '');
    });
  });

  group('MarkedCart.sameMark — bitta KM ning turli yozilishi', () {
    test('aynan teng', () {
      expect(MarkedCart.sameMark(kClean1, kClean1), isTrue);
    });

    test('boshqa seriya — boshqa KM', () {
      expect(MarkedCart.sameMark(kClean1, kClean2), isFalse);
    });

    test('bitta belgi farqi (katta/kichik harf) — boshqa KM', () {
      expect(MarkedCart.sameMark(kClean1, kClean1.replaceFirst('x', 'X')),
          isFalse);
    });

    test('null / bo\'sh — hech qachon teng emas', () {
      expect(MarkedCart.sameMark(null, kClean1), isFalse);
      expect(MarkedCart.sameMark(kClean1, null), isFalse);
      expect(MarkedCart.sameMark('', ''), isFalse);
      expect(MarkedCart.sameMark(null, null), isFalse);
    });

    test('kirill ↔ lotin (rus tartibi) — bitta KM', () {
      expect(MarkedCart.sameMark(typedOnRu(kClean1), kClean1), isTrue);
      expect(MarkedCart.sameMark(kClean1, typedOnRu(kClean1)), isTrue);
      expect(MarkedCart.sameMark(typedOnRu(kClean1), kClean2), isFalse);
    });

    test('GS `029` bo\'lib yozilgan ↔ yozilmagan — bitta KM', () {
      expect(MarkedCart.sameMark('${kClean1}029', kClean1), isTrue);
      expect(MarkedCart.sameMark(kClean1, '${kClean1}029'), isTrue);
      // ichida ham (masalan 8005 narx AI oldida)
      expect(
          MarkedCart.sameMark(
              '${kClean1}0298005012345029', '${kClean1}8005012345'),
          isTrue);
      expect(MarkedCart.sameMark('${kClean1}029', kClean2), isFalse);
    });

    test('`029` + kirill birga', () {
      expect(MarkedCart.sameMark('${kClean1}029', typedOnRu(kClean1)), isTrue);
    });

    test('seriya ichidagi haqiqiy 029 buzilmaydi', () {
      const a = '010${kEan}21AB029CD12345';
      const b = '010${kEan}21AB029CD12346';
      expect(MarkedCart.sameMark(a, a), isTrue);
      expect(MarkedCart.sameMark(a, b), isFalse);
      // bir xil uzunlik — `029` qoidasi umuman ishlamaydi
      expect(
          MarkedCart.sameMark(
              '010${kEan}210290ABCDEFGHI', '010${kEan}210029ABCDEFGHI'),
          isFalse);
    });

    test('uzunlik farqi 3 ga karrali emas — teng emas', () {
      expect(MarkedCart.sameMark('${kClean1}02', kClean1), isFalse);
      expect(MarkedCart.sameMark('${kClean1}0290', kClean1), isFalse);
    });

    test('farq `029` emas, boshqa 3 belgi — teng emas', () {
      expect(MarkedCart.sameMark('${kClean1}030', kClean1), isFalse);
      expect(MarkedCart.sameMark('${kClean1}abc', kClean1), isFalse);
    });

    test('ketma-ket va ustma-ust 029 lar (qaytish kerak bo\'lgan holat)', () {
      // "0290" + "29" ichida: birinchi 0 ni tashlamay, keyingi 029 tashlanadi
      expect(MarkedCart.sameMark('X0029Y', 'X0Y'), isTrue);
      expect(MarkedCart.sameMark('X029029Y', 'XY'), isTrue);
      expect(MarkedCart.sameMark('X029029Y', 'X029Y'), isTrue);
      expect(MarkedCart.sameMark('X02929Y', 'X29Y'), isTrue);
      expect(MarkedCart.sameMark('X02929Y', 'X02Y'), isFalse);
    });
  });

  group('MarkedCart qidiruvlari sameMark bilan', () {
    test('indexOfMark: kirill qator ↔ lotin skan', () {
      expect(
          MarkedCart.indexOfMark([row(mark: typedOnRu(kClean1))], kClean1), 0);
    });

    test('indexOfMark: `029` li qator ↔ `029` siz skan', () {
      expect(MarkedCart.indexOfMark([row(mark: '${kClean1}029')], kClean1), 0);
    });

    test('indexOfMark: o\'chirilgan qator sanalmaydi (o\'zgarmagan)', () {
      expect(
          MarkedCart.indexOfMark([row(mark: kClean1, deleted: true)], kClean1),
          -1);
    });

    test('hasMark (ONKM yoqiq yo\'l): kirill / `029` farqi takror deb topiladi',
        () {
      expect(MarkedCart.hasMark([row(mark: kClean1)], kPid, typedOnRu(kClean1)),
          isTrue);
      expect(MarkedCart.hasMark([row(mark: '${kClean1}029')], kPid, kClean1),
          isTrue);
      expect(MarkedCart.hasMark([row(mark: kClean1)], kPid, kClean2), isFalse);
      expect(MarkedCart.hasMark([row(mark: kClean1)], 'boshqa', kClean1),
          isFalse);
    });

    test('decideAfterCheck / decideWithoutOnkm', () {
      final rows = [row(mark: '${kClean1}029')];
      expect(MarkedCart.decideAfterCheck(rows, kPid, kClean1),
          MarkAction.warnDuplicate);
      expect(MarkedCart.decideWithoutOnkm(rows, kPid, kClean1),
          MarkAction.warnDuplicate);
      expect(MarkedCart.decideAfterCheck(rows, kPid, kClean2),
          MarkAction.addNew);
      expect(MarkedCart.decideWithoutOnkm(rows, kPid, kClean2),
          MarkAction.addNew);
    });
  });

  group('To\'liq yo\'l: to\'g\'ridan skan + dialog', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    setUpAll(() async {
      await setUpPosTestEnv('km_dialog_duplicate_test');
      await Pref.setString(PrefKeys.storeId, kShop);
    });
    tearDownAll(tearDownPosTestEnv);

    setUp(() async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
      await Pref.setBool('validation_onkm', false);
      await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
      await Pref.setBool(PrefKeys.autoGenerate, false);
      await HiveBoxes.getDiscounts().clear();
      DiscountSingleton.resetAll();
    });

    // Videodagi holat: rus tartibi yoqiq kassa.
    testWidgets(
        'RU tartib: KM to\'g\'ridan → shtrix-kod → dialogga O\'SHA KM — '
        '"oldin qo\'shilgan", qator qo\'shilmaydi', (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, typedOnRu(kRaw1NoGs));
      expect(active(p), hasLength(1));
      expect(active(p).single.mark, kClean1);

      await scanIntoDialog(tester, p, key, typedOnRu(kRaw1NoGs));

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(1), reason: 'bitta KM — bitta qator');
    });

    testWidgets('RU tartib: dialogdan kirgan KM savatga LOTIN bo\'lib tushadi',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scanIntoDialog(tester, p, key, typedOnRu(kRaw1NoGs));

      expect(active(p), hasLength(1));
      expect(active(p).single.mark, kClean1,
          reason: 'soliqqa kirill harfli KM ketmasin');
    });

    testWidgets('RU tartib: avval dialog, keyin to\'g\'ridan — "oldin qo\'shilgan"',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scanIntoDialog(tester, p, key, typedOnRu(kRaw1NoGs));
      await scan(tester, p, key, typedOnRu(kRaw1NoGs));

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(1));
    });

    testWidgets('RU tartib: dialogga ikki marta bitta KM — ikkinchisi rad',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scanIntoDialog(tester, p, key, typedOnRu(kRaw1NoGs));
      await scanIntoDialog(tester, p, key, typedOnRu(kRaw1NoGs));

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(1));
    });

    testWidgets('RU tartib: dialogga BOSHQA KM — ikkinchi qator qo\'shiladi',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, typedOnRu(kRaw1NoGs));
      await scanIntoDialog(tester, p, key, typedOnRu(kRaw2Gs));

      expect(find.textContaining('oldin qo\'shilgan'), findsNothing);
      expect(active(p).map((e) => e.mark).toSet(), {kClean1, kClean2});
    });

    testWidgets('lotin tartib: to\'g\'ridan → dialog (o\'zgarmagan) — rad',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, kRaw1Gs);
      await scanIntoDialog(tester, p, key, kRaw1Gs);

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(1));
    });

    // Skaner GS ni Alt-kod bilan yuboradi: tinglovchiga `029`, maydonga hech narsa.
    testWidgets('GS `029`: to\'g\'ridan (029 bilan) → dialog (029 siz) — rad',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scan(tester, p, key, kRaw1Gs029);
      expect(active(p).single.mark, '${kClean1}029',
          reason: 'saqlanadigan satr o\'zgarmagan (faqat solishtirish)');

      await scanIntoDialog(tester, p, key, kRaw1NoGs);

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(1));
    });

    testWidgets('GS `029`: dialog (029 siz) → to\'g\'ridan (029 bilan) — rad',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      await scanIntoDialog(tester, p, key, kRaw1NoGs);
      await scan(tester, p, key, kRaw1Gs029);

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(1));
    });

    // Yangilanishdan oldin savatda qolgan kirill KM (saqlangan chek).
    testWidgets('savatda eski kirill KM qatori + shu KM to\'g\'ridan — rad',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(row(mark: typedOnRu(kClean1)));

      await scan(tester, p, key, kRaw1Gs);

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(1));
    });

    testWidgets('o\'chirilgan qatordagi KM qayta skanerlansa — qo\'shiladi',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(row(mark: kClean1, deleted: true));

      await scanIntoDialog(tester, p, key, typedOnRu(kRaw1NoGs));

      expect(find.textContaining('oldin qo\'shilgan'), findsNothing);
      expect(active(p), hasLength(1));
      expect(active(p).single.mark, kClean1);
    });

    testWidgets('19 ta turli KM + bittasi dialogdan takror — 19 ligicha',
        (tester) async {
      useCatalog([drPepper()]);
      final key = await pumpApp(tester);
      final p = freshProvider();

      String raw(int i) =>
          '010$kEan' '21Ab${i.toString().padLeft(3, '0')}xYzQwErT${kGs}93abcd';
      for (var i = 0; i < 19; i++) {
        await scan(tester, p, key, typedOnRu(raw(i)));
      }
      expect(active(p), hasLength(19));

      await scanIntoDialog(tester, p, key, typedOnRu(raw(7)));

      expect(find.textContaining('oldin qo\'shilgan'), findsOneWidget);
      await tapOk(tester);
      expect(active(p), hasLength(19));
    });
  });
}
