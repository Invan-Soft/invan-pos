// Kaftpay kassa sozlamalari va to'lovlar jurnali.
//
// Kalitlar manbai (birinchisi bo'sh bo'lmasa o'sha):
//   1. adminkadagi "Kaftpay" to'lov turining `merchant_id` / `secret_key` i
//      (Click/Uzum kalitlari kabi — har kassaga o'z terminali);
//   2. kassa sozlamasi (Sozlamalar → Kaftpay, PIN bilan) — sinov uchun.
//
// Jurnal: har `/pay` urinishi kaliti bilan `/pay` dan OLDIN yoziladi —
// javob yo'qolsa yoki kassa o'chib qolsa ham keyin status so'raladi
// (Kaftpay namunaviy kassasi `pp-pos-app` dagi `journal.db` kabi).

import 'dart:convert';

import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class KaftpaySettings {
  const KaftpaySettings._();

  /// SDK (palm_wrapper.dll, palm_sdk.dll, dim_palm.dll, TNN.dll, config/)
  /// sukut bo'yicha shu yerda — kassa keshi yonida.
  static const String defaultSdkDir = r'C:\ProgramData\InVanPos2\kaftpay';

  static String get sdkDir {
    final v = Pref.getString(PrefKeys.kaftpaySdkDir, '').trim();
    return v.isEmpty ? defaultSdkDir : v;
  }

  static String get localClientId =>
      Pref.getString(PrefKeys.kaftpayClientId, '').trim();
  static String get localSecret =>
      Pref.getString(PrefKeys.kaftpaySecret, '').trim();

  /// Kalitlar: adminkadagi tur → kassa sozlamasi. Ikkalasida ham yo'q — null.
  static KaftpayConfig? config({Payment? payment}) => resolveConfig(
        adminClientId: payment?.merchantId,
        adminSecret: payment?.secretKey,
        localClientId: localClientId,
        localSecret: localSecret,
      );

  /// [config] ning sof qismi (test uchun).
  static KaftpayConfig? resolveConfig({
    String? adminClientId,
    String? adminSecret,
    required String localClientId,
    required String localSecret,
  }) {
    final aId = (adminClientId ?? '').trim();
    final aSecret = (adminSecret ?? '').trim();
    if (aId.isNotEmpty && aSecret.isNotEmpty) {
      return KaftpayConfig(
          clientId: aId, secret: aSecret, language: KaftpayLang.serverLanguage);
    }
    if (localClientId.isNotEmpty && localSecret.isNotEmpty) {
      return KaftpayConfig(
          clientId: localClientId,
          secret: localSecret,
          language: KaftpayLang.serverLanguage);
    }
    return null;
  }

  /// `/pay` dagi kassir — PIN bilan kirgan xodim (`sellerId` bilan bir xil).
  static String get cashierId => Pref.getString(PrefKeys.cashierId, '').trim();

  static String get cashierName => [
        Pref.getString(PrefKeys.cashierName, '').trim(),
        Pref.getString(PrefKeys.cashierSurname, '').trim(),
      ].where((e) => e.isNotEmpty).join(' ');
}

enum KaftpayJournalStatus {
  /// Kalit yozildi, `/pay` javobi hali yo'q (kassa shu paytda o'chgan bo'lishi
  /// mumkin) — status so'ralishi kerak.
  pending,

  /// Pul yechildi.
  charged,

  /// Pul yechilmadi (aniq).
  notCharged,

  /// Natija noma'lum — status so'ralishi kerak, `/pay` QAYTA YUBORILMAYDI.
  unknown,

  /// To'liq qaytarildi.
  refunded,

  /// Vozvrat natijasi noma'lum — QAYTA YUBORILMAYDI, adminkada tekshiriladi.
  refundUnknown;

  static KaftpayJournalStatus parse(Object? v) => values.firstWhere(
        (e) => e.name == v,
        orElse: () => unknown,
      );
}

class KaftpayJournalEntry {
  const KaftpayJournalEntry({
    required this.key,
    required this.requestId,
    required this.consumerGuid,
    required this.amount,
    required this.createdAt,
    required this.status,
    this.consumerName,
    this.transactionId,
    this.note,
    this.receipt,
  });

  /// `Idempotency-Key`.
  final String key;
  final String requestId;
  final String consumerGuid;
  final String? consumerName;

  /// Tiyin.
  final int amount;
  final DateTime createdAt;
  final KaftpayJournalStatus status;
  final String? transactionId;

  /// Oxirgi xato / izoh (kassirga ko'rsatiladi).
  final String? note;

  /// Sotuv cheki: `null` — eski yozuv (kuzatilmagan), `''` — sotuv hali
  /// chekka yozilmagan, boshqasi — chek raqami.
  final String? receipt;

