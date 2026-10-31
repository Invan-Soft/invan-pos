// Bitta Kaftpay to'lovi (to'lov ekranidagi oyna mantig'i, UI'siz):
//   skan → identify → kassir mijozni tasdiqlaydi/tanlaydi → /pay → natija.
//
// Pul qoidalari (kaftpay_payment_flow.dart):
//   - kalit jurnalga `/pay` dan OLDIN yoziladi;
//   - `/pay` hech qachon qayta yuborilmaydi — noaniqda faqat status;
//   - `ambiguous` da mijoz avtomatik tanlanmaydi;
//   - `requestId` muddati (≈120 s) o'tgan bo'lsa — qayta skan.

import 'package:flutter/foundation.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_scanner.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';

enum KaftpayCheckoutStep {
  /// Kaft kutilmoqda (skaner).
  scanning,

  /// Server mijozni qidiryapti.
  identifying,

  /// Kassir mijozni tasdiqlaydi / tanlaydi.
  choosing,

  /// Kaft hech kimga mos kelmadi.
  noMatch,

  /// `/pay` ketdi — BEKOR QILIB BO'LMAYDI.
  charging,

  /// Pul yechildi — oyna natijani qaytaradi.
  charged,

  /// Natija noma'lum — faqat "Holatni tekshirish".
  unknown,

  /// Xato (skaner, tarmoq, rad) — pul yechilmagan; qayta skan mumkin.
  failed,
}

class KaftpayCheckout extends ChangeNotifier {
  KaftpayCheckout({
    required this.api,
    required this.scanner,
    required this.journal,
    required this.amount,
    required this.cashierId,
    required this.cashierName,
    KaftpayPaymentFlow? flow,
    DateTime Function()? now,
    String Function()? newKey,
  })  : flow = flow ?? KaftpayPaymentFlow(api),
        _now = now ?? DateTime.now,
        _newKey = newKey ?? KaftpayPaymentFlow.newIdempotencyKey;

  final KaftpayApi api;
  final KaftpayScanner scanner;
  final KaftpayJournal journal;
  final KaftpayPaymentFlow flow;

  /// Tiyin.
  final int amount;
  final String cashierId;
  final String cashierName;
  final DateTime Function() _now;
  final String Function() _newKey;

  /// Server bergan muddatdan shuncha oldin "muddati o'tdi" deymiz.
  static const Duration deadlineMargin = Duration(seconds: 5);
  static const Duration defaultTtl = Duration(seconds: 120);

  KaftpayCheckoutStep step = KaftpayCheckoutStep.scanning;

  /// Kassirga joriy xabar (skaner bosqichi / xato / natija).
  String message = '';

  KaftpayIdentifyResult? identified;
  String? selectedGuid;
  KaftpayChargeOutcome? outcome;
  DateTime? _deadline;
  KaftpayPayRequest? _request;
  bool _disposed = false;

  /// Tasdiqlash ro'yxati: `suggestion` birinchi, keyin boshqa nomzodlar.
  List<KaftpayCandidate> get candidates {
    final r = identified;
    if (r == null) return const [];
    final s = r.suggested;
    return [
      if (s != null) s,
      ...r.candidates.where((c) => c.consumerGuid != s?.consumerGuid),
    ];
  }

  KaftpayCandidate? get selected {
    for (final c in candidates) {
      if (c.consumerGuid == selectedGuid) return c;
    }
    return null;
  }

  bool get isExpired {
    final d = _deadline;
    return d != null && !_now().isBefore(d);
  }

  /// Bekor qilish mumkinmi — pul yo'lda bo'lsa yoki natija noma'lum bo'lsa yo'q
  /// (noma'lumni oyna "Keyinroq" bilan yopadi — jurnalda qoladi).
  bool get canCancel =>
      step != KaftpayCheckoutStep.charging &&
      step != KaftpayCheckoutStep.charged &&
      step != KaftpayCheckoutStep.unknown;

  bool get canPay =>
      step == KaftpayCheckoutStep.choosing && selected != null && !isExpired;

