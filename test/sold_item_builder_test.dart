// Savat qatori yasovchi (`SoldItemBuilder.build`) — test.
//
// Faza 8 da `_createSoldItem` dan ajratildi. Ilgari private edi — testlanmasdi.
// Bu savatga mahsulot qo'shishning yuragi: har skan/bosishda chaqiriladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/sold_item_builder.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

ItemModel product({
  String id = 'p1',
  String name = 'Pepsi',
  String? mxik = '02202001001000000',
  bool? isMarking,
  List<String> barcode = const ['4780000000000'],
  String sku = '1001',
}) {
  final m = ItemModel();
  m.id = id;
  m.name = name;
  m.mxikCode = mxik;
  m.isMarking = isMarking;
  m.barcode = barcode;
  m.sku = sku;
  return m;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('sold_item_builder_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
  });

  group('Asosiy maydonlar', () {
    test('narx, miqdor va nom ko\'chadi', () {
      final r = SoldItemBuilder.build(product(name: 'Pepsi'), 5000, 3, false);

      expect(r.productName, 'Pepsi');
      expect(r.price, 5000);
      expect(r.value, 3);
      expect(r.productId, 'p1');
    });

    test('yangi qator o\'chirilmagan va inBox = 0', () {
      final r = SoldItemBuilder.build(product(), 5000, 1, false);

      expect(r.isDeleted, isFalse);
      expect(r.inBox, 0);
    });

    test('realPrice va onlyPrice boshida narxga teng', () {
      final r = SoldItemBuilder.build(product(), 5000, 1, false);

      expect(r.realPrice, 5000);
      expect(r.onlyPrice, 5000);
    });
  });

  group('isKg bayrog\'i', () {
    test('kilo mahsulot', () {
      final r = SoldItemBuilder.build(product(), 5000, 1.5, true);

      expect(r.isKg, isTrue);
      expect(r.value, 1.5);
    });

    test('dona mahsulot', () {
      expect(SoldItemBuilder.build(product(), 5000, 1, false).isKg, isFalse);
    });
  });

  group('Markirovka aniqlash (MxikRules orqali)', () {
    test('MXIK ro\'yxatda -> marking true', () {
      final r = SoldItemBuilder.build(
          product(mxik: '02205000000000000'), 5000, 1, false);

      expect(r.marking, isTrue);
    });

    test('product.isMarking = true -> marking true', () {
      final r = SoldItemBuilder.build(
          product(mxik: '99999999999999999', isMarking: true), 5000, 1, false);

      expect(r.marking, isTrue);
    });

    test('tanish bo\'lmagan MXIK -> marking false', () {
      final r = SoldItemBuilder.build(
          product(mxik: '99999999999999999'), 5000, 1, false);

      expect(r.marking, isFalse);
    });

    test('markirovkali mahsulotga productType va KIZ qo\'yiladi', () {
      final r = SoldItemBuilder.build(
          product(mxik: '02205000000000000'), 5000, 1, false);

      expect(r.productType, '2'); // alkogol
      expect(r.productPackage, 'KIZ');
    });

    test('markirovkasiz mahsulotda ikkalasi bo\'sh', () {
      final r = SoldItemBuilder.build(
          product(mxik: '99999999999999999'), 5000, 1, false);

      expect(r.productType, '');
      expect(r.productPackage, '');
    });
  });

  group('Chetki holatlar', () {
    test('mxikCode null bo\'lsa xato bermaydi', () {
      final r = SoldItemBuilder.build(product(mxik: null), 5000, 1, false);

      expect(r.marking, isFalse);
      expect(r.productType, '');
    });

    test('narx 0 bo\'lsa ham qator yasaladi', () {
      final r = SoldItemBuilder.build(product(), 0, 1, false);

      expect(r.price, 0);
      expect(r.realPrice, 0);
    });
  });
}
