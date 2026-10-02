// Click/Payme/Uzum fiskal testlari uchun umumiy fixture'lar:
// test/epay_fiscal_matrix_test.dart, test/receipt_epay_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/receipt_payments.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/services/local_selling_service.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/fiscal_service/model/fiscal_receipt_model.dart';
import 'package:invan2/fiscal_service/model/location/location.dart';
import 'package:invan2/fiscal_service/model/receipt_data_model.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'provider_harness.dart';

const kMxik = '01234567890123456';
const ids = PaymentIds(
  cash: 'pay-cash',
  card: 'pay-card',
  cashback: 'pay-cashback',
  debt: 'pay-debt',
  payme: 'pay-payme',
  click: 'pay-click',
  uzum: 'pay-uzum',
);

/// Fiskalda qaysi maydonga tushishi kerak.
enum Bucket { cash, card, other }

/// To'lov ekranidagi tugma.
enum Kind {
  cash('pay-cash', 0, Bucket.cash),
  uzcard('pay-card', 0, Bucket.card),
  humo('@pay-card', 1, Bucket.card),
  clickPass('pay-click', 0, Bucket.card),
  clickQr('@pay-click', 1, Bucket.other),
  paymeGo('pay-payme', 0, Bucket.card),
  paymeQr('@pay-payme', 1, Bucket.other),
  uzum('pay-uzum', 0, Bucket.other),
  uzumQr('@pay-uzum', 1, Bucket.other),
  cashback('pay-cashback', 0, Bucket.other),
  debt('pay-debt', 0, Bucket.card);

  const Kind(this.key, this.type, this.bucket);

  /// `paymentsMap` kaliti (QR — '@id').
  final String key;
  final int type;
  final Bucket bucket;
}

/// Savat varianti.
class Cart {
  const Cart(this.name, this.rows);
  final String name;
  final List<ReceiptModelSoldItem4> Function() rows;
}

ReceiptModelSoldItem4 row({
  required double realPrice,
  double? price,
  double value = 1,
  double vatPercent = 12,
  String name = 'Tovar',
}) =>
    makeSoldItem(
      productId: name,
      name: name,
      price: price ?? realPrice,
      realPrice: realPrice,
      onlyPrice: realPrice,
      value: value,
      vatPercent: vatPercent,
      singleDiscount: realPrice - (price ?? realPrice),
      mxik: kMxik,
    );

final List<Cart> carts = [
  Cart('bitta qator 50 000, 12%', () => [row(realPrice: 50000)]),
  Cart('ko\'p qator, QQS 12% va 0%', () => [
        row(realPrice: 37500, value: 2, name: 'A'),
        row(realPrice: 15000, vatPercent: 0, name: 'B'),
        row(realPrice: 9990, name: 'C'),
      ]),
  Cart('chegirma 120 000 → 99 000', () => [
        row(realPrice: 120000, price: 99000, name: 'D'),
        row(realPrice: 4500, value: 3, name: 'E'),
      ]),
  Cart('katta summa 3 × 12 500 000', () => [
        row(realPrice: 12500000, value: 3, name: 'F'),
      ]),
];

/// Tarozi: 0.29 × 77 950 = 22 605.5 (yarim so'm) — §10.2.1 yaxlitlash.
Cart scaleCart = Cart('tarozi 0.29 × 77 950', () => [
      row(realPrice: 77950, value: 0.29, name: 'Go\'sht'),
      row(realPrice: 12000, name: 'Non'),
    ]);

double cartTotal(List<ReceiptModelSoldItem4> rows) =>
    rows.fold<double>(0, (a, r) => a + r.price * r.value);

/// To'lov ekrani xaritasi → haqiqiy `ReceiptPayments.build`.
List<ReceiptModelPaymentType4> buildPayments(
  Map<Kind, double> amounts, {
  double sdacha = 0,
}) {
  final map = <String, Payment>{
    for (final e in amounts.entries)
      e.key.key: Payment(
        name: e.key.name,
        id: e.key.key.replaceFirst('@', ''),
        type: e.key.type,
        value: e.value,
      ),
  };
  return ReceiptPayments.build(map,
      ids: ids, sdacha: sdacha, zdachaToCashBack: 0);
}

ReceiptModel4 receiptOf(
  List<ReceiptModelSoldItem4> rows,
  List<ReceiptModelPaymentType4> payments, {
  bool isRefund = false,
}) {
  final r = ReceiptModel4(
    createdDate: '2026-10-02 12:00:00',
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
    totalPrice: cartTotal(rows),
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
        ? jsonEncode({
            'TerminalID': 'MOCK00000001',
            'ReceiptSeq': '101',
            'DateTime': '20261002120000',
            'FiscalSign': '600000000101',
            'QRCodeURL': '',
          })
        : null,
  );
  r.soldItemList.addAll(rows);
  r.payment.addAll(payments);
  return r;
}

