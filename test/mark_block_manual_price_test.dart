// Markirovkali mahsulot + blok: qo'lda narx o'zgartirilganda sinxronlik testi.
// Muammo (real POS): markirovkali suvni blok + dona urib, dona narxini qo'lda
// o'zgartirsa — blok tier narxda qolib ketardi, yangi marka skani esa manual
// narxni meros olmay guruh o'rtacha (blend) ko'rsatardi.
//
// Fix A: _saveMarkGroup manual narxda _syncManualPriceAcrossProductRows chaqiradi
//        (blok qatoriga ham sinxronlanadi).
// Fix B: yangi skan mavjud manual narxni oladi (_applyExistingManualPrice).
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

ReceiptModelSoldItem4 makeRow({
  String productId = 'hydro-id',
  String name = 'Hydrolife 0.5',
  double price = 2750,
  double value = 1,
  int saleType = 1,
  int boxValue = 0,
  int boxQuantity = 0,
  bool marking = false,
  String? mark,
  bool isPriceOnlyChanged = false,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: '4780012960054',
    sku: 622,
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
    saleType: saleType,
    boxValue: boxValue,
    boxQuantity: boxQuantity,
  )..isPriceOnlyChanged = isPriceOnlyChanged;
}

/// Marka guruhi tahririda saqlanadigan "tahrirlangan nusxa" (qo'lda narx).
/// [markCount] guruhdagi marka soni (dialog displayValue).
ReceiptModelSoldItem4 editedMark(double newPrice, int markCount) {
  final copy = makeRow(
    price: newPrice,
    value: markCount.toDouble(),
    saleType: 1,
    marking: true,
  );
  copy.isPriceOnlyChanged = true;
  copy.isPriceChanged = true;
  return copy;
}

