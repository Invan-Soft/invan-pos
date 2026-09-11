// Fiskal modulga ketadigan AYNAN wire-format JSON — to'liq zanjir testi.
//
// Nega kerak: ishlab chiqish mashinasida (Mac) fiskal modul yo'q, shuning
// uchun `is_marking=false` + markirovka MXIK fallback'i modul darajasida
// tekshirilmagan. Bu test `LocalService.saleWithOutIncom` bajaradigan
// o'sha zanjirni tarmoqsiz takrorlaydi:
//
//   ReceiptModel4 → ReceiptSingleton4.saleOnOFD (OFD body)
//     → RequestSaleModel.fromJson
//     → FiscalReceiptModel.fromRequest(...)
//     → toJson()  ← modulga POST qilinadigan JSON (Api.SendSaleReceipt /
//                    Api.SendRefundReceipt, params.Receipt.Items[].SPIC ...)
//
// Tekshiriladi: SPIC / Barcode / Label / PackageCode / Name / Amount / Price,
// method, RefundInfo, hamda §10.2.1 balansi (Σ(Price−Discount) =
// ReceivedCash + ReceivedCard + ΣOther) almashtirishdan keyin ham buzilmagani.
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

const kStaticMxik = '01905012001000000';
const kSuvMxik = '02202002001000000'; // markirovka ro'yxatida (suv/sharbat)
const kPivoMxik = '02206002002000000'; // alkogol — ro'yxatda
const kOddiyMxik = '01234567890123456';
const kBarcode = '4780000000001';
const kMark = '0104780000000001215Ab1cD2eF3g';
const kFactory = 'UZ000000000MOCK';
const kTerminal = 'MOCK00000001';

ItemModel product(String id, {required bool isMarking, required String mxik}) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.isMarking = isMarking;
  m.mxikCode = mxik;
  m.barcode = [kBarcode];
  return m;
}

ReceiptModelSoldItem4 row({
  required String productId,
  required String mxik,
  String? mark,
  String name = 'MARTCHOTASI 123321',
  double price = 4000,
  double value = 1,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: kBarcode,
    sku: 7105,
    vatPercent: 12,
    vat: (price * 12) / 112,
    mxik: mxik,
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
    sellerId: kCashierId,
    soldBy: kCashierId,
    singleDiscount: 0,
    ownerType: 1,
    mark: mark,
    marking: mark != null,
    packageCode: '1512199',
    packageName: 'dona',
  );
}

ReceiptModel4 receiptWith(List<ReceiptModelSoldItem4> rows,
    {bool isRefund = false}) {
  double total = 0;
  for (final r in rows) {
    total += r.price * r.value;
  }
  final r = ReceiptModel4(
    createdDate: '2026-09-11 12:00:00',
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
    // Vozvrat: asl chekning fiskal pasporti (modul javobidan saqlangan)
    refundInfo: isRefund
        ? jsonEncode(Info(
            terminalId: kTerminal,
            receiptSeq: '101',
            dateTime: '20260911120000',
            fiscalSign: '600000000101',
            qrCodeUrl: 'https://ofd.soliq.uz/check?t=$kTerminal&r=101',
          ).toJson())
        : null,
  );
  r.soldItemList.addAll(rows);
  r.payment.add(
    ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: total),
  );
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
    DateTime(2026, 9, 11, 12, 0, 0),
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
  // Modulga aynan shu ketadi: jsonEncode(fiscal.toJson())
  return jsonDecode(jsonEncode(fiscal.toJson())) as Map<String, dynamic>;
}

List<Map<String, dynamic>> itemsOf(Map<String, dynamic> wire) =>
    (wire['params']['Receipt']['Items'] as List).cast<Map<String, dynamic>>();

