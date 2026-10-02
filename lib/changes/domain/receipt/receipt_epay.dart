// Chekning elektron to'lov (Click Pass / Payme Go / Uzum / Paynet) ma'lumoti.
//
// Nega kerak (2026-10-02): ilgari bu ma'lumot chekda emas, global joyda
// turardi — `ClickService.paymentId`, `UzumService.paymentId`,
// `PaynetService.paymentId` (xotirada) va Pref `epay_Id` / `epayPay_Id` /
// `epay_phone` / `p_id`. Natijada:
//   1. Fiskal `ExtraInfo` (QRPaymentProvider / QRPaymentID / PhoneNumber)
//      oldingi to'lovdan qolgan qiymat bilan ketardi — hatto naqd chekda ham
//      (Click'ning `submit_qrcode` javobi Pref'ni tozalashdan KEYIN qayta
//      yozardi; fiskal yiqilsa Pref umuman tozalanmasdi).
//   2. Cheklar ro'yxatidan fiskalga qayta yuborilgan (PreOfd) Pass chekida
//      provayderga (Click/Payme/Uzum/Paynet) o'sha chekning emas, xotiradagi
//      oxirgi to'lov ID'si ketardi (dastur qayta ochilgan bo'lsa — bo'sh).
//
// Endi chek yaratilgan zahoti ([capture]) shu chekdagi Pass/Go to'lovlarining
// ID'lari chekka (`ReceiptModel4.epayJson`) yoziladi va fiskal body ham,
// provayderga yuborish ham faqat shu yerdan o'qiydi.
//
// Testlar: test/receipt_epay_test.dart, test/epay_fiscal_matrix_test.dart

import 'dart:convert';

import 'package:invan2/changes/domain/receipt/receipt_vat.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

/// Fiskal chek URL'i qaytariladigan provayder.
enum EpayTarget { click, payme, uzum, paynet }

class ReceiptEpay {
  const ReceiptEpay({
    this.qrPaymentProvider = 0,
    this.qrPaymentId = '',
    this.phoneNumber = '',
    this.clickPaymentId = '',
    this.paymeReceiptId = '',
    this.uzumPaymentId = '',
    this.paynetPaymentId,
  });

  /// Fiskal `ExtraInfo.QRPaymentProvider` kodlari.
  static const int clickProvider = 64;
  static const int paymeProvider = 141;
  static const int uzumProvider = 161;

  static const ReceiptEpay empty = ReceiptEpay();

  /// Fiskal `ExtraInfo` — 0 / bo'sh: elektron Pass to'lov yo'q.
  final int qrPaymentProvider;
  final String qrPaymentId;
  final String phoneNumber;

  /// Provayderga fiskal chek URL'ini qaytarish uchun — bo'sh bo'lsa
  /// yuborilmaydi (noto'g'ri ID bilan yuborishdan ko'ra yubormagan yaxshi).
  final String clickPaymentId;
  final String paymeReceiptId;
  final String uzumPaymentId;
  final int? paynetPaymentId;

  bool get isEmpty =>
      qrPaymentProvider == 0 &&
      qrPaymentId.isEmpty &&
      phoneNumber.isEmpty &&
      clickPaymentId.isEmpty &&
      paymeReceiptId.isEmpty &&
      uzumPaymentId.isEmpty &&
      paynetPaymentId == null;