/// Blok guruhi tahririda saqlanadigan "tahrirlangan nusxa" (qo'lda blok narxi).
/// [blockCount] guruhdagi blok soni (dialog displayValue), [boxValue] 1 blokdagi dona.
ReceiptModelSoldItem4 editedBox(double newBlockPrice, int blockCount, int boxValue) {
  final copy = makeRow(
    price: newBlockPrice,
    value: blockCount.toDouble(),
    saleType: 2,
    boxValue: boxValue,
    boxQuantity: blockCount,
  );
  copy.isPriceOnlyChanged = true;
  copy.isPriceChanged = true;
  return copy;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('mark_block_price_test'));
  tearDownAll(tearDownPosTestEnv);

  group('Markirovka guruhi + blok — qo\'lda narx sinxron', () {
    test('Fix A: marka narxini 2750->4000 qilsa blok 33000->48000 bo\'ladi',
        () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 33000, value: 1, saleType: 2, boxValue: 12, boxQuantity: 1);
      final mark =
          makeRow(price: 2750, value: 1, marking: true, mark: 'm1');
      p.getCurrentClient.orderedProducts.addAll([blok, mark]);

      p.beginMarkGroupEdit('hydro-id');
      p.tapIndexToEdit(1);
      await p.pressDialogSaveButton(editedMark(4000, 1));
      p.endMarkGroupEdit();

      final rows = p.getCurrentClient.orderedProducts;
      final blokRow = rows.firstWhere((e) => e.saleType == 2);
      final markRow = rows.firstWhere((e) => e.marking);
      expect(markRow.price, 4000);
      expect(blokRow.price, 48000); // 4000 × 12
      expect(blokRow.isPriceOnlyChanged, true);
    });

    test('Fix A: 2 marka + blok — hammasi bir xil dona narxiga tushadi',
        () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 33000, value: 1, saleType: 2, boxValue: 12, boxQuantity: 1);
      final m1 = makeRow(price: 2750, value: 1, marking: true, mark: 'm1');
      final m2 = makeRow(price: 2750, value: 1, marking: true, mark: 'm2');
      p.getCurrentClient.orderedProducts.addAll([blok, m1, m2]);

      p.beginMarkGroupEdit('hydro-id');
      p.tapIndexToEdit(1);
      await p.pressDialogSaveButton(editedMark(4000, 2));
      p.endMarkGroupEdit();

      final rows = p.getCurrentClient.orderedProducts;
      for (final m in rows.where((e) => e.marking)) {
        expect(m.price, 4000);
      }
      expect(rows.firstWhere((e) => e.saleType == 2).price, 48000);
    });

    test(
        'Fix B mexanizmi: manual narxli guruhga yangi marka (tier 2750) qo\'shilsa, '
        'guruh tahriri uni ham 4000 qiladi (blend yo\'q)', () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 33000, value: 1, saleType: 2, boxValue: 12, boxQuantity: 1);
      // Allaqachon manual (4000) marka
      final manualMark = makeRow(
          price: 4000, value: 1, marking: true, mark: 'm1',
          isPriceOnlyChanged: true);
      // Yangi skan qilingan tier (2750) marka — hali manual emas
      final freshMark =
          makeRow(price: 2750, value: 1, marking: true, mark: 'm2');
      p.getCurrentClient.orderedProducts.addAll([blok, manualMark, freshMark]);

      // Guruh tahriri (yoki keyingi skan) manual narxni butun guruhga tarqatadi
      p.beginMarkGroupEdit('hydro-id');
      p.tapIndexToEdit(1);
      await p.pressDialogSaveButton(editedMark(4000, 2));
      p.endMarkGroupEdit();

      final rows = p.getCurrentClient.orderedProducts;
      for (final m in rows.where((e) => e.marking)) {
        expect(m.price, 4000); // ikkala marka ham 4000 — o'rtacha (3375) EMAS
      }
      expect(rows.firstWhere((e) => e.saleType == 2).price, 48000);
    });

    test(
        'Teskari yo\'nalish: blok narxini 30000->40000 (10 tali blok) qilsa, '
        '2 ta alohida marka (dona) ham 4000 bo\'ladi', () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 30000, value: 1, saleType: 2, boxValue: 10, boxQuantity: 1);
      final m1 = makeRow(price: 3000, value: 1, marking: true, mark: 'm1');
      final m2 = makeRow(price: 3000, value: 1, marking: true, mark: 'm2');
      p.getCurrentClient.orderedProducts.addAll([blok, m1, m2]);

      // Blok guruhi tahriri: 1 blok, narxi 30000->40000
      p.beginBoxGroupEdit('hydro-id');
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(editedBox(40000, 1, 10));
      p.endBoxGroupEdit();

      final rows = p.getCurrentClient.orderedProducts;
      final blokRow = rows.firstWhere((e) => e.saleType == 2);
      expect(blokRow.price, 40000);
      for (final m in rows.where((e) => e.marking)) {
        expect(m.price, 4000); // 40000 / 10
        expect(m.isPriceOnlyChanged, true);
      }
    });

    test('qty-only marka tahririda blokka tegilmaydi (narx o\'zgarmagan)',
        () async {
      final p = freshProvider();
      final blok = makeRow(
          price: 33000, value: 1, saleType: 2, boxValue: 12, boxQuantity: 1);
      final m1 = makeRow(price: 2750, value: 1, marking: true, mark: 'm1');
      final m2 = makeRow(price: 2750, value: 1, marking: true, mark: 'm2');
      p.getCurrentClient.orderedProducts.addAll([blok, m1, m2]);

      // narx bir xil (2750), faqat qty 2->1 (bitta marka o'chadi)
      final copy = makeRow(price: 2750, value: 1, marking: true);
      p.beginMarkGroupEdit('hydro-id');
      p.tapIndexToEdit(1);
      await p.pressDialogSaveButton(copy);
      p.endMarkGroupEdit();

      final blokRow =
          p.getCurrentClient.orderedProducts.firstWhere((e) => e.saleType == 2);
      expect(blokRow.price, 33000); // o'zgarmagan
      expect(blokRow.isPriceOnlyChanged, false);
    });
  });
}
