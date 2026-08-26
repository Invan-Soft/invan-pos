// Chekka ketadigan to'lov turlari ro'yxati — `paymentsMapAsList`.
//
// Bu nomlar (CASH / UZCARD / HUMO / CASHBACK / DEBT / PAYME GO / PAYME QR /
// CLICK PASS / CLICK QR / UZUM / UZUM QR) FISKAL CHEKKA va serverga ketadi.
// Bittasi xato bo'lsa chek noto'g'ri to'lov turi bilan yozib qo'yiladi.
//
// Naqddan `sdacha` ayiriladi: kassir 120 000 bergan bo'lsa ham chekda
// tovarga ketgan 100 000 turishi kerak.
//
// Mavjud qamrov faqat uzunlik va yig'indini tekshirardi — nom xaritalashning
// bironta ham varianti sinalmagan edi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/receipt_payments.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kCashId = 'cash-id';
const kCardId = 'card-id';
const kDebtId = 'debt-id';
const kCashbackId = 'cashback-id';
const kPaymeId = 'payme-id';
const kClickId = 'click-id';
const kUzumId = 'uzum-id';

Payment pay(String id, {String name = 'Nomsiz', int type = 0, double? value}) =>
    Payment(id: id, name: name, title: name, type: type, enable: true, value: value);

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

/// `paymentsMap` ni to'g'ridan-to'g'ri qo'yib, chek ro'yxatini o'qiydi.
/// [key] — xaritadagi kalit (type 1 to'lovlar '@id' bilan saqlanadi).
ReceiptModelPaymentType4 single(String key, Payment payment,
    {double total = 100000}) {
  final p = paymentPage(total: total);
  p.paymentsMap = {key: payment};
  return p.paymentsMapAsList.single;
}

