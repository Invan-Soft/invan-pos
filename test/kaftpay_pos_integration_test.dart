// Kaftpay — POS'ga ulanishi: to'lov ekranidagi summa, chekdagi nom, fiskal
// modulga ketadigan JSON (karta), o'chirib bo'lmaslik, tur id'sini tanish.
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/domain/receipt/receipt_payments.dart';
import 'package:invan2/changes/domain/receipt/receipt_vat.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/services/web_socket_service/product/products_ws_service.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/epay_fixtures.dart';
import 'support/provider_harness.dart';

const kKaftpayId = 'pay-kaftpay';

Payment pay(String id, String name, {int? type}) =>
    Payment(id: id, name: name, title: name, enable: true, type: type);

Payment get kaftpay => pay(kKaftpayId, 'Kaftpay');

OrderingProvider4 paymentPage({double total = 100000}) {
  final p = freshProvider();
  p.initPaymentPageValues(
    sixClientModel4: SixClientModel4(
      clientNumber: 1,
      lastAddedIndex: -1,
      orderedProducts: [],
      discountAmountFromNewClient: 0,
    ),
    totalPrice: total,
    discountAmount: 0,
  );
  return p;
}

Map<String, ReceiptModelPaymentType4> chekOf(OrderingProvider4 p) =>
    {for (final e in p.paymentsMapAsList) e.payId: e};

const kYagonaId = 'pay-yagona';

/// Fixture'dagi `ids` + Kaftpay (+ YagonaQr — ikkalasi bitta chekda).
const kIds = PaymentIds(
  cash: 'pay-cash',
  card: 'pay-card',
  cashback: 'pay-cashback',
  debt: 'pay-debt',
  payme: 'pay-payme',
  click: 'pay-click',
  uzum: 'pay-uzum',
  yagonaQr: kYagonaId,
  kaftpay: kKaftpayId,
);

/// To'lov ekrani xaritasi (Kind'lar + Kaftpay) → haqiqiy `ReceiptPayments.build`.
List<ReceiptModelPaymentType4> paysWithKaftpay(
  Map<Kind, double> amounts, {
  double kaftpayValue = 0,
  double yagona = 0,
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
    if (yagona > 0)
      kYagonaId:
          Payment(name: 'YagonaQr', id: kYagonaId, type: null, value: yagona),
    if (kaftpayValue > 0)
      kKaftpayId: Payment(
          name: 'Kaftpay', id: kKaftpayId, type: null, value: kaftpayValue),
  };
  return ReceiptPayments.build(map,
      ids: kIds, sdacha: sdacha, zdachaToCashBack: 0);
}

/// Kaftpay ishtirokidagi chek (provider'dagidek cardType 2).
ReceiptModel4 saleWithKaftpay(
  List<ReceiptModelSoldItem4> rows,
  Map<Kind, double> amounts, {
  required double kaftpayValue,
  double yagona = 0,
  double sdacha = 0,
}) =>
    receiptOf(
        rows,
        paysWithKaftpay(amounts,
            kaftpayValue: kaftpayValue, yagona: yagona, sdacha: sdacha))
      ..cardType = 2;

/// Kutilgan fiskal maydonlar: Kaftpay (va YagonaQr) — karta.
void expectBucketsWithKaftpay(
  Map<String, dynamic> w,
  Map<Kind, double> amounts,
  double cardExtra,
  String why, {
  int rows = 1,
}) {
  double cash = 0, card = cardExtra, other = 0;
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
  expect(rp['ReceivedCash'], (cash * 100).round(),
      reason: '$why: ReceivedCash');
  expect(rp['ReceivedCard'], (card * 100).round(),
      reason: '$why: ReceivedCard');
  expect(sumOf(w, 'Other'), closeTo(other * 100, rows * 100.0),
      reason: '$why: ΣOther');
  if (other == 0) expect(sumOf(w, 'Other'), 0, reason: '$why: Other 0');
}

Map<String, dynamic> extraOf(Map<String, dynamic> w) =>
    receiptPart(w)['ExtraInfo'] as Map<String, dynamic>;

