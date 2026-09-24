// Fiskal `VAT` bazasi: Price − Discount − Other.
//
// Nega kerak: 2026-09-24 gacha `ReceiptSingleton4._countVat` chegirmani
// ayirmasdan `(Price − Other)` dan QQS hisoblardi. Chegirmali tovarda soliqqa
// chegirmaSIZ narxdan QQS ketardi (50 000 so'm, 30 000 chegirma → QQS 50 000
// dan, 5 357 so'm; to'g'risi 20 000 dan, 2 143 so'm). Rasmiy FiscalDriveService
// misoli: Price 100000, Discount 50000, VATPercent 12 → VAT 5357
// = (100000 − 50000) × 12 / 112.
//
// Zanjir `test/fiscal_wire_format_test.dart` bilan bir xil (tarmoqsiz):
//   ReceiptModel4 → ReceiptSingleton4.saleOnOFD → RequestSaleModel
//     → FiscalReceiptModel.fromRequest → toJson()  ← modulga ketadigan JSON
//
// Tekshiriladi: `Items[].VAT` har qatorda
//   trunc((Price − Discount − Other) × VATPercent / (100 + VATPercent)),
// cashback (`Other`) bilan aralash holatlar, `_enforce1021Balance` ning
// uchala tuzatish yo'li (per-item qirqish, residual > 0, residual < 0) dan
// keyin ham VAT shu formulada qolishi va §10.2.1 balansi.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/fiscal_service/model/fiscal_receipt_model.dart';
import 'package:invan2/fiscal_service/model/location/location.dart';
import 'package:invan2/fiscal_service/model/receipt_data_model.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kMxik = '01234567890123456';
const kBarcode = '4780000000002';
const kCashbackPayId = 'pay-cashback-1';
const kFactory = 'UZ000000000MOCK';
const kTerminal = 'MOCK00000001';

ItemModel product(String id) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.isMarking = false;
  m.mxikCode = kMxik;
  m.barcode = [kBarcode];
  return m;
}

/// Savat qatori. [realPrice] — chegirmasiz narx, [price] — chegirmadan keyingi
/// narx (berilmasa chegirma yo'q). Diskont qo'llanganda ilova aynan shunday
/// qiladi: `price` kamayadi, `realPrice` asl narxda qoladi
/// (discount_helpers.dart), fiskalga `Price = realPrice × qty`,
/// `Discount = (realPrice − price) × qty` ketadi.
ReceiptModelSoldItem4 row({
  required double realPrice,
  double? price,
  double value = 1,
  double vatPercent = 12,
  String productId = 'p-1',
  String name = 'Tovar',
}) {
  final double p = price ?? realPrice;
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: kBarcode,
    sku: 1,
    vatPercent: vatPercent,
    vat: p == 0 ? 0 : (p * vatPercent) / (100 + vatPercent),
    mxik: kMxik,
    tin: '',
    onlyPrice: realPrice,
    realPrice: realPrice,
    price: p,
    cost: 0,
    vatName: 'НДС ${vatPercent.toStringAsFixed(0)}%',
    createdTime: DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: name,
    sellerId: kCashierId,
    soldBy: kCashierId,
    singleDiscount: realPrice - p,
    ownerType: 1,
    packageCode: '1512199',
    packageName: 'dona',
  );
}

ReceiptModelPaymentType4 cash(double v) =>
    ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: v);

/// Do'kon bonusi (cashback). `saleOnOFD` uni `payId == PrefKeys.cashbackId`
/// bo'yicha taniydi va qatorlar bo'ylab `Other` ga taqsimlaydi.
ReceiptModelPaymentType4 cashback(double v) =>
    ReceiptModelPaymentType4(name: 'Cashback', payId: kCashbackPayId, value: v);

