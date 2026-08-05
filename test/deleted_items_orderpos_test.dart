// O'chirilgan mahsulotlar -> order_pos "deleted_items" oqimi testi.
// Real provider metodlari (pressDialogDeleteButton, pressDialogSaveButton,
// removeLastAdded, mark-guruh) va serverga ketadigan JSON tekshiriladi.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/services/receipt_api_4.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

ReceiptModelSoldItem4 makeRow({
  String productId = 'pepsi-id',
  String name = 'Pepsi 1.5L',
  double price = 5000,
  double value = 3,
  bool marking = false,
  String? mark,
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
    marking: marking,
    mark: mark,
  );
}

ReceiptModel4 makeReceipt() {
  return ReceiptModel4(
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
    cashierId: kCashierId,
    cashierName: 'Test Kassir',
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: false,
    totalPrice: 10000,
    uploaded: false,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: '',
    posName: 'Test POS',
    isDonate: false,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('deleted_items_test'));
  tearDownAll(tearDownPosTestEnv);

  group("1. OPD dialog orqali to'liq o'chirish", () {
    test("3 ta pepsi qatorini o'chirish -> qty 3, total 15000", () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));

      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.orderedProducts, isEmpty);
      expect(p.getCurrentClient.deletedItems.length, 1);
      final d = p.getCurrentClient.deletedItems.first;
      expect(d.productId, 'pepsi-id');
      expect(d.quantity, 3);
      expect(d.totalPrice, 15000);
      expect(d.deletedBy, kCashierId);
      expect(d.deletedTime, isNotEmpty);
    });

    test("3 qatordan bittasini o'chirish -> qolganlar joyida", () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'cola', name: 'Cola', price: 7000, value: 1))
        ..add(makeRow(price: 5000, value: 2))
        ..add(makeRow(productId: 'fanta', name: 'Fanta', price: 6000, value: 4));

      p.tapIndexToEdit(1); // pepsi
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.orderedProducts.length, 2);
      expect(p.getCurrentClient.deletedItems.length, 1);
      expect(p.getCurrentClient.deletedItems.first.productId, 'pepsi-id');
      expect(p.getCurrentClient.deletedItems.first.totalPrice, 10000);
    });
  });

  group('2. Qty kamaytirish (OPD Save)', () {
    test('3 -> 2: farq 1 dona deleted bo\'ladi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));

      p.tapIndexToEdit(0);
      final edited = makeRow(price: 5000, value: 2);
      await p.pressDialogSaveButton(edited);

      expect(p.getCurrentClient.orderedProducts.single.value, 2);
      expect(p.getCurrentClient.deletedItems.length, 1);
      final d = p.getCurrentClient.deletedItems.first;
      expect(d.quantity, 1);
      expect(d.totalPrice, 5000);
    });

    test('5 -> 1: farq 4 dona, total 20000', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 5));

      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeRow(price: 5000, value: 1));

      final d = p.getCurrentClient.deletedItems.single;
      expect(d.quantity, 4);
      expect(d.totalPrice, 20000);
    });

    test('qty oshirish 2 -> 5: hech narsa yozilmaydi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 2));

      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeRow(price: 5000, value: 5));

      expect(p.getCurrentClient.deletedItems, isEmpty);
    });

    test('qty o\'zgarmasa (faqat narx): yozilmaydi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));

      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeRow(price: 4500, value: 3));

      expect(p.getCurrentClient.deletedItems, isEmpty);
    });

    test('OPD Save value=0: to\'liq o\'chirish sifatida yoziladi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));

      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeRow(price: 5000, value: 0));
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.orderedProducts, isEmpty);
      final d = p.getCurrentClient.deletedItems.single;
      expect(d.quantity, 3);
      expect(d.totalPrice, 15000);
    });

    test('kasr qty (tarozi) 1.5 -> 0.5: farq 1.0', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 20000, value: 1.5));

      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeRow(price: 20000, value: 0.5));

      final d = p.getCurrentClient.deletedItems.single;
      expect(d.quantity, 1.0);
      expect(d.totalPrice, 20000);
    });
  });

  group('3. removeLastAdded (X tugma)', () {
    test('oxirgi qo\'shilgan qator o\'chadi va yoziladi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'fanta', name: 'Fanta', price: 6000, value: 2))
        ..add(makeRow(price: 5000, value: 1));
      p.getCurrentClient.lastAddedIndex = 0; // eng yangi qator indeksi

      p.removeLastAdded();

      expect(p.getCurrentClient.orderedProducts.length, 1);
      expect(p.getCurrentClient.deletedItems.length, 1);
      expect(p.getCurrentClient.deletedItems.first.productId, 'fanta');
      expect(p.getCurrentClient.deletedItems.first.totalPrice, 12000);
    });
  });

  group('4. Markirovka guruhi', () {
    test('guruh qty 3 -> 1: 2 ta mark qatori yoziladi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M1'))
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M2'))
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M3'));

      p.beginMarkGroupEdit('pepsi-id');
      await p.pressDialogSaveButton(makeRow(price: 5000, value: 1));
      p.endMarkGroupEdit();

      expect(
        p.getCurrentClient.orderedProducts
            .where((e) => !(e.isDeleted ?? false))
            .length,
        1,
      );
      expect(p.getCurrentClient.deletedItems.length, 2);
      expect(
        p.getCurrentClient.deletedItems.every(
          (d) => d.quantity == 1 && d.totalPrice == 5000,
        ),
        isTrue,
      );
    });

    test('guruhni butunlay o\'chirish: barcha marklar yoziladi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M1'))
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M2'));

      p.beginMarkGroupEdit('pepsi-id');
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.deletedItems.length, 2);
    });
  });

  group('5. Yig\'ilish va serverga ketadigan JSON', () {
    test('bir sessiyada bir nechta delete yig\'iladi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'cola', name: 'Cola', price: 7000, value: 2))
        ..add(makeRow(price: 5000, value: 3));

      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      p.tapIndexToEdit(0); // endi pepsi 0-indeksda
      await p.pressDialogSaveButton(makeRow(price: 5000, value: 1));

      expect(p.getCurrentClient.deletedItems.length, 2);
      expect(p.getCurrentClient.deletedItems[0].productId, 'cola');
      expect(p.getCurrentClient.deletedItems[1].quantity, 2);
    });

    test('chekka biriktirish -> toJson -> deleted_items massivi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeRow(price: 5000, value: 2));

      // pressPaymentButton dagi biriktirish bilan bir xil kod:
      final receipt = makeReceipt();
      receipt.soldItemList.add(makeRow(price: 5000, value: 2));
      receipt.deletedItemsJson = jsonEncode(
        p.getCurrentClient.deletedItems.map((e) => e.toJson()).toList(),
      );

      final body = receipt.toJson();
      final deletedItems = body['deleted_items'] as List;
      expect(deletedItems.length, 1);
      expect(deletedItems.first['product_id'], 'pepsi-id');
      expect(deletedItems.first['quantity'], 1);
      expect(deletedItems.first['total_price'], 5000);
      expect(deletedItems.first['deleted_by'], kCashierId);
      expect(deletedItems.first['deleted_time'], isNotEmpty);

      // order_pos body'siga jsonEncode qilinishi xatosiz o'tishi kerak
      final encoded = jsonEncode({'order': [body]});
      expect(encoded, contains('"deleted_items"'));
    });

    test('ReceiptApi4.func (upload nusxasi) deleted_items ni saqlaydi', () {
      final receipt = makeReceipt();
      receipt.deletedItemsJson = jsonEncode([
        {
          'deleted_by': kCashierId,
          'deleted_time': '2026-07-16 10:05:00',
          'product_id': 'pepsi-id',
          'quantity': 1,
          'total_price': 5000,
        }
      ]);

      final serverCopy = ReceiptApi4.func(receipt, isServer: true);
      final body = serverCopy.toJson();
      expect((body['deleted_items'] as List).length, 1);
    });

    test('delete bo\'lmagan sotuv: deleted_items = []', () {
      final receipt = makeReceipt();
      final body = receipt.toJson();
      expect(body['deleted_items'], isEmpty);
    });

    test('eski (update\'dan avvalgi) chek: bo\'sh string ham buzilmaydi', () {
      final receipt = makeReceipt();
      receipt.deletedItemsJson = ''; // eski ObjectBox yozuvi default
      expect(receipt.toJson()['deleted_items'], isEmpty);

      final serverCopy = ReceiptApi4.func(receipt, isServer: true);
      expect(serverCopy.toJson()['deleted_items'], isEmpty);
    });

    test('OFFLINE BATCH: 10 chek, har xil delete case, bitta upload', () async {
      // Har bir chek alohida sotuv sessiyasi: real provider metodlari bilan
      // delete qilinadi, keyin pressPaymentButton'dagi kod bilan chekka
      // biriktiriladi (offline ObjectBox saqlanishini imitatsiya qiladi).
      final receipts = <ReceiptModel4>[];

      Future<ReceiptModel4> finishSale(OrderingProvider4 p, int n) async {
        final receipt = makeReceipt();
        receipt.orderId = 'order-$n';
        receipt.externalId = 'ext-$n';
        receipt.payment.add(ReceiptModelPaymentType4(
            name: 'Наличные', payId: 'cash-pay-id', value: 1000));
        receipt.soldItemList.addAll(
          p.getCurrentClient.orderedProducts
              .where((e) => !(e.isDeleted ?? false)),
        );
        receipt.deletedItemsJson = jsonEncode(
          p.getCurrentClient.deletedItems.map((e) => e.toJson()).toList(),
        );
        p.getCurrentClient.deletedItems.clear();
        return receipt;
      }

      // 1-chek: 1 dona o'chirish
      var p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'p1', price: 5000, value: 1))
        ..add(makeRow(productId: 'keep', price: 3000, value: 2));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 30));
      receipts.add(await finishSale(p, 1));

      // 2-chek: 50 talik qatorni to'liq o'chirish
      p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'p2', price: 1000, value: 50))
        ..add(makeRow(productId: 'keep', price: 3000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 30));
      receipts.add(await finishSale(p, 2));

      // 3-chek: 50 -> 35 kamaytirish (15 ta o'chdi)
      p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'p3', price: 2000, value: 50));
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(
          makeRow(productId: 'p3', price: 2000, value: 35));
      receipts.add(await finishSale(p, 3));

      // 4-chek: ikki xil productni o'chirish
      p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'p4a', price: 4000, value: 2))
        ..add(makeRow(productId: 'p4b', price: 6000, value: 3))
        ..add(makeRow(productId: 'keep', price: 3000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 30));
      p.tapIndexToEdit(0); // endi p4b 0-indeksda
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 30));
      receipts.add(await finishSale(p, 4));

      // 5-chek: tarozi 2.5 kg -> 1.0 kg (1.5 kg o'chdi)
      p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'p5', price: 20000, value: 2.5));
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(
          makeRow(productId: 'p5', price: 20000, value: 1.0));
      receipts.add(await finishSale(p, 5));

      // 6-chek: delete YO'Q
      p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'p6', price: 8000, value: 2));
      receipts.add(await finishSale(p, 6));

      // 7-chek: OPD Save value=0 orqali delete
      p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'p7', price: 12000, value: 4))
        ..add(makeRow(productId: 'keep', price: 3000, value: 1));
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(
          makeRow(productId: 'p7', price: 12000, value: 0));
      await Future.delayed(const Duration(milliseconds: 30));
      receipts.add(await finishSale(p, 7));

      // 8-chek: X tugma (removeLastAdded)
      p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'p8', price: 2500, value: 6))
        ..add(makeRow(productId: 'keep', price: 3000, value: 1));
      p.getCurrentClient.lastAddedIndex = 0;
      p.removeLastAdded();
      receipts.add(await finishSale(p, 8));

      // 9-chek: mark-guruh 3 -> 1 (2 ta mark o'chdi)
      p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'p9', price: 5000, value: 1, marking: true, mark: 'A1'))
        ..add(makeRow(productId: 'p9', price: 5000, value: 1, marking: true, mark: 'A2'))
        ..add(makeRow(productId: 'p9', price: 5000, value: 1, marking: true, mark: 'A3'));
      p.beginMarkGroupEdit('p9');
      await p.pressDialogSaveButton(
          makeRow(productId: 'p9', price: 5000, value: 1));
      p.endMarkGroupEdit();
      receipts.add(await finishSale(p, 9));

      // 10-chek: katta aralash — 100 -> 40 (60 o'chdi) + 15 talik to'liq delete
      p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'p10a', price: 500, value: 100))
        ..add(makeRow(productId: 'p10b', price: 9000, value: 15));
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(
          makeRow(productId: 'p10a', price: 500, value: 40));
      p.tapIndexToEdit(1);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 30));
      receipts.add(await finishSale(p, 10));

      // ---- OFFLINE FLUSH: real upload body quruvchisi orqali ----
      // HTTP test muhitida bloklangan (offline holat!) — lekin body
      // postdan OLDIN Pref("bodyForDiscountError") ga yoziladi.
      try {
        await ReceiptApi4.receiptCreateGroup(receipts);
      } catch (_) {
        // tarmoq/log xatolari muhim emas — body allaqachon qurilgan
      }

      final rawBody = Pref.getString('bodyForDiscountError', '');
      expect(rawBody, isNotEmpty);
      final body = jsonDecode(rawBody) as Map<String, dynamic>;
      final orders = body['order'] as List;
      expect(orders.length, 10);

      List deletedOf(String extId) => (orders
              .firstWhere((o) => o['external_id'] == extId)['deleted_items']
          as List);

      // 1: 1 dona, 5000
      var d = deletedOf('ext-1');
      expect(d.single['quantity'], 1);
      expect(d.single['total_price'], 5000);
      expect(d.single['product_id'], 'p1');

      // 2: 50 ta, 50000
      d = deletedOf('ext-2');
      expect(d.single['quantity'], 50);
      expect(d.single['total_price'], 50000);

      // 3: 15 ta, 30000
      d = deletedOf('ext-3');
      expect(d.single['quantity'], 15);
      expect(d.single['total_price'], 30000);

      // 4: 2 ta yozuv (p4a 2x4000=8000, p4b 3x6000=18000)
      d = deletedOf('ext-4');
      expect(d.length, 2);
      expect(d.map((e) => e['total_price']).toList()..sort(),
          [8000, 18000]);

      // 5: kasr 1.5 kg, 30000
      d = deletedOf('ext-5');
      expect(d.single['quantity'], 1.5);
      expect(d.single['total_price'], 30000);

      // 6: bo'sh
      expect(deletedOf('ext-6'), isEmpty);

      // 7: value=0 -> 4 ta, 48000
      d = deletedOf('ext-7');
      expect(d.single['quantity'], 4);
      expect(d.single['total_price'], 48000);

      // 8: X tugma -> 6 ta, 15000
      d = deletedOf('ext-8');
      expect(d.single['quantity'], 6);
      expect(d.single['total_price'], 15000);

      // 9: 2 ta mark (har biri qty 1, 5000)
      d = deletedOf('ext-9');
      expect(d.length, 2);
      expect(d.every((e) => e['quantity'] == 1 && e['total_price'] == 5000),
          isTrue);

      // 10: 60 ta (30000) + 15 ta (135000)
      d = deletedOf('ext-10');
      expect(d.length, 2);
      expect(d.map((e) => e['quantity']).toList()..sort(), [15, 60]);
      expect(d.map((e) => e['total_price']).toList()..sort(),
          [30000, 135000]);

      // Har bir yozuvda kassir va vaqt bor, cheklar aro aralashish yo'q
      for (final o in orders) {
        for (final di in (o['deleted_items'] as List)) {
          expect(di['deleted_by'], kCashierId);
          expect(di['deleted_time'], isNotEmpty);
        }
      }
    });

    test('sotuvdan keyin tozalash: keyingi sotuvga o\'tmaydi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(p.getCurrentClient.deletedItems, isNotEmpty);

      // pressPaymentButton muvaffaqiyatli saqlagandan keyingi qadam:
      p.getCurrentClient.deletedItems.clear();

      final receipt = makeReceipt();
      receipt.deletedItemsJson = jsonEncode(
        p.getCurrentClient.deletedItems.map((e) => e.toJson()).toList(),
      );
      expect(receipt.toJson()['deleted_items'], isEmpty);
    });
  });

  group('6. added_time va check_number (sotuvsiz orphan)', () {
    test('added_time yoziladi (mahsulot qo\'shilgan vaqt)', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.deletedItems.single.addedTime, isNotEmpty);
    });

    test('savat bo\'shamaydi (boshqa aktiv qoladi): check_number bo\'sh -> toJson externalId qo\'yadi',
        () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'cola', name: 'Cola', price: 7000, value: 1))
        ..add(makeRow(price: 5000, value: 2)); // pepsi index 1
      p.tapIndexToEdit(1); // pepsi o'chadi, cola aktiv qoladi
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      // Savat bo'shamadi -> orphan EMAS -> checkNumber bo'sh
      expect(p.getCurrentClient.orderedProducts.length, 1);
      expect(p.getCurrentClient.deletedItems.single.checkNumber, '');

      final receipt = makeReceipt(); // externalId 'ext-1'
      receipt.deletedItemsJson = jsonEncode(
        p.getCurrentClient.deletedItems.map((e) => e.toJson()).toList(),
      );
      final di = receipt.toJson()['deleted_items'] as List;
      expect(di.first['check_number'], 'ext-1'); // injection
      expect(di.first['added_time'], isNotEmpty);
    });

    test('savat SOTUVSIZ bo\'shadi: check_number "-" bo\'ladi va toJson uni saqlaydi',
        () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton(); // savat bo'shadi -> orphan
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.orderedProducts, isEmpty);
      expect(p.getCurrentClient.deletedItems.single.checkNumber, '-');

      final receipt = makeReceipt(); // externalId 'ext-1'
      receipt.deletedItemsJson = jsonEncode(
        p.getCurrentClient.deletedItems.map((e) => e.toJson()).toList(),
      );
      final di = receipt.toJson()['deleted_items'] as List;
      // "-" saqlanadi, externalId qo'yilmaydi
      expect(di.first['check_number'], '-');
    });

    test('foydalanuvchi senariysi: A(orphan "-") + keyingi run C(real chek)',
        () async {
      final p = freshProvider();
      // Run 1: A qo'shildi, o'chirildi -> savat bo'sh -> orphan
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'aaa', name: 'A', price: 5000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      // Run 2: B, C qo'shildi; C o'chirildi (B aktiv qoladi -> orphan EMAS); sotildi
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'bbb', name: 'B', price: 6000, value: 1))
        ..add(makeRow(productId: 'ccc', name: 'C', price: 7000, value: 1));
      p.tapIndexToEdit(1); // ccc o'chadi, bbb qoladi
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      final items = p.getCurrentClient.deletedItems;
      expect(items.length, 2);
      expect(items.firstWhere((d) => d.productId == 'aaa').checkNumber, '-');
      expect(items.firstWhere((d) => d.productId == 'ccc').checkNumber, '');

      final receipt = makeReceipt(); // externalId 'ext-1'
      receipt.deletedItemsJson =
          jsonEncode(items.map((e) => e.toJson()).toList());
      final di = (receipt.toJson()['deleted_items'] as List).cast<Map>();
      expect(
          di.firstWhere((m) => m['product_id'] == 'aaa')['check_number'], '-');
      expect(di.firstWhere((m) => m['product_id'] == 'ccc')['check_number'],
          'ext-1');
    });

    test('butun savat scrap qilindi: ikkala o\'chirish ham "-" bo\'ladi',
        () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'aaa', name: 'A', price: 5000, value: 1))
        ..add(makeRow(productId: 'bbb', name: 'B', price: 6000, value: 1));

      // A o'chadi (B aktiv qoladi -> hali orphan emas)
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(p.getCurrentClient.deletedItems.firstWhere((d) => d.productId == 'aaa').checkNumber, '');

      // B o'chadi (savat bo'shadi -> ikkalasi ham orphan)
      p.tapIndexToEdit(0); // bbb endi 0-indeksda
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.orderedProducts, isEmpty);
      for (final d in p.getCurrentClient.deletedItems) {
        expect(d.checkNumber, '-');
      }
    });

    test('removeLastAdded (X) bilan savat bo\'shasa ham "-" bo\'ladi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 1));
      p.getCurrentClient.lastAddedIndex = 0;

      p.removeLastAdded();

      expect(p.getCurrentClient.orderedProducts, isEmpty);
      expect(p.getCurrentClient.deletedItems.single.checkNumber, '-');
    });
  });

  group('7. Qo\'shimcha chetki holatlar (orphan)', () {
    test('red-delete rejimi: savat bo\'shasa "-" (item isDeleted=true qoladi)',
        () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      addTearDown(() => Pref.setBool(PrefKeys.isRedDeleteActivated, false));

      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      // red-delete: qator listda qoladi (isDeleted=true), aktiv yo'q -> orphan
      expect(p.getCurrentClient.orderedProducts.length, 1);
      expect(p.getCurrentClient.orderedProducts.single.isDeleted, true);
      expect(p.getCurrentClient.deletedItems.single.checkNumber, '-');
    });

    test('markirovka guruhini butunlay o\'chirish (savat bo\'sh): hammasi "-"',
        () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M1'))
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M2'));

      p.beginMarkGroupEdit('pepsi-id');
      p.pressDialogDeleteButton(); // -> _deleteMarkGroup, savat bo'shadi
      p.endMarkGroupEdit();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.deletedItems.length, 2);
      for (final d in p.getCurrentClient.deletedItems) {
        expect(d.checkNumber, '-');
      }
    });

    test('blok guruhini butunlay o\'chirish (savat bo\'sh): hammasi "-"',
        () async {
      final p = freshProvider();
      final b1 = makeRow(productId: 'box-id', price: 5000, value: 12)
        ..saleType = 2;
      final b2 = makeRow(productId: 'box-id', price: 5000, value: 12)
        ..saleType = 2;
      p.getCurrentClient.orderedProducts
        ..add(b1)
        ..add(b2);

      p.beginBoxGroupEdit('box-id');
      p.pressDialogDeleteButton(); // -> _deleteBoxGroup, savat bo'shadi
      p.endBoxGroupEdit();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        p.getCurrentClient.orderedProducts
            .where((e) => !(e.isDeleted ?? false)),
        isEmpty,
      );
      expect(p.getCurrentClient.deletedItems.length, 2);
      for (final d in p.getCurrentClient.deletedItems) {
        expect(d.checkNumber, '-');
      }
    });

    test('ketma-ket 2 orphan run + sotuv: A"-", B"-", D real chek', () async {
      final p = freshProvider();
      // Run 1: A -> o'chirildi -> savat bo'sh -> "-"
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'a', name: 'A', price: 1000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      // Run 2: B -> o'chirildi -> savat bo'sh -> "-"
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'b', name: 'B', price: 2000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      // Run 3: C (sotiladi), D o'chiriladi (C aktiv -> D orphan emas)
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'c', name: 'C', price: 3000, value: 1))
        ..add(makeRow(productId: 'd', name: 'D', price: 4000, value: 1));
      p.tapIndexToEdit(1); // d o'chadi
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      final items = p.getCurrentClient.deletedItems;
      expect(items.firstWhere((x) => x.productId == 'a').checkNumber, '-');
      expect(items.firstWhere((x) => x.productId == 'b').checkNumber, '-');
      expect(items.firstWhere((x) => x.productId == 'd').checkNumber, '');

      final receipt = makeReceipt(); // externalId 'ext-1'
      receipt.deletedItemsJson =
          jsonEncode(items.map((e) => e.toJson()).toList());
      final di = (receipt.toJson()['deleted_items'] as List).cast<Map>();
      expect(di.firstWhere((m) => m['product_id'] == 'a')['check_number'], '-');
      expect(di.firstWhere((m) => m['product_id'] == 'b')['check_number'], '-');
      expect(di.firstWhere((m) => m['product_id'] == 'd')['check_number'],
          'ext-1');
    });

    test('qty-kamaytirish (yagona item 3->2): orphan EMAS, item qoladi',
        () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeRow(price: 5000, value: 2));

      expect(p.getCurrentClient.orderedProducts.single.value, 2);
      expect(p.getCurrentClient.deletedItems.single.checkNumber, '');
    });

    test('added_time = createdTime (UTC formatida)', () async {
      final p = freshProvider();
      final ts = DateTime(2026, 7, 31, 15, 7, 20).millisecondsSinceEpoch;
      final row = makeRow(price: 5000, value: 1)..createdTime = ts;
      p.getCurrentClient.orderedProducts.add(row);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      final expected = DateFormat('yyyy-MM-dd HH:mm:ss')
          .format(DateTime.fromMillisecondsSinceEpoch(ts).toUtc());
      expect(p.getCurrentClient.deletedItems.single.addedTime, expected);
    });

    test('offline func: "-" saqlanadi, bo\'sh esa externalId bilan to\'ldiriladi',
        () {
      final receipt = makeReceipt(); // externalId 'ext-1'
      receipt.deletedItemsJson = jsonEncode([
        {
          'deleted_by': kCashierId,
          'deleted_time': '2026-07-31 10:00:00',
          'added_time': '2026-07-31 09:59:00',
          'check_number': '-',
          'product_id': 'x',
          'quantity': 1,
          'total_price': 1000,
        },
        {
          'deleted_by': kCashierId,
          'deleted_time': '2026-07-31 10:01:00',
          'added_time': '2026-07-31 10:00:30',
          'check_number': '',
          'product_id': 'y',
          'quantity': 1,
          'total_price': 2000,
        },
      ]);

      final serverCopy = ReceiptApi4.func(receipt, isServer: true);
      final di = (serverCopy.toJson()['deleted_items'] as List).cast<Map>();
      expect(di.firstWhere((m) => m['product_id'] == 'x')['check_number'], '-');
      expect(di.firstWhere((m) => m['product_id'] == 'y')['check_number'],
          'ext-1');
    });

    test('ko\'p-mijoz: bir mijoz orphani boshqasiga o\'tmaydi', () async {
      final p = freshProvider();
      // Mijoz 1: X (aktiv qoladi -> mijoz saqlanadi)
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'x', name: 'X', price: 5000, value: 1));
      // Mijoz 2 yaratiladi va unga o'tiladi
      p.addClient();
      // Mijoz 2: Y, Z qo'shildi; Y o'chirildi (Z aktiv -> Y orphan emas, mijoz saqlanadi)
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'y', name: 'Y', price: 6000, value: 1))
        ..add(makeRow(productId: 'z', name: 'Z', price: 7000, value: 1));
      p.tapIndexToEdit(0); // y o'chadi
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.deletedItems.single.productId, 'y');

      // Mijoz 1 ga qaytamiz
      p.selectClient(0);
      expect(p.getCurrentClient.orderedProducts.single.productId, 'x');
      expect(p.getCurrentClient.deletedItems, isEmpty); // izolyatsiya
      expect(p.getOrphanDeletedItems, isEmpty); // hech narsa "yetim" qolmadi
    });
  });

  group('8. Slot o\'chirilganda yozuvlar saqlanadi', () {
    test('bo\'shagan mijoz sloti tashlab ketilsa yozuv YO\'QOLMAYDI', () async {
      final p = freshProvider();
      // Mijoz 1: X aktiv qoladi
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'x', name: 'X', price: 5000, value: 1));
      // Mijoz 2: Y qo'shildi va o'chirildi -> savat BO'SHADI -> "-"
      p.addClient();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'y', name: 'Y', price: 6000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(p.getCurrentClient.deletedItems.single.checkNumber, '-');
      expect(p.getSixClient4List.length, 2);

      // Mijoz 1 ga qaytamiz -> bo'sh slot ro'yxatdan chiqadi
      p.selectClient(0);

      expect(p.getSixClient4List.length, 1);
      expect(p.getOrphanDeletedItems.length, 1);
      expect(p.getOrphanDeletedItems.single.productId, 'y');
      expect(p.getOrphanDeletedItems.single.checkNumber, '-');
    });

    test('saqlangan yozuv keyingi chek bilan "-" holida ketadi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'x', name: 'X', price: 5000, value: 1));
      p.addClient();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'y', name: 'Y', price: 6000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      p.selectClient(0);

      // Mijoz 1 da ham bitta o'chirish (aktiv qator qoladi -> chek raqami oladi)
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'z', name: 'Z', price: 7000, value: 1));
      p.tapIndexToEdit(1); // z o'chadi, x aktiv qoladi
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      // To'lovdagi biriktirish: orphan + joriy slot
      final receipt = makeReceipt(); // externalId 'ext-1'
      receipt.deletedItemsJson = jsonEncode([
        ...p.getOrphanDeletedItems,
        ...p.getCurrentClient.deletedItems,
      ].map((e) => e.toJson()).toList());

      final di = (receipt.toJson()['deleted_items'] as List).cast<Map>();
      expect(di.length, 2);
      expect(di.firstWhere((m) => m['product_id'] == 'y')['check_number'], '-');
      expect(di.firstWhere((m) => m['product_id'] == 'z')['check_number'],
          'ext-1');
    });

    test('cancelOrdering bilan bo\'shatilgan slot: yozuv "-" bo\'lib saqlanadi',
        () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'x', name: 'X', price: 5000, value: 1));
      p.addClient();
      // Mijoz 2: Y va Z; Y o'chirildi (Z aktiv -> hali chek raqami yo'q, "")
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'y', name: 'Y', price: 6000, value: 1))
        ..add(makeRow(productId: 'z', name: 'Z', price: 7000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(p.getCurrentClient.deletedItems.single.checkNumber, '');

      // Savat butunlay bekor qilindi (orphan hook yo'q yo'l)
      p.cancelOrdering(true);
      p.selectClient(0);

      // Slot yo'q qilindi, lekin yozuv saqlandi va "-" bo'ldi —
      // ya'ni keyingi chekning raqamini o'zlashtirib olmaydi
      expect(p.getOrphanDeletedItems.single.productId, 'y');
      expect(p.getOrphanDeletedItems.single.checkNumber, '-');
    });

    test('aktiv mahsulotli slot o\'chirilmaydi -> orphan ro\'yxat bo\'sh',
        () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'x', name: 'X', price: 5000, value: 1));
      p.addClient();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'y', name: 'Y', price: 6000, value: 1))
        ..add(makeRow(productId: 'z', name: 'Z', price: 7000, value: 1));
      p.tapIndexToEdit(0); // y o'chadi, z aktiv qoladi
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      p.selectClient(0);

      expect(p.getSixClient4List.length, 2); // ikkala slot ham qoldi
      expect(p.getOrphanDeletedItems, isEmpty);
      expect(p.getSixClient4List[1].deletedItems.single.productId, 'y');
    });

    test('bir nechta slot ketma-ket bo\'shasa hammasi yig\'iladi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'x', name: 'X', price: 5000, value: 1));
      // Mijoz 2: A qo'shildi-o'chirildi
      p.addClient();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'a', name: 'A', price: 1000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      p.selectClient(0);
      // Mijoz 3: B qo'shildi-o'chirildi
      p.addClient();
      p.getCurrentClient.orderedProducts
          .add(makeRow(productId: 'b', name: 'B', price: 2000, value: 1));
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));
      p.selectClient(0);

      expect(p.getOrphanDeletedItems.length, 2);
      expect(
        p.getOrphanDeletedItems.map((e) => e.productId).toList(),
        ['a', 'b'],
      );
      for (final d in p.getOrphanDeletedItems) {
        expect(d.checkNumber, '-');
      }
    });
  });

  group('9. deleted_by = PIN kiritgan xodim', () {
    final approver = Employee(
      user: EmployeeUser(id: 'admin-777', firstName: 'Admin'),
    );

    test('OPD o\'chirish: PIN egasi yoziladi, kassir emas', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));

      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton(approvedBy: approver);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.deletedItems.single.deletedBy, 'admin-777');
    });

    test('PIN so\'ralmasa (approvedBy null) — joriy kassir qoladi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));

      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.deletedItems.single.deletedBy, kCashierId);
    });

    test('qty kamaytirish (3->2): PIN egasi yoziladi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeRow(price: 5000, value: 3));

      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(
        makeRow(price: 5000, value: 2),
        approvedBy: approver,
      );

      final d = p.getCurrentClient.deletedItems.single;
      expect(d.deletedBy, 'admin-777');
      expect(d.quantity, 1);
    });

    test('markirovka guruhini o\'chirish: hamma qatorda PIN egasi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M1'))
        ..add(makeRow(price: 5000, value: 1, marking: true, mark: 'M2'));

      p.beginMarkGroupEdit('pepsi-id');
      p.pressDialogDeleteButton(approvedBy: approver);
      p.endMarkGroupEdit();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.deletedItems.length, 2);
      for (final d in p.getCurrentClient.deletedItems) {
        expect(d.deletedBy, 'admin-777');
      }
    });

    test('blok guruhini o\'chirish: hamma qatorda PIN egasi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'box-id', price: 5000, value: 12)
          ..saleType = 2)
        ..add(makeRow(productId: 'box-id', price: 5000, value: 12)
          ..saleType = 2);

      p.beginBoxGroupEdit('box-id');
      p.pressDialogDeleteButton(approvedBy: approver);
      p.endBoxGroupEdit();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(p.getCurrentClient.deletedItems.length, 2);
      for (final d in p.getCurrentClient.deletedItems) {
        expect(d.deletedBy, 'admin-777');
      }
    });

    test('serverga ketadigan JSON da deleted_by = PIN egasi', () async {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeRow(productId: 'x', name: 'X', price: 5000, value: 1))
        ..add(makeRow(productId: 'y', name: 'Y', price: 6000, value: 1));

      p.tapIndexToEdit(1); // y o'chadi, x aktiv qoladi
      p.pressDialogDeleteButton(approvedBy: approver);
      await Future.delayed(const Duration(milliseconds: 50));

      final receipt = makeReceipt();
      receipt.deletedItemsJson = jsonEncode(
        p.getCurrentClient.deletedItems.map((e) => e.toJson()).toList(),
      );
      final di = (receipt.toJson()['deleted_items'] as List).cast<Map>();
      expect(di.single['deleted_by'], 'admin-777');
      expect(di.single['check_number'], 'ext-1');
    });
  });
}