  /// Skan + identify. Qayta skan uchun ham shu.
  Future<void> start() async {
    identified = null;
    selectedGuid = null;
    _deadline = null;
    _set(
        KaftpayCheckoutStep.scanning,
        KaftpayLang.t(
            'Kaftni skanerga qo\'ying', 'Приложите ладонь к сканеру'));
    final KaftpayPalmScan scan;
    try {
      scan = await scanner.capture(onStage: (_, m) {
        if (step == KaftpayCheckoutStep.scanning) _set(step, m);
      });
    } on KaftpayScannerException catch (e) {
      if (e.cancelled) return;
      _set(KaftpayCheckoutStep.failed, e.message);
      return;
    }
    if (_disposed) return;
    _set(KaftpayCheckoutStep.identifying,
        KaftpayLang.t('Mijoz aniqlanmoqda...', 'Определяем клиента...'));
    final res = await api.identify(scan);
    if (_disposed) return;
    final data = res.data;
    if (data == null) {
      _set(KaftpayCheckoutStep.failed, res.error!.message);
      return;
    }
    identified = data;
    final ttl = data.ttlFrom(res.serverTime) ?? defaultTtl;
    _deadline = _now().add(ttl - deadlineMargin);
    if (data.isNoMatch) {
      _set(
          KaftpayCheckoutStep.noMatch,
          KaftpayLang.t(
              'Mijoz topilmadi. Kaftni qayta skanerlang yoki mijoz Kaftpay\'da '
                  'ro\'yxatdan o\'tmagan.',
              'Клиент не найден. Отсканируйте ладонь ещё раз или клиент не '
                  'зарегистрирован в Kaftpay.'));
      return;
    }
    // `ambiguous` — kassir o'zi tanlaydi (avtomatik tanlov yo'q).
    selectedGuid = data.suggested?.consumerGuid;
    _set(
        KaftpayCheckoutStep.choosing,
        data.needsCashierChoice
            ? KaftpayLang.t(
                'Bir nechta o\'xshash mijoz — telefon raqami bo\'yicha to\'g\'risini tanlang',
                'Несколько похожих клиентов — выберите по номеру телефона')
            : KaftpayLang.t('Mijozni tasdiqlang', 'Подтвердите клиента'));
  }

  void select(String consumerGuid) {
    if (step != KaftpayCheckoutStep.choosing) return;
    if (!(identified?.isCandidate(consumerGuid) ?? false)) return;
    selectedGuid = consumerGuid;
    notifyListeners();
  }

  /// Pul yechish. Faqat [canPay] da.
  Future<void> pay() async {
    if (step != KaftpayCheckoutStep.choosing) return;
    final who = selected;
    final req = identified;
    if (who == null || req == null) return;
    if (isExpired) {
      _set(
          KaftpayCheckoutStep.failed,
          KaftpayLang.t('Aniqlash muddati tugadi — kaftni qayta skanerlang',
              'Время истекло — отсканируйте ладонь заново'));
      return;
    }
    final request = KaftpayPayRequest(
      requestId: req.requestId,
      consumerGuid: who.consumerGuid,
      amount: amount,
      cashierId: cashierId,
      cashierName: cashierName,
    );
    final invalid = request.validate();
    if (invalid != null) {
      _set(KaftpayCheckoutStep.failed, invalid);
      return;
    }
    final key = _newKey();
    _request = request;
    await journal.put(KaftpayJournalEntry(
      key: key,
      requestId: request.requestId,
      consumerGuid: request.consumerGuid,
      consumerName: who.displayName,
      amount: amount,
      createdAt: _now(),
      status: KaftpayJournalStatus.pending,
      receipt: '', // sotuv chekka yozilgach to'ldiriladi (KaftpaySaleCharges)
    ));
    _set(KaftpayCheckoutStep.charging,
        KaftpayLang.t('To\'lov o\'tkazilmoqda...', 'Проводим оплату...'));
    final o = await flow.charge(idempotencyKey: key, request: request);
    await _apply(o);
  }

  /// Noma'lum natijani status orqali aniqlash (pul yechmaydi).
  Future<void> checkStatus() async {
    final o = outcome;
    if (step != KaftpayCheckoutStep.unknown || o == null) return;
    _set(KaftpayCheckoutStep.charging,
        KaftpayLang.t('Holat tekshirilmoqda...', 'Проверяем статус...'));
    final r = await flow.resolve(o.idempotencyKey, expected: _request);
    await _apply(r);
  }

  Future<void> _apply(KaftpayChargeOutcome o) async {
    outcome = o;
    final prev = journal.byKey(o.idempotencyKey);
    if (prev != null) {
      await journal.put(prev.copyWith(
        status: o.isCharged
            ? KaftpayJournalStatus.charged
            : o.isUnknown
                ? KaftpayJournalStatus.unknown
                : KaftpayJournalStatus.notCharged,
        transactionId: o.transactionId,
        note: o.isCharged ? null : o.message,
      ));
    }
    if (_disposed) return;
    switch (o.state) {
      case KaftpayChargeState.charged:
        _set(KaftpayCheckoutStep.charged, o.message);
        break;
      case KaftpayChargeState.unknown:
        _set(KaftpayCheckoutStep.unknown, o.message);
        break;
      case KaftpayChargeState.notCharged:
        _set(
            KaftpayCheckoutStep.failed,
            KaftpayLang.t('${o.message}. Pul yechilmadi.',
                '${o.message}. Деньги не списаны.'));
        break;
    }
  }

  /// Skanni to'xtatadi (oyna yopilganda).
  void cancel() {
    if (step == KaftpayCheckoutStep.scanning) scanner.cancel();
  }

  void _set(KaftpayCheckoutStep s, String m) {
    if (_disposed) return;
    if (kDebugMode) debugPrint('[Kaftpay] ${s.name}: $m');
    step = s;
    message = m;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (step == KaftpayCheckoutStep.scanning) scanner.cancel();
    super.dispose();
  }
}
