// YagonaQr — admin paneldagi alohida to'lov turi (2026-10-20, Odoo forkidan).
//
// Terminal integratsiyasi yo'q: mijoz Yagona QR orqali to'laydi, kassir
// to'lov ekranidagi tugmani bosib belgilaydi (`OrderingProvider4.typeYagonaQr`).
// Serverga to'lov turining o'z id'si bilan ketadi (`PrefKeys.yagonaQrId`).
// Fiskalda karta: `ReceivedCard` + `ExtraInfo.CardType` 2
// (`FiscalPaymentSplit.of`). X/Z hisobotda alohida qator yo'q — "Plastik" ichida.
//
// Testlar: test/yagonaqr_payment_test.dart

/// YagonaQr — admin paneldagi alohida to'lov turi (kassir belgilaydi).
/// Chekdagi/hisobotdagi kanonik nom: 'YAGONAQR'. Fiskalda karta
/// (ReceivedCard, cardType 2).
class YagonaQr {
  const YagonaQr._();

  static const String code = 'YAGONAQR';

  /// Admin nomni har xil yozishi mumkin — harf katta-kichikligi va harfdan
  /// boshqa belgilar (bo'sh joy, `_`, `-`, `.`, `/` ...) hisobga olinmaydi:
  /// "YagonaQr", "YAGONAQR", "yagonaqr", "Yagona QR", "yagona_qr",
  /// "Yagona-QR", "Yagona.QR" → true. Kassada bunday tur bitta bo'ladi.
  static bool isName(String? name) => (name ?? '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z]'), '')
      .contains('yagonaqr');
}
