// Chek QQS'i va to'lov tasnifi — fiskal (`ReceiptSingleton4.saleOnOFD`) bilan
// BIR XIL qoida, bitta joyda.
//
// Nega kerak (2026-09-24): 100% cashback bilan to'langan chekda fiskalga
// `VAT 0` ketardi (cashback — xaridordan olinmagan do'kon bonusi, fiskal
// `Other` maydoni), qog'oz chek esa "sh.j QQS" ni chegirmali narxdan 12%
// qilib ko'rsatardi. Endi ikkisi bir manbadan hisoblanadi:
//
//   qator QQS = (narx × miqdor − qatorga tushgan cashback ulushi) × p / (100 + p)
//
// Ulush fiskal `_countOtherOFD` bilan aynan bir xil taqsimlanadi (chegirmali
// qator summasining chek jamisidagi nisbati, so'mga yaxlitlab).
//
// Click Pass / Payme Go (2026-09-30): ilova integratsiyasi orqali olingan
// haqiqiy beznal pul → fiskal `ReceivedCard`, QQS to'liq (rasmiy talab,
// docs/fiskal-tolov-turlari-va-qqs.md §2.2). Qog'oz chek bilan mos.
// Click QR / Payme QR (qo'lda belgilanadigan, `@id`) va Uzum (Pass ham, QR
// ham) — o'zgarishsiz `Other` (QQS 0). Qog'oz chekda ular ayrilMAYDI.
//
// Testlar: test/receipt_vat_test.dart

import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/util_functions.dart';

/// Chek to'lovlarining fiskal tasnifi (so'mda).
class FiscalPaymentSplit {
  /// Naqd → fiskal `ReceivedCash`.
  final double cash;

  /// Karta (Uzcard/Humo/terminal, noma'lum turlar) → fiskal `ReceivedCard`.
  final double card;

  /// Do'kon bonusi (cashback) — xaridordan olinmagan pul → fiskal `Other`.
  final double cashback;

  /// Click QR / Payme QR / Uzum — fiskal `Other` (yuqoridagi izoh).
  /// Click Pass / Payme Go bu yerga emas, [card] ga tushadi.
  final double epay;

  const FiscalPaymentSplit({
    required this.cash,
    required this.card,
    required this.cashback,
    required this.epay,
  });

  /// QR varianti: to'lov ekranida qo'lda belgilangan (`type: 1` → payId
  /// '@id', nomi 'CLICK QR' / 'PAYME QR' / 'UZUM QR'). Serverdan qaytgan
  /// chekda '@' olib tashlangan bo'lishi mumkin — shuning uchun nom ham.
  static bool isQr(ReceiptModelPaymentType4 p) =>
      p.payId.trim().startsWith('@') || p.name.toUpperCase().contains('QR');

  /// Chekda [providerId] ning Pass/Go (integratsiya orqali) to'lovi bormi.
  /// Fiskal chek URL'i provayderga (Click/Payme/Uzum) faqat shunda qaytariladi:
  /// QR variantida provayder to'lov ID'si yo'q (yoki oldingi to'lovdan qolgan).
  static bool hasPass(ReceiptModel4 receipt, String providerId) {
    if (providerId.isEmpty) return false;
    return receipt.payment.any(
      (p) => p.payId.replaceFirst('@', '').trim() == providerId && !isQr(p),
    );
  }

