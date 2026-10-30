/*
    Kaftpay to'lov/vozvrat oqimi — pul xavfsizligi (swagger §4).

    Asosiy qoida: `/pay` javobi kelmasa "pul ketmadi" deb HECH QACHON
    taxmin qilinmaydi va boshqa kalit bilan qayta yechilmaydi.

    charge():
      /pay → 200                              → charged
      /pay → aniq rad (1203, 1206, 1201 ...)  → notCharged (pul ketmagan)
      /pay → timeout / tarmoq / 1215 / 9999 / 5xx / tushunarsiz / 1207 / 1209
           → resolve(): GET /pay/status/{key}
               200 SUCCESS (shu requestId va summa) → charged
               200 PENDING (ekvayerda)              → yana so'raladi
               1210                                 → notCharged (kalit bo'sh,
                                                      shu kalit bilan qayta
                                                      urinish xavfsiz)
               boshqa / javob yo'q                  → unknown
      unknown — kassa sotuvni yopmaydi, boshqa to'lov turiga ham o'tkazmaydi;
      kassir keyinroq resolve() ni qayta bosadi (kalit saqlanadi).

    refund():
      200                         → refunded
      1223                        → unknown, QAYTA YUBORILMAYDI (support)
      aniq rad (1224, 1221, ...)  → notRefunded
      tarmoq / server             → asl to'lov kaliti bo'lsa status: REFUNDED
                                    → refunded, aks holda unknown (qayta
                                    yuborish xavfsiz: REFUNDED tranzaksiyaga
                                    vozvrat natijani takrorlaydi).

    Testlar: test/kaftpay_payment_flow_test.dart
*/

import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_error.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:uuid/uuid.dart';

enum KaftpayChargeState {
  /// Pul yechildi.
  charged,

  /// Pul yechilmagani ANIQ.
  notCharged,

  /// Aniqlab bo'lmadi — qayta yechish TAQIQLANGAN, faqat [KaftpayPaymentFlow.resolve].
  unknown,
}

class KaftpayChargeOutcome {
  final KaftpayChargeState state;
  final String idempotencyKey;
  final String? transactionId;

  /// Tiyin.
  final int? amount;
  final String? acquirerRef;
  final KaftpayOfdStatus ofdStatus;
  final String? cardMask;

  /// notCharged / unknown sababi.
  final KaftpayError? error;

  const KaftpayChargeOutcome({
    required this.state,
    required this.idempotencyKey,
    this.transactionId,
    this.amount,
    this.acquirerRef,
    this.ofdStatus = KaftpayOfdStatus.unknown,
    this.cardMask,
    this.error,
  });

  bool get isCharged => state == KaftpayChargeState.charged;
  bool get isUnknown => state == KaftpayChargeState.unknown;

  /// Chekni biz chiqarib, havolasini `attachOfdReceipt` ga yuborishimiz kerak.
  bool get needsExternalReceipt =>
      ofdStatus == KaftpayOfdStatus.awaitingExternal;

  String get message {
    switch (state) {
      case KaftpayChargeState.charged:
        return 'Kaftpay: to\'lov o\'tdi';
      case KaftpayChargeState.notCharged:
        return error?.message ?? 'Kaftpay: to\'lov o\'tmadi';
      case KaftpayChargeState.unknown:
        return 'Kaftpay: to\'lov natijasi noma\'lum — QAYTA YECHMANG, '
            '"Tekshirish" tugmasini bosing'
            '${error == null ? '' : ' (${error!.message})'}';
    }
  }
}

enum KaftpayRefundState { refunded, notRefunded, unknown }

class KaftpayRefundOutcome {
  final KaftpayRefundState state;
  final String transactionId;
  final int? amount;
  final String? refundAcquirerRef;
  final KaftpayError? error;

  /// unknown holatda: shu vozvratni qayta yuborish mumkinmi.
  /// `1223` da false — faqat Kaftpay support.
  final bool retryAllowed;

  const KaftpayRefundOutcome({
    required this.state,
    required this.transactionId,
    this.amount,
    this.refundAcquirerRef,
    this.error,
    this.retryAllowed = false,
  });

  bool get isRefunded => state == KaftpayRefundState.refunded;
}

