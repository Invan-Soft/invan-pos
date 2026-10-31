// Kaftpay — kaft (palm) bilan to'lov (20-task, 2026-10-30).
//
// Admin panelda "Kaftpay" nomli to'lov turi qo'shiladi (YagonaQr kabi nom
// bo'yicha taniladi, id — `PrefKeys.kaftpayId`). To'lov ekranidagi tugma:
// VP930 skanerida kaft → Kaftpay `identify` → kassir mijozni tasdiqlaydi →
// `/pay` (pul mijoz kartasidan yechiladi) → summa shu tur id'si bilan
// yoziladi. Fiskalda karta (`ReceivedCard`): pul bank kartasidan.
//
// API qatlami: lib/changes/services/payment/kaftpay/.

/// Kaftpay to'lov turi (admin panel). Chekdagi kanonik nom: 'KAFTPAY'.
class Kaftpay {
  const Kaftpay._();

  static const String code = 'KAFTPAY';

  /// Admin nomni har xil yozishi mumkin: "Kaftpay", "KAFTPAY", "Kaft Pay",
  /// "kaft_pay" → true (harfdan boshqa belgilar hisobga olinmaydi).
  static bool isName(String? name) => (name ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z]'), '')
      .contains('kaftpay');
}
