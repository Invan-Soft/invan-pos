// Chekka ketadigan to'lov turlari ro'yxati.
//
// `paymentsMap` (UI ishlatadigan ko'rinish) fiskal chek va server kutadigan
// ko'rinishga aylantiriladi. Ikki ish bajariladi:
//   1. NOM normallashtiriladi — kassa sozlamasidagi to'lov IDsiga qarab
//      CASH / UZCARD / HUMO / CASHBACK / DEBT / PAYME GO / PAYME QR /
//      CLICK PASS / CLICK QR / UZUM / UZUM QR
//   2. Naqd qatoridan QAYTIM ayiriladi — kassir 120 000 bergan bo'lsa ham
//      chekda tovarga ketgan 100 000 turishi kerak
//
// `type: 1` bo'lgan to'lovlar xaritada '@id' kaliti bilan yotadi (QR
// variantlari), shuning uchun taqqoslashda '@' olib tashlanadi. Naqd esa
// AYNAN solishtiriladi — bu asl xatti-harakat.
//
// `OrderingProvider4.paymentsMapAsList` dan ajratildi — qoidalar o'zgarmagan.

import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

/// Kassa sozlamasidagi to'lov turlarining IDlari.
class PaymentIds {
  const PaymentIds({
    required this.cash,
    required this.card,
    required this.cashback,
    required this.debt,
    required this.payme,
    required this.click,
    required this.uzum,
  });

  final String cash;
  final String card;
  final String cashback;
  final String debt;
  final String payme;
  final String click;
  final String uzum;
}

class ReceiptPayments {
  const ReceiptPayments._();

  /// [sdacha] va [zdachaToCashBack] — naqd qatoridan ayiriladigan qaytim.
  static List<ReceiptModelPaymentType4> build(
    Map<String, Payment> paymentsMap, {
    required PaymentIds ids,
    required double sdacha,
    required double zdachaToCashBack,
  }) {
    return paymentsMap.entries.map((e) {
      final String bare = e.key.replaceFirst('@', '');
      String name = e.value.name ?? '';
      double paymentValue = e.value.value ?? 0;

      if (e.key == ids.cash) name = 'CASH';

      if (bare == ids.card) name = 'UZCARD';
      if (bare == ids.card && e.value.type == 1) name = 'HUMO';

      if (e.key == ids.cashback) name = 'CASHBACK';
      if (e.key == ids.debt) name = 'DEBT';

      if (sdacha > 0 && e.key == ids.cash) paymentValue -= sdacha;
      if (zdachaToCashBack > 0 && e.key == ids.cash) {
        paymentValue -= zdachaToCashBack;
      }

      if (bare == ids.payme) name = 'PAYME GO';
      if (bare == ids.click) name = 'CLICK PASS';
      if (bare == ids.uzum) name = 'UZUM';

      if (bare == ids.payme && e.value.type == 1) name = 'PAYME QR';
      if (bare == ids.click && e.value.type == 1) name = 'CLICK QR';
      if (bare == ids.uzum && e.value.type == 1) name = 'UZUM QR';

      paymentValue = double.parse(paymentValue.round().toStringAsFixed(3));
      return ReceiptModelPaymentType4(
        name: name,
        payId: e.key,
        value: paymentValue,
      );
    }).toList();
  }
}