class KaftpayPaymentFlow {
  KaftpayPaymentFlow(
    this.api, {
    this.statusAttempts = 3,
    this.statusDelay = const Duration(seconds: 2),
    Future<void> Function(Duration)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final KaftpayApi api;

  /// resolve() ichida status necha marta so'raladi.
  final int statusAttempts;
  final Duration statusDelay;
  final Future<void> Function(Duration) _sleep;

  /// Bitta niyat qilingan to'lovga bitta kalit. Saqlab qo'yiladi: javob
  /// yo'qolsa (hatto kassa o'chib qolsa ham) shu kalit bilan status so'raladi.
  static String newIdempotencyKey() => const Uuid().v4();

  /// `/pay` dan keyin pul ketmagani ANIQ bo'lgan kodlar. Qolgan hamma narsa
  /// (noma'lum kod ham) status orqali tekshiriladi.
  static const Set<String> definitePayRejections = {
    '1200', '1201', '1202', '1203', '1204', '1205', '1206', '1208', //
    '1211', '1212', '1213', '1214', '1052', '1053', '1054', '1055',
  };

  static bool isDefinitePayRejection(KaftpayError e) {
    switch (e.kind) {
      case KaftpayErrorKind.local:
      case KaftpayErrorKind.validation:
      case KaftpayErrorKind.auth:
        return true;
      case KaftpayErrorKind.business:
        return definitePayRejections.contains(e.code);
      default:
        return false;
    }
  }

  Future<KaftpayChargeOutcome> charge({
    required String idempotencyKey,
    required KaftpayPayRequest request,
  }) async {
    final res = await api.pay(idempotencyKey: idempotencyKey, request: request);
    final data = res.data;
    if (data != null) {
      // 200 ham hali "pul ketdi" degani emas: `status` qaraladi (Kaftpay
      // namunaviy kassasi `pp-pos-app` ham shunday). Ekvayer PENDING
      // qaytarsa — natija noma'lum, status orqali aniqlanadi.
      switch (data.status) {
        case KaftpayTxStatus.success:
          return KaftpayChargeOutcome(
            state: KaftpayChargeState.charged,
            idempotencyKey: idempotencyKey,
            transactionId: data.transactionId,
            amount: data.amount ?? request.amount,
            acquirerRef: data.acquirerRef,
            ofdStatus: data.ofdStatus,
          );
        case KaftpayTxStatus.failed:
          return KaftpayChargeOutcome(
            state: KaftpayChargeState.notCharged,
            idempotencyKey: idempotencyKey,
            transactionId: data.transactionId,
            error: KaftpayError.local(
                'Bank to\'lovni rad etdi (FAILED) — pul yechilmadi'),
          );
        default:
          return resolve(idempotencyKey,
              expected: request,
              cause: KaftpayError.local(
                  'Kaftpay javobi: ${data.statusRaw ?? 'status yo\'q'}'));
      }
    }
    final err = res.error!;
    if (isDefinitePayRejection(err)) {
      return KaftpayChargeOutcome(
        state: KaftpayChargeState.notCharged,
        idempotencyKey: idempotencyKey,
        error: err,
      );
    }
    return resolve(idempotencyKey, expected: request, cause: err);
  }

  /// Javobi yo'qolgan to'lov taqdirini aniqlaydi. [expected] berilsa topilgan
  /// to'lov shu so'rovniki ekani tekshiriladi (kalit boshqa to'lovga
  /// ishlatilgan bo'lsa `charged` deb aldanmaslik uchun).
  Future<KaftpayChargeOutcome> resolve(
    String idempotencyKey, {
    KaftpayPayRequest? expected,
    KaftpayError? cause,
  }) async {
    KaftpayError? last = cause;
    for (var i = 0; i < statusAttempts; i++) {
      if (i > 0) await _sleep(statusDelay);
      final st = await api.payStatus(idempotencyKey);
      final s = st.data;
      if (s != null) {
        if (expected != null &&
            ((s.requestId != null && s.requestId != expected.requestId) ||
                (s.amount != null && s.amount != expected.amount))) {
          return KaftpayChargeOutcome(
            state: KaftpayChargeState.unknown,
            idempotencyKey: idempotencyKey,
            transactionId: s.transactionId,
            error: KaftpayError.local(
                'Bu kalit boshqa to\'lovga tegishli (requestId/summa mos emas): '
                'tx ${s.transactionId}'),
          );
        }
        if (s.status == KaftpayTxStatus.success) {
          return KaftpayChargeOutcome(
            state: KaftpayChargeState.charged,
            idempotencyKey: idempotencyKey,
            transactionId: s.transactionId,
            amount: s.amount ?? expected?.amount,
            acquirerRef: s.acquirerRef,
            ofdStatus: s.ofdStatus,
            cardMask: s.cardMask,
          );
        }
        if (s.status == KaftpayTxStatus.pending) {
          last = KaftpayError.local(
              'Bank hali javob bermadi (${s.requestStatus ?? 'PENDING'})');
          continue;
        }
        // FAILED — server yakuniy holati: ekvayer rad etgan, pul ketmagan
        // (CHARGING'da qolganini status endpoint'i o'zi ekvayerdan
        // so'rab yopadi).
        if (s.status == KaftpayTxStatus.failed) {
          return KaftpayChargeOutcome(
            state: KaftpayChargeState.notCharged,
            idempotencyKey: idempotencyKey,
            transactionId: s.transactionId,
            error: KaftpayError.local(
                'Bank to\'lovni rad etdi (FAILED) — pul yechilmadi'),
          );
        }
        // REFUNDED / noma'lum — avtomatik xulosa chiqarilmaydi.
        return KaftpayChargeOutcome(
          state: KaftpayChargeState.unknown,
          idempotencyKey: idempotencyKey,
          transactionId: s.transactionId,
          error: KaftpayError.local(
              'Kaftpay to\'lov holati: ${s.statusRaw ?? 'noma\'lum'}'),
        );
      }
      final err = st.error!;
      if (err.code == KaftpayErrorCodes.noPaymentForKey) {
        return KaftpayChargeOutcome(
          state: KaftpayChargeState.notCharged,
          idempotencyKey: idempotencyKey,
          error: cause ?? err,
        );
      }
      last = err;
      if (err.kind == KaftpayErrorKind.network ||
          err.kind == KaftpayErrorKind.server ||
          err.kind == KaftpayErrorKind.badResponse) {
        continue;
      }
      break; // auth / 1202 / 1208 — qayta so'rash foyda bermaydi.
    }
    return KaftpayChargeOutcome(
      state: KaftpayChargeState.unknown,
      idempotencyKey: idempotencyKey,
      error: last,
    );
  }

  /// To'liq vozvrat. [paymentIdempotencyKey] — asl to'lov kaliti; javob
  /// yo'qolsa vozvrat bo'lgan-bo'lmaganini status orqali bilish uchun.
  Future<KaftpayRefundOutcome> refund({
    required String transactionId,
    required String cashierId,
    required String cashierName,
    String? reason,
    String? paymentIdempotencyKey,
  }) async {
    final res = await api.refund(
      transactionId: transactionId,
      cashierId: cashierId,
      cashierName: cashierName,
      reason: reason,
    );
    final data = res.data;
    if (data != null) {
      return KaftpayRefundOutcome(
        state: KaftpayRefundState.refunded,
        transactionId: transactionId,
        amount: data.amount,
        refundAcquirerRef: data.refundAcquirerRef,
      );
    }
    final err = res.error!;
    if (err.code == KaftpayErrorCodes.refundOutcomeUnknown) {
      return KaftpayRefundOutcome(
        state: KaftpayRefundState.unknown,
        transactionId: transactionId,
        error: err,
        retryAllowed: false,
      );
    }
    final inDoubt = err.kind == KaftpayErrorKind.network ||
        err.kind == KaftpayErrorKind.server ||
        err.kind == KaftpayErrorKind.badResponse;
    if (!inDoubt) {
      return KaftpayRefundOutcome(
        state: KaftpayRefundState.notRefunded,
        transactionId: transactionId,
        error: err,
      );
    }
    final key = paymentIdempotencyKey;
    if (key != null && key.isNotEmpty) {
      final st = await api.payStatus(key);
      final s = st.data;
      if (s != null &&
          s.status == KaftpayTxStatus.refunded &&
          (s.transactionId == null || s.transactionId == transactionId)) {
        return KaftpayRefundOutcome(
          state: KaftpayRefundState.refunded,
          transactionId: transactionId,
          amount: s.amount,
        );
      }
    }
    return KaftpayRefundOutcome(
      state: KaftpayRefundState.unknown,
      transactionId: transactionId,
      error: err,
      retryAllowed: true,
    );
  }
}
