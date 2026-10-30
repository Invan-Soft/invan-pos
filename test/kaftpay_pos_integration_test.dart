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
