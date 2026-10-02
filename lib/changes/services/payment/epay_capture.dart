// Elektron to'lov ID'larining global manbalari (servis maydonlari va Pref)
// bilan `ReceiptEpay` o'rtasidagi ko'prik.
//
// - [reset] — to'lov sahifasi ochilganda (`initPaymentPageValues`): oldingi
//   sotuvdan qolgan ID hech qachon yangi chekka tushmasin. `paymentsMap` ham
//   shu yerda tozalanadi, ya'ni yangi Pass to'lov baribir qaytadan qilinadi.
// - [forReceipt] — chek yig'ilgan zahoti: shu chekdagi Pass/Go to'lovlarining
//   ID'larini chekka yozish uchun JSON.

import 'package:invan2/changes/domain/receipt/receipt_epay.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/changes/services/payment/paynet_service.dart';
import 'package:invan2/changes/services/payment/uzum_service.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class EpayCapture {
  const EpayCapture._();

  /// `ReceiptModel4.epayJson` uchun qiymat (Pass/Go yo'q bo'lsa null).
  static String? forReceipt(ReceiptModel4 receipt) => ReceiptEpay.capture(
        receipt: receipt,
        clickId: Pref.getString(PrefKeys.clickId, ''),
        paymeId: Pref.getString(PrefKeys.paymeId, ''),
        uzumId: Pref.getString(PrefKeys.uzumId, ''),
        paynetId: Pref.getString(PrefKeys.paynetId, ''),
        clickPaymentId: ClickService.paymentId,
        paymeReceiptId: Pref.getString('p_id', ''),
        uzumPaymentId: UzumService.paymentId,
        paynetPaymentId: PaynetService.paymentId,
        lastProvider: Pref.getInt('epayPay_Id', 0),
        lastPhone: Pref.getString('epay_phone', ''),
      ).encode();

  /// Yangi to'lov sessiyasi — oldingi to'lov ID'lari unutiladi.
  static void reset() {
    ClickService.paymentId = null;
    UzumService.paymentId = null;
    PaynetService.paymentId = null;
    // Faqat qiymat bor bo'lsa yoziladi — to'lov sahifasi har ochilganda
    // diskka bekorga yozilmasin.
    for (final String key in const ['p_id', 'epay_Id', 'epay_phone']) {
      if (Pref.getString(key, '').isNotEmpty) Pref.setString(key, '');
    }
    if (Pref.getInt('epayPay_Id', 0) != 0) Pref.setInt('epayPay_Id', 0);
  }
}
