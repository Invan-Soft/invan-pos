// Qog'oz chek QQS'i = fiskal QQS'i — `ReceiptVat` / `FiscalPaymentSplit`.
//
// Nega kerak: 100% cashback bilan to'langan chekda fiskalga VAT 0 ketardi,
// qog'oz chek esa "sh.j QQS" ni 12% qilib ko'rsatardi. Endi ikkisi bitta
// qoidadan (lib/changes/domain/receipt/receipt_vat.dart). Bu testlar:
//   1) to'lov tasnifi fiskal body (`saleOnOFD` → modul JSON) bilan aynan
//      bir xil: ReceivedCash / ReceivedCard / ΣOther;
//   2) chek jami QQS'i fiskal ΣVAT bilan (qator boshiga ≤ 1 so'm yaxlitlash)
//      mos — cashback, chegirma, ko'p qator, QQS 0%, vozvrat;
//   3) qator QQS'i aniq raqamlarda; blok/dona bo'linganda yig'indi saqlanadi.
// Click Pass / Payme Go: fiskalda ReceivedCard (QQS to'liq), chek bilan mos.
// Click QR / Payme QR / Uzum: fiskalda Other (VAT 0), chekda ayrilmaydi —
// ataylab (§6.1). Bu farq ham testda qayd etilgan.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/receipt_vat.dart';
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
const kCashbackId = 'pay-cashback';
const kClickId = 'pay-click';
const kPaymeId = 'pay-payme';
const kUzumId = 'pay-uzum';
const kCardId = 'pay-card';
const kCashId = 'pay-cash';

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

ReceiptModelPaymentType4 pay(String name, String payId, double v) =>
    ReceiptModelPaymentType4(name: name, payId: payId, value: v);

ReceiptModelPaymentType4 cash(double v) => pay('CASH', kCashId, v);
ReceiptModelPaymentType4 card(double v) => pay('CARD', kCardId, v);
ReceiptModelPaymentType4 cashback(double v) => pay('Cashback', kCashbackId, v);
// Nomlar/IDlar `ReceiptPayments.build` natijasidagidek: Pass/Go — '@' siz,
// QR (`type: 1`) — '@id'.
ReceiptModelPaymentType4 clickPass(double v) => pay('CLICK PASS', kClickId, v);
ReceiptModelPaymentType4 clickQr(double v) => pay('CLICK QR', '@$kClickId', v);
ReceiptModelPaymentType4 paymeGo(double v) => pay('PAYME GO', kPaymeId, v);
ReceiptModelPaymentType4 paymeQr(double v) => pay('PAYME QR', '@$kPaymeId', v);
ReceiptModelPaymentType4 uzum(double v) => pay('UZUM', kUzumId, v);
ReceiptModelPaymentType4 uzumQr(double v) => pay('UZUM QR', '@$kUzumId', v);

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
        ? jsonEncode({
            'TerminalID': 'MOCK00000001',
            'ReceiptSeq': '101',
            'DateTime': '20260924120000',
            'FiscalSign': '600000000101',
            'QRCodeURL': '',
          })
        : null,
  );
  r.soldItemList.addAll(rows);
  r.payment.addAll(payments ?? [cash(total)]);
  return r;
}

