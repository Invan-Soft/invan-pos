// OPD narx tahriri blok ⇄ dona sinxronligi testi.
// Blok qatorining narxi o'zgartirilsa dona qatorlari (narx/boxValue) ga,
// dona narxi o'zgartirilsa blok qatorlari (narx×boxValue) ga tushishi kerak —
// bitta mahsulot, narxi bir xil. Orqa fon (value/price semantikasi) o'zgarmaydi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

ReceiptModelSoldItem4 makeRow({
  String productId = 'montella-id',
  String name = 'Montella Daily 0.33',
  double price = 1800,
  double value = 1,
  int saleType = 1,
  int boxValue = 0,
  int boxQuantity = 0,
  bool isFreeGift = false,
  bool isPriceOnlyChanged = false,
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
    soldBy: kCashierId,
    singleDiscount: 0,
    ownerType: 0,
    isDeleted: false,
    isFreeGift: isFreeGift,
    saleType: saleType,
    boxValue: boxValue,
    boxQuantity: boxQuantity,
  )..isPriceOnlyChanged = isPriceOnlyChanged;
}

/// OPD saqlashda yuboriladigan "tahrirlangan nusxa": narxi qo'lda o'zgartirilgan
ReceiptModelSoldItem4 editedCopy(ReceiptModelSoldItem4 src, double newPrice) {
  final copy = makeRow(
    productId: src.productId,
    name: src.productName,
    price: newPrice,
    value: src.value,
    saleType: src.saleType,
    boxValue: src.boxValue,
    boxQuantity: src.boxQuantity,
  );
  copy.isPriceOnlyChanged = true;
  copy.isPriceChanged = true;
  return copy;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('box_price_sync_test'));
  tearDownAll(tearDownPosTestEnv);

  group('OPD narx tahriri — blok ⇄ dona sinxron', () {
    test('blok narxi 21600->18000: dona qatori 1800->1500 bo\'ladi', () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 21600, value: 1, saleType: 2, boxValue: 12, boxQuantity: 1);
      final dona = makeRow(price: 1800, value: 1);
      p.getCurrentClient.orderedProducts.addAll([blok, dona]);

      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(editedCopy(blok, 18000));

      final rows = p.getCurrentClient.orderedProducts;
      final blokRow = rows.firstWhere((e) => e.saleType == 2);
      final donaRow = rows.firstWhere((e) => e.saleType != 2);
      expect(blokRow.price, 18000);
      expect(donaRow.price, 1500); // 18000 / 12
      expect(donaRow.onlyPrice, 1500);
      expect(donaRow.isPriceOnlyChanged, true); // tier reprice tegmasin
    });

    test('dona narxi 1800->2000: blok qatori 21600->24000 bo\'ladi', () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 21600, value: 1, saleType: 2, boxValue: 12, boxQuantity: 1);
      final dona = makeRow(price: 1800, value: 1);
      p.getCurrentClient.orderedProducts.addAll([blok, dona]);

      p.tapIndexToEdit(1);
      await p.pressDialogSaveButton(editedCopy(dona, 2000));

      final rows = p.getCurrentClient.orderedProducts;
      final blokRow = rows.firstWhere((e) => e.saleType == 2);
      expect(blokRow.price, 24000); // 2000 × 12
      expect(blokRow.isPriceOnlyChanged, true);
    });

    test('narx o\'zgarmagan tahrirda (qty-only) boshqa qatorga tegilmaydi',
        () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 21600, value: 1, saleType: 2, boxValue: 12, boxQuantity: 1);
      final dona = makeRow(price: 1800, value: 3);
      p.getCurrentClient.orderedProducts.addAll([blok, dona]);

      p.tapIndexToEdit(1);
      // narx bir xil (1800), faqat qty 3->2
      final copy = makeRow(price: 1800, value: 2);
      await p.pressDialogSaveButton(copy);

      final blokRow = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.saleType == 2);
      expect(blokRow.price, 21600); // o'zgarmagan
      expect(blokRow.isPriceOnlyChanged, false);
    });

    test('free gift qatoriga tegilmaydi (narxi 0 qoladi)', () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 21600, value: 1, saleType: 2, boxValue: 12, boxQuantity: 1);
      final gift = makeRow(price: 0, value: 1, isFreeGift: true);
      p.getCurrentClient.orderedProducts.addAll([blok, gift]);

      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(editedCopy(blok, 18000));

      final giftRow = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.isFreeGift);
      expect(giftRow.price, 0);
    });

    test('2 blok + dona: hammasi bitta dona narxiga tushadi', () async {
      final p = freshProvider();
      final blok1 = makeRow(
          price: 21600, value: 1, saleType: 2, boxValue: 12, boxQuantity: 2);
      final blok2 = makeRow(
          price: 21600, value: 1, saleType: 2, boxValue: 12, boxQuantity: 2);
      final dona = makeRow(price: 1800, value: 1);
      p.getCurrentClient.orderedProducts.addAll([blok1, blok2, dona]);

      p.tapIndexToEdit(2);
      await p.pressDialogSaveButton(editedCopy(dona, 1500));

      final rows = p.getCurrentClient.orderedProducts;
      for (final e in rows.where((e) => e.saleType == 2)) {
        expect(e.price, 18000); // 1500 × 12
      }
    });
  });
}
