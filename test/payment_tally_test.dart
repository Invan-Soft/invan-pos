// To'lov arifmetikasi (payment tally) xarakteristik testi.
//
// MAQSAD: bu testlar hozirgi xatti-harakatni MUZLATADI. Ular Faza 3 da
// `paymentsMap` ustidagi hisob PaymentTallyController ga ko'chirilganda
// hech narsa o'zgarmaganini isbotlash uchun yozilgan.
//
// Qamrov: initPaymentPageValues, allPaymentType, onNumPressed,
// onBackSpacePressed, removeFromPaymentList, getAvailableSumma,
// getSelectedPaymentSumma, mustPay/sdacha/isButtonEnabled hisobi.
//
// MUHIM: bu yerda "to'g'rimi?" emas, "hozir nima bo'lyapti?" yoziladi.
// Shubhali xatti-harakat topilsa — izohda QAYD etiladi, tuzatilmaydi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/models/supplier_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kCashId = 'cash-id';
const kCardId = 'card-id';
const kDebtId = 'debt-id';
const kCashbackId = 'cashback-id';

/// `type: 1` bo'lgan to'lov turi paymentsMap'da '@id' kaliti bilan saqlanadi
/// (masalan Click/Payme), qolganlari oddiy id bilan.
Payment payment(String id, {String name = 'To\'lov', int type = 0}) =>
    Payment(id: id, name: name, title: name, type: type, enable: true);

/// To'lov sahifasi ochilgan holatni simulyatsiya qiladi.
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