ReceiptModel4 receiptWith(
  List<ReceiptModelSoldItem4> rows, {
  List<ReceiptModelPaymentType4>? payments,
  bool isRefund = false,
}) {
  double total = 0;
  for (final r in rows) {
    total += r.price * r.value;
  }
  final r = ReceiptModel4(
    createdDate: '2026-09-24 12:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'DN-1',
    orderType: isRefund ? 'refund' : 'sale',
    shopId: 'shop-1',
    userId: kUserId,
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: kCashierId,
    cashierName: kCashierName,
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: isRefund,
    totalPrice: total,
    uploaded: false,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: isRefund ? 'DN-0' : '',
    posName: 'Test POS',
    isDonate: false,
    refundInfo: isRefund
        ? jsonEncode(Info(
            terminalId: kTerminal,
            receiptSeq: '101',
            dateTime: '20260924120000',
            fiscalSign: '600000000101',
            qrCodeUrl: 'https://ofd.soliq.uz/check?t=$kTerminal&r=101',
          ).toJson())
        : null,
  );
  r.soldItemList.addAll(rows);
  r.payment.addAll(payments ?? [cash(total)]);
  return r;
}

/// `LocalService.saleWithOutIncom` bilan bir xil zanjir — tarmoqsiz.
Map<String, dynamic> wireJson(ReceiptModel4 receipt) {
  final Map<String, dynamic> ofdBody = ReceiptSingleton4.saleOnOFD(receipt);
  final RequestSaleModel model = RequestSaleModel.fromJson(ofdBody);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: kFactory,
      terminalID: kTerminal,
      location: Location(latitude: 41.311081, longitude: 69.240562),
    ),
    DateTime(2026, 9, 24, 12, 0, 0),
    ExtraInfo(
      carNumber: '',
      phoneNumber: '',
      cardType: 0,
      pinfl: '',
      tin: '',
      qrPaymentID: '',
      qrPaymentProvider: 0,
      cardNumber: '',
      pptId: '',
      cashedOutFromCard: 0,
    ),
  );
  return jsonDecode(jsonEncode(fiscal.toJson())) as Map<String, dynamic>;
}

Map<String, dynamic> receiptOf(Map<String, dynamic> wire) =>
    wire['params']['Receipt'] as Map<String, dynamic>;

List<Map<String, dynamic>> itemsOf(Map<String, dynamic> wire) =>
    (receiptOf(wire)['Items'] as List).cast<Map<String, dynamic>>();

/// Modul kutadigan VAT: trunc((Price − Discount − Other) × p / (100 + p)).
/// Transformatsiya kasrni `.toInt()` bilan kesadi, shuning uchun floor.
num netVat(Map<String, dynamic> it) {
  final num p = it['VATPercent'] as num;
  if (p == 0) return 0;
  final num base = (it['Price'] as num) -
      (it['Discount'] as num) -
      (it['Other'] as num? ?? 0);
  final num v = base * p / (100 + p);
  return v < 0 ? 0 : v.floor();
}

/// Har qatorda VAT aynan net bazadan (±1 tiyin yaxlitlash).
void expectVatFromNet(Map<String, dynamic> wire) {
  for (final it in itemsOf(wire)) {
    expect(it['VAT'], closeTo(netVat(it), 1),
        reason:
            '${it['Name']}: VAT=(Price−Discount−Other)×p/(100+p) bo\'lishi kerak '
            '(Price=${it['Price']} Discount=${it['Discount']} Other=${it['Other']})');
  }
}

