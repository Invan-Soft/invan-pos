// Joriy sotuvda yechilgan Kaftpay to'lovlari.
//
// - Tranzaksiya ID'lari chekka (`ReceiptModel4.epayJson`, ReceiptEpay)
//   yoziladi — keyin chekdan Kaftpay to'lovini topish mumkin.
// - Chek saqlangach jurnalda "chekka yozildi" deb belgilanadi. Belgilanmay
//   qolgan yechilgan to'lov — pul ketgan, chek chiqmagan:
//   KaftpayUnboundNotice ogohlantiradi.

import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';

class KaftpaySaleCharges {
  KaftpaySaleCharges({KaftpayJournal Function()? journal})
      : _journal = journal ?? KaftpayJournal.new;

  final KaftpayJournal Function() _journal;

  /// Jurnal kaliti → tranzaksiya ID'si (bo'sh bo'lishi mumkin).
  final Map<String, String> _byKey = {};

  bool get isEmpty => _byKey.isEmpty;

  List<String> get journalKeys => List.unmodifiable(_byKey.keys);

  List<String> get transactionIds => [
        for (final tx in _byKey.values)
          if (tx.isNotEmpty) tx
      ];

  void add({required String journalKey, String? transactionId}) {
    if (journalKey.isEmpty) return;
    _byKey[journalKey] = transactionId ?? '';
  }

  /// Chek saqlandi: jurnalda belgilanadi va ro'yxat tozalanadi.
  Future<void> bind(String receipt) async {
    if (_byKey.isEmpty) return;
    final keys = _byKey.keys.toList();
    _byKey.clear();
    await _journal().bindReceipt(keys, receipt);
  }

  /// Yangi to'lov sahifasi: oldingi sotuvning to'lovlari unutiladi (jurnalda
  /// esa "chek yo'q" bo'lib qoladi — ogohlantirish shundan).
  void clear() => _byKey.clear();
}