/// Klaviaturada summa terish (onNumPressed raqamma-raqam ishlaydi).
void typeAmount(OrderingProvider4 p, String digits) {
  for (final ch in digits.split('')) {
    p.onNumPressed(int.parse(ch));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('payment_tally_test');
    await Pref.setString(PrefKeys.cashId, kCashId);
    await Pref.setString(PrefKeys.debtId, kDebtId);
    await Pref.setString(PrefKeys.cashbackId, kCashbackId);
  });
  tearDownAll(tearDownPosTestEnv);

  group('initPaymentPageValues — boshlang\'ich holat', () {
    test('mustPay = totalPrice, sdacha = 0, tugma o\'chiq', () {
      final p = paymentPage(total: 100000);

      expect(p.getTotalPaymentPrice, 100000);
      expect(p.getMustPay, 100000);
      expect(p.getSdacha, 0);
      expect(p.getIsButtonEnabled, isFalse);
      expect(p.paymentsMap, isEmpty);
    });

    test('qayta chaqirilsa avvalgi to\'lovlar tozalanadi', () {
      final p = paymentPage(total: 50000);
      p.allPaymentType(payment(kCardId));
      expect(p.paymentsMap, isNotEmpty);

      p.initPaymentPageValues(
        sixClientModel4: SixClientModel4(
          clientNumber: 1,
          lastAddedIndex: -1,
          orderedProducts: [],
          discountAmountFromNewClient: 0,
        ),
        totalPrice: 70000,
        discountAmount: 0,
      );

      expect(p.paymentsMap, isEmpty);
      expect(p.getMustPay, 70000);
      expect(p.getIsButtonEnabled, isFalse);
    });
  });

  group('allPaymentType — summa kiritilmagan (to\'liq to\'lash)', () {
    test('karta: butun qoldiq yopiladi, tugma yoqiladi', () {
      final p = paymentPage(total: 100000);

      p.allPaymentType(payment(kCardId));

      expect(p.paymentsMap[kCardId]?.value, 100000);
      expect(p.getMustPay, 0);
      expect(p.getSdacha, 0);
      expect(p.getIsButtonEnabled, isTrue);
    });

    test('type=1 to\'lov turi "@id" kaliti bilan saqlanadi', () {
      final p = paymentPage(total: 30000);

      p.allPaymentType(payment('click-id', type: 1));

      expect(p.paymentsMap.containsKey('@click-id'), isTrue);
      expect(p.paymentsMap['@click-id']?.value, 30000);
    });
  });

  group('allPaymentType — qisman summa kiritilgan', () {
    test('40000 kiritilsa faqat shuncha yoziladi, qoldiq 60000', () {
      final p = paymentPage(total: 100000);

      typeAmount(p, '40000');
      p.allPaymentType(payment(kCardId));

      expect(p.paymentsMap[kCardId]?.value, 40000);
      expect(p.getMustPay, 60000);
      expect(p.getIsButtonEnabled, isFalse);
      // Kiritish maydoni har to'lovdan keyin tozalanadi
      expect(p.controller.text, '0');
    });

    test('ikki xil to\'lov bilan bo\'lib to\'lash', () {
      final p = paymentPage(total: 100000);

      typeAmount(p, '30000');
      p.allPaymentType(payment(kCardId));
      typeAmount(p, '70000');
      p.allPaymentType(payment('humo-id'));

      expect(p.paymentsMap[kCardId]?.value, 30000);
      expect(p.paymentsMap['humo-id']?.value, 70000);
      expect(p.getMustPay, 0);
      expect(p.getIsButtonEnabled, isTrue);
    });

    test('kartada ortiqcha summa kiritilsa qoldiq bilan cheklanadi', () {
      final p = paymentPage(total: 50000);

      typeAmount(p, '80000');
      p.allPaymentType(payment(kCardId));

      // Naqd BO'LMAGAN to'lovda ortiqcha qabul qilinmaydi
      expect(p.paymentsMap[kCardId]?.value, 50000);
      expect(p.getSdacha, 0);
    });
  });

  group('Naqd to\'lov — ortiqcha qabul qilinadi (sdacha)', () {
    test('50000 lik xaridga 100000 naqd: sdacha 50000', () {
      final p = paymentPage(total: 50000);

      typeAmount(p, '100000');
      p.allPaymentType(payment(kCashId, name: 'Naqd'));

      expect(p.paymentsMap[kCashId]?.value, 100000);
      expect(p.getSdacha, 50000);
      expect(p.getMustPay, -50000);
      expect(p.getIsButtonEnabled, isTrue);
    });

    test('naqd summa kiritilmasa aynan qoldiq yoziladi', () {
      final p = paymentPage(total: 50000);

      p.allPaymentType(payment(kCashId, name: 'Naqd'));

      expect(p.paymentsMap[kCashId]?.value, 50000);
      expect(p.getSdacha, 0);
      expect(p.getIsButtonEnabled, isTrue);
    });
  });

  group('getAvailableSumma / getSelectedPaymentSumma', () {
    test('available tanlangan turdan boshqa to\'lovlarni chegiradi', () {
      final p = paymentPage(total: 100000);

      typeAmount(p, '30000');
      p.allPaymentType(payment(kCardId));

      // Endi naqdni tanlaymiz — available = 100000 - 30000 (karta)
      p.allPaymentType(payment(kCashId, name: 'Naqd'));

      expect(p.paymentsMap[kCashId]?.value, 70000);
      expect(p.getMustPay, 0);
    });

    test('bir turga ikki marta bosilsa summalar qo\'shiladi', () {
      final p = paymentPage(total: 100000);

      typeAmount(p, '20000');
      p.allPaymentType(payment(kCardId));
      typeAmount(p, '20000');
      p.allPaymentType(payment(kCardId));

      // Ikkinchi bosishda oldingi qiymat ustiga qo'shiladi (20000 + 20000)
      expect(p.paymentsMap[kCardId]?.value, 40000);
      expect(p.paymentsMap.length, 1);
    });
  });

  group('removeFromPaymentList', () {
    test('index tanlanmagan (-1): hamma to\'lov tozalanadi', () {
      final p = paymentPage(total: 100000);
      typeAmount(p, '30000');
      p.allPaymentType(payment(kCardId));
      typeAmount(p, '70000');
      p.allPaymentType(payment('humo-id'));

      p.removeFromPaymentList();

      expect(p.paymentsMap, isEmpty);
      expect(p.getMustPay, 100000);
      expect(p.getIsButtonEnabled, isFalse);
    });

    test('index tanlangan: faqat o\'sha to\'lov o\'chadi', () {
      final p = paymentPage(total: 100000);
      typeAmount(p, '30000');
      p.allPaymentType(payment(kCardId));
      typeAmount(p, '70000');
      p.allPaymentType(payment('humo-id'));

      p.selectPaymentIndex(0);
      p.removeFromPaymentList();

      expect(p.paymentsMap.containsKey(kCardId), isFalse);
      expect(p.paymentsMap['humo-id']?.value, 70000);
      expect(p.getMustPay, 30000);
      expect(p.getIsButtonEnabled, isFalse);
      expect(p.selectedPaymentIndex, -1);
    });
  });

  group('Klaviatura: onNumPressed / onBackSpacePressed', () {
    test('raqamlar formatlangan holda yig\'iladi', () {
      final p = paymentPage();

      typeAmount(p, '12345');

      expect(p.controller.text, '12,345');
    });

    test('boshidagi nol almashtiriladi', () {
      final p = paymentPage();

      p.onNumPressed(5);

      expect(p.controller.text, '5');
    });

    test('backspace oxirgi raqamni o\'chiradi', () {
      final p = paymentPage();
      typeAmount(p, '1500');

      p.onBackSpacePressed();

      expect(p.controller.text, '150');
    });

    test('bitta raqam qolganda backspace nolga qaytaradi', () {
      final p = paymentPage();
      p.onNumPressed(7);

      p.onBackSpacePressed();

      expect(p.controller.text, '0');
    });

    test('15 belgidan uzun kiritilmaydi', () {
      final p = paymentPage();
      final before = p.controller.text;

      typeAmount(p, '1234567890123456789');

      expect(p.controller.text.length, lessThanOrEqualTo(19));
      expect(p.controller.text, isNot(before));
    });
  });

  group('notifyListeners — UI qayta chizilishi (Faza 3 ning asosiy xavfi)', () {
    // To'lov hisobi PaymentTallyController ga ko'chirildi. Kontroller
    // ChangeNotifier EMAS — provider'ning notifyListeners ini callback
    // sifatida oladi. Bu ulanish uzilsa, summa o'zgaradi-yu ekranda eski
    // qiymat qolib ketardi — kassa uchun jiddiy xato.

    test('allPaymentType listenerni uyg\'otadi', () {
      final p = paymentPage(total: 50000);
      var notified = 0;
      p.addListener(() => notified++);

      p.allPaymentType(payment(kCardId));

      expect(notified, greaterThan(0));
    });

    test('removeFromPaymentList listenerni uyg\'otadi', () {
      final p = paymentPage(total: 50000);
      p.allPaymentType(payment(kCardId));

      var notified = 0;
      p.addListener(() => notified++);

      p.removeFromPaymentList();

      expect(notified, greaterThan(0));
    });

    test('selectPaymentIndex va changeTheSelectedPaymentIndex uyg\'otadi', () {
      final p = paymentPage(total: 50000);
      p.allPaymentType(payment(kCardId));

      var notified = 0;
      p.addListener(() => notified++);

      p.selectPaymentIndex(0);
      expect(notified, 1);

      p.changeTheSelectedPaymentIndex(false);
      expect(notified, 2);
    });

    test('onNumPressed uyg\'otadi (klaviatura fasadda qoldi)', () {
      final p = paymentPage();
      var notified = 0;
      p.addListener(() => notified++);

      p.onNumPressed(5);

      expect(notified, greaterThan(0));
    });
  });

  group('paymentsMapAsList — chekka ketadigan ko\'rinish', () {
    test('har to\'lov nomi va qiymati bilan ro\'yxatga aylanadi', () {
      final p = paymentPage(total: 100000);
      typeAmount(p, '40000');
      p.allPaymentType(payment(kCardId, name: 'Karta'));
      typeAmount(p, '60000');
      p.allPaymentType(payment(kCashId, name: 'Naqd'));

      final list = p.paymentsMapAsList;

      expect(list.length, 2);
      expect(list.map((e) => e.value).reduce((a, b) => a + b), 100000);
    });
  });

  // 2026-08-17: qarzdorsiz DEBT bug'i. Qarz tugmasi UI da faqat mijoz/supplier
  // bor bo'lsa ko'rinadi, lekin qarz QO'SHILGANDAN KEYIN qarzdor olib
  // tashlansa (Didox supplier DELETE, "mijoz topilmadi" qidiruvi) DEBT qatori
  // ro'yxatda qolib ketardi va sotuv mijozsiz qarzga yozilardi.
  group('Qarzdorsiz DEBT — qarzdor olib tashlanganda', () {
    ClientModel debtClient() => ClientModel(
          id: 'client-1',
          firstName: 'Ali',
          isAvailableForDebt: true,
        );

    SupplierModel innSupplier() => SupplierModel(
          id: 'supplier-1',
          supplierCompanyName: 'OOO Test',
          agreementNumber: const [],
          name: 'Test',
          phoneNumber: const [],
          externalId: '',
          status: '',
          contact: '',
          inn: '123456789',
          email: '',
        );

    test('supplier o\'chirilsa DEBT qatori ham ro\'yxatdan chiqadi', () {
      final p = paymentPage(total: 100000);
      p.setSelectedSupplierFromInnSearch(innSupplier());
      p.allPaymentType(payment(kDebtId, name: 'DEBT'));
      expect(p.paymentsMap.containsKey(kDebtId), isTrue);
      expect(p.getIsButtonEnabled, isTrue);

      p.setSelectedSupplierFromInnSearch(null);

      expect(p.paymentsMap.containsKey(kDebtId), isFalse);
      expect(p.getMustPay, 100000);
      expect(p.getIsButtonEnabled, isFalse);
      expect(p.isDebtSelectedWithoutDebtor, isFalse);
    });

    test('mijoz tozalansa (qidiruvda topilmadi) DEBT qatori chiqadi', () {
      final p = paymentPage(total: 100000);
      p.initClientByBloc(debtClient());
      p.allPaymentType(payment(kDebtId, name: 'DEBT'));
      expect(p.paymentsMap.containsKey(kDebtId), isTrue);

      p.initClientByBloc(null);

      expect(p.paymentsMap.containsKey(kDebtId), isFalse);
    });

    test('qarzdor qolgan bo\'lsa DEBT qatoriga tegilmaydi', () {
      final p = paymentPage(total: 100000);
      p.initClientByBloc(debtClient());
      p.allPaymentType(payment(kDebtId, name: 'DEBT'));

      // Supplier allaqachon yo'q edi — mijoz turibdi, qarz qolishi kerak.
      p.setSelectedSupplierFromInnSearch(null);

      expect(p.paymentsMap.containsKey(kDebtId), isTrue);
      expect(p.isDebtSelectedWithoutDebtor, isFalse);
    });

    test('qarz olishga ruxsati yo\'q mijozga almashtirilsa DEBT chiqadi', () {
      final p = paymentPage(total: 100000);
      p.initClientByBloc(debtClient());
      p.allPaymentType(payment(kDebtId, name: 'DEBT'));
      expect(p.paymentsMap.containsKey(kDebtId), isTrue);

      // Kassir mijozni almashtirdi — yangisiga qarz berish mumkin emas.
      p.initClientByBloc(ClientModel(
        id: 'client-2',
        firstName: 'Vali',
        isAvailableForDebt: false,
      ));

      expect(p.paymentsMap.containsKey(kDebtId), isFalse);
      expect(p.getMustPay, 100000);
    });

    test('faqat DEBT o\'chadi — naqd qatori joyida qoladi', () {
      final p = paymentPage(total: 100000);
      p.initClientByBloc(debtClient());
      typeAmount(p, '40000');
      p.allPaymentType(payment(kCashId, name: 'CASH'));
      p.allPaymentType(payment(kDebtId, name: 'DEBT'));
      expect(p.paymentsMap.length, 2);

      p.initClientByBloc(null);

      expect(p.paymentsMap.containsKey(kCashId), isTrue);
      expect(p.paymentsMap[kCashId]!.value, 40000);
      expect(p.paymentsMap.containsKey(kDebtId), isFalse);
      expect(p.getMustPay, 60000);
    });

    test('isDebtSelectedWithoutDebtor — qarzdorsiz qolgan DEBT ni aniqlaydi',
        () {
      final p = paymentPage(total: 100000);
      // Qarzdorsiz DEBT holatini to'g'ridan-to'g'ri quramiz (so'nggi to'siq
      // shu holatda sotuvni bloklaydi).
      p.paymentsMap = {kDebtId: payment(kDebtId, name: 'DEBT')};
      expect(p.isDebtSelectedWithoutDebtor, isTrue);

      p.initClientByBloc(debtClient());
      expect(p.isDebtSelectedWithoutDebtor, isFalse);
    });
  });

  // 2026-08-17: qarz bug'i bilan bir xil sinf. Cashback summasi AYNAN tanlangan
  // mijozning balansiga qarab tekshiriladi; mijoz o'zgarsa qator qolib ketardi
  // va chek "bonus bilan to'landi" bo'lib ketardi-yu, balans kamaymasdi
  // (`pay_by_loyalty/{client_id}` bo'sh id bilan xato beradi).
  group('Mijozsiz CASHBACK — mijoz o\'zgarganda', () {
    ClientModel clientA() => ClientModel(id: 'client-A', firstName: 'Ali');
    ClientModel clientB() => ClientModel(id: 'client-B', firstName: 'Vali');

    test('mijoz o\'chirilsa cashback qatori ham chiqadi', () {
      final p = paymentPage(total: 100000);
      p.initClientByBloc(clientA());
      typeAmount(p, '30000');
      p.allPaymentType(payment(kCashbackId, name: 'CASHBACK'));
      expect(p.paymentsMap.containsKey(kCashbackId), isTrue);

      p.initClientByBloc(null);

      expect(p.paymentsMap.containsKey(kCashbackId), isFalse);
      expect(p.getMustPay, 100000);
      expect(p.isCashbackSelectedWithoutClient, isFalse);
    });

    test('boshqa mijozga almashtirilsa cashback qatori chiqadi', () {
      final p = paymentPage(total: 100000);
      p.initClientByBloc(clientA());
      typeAmount(p, '30000');
      p.allPaymentType(payment(kCashbackId, name: 'CASHBACK'));

      // B ning balansi boshqa — A ning balansiga qarab tekshirilgan summa
      // B ga o'tib ketmasligi kerak.
      p.initClientByBloc(clientB());

      expect(p.paymentsMap.containsKey(kCashbackId), isFalse);
    });

    test('o\'sha mijoz qayta o\'rnatilsa cashback qatoriga tegilmaydi', () {
      final p = paymentPage(total: 100000);
      p.initClientByBloc(clientA());
      typeAmount(p, '30000');
      p.allPaymentType(payment(kCashbackId, name: 'CASHBACK'));

      p.initClientByBloc(clientA());

      expect(p.paymentsMap.containsKey(kCashbackId), isTrue);
      expect(p.paymentsMap[kCashbackId]!.value, 30000);
    });

    test('faqat CASHBACK o\'chadi — naqd qatori joyida qoladi', () {
      final p = paymentPage(total: 100000);
      p.initClientByBloc(clientA());
      typeAmount(p, '40000');
      p.allPaymentType(payment(kCashId, name: 'CASH'));
      typeAmount(p, '30000');
      p.allPaymentType(payment(kCashbackId, name: 'CASHBACK'));
      expect(p.paymentsMap.length, 2);

      p.initClientByBloc(null);

      expect(p.paymentsMap.containsKey(kCashId), isTrue);
      expect(p.paymentsMap[kCashId]!.value, 40000);
      expect(p.paymentsMap.containsKey(kCashbackId), isFalse);
      expect(p.getMustPay, 60000);
    });

    test('isCashbackSelectedWithoutClient — mijozsiz qolgan qatorni aniqlaydi',
        () {
      final p = paymentPage(total: 100000);
      p.paymentsMap = {kCashbackId: payment(kCashbackId, name: 'CASHBACK')};
      expect(p.isCashbackSelectedWithoutClient, isTrue);

      p.initClientByBloc(clientA());
      expect(p.isCashbackSelectedWithoutClient, isFalse);
    });
  });
}