void main() {
  setUpAll(() async {
    await setUpPosTestEnv('receipt_payment_names_test');
    await Pref.setString(PrefKeys.cashId, kCashId);
    await Pref.setString(PrefKeys.cardId, kCardId);
    await Pref.setString(PrefKeys.debtId, kDebtId);
    await Pref.setString(PrefKeys.cashbackId, kCashbackId);
    await Pref.setString(PrefKeys.paymeId, kPaymeId);
    await Pref.setString(PrefKeys.clickId, kClickId);
    await Pref.setString(PrefKeys.uzumId, kUzumId);
  });
  tearDownAll(tearDownPosTestEnv);

  group('Nom xaritalash', () {
    test('naqd → CASH', () {
      expect(single(kCashId, pay(kCashId, value: 1000)).name, 'CASH');
    });

    test('karta (type 0) → UZCARD', () {
      expect(single(kCardId, pay(kCardId, value: 1000)).name, 'UZCARD');
    });

    test('karta (type 1) → HUMO', () {
      expect(single('@$kCardId', pay(kCardId, type: 1, value: 1000)).name,
          'HUMO');
    });

    test('cashback → CASHBACK', () {
      expect(single(kCashbackId, pay(kCashbackId, value: 1000)).name,
          'CASHBACK');
    });

    test('qarz → DEBT', () {
      expect(single(kDebtId, pay(kDebtId, value: 1000)).name, 'DEBT');
    });

    test('payme (type 0) → PAYME GO', () {
      expect(single(kPaymeId, pay(kPaymeId, value: 1000)).name, 'PAYME GO');
    });

    test('payme (type 1) → PAYME QR', () {
      expect(single('@$kPaymeId', pay(kPaymeId, type: 1, value: 1000)).name,
          'PAYME QR');
    });

    test('click (type 0) → CLICK PASS', () {
      expect(single(kClickId, pay(kClickId, value: 1000)).name, 'CLICK PASS');
    });

    test('click (type 1) → CLICK QR', () {
      expect(single('@$kClickId', pay(kClickId, type: 1, value: 1000)).name,
          'CLICK QR');
    });

    test('uzum (type 0) → UZUM', () {
      expect(single(kUzumId, pay(kUzumId, value: 1000)).name, 'UZUM');
    });

    test('uzum (type 1) → UZUM QR', () {
      expect(single('@$kUzumId', pay(kUzumId, type: 1, value: 1000)).name,
          'UZUM QR');
    });

    test('notanish id → to\'lovning O\'Z nomi qoladi', () {
      expect(single('boshqa-id', pay('boshqa-id', name: 'Terminal', value: 500))
          .name, 'Terminal');
    });

    test('notanish id va nomi yo\'q → bo\'sh string', () {
      final p = paymentPage();
      p.paymentsMap = {
        'x': Payment(id: 'x', type: 0, enable: true, value: 100)
      };
      expect(p.paymentsMapAsList.single.name, '');
    });

    test('QAYD: naqd kaliti "@" bilan kelsa CASH deb tanilmaydi', () {
      // CASH tekshiruvi `e.key` ni AYNAN solishtiradi (replaceFirst yo'q).
      expect(single('@$kCashId', pay(kCashId, name: 'Naqd', value: 100)).name,
          'Naqd');
    });
  });

  group('payId va qiymat', () {
    test('payId xaritadagi kalitni saqlaydi', () {
      expect(single('@$kCardId', pay(kCardId, type: 1, value: 1000)).payId,
          '@$kCardId');
    });

    test('qiymat butun songa yaxlitlanadi', () {
      expect(single(kCashId, pay(kCashId, value: 1000.4)).value, 1000);
      expect(single(kCashId, pay(kCashId, value: 1000.6)).value, 1001);
    });

    test('qiymati yo\'q to\'lov 0 bo\'ladi', () {
      expect(single(kCashId, pay(kCashId)).value, 0);
    });

    test('bir nechta to\'lov — hammasi ro\'yxatga tushadi', () {
      final p = paymentPage();
      p.paymentsMap = {
        kCashId: pay(kCashId, value: 40000),
        kCardId: pay(kCardId, value: 60000),
      };
      final list = p.paymentsMapAsList;
      expect(list.map((e) => e.name), ['CASH', 'UZCARD']);
      expect(list.map((e) => e.value).reduce((a, b) => a + b), 100000);
    });

    test('bo\'sh xarita → bo\'sh ro\'yxat', () {
      final p = paymentPage();
      p.paymentsMap = {};
      expect(p.paymentsMapAsList, isEmpty);
    });
  });

  group('Sdacha (qaytim) naqddan ayiriladi', () {
    test('120 000 berilib 100 000 lik chek → CASH qatori 100 000', () {
      final p = paymentPage(total: 100000);
      for (final ch in '120000'.split('')) {
        p.onNumPressed(int.parse(ch));
      }
      p.allPaymentType(pay(kCashId, name: 'Naqd'));

      expect(p.getSdacha, 20000);
      expect(p.paymentsMapAsList.single.name, 'CASH');
      expect(p.paymentsMapAsList.single.value, 100000);
    });

    test('sdacha yo\'q bo\'lsa qiymat o\'zgarmaydi', () {
      final p = paymentPage(total: 100000);
      for (final ch in '100000'.split('')) {
        p.onNumPressed(int.parse(ch));
      }
      p.allPaymentType(pay(kCashId, name: 'Naqd'));

      expect(p.getSdacha, 0);
      expect(p.paymentsMapAsList.single.value, 100000);
    });

    test('sdacha FAQAT naqd qatoridan ayiriladi', () {
      final p = paymentPage(total: 100000);
      p.paymentsMap = {
        kCardId: pay(kCardId, value: 60000),
        kCashId: pay(kCashId, value: 60000),
      };
      // sdacha hisoblanishi uchun naqd ustiga qo'shamiz
      for (final ch in '60000'.split('')) {
        p.onNumPressed(int.parse(ch));
      }
      p.allPaymentType(pay(kCashId, name: 'Naqd'));

      final card = p.paymentsMapAsList.firstWhere((e) => e.name == 'UZCARD');
      expect(card.value, 60000, reason: 'karta qatoriga tegilmaydi');
    });
  });

  group('ReceiptPayments — to\'g\'ridan-to\'g\'ri (providersiz)', () {
    const ids = PaymentIds(
      cash: kCashId,
      card: kCardId,
      cashback: kCashbackId,
      debt: kDebtId,
      payme: kPaymeId,
      click: kClickId,
      uzum: kUzumId,
    );

    List<ReceiptModelPaymentType4> build(
      Map<String, Payment> map, {
      double sdacha = 0,
      double toCashback = 0,
    }) =>
        ReceiptPayments.build(map,
            ids: ids, sdacha: sdacha, zdachaToCashBack: toCashback);

    test('zdachaToCashBack naqddan ayiriladi', () {
      final r = build({kCashId: pay(kCashId, value: 120000)},
          toCashback: 20000);
      expect(r.single.value, 100000);
    });

    test('sdacha va zdachaToCashBack BIRGA ayiriladi', () {
      final r = build({kCashId: pay(kCashId, value: 130000)},
          sdacha: 20000, toCashback: 10000);
      expect(r.single.value, 100000);
    });

    test('zdachaToCashBack faqat naqdga ta\'sir qiladi', () {
      final r = build({kCardId: pay(kCardId, value: 50000)},
          toCashback: 20000);
      expect(r.single.value, 50000);
    });

    test('manfiy qaytim (0 dan katta emas) ayirilmaydi', () {
      final r = build({kCashId: pay(kCashId, value: 50000)},
          sdacha: -10000, toCashback: -5000);
      expect(r.single.value, 50000);
    });

    test('ayirilgandan keyin manfiy qiymat ham qaytishi mumkin', () {
      final r = build({kCashId: pay(kCashId, value: 1000)}, sdacha: 3000);
      expect(r.single.value, -2000);
    });

    test('bo\'sh ID lar: hech narsa nomlanmaydi', () {
      const bosh = PaymentIds(
          cash: '', card: '', cashback: '', debt: '', payme: '', click: '',
          uzum: '');
      final r = ReceiptPayments.build(
          {'x': pay('x', name: 'Terminal', value: 100)},
          ids: bosh, sdacha: 0, zdachaToCashBack: 0);
      expect(r.single.name, 'Terminal');
    });

    test('tartib: QR varianti oddiy variantdan KEYIN qo\'llanadi', () {
      final r = build({'@$kUzumId': pay(kUzumId, type: 1, value: 100)});
      expect(r.single.name, 'UZUM QR',
          reason: 'avval UZUM qo\'yiladi, keyin QR ustidan yozadi');
    });

    test('xarita tartibi natijada saqlanadi', () {
      final r = build({
        kDebtId: pay(kDebtId, value: 1),
        kCashId: pay(kCashId, value: 2),
        kCardId: pay(kCardId, value: 3),
      });
      expect(r.map((e) => e.name), ['DEBT', 'CASH', 'UZCARD']);
    });
  });
}