/// §10.2.1: Σ(Price − Discount) == ReceivedCash + ReceivedCard + ΣOther,
/// har qatorda Other + Discount ≤ Price.
void expectBalanced(Map<String, dynamic> wire) {
  final receipt = receiptOf(wire);
  num left = 0, other = 0;
  for (final it in itemsOf(wire)) {
    left += (it['Price'] as num) - (it['Discount'] as num);
    other += (it['Other'] as num? ?? 0);
    expect((it['Other'] as num? ?? 0) + (it['Discount'] as num),
        lessThanOrEqualTo(it['Price'] as num),
        reason: 'per-item: Other + Discount ≤ Price');
  }
  final right = (receipt['ReceivedCash'] as num) +
      (receipt['ReceivedCard'] as num) +
      other;
  expect(left, right, reason: '§10.2.1 balans');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('fiscal_vat_base', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashbackId, kCashbackPayId);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [product('p-1'), product('p-2')];
  });
  tearDown(() => ItemsSingleton.products = []);

  group('QQS bazasi: chegirma (Discount)', () {
    test('50 000 so\'m, 30 000 chegirma → QQS 20 000 dan (2 143), 50 000 dan emas',
        () {
      final wire = wireJson(receiptWith([row(realPrice: 50000, price: 20000)]));
      final it = itemsOf(wire).single;

      expect(it['Price'], 5000000, reason: 'chegirmasiz, tiyinda');
      expect(it['Discount'], 3000000);
      expect(it['Other'], 0);
      expect(it['VATPercent'], 12);
      // 2 000 000 × 12 / 112 = 214 285.71 → 214 285 tiyin = 2 143 so'm
      expect(it['VAT'], closeTo(214285, 1));
      // Eski (xato) qiymat: 5 000 000 × 12 / 112 = 535 714
      expect(it['VAT'], isNot(closeTo(535714, 1)),
          reason: 'chegirmasiz narxdan QQS ketmasligi kerak');
      expect(receiptOf(wire)['ReceivedCash'], 2000000);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('rasmiy FiscalDriveService misoli: Price 100000, Discount 50000 → VAT 5357',
        () {
      // 1 000 so'm tovar 500 so'm chegirma bilan
      final wire = wireJson(receiptWith([row(realPrice: 1000, price: 500)]));
      final it = itemsOf(wire).single;
      expect(it['Price'], 100000);
      expect(it['Discount'], 50000);
      expect(it['VAT'], 5357);
      expectBalanced(wire);
    });

    test('chegirmasiz tovar: QQS o\'zgarmaydi (Price × 12 / 112)', () {
      final wire = wireJson(receiptWith([row(realPrice: 4000)]));
      final it = itemsOf(wire).single;
      expect(it['Price'], 400000);
      expect(it['Discount'], 0);
      expect(it['VAT'], closeTo(42857, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('miqdor > 1: Discount va QQS qator bo\'yicha', () {
      final wire =
          wireJson(receiptWith([row(realPrice: 50000, price: 20000, value: 3)]));
      final it = itemsOf(wire).single;
      expect(it['Amount'], 3000);
      expect(it['Price'], 15000000);
      expect(it['Discount'], 9000000);
      // 6 000 000 × 12 / 112 = 642 857.14
      expect(it['VAT'], closeTo(642857, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('100% chegirma (sovg\'a): Discount = Price, VAT 0', () {
      final wire = wireJson(receiptWith([row(realPrice: 50000, price: 0)]));
      final it = itemsOf(wire).single;
      expect(it['Price'], 5000000);
      expect(it['Discount'], 5000000);
      expect(it['VAT'], 0);
      expectBalanced(wire);
    });

    test('QQS 0% tovar: chegirma bo\'lsa ham VAT 0, VATPercent 0', () {
      final wire = wireJson(
          receiptWith([row(realPrice: 50000, price: 20000, vatPercent: 0)]));
      final it = itemsOf(wire).single;
      expect(it['VATPercent'], 0);
      expect(it['VAT'], 0);
      expect(it['Discount'], 3000000);
      expectBalanced(wire);
    });

    test('vozvrat: chegirmali qator QQS\'i ham chegirmadan keyingi', () {
      final wire = wireJson(
          receiptWith([row(realPrice: 50000, price: 20000)], isRefund: true));
      expect(wire['method'], 'Api.SendRefundReceipt');
      final it = itemsOf(wire).single;
      expect(it['Price'], 5000000);
      expect(it['Discount'], 3000000);
      expect(it['VAT'], closeTo(214285, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('ko\'p qatorli chek: chegirmali va chegirmasiz qatorlar mustaqil', () {
      final wire = wireJson(receiptWith([
        row(realPrice: 50000, price: 20000, name: 'Chegirmali'),
        row(realPrice: 30000, value: 2, productId: 'p-2', name: 'Oddiy'),
      ]));
      final items = itemsOf(wire);
      final a = items.firstWhere((e) => e['Name'] == 'Chegirmali');
      final b = items.firstWhere((e) => e['Name'] == 'Oddiy');
      expect(a['VAT'], closeTo(214285, 1));
      expect(b['Discount'], 0);
      expect(b['VAT'], closeTo(642857, 1), reason: '6 000 000 × 12 / 112');
      expect(receiptOf(wire)['ReceivedCash'], 8000000);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });
  });

  group('QQS bazasi: cashback (Other) — xaridordan olinmagan pul', () {
    test('100% cashback: Other = Price, VAT 0', () {
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000)],
        payments: [cashback(50000)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Price'], 5000000);
      expect(it['Other'], 5000000);
      expect(it['VAT'], 0);
      expect(receiptOf(wire)['ReceivedCash'], 0);
      expect(receiptOf(wire)['ReceivedCard'], 0);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('qisman cashback + naqd: QQS faqat naqd qismidan', () {
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000)],
        payments: [cashback(20000), cash(30000)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Other'], 2000000);
      // 3 000 000 × 12 / 112 = 321 428.57
      expect(it['VAT'], closeTo(321428, 1));
      expect(receiptOf(wire)['ReceivedCash'], 3000000);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('chegirma + qisman cashback: baza = Price − Discount − Other', () {
      // 50 000 → 20 000 chegirma bilan; 5 000 cashback + 15 000 naqd
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000, price: 20000)],
        payments: [cashback(5000), cash(15000)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Price'], 5000000);
      expect(it['Discount'], 3000000);
      expect(it['Other'], 500000);
      // 1 500 000 × 12 / 112 = 160 714.28
      expect(it['VAT'], closeTo(160714, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('chegirma + 100% cashback: Other + Discount == Price, VAT 0', () {
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000, price: 20000)],
        payments: [cashback(20000)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Discount'], 3000000);
      expect(it['Other'], 2000000);
      expect((it['Other'] as num) + (it['Discount'] as num), it['Price']);
      expect(it['VAT'], 0);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('ko\'p qatorli: cashback qatorlarga ulushi bo\'yicha, har qator VAT o\'z netidan',
        () {
      // A: 50 000 → 20 000 (net 20 000); B: 30 000 × 2 = 60 000. Jami 80 000.
      // Cashback 16 000 (20%) → A ga 4 000, B ga 12 000. Naqd 64 000.
      final wire = wireJson(receiptWith(
        [
          row(realPrice: 50000, price: 20000, name: 'A'),
          row(realPrice: 30000, value: 2, productId: 'p-2', name: 'B'),
        ],
        payments: [cashback(16000), cash(64000)],
      ));
      final items = itemsOf(wire);
      final a = items.firstWhere((e) => e['Name'] == 'A');
      final b = items.firstWhere((e) => e['Name'] == 'B');
      expect(a['Other'], 400000);
      expect(b['Other'], 1200000);
      // A: (5 000 000 − 3 000 000 − 400 000) × 12 / 112 = 171 428.57
      expect(a['VAT'], closeTo(171428, 1));
      // B: (6 000 000 − 0 − 1 200 000) × 12 / 112 = 514 285.71
      expect(b['VAT'], closeTo(514285, 1));
      expect(receiptOf(wire)['ReceivedCash'], 6400000);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });
  });

  group('_enforce1021Balance tuzatishlaridan keyin ham VAT net bazadan', () {
    test('per-item qirqish: cashback net\'dan oshsa Other = Price − Discount, VAT 0',
        () {
      // Net 20 000, cashback 20 001 (yaxlitlash oqibati) → Other qirqiladi.
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000, price: 20000)],
        payments: [cashback(20001)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Other'], 2000000,
          reason: 'Other ≤ Price − Discount ga qirqiladi');
      expect(it['VAT'], 0);
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('residual > 0 (tarozi yarim so\'m): Price kamayadi, VAT qayta hisoblanadi',
        () {
      // 0.29 × 77 950 = 22 605.5 → Price 22 606 ga yuqoriga yaxlitlanadi,
      // to'lov 22 605 (pastga). Chegirma bilan (80 000 → 77 950).
      final wire = wireJson(receiptWith(
        [row(realPrice: 80000, price: 77950, value: 0.29)],
        payments: [cashback(22605)],
      ));
      final it = itemsOf(wire).single;
      expect(it['VAT'], 0, reason: '100% cashback → QQS bazasi 0');
      expectVatFromNet(wire);
      expectBalanced(wire);
    });

    test('residual < 0 (to\'lov 1 so\'m ko\'p): Other kamayadi, VAT netdan', () {
      // 50 000 tovar, cashback 20 000 + naqd 30 001.
      final wire = wireJson(receiptWith(
        [row(realPrice: 50000)],
        payments: [cashback(20000), cash(30001)],
      ));
      final it = itemsOf(wire).single;
      expect(it['Other'], 1999900);
      // (5 000 000 − 1 999 900) × 12 / 112 = 321 439.28
      expect(it['VAT'], closeTo(321439, 1));
      expectVatFromNet(wire);
      expectBalanced(wire);
    });
  });
}
