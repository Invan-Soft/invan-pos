// OPD dialogi: ruxsatsiz kassir savatni PIN siz kamaytira olmaydi va narxni
// o'zgartira olmaydi. Testlar haqiqiy dialog ustida (tugmalar, klaviatura).
//
// Bug: qty tekshiruvi faqat 400 ms kechikkan taymerda edi. Undan oldin
// Saqlash bosilsa qty PIN siz saqlanardi, keyin taymer savat qatorining o'zini
// orqaga qaytarardi: ro'yxatda 3 ta, to'lov sahifasida 10 talik summa.
// Hujjat: docs/sessions/2026-11-03-opd-qty-access.md
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/operation_on_product_provider.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/home/features/operation_on_product/delete_item/input_alert_dialog.dart';
import 'package:invan2/features/home/features/operation_on_product/opd_bottom.dart';
import 'package:invan2/features/home/features/operation_on_product/operation_on_product.dart';
import 'package:invan2/features/home/features/operation_on_product/operation_on_product_dialog.dart';
import 'package:invan2/features/lock/lock/view/lock_number_button.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'support/provider_harness.dart';

const kPid = 'pepsi-id';
const kManagerId = 'rahbar-1';
const kManagerPin = '7777';
const kNoRightsPin = '8888';
const kUnit = 10000.0;

ItemModel pepsi({bool kg = false, List<ShopPriceTiers>? tiers}) {
  final m = ItemModel();
  m.id = kPid;
  m.name = 'Pepsi';
  m.vat = Vat(percentage: 12);
  m.measurementUnit = MeasurementUnit(shortName: kg ? 'kg' : 'dona');
  m.shopPrices = ShopPrices(
    shID: ShID(
      shopId: 'shop-1',
      shopPriceTiers:
          tiers ?? [ShopPriceTiers(minQuantity: 1, retailPrice: kUnit)],
    ),
  );
  return m;
}

Future<void> setEmployees({bool delete = false, bool edit = false}) async {
  final box = HiveBoxes.getEmployees();
  await box.clear();
  await box.add(Employee(
    user:
        EmployeeUser(id: kCashierId, firstName: kCashierName, passCode: '1111'),
    access: EmployeeAccess(deletePrice: delete, editPrice: edit),
  ));
  await box.add(Employee(
    user: EmployeeUser(
        id: kManagerId, firstName: 'Rahbar', passCode: kManagerPin),
    access: EmployeeAccess(deletePrice: true, editPrice: true),
  ));
  await box.add(Employee(
    user: EmployeeUser(
        id: 'kassir-2', firstName: 'Kassir', passCode: kNoRightsPin),
    access: EmployeeAccess(deletePrice: false, editPrice: false),
  ));
}

class Host {
  Host(this.tester, this.p);

  final WidgetTester tester;
  final OrderingProvider4 p;
  late BuildContext ctx;

  List<ReceiptModelSoldItem4> get rows => p.getCurrentClient.orderedProducts;

  List get deleted => p.getCurrentClient.deletedItems;

  double get total => ItemsSingleton.getTotalPrice(rows);

  Finder get pinDialog => find.byType(InputAlertDialog);

  Finder get opdDialog => find.byType(OperationOnProductDialog);

  OperationOnProductProvider get opd =>
      tester.element(find.byType(OPDBottom)).read<OperationOnProductProvider>();

