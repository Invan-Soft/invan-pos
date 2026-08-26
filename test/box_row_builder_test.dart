// Blok (yaqin qadoq) qatori — `BoxRowBuilder`.
//
// Blok qatorining semantikasi savatdagi guruhlash, tier narx va vozvrat
// hisobining asosi: bitta qator = bitta blok (`value: 1`), narx BUTUN blok
// narxi, `marking: false`. Buzilsa blok noto'g'ri narxda sotiladi yoki
// markirovka guruhiga aralashib ketadi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/box_row_builder.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kMarkingMxik = '02202001001000000';
const kPlainMxik = '01101001001000000';

ItemModel product({
  String mxik = kPlainMxik,
  String name = 'Suv 1L',
  int vatPercent = 12,
  num supplyPrice = 3000,
  String? ownerType = '2',
}) {
  final m = ItemModel();
  m.id = 'suv-id';
  m.name = name;
  m.sku = '1001';
  m.mxikCode = mxik;
  m.packageCode = 'PACK-1';
  m.packageName = 'BOX';
  m.commissionTin = '123456789';
  m.ownerType = ownerType;
  m.barcode = ['4780000000001'];
  m.vat = Vat(percentage: vatPercent, name: 'NDS $vatPercent%');
  m.shopPrices =
      ShopPrices(shID: ShID(shopId: 'shop-1', supplyPrice: supplyPrice));
  return m;
}

ReceiptModelSoldItem4 row({
  ItemModel? p,
  double boxPrice = 60000,
  int boxValue = 12,
  int boxQuantity = 1,
  String rawMark = 'BOX-KM-1',
}) =>
    BoxRowBuilder.build(p ?? product(),
        boxPrice: boxPrice,
        boxValue: boxValue,
        boxQuantity: boxQuantity,
        rawMark: rawMark,
        sellerId: 'kassir-1');

void main() {
  setUpAll(() async {
    await setUpPosTestEnv('box_row_builder_test');
    await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
  });
  tearDownAll(tearDownPosTestEnv);

  group('Blok semantikasi', () {
    test('saleType = 2 (blok qatori)', () => expect(row().saleType, 2));

    test('value HAR DOIM 1 — bitta qator bitta blok', () {
      expect(row(boxQuantity: 5).value, 1);
    });

    test('narx BUTUN blok narxi', () => expect(row(boxPrice: 60000).price, 60000));

    test('boxValue va boxQuantity saqlanadi', () {
      final r = row(boxValue: 6, boxQuantity: 3);
      expect(r.boxValue, 6);
      expect(r.boxQuantity, 3);
    });

    test('marking HAR DOIM false — blok markirovka guruhiga kirmaydi', () {
      expect(row(p: product(mxik: kMarkingMxik)).marking, isFalse);
    });

    test('markirovkali mahsulotda blok KM saqlanadi', () {
      expect(row(p: product(mxik: kMarkingMxik), rawMark: 'KM-9').mark, 'KM-9');
    });

    test('markirovkasiz mahsulotda mark null', () {
      expect(row(p: product(mxik: kPlainMxik)).mark, isNull);
    });

    test('nomga " //blok" qo\'shiladi', () {
      expect(row(p: product(name: 'Pepsi')).productName, 'Pepsi //blok');
    });
  });

  group('Narx va QQS', () {
    test('realPrice va onlyPrice blok narxiga teng', () {
      final r = row(boxPrice: 48000);
      expect([r.realPrice, r.onlyPrice], [48000, 48000]);
    });

    test('QQS blok narxidan hisoblanadi', () {
      expect(row(boxPrice: 11200).vat, closeTo(11200 * 12 / 112, 0.001));
    });

    test('narx 0 bo\'lsa QQS ham 0', () => expect(row(boxPrice: 0).vat, 0));

    test('tannarx katalogning supplyPrice idan', () {
      expect(row(p: product(supplyPrice: 45000)).cost, 45000);
    });

    test('diskont maydonlari nolda', () {
      final r = row();
      expect(r.singleDiscount, 0);
      expect(r.discountPercent, 0);
    });
  });

  group('Katalogdan ko\'chadigan maydonlar', () {
    test('MXIK, paket kodi/nomi va komissiya INN', () {
      final r = row();
      expect(r.mxik, kPlainMxik);
      expect(r.packageCode, 'PACK-1');
      expect(r.packageName, 'BOX');
      expect(r.tin, '123456789');
    });

    test('ownerType raqamga o\'giriladi, yo\'q bo\'lsa 1', () {
      expect(row(p: product(ownerType: '3')).ownerType, 3);
      expect(row(p: product(ownerType: null)).ownerType, 1);
    });

    test('sellerId parametrdan keladi', () {
      expect(row().sellerId, 'kassir-1');
    });

    test('yangi qator o\'chirilmagan', () => expect(row().isDeleted, isFalse));
  });
}