Map<String, dynamic> paramsOf(ReceiptModel4 r) =>
    ReceiptSingleton4.saleOnOFD(r)['params'] as Map<String, dynamic>;

/// Modulga ketadigan JSON.
Map<String, dynamic> wireOf(ReceiptModel4 receipt) {
  final body = ReceiptSingleton4.saleOnOFD(receipt);
  final model = RequestSaleModel.fromJson(body);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: 'UZ000000000MOCK',
      terminalID: 'MOCK00000001',
      location: Location(latitude: 41.311081, longitude: 69.240562),
    ),
    DateTime(2026, 10, 2, 12, 0, 0),
    // saleWithOutIncom bilan aynan bir xil ExtraInfo.
    LocalService.extraInfoFromBody(body),
  );
  return jsonDecode(jsonEncode(fiscal.toJson())) as Map<String, dynamic>;
}

Map<String, dynamic> receiptPart(Map<String, dynamic> w) =>
    w['params']['Receipt'] as Map<String, dynamic>;
List<Map<String, dynamic>> itemsOf(Map<String, dynamic> w) =>
    (receiptPart(w)['Items'] as List).cast<Map<String, dynamic>>();
num sumOf(Map<String, dynamic> w, String key) =>
    itemsOf(w).fold<num>(0, (a, it) => a + (it[key] as num? ?? 0));

/// Modul qabul qilishi uchun shart bo'lgan invariantlar.
void expectModuleInvariants(Map<String, dynamic> w, String why) {
  final rp = receiptPart(w);
  final num cash = rp['ReceivedCash'] as num;
  final num card = rp['ReceivedCard'] as num;
  expect(cash, greaterThanOrEqualTo(0), reason: '$why: ReceivedCash');
  expect(card, greaterThanOrEqualTo(0), reason: '$why: ReceivedCard');

  for (final it in itemsOf(w)) {
    final num price = it['Price'] as num;
    final num disc = it['Discount'] as num? ?? 0;
    final num other = it['Other'] as num? ?? 0;
    final num vat = it['VAT'] as num? ?? 0;
    final num p = it['VATPercent'] as num? ?? 0;
    expect(other, greaterThanOrEqualTo(0), reason: '$why: ${it['Name']} Other');
    expect(other + disc, lessThanOrEqualTo(price),
        reason: '$why: ${it['Name']} Other+Discount ≤ Price');
    final double expectedVat = p == 0 ? 0 : (price - disc - other) * p / (100 + p);
    expect(vat, closeTo(expectedVat, 1),
        reason: '$why: ${it['Name']} VAT bazasi (Price−Discount−Other)');
  }

  final num lhs = sumOf(w, 'Price') - sumOf(w, 'Discount');
  final num rhs = cash + card + sumOf(w, 'Other');
  expect(lhs, rhs, reason: '$why: §10.2.1 Σ(Price−Discount) = Cash+Card+ΣOther');
}

/// To'lov turlariga qarab kutilgan maydonlar (tiyinda).
void expectBuckets(
  Map<String, dynamic> w,
  Map<Kind, double> amounts,
  String why, {
  int rows = 1,
}) {
  double cash = 0, card = 0, other = 0;
  amounts.forEach((k, v) {
    switch (k.bucket) {
      case Bucket.cash:
        cash += v;
        break;
      case Bucket.card:
        card += v;
        break;
      case Bucket.other:
        other += v;
        break;
    }
  });
  final rp = receiptPart(w);
  expect(rp['ReceivedCash'], (cash * 100).round(), reason: '$why: ReceivedCash');
  expect(rp['ReceivedCard'], (card * 100).round(), reason: '$why: ReceivedCard');
  // Other qatorlarga so'mga yaxlitlab taqsimlanadi — qator boshiga ≤ 1 so'm.
  expect(sumOf(w, 'Other'), closeTo(other * 100, rows * 100.0),
      reason: '$why: ΣOther');
  if (other == 0) expect(sumOf(w, 'Other'), 0, reason: '$why: Other 0');
}

void expectFlags(Map<String, dynamic> params, Set<Kind> kinds, String why) {
  expect(params['receivedClick'], kinds.contains(Kind.clickPass),
      reason: '$why: receivedClick');
  expect(params['receivedPayme'], kinds.contains(Kind.paymeGo),
      reason: '$why: receivedPayme');
  expect(params['receivedUzum'], kinds.contains(Kind.uzum),
      reason: '$why: receivedUzum');
}