/// Modulga ketadigan JSON (fiscal_vat_base_test bilan bir xil zanjir).
Map<String, dynamic> wireOf(ReceiptModel4 receipt) {
  final ofdBody = ReceiptSingleton4.saleOnOFD(receipt);
  final model = RequestSaleModel.fromJson(ofdBody);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: 'UZ000000000MOCK',
      terminalID: 'MOCK00000001',
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

Map<String, dynamic> receiptPart(Map<String, dynamic> w) =>
    w['params']['Receipt'] as Map<String, dynamic>;
List<Map<String, dynamic>> itemsOf(Map<String, dynamic> w) =>
    (receiptPart(w)['Items'] as List).cast<Map<String, dynamic>>();

num sumOf(Map<String, dynamic> w, String key) =>
    itemsOf(w).fold<num>(0, (a, it) => a + (it[key] as num? ?? 0));

/// Chek jami QQS (so'm) fiskal ΣVAT (tiyin/100) bilan qator boshiga
/// ≤ 1 so'm farqda mos.
void expectPaperMatchesFiscal(ReceiptModel4 receipt) {
  final w = wireOf(receipt);
  final double fiscalVat = sumOf(w, 'VAT') / 100;
  final double paperVat = ReceiptVat.total(receipt);
  expect(paperVat, closeTo(fiscalVat, itemsOf(w).length.toDouble()),
      reason: 'chek QQS=$paperVat, fiskal ΣVAT=$fiscalVat');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('receipt_vat', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashbackId, kCashbackId);
    await Pref.setString(PrefKeys.clickId, kClickId);
    await Pref.setString(PrefKeys.paymeId, kPaymeId);
    await Pref.setString(PrefKeys.uzumId, kUzumId);
    await Pref.setString(PrefKeys.cardId, kCardId);
    await Pref.setString(PrefKeys.cashId, kCashId);
  });
  tearDownAll(tearDownPosTestEnv);

  group('FiscalPaymentSplit — to\'lov tasnifi fiskal body bilan bir xil', () {
    void expectSplitMatchesWire(ReceiptModel4 receipt) {
      final s = FiscalPaymentSplit.of(receipt);
      final w = wireOf(receipt);
      expect(receiptPart(w)['ReceivedCash'], closeTo(s.cash * 100, 0.5));
      expect(receiptPart(w)['ReceivedCard'], closeTo(s.card * 100, 0.5));
      // ΣOther = cashback + epay (chek jamidan oshmasa, yaxlitlash ±1)
      expect(sumOf(w, 'Other'), closeTo((s.cashback + s.epay) * 100, 100));
    }

    test('naqd nomi bo\'yicha', () {
      final r = receiptWith([row(realPrice: 50000)], payments: [pay('cash', 'x', 50000)]);
      final s = FiscalPaymentSplit.of(r);
      expect(s.cash, 50000);
      expect(s.card + s.cashback + s.epay, 0);
      expectSplitMatchesWire(r);
    });

    test('naqd adminka ID bo\'yicha (nom boshqa)', () {
      final r = receiptWith([row(realPrice: 50000)], payments: [pay('Naqd pul', '@$kCashId', 50000)]);
      expect(FiscalPaymentSplit.of(r).cash, 50000);
      expectSplitMatchesWire(r);
    });

    test('karta: CARD / UZCARD / HUMO nomlari va ID', () {
      for (final p in [
        pay('CARD', 'x', 50000),
        pay('uzcard', 'x', 50000),
        pay('Humo', 'x', 50000),
        pay('Terminal', kCardId, 50000),
      ]) {
        final r = receiptWith([row(realPrice: 50000)], payments: [p]);
        expect(FiscalPaymentSplit.of(r).card, 50000, reason: p.name);
        expectSplitMatchesWire(r);
      }
    });

    test('cashback ID bo\'yicha', () {
      final r = receiptWith([row(realPrice: 50000)], payments: [cashback(50000)]);
      final s = FiscalPaymentSplit.of(r);
      expect(s.cashback, 50000);
      expect(s.cash + s.card + s.epay, 0);
      expectSplitMatchesWire(r);
    });

    test('Click QR / Payme QR / Uzum (Pass ham, QR ham) → epay (Other)', () {
      for (final p in [clickQr(50000), paymeQr(50000), uzum(50000), uzumQr(50000)]) {
        final r = receiptWith([row(realPrice: 50000)], payments: [p]);
        final s = FiscalPaymentSplit.of(r);
        expect(s.epay, 50000, reason: p.name);
        expect(s.card, 0, reason: p.name);
        expectSplitMatchesWire(r);
      }
    });

    test('Click Pass / Payme Go → karta (ReceivedCard), Other 0', () {
      for (final p in [clickPass(50000), paymeGo(50000)]) {
        final r = receiptWith([row(realPrice: 50000)], payments: [p]);
        final s = FiscalPaymentSplit.of(r);
        expect(s.card, 50000, reason: p.name);
        expect(s.epay, 0, reason: p.name);
        final w = wireOf(r);
        expect(receiptPart(w)['ReceivedCard'], 5000000, reason: p.name);
        expect(sumOf(w, 'Other'), 0, reason: p.name);
        expectSplitMatchesWire(r);
      }
    });

    test('QR: serverdan qaytgan chekda \'@\' yo\'q, lekin nomi QR → epay', () {
      final r = receiptWith([row(realPrice: 50000)],
          payments: [pay('CLICK QR', kClickId, 50000)]);
      expect(FiscalPaymentSplit.of(r).epay, 50000);
    });

    test('Click ID bor, lekin nomi mos emas → karta (fallback)', () {
      final r = receiptWith([row(realPrice: 50000)], payments: [pay('Boshqa', kClickId, 50000)]);
      expect(FiscalPaymentSplit.of(r).card, 50000);
      expectSplitMatchesWire(r);
    });

    test('noma\'lum tur (nasiya, paynet...) → karta', () {
      final r = receiptWith([row(realPrice: 50000)], payments: [pay('debt', 'pay-debt', 50000)]);
      expect(FiscalPaymentSplit.of(r).card, 50000);
      expectSplitMatchesWire(r);
    });

    test('aralash: naqd + karta + cashback + click QR', () {
      final r = receiptWith(
        [row(realPrice: 100000)],
        payments: [cash(40000), card(30000), cashback(20000), clickQr(10000)],
      );
      final s = FiscalPaymentSplit.of(r);
      expect(s.cash, 40000);
      expect(s.card, 30000);
      expect(s.cashback, 20000);
      expect(s.epay, 10000);
      expectSplitMatchesWire(r);
    });

    test('aralash: naqd + Click Pass + Payme QR', () {
      final r = receiptWith(
        [row(realPrice: 100000)],
        payments: [cash(40000), clickPass(35000), paymeQr(25000)],
      );
      final s = FiscalPaymentSplit.of(r);
      expect(s.cash, 40000);
      expect(s.card, 35000);
      expect(s.epay, 25000);
      expectSplitMatchesWire(r);
    });

    test('vozvrat: hammasi naqd, to\'lov turidan qat\'iy nazar', () {
      final r = receiptWith(
        [row(realPrice: 50000)],
        payments: [card(30000), cashback(20000)],
        isRefund: true,
      );
      final s = FiscalPaymentSplit.of(r);
      expect(s.cash, 50000);
      expect(s.card + s.cashback + s.epay, 0);
      expectSplitMatchesWire(r);
    });
  });

  group('ReceiptVat — chek QQS\'i fiskal bilan mos', () {
    test('100% cashback: chekda QQS 0 (ilgari 12% ko\'rsatardi)', () {
      final r = receiptWith([row(realPrice: 50000)], payments: [cashback(50000)]);
      expect(ReceiptVat.paperOtherTotal(r), 50000);
      expect(ReceiptVat.perLine(r), [0]);
      expect(ReceiptVat.total(r), 0);
      expectPaperMatchesFiscal(r);
    });

    test('naqd, chegirmasiz: 50 000 × 12/112 = 5 357.14', () {
      final r = receiptWith([row(realPrice: 50000)]);
      expect(ReceiptVat.total(r), closeTo(5357.14, 0.01));
      expectPaperMatchesFiscal(r);
    });

    test('naqd, chegirma bilan: QQS chegirmadan keyingi narxdan', () {
      final r = receiptWith([row(realPrice: 50000, price: 20000)]);
      expect(ReceiptVat.total(r), closeTo(2142.86, 0.01));
      expectPaperMatchesFiscal(r);
    });

    test('qisman cashback + naqd: faqat naqd qismidan', () {
      final r = receiptWith([row(realPrice: 50000)],
          payments: [cashback(20000), cash(30000)]);
      // (50 000 − 20 000) × 12/112 = 3 214.29
      expect(ReceiptVat.total(r), closeTo(3214.29, 0.01));
      expectPaperMatchesFiscal(r);
    });

    test('ko\'p qator, cashback ulushi qatorlarga nisbat bo\'yicha', () {
      // 45 000 (chegirmali) + 30 000; cashback 15 000 → 9 000 + 6 000
      final r = receiptWith(
        [row(realPrice: 50000, price: 45000, name: 'A'), row(realPrice: 30000, name: 'B')],
        payments: [cashback(15000), cash(60000)],
      );
      final per = ReceiptVat.perLine(r);
      // (45 000 − 9 000) × 12/112 = 3 857.14; (30 000 − 6 000) × 12/112 = 2 571.43
      expect(per[0], closeTo(3857.14, 0.01));
      expect(per[1], closeTo(2571.43, 0.01));
      expectPaperMatchesFiscal(r);
    });

    test('chegirma + 100% cashback: 0', () {
      final r = receiptWith([row(realPrice: 50000, price: 20000)],
          payments: [cashback(20000)]);
      expect(ReceiptVat.total(r), 0);
      expectPaperMatchesFiscal(r);
    });

    test('QQS 0% qator: 0, boshqa qator o\'z QQS\'i bilan', () {
      final r = receiptWith(
        [row(realPrice: 50000, vatPercent: 0, name: 'A'), row(realPrice: 30000, name: 'B')],
        payments: [cashback(8000), cash(72000)],
      );
      final per = ReceiptVat.perLine(r);
      expect(per[0], 0);
      // B ulushi: 30/80 × 8 000 = 3 000 → (30 000 − 3 000) × 12/112 = 2 892.86
      expect(per[1], closeTo(2892.86, 0.01));
      expectPaperMatchesFiscal(r);
    });

    test('vozvrat: cashback ayrilmaydi (fiskalda ham Other yo\'q)', () {
      final r = receiptWith([row(realPrice: 50000, price: 20000)],
          payments: [cashback(20000)], isRefund: true);
      expect(ReceiptVat.paperOtherTotal(r), 0);
      expect(ReceiptVat.total(r), closeTo(2142.86, 0.01));
      expectPaperMatchesFiscal(r);
    });

    test('miqdor > 1 va tarozi kasr: yaxlitlash chegarasida mos', () {
      final r = receiptWith(
        [row(realPrice: 50000, price: 20000, value: 3, name: 'A'), row(realPrice: 77950, value: 0.29, name: 'B')],
        payments: [cashback(22605), cash(60000)],
      );
      expectPaperMatchesFiscal(r);
    });

    test('Click Pass / Payme Go: chek va fiskal QQS to\'liq, mos', () {
      for (final p in [clickPass(50000), paymeGo(50000)]) {
        final r = receiptWith([row(realPrice: 50000)], payments: [p]);
        expect(ReceiptVat.total(r), closeTo(5357.14, 0.01), reason: p.name);
        expect(sumOf(wireOf(r), 'VAT'), closeTo(535714, 1), reason: p.name);
        expectPaperMatchesFiscal(r);
      }
    });

    test('QAYD: Click QR bilan to\'langanda chekda QQS to\'liq, fiskalda 0', () {
      // Fiskal QR'ni Other'ga yozadi (§6.1 — ataylab o'zgartirilmagan).
      final r = receiptWith([row(realPrice: 50000)], payments: [clickQr(50000)]);
      expect(ReceiptVat.paperOtherTotal(r), 0);
      expect(ReceiptVat.total(r), closeTo(5357.14, 0.01));
      expect(sumOf(wireOf(r), 'VAT'), 0);
    });
  });

  group('receivedClick/Payme/Uzum — provayderga fiskal URL faqat Pass/Go da', () {
    Map<String, dynamic> paramsOf(ReceiptModel4 r) =>
        ReceiptSingleton4.saleOnOFD(r)['params'] as Map<String, dynamic>;

    test('Pass/Go → true', () {
      expect(paramsOf(receiptWith([row(realPrice: 50000)],
          payments: [clickPass(50000)]))['receivedClick'], true);
      expect(paramsOf(receiptWith([row(realPrice: 50000)],
          payments: [paymeGo(50000)]))['receivedPayme'], true);
      expect(paramsOf(receiptWith([row(realPrice: 50000)],
          payments: [uzum(50000)]))['receivedUzum'], true);
    });

    test('QR → false (ilgari true edi va eski payment ID bilan yuborilardi)', () {
      final p = paramsOf(receiptWith([row(realPrice: 90000)],
          payments: [clickQr(30000), paymeQr(30000), uzumQr(30000)]));
      expect(p['receivedClick'], false);
      expect(p['receivedPayme'], false);
      expect(p['receivedUzum'], false);
    });

    test('naqd → hammasi false', () {
      final p = paramsOf(receiptWith([row(realPrice: 50000)]));
      expect(p['receivedClick'], false);
      expect(p['receivedPayme'], false);
      expect(p['receivedUzum'], false);
    });
  });

  group('ReceiptVat.lineVat — qator va blok/dona bo\'linishi', () {
    test('qty berilmasa to\'liq qator', () {
      expect(ReceiptVat.lineVat(row(realPrice: 50000, value: 2)),
          closeTo(10714.29, 0.01));
    });

    test('other bazadan oshsa 0, manfiy emas', () {
      expect(ReceiptVat.lineVat(row(realPrice: 50000), other: 60000), 0);
    });

    test('QQS 0% → 0', () {
      expect(ReceiptVat.lineVat(row(realPrice: 50000, vatPercent: 0)), 0);
    });

    test('blok + dona bo\'lib chizilganda qismlar yig\'indisi = butun qator', () {
      // 14 dona (1 blok × 12 + 2 dona), cashback ulushi 7 000 butun qatorga
      final r = row(realPrice: 5000, value: 14);
      const share = 7000.0;
      final whole = ReceiptVat.lineVat(r, other: share);
      final block = ReceiptVat.lineVat(r, qty: 12, other: share * 12 / 14);
      final loose = ReceiptVat.lineVat(r, qty: 2, other: share * 2 / 14);
      expect(block + loose, closeTo(whole, 0.001));
    });
  });
}
