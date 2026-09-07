
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/row_repricer.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

const kPid = 'suv-id';
const kBox = 12;

ItemModel product({
  String id = kPid,
  Map<int, num> tiers = const {1: 5000, 12: 4500},
  String unit = 'dona',
  int vatPercent = 12,
}) {
  final m = ItemModel();
  m.id = id;
  m.name = 'Suv';
  m.vat = Vat(percentage: vatPercent);
  m.measurementUnit = MeasurementUnit(shortName: unit);
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: 'shop-1', shopPriceTiers: [
      for (final t in tiers.entries)
        ShopPriceTiers(minQuantity: t.key, retailPrice: t.value)
    ]),
  );
  return m;
}

class DiscountSpy {
  final calls = <String>[];
  void call(ItemModel p, ReceiptModelSoldItem4 row) =>
      calls.add('${row.productId}:${row.saleType}');
}

void main() {
  setUpAll(() => setUpPosTestEnv('row_repricer_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() => ItemsSingleton.products = [product()]);

  group('isKg', () {
    test('кг (kirill) → true', () {
      expect(RowRepricer.isKg(product(unit: 'кг')), isTrue);
    });

    test('kg (lotin) → true', () {
      expect(RowRepricer.isKg(product(unit: 'kg')), isTrue);
    });

    test('dona → false', () {
      expect(RowRepricer.isKg(product(unit: 'dona')), isFalse);
    });

    test('QAYD: "КГ" (bosh harf) tanilmaydi → false', () {
      expect(RowRepricer.isKg(product(unit: 'КГ')), isFalse);
    });

    test('o\'lchov birligi yo\'q → false', () {
      final m = ItemModel();
      expect(RowRepricer.isKg(m), isFalse);
    });
  });

  group('applyExistingManualPrice — ilgari testlab bo\'lmagan', () {
    test('qo\'lda narxli qator yo\'q → false, qatorlar tegilmaydi', () {
      final rows = [
        makeSoldItem(productId: kPid, price: 2000),
        makeSoldItem(productId: kPid, price: 2000),
      ];
      expect(RowRepricer.applyExistingManualPrice(rows, kPid), isFalse);
      expect(rows[1].price, 2000);
    });

    test('qo\'lda narxli qator bor → true va boshqalarga tarqaladi', () {
      final rows = [
        makeSoldItem(productId: kPid, price: 3000, isPriceOnlyChanged: true),
        makeSoldItem(productId: kPid, price: 2000),
      ];
      expect(RowRepricer.applyExistingManualPrice(rows, kPid), isTrue);
      expect(rows[1].price, 3000);
      expect(rows[1].isPriceOnlyChanged, isTrue);
    });

    test('manual dona narxi yangi BLOK qatoriga ko\'payib o\'tadi', () {
      final rows = [
        makeSoldItem(productId: kPid, price: 3000, isPriceOnlyChanged: true),
        makeSoldItem(
            productId: kPid, price: 1, saleType: 2, boxValue: kBox),
      ];
      expect(RowRepricer.applyExistingManualPrice(rows, kPid), isTrue);
      expect(rows[1].price, 3000 * kBox);
    });

    test('manual BLOK narxi yangi dona qatoriga bo\'linib o\'tadi', () {
      final rows = [
        makeSoldItem(
            productId: kPid,
            price: 36000,
            saleType: 2,
            boxValue: kBox,
            isPriceOnlyChanged: true),
        makeSoldItem(productId: kPid, price: 1),
      ];
      expect(RowRepricer.applyExistingManualPrice(rows, kPid), isTrue);
      expect(rows[1].price, 3000);
    });

    test('o\'chirilgan manual qator manba bo\'lmaydi → false', () {
      final rows = [
        makeSoldItem(
            productId: kPid,
            price: 3000,
            isPriceOnlyChanged: true,
            isDeleted: true),
        makeSoldItem(productId: kPid, price: 2000),
      ];
      expect(RowRepricer.applyExistingManualPrice(rows, kPid), isFalse);
      expect(rows[1].price, 2000);
    });

    test('tekin sovg\'a manual qatori manba bo\'lmaydi → false', () {
      final rows = [
        makeSoldItem(
            productId: kPid,
            price: 3000,
            isPriceOnlyChanged: true,
            isFreeGift: true),
        makeSoldItem(productId: kPid, price: 2000),
      ];
      expect(RowRepricer.applyExistingManualPrice(rows, kPid), isFalse);
    });

    test('bir nechta manual qatordan BIRINCHISI manba bo\'ladi', () {
      final rows = [
        makeSoldItem(productId: kPid, price: 3000, isPriceOnlyChanged: true),
        makeSoldItem(productId: kPid, price: 7000, isPriceOnlyChanged: true),
        makeSoldItem(productId: kPid, price: 1),
      ];
      RowRepricer.applyExistingManualPrice(rows, kPid);
      expect(rows[2].price, 3000);
    });

    test('boshqa mahsulotning manual qatori hisobga olinmaydi → false', () {
      final rows = [
        makeSoldItem(
            productId: 'boshqa', price: 3000, isPriceOnlyChanged: true),
        makeSoldItem(productId: kPid, price: 2000),
      ];
      expect(RowRepricer.applyExistingManualPrice(rows, kPid), isFalse);
      expect(rows[1].price, 2000);
    });

    test('productId null → false', () {
      expect(RowRepricer.applyExistingManualPrice([], null), isFalse);
    });

    test('productId bo\'sh → false', () {
      expect(RowRepricer.applyExistingManualPrice([], ''), isFalse);
    });

    test('bo\'sh savat → false', () {
      expect(RowRepricer.applyExistingManualPrice([], kPid), isFalse);
    });
  });

  group('byTotalUnits — diskont qo\'llovchi chaqiruvi', () {
    test('faqat DONA qatorlariga diskont qo\'llanadi (blokka emas)', () {
      final spy = DiscountSpy();
      final rows = [
        makeSoldItem(productId: kPid, price: 1, value: 1),
        makeSoldItem(
            productId: kPid, price: 1, value: 1, saleType: 2, boxValue: kBox),
      ];
      RowRepricer.byTotalUnits(rows, kPid, applyDiscounts: spy.call);
      expect(spy.calls, ['$kPid:1']);
    });

    test('early return bo\'lsa diskont umuman chaqirilmaydi', () {
      final spy = DiscountSpy();
      RowRepricer.byTotalUnits([], 'yoq-id', applyDiscounts: spy.call);
      expect(spy.calls, isEmpty);
    });

    test('qo\'lda narxli qatorga diskont chaqirilmaydi', () {
      final spy = DiscountSpy();
      final rows = [
        makeSoldItem(productId: kPid, price: 3000, isPriceOnlyChanged: true),
      ];
      RowRepricer.byTotalUnits(rows, kPid, applyDiscounts: spy.call);
      expect(spy.calls, isEmpty);
    });
  });

  group('syncManualPrice — to\'g\'ridan-to\'g\'ri', () {
    test('bo\'sh productId li tahrir hech narsani o\'zgartirmaydi', () {
      final rows = [makeSoldItem(productId: '', price: 2000)];
      RowRepricer.syncManualPrice(rows, makeSoldItem(productId: '', price: 9));
      expect(rows[0].price, 2000);
    });

    test('bo\'sh savatda xato bermaydi', () {
      expect(
        () => RowRepricer.syncManualPrice(
            [], makeSoldItem(productId: kPid, price: 100)),
        returnsNormally,
      );
    });
  });
}