  /// Chek yaratilayotgan paytdagi manbalardan faqat SHU chekdagi to'lovlarga
  /// tegishlisini oladi. Manbalar (servis/Pref qiymatlari) chaqiruvchidan
  /// beriladi — bu klass global holatni o'qimaydi.
  ///
  /// - Click/Payme/Uzum ID'si faqat chekda o'sha provayderning Pass/Go
  ///   to'lovi bo'lsa (QR — qo'lda belgilanadi, provayder ID'si yo'q).
  /// - Paynet ID'si chekda Paynet to'lovi bo'lsa (Pass ham, QR ham —
  ///   `receivedPaynet` bilan bir xil qoida).
  /// - ExtraInfo: chekdagi Pass/Go provayderi. Bir nechta bo'lsa — eng oxirgi
  ///   to'langani ([lastProvider], Pref `epayPay_Id`), aniqlanmasa Click →
  ///   Payme → Uzum tartibida birinchisi. Telefon faqat [lastProvider] shu
  ///   provayder bo'lsa (u boshqa provayderniki bo'lishi mumkin).
  static ReceiptEpay capture({
    required ReceiptModel4 receipt,
    required String clickId,
    required String paymeId,
    required String uzumId,
    required String paynetId,
    String? clickPaymentId,
    String? paymeReceiptId,
    String? uzumPaymentId,
    int? paynetPaymentId,
    int lastProvider = 0,
    String lastPhone = '',
  }) {
    if (receipt.isRefund) return empty;

    String pick(String providerId, String? value) =>
        FiscalPaymentSplit.hasPass(receipt, providerId)
            ? (value ?? '').trim()
            : '';

    final String click = pick(clickId, clickPaymentId);
    final String payme = pick(paymeId, paymeReceiptId);
    final String uzum = pick(uzumId, uzumPaymentId);

    final bool hasPaynet = paynetId.isNotEmpty &&
        receipt.payment
            .any((p) => p.payId.replaceFirst('@', '').trim() == paynetId);
    final int? paynet =
        hasPaynet && paynetPaymentId != null && paynetPaymentId > 0
            ? paynetPaymentId
            : null;

    final Map<int, String> present = <int, String>{
      if (click.isNotEmpty) clickProvider: click,
      if (payme.isNotEmpty) paymeProvider: payme,
      if (uzum.isNotEmpty) uzumProvider: uzum,
    };
    int provider = 0;
    if (present.containsKey(lastProvider)) {
      provider = lastProvider;
    } else if (present.isNotEmpty) {
      provider = present.keys.first;
    }

    return ReceiptEpay(
      qrPaymentProvider: provider,
      qrPaymentId: present[provider] ?? '',
      phoneNumber: provider != 0 && provider == lastProvider ? lastPhone : '',
      clickPaymentId: click,
      paymeReceiptId: payme,
      uzumPaymentId: uzum,
      paynetPaymentId: paynet,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'qrPaymentProvider': qrPaymentProvider,
        'qrPaymentId': qrPaymentId,
        'phoneNumber': phoneNumber,
        'clickPaymentId': clickPaymentId,
        'paymeReceiptId': paymeReceiptId,
        'uzumPaymentId': uzumPaymentId,
        if (paynetPaymentId != null) 'paynetPaymentId': paynetPaymentId,
      };

  factory ReceiptEpay.fromJson(Map<String, dynamic> json) => ReceiptEpay(
        qrPaymentProvider: (json['qrPaymentProvider'] as num?)?.toInt() ?? 0,
        qrPaymentId: '${json['qrPaymentId'] ?? ''}',
        phoneNumber: '${json['phoneNumber'] ?? ''}',
        clickPaymentId: '${json['clickPaymentId'] ?? ''}',
        paymeReceiptId: '${json['paymeReceiptId'] ?? ''}',
        uzumPaymentId: '${json['uzumPaymentId'] ?? ''}',
        paynetPaymentId: (json['paynetPaymentId'] as num?)?.toInt(),
      );

  /// Fiskal muvaffaqiyatli bo'lgach fiskal chek URL'i qaysi provayderlarga
  /// qaytariladi. [params] — `saleOnOFD` body'sining `params` qismi
  /// (`receivedClick` va h.k. — faqat Pass/Go'da true). Bayroq bo'lsa-yu,
  /// chekda ID bo'lmasa (yangilanishdan oldingi chek) — yuborilmaydi:
  /// boshqa to'lov ID'si bilan yuborishdan ko'ra yubormagan to'g'ri.
  Set<EpayTarget> targets(Map<String, dynamic> params) => <EpayTarget>{
        if (params['receivedClick'] == true && clickPaymentId.isNotEmpty)
          EpayTarget.click,
        if (params['receivedPayme'] == true && paymeReceiptId.isNotEmpty)
          EpayTarget.payme,
        if (params['receivedUzum'] == true && uzumPaymentId.isNotEmpty)
          EpayTarget.uzum,
        if (params['receivedPaynet'] == true && paynetPaymentId != null)
          EpayTarget.paynet,
      };

  /// `ReceiptModel4.epayJson` uchun. Bo'sh bo'lsa `null` (eski cheklar kabi).
  String? encode() => isEmpty ? null : jsonEncode(toJson());

  /// Buzilgan yoki yo'q (eski chek) — [empty].
  static ReceiptEpay decode(String? raw) {
    if (raw == null || raw.isEmpty) return empty;
    try {
      final dynamic json = jsonDecode(raw);
      return json is Map<String, dynamic> ? ReceiptEpay.fromJson(json) : empty;
    } catch (_) {
      return empty;
    }
  }
}
