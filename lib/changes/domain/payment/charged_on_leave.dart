// To'lov sahifasidan chiqishdan oldin: pul ALLAQACHON yechilgan, lekin sotuv
// yakunlanmasa chekka tushmaydigan to'lovlar (2026-10-31).
//
// - Kaftpay — kaft bilan yechilgan summa.
// - Uzcard / Humo — terminal integratsiyasi (Arcus) yoqilgan bo'lsa: to'lov
//   qatori faqat terminal "ОДОБРЕНО" degandan keyin qo'shiladi, demak pul
//   kartadan yechilgan. Integratsiya o'chiq bo'lsa karta qatori — kassirning
//   qo'lda belgisi (pul bu dastur orqali yechilmagan) → ogohlantirilmaydi.
//
// Arcus kodiga (typeUzcard / typeHumo) TEGILMAYDI — faqat to'lov xaritasi
// o'qiladi.
//
// Testlar: test/charged_on_leave_test.dart

import 'package:invan2/changes/models/organization_model.dart' show Payment;
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

enum ChargedKind { kaftpay, uzcard, humo }

class ChargedPayment {
  const ChargedPayment(this.kind, this.amount);

  final ChargedKind kind;

  /// So'm.
  final double amount;
}

class ChargedOnLeave {
  const ChargedOnLeave._();

  /// [paymentsMap] kalitlari: Uzcard — `cardId`, Humo — `@cardId`
  /// (`type: 1`), Kaftpay — o'z id'si.
  static List<ChargedPayment> of(
    Map<String, Payment> paymentsMap, {
    required String kaftpayId,
    required String cardId,
    required bool uzcardTerminal,
    required bool humoTerminal,
  }) {
    double value(String key) =>
        key.isEmpty || key == '@' ? 0 : (paymentsMap[key]?.value ?? 0);
    final list = <ChargedPayment>[
      if (kaftpayId.isNotEmpty)
        ChargedPayment(ChargedKind.kaftpay, value(kaftpayId)),
      if (uzcardTerminal && cardId.isNotEmpty)
        ChargedPayment(ChargedKind.uzcard, value(cardId)),
      if (humoTerminal && cardId.isNotEmpty)
        ChargedPayment(ChargedKind.humo, value('@$cardId')),
    ];
    return [
      for (final c in list)
        if (c.amount > 0) c
    ];
  }

  /// Joriy sozlamalar bilan.
  static List<ChargedPayment> current(Map<String, Payment> paymentsMap) => of(
        paymentsMap,
        kaftpayId: Pref.getString(PrefKeys.kaftpayId, ''),
        cardId: Pref.getString(PrefKeys.cardId, ''),
        uzcardTerminal: Pref.getBool(PrefKeys.isUzcardEnabled, false),
        humoTerminal: Pref.getBool(PrefKeys.isHumoEnabled, false),
      );
}