/// §10.2.1: Σ(Price − Discount) == ReceivedCash + ReceivedCard + ΣOther
void expectBalanced(Map<String, dynamic> wire) {
  final receipt = wire['params']['Receipt'] as Map<String, dynamic>;
  num left = 0, other = 0;
  for (final it in itemsOf(wire)) {
    left += (it['Price'] as num) - (it['Discount'] as num);
    other += (it['Other'] as num? ?? 0);
    expect((it['Other'] as num? ?? 0) + (it['Discount'] as num),
        lessThanOrEqualTo(it['Price'] as num),
        reason: 'per-item: Other + Discount ≤ Price');
  }
  final right =
      (receipt['ReceivedCash'] as num) + (receipt['ReceivedCard'] as num) + other;
  expect(left, right, reason: '§10.2.1 balans');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('fiscal_wire_format', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kStaticMxik);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [
      product('p-suv', isMarking: false, mxik: kSuvMxik),
      product('p-suv-true', isMarking: true, mxik: kSuvMxik),
      product('p-pivo', isMarking: false, mxik: kPivoMxik),
      product('p-non', isMarking: false, mxik: kOddiyMxik),
    ];
  });
  tearDown(() => ItemsSingleton.products = []);

  group('Api.SendSaleReceipt', () {
    test('is_marking=false + MXIK 02202, KM yo\'q → SPIC statik, Barcode "", Label ""',
        () {
      final wire = wireJson(receiptWith([row(productId: 'p-suv', mxik: kSuvMxik)]));

      expect(wire['jsonrpc'], '2.0');
      expect(wire['method'], 'Api.SendSaleReceipt');
      expect(wire['params']['FactoryID'], kFactory);

      final it = itemsOf(wire).single;
      expect(it['SPIC'], kStaticMxik);
      expect(it['Barcode'], '');
      expect(it['Label'], '');
      expect(it['Name'], 'MARTCHOTASI 123321');
      expect(it['PackageCode'], '1512199', reason: 'paket kodi tegilmaydi');
      expect(it['Amount'], 1000);
      expect(it['Price'], 400000, reason: 'tiyinda');
      expect(it['Discount'], 0);
      expect(it['VATPercent'], 12);
      expectBalanced(wire);
    });

    test('alkogol MXIK (02206) + is_marking=false, KM yo\'q → SPIC statik', () {
      final wire = wireJson(
          receiptWith([row(productId: 'p-pivo', mxik: kPivoMxik, name: 'Pivo')]));
      final it = itemsOf(wire).single;
      expect(it['SPIC'], kStaticMxik);
      expect(it['Barcode'], '');
      expectBalanced(wire);
    });

    test('is_marking=true + KM bilan → SPIC asl, Barcode asl, Label=KM', () {
      final wire = wireJson(receiptWith(
          [row(productId: 'p-suv-true', mxik: kSuvMxik, mark: kMark)]));
      final it = itemsOf(wire).single;
      expect(it['SPIC'], kSuvMxik);
      expect(it['Barcode'], kBarcode);
      expect(it['Label'], kMark);
      expectBalanced(wire);
    });

    test('is_marking=false, lekin KM skanerlangan → SPIC asl, Label=KM', () {
      final wire = wireJson(
          receiptWith([row(productId: 'p-suv', mxik: kSuvMxik, mark: kMark)]));
      final it = itemsOf(wire).single;
      expect(it['SPIC'], kSuvMxik);
      expect(it['Label'], kMark);
    });

    test('oddiy tovar → hech narsa o\'zgarmaydi', () {
      final wire = wireJson(
          receiptWith([row(productId: 'p-non', mxik: kOddiyMxik, name: 'Non')]));
      final it = itemsOf(wire).single;
      expect(it['SPIC'], kOddiyMxik);
      expect(it['Barcode'], kBarcode);
      expect(it['Label'], '');
    });

    test('aralash chek: har item o\'z qoidasi bilan, balans saqlanadi', () {
      final wire = wireJson(receiptWith([
        row(productId: 'p-suv', mxik: kSuvMxik, value: 3),
        row(productId: 'p-suv-true', mxik: kSuvMxik, mark: kMark, name: 'Suv KM'),
        row(productId: 'p-non', mxik: kOddiyMxik, name: 'Non', price: 2500),
      ]));
      final items = itemsOf(wire);
      expect(items.length, 3);

      final suv = items.firstWhere((e) => e['Name'] == 'MARTCHOTASI 123321');
      expect(suv['SPIC'], kStaticMxik);
      expect(suv['Barcode'], '');
      expect(suv['Amount'], 3000);
      expect(suv['Price'], 1200000);

      final suvKm = items.firstWhere((e) => e['Name'] == 'Suv KM');
      expect(suvKm['SPIC'], kSuvMxik);
      expect(suvKm['Label'], kMark);

      final non = items.firstWhere((e) => e['Name'] == 'Non');
      expect(non['SPIC'], kOddiyMxik);
      expect(non['Barcode'], kBarcode);

      expect(wire['params']['Receipt']['ReceivedCash'], 1850000);
      expect(wire['params']['Receipt']['ReceivedCard'], 0);
      expectBalanced(wire);
    });

    test('modul talab qiladigan maydonlar hammasi bor', () {
      final wire = wireJson(receiptWith([row(productId: 'p-suv', mxik: kSuvMxik)]));
      final receipt = wire['params']['Receipt'] as Map<String, dynamic>;
      for (final k in ['Time', 'ReceivedCash', 'ReceivedCard', 'Location', 'Items', 'ExtraInfo']) {
        expect(receipt.containsKey(k), isTrue, reason: k);
      }
      expect(receipt['Time'], '2026-09-11 12:00:00');
      final it = itemsOf(wire).single;
      for (final k in [
        'SPIC', 'Barcode', 'Label', 'Name', 'Amount', 'Price', 'Discount',
        'Other', 'VAT', 'VATPercent', 'Units', 'PackageCode', 'OwnerType',
        'CommissionInfo'
      ]) {
        expect(it.containsKey(k), isTrue, reason: k);
      }
      expect(it['SPIC'], isNot(isEmpty), reason: 'SPIC bo\'sh ketmasligi shart');
    });
  });

  group('Api.SendRefundReceipt', () {
    test('vozvrat: SPIC statik, Barcode "", RefundInfo asl chek pasporti bilan',
        () {
      final wire = wireJson(
          receiptWith([row(productId: 'p-suv', mxik: kSuvMxik)], isRefund: true));

      expect(wire['method'], 'Api.SendRefundReceipt');
      final it = itemsOf(wire).single;
      expect(it['SPIC'], kStaticMxik);
      expect(it['Barcode'], '');
      expect(it['Label'], '');

      final refundInfo =
          wire['params']['Receipt']['RefundInfo'] as Map<String, dynamic>?;
      expect(refundInfo, isNotNull);
      final values = refundInfo!.values.map((v) => v.toString()).toList();
      expect(values, contains(kTerminal));
      expect(values, contains('101'));
      expect(values, contains('600000000101'));
      expectBalanced(wire);
    });

    test('vozvrat, is_marking=true: SPIC asl (fallback aralashmaydi)', () {
      final wire = wireJson(receiptWith(
          [row(productId: 'p-suv-true', mxik: kSuvMxik)], isRefund: true));
      final it = itemsOf(wire).single;
      expect(it['SPIC'], kSuvMxik);
      expect(it['Barcode'], kBarcode);
    });
  });
}
