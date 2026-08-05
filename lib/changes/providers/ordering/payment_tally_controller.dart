// To'lov hisobi (tally): `paymentsMap` ustidagi arifmetika.
//
// OrderingProvider4 dan ajratildi (2026-08-05) — tanalar o'zgartirilmadi.
// Bu zona SAVATGA bog'liq emas: savat jami narxi bir marta `totalPrice`
// sifatida beriladi, keyin barcha hisob shu son ustida boradi.
//
// BU YERGA KIRMAYDI (ataylab): pressPaymentButton, pressPaymentButtonOnlyOFD,
// typeUzcard/typeHumo/typeClick/typePayme/typeUzum/typePaynet — ular tarmoq,
// fiskal modul va dialoglar bilan ishlaydi.
//
// MUHIM — bu sinf ATAYLAB `ChangeNotifier` EMAS (Faza 2 dagi kabi).
// Konstruktorda `notify` callback oladi; aks holda OrderingProvider4 ni
// tinglayotgan UI qayta chizilmay qolardi.
//
// Testlar: test/payment_tally_test.dart

import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class PaymentTallyController {
  PaymentTallyController(this._notify);

  final void Function() _notify;

  /// Kiritilgan to'lovlar. Kalit: `type == 1` bo'lsa '@id', aks holda id.
  /// Public — UI to'g'ridan-to'g'ri o'qiydi (payment/left/left.dart va b.).
  Map<String, Payment> paymentsMap = {};

  /// Joriy tanlangan to'lov turi kaliti.
  String? selectedPaymentType;

  /// Ro'yxatdagi tanlangan qator indeksi (-1 = tanlanmagan).
  int selectedPaymentIndex = -1;

  /// Savat jami narxi. `late` — to'lov sahifasi ochilmasdan o'qilsa xato
  /// beradi (asl xatti-harakat shunday edi, saqlab qolindi).
  late num totalPrice;

  double mustPay = 0;
  double sdacha = 0;
  double zdachaToCashBack = 0;
  bool isButtonEnabled = false;

  void checkButtonIsEnable() {
    num currentMoney = 0;
    paymentsMap.forEach(
      (key, value) {
        currentMoney += value.value ?? 0;
      },
    );
    mustPay = totalPrice - currentMoney + zdachaToCashBack;

    sdacha = (currentMoney - totalPrice).roundToDouble();

    if (mustPay > 0) {
      isButtonEnabled = false;
    } else {
      isButtonEnabled = true;
    }

    _notify();
  }

  double getAvailableSumma() {
    double paid = 0;
    paymentsMap.forEach((key, payment) {
      if (key != selectedPaymentType) {
        paid += payment.value ?? 0;
      }
    });
    double a = totalPrice - paid;
    return a;
  }

  double getSelectedPaymentSumma() {
    double paid = 0;
    paymentsMap.forEach((key, payment) {
      if (key == selectedPaymentType) {
        paid += payment.value ?? 0;
      }
    });
    return paid;
  }

  void payByAll(double v, Payment payment) {
    final updatedPayment = Payment(
      id: payment.id,
      name: payment.name,
      title: payment.title,
      enable: payment.enable,
      isAdded: payment.isAdded,
      merchantId: payment.merchantId,
      merchantUserId: payment.merchantUserId,
      password: payment.password,
      secretKey: payment.secretKey,
      serviceId: payment.serviceId,
      type: payment.type,
      value: v,
    );

    String key = updatedPayment.type == 1
        ? '@${updatedPayment.id}'
        : updatedPayment.id ?? '';

    paymentsMap = {
      ...paymentsMap,
      key: updatedPayment,
    };

    checkButtonIsEnable();
    _notify();
  }

  void removeFromPaymentList() {
    if (selectedPaymentIndex >= 0 && paymentsMap.isNotEmpty) {
      final paymentKeyList = paymentsMap.keys.toList();
      if (selectedPaymentIndex < paymentKeyList.length) {
        final selectedPaymentKey = paymentKeyList[selectedPaymentIndex];

        if (selectedPaymentKey == Pref.getString(PrefKeys.debtId, '')) {
          Pref.setBool(PrefKeys.debtClick, false);
        }

        paymentsMap.remove(selectedPaymentKey);
      }

      selectedPaymentIndex = -1;
    } else {
      paymentsMap.clear();
      selectedPaymentIndex = -1;
      Pref.setBool(PrefKeys.debtClick, false);
    }

    checkButtonIsEnable();
    _notify();
  }

  void selectPaymentIndex(int v) {
    selectedPaymentIndex = v;
    _notify();
  }

  void changeTheSelectedPaymentIndex(bool up) {
    if (!up) {
      if (selectedPaymentIndex < paymentsMap.length - 1) {
        selectedPaymentIndex++;
      } else {
        selectedPaymentIndex = 0;
      }
    } else {
      if (selectedPaymentIndex <= 0) {
        selectedPaymentIndex = paymentsMap.length - 1;
      } else {
        selectedPaymentIndex--;
      }
    }
    _notify();
  }
}
