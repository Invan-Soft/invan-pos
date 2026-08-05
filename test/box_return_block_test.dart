// Blok vozvrat oqimi testi: UI blok hisobida ishlaydi, data esa dona (value)
// hisobida qoladi. ReturnPageProviderr ko'chirish logikasi va funcToRefund
// (refund_order_items body) jamlash tekshiriladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/providers/return_page_provider.dart';
import 'package:invan2/changes/services/receipt_api_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';

import 'support/provider_harness.dart';

ReceiptModelSoldItem4 makeRow({
  String productId = 'pepsi-id',
  String name = 'Pepsi 1.5L',
  double price = 2000,
  double value = 12,
  int saleType = 1,
  int boxValue = 0,
  int boxQuantity = 0,
  String refundItemId = 'item-1',
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
    refundItemId: refundItemId,
    saleType: saleType,
    boxValue: boxValue,
    boxQuantity: boxQuantity,
  );
}

ReceiptModel4 makeReceipt(List<ReceiptModelSoldItem4> items) {
  final r = ReceiptModel4(
    createdDate: '2026-07-16 10:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'ext-1',
    orderType: 'sale',
    shopId: 'shop-1',
    userId: 'user-1',
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: 'kassir-001',
    cashierName: 'Test Kassir',
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: true,
    totalPrice: 0,
    uploaded: false,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: 'ext-1',
    posName: 'Test POS',
    isDonate: false,
  );
  r.soldItemList.addAll(items);
  return r;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => setUpPosTestEnv('box_return_test'));
  tearDownAll(tearDownPosTestEnv);

  group('ReturnPageProviderr — blok qatori ko\'chirish', () {
    test('1 blok (12 dona) butunlay o\'ngga o\'tadi', () {
      final block =
          makeRow(value: 12, saleType: 2, boxValue: 12, boxQuantity: 1);
      final p = ReturnPageProviderr(receiptModel4: makeReceipt([block]));

      p.pressLeftIndex(0);
      p.pressLeftProduct();

      expect(p.getLeftList, isEmpty);
      expect(p.getRightList.length, 1);
      expect(p.getRightList.first.value, 12); // data dona hisobida
      expect(p.getRightList.first.saleType, 2);
      expect(p.getRightTotalPrice, 24000);
    });

    test('2 blokdan 1 blok qaytarish — dialog 1 blok = 12 dona yuboradi', () {
      final block =
          makeRow(value: 24, saleType: 2, boxValue: 12, boxQuantity: 2);
      final p = ReturnPageProviderr(receiptModel4: makeReceipt([block]));

      p.pressLeftIndex(0);
      p.pressLeftProductDialog2(1 * 12); // UI: 1 blok -> 12 dona

      expect(p.getLeftList.first.value, 12);
      expect(p.getLeftList.first.boxQuantity, 1);
      expect(p.getRightList.first.value, 12);
      expect(p.getRightList.first.saleType, 2);
      expect(p.getRightList.first.boxValue, 12);
      expect(p.getRightList.first.boxQuantity, 1);
    });

    test('blok qatori dona qatoriga qo\'shilib ketmaydi (aralash qoldiq)', () {
      final block =
          makeRow(value: 12, saleType: 2, boxValue: 12, boxQuantity: 1);
      final loose = makeRow(value: 4);
      final p = ReturnPageProviderr(receiptModel4: makeReceipt([block, loose]));

      // Blokni o'tkazamiz
      p.pressLeftIndex(0);
      p.pressLeftProduct();
      // Dona qatoridan 2 tasini o'tkazamiz
      p.pressLeftIndex(0);
      p.pressLeftProductDialog2(2);

      expect(p.getRightList.length, 2); // blok va dona alohida qator
      final blockRow = p.getRightList.firstWhere((e) => e.saleType == 2);
      final looseRow = p.getRightList.firstWhere((e) => e.saleType != 2);
      expect(blockRow.value, 12);
      expect(looseRow.value, 2);
      expect(p.getRightTotalPrice, 24000 + 4000);
    });

    test('bo\'lingan blok qaytib kelib blok qatoriga qo\'shiladi', () {
      final block =
          makeRow(value: 24, saleType: 2, boxValue: 12, boxQuantity: 2);
      final p = ReturnPageProviderr(receiptModel4: makeReceipt([block]));

      p.pressLeftIndex(0);
      p.pressLeftProductDialog2(12); // 1 blok o'ngga
      p.pressRightIndex(0);
      p.pressRightProductDialog2(12); // 1 blok chapga qaytadi

      expect(p.getRightList, isEmpty);
      expect(p.getLeftList.length, 1);
      expect(p.getLeftList.first.value, 24);
      expect(p.getLeftList.first.boxQuantity, 2);
    });
  });

  group('funcToRefund — refund_order_items body (dona semantika)', () {
    // Backend sotuvni dona hisobida yuritadi (3 blok = "36 ta sotildi"),
    // shuning uchun vozvrat quantity ham DONA: 1 blok(12 dona) -> quantity=12.
    test('1 blok (12 dona) -> quantity=12, price=dona narxi', () {
      final r = makeReceipt(
          [makeRow(value: 12, saleType: 2, boxValue: 12, boxQuantity: 1)]);
      r.payment.add(
          ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: 24000));

      final body = ReceiptApi4.funcToRefund(r);

      final items = body['items'] as List;
      expect(items.length, 1);
      expect(items.first['quantity'], 12);
      expect(items.first['price'], 2000);
      expect(items.first['id'], 'item-1');
    });

    test('2 blok (24 dona) -> quantity=24', () {
      final r = makeReceipt(
          [makeRow(value: 24, saleType: 2, boxValue: 12, boxQuantity: 2)]);
      r.payment.add(
          ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: 48000));

      final body = ReceiptApi4.funcToRefund(r);

      final items = body['items'] as List;
      expect(items.first['quantity'], 24);
    });

    test('blok + dona qatorlari bitta itemga jamlanadi (12+4=16)', () {
      final r = makeReceipt([
        makeRow(value: 12, saleType: 2, boxValue: 12, boxQuantity: 1),
        makeRow(value: 4),
      ]);
      r.payment.add(
          ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: 32000));

      final body = ReceiptApi4.funcToRefund(r);

      final items = body['items'] as List;
      expect(items.length, 1); // bir xil refundItemId -> bitta yozuv
      expect(items.first['quantity'], 16);
      expect(items.first['id'], 'item-1');
    });

    test('oddiy (blok bo\'lmagan) item avvalgidek dona hisobida', () {
      final r = makeReceipt([makeRow(value: 3)]);
      r.payment.add(
          ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: 6000));

      final body = ReceiptApi4.funcToRefund(r);

      final items = body['items'] as List;
      expect(items.first['quantity'], 3);
    });
  });

  group('consolidateSoldItems — blok semantikasi', () {
    // SOTUV savati: har blok qatori value=1 (token), price=blok narxi.
    // Konsolidatsiya ularni dona hisobiga o'tkazadi. Bu FAQAT sotuv chekiga
    // qo'llanadi — vozvrat cheki qatorlari allaqachon dona hisobida bo'lgani
    // uchun toOBJECTBOX vozvratda konsolidatsiya QILMAYDI (aks holda 12 dona
    // "12 blok"=144 bo'lib buzilardi — DH120 bugi).
    test('savat: 3 blok qatori (value=1, price=21600) -> 36 dona × 1800', () {
      final r = makeReceipt(List.generate(
        3,
        (i) => makeRow(
          value: 1,
          price: 21600,
          saleType: 2,
          boxValue: 12,
          boxQuantity: 3,
        ),
      ));

      final out = ReceiptSingleton4.consolidateSoldItems(r);

      expect(out.soldItemList.length, 1);
      final item = out.soldItemList.first;
      expect(item.value, 36); // fizik dona
      expect(item.price, 1800); // dona narxi
      expect(item.saleType, 2);
      expect(item.boxValue, 12);
      expect(item.boxQuantity, 3);
    });

    test('vozvrat qatori (value=12 dona) konsolidatsiyadan o\'tsa buziladi — '
        'shuning uchun refundda chaqirilmaydi', () {
      final r = makeReceipt(
          [makeRow(value: 12, saleType: 2, boxValue: 12, boxQuantity: 1)]);

      final out = ReceiptSingleton4.consolidateSoldItems(r);

      // Hujjatlashtirilgan buzilish shakli: dona value blok soni deb olinadi
      expect(out.soldItemList.first.value, 144);
      // toOBJECTBOX endi isRefund chekda consolidateSoldItems'ni chaqirmaydi —
      // bu test kelajakda semantika o'zgarsa ogohlantirish uchun turibdi.
    });
  });
}