  /// `saleOnOFD` dagi qoida: vozvratda hammasi naqd; sotuvda avval nom,
  /// keyin adminka ID bo'yicha; hech qaysiga tushmasa — karta.
  static FiscalPaymentSplit of(ReceiptModel4 receipt) {
    double cash = 0, card = 0, cashback = 0, epay = 0;

    if (receipt.isRefund) {
      // Vozvrat: to'lov turidan qat'iy nazar hammasi CASH orqali qaytariladi
      for (final p in receipt.payment) {
        cash += p.value;
      }
      return FiscalPaymentSplit(cash: cash, card: 0, cashback: 0, epay: 0);
    }

    final clickId = Pref.getString(PrefKeys.clickId, "");
    final uzumId = Pref.getString(PrefKeys.uzumId, "");
    final paymeId = Pref.getString(PrefKeys.paymeId, "");
    final cashId = Pref.getString(PrefKeys.cashId, "cash");
    final cashbackId = Pref.getString(PrefKeys.cashbackId, "cash");
    final cardId = Pref.getString(PrefKeys.cardId, '');

    for (final p in receipt.payment) {
      final nameUpper = p.name.toUpperCase().trim();
      final id = p.payId.replaceFirst('@', '').trim();

      if (nameUpper == 'CASH' || id == cashId) {
        cash += p.value;
      } else if (nameUpper == 'CARD' ||
          nameUpper == 'UZCARD' ||
          nameUpper == 'HUMO' ||
          id == cardId) {
        card += p.value;
      } else if (id == cashbackId) {
        cashback += p.value;
      } else if ((id == clickId && nameUpper.contains('CLICK')) ||
          (id == paymeId && nameUpper.contains('PAYME'))) {
        // Pass / Go — beznal (karta), QR — Other
        if (isQr(p)) {
          epay += p.value;
        } else {
          card += p.value;
        }
      } else if (id == uzumId && nameUpper.contains('UZUM')) {
        epay += p.value;
      } else {
        // Boshqa barcha holatlar (xavfsizlik uchun) → CARD
        card += p.value;
      }
    }
    return FiscalPaymentSplit(
        cash: cash, card: card, cashback: cashback, epay: epay);
  }
}

/// Chek qatorlari QQS'i — fiskal `VAT` bilan bir xil baza.
class ReceiptVat {
  const ReceiptVat._();

  /// Qatorga tushadigan "Other" ulushi (so'mda), fiskal `_countOtherOFD`
  /// bilan aynan bir xil: chegirmali qator summasining chek jamisidagi
  /// nisbati, so'mga yaxlitlab. [receiptTotal] — `getOfdTotalPrice`.
  static double otherShare(
    ReceiptModelSoldItem4 row, {
    required double otherTotal,
    required double receiptTotal,
  }) {
    if (otherTotal == 0 || receiptTotal == 0) return 0;
    final double share =
        otherTotal * ((((row.price * row.value) * 100) / receiptTotal) / 100);
    return UtilFunctions.roundToNearest(share);
  }

  /// Qator QQS'i (so'mda): (narx × [qty] − [other]) × p / (100 + p).
  /// [qty] berilmasa qatorning to'liq miqdori. Manfiy chiqsa 0.
  static double lineVat(
    ReceiptModelSoldItem4 row, {
    num? qty,
    double other = 0,
  }) {
    final num q = qty ?? row.value;
    final double base = row.price * q - other;
    if (base <= 0 || row.vatPercent == 0) return 0;
    return base * row.vatPercent / (100 + row.vatPercent);
  }

  /// Qog'oz chekda bazadan ayriladigan summa: faqat cashback (fiskal kabi
  /// butun so'mga yaxlitlab). Vozvratda 0 — fiskalda ham `Other` yo'q.
  static double paperOtherTotal(ReceiptModel4 receipt) {
    if (receipt.isRefund) return 0;
    return FiscalPaymentSplit.of(receipt).cashback.roundToDouble();
  }

  /// Har qator QQS'i (so'mda), `soldItemList` tartibida.
  static List<double> perLine(ReceiptModel4 receipt) {
    final rows = receipt.soldItemList;
    final double other = paperOtherTotal(receipt);
    final double total = ItemsSingleton.getOfdTotalPrice(rows);
    return [
      for (final r in rows)
        lineVat(r,
            other: otherShare(r, otherTotal: other, receiptTotal: total)),
    ];
  }

  /// Chek bo'yicha jami QQS (so'mda) — "shu jumladan QQS".
  static double total(ReceiptModel4 receipt) =>
      perLine(receipt).fold<double>(0, (a, b) => a + b);
}
