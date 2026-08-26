// Markirovkali mahsulot qatori — `MarkedRowBuilder`.
//
// KM skanerlanganda har DONA alohida qator bo'ladi (miqdor har doim 1),
// chunki har donaning o'z markirovka kodi bor. Bu qoida savatdagi guruhlash
// va OPD dagi qty tahririning asosi — buzilsa, kassir qty ni o'zgartira
// olmay qoladi yoki KM lar aralashib ketadi.
//
// Bu kod Faza 9.5 gacha `addSeperatedProduct` ichida edi: metod dialog
// ochadi va `AppNavigation.navigatorKey` ni talab qiladi — testlab bo'lmasdi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/marked_row_builder.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kMarkingMxik = '02202001001000000'; // suv — markirovka guruhida
const kPlainMxik = '01101001001000000';

ItemModel product({
  String mxik = kMarkingMxik,
  bool isMarking = false,
  String unit = 'dona',
  int vatPercent = 12,
  String? ownerType = '2',
  String? packageType = 'BOX',
}) {
  final m = ItemModel();
  m.id = 'suv-id';
  m.name = 'Suv 1L';
  m.sku = '1001';
  m.mxikCode = mxik;
  m.isMarking = isMarking;
  m.packageCode = 'PACK-1';
  m.packageType = packageType;
  m.commissionTin = '123456789';
  m.ownerType = ownerType;
  m.barcode = ['4780000000001', '4780000000002'];
  m.vat = Vat(percentage: vatPercent, name: 'NDS $vatPercent%');
  m.measurementUnit = MeasurementUnit(shortName: unit);
  return m;
}

ReceiptModelSoldItem4 row({
  ItemModel? p,
  double price = 5000,
  String? mark = 'KM-001',
  String sellerId = 'kassir-1',
}) =>
    MarkedRowBuilder.build(p ?? product(), price,
        markValue: mark, sellerId: sellerId);

void main() {
  setUpAll(() async {
    await setUpPosTestEnv('marked_row_builder_test');
    await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
  });
  tearDownAll(tearDownPosTestEnv);

  group('Markirovka semantikasi', () {
    test('miqdor HAR DOIM 1 — har skan alohida qator', () {
      expect(row().value, 1);
    });

    test('markirovkali mahsulotga skanerlangan KM biriktiriladi', () {
      expect(row(mark: 'KM-XYZ').mark, 'KM-XYZ');
    });

    test('markirovkasiz mahsulotda mark null', () {
      expect(row(p: product(mxik: kPlainMxik)).mark, isNull);
    });

    test('marking bayrog\'i MxikRules qaroriga tayanadi', () {
      expect(row().marking, isTrue);
      expect(row(p: product(mxik: kPlainMxik)).marking, isFalse);
    });

    test('OFD o\'chiq bo\'lsa marking false va mark null', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, false);
      final r = row();
      expect(r.marking, isFalse);
      expect(r.mark, isNull);
      await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    });

    test('markirovkali mahsulotga productType va KIZ qo\'yiladi', () {
      final r = row();
      expect(r.productType, isNotEmpty);
      expect(r.productPackage, 'KIZ');
    });

    test('markirovkasizda ikkalasi bo\'sh', () {
      final r = row(p: product(mxik: kPlainMxik));
      expect(r.productType, isEmpty);
      expect(r.productPackage, isEmpty);
    });
  });

  group('SoldItemBuilder dan farqlari (ataylab)', () {
    test('soldBy da O\'LCHOV BIRLIGI ketadi (kategoriya IDsi emas)', () {
      expect(row(p: product(unit: 'кг')).soldBy, 'кг');
    });

    test('o\'lchov birligi yo\'q bo\'lsa bo\'sh string', () {
      final m = product();
      m.measurementUnit = null;
      expect(row(p: m).soldBy, '');
    });

    test('packageName mahsulot qadoq turidan', () {
      expect(row(p: product(packageType: 'PALLET')).packageName, 'PALLET');
    });

    test('cost har doim 0 (tannarx skan yo\'lida kelmaydi)', () {
      expect(row().cost, 0);
    });
  });

  group('Narx va QQS', () {
    test('price, realPrice, onlyPrice bir xil', () {
      final r = row(price: 4500);
      expect([r.price, r.realPrice, r.onlyPrice], [4500, 4500, 4500]);
    });

    test('QQS narxdan hisoblanadi (12%)', () {
      expect(row(price: 5600).vat, closeTo(5600 * 12 / 112, 0.001));
    });

    test('narx 0 bo\'lsa QQS ham 0', () {
      expect(row(price: 0).vat, 0);
    });

    test('QQS foizi 0 bo\'lsa vatPercent 0', () {
      expect(row(p: product(vatPercent: 0)).vatPercent, 0);
    });

    test('diskont maydonlari nolda boshlanadi', () {
      final r = row();
      expect(r.singleDiscount, 0);
      expect(r.discountPercent, 0);
    });
  });

  group('Katalogdan ko\'chadigan maydonlar', () {
    test('nom, MXIK, paket kodi, komissiya INN', () {
      final r = row();
      expect(r.productName, 'Suv 1L');
      expect(r.mxik, kMarkingMxik);
      expect(r.packageCode, 'PACK-1');
      expect(r.tin, '123456789');
    });

    test('barcode BIRINCHI koddan', () {
      expect(row().barcode, '4780000000001');
    });

    test('ownerType raqamga o\'giriladi', () {
      expect(row(p: product(ownerType: '3')).ownerType, 3);
    });

    test('ownerType bo\'sh bo\'lsa 1', () {
      expect(row(p: product(ownerType: '')).ownerType, 1);
    });

    test('sellerId parametrdan keladi (joriy kassir)', () {
      expect(row(sellerId: 'kassir-777').sellerId, 'kassir-777');
    });

    test('yangi qator o\'chirilmagan va inBox = 0', () {
      final r = row();
      expect(r.isDeleted, isFalse);
      expect(r.inBox, 0);
    });
  });
}