  /// Pul yechilgan, lekin sotuv chekka yozilmagan: kassir sotuvni yakunlamay
  /// chiqib ketdi, fiskal xato berdi yoki dastur yopildi.
  bool get isUnbound => status == KaftpayJournalStatus.charged && receipt == '';

  bool get needsStatusCheck =>
      status == KaftpayJournalStatus.pending ||
      status == KaftpayJournalStatus.unknown;

  bool get canRefund =>
      status == KaftpayJournalStatus.charged &&
      (transactionId ?? '').isNotEmpty;

  KaftpayJournalEntry copyWith({
    KaftpayJournalStatus? status,
    String? transactionId,
    String? note,
    String? receipt,
  }) =>
      KaftpayJournalEntry(
        key: key,
        requestId: requestId,
        consumerGuid: consumerGuid,
        consumerName: consumerName,
        amount: amount,
        createdAt: createdAt,
        status: status ?? this.status,
        transactionId: transactionId ?? this.transactionId,
        note: note,
        receipt: receipt ?? this.receipt,
      );

  Map<String, dynamic> toJson() => {
        'key': key,
        'requestId': requestId,
        'consumerGuid': consumerGuid,
        if (consumerName != null) 'consumerName': consumerName,
        'amount': amount,
        'createdAt': createdAt.toUtc().toIso8601String(),
        'status': status.name,
        if (transactionId != null) 'transactionId': transactionId,
        if (note != null) 'note': note,
        if (receipt != null) 'receipt': receipt,
      };

  static KaftpayJournalEntry? fromJson(Object? j) {
    if (j is! Map) return null;
    final key = j['key'];
    if (key is! String || key.isEmpty) return null;
    return KaftpayJournalEntry(
      key: key,
      requestId: '${j['requestId'] ?? ''}',
      consumerGuid: '${j['consumerGuid'] ?? ''}',
      consumerName: j['consumerName'] as String?,
      amount: (j['amount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse('${j['createdAt']}')?.toLocal() ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: KaftpayJournalStatus.parse(j['status']),
      transactionId: j['transactionId'] as String?,
      note: j['note'] as String?,
      receipt: j['receipt'] as String?,
    );
  }
}

/// Jurnal saqlovchisi — sukut bo'yicha Pref (Hive), testda xotira.
class KaftpayJournal {
  KaftpayJournal(
      {String Function()? read, Future<void> Function(String)? write})
      : _read = read ?? (() => Pref.getString(PrefKeys.kaftpayJournal, '')),
        _write = write ?? ((v) => Pref.setString(PrefKeys.kaftpayJournal, v));

  /// Eng ko'pi bilan shuncha yozuv (eng eskilari tushib qoladi, lekin
  /// tekshirilishi kerak bo'lganlari hech qachon).
  static const int maxEntries = 200;

  final String Function() _read;
  final Future<void> Function(String) _write;

  /// Eng yangisi birinchi.
  List<KaftpayJournalEntry> all() {
    final raw = _read();
    if (raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      return list
          .map(KaftpayJournalEntry.fromJson)
          .whereType<KaftpayJournalEntry>()
          .toList();
    } catch (_) {
      return const [];
    }
  }

  KaftpayJournalEntry? byKey(String key) {
    for (final e in all()) {
      if (e.key == key) return e;
    }
    return null;
  }

  List<KaftpayJournalEntry> unresolved() =>
      all().where((e) => e.needsStatusCheck).toList();

  /// Pul yechilgan, chek chiqmagan to'lovlar.
  List<KaftpayJournalEntry> unbound() =>
      all().where((e) => e.isUnbound).toList();

  /// Sotuv chekka yozildi — shu to'lovlar endi chekda.
  Future<void> bindReceipt(Iterable<String> keys, String receipt) async {
    final wanted = keys.toSet();
    if (wanted.isEmpty) return;
    final list = [
      for (final e in all())
        wanted.contains(e.key)
            ? e.copyWith(note: e.note, receipt: receipt.isEmpty ? '-' : receipt)
            : e
    ];
    await _write(jsonEncode([for (final e in list) e.toJson()]));
  }

  /// Kalit bo'yicha yangilaydi yoki boshiga qo'shadi.
  Future<void> put(KaftpayJournalEntry entry) async {
    final list = [entry, ...all().where((e) => e.key != entry.key)];
    var kept = list;
    if (list.length > maxEntries) {
      kept = [
        ...list.take(maxEntries),
        ...list
            .skip(maxEntries)
            .where((e) => e.needsStatusCheck || e.isUnbound),
      ];
    }
    await _write(jsonEncode([for (final e in kept) e.toJson()]));
  }
}
