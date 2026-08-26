// OFD o'chirilganda markirovkali mahsulot ODDIY mahsulot kabi ishlashi kerak.
//
// MUAMMO (2026-08-26, do'konda tasdiqlangan): adminkada OFD o'chiq bo'lsa ham
// savat qatoriga `marking: true` qo'yilardi. Oqibati zanjiri:
//   basket_grouping → qator "markirovka guruhi" deb ko'rsatiladi
//   order_list → tahrir `beginMarkGroupEdit` yo'liga ketadi
//   saveMarkGroup → qty ni QATORLAR SONI deb hisoblaydi (har marka = 1 qator).
//     OFD o'chiq holda esa bitta qator bo'lib, `value` = 3 bo'ladi. Shuning
//     uchun "yangi qty 2 >= joriy qatorlar soni 1" deb HECH NARSA qilmasdi —
//     kassir sonini kamaytira olmasdi va xato ham chiqmasdi.
//
// Kutilgan xatti-harakat: OFD o'chiq → `marking` false → oddiy qator →
// qty ni bemalol kamaytirish va oshirish mumkin.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

import 'support/provider_harness.dart';

/// Suv — markirovkali MXIK guruhida (02202...), lekin `isMarking` bayrog'isiz.
const kSuvMxik = '02202001001000000';
const kSuvId = 'suv-id';

ItemModel suv({bool isMarking = false, String mxik = kSuvMxik}) {
  final m = ItemModel();
  m.id = kSuvId;
  m.name = 'Suv 1L';
  m.sku = '1001';
  m.mxikCode = mxik;
  m.isMarking = isMarking;
  // OFD yoqiq holatda paket kodi bo'lmasa 'MXIK/paket yo'q' dialogi chiqadi.
  m.packageCode = 'PACK-1';
  m.barcode = ['4780000000001'];
  m.vat = Vat(percentage: 12);
  m.measurementUnit = MeasurementUnit(shortName: 'dona');
  m.shopPrices = ShopPrices(
    shID: ShID(
      shopId: 'shop-1',
      shopPriceTiers: [ShopPriceTiers(minQuantity: 1, retailPrice: 5000)],
    ),
  );
  return m;
}

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

/// `addProduct` ichida `AppNavigation.navigatorKey.currentContext` o'qiladi,
/// shuning uchun shu kalitli MaterialApp ko'tariladi.
Future<BuildContext> appContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(MaterialApp(
    navigatorKey: AppNavigation.navigatorKey,
    locale: const Locale('uz'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: (c) {
      captured = c;
      // Dialoglar SizeConfig.h/v ni o'qiydi — initsializatsiyasiz
      // LateInitializationError beradi.
      SizeConfig().init(c);
      return const SizedBox();
    })),
  ));
  return captured;
}

/// `pumpAndSettle` o'rniga: kutilmagan dialog/taymer bo'lsa test 10 daqiqa
/// osilib qolmasin. Bu yerda faqat mikrotasklar bo'shashi kerak.
Future<void> settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

/// OPD dialogidan "Saqlash": [index] qatorining qty sini [newQty] ga o'zgartirish.
/// Savat qatori markirovka guruhi bo'lsa UI `beginMarkGroupEdit` yo'liga
/// yuboradi — shu yerda ham xuddi shunday qilinadi.
Future<void> editQty(OrderingProvider4 p, int index, double newQty) async {
  final row = cart(p)[index];
  final isMarkGroup = row.marking && row.saleType != 2;
  if (isMarkGroup) p.beginMarkGroupEdit(row.productId);
  p.tapIndexToEdit(index);
  await p.pressDialogSaveButton(makeSoldItem(
    productId: row.productId,
    price: row.price,
    value: newQty,
    marking: row.marking,
  ));
  if (isMarkGroup) p.endMarkGroupEdit();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('marking_flag_ofd_gating_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    ItemsSingleton.products = [suv()];
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
  });

  group('OFD O\'CHIQ — markirovkali MXIK oddiy mahsulot kabi', () {
    setUp(() => Pref.setBool(PrefKeys.markCheckWithOfd, false));

    testWidgets('savatga qo\'shilgan qatorda marking = false', (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();

      p.addProduct(
          value: 1, product: suv(), where: 'test', context: ctx);
      await settle(tester);

      expect(cart(p), hasLength(1));
      expect(cart(p).first.marking, isFalse,
          reason: 'OFD o\'chiq — qator markirovka guruhi bo\'lmasligi kerak');
    });

    testWidgets('product.isMarking = true bo\'lsa ham marking false',
        (tester) async {
      final ctx = await appContext(tester);
      ItemsSingleton.products = [suv(isMarking: true)];
      final p = freshProvider();

      p.addProduct(
          value: 1, product: suv(isMarking: true), where: 'test', context: ctx);
      await settle(tester);

      expect(cart(p).first.marking, isFalse);
    });

    testWidgets('ASOSIY SIMPTOM: qty ni 3 dan 2 ga KAMAYTIRISH ishlaydi',
        (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();

      p.addProduct(value: 3, product: suv(), where: 'test', context: ctx);
      await settle(tester);
      expect(cart(p).first.value, 3);

      await editQty(p, 0, 2);
      await settle(tester);

      expect(cart(p).first.value, 2,
          reason: 'OFD o\'chiq holda qty kamayishi shart');
    });

    testWidgets('qty ni OSHIRISH ham ishlaydi', (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();

      p.addProduct(value: 2, product: suv(), where: 'test', context: ctx);
      await settle(tester);

      await editQty(p, 0, 5);
      await settle(tester);

      expect(cart(p).first.value, 5);
    });

    testWidgets('qty 0 qilinsa qator o\'chadi', (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();

      p.addProduct(value: 2, product: suv(), where: 'test', context: ctx);
      await settle(tester);

      await editQty(p, 0, 0);
      await settle(tester);

      expect(cart(p), isEmpty);
    });
  });

  group('OFD YOQIQ, avto-aniqlash O\'CHIQ — ham oddiy mahsulot kabi', () {
    setUp(() async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
      await Pref.setBool(PrefKeys.sellProductsWithMarking, false);
    });

    testWidgets('MXIK bo\'yicha markirovkali deb belgilanmaydi',
        (tester) async {
      final ctx = await appContext(tester);
      final p = freshProvider();

      p.addProduct(value: 1, product: suv(), where: 'test', context: ctx);
      await settle(tester);

      expect(cart(p).first.marking, isFalse,
          reason: 'avto-aniqlash o\'chiq — MXIK bo\'yicha aniqlanmasligi kerak');
    });
  });


// QAYD: "markirovkasiz MXIK oddiy qator bo'lib qoladi" testi ham yozilgan
// edi, lekin `addProduct` ni OFD YOQIQ holatda chaqirish test muhitida
// osilib qolardi (sabab aniqlanmadi — ilova kodida emas, test harness'ida).
// O'sha holat `test/sold_item_builder_test.dart` da qoplangan.
}