/// To'lov ekranidan chekkacha: provider'ning to'lovlari va cardType'i.
ReceiptModel4 receiptFromPage(
        OrderingProvider4 p, List<ReceiptModelSoldItem4> rows) =>
    receiptOf(rows, p.paymentsMapAsList)..cardType = p.lastCardType;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('kaftpay_pos_test', withEmployee: false);
    final org = OrganizationModelAdapter(), payment = PaymentAdapter();
    if (!Hive.isAdapterRegistered(org.typeId)) {
      Hive.registerAdapter<OrganizationModel>(org);
    }
    if (!Hive.isAdapterRegistered(payment.typeId)) {
      Hive.registerAdapter<Payment>(payment);
    }
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashId, ids.cash);
    await Pref.setString(PrefKeys.cardId, ids.card);
    await Pref.setString(PrefKeys.cashbackId, ids.cashback);
    await Pref.setString(PrefKeys.debtId, ids.debt);
    await Pref.setString(PrefKeys.clickId, ids.click);
    await Pref.setString(PrefKeys.paymeId, ids.payme);
    await Pref.setString(PrefKeys.uzumId, ids.uzum);
    await Pref.setString(PrefKeys.kaftpayId, kKaftpayId);
    await Pref.setString(PrefKeys.yagonaQrId, kYagonaId);
  });
  tearDownAll(tearDownPosTestEnv);

  group('To\'lov ekrani', () {
    test('summa: klaviaturadagi yoki qoldiq; qoldiqdan katta bo\'lsa qoldiq',
        () {
      final p = paymentPage(total: 100000);
      expect(p.kaftpayAmount(kaftpay), 100000);
      p.controller.text = '30000';
      expect(p.kaftpayAmount(kaftpay), 30000);
      p.controller.text = '150000';
      expect(p.kaftpayAmount(kaftpay), 100000);
    });

    test(
        'naqd 40 000 + Kaftpay 60 000 — YECHILGAN summa yoziladi, chekda '
        'KAFTPAY', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '40000';
      p.allPaymentType(pay(ids.cash, 'CASH'));
      expect(p.kaftpayAmount(kaftpay), 60000);
      // Oyna ochiq turganda klaviatura o'zgargan bo'lsa ham — yechilgani.
      p.controller.text = '5000';
      p.recordKaftpay(kaftpay, 60000);

      expect(p.paymentsMap[kKaftpayId]?.value, 60000);
      expect(p.controller.text, '0');
      final chek = chekOf(p);
      expect(chek[ids.cash]?.name, 'CASH');
      expect(chek[kKaftpayId]?.name, 'KAFTPAY');
      expect(chek[kKaftpayId]?.payId, kKaftpayId, reason: '"@" siz');
      expect(p.kaftpayAmount(kaftpay), 0, reason: 'to\'liq to\'landi');
    });

    test('Kaftpay qatori o\'chirilmaydi (tanlangan ham, "hammasini" ham)', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '30000';
      p.allPaymentType(pay(ids.cash, 'CASH'));
      p.recordKaftpay(kaftpay, 70000);

      p.selectedPaymentIndex = p.paymentsMap.keys.toList().indexOf(kKaftpayId);
      expect(p.removeFromPaymentList(), isFalse);
      expect(p.paymentsMap[kKaftpayId]?.value, 70000);

      // Hech narsa tanlanmagan — "hammasini tozalash": naqd ketadi, Kaftpay qoladi.
      p.selectedPaymentIndex = -1;
      expect(p.removeFromPaymentList(), isFalse);
      expect(p.paymentsMap.keys, [kKaftpayId]);

      // Oddiy qator — eskidek o'chiriladi.
      p.controller.text = '30000';
      p.allPaymentType(pay(ids.cash, 'CASH'));
      p.selectedPaymentIndex = p.paymentsMap.keys.toList().indexOf(ids.cash);
      expect(p.removeFromPaymentList(), isTrue);
      expect(p.paymentsMap.keys, [kKaftpayId]);
    });
  });

  group('Fiskal', () {
    final rows = [row(realPrice: 100000)];

    test('Kaftpay — KARTA (ReceivedCard), Other 0; naqd bilan aralash', () {
      final r = receiptOf(rows, [
        ReceiptModelPaymentType4(name: 'CASH', payId: ids.cash, value: 40000),
        ReceiptModelPaymentType4(
            name: 'KAFTPAY', payId: kKaftpayId, value: 60000),
      ]);
      final split = FiscalPaymentSplit.of(r);
      expect(split.cash, 40000);
      expect(split.card, 60000);
      expect(split.epay, 0);

      final w = wireOf(r);
      expect(receiptPart(w)['ReceivedCash'], 4000000);
      expect(receiptPart(w)['ReceivedCard'], 6000000);
      expect(sumOf(w, 'Other'), 0);
      expectModuleInvariants(w, 'kaftpay+naqd');
    });

    test('serverdan qaytgan chek (admin nomi bilan) ham id bo\'yicha karta',
        () {
      final r = receiptOf(rows, [
        ReceiptModelPaymentType4(
            name: 'Kaftpay', payId: kKaftpayId, value: 100000),
      ]);
      expect(FiscalPaymentSplit.of(r).card, 100000);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Soliq: cardType 2 (YagonaQr kabi)', () {
    test('boshida 0; faqat naqd — 0; Kaftpay yechildi — 2; yangi sahifa — 0',
        () {
      final p = paymentPage(total: 100000);
      expect(p.lastCardType, 0);
      p.controller.text = '40000';
      p.allPaymentType(pay(ids.cash, 'CASH'));
      expect(p.lastCardType, 0, reason: 'naqd chekka CardType ketmasin');
      p.recordKaftpay(kaftpay, 60000);
      expect(p.lastCardType, 2);
      p.initPaymentPageValues(
        sixClientModel4: SixClientModel4(
          clientNumber: 1,
          lastAddedIndex: -1,
          orderedProducts: [],
          discountAmountFromNewClient: 0,
        ),
        totalPrice: 100000,
        discountAmount: 0,
      );
      expect(p.lastCardType, 0);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('To\'lov ekranidan soliqqacha (provider → fiskal JSON)', () {
    final rows = [row(realPrice: 100000)];

    test('naqd 40 000 + Kaftpay 60 000', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '40000';
      p.allPaymentType(pay(ids.cash, 'CASH'));
      p.recordKaftpay(kaftpay, 60000);
      final w = wireOf(receiptFromPage(p, rows));
      expectModuleInvariants(w, 'naqd+kaftpay');
      expect(receiptPart(w)['ReceivedCash'], 4000000);
      expect(receiptPart(w)['ReceivedCard'], 6000000);
      expect(sumOf(w, 'Other'), 0);
      expect(extraOf(w)['CardType'], 2);
    });

    test('faqat Kaftpay 100 000', () {
      final p = paymentPage(total: 100000);
      p.recordKaftpay(kaftpay, 100000);
      final w = wireOf(receiptFromPage(p, rows));
      expectModuleInvariants(w, 'kaftpay');
      expect(receiptPart(w)['ReceivedCash'], 0);
      expect(receiptPart(w)['ReceivedCard'], 10000000);
      expect(extraOf(w)['CardType'], 2);
      expect(sumOf(w, 'VAT'), greaterThan(0), reason: 'karta — QQS to\'liq');
    });

    test('Kaftpay ikki marta (30 000 + 70 000) — chekda bitta qator', () {
      final p = paymentPage(total: 100000);
      p.recordKaftpay(kaftpay, 30000);
      p.recordKaftpay(kaftpay, 70000);
      final chek = chekOf(p);
      expect(chek.length, 1);
      expect(chek[kKaftpayId]?.value, 100000);
      final w = wireOf(receiptFromPage(p, rows));
      expect(receiptPart(w)['ReceivedCard'], 10000000);
    });

    test('Uzcard 30 000 + Kaftpay 70 000 — ikkalasi karta', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '30000';
      p.allPaymentType(pay(ids.card, 'CARD'));
      p.recordKaftpay(kaftpay, 70000);
      final w = wireOf(receiptFromPage(p, rows));
      expectModuleInvariants(w, 'uzcard+kaftpay');
      expect(receiptPart(w)['ReceivedCash'], 0);
      expect(receiptPart(w)['ReceivedCard'], 10000000);
      expect(extraOf(w)['CardType'], 2);
    });

    test('Click QR 20 000 + Kaftpay 80 000 — QR Other, Kaftpay karta', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '20000';
      p.allPaymentType(pay(ids.click, 'Click', type: 1));
      p.recordKaftpay(kaftpay, 80000);
      final r = receiptFromPage(p, rows);
      final w = wireOf(r);
      expectModuleInvariants(w, 'clickQr+kaftpay');
      expect(receiptPart(w)['ReceivedCard'], 8000000);
      expect(sumOf(w, 'Other'), 2000000);
      expect(paramsOf(r)['receivedClick'], false);
    });

    test('naqd + YagonaQr + Kaftpay (uchtasi)', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '20000';
      p.allPaymentType(pay(ids.cash, 'CASH'));
      p.controller.text = '30000';
      p.typeYagonaQr(pay(kYagonaId, 'YagonaQr'));
      p.recordKaftpay(kaftpay, 50000);
      final chek = chekOf(p);
      expect(chek.values.map((e) => e.name),
          unorderedEquals(['CASH', 'YAGONAQR', 'KAFTPAY']));
      final w = wireOf(receiptFromPage(p, rows));
      expectModuleInvariants(w, 'naqd+yagona+kaftpay');
      expect(receiptPart(w)['ReceivedCash'], 2000000);
      expect(receiptPart(w)['ReceivedCard'], 8000000);
      expect(extraOf(w)['CardType'], 2);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Fiskal JSON: faqat Kaftpay × savat', () {
    for (final cart in [...carts, scaleCart]) {
      test(cart.name, () {
        final rows = cart.rows();
        final r = saleWithKaftpay(rows, {}, kaftpayValue: cartTotal(rows));
        final w = wireOf(r);
        final why = 'Kaftpay / ${cart.name}';

        expectModuleInvariants(w, why);
        final rp = receiptPart(w);
        expect(rp['ReceivedCash'], 0, reason: why);
        expect(rp['ReceivedCard'], (r.payment.single.value * 100).round(),
            reason: why);
        expect(sumOf(w, 'Other'), 0, reason: '$why: Other 0');
        expect(extraOf(w)['CardType'], 2, reason: '$why: CardType');
        // Kaftpay QR provayder emas — ExtraInfo'da provayder yo'q.
        expect(extraOf(w)['QRPaymentProvider'], anyOf(0, isNull),
            reason: '$why: QRPaymentProvider');
        expectFlags(paramsOf(r), <Kind>{}, why);
        if (rows.any((x) => x.vatPercent > 0)) {
          expect(sumOf(w, 'VAT'), greaterThan(0), reason: '$why: VAT');
        }
      });
    }

    test('aniq raqamlar: 112 000 (12%) — ReceivedCard 11 200 000, VAT 12 000',
        () {
      final r =
          saleWithKaftpay([row(realPrice: 112000)], {}, kaftpayValue: 112000);
      final w = wireOf(r);
      expect(receiptPart(w)['ReceivedCard'], 11200000);
      expect(receiptPart(w)['ReceivedCash'], 0);
      expect(sumOf(w, 'Other'), 0);
      expect(sumOf(w, 'VAT'), closeTo(1200000, 100));
    });

    test('qog\'oz chek QQS\'i fiskal bilan bir xil', () {
      final r =
          saleWithKaftpay([row(realPrice: 112000)], {}, kaftpayValue: 112000);
      expect(ReceiptVat.total(r), closeTo(12000, 0.01));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Fiskal JSON: Kaftpay + har bir to\'lov turi (1/3 + 2/3)', () {
    for (final k in Kind.values) {
      test('${k.name} + Kaftpay', () {
        for (final cart in carts) {
          final rows = cart.rows();
          final double total = cartTotal(rows);
          final double first = (total / 3).floorToDouble();
          final amounts = {k: first};
          final r = saleWithKaftpay(rows, amounts, kaftpayValue: total - first);
          final w = wireOf(r);
          final why = '${k.name}+Kaftpay / ${cart.name}';
          expectModuleInvariants(w, why);
          expectBucketsWithKaftpay(w, amounts, total - first, why,
              rows: rows.length);
          expectFlags(paramsOf(r), {k}, why);
          expect(extraOf(w)['CardType'], 2, reason: why);
        }
      });
    }
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Fiskal JSON: murakkab holatlar', () {
    test('naqd 30 000 + Uzcard 20 000 + Kaftpay 50 000', () {
      final rows = [
        row(realPrice: 37500, value: 2, name: 'A'),
        row(realPrice: 25000, name: 'B'),
      ];
      final r = saleWithKaftpay(rows, {Kind.cash: 30000, Kind.uzcard: 20000},
          kaftpayValue: 50000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'naqd+karta+kaftpay');
      expect(receiptPart(w)['ReceivedCash'], 3000000);
      expect(receiptPart(w)['ReceivedCard'], 7000000);
      expect(sumOf(w, 'Other'), 0);
    });

    test('naqd qaytim: naqd 50 000 (qaytim 20 000) + Kaftpay 70 000', () {
      final r = saleWithKaftpay([row(realPrice: 100000)], {Kind.cash: 50000},
          kaftpayValue: 70000, sdacha: 20000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'sdacha');
      expect(receiptPart(w)['ReceivedCash'], 3000000);
      expect(receiptPart(w)['ReceivedCard'], 7000000);
    });

    test('cashback 10 000 + Kaftpay 90 000: Other = cashback', () {
      final r = saleWithKaftpay(
          [row(realPrice: 100000)], {Kind.cashback: 10000},
          kaftpayValue: 90000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'cashback+kaftpay');
      expect(receiptPart(w)['ReceivedCard'], 9000000);
      expect(sumOf(w, 'Other'), 1000000);
      expect(sumOf(w, 'VAT'), closeTo(90000 * 12 / 112 * 100, 100));
    });

    test(
        'Click Pass + Payme Go + Kaftpay: hammasi karta, bayroqlar faqat Pass/Go',
        () {
      final r = saleWithKaftpay(
          [row(realPrice: 90000)], {Kind.clickPass: 30000, Kind.paymeGo: 30000},
          kaftpayValue: 30000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'pass+go+kaftpay');
      expect(receiptPart(w)['ReceivedCard'], 9000000);
      expectFlags(
          paramsOf(r), {Kind.clickPass, Kind.paymeGo}, 'pass+go+kaftpay');
    });

    test('YagonaQr 40 000 + Kaftpay 60 000 — ikkalasi karta', () {
      final r = saleWithKaftpay([row(realPrice: 100000)], {},
          kaftpayValue: 60000, yagona: 40000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'yagona+kaftpay');
      expect(receiptPart(w)['ReceivedCard'], 10000000);
      expect(sumOf(w, 'Other'), 0);
    });

    test('hamma 11 tur + YagonaQr + Kaftpay bitta chekda', () {
      final rows = [
        row(realPrice: 140000, name: 'X'),
        row(realPrice: 55000, vatPercent: 0, name: 'Y'),
      ];
      final amounts = {for (final k in Kind.values) k: 15000.0};
      final r =
          saleWithKaftpay(rows, amounts, kaftpayValue: 15000, yagona: 15000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'hammasi');
      expectBucketsWithKaftpay(w, amounts, 30000, 'hammasi', rows: 2);
    });

    test('tarozi (yarim so\'m) + naqd + Kaftpay: §10.2.1 balans', () {
      final rows = scaleCart.rows();
      final total = cartTotal(rows);
      final r = saleWithKaftpay(rows, {Kind.cash: 10000},
          kaftpayValue: total - 10000);
      expectModuleInvariants(wireOf(r), 'tarozi');
    });

    test('vozvrat: Kaftpay chekining qaytarilishi — hammasi ReceivedCash', () {
      final r = receiptOf(
        [row(realPrice: 50000)],
        [
          ReceiptModelPaymentType4(
              name: 'KAFTPAY', payId: kKaftpayId, value: 50000)
        ],
        isRefund: true,
      );
      final w = wireOf(r);
      expectModuleInvariants(w, 'vozvrat');
      expect(receiptPart(w)['ReceivedCash'], 5000000);
      expect(receiptPart(w)['ReceivedCard'], 0);
    });
  });

  group('To\'lov turini tanish', () {
    test('ReceiptPayments: id bo\'lmasa nom o\'zgarmaydi', () {
      final list = ReceiptPayments.build(
        {kKaftpayId: Payment(id: kKaftpayId, name: 'Kaftpay', value: 10)},
        ids: ids,
        sdacha: 0,
        zdachaToCashBack: 0,
      );
      expect(list.single.name, 'Kaftpay');
    });

    test('WS type 40: "Kaftpay" nomi — id Pref\'ga, isAdded qutida', () async {
      await Pref.setString(PrefKeys.kaftpayId, '');
      final box = await Hive.openBox<Payment>('other_payments');
      await box.clear();
      await box.add(Payment(id: 'srv-kaft', name: 'Kaftpay', isAdded: false));
      await ProductsWsService.applyPaymentToggle(
          {'name': 'Kaftpay', 'id': 'srv-kaft', 'is_used': true});
      expect(Pref.getString(PrefKeys.kaftpayId, ''), 'srv-kaft');
      expect(otherPaymentsGlobal.firstWhere((e) => e.id == 'srv-kaft').isAdded,
          isTrue);
      await Pref.setString(PrefKeys.kaftpayId, kKaftpayId);
    });

    test('ishga tushishda id tiklanadi (tur qutida bor, Pref bo\'sh)',
        () async {
      await Pref.setString(PrefKeys.kaftpayId, '');
      final box = await Hive.openBox<Payment>('other_payments');
      await box.clear();
      await box.add(Payment(id: 'srv-kaft2', name: 'KAFT PAY', isAdded: true));
      await OrganizationSingleton.setOtherPayments();
      expect(Pref.getString(PrefKeys.kaftpayId, ''), 'srv-kaft2');
      await Pref.setString(PrefKeys.kaftpayId, kKaftpayId);
    });
  });
}
