// Blok UI guruhlash testi: groupBasketRows blok qatorlarini (saleType==2) bir
// xil productId bo'yicha bitta qatorga yig'adi. Data model o'zgarmaydi — bu
// faqat savat/to'lov ekranidagi vizual guruhlash. Blok guruhi marka guruhidan
// va dona qatorlaridan ALOHIDA bo'ladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/home/features/home_orders/order_list/basket_grouping.dart';

ReceiptModelSoldItem4 makeRow({
  String productId = 'montella-id',
  String name = 'Montella 1L',
  double price = 1800,
  double value = 1,
  int saleType = 1,
  int boxValue = 0,
  int boxQuantity = 0,
  bool marking = false,
  String? mark,
  bool isDeleted = false,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: '4780000000000',
    sku: 1001,
    vatPercent: 12,
    vat: (price * 12) / 112,
    mxik: '02202001001000000',
    tin: '',
    onlyPrice: price,
    realPrice: price,
    price: price,
    cost: 0,
    vatName: 'НДС 12%',
    createdTime: DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: name,
    sellerId: '',
    soldBy: 'kassir-001',
    singleDiscount: 0,
    ownerType: 0,
    marking: marking,
    mark: mark,
    isDeleted: isDeleted,
    saleType: saleType,
    boxValue: boxValue,
    boxQuantity: boxQuantity,
  );
}

void main() {
  group('groupBasketRows — blok guruhlash', () {
    test('3 blok (value=1, blok narx=21600) -> 1 qator, qty=3 blok, 36 dona',
        () {
      final items = [
        makeRow(
            saleType: 2,
            value: 1,
            price: 21600,
            boxValue: 12,
            boxQuantity: 3),
        makeRow(
            saleType: 2,
            value: 1,
            price: 21600,
            boxValue: 12,
            boxQuantity: 3),
        makeRow(
            saleType: 2,
            value: 1,
            price: 21600,
            boxValue: 12,
            boxQuantity: 3),
      ];
      final rows = groupBasketRows(items);
      expect(rows.length, 1);
      final r = rows.first;
      expect(r.isBoxGroup, true);
      expect(r.isMarkGroup, false);
      expect(r.totalValue, 3); // blok soni
      expect(r.unitPrice, 21600); // blok narxi
      expect(r.totalPrice, 64800); // 3 * 21600
      expect(r.boxValue, 12);
      expect(r.totalUnits, 36); // 3 blok * 12 dona
      expect(r.indices.length, 3);
    });

    test('blok + dona bir mahsulot -> 2 alohida qator (guruhlanmaydi)', () {
      final items = [
        makeRow(
            saleType: 2,
            value: 1,
            price: 21600,
            boxValue: 12,
            boxQuantity: 1),
        makeRow(saleType: 1, value: 3, price: 1800), // dona
      ];
      final rows = groupBasketRows(items);
      expect(rows.length, 2);
      final box = rows.firstWhere((e) => e.isBoxGroup);
      final loose = rows.firstWhere((e) => !e.isBoxGroup && !e.isMarkGroup);
      expect(box.totalValue, 1);
      expect(box.totalUnits, 12);
      expect(loose.totalValue, 3);
    });

    test("o'chirilgan blok guruhga kirmaydi", () {
      final items = [
        makeRow(
            saleType: 2,
            value: 1,
            price: 21600,
            boxValue: 12,
            boxQuantity: 2),
        makeRow(
            saleType: 2,
            value: 1,
            price: 21600,
            boxValue: 12,
            boxQuantity: 2,
            isDeleted: true),
      ];
      final rows = groupBasketRows(items);
      final boxGroup = rows.firstWhere((e) => e.isBoxGroup);
      expect(boxGroup.totalValue, 1); // faqat aktiv blok
      // o'chirilgan blok alohida qator bo'lib qoladi (audit ko'rinishi)
      expect(rows.any((e) => !e.isBoxGroup && (e.representative.isDeleted ?? false)),
          true);
    });

    test('blok va marka guruhlari alohida (bitta mahsulot)', () {
      final items = [
        makeRow(
            saleType: 2,
            value: 1,
            price: 21600,
            boxValue: 12,
            boxQuantity: 1),
        makeRow(saleType: 1, value: 1, price: 1800, marking: true, mark: 'm1'),
        makeRow(saleType: 1, value: 1, price: 1800, marking: true, mark: 'm2'),
      ];
      final rows = groupBasketRows(items);
      expect(rows.length, 2);
      final box = rows.firstWhere((e) => e.isBoxGroup);
      final mark = rows.firstWhere((e) => e.isMarkGroup);
      expect(box.totalValue, 1);
      expect(mark.totalValue, 2);
    });

    test('turli mahsulot bloklari alohida qatorlarda', () {
      final items = [
        makeRow(
            productId: 'a',
            saleType: 2,
            value: 1,
            price: 21600,
            boxValue: 12,
            boxQuantity: 1),
        makeRow(
            productId: 'b',
            saleType: 2,
            value: 1,
            price: 30000,
            boxValue: 6,
            boxQuantity: 1),
      ];
      final rows = groupBasketRows(items);
      expect(rows.length, 2);
      expect(rows.every((e) => e.isBoxGroup), true);
    });
  });
}