  Future<void> pump() async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<OrderingProvider4>.value(value: p),
          BlocProvider<BlBloc>(create: (_) => BlBloc()),
        ],
        child: MaterialApp(
          navigatorKey: AppNavigation.navigatorKey,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('uz'),
          home: Builder(builder: (c) {
            SizeConfig().init(c);
            ctx = c;
            return const Scaffold(body: SizedBox.expand());
          }),
        ),
      ),
    );
    await tester.pump();
  }

  /// `OrderList._openRowEditor` bilan bir xil ochiladi.
  Future<void> openRow(int index) async {
    p.tapIndexToEdit(index);
    unawaited(OperationOnProduct.operationOnProductDialog(
      context: ctx,
      item: rows[index],
      isClientMinimumPrice: false,
    ));
    await settle();
  }

  Future<void> openBoxGroup(num count) async {
    p.beginBoxGroupEdit(kPid);
    p.tapIndexToEdit(0);
    unawaited(OperationOnProduct.operationOnProductDialog(
      context: ctx,
      item: rows.first,
      isClientMinimumPrice: false,
      displayValue: count,
    ).whenComplete(p.endBoxGroupEdit));
    await settle();
  }

  Future<void> openMarkGroup(num count) async {
    p.beginMarkGroupEdit(kPid);
    p.tapIndexToEdit(0);
    unawaited(OperationOnProduct.operationOnProductDialog(
      context: ctx,
      item: rows.first,
      isClientMinimumPrice: false,
      displayValue: count,
    ).whenComplete(p.endMarkGroupEdit));
    await settle();
  }

  /// Dialog animatsiyasi tugasin, lekin 400 ms lik taymerga yetmasin.
  Future<void> settle() async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  Future<void> tapDigit(String d) async {
    await tester.tap(find.byWidgetPredicate(
        (w) => w is LockNumberButton && w.number == d,
        description: 'raqam $d'));
    await tester.pump(const Duration(milliseconds: 20));
  }

  Future<void> key(LogicalKeyboardKey k) async {
    await tester.sendKeyEvent(k);
    await tester.pump(const Duration(milliseconds: 20));
  }

  /// Bitta bosish = down + up; `OPDCenter` ulardan bittasida ishlaydi.
  Future<void> backspace() => key(LogicalKeyboardKey.backspace);

  Future<void> _tapButton(String text) async {
    await tester.tap(find.widgetWithText(MaterialButton, text));
    await tester.pump(const Duration(milliseconds: 20));
  }

  Future<void> tapSave() => _tapButton(AppLocalizations.of(ctx)!.saqlash);

  Future<void> tapDelete() => _tapButton(AppLocalizations.of(ctx)!.ochirish);

  Future<void> tapIcon(IconData icon, {int at = 0}) async {
    await tester.tap(find.widgetWithIcon(ElevatedButton, icon).at(at));
    await tester.pump(const Duration(milliseconds: 20));
  }

  /// Barcha taymerlar ishlab bo'lsin: yopilgan dialog ham savatga tegmasin.
  Future<void> afterTimers() async {
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
  }

  Future<void> enterPin(String pin) async {
    await tester.enterText(find.byType(TextField).last, pin);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// PIN oynasini tashqariga bosib yopish (rad etish).
  Future<void> refusePin() async {
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<Host> hostWith(
  WidgetTester t, {
  double value = 10,
  double price = kUnit,
  bool kg = false,
}) async {
  final p = freshProvider();
  p.getCurrentClient.orderedProducts
      .add(makeSoldItem(productId: kPid, price: price, value: value, isKg: kg));
  final h = Host(t, p);
  await h.pump();
  return h;
}

/// Bitta blok = bitta qator; `value` = 1.
Future<Host> hostWithBoxes(WidgetTester t, int count) async {
  final p = freshProvider();
  for (var i = 0; i < count; i++) {
    p.getCurrentClient.orderedProducts.add(makeSoldItem(
      productId: kPid,
      price: kUnit * 12,
      saleType: 2,
      boxValue: 12,
      boxQuantity: count,
      mark: 'blok-$i',
    ));
  }
  final h = Host(t, p);
  await h.pump();
  return h;
}

Future<Host> hostWithMarks(WidgetTester t, int count) async {
  final p = freshProvider();
  for (var i = 0; i < count; i++) {
    p.getCurrentClient.orderedProducts.add(makeSoldItem(
      productId: kPid,
      price: kUnit,
      marking: true,
      mark: 'marka-$i',
    ));
  }
  final h = Host(t, p);
  await h.pump();
  return h;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('opd_qty_access', withEmployee: false);
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });
  tearDownAll(tearDownPosTestEnv);

  // testWidgets ichida Hive IO kutilsa osilib qoladi — sozlash shu yerda.
  setUp(() async {
    ItemsSingleton.products = [pepsi()];
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
    await setEmployees();
  });

  group('Raqam + tez Saqlash (kassirda ruxsat yo\'q)', () {
    testWidgets('PIN so\'raladi, rad etilsa savat va oyna o\'zgarmaydi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await h.tapSave();
      await h.settle();

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.first.value, 10);
      expect(h.deleted, isEmpty);

      await h.refusePin();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.opdDialog, findsOneWidget);
      expect(h.opd.target.value, 10);
      expect(h.rows.first.value, 10);
      expect(h.total, 10 * kUnit);
      expect(h.deleted, isEmpty);
    });

    testWidgets('rad etilgach qayta Saqlash: 10 qoladi, PIN so\'ralmaydi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);
      await h.tapDigit('3');
      await h.tapSave();
      await h.settle();
      await h.refusePin();

      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.opdDialog, findsNothing);
      expect(h.rows.first.value, 10);
      expect(h.deleted, isEmpty);
    });

    testWidgets('rad etilgach keyingi raqam qty o\'rniga yoziladi', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);
      await h.tapDigit('3');
      await h.tapSave();
      await h.settle();
      await h.refusePin();

      await h.tapDigit('2');
      expect(h.opd.target.value, 2);
      await h.afterTimers(); // taymer PIN so'raydi
      await h.refusePin();
    });

    testWidgets('to\'g\'ri PIN: 3 saqlanadi, jami 3 talik, deleted_by = rahbar',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await h.tapSave();
      await h.settle();
      await h.enterPin(kManagerPin);
      await h.afterTimers();

      expect(h.opdDialog, findsNothing);
      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 3);
      expect(h.total, 3 * kUnit, reason: 'to\'lov sahifasi shu summani oladi');
      expect(h.deleted.single.quantity, 7);
      expect(h.deleted.single.deletedBy, kManagerId);
    });

    testWidgets('ruxsati yo\'q xodim PINi o\'tmaydi', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await h.tapSave();
      await h.settle();
      await h.enterPin(kNoRightsPin);

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.first.value, 10);
      expect(h.deleted, isEmpty);
      await h.refusePin();
    });

    testWidgets('Enter ham Saqlash kabi tekshiriladi', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.key(LogicalKeyboardKey.digit3);
      await h.key(LogicalKeyboardKey.enter);
      await h.settle();

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.first.value, 10);
      await h.refusePin();
    });

    for (final ms in [0, 50, 150, 300, 390]) {
      testWidgets('raqamdan $ms ms keyin Saqlash: bitta PIN, savat 10',
          (t) async {
        final h = await hostWith(t);
        await h.openRow(0);

        await h.tapDigit('3');
        await t.pump(Duration(milliseconds: ms));
        await h.tapSave();
        await t.pump(const Duration(milliseconds: 700));

        expect(h.pinDialog, findsOneWidget);
        expect(h.opdDialog, findsOneWidget);
        expect(h.rows.first.value, 10);
        expect(h.total, 10 * kUnit);
        await h.refusePin();
        await h.afterTimers();
        expect(h.rows.first.value, 10);
      });
    }

    testWidgets('boshqa qatorlarga tegilmaydi', (t) async {
      final h = await hostWith(t);
      h.rows.insert(0, makeSoldItem(productId: 'cola', price: 500, value: 4));
      await h.openRow(1);

      await h.tapDigit('3');
      await h.tapSave();
      await h.settle();
      await h.enterPin(kManagerPin);
      await h.afterTimers();

      expect(h.rows[0].productId, 'cola');
      expect(h.rows[0].value, 4);
      expect(h.rows[1].value, 3);
    });

    testWidgets('pog\'ona narx: PIN dan keyin 3 ta o\'z narxida', (t) async {
      ItemsSingleton.products = [
        pepsi(tiers: [
          ShopPriceTiers(minQuantity: 1, retailPrice: kUnit),
          ShopPriceTiers(minQuantity: 10, retailPrice: 8000),
        ]),
      ];
      final h = await hostWith(t, price: 8000);
      await h.openRow(0);

      await h.tapDigit('3');
      await h.tapSave();
      await h.settle();
      expect(h.opd.target.price, 8000, reason: 'PIN paytida 10 talik narx');
      await h.enterPin(kManagerPin);
      await h.afterTimers();

      expect(h.rows.first.value, 3);
      expect(h.rows.first.price, kUnit);
      expect(h.total, 3 * kUnit);
    });
  });

  group('Terib to\'xtaganda PIN', () {
    testWidgets('rad etilsa 10 qaytadi, keyin Saqlash PIN siz', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await t.pump(const Duration(milliseconds: 500));
      expect(h.pinDialog, findsOneWidget);
      expect(h.opd.target.value, 10);

      await h.refusePin();
      expect(h.opd.target.value, 10);

      await h.tapSave();
      await h.afterTimers();
      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 10);
      expect(h.deleted, isEmpty);
    });

    testWidgets('to\'g\'ri PIN: Saqlashda ikkinchi marta so\'ralmaydi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await t.pump(const Duration(milliseconds: 500));
      await h.enterPin(kManagerPin);
      expect(h.opd.target.value, 3);

      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 3);
      expect(h.total, 3 * kUnit);
      expect(h.deleted.single.deletedBy, kManagerId);
    });

    testWidgets(
        'kassa kg: 2.5 → 1 tez Saqlash → PIN, 1.5 o\'chirilgan yoziladi',
        (t) async {
      ItemsSingleton.products = [pepsi(kg: true)];
      final h = await hostWith(t, value: 2.5, kg: true);
      await h.openRow(0);

      await h.tapDigit('1');
      await h.tapSave();
      await h.settle();
      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.first.value, 2.5);

      await h.enterPin(kManagerPin);
      await h.afterTimers();
      expect(h.rows.first.value, 1);
      expect(h.deleted.single.quantity, 1.5);
      expect(h.deleted.single.deletedBy, kManagerId);
    });

    testWidgets('kg: "1." da rad etilsa keyingi raqam butun son bo\'ladi',
        (t) async {
      ItemsSingleton.products = [pepsi(kg: true)];
      final h = await hostWith(t, value: 2.5, kg: true);
      await h.openRow(0);

      await h.tapDigit('1');
      await h.tapDigit('.');
      await t.pump(const Duration(milliseconds: 500));
      expect(h.pinDialog, findsOneWidget);
      await h.refusePin();
      expect(h.opd.target.value, 2.5);

      await h.tapDigit('3');
      expect(h.opd.target.value, 3);
    });

    testWidgets('ruxsat 7 gacha: undan pastga yana PIN', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);
      await h.tapDigit('7');
      await t.pump(const Duration(milliseconds: 500));
      await h.enterPin(kManagerPin);
      expect(h.opd.target.value, 7);

      await h.backspace(); // 7 → 0
      await h.tapDigit('3');
      await h.tapSave();
      await h.settle();

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.first.value, 10);
      await h.refusePin();
      expect(h.opd.target.value, 7, reason: 'oxirgi ruxsat etilgan qty');
    });

    testWidgets('ruxsat 7 gacha, keyin + bilan 9: PIN siz, 1 ta o\'chiriladi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);
      await h.tapDigit('7');
      await t.pump(const Duration(milliseconds: 500));
      await h.enterPin(kManagerPin);

      await h.tapIcon(Icons.add);
      await h.tapIcon(Icons.add);
      await h.tapSave();
      await h.afterTimers();

      expect(h.rows.first.value, 9);
      expect(h.deleted.single.quantity, 1);
      expect(h.deleted.single.deletedBy, kManagerId);
    });
  });

  group('Oshirish: PIN kerak emas', () {
    testWidgets('10 → "15" tez Saqlash', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('1');
      await h.tapDigit('5');
      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 15);
      expect(h.deleted, isEmpty);
    });

    testWidgets('10 → "15" terib to\'xtash: PIN yo\'q', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('1');
      await h.tapDigit('5');
      await t.pump(const Duration(milliseconds: 600));

      expect(h.pinDialog, findsNothing);
      expect(h.opd.target.value, 15);
    });

    testWidgets('+ bilan 11, - bilan 10: PIN yo\'q, hech narsa o\'chmaydi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapIcon(Icons.add);
      await h.tapIcon(Icons.remove);
      await t.pump(const Duration(milliseconds: 600));
      expect(h.pinDialog, findsNothing);
      expect(h.opd.target.value, 10);

      await h.tapSave();
      await h.afterTimers();
      expect(h.rows.first.value, 10);
      expect(h.deleted, isEmpty);
    });

    testWidgets('raqam terilmagan: Saqlash shunchaki yopadi', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.opdDialog, findsNothing);
      expect(h.rows.first.value, 10);
    });
  });

  group('Boshqa yo\'llar bilan kamaytirish', () {
    testWidgets('Backspace → 0 → Saqlash: PIN siz qator o\'chmaydi', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.backspace();
      expect(h.opd.target.value, 0);
      await h.tapSave();
      await h.settle();

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.single.value, 10);
      expect(h.deleted, isEmpty);

      await h.refusePin();
      expect(h.opd.target.value, 10);
      expect(h.opdDialog, findsOneWidget);
    });

    testWidgets('Backspace → 0 → Saqlash + PIN: qator o\'chadi, rahbar nomidan',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.backspace();
      await h.tapSave();
      await h.settle();
      await h.enterPin(kManagerPin);
      await h.afterTimers();

      expect(h.rows, isEmpty);
      expect(h.total, 0);
      expect(h.opdDialog, findsNothing);
      expect(h.deleted.single.quantity, 10);
      expect(h.deleted.single.deletedBy, kManagerId);
    });

    testWidgets('qizil o\'chirish: PIN bilan qator qizil, jami 0', (t) async {
      final h = await hostWith(t);
      await t.runAsync(() => Pref.setBool(PrefKeys.isRedDeleteActivated, true));
      await h.openRow(0);

      await h.backspace();
      await h.tapSave();
      await h.settle();
      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.single.isDeleted, isFalse);

      await h.enterPin(kManagerPin);
      await h.afterTimers();
      expect(h.rows.single.isDeleted, isTrue);
      expect(h.total, 0);
      expect(h.deleted.single.deletedBy, kManagerId);
    });

    testWidgets(
        'Backspace, keyin raqam: to\'xtaganda PIN (eski kodda yo\'q edi)',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.backspace(); // 10 → 0
      await h.tapDigit('3'); // 0 → 3
      await t.pump(const Duration(milliseconds: 500));

      expect(h.pinDialog, findsOneWidget);
      await h.refusePin();
      expect(h.opd.target.value, 10);
    });

    testWidgets('Backspace, keyin 10 dan katta son: PIN yo\'q', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.backspace(); // 10 → 0
      await h.tapDigit('1');
      await h.tapDigit('2');
      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 12);
      expect(h.deleted, isEmpty);
    });

    testWidgets('0 terib Saqlash: PIN siz qator o\'chmaydi', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('0');
      await h.tapSave();
      await h.settle();

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.single.value, 10);
      await h.refusePin();
      expect(h.rows.single.value, 10);
    });

    testWidgets('klaviatura `-`: darhol PIN, rad etilsa 10', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.key(LogicalKeyboardKey.numpadSubtract);
      await h.settle();
      expect(h.pinDialog, findsOneWidget);
      expect(h.opd.target.value, 10);

      await h.refusePin();
      expect(h.opd.target.value, 10);
      await h.tapSave();
      await h.afterTimers();
      expect(h.rows.first.value, 10);
      expect(h.deleted, isEmpty);
    });

    testWidgets('ekrandagi `-` + PIN: 9, Saqlashda qayta so\'ralmaydi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapIcon(Icons.remove);
      await h.settle();
      expect(h.pinDialog, findsOneWidget);
      await h.enterPin(kManagerPin);
      expect(h.opd.target.value, 9);

      await h.tapSave();
      await h.afterTimers();
      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 9);
      expect(h.deleted.single.quantity, 1);
      expect(h.deleted.single.deletedBy, kManagerId);
    });

    testWidgets('quti maydonidagi `-`: PIN so\'raladi', (t) async {
      final h = await hostWith(t, value: 12);
      h.rows.first
        ..soldBy = 'box'
        ..inBox = 6;
      await h.openRow(0);

      await h.tapIcon(Icons.remove, at: 1);
      await h.settle();
      expect(h.pinDialog, findsOneWidget);

      await h.refusePin();
      expect(h.opd.target.value, 12);
    });

    testWidgets('blok guruhi: Backspace → 0 → Saqlash PIN siz o\'chmaydi',
        (t) async {
      final h = await hostWithBoxes(t, 3);
      await h.openBoxGroup(3);

      await h.backspace();
      await h.tapSave();
      await h.settle();
      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.length, 3);
      expect(h.deleted, isEmpty);

      await h.enterPin(kManagerPin);
      await h.afterTimers();
      expect(h.rows, isEmpty);
      expect(h.deleted.length, 3);
      expect(h.deleted.every((d) => d.deletedBy == kManagerId), isTrue);
    });

    testWidgets('marka guruhi: Backspace → 0 → Saqlash PIN siz o\'chmaydi',
        (t) async {
      final h = await hostWithMarks(t, 3);
      await h.openMarkGroup(3);

      await h.backspace();
      await h.tapSave();
      await h.settle();
      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.length, 3);

      await h.refusePin();
      expect(h.rows.length, 3);
      expect(h.deleted, isEmpty);
    });

    testWidgets('marka guruhi: `-` + PIN: 1 ta marka o\'chadi', (t) async {
      final h = await hostWithMarks(t, 3);
      await h.openMarkGroup(3);

      await h.tapIcon(Icons.remove);
      await h.settle();
      await h.enterPin(kManagerPin);
      await h.tapSave();
      await h.afterTimers();

      expect(h.rows.length, 2);
      expect(h.deleted.single.deletedBy, kManagerId);
    });
  });

  group('Dialog yopilishi va kechikkan taymer', () {
    testWidgets('raqam terib oynani yopsa: PIN chiqmaydi, savat o\'zgarmaydi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await t.tapAt(const Offset(5, 5));
      await h.afterTimers();

      expect(h.opdDialog, findsNothing);
      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 10);
      expect(h.deleted, isEmpty);
    });

    testWidgets('raqam + O\'chirish: bitta PIN oynasi, rad etilsa qator joyida',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await h.tapDelete();
      await t.pump(const Duration(milliseconds: 700));

      expect(h.pinDialog, findsOneWidget, reason: 'ikkinchi PIN ochilmaydi');
      await h.refusePin();
      expect(h.opdDialog, findsOneWidget);
      expect(h.rows.single.value, 10);
      expect(h.deleted, isEmpty);
    });

    testWidgets('raqam + O\'chirish + PIN: qator o\'chadi, oyna yopiladi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await h.tapDelete();
      await h.settle();
      await h.enterPin(kManagerPin);
      await h.afterTimers();

      expect(h.opdDialog, findsNothing);
      expect(h.pinDialog, findsNothing);
      expect(h.rows, isEmpty);
      expect(h.deleted.single.quantity, 10);
      expect(h.deleted.single.deletedBy, kManagerId);
    });
  });

  group('PIN oynasi ochiq turganda', () {
    testWidgets('Saqlash hisobga olinmaydi, oyna ikkinchi marta ochilmaydi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);
      await h.tapDigit('3');
      await t.pump(const Duration(milliseconds: 500));
      expect(h.pinDialog, findsOneWidget);

      final opd = h.opd;
      final ctx = t.element(find.byType(OPDBottom));
      unawaited(opd.onSaveButtonPressed(ctx));
      unawaited(opd.attemptDecreaseQuantity(1, ctx));
      await h.settle();

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.first.value, 10);
      expect(h.opd.target.value, 10);
      await h.refusePin();
    });

    testWidgets('qty 1 da `-` + kutilayotgan taymer: bitta PIN (o\'chirish)',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('1'); // value=1, taymer ishlayapti
      await h.tapIcon(Icons.remove); // qty <= 1 → o'chirish PIN i
      await t.pump(const Duration(milliseconds: 700));

      expect(h.pinDialog, findsOneWidget);
      await h.refusePin();
      expect(h.rows.single.value, 10);
      expect(h.deleted, isEmpty);
    });
  });

  group('Kg mahsulot qo\'shilganda ochilgan og\'irlik oynasi', () {
    setUp(() => ItemsSingleton.products = [pepsi(kg: true)]);

    Future<Host> addKg(WidgetTester t, {double? existing}) async {
      final p = freshProvider();
      if (existing != null) {
        p.getCurrentClient.orderedProducts.add(makeSoldItem(
            productId: kPid, price: kUnit, value: existing, isKg: true));
      }
      final h = Host(t, p);
      await h.pump();
      p.addProduct(
          value: 1, product: pepsi(kg: true), where: 'test', context: h.ctx);
      await h.settle();
      await h.settle();
      expect(h.opdDialog, findsOneWidget);
      return h;
    }

    testWidgets('yangi qator: 0.35 PIN siz (sekin tersa ham)', (t) async {
      final h = await addKg(t);

      await h.tapDigit('0');
      await t.pump(const Duration(milliseconds: 500));
      expect(h.pinDialog, findsNothing);
      await h.tapDigit('.');
      await t.pump(const Duration(milliseconds: 500));
      await h.tapDigit('3');
      await t.pump(const Duration(milliseconds: 500));
      await h.tapDigit('5');
      await t.pump(const Duration(milliseconds: 500));
      expect(h.pinDialog, findsNothing);

      await h.tapSave();
      await h.afterTimers();
      expect(h.pinDialog, findsNothing);
      expect(h.rows.single.value, 0.35);
    });

    testWidgets('savatda 2 kg bor edi, +1: 2.5 ga PIN kerak emas', (t) async {
      final h = await addKg(t, existing: 2);
      expect(h.rows.single.value, 3);

      await h.tapDigit('2');
      await h.tapDigit('.');
      await h.tapDigit('5');
      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.rows.single.value, 2.5);
    });

    testWidgets('savatda 2 kg bor edi, +1: 1 ga tushirishga PIN kerak',
        (t) async {
      final h = await addKg(t, existing: 2);

      await h.tapDigit('1');
      await h.tapSave();
      await h.settle();

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.single.value, 3);
      await h.refusePin();
      expect(h.opd.target.value, 2, reason: 'qo\'shishdan oldingi qty');
    });

    testWidgets('keyin qatorni bosib kamaytirsa PIN kerak', (t) async {
      final h = await addKg(t);
      await h.tapSave(); // og'irlik oynasi: 1 kg
      await h.afterTimers();
      expect(h.rows.single.value, 1);

      await h.openRow(0);
      await h.tapDigit('0');
      await h.tapDigit('.');
      await h.tapDigit('5');
      await h.tapSave();
      await h.settle();

      expect(h.pinDialog, findsOneWidget);
      expect(h.rows.single.value, 1);
      await h.refusePin();
    });
  });

  group('Kassirda deletePrice ruxsati bor', () {
    setUp(() => setEmployees(delete: true));

    testWidgets('raqam + tez Saqlash: PIN yo\'q, qator 3 da qoladi', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 3);
      expect(h.total, 3 * kUnit);
      expect(h.deleted.single.quantity, 7);
      expect(h.deleted.single.deletedBy, kCashierId);
    });

    testWidgets('terib to\'xtash: PIN yo\'q, qty terilgani', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      await t.pump(const Duration(milliseconds: 600));

      expect(h.pinDialog, findsNothing);
      expect(h.opd.target.value, 3);
    });

    testWidgets('`-`: PIN yo\'q, 9', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapIcon(Icons.remove);
      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.rows.first.value, 9);
    });

    testWidgets('Backspace → 0 → Saqlash: PIN siz o\'chadi', (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.backspace();
      await h.tapSave();
      await h.afterTimers();

      expect(h.pinDialog, findsNothing);
      expect(h.rows, isEmpty);
      expect(h.deleted.single.deletedBy, kCashierId);
    });

    testWidgets('Enter ikki marta: bitta saqlash, asosiy sahifa joyida',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      final opd = h.opd;
      final ctx = t.element(find.byType(OPDBottom));
      await opd.onSaveButtonPressed(ctx);
      await opd.onSaveButtonPressed(ctx);
      await h.afterTimers();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(h.opdDialog, findsNothing);
      expect(h.rows.first.value, 3);
      expect(h.deleted.length, 1);
    });

    testWidgets('saqlangach kechikkan tugma savat qatoriga tegmaydi',
        (t) async {
      final h = await hostWith(t);
      await h.openRow(0);

      await h.tapDigit('3');
      final opd = h.opd;
      await h.tapSave();

      opd
        ..onNumPressed('5')
        ..onBackSpacePressed()
        ..increaseQuantity(1)
        ..decreaseQuantity(1);
      await h.afterTimers();

      expect(h.rows.first.value, 3);
      expect(h.total, 3 * kUnit);
    });
  });

  group('Narx maydonlari: Backspace ham editPrice talab qiladi', () {
    Future<Host> manualRow(WidgetTester t) async {
      final h = await hostWith(t);
      h.rows.first
        ..isPriceOnlyChanged = true
        ..isPriceChanged = true;
      await h.openRow(0);
      return h;
    }

    for (final field in {0: 'narx', 3: 'chegirma', 5: 'asl narx'}.entries) {
      testWidgets('ruxsatsiz, ${field.value}: o\'zgarmaydi', (t) async {
        final h = await manualRow(t);

        h.opd.selectInput(field.key);
        await t.pump();
        await h.backspace();
        await h.tapSave();
        await h.afterTimers();

        expect(h.rows.first.price, kUnit);
        expect(h.rows.first.onlyPrice, kUnit);
        expect(h.rows.first.discountPercent ?? 0, 0);
        expect(h.total, 10 * kUnit);
      });
    }

    testWidgets('ruxsatsiz, 20% chegirmali qator: chegirma o\'zgarmaydi',
        (t) async {
      final h = await hostWith(t, price: 8000);
      h.rows.first
        ..realPrice = kUnit
        ..onlyPrice = kUnit
        ..discountPercent = 20
        ..isPriceOnlyChanged = true
        ..isPriceChanged = true;
      await h.openRow(0);

      h.opd.selectInput(3);
      await t.pump();
      h.opd.isSelectedAlls = List.generate(6, (_) => false);
      await h.backspace();
      await h.tapSave();
      await h.afterTimers();

      expect(h.rows.first.price, 8000);
      expect(h.rows.first.discountPercent, 20);
    });

    testWidgets('ruxsati bor kassir narxni Backspace bilan o\'zgartiradi',
        (t) async {
      await t.runAsync(() => setEmployees(edit: true));
      final h = await manualRow(t);

      h.opd.selectInput(0);
      await t.pump();
      await h.backspace();
      await h.tapSave();
      await h.afterTimers();

      expect(h.rows.first.price, lessThan(kUnit));
    });

    testWidgets('narx maydoni tanlangan, raqam: ruxsatsiz o\'zgarmaydi',
        (t) async {
      final h = await manualRow(t);

      h.opd.selectInput(0);
      await t.pump();
      await h.tapDigit('5');
      await h.tapSave();
      await h.afterTimers();

      expect(h.rows.first.price, kUnit);
    });
  });
}
