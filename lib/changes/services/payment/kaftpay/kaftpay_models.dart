/*
    Kaftpay (pp-pos-api) so'rov/javob modellari — swagger 2026-10-29 holati.

    Summalar HAMMA joyda tiyinda (1 so'm = 100 tiyin) — [KaftpayMoney].
    Javobdagi vaqtlar `dd.MM.yyyy HH:mm:ss`, GMT+5 — [KaftpayTime].
    Enum'lar noma'lum qiymatga `unknown` bo'ladi va asl matn saqlanadi
    (server yangi holat qo'shsa kassa yiqilmasin).
*/

import 'dart:math' as math;

class KaftpayMoney {
  const KaftpayMoney._();

  /// So'm → tiyin. `12345.67 * 100` = 1234566.999… bo'lgani uchun yaxlitlanadi.
  static int toTiyin(num som) => (som * 100).round();

  static double toSom(int tiyin) => tiyin / 100;
}

class KaftpayTime {
  const KaftpayTime._();

  static final RegExp _re =
      RegExp(r'^(\d{2})\.(\d{2})\.(\d{4}) (\d{2}):(\d{2}):(\d{2})$');

  /// `01.08.2026 15:06:12` (GMT+5) → UTC. Shakl boshqacha bo'lsa ISO-8601
  /// sinab ko'riladi, u ham bo'lmasa null.
  static DateTime? parse(Object? raw) {
    if (raw is! String) return null;
    final m = _re.firstMatch(raw.trim());
    if (m == null) return DateTime.tryParse(raw)?.toUtc();
    int g(int i) => int.parse(m.group(i)!);
    return DateTime.utc(g(3), g(2), g(1), g(4), g(5), g(6))
        .subtract(const Duration(hours: 5));
  }
}

String? _str(Object? v) {
  if (v == null) return null;
  final s = v.toString();
  return s.isEmpty ? null : s;
}

int? _int(Object? v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

double? _double(Object? v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}

bool? _bool(Object? v) {
  if (v is bool) return v;
  if (v is String) {
    if (v == 'true') return true;
    if (v == 'false') return false;
  }
  return null;
}

// ─── Enum'lar ────────────────────────────────────────────────────────────────

enum KaftpayHand {
  left('LEFT'),
  right('RIGHT'),

  /// Skaner qo'lni aniqlay olmadi — ikkala qo'l bilan solishtiriladi.
  unspecified('UNSPECIFIED');

  final String wire;
  const KaftpayHand(this.wire);

  /// Windows `palm_wrapper.dll` ning `palm_type_out`: 0 = chap, 1 = o'ng
  /// (SDK hujjati: "1→RIGHT is what's confirmed correct in practice").
  static KaftpayHand fromSdk(int? palmType) {
    if (palmType == 0) return KaftpayHand.left;
    if (palmType == 1) return KaftpayHand.right;
    return KaftpayHand.unspecified;
  }
}

enum KaftpayIdentifyReason {
  /// Bitta kuchli moslik — `suggestion` ni kassir tasdiqlaydi.
  confident,

  /// Bir nechta ehtimol — kassir `candidates` dan TANLAYDI.
  ambiguous,

  /// Hech kim tanilmadi — boshqa to'lov turi.
  noMatch,

  unknown;

  static KaftpayIdentifyReason parse(Object? raw) {
    switch (raw) {
      case 'confident':
        return KaftpayIdentifyReason.confident;
      case 'ambiguous':
        return KaftpayIdentifyReason.ambiguous;
      case 'no_match':
        return KaftpayIdentifyReason.noMatch;
      default:
        return KaftpayIdentifyReason.unknown;
    }
  }
}

enum KaftpayTxStatus {
  pending,
  success,
  failed,
  refunded,
  unknown;

  static KaftpayTxStatus parse(Object? raw) {
    switch (raw) {
      case 'PENDING':
        return KaftpayTxStatus.pending;
      case 'SUCCESS':
        return KaftpayTxStatus.success;
      case 'FAILED':
        return KaftpayTxStatus.failed;
      case 'REFUNDED':
        return KaftpayTxStatus.refunded;
      default:
        return KaftpayTxStatus.unknown;
    }
  }
}

enum KaftpayOfdStatus {
  /// Kaftpay fiskallaydi, navbatda.
  pending,
  sent,

  /// Kaftpay o'zi qayta urinadi.
  failed,

  /// Merchant-fiscalized terminal: chekni BIZ chiqarib, havolasini
  /// `/pay/{tx}/ofd-receipt` ga yuborishimiz kerak.
  awaitingExternal,
  external,

  /// `isTest` terminal: na ekvayer, na OFD chaqiriladi.
  test,
  unknown;

  static KaftpayOfdStatus parse(Object? raw) {
    switch (raw) {
      case 'PENDING':
        return KaftpayOfdStatus.pending;
      case 'SENT':
        return KaftpayOfdStatus.sent;
      case 'FAILED':
        return KaftpayOfdStatus.failed;
      case 'AWAITING_EXTERNAL':
        return KaftpayOfdStatus.awaitingExternal;
      case 'EXTERNAL':
        return KaftpayOfdStatus.external;
      case 'TEST':
        return KaftpayOfdStatus.test;
      default:
        return KaftpayOfdStatus.unknown;
    }
  }
}

// ─── Kaft skani ──────────────────────────────────────────────────────────────

/// Skanerdan olingan kaft: IR (majburiy) va RGB (ixtiyoriy) — har biri 516 float.
class KaftpayPalmScan {
  static const int vectorLength = 516;

  /// `palm_wrapper.cpp` dagi `IsValidFeatures`: L2 norma shundan kichik
  /// bo'lsa kadr bo'sh hisoblanadi.
  static const double minNorm = 0.01;

  final List<double> ir;
  final List<double>? rgb;
  final KaftpayHand hand;

  /// Har xil model shablonlari solishtirilmaydi; server default'i ham shu.
  final String scannerModel;

  const KaftpayPalmScan({
    required this.ir,
    this.rgb,
    this.hand = KaftpayHand.unspecified,
    this.scannerModel = 'palm-VP930',
  });

  /// Yuborishdan OLDIN mahalliy tekshiruv (server baribir `1104`/`1105`
  /// beradi, lekin bu yerda tutsak mijozni darhol qayta skanerlatamiz).
  /// null — yaroqli, aks holda sabab.
  String? validate() {
    if (ir.length != vectorLength) {
      return 'IR vektor ${ir.length} ta, $vectorLength ta bo\'lishi kerak';
    }
    if (!ir.every((v) => v.isFinite)) {
      return 'IR vektorda NaN/Infinity bor';
    }
    var sq = 0.0;
    for (final v in ir) {
      sq += v * v;
    }
    if (math.sqrt(sq) < minNorm) return 'IR vektor bo\'sh (norma ~0)';
    // RGB tekshirilmaydi: yaroqsizi [vectorsJson] da tashlab yuboriladi.
    return null;
  }

  /// RGB yuboriladimi: 516 ta, hammasi chekli va hammasi 0 emas. SDK RGB'ni
  /// NaN'ga tekshirmaydi (IR'ni tekshiradi), VP930 esa RGB'ni 0 bilan
  /// to'ldiradi — bunday RGB "yo'q" hisoblanadi, skan rad etilmaydi
  /// (asosiysi IR; server ham 0 RGB'ni "yo'q" deb oladi).
  bool get hasUsableRgb {
    final c = rgb;
    return c != null &&
        c.length == vectorLength &&
        c.every((v) => v.isFinite) &&
        c.any((v) => v != 0);
  }

  /// Shifrlanadigan ochiq matn: `{"ir":[...],"rgb":[...]|null}`.
  Map<String, dynamic> vectorsJson() => {
        'ir': ir,
        'rgb': hasUsableRgb ? rgb : null,
      };
}

// ─── /ping ───────────────────────────────────────────────────────────────────

class KaftpayTerminalInfo {
  final String? clientId;
  final String? terminalCode;
  final String? committentTin;

  /// true — Kaftpay o'zi fiskallaydi (`products` MXIK bilan shart);
  /// false — chekni biz chiqaramiz va havolasini bildiramiz.
  final bool? ofdEnabled;

  /// true — test terminal: ekvayer va OFD chaqirilmaydi.
  final bool? isTest;
  final String? status;

  const KaftpayTerminalInfo({
    this.clientId,
    this.terminalCode,
    this.committentTin,
    this.ofdEnabled,
    this.isTest,
    this.status,
  });

  factory KaftpayTerminalInfo.fromJson(Map<String, dynamic> j) =>
      KaftpayTerminalInfo(
        clientId: _str(j['clientId']),
        terminalCode: _str(j['terminalCode']),
        committentTin: _str(j['committentTin']),
        ofdEnabled: _bool(j['ofdEnabled']),
        isTest: _bool(j['isTest']),
        status: _str(j['status']),
      );

  bool get isActive => status == 'ACTIVE';
}

// ─── /identify ───────────────────────────────────────────────────────────────

class KaftpayCandidate {
  /// `/pay` ga aynan shu ketadi.
  final String consumerGuid;

  /// Swagger: qisqartirilgan ism (`Alisher U.`). AMALDA matcher'dan keladi
  /// va mijoz GUID'iga teng (Kaftpay `REGISTRATION-PAYMENT-TECH.md` §6) —
  /// haqiqiy ism [firstName] da.
  final String? name;
  final String? firstName;

  /// 0..1, faqat tartib uchun — chegaralarni server qo'llagan.
  final double? score;
  final String? phoneLast4;

  const KaftpayCandidate({
    required this.consumerGuid,
    this.name,
    this.firstName,
    this.score,
    this.phoneLast4,
  });

  factory KaftpayCandidate.fromJson(Map<String, dynamic> j) => KaftpayCandidate(
        consumerGuid: _str(j['consumerGuid']) ?? '',
        name: _str(j['name']),
        firstName: _str(j['firstName']),
        score: _double(j['score']),
        phoneLast4: _str(j['phoneLast4']),
      );

  static final RegExp _uuid = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false);

  /// Kassir ko'radigan ism: `firstName`, u bo'lmasa `name` (GUID bo'lsa —
  /// ko'rsatilmaydi).
  String? get displayName {
    final f = firstName?.trim();
    if (f != null && f.isNotEmpty) return f;
    final n = name?.trim();
    if (n == null || n.isEmpty || _uuid.hasMatch(n) || n == consumerGuid) {
      return null;
    }
    return n;
  }

  /// Kassir ko'radigan qator: `Alisher · ***4567`.
  String get label {
    final n = displayName ?? '—';
    final p = phoneLast4;
    return p == null ? n : '$n · ***$p';
  }
}

class KaftpayIdentifyResult {
  final String requestId;
  final KaftpayIdentifyReason reason;
  final String? reasonRaw;
  final KaftpayCandidate? suggestion;
  final List<KaftpayCandidate> candidates;

  /// UTC. Shundan keyin `/pay` → `1201`, qayta skanerlash kerak.
  final DateTime? expiresAt;

  const KaftpayIdentifyResult({
    required this.requestId,
    required this.reason,
    this.reasonRaw,
    this.suggestion,
    this.candidates = const [],
    this.expiresAt,
  });

  factory KaftpayIdentifyResult.fromJson(Map<String, dynamic> j) {
    final s = j['suggestion'];
    final c = j['candidates'];
    return KaftpayIdentifyResult(
      requestId: _str(j['requestId']) ?? '',
      reason: KaftpayIdentifyReason.parse(j['reason']),
      reasonRaw: _str(j['reason']),
      suggestion:
          s is Map<String, dynamic> ? KaftpayCandidate.fromJson(s) : null,
      candidates: c is List
          ? c
              .whereType<Map<String, dynamic>>()
              .map(KaftpayCandidate.fromJson)
              .where((e) => e.consumerGuid.isNotEmpty)
              .toList()
          : const [],
      expiresAt: KaftpayTime.parse(j['expiresAt']),
    );
  }

  /// Kassir tasdiqlashi uchun tayyor bitta nomzod (faqat `confident`).
  /// `ambiguous` da HECH QACHON avtomatik tanlanmaydi.
  KaftpayCandidate? get suggested => reason == KaftpayIdentifyReason.confident
      ? (suggestion ?? (candidates.length == 1 ? candidates.first : null))
      : null;

  bool get needsCashierChoice => reason == KaftpayIdentifyReason.ambiguous;

  bool get isNoMatch =>
      reason == KaftpayIdentifyReason.noMatch ||
      (candidates.isEmpty && suggestion == null);

  /// `/pay` faqat shu ro'yxatdagi guid bilan (`1203`).
  bool isCandidate(String consumerGuid) =>
      candidates.any((c) => c.consumerGuid == consumerGuid) ||
      suggestion?.consumerGuid == consumerGuid;

  /// [serverNow] (envelope `timestamp`) dan [expiresAt] gacha qolgan vaqt —
  /// kassa soati noto'g'ri bo'lsa ham to'g'ri hisoblanadi.
  Duration? ttlFrom(DateTime? serverNow) {
    final e = expiresAt;
    if (e == null || serverNow == null) return null;
    return e.difference(serverNow);
  }
}

// ─── /pay ────────────────────────────────────────────────────────────────────

/// Chek qatori. Hamma summalar tiyinda; qator sof jami
/// `price - discount - other`, `/pay` da yig'indisi `amount` ga teng (`1204`).
class KaftpayReceiptItem {
  final String name;

  /// MXIK (SPIC/IKPU).
  final String? spic;

  /// Qadoq kodi — faqat [spic] bilan (`1054`).
  final String? packageCode;

  /// Qator jami (narx × miqdor), chegirmadan OLDIN.
  final int price;
  final int? amount;
  final int? vatPercent;
  final int? discount;
  final int? other;

  /// O'lchov birligi kodi.
  final int? units;

  /// Markirovka kodi.
  final String? label;
  final String? commissionTin;
  final String? commissionPinfl;

  const KaftpayReceiptItem({
    required this.name,
    required this.price,
    this.spic,
    this.packageCode,
    this.amount,
    this.vatPercent,
    this.discount,
    this.other,
    this.units,
    this.label,
    this.commissionTin,
    this.commissionPinfl,
  });

  int get netTotal => price - (discount ?? 0) - (other ?? 0);

  Map<String, dynamic> toJson() {
    final m = <String, dynamic>{'name': name, 'price': price};
    void put(String k, Object? v) {
      if (v == null) return;
      if (v is String && v.isEmpty) return;
      m[k] = v;
    }

    put('spic', spic);
    put('packageCode', packageCode);
    put('amount', amount);
    put('vatPercent', vatPercent);
    put('discount', discount);
    put('other', other);
    put('units', units);
    put('label', label);
    put('commissionTin', commissionTin);
    put('commissionPinfl', commissionPinfl);
    return m;
  }
}

class KaftpayPayRequest {
  static const int cashierIdMax = 64;
  static const int cashierNameMax = 128;

  final String requestId;
  final String consumerGuid;

  /// Tiyin.
  final int amount;
  final String cashierId;
  final String cashierName;

  /// Kaftpay fiskallasa (`ofdEnabled`) — shart; biz fiskallasak — ixtiyoriy.
  final List<KaftpayReceiptItem>? products;

  const KaftpayPayRequest({
    required this.requestId,
    required this.consumerGuid,
    required this.amount,
    required this.cashierId,
    required this.cashierName,
    this.products,
  });

  /// Mahalliy tekshiruv — server rad etadiganini tarmoqqa chiqmasdan tutadi.
  String? validate() {
    if (requestId.trim().isEmpty) return 'requestId yo\'q';
    if (consumerGuid.trim().isEmpty) return 'Mijoz tanlanmagan';
    if (amount <= 0) return 'Summa 0 dan katta bo\'lishi kerak';
    if (cashierId.trim().isEmpty || cashierName.trim().isEmpty) {
      return 'Kassir ma\'lumoti (id/ism) yo\'q';
    }
    if (cashierId.trim().length > cashierIdMax) {
      return 'Kassir id $cashierIdMax belgidan uzun';
    }
    final p = products;
    if (p != null && p.isNotEmpty) {
      final sum = p.fold<int>(0, (s, e) => s + e.netTotal);
      if (sum != amount) {
        return 'Mahsulotlar jami ($sum tiyin) summaga ($amount tiyin) teng emas';
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    final name = cashierName.trim();
    final m = <String, dynamic>{
      'requestId': requestId,
      'consumerGuid': consumerGuid,
      'amount': amount,
      'cashierId': cashierId.trim(),
      'cashierName': name.length > cashierNameMax
          ? name.substring(0, cashierNameMax)
          : name,
    };
    final p = products;
    if (p != null && p.isNotEmpty) {
      m['products'] = p.map((e) => e.toJson()).toList();
    }
    return m;
  }
}

class KaftpayPayResult {
  /// Chekka chiqariladi — vozvrat va hamma joyda shu id.
  final String transactionId;
  final KaftpayTxStatus status;
  final String? statusRaw;

  /// Tiyin.
  final int? amount;
  final String? acquirerRef;
  final KaftpayOfdStatus ofdStatus;
  final String? ofdStatusRaw;

  const KaftpayPayResult({
    required this.transactionId,
    required this.status,
    this.statusRaw,
    this.amount,
    this.acquirerRef,
    this.ofdStatus = KaftpayOfdStatus.unknown,
    this.ofdStatusRaw,
  });

  factory KaftpayPayResult.fromJson(Map<String, dynamic> j) => KaftpayPayResult(
        transactionId: _str(j['transactionId']) ?? '',
        status: KaftpayTxStatus.parse(j['status']),
        statusRaw: _str(j['status']),
        amount: _int(j['amount']),
        acquirerRef: _str(j['acquirerRef']),
        ofdStatus: KaftpayOfdStatus.parse(j['ofdStatus']),
        ofdStatusRaw: _str(j['ofdStatus']),
      );
}

// ─── /pay/status/{key} ───────────────────────────────────────────────────────

class KaftpayPaymentStatus {
  final String? idempotencyKey;
  final String? requestId;

  /// `IDENTIFIED` / `CONFIRMED` / `CHARGING` / `CHARGED` / `CANCELLED` / `EXPIRED`.
  final String? requestStatus;
  final String? transactionId;
  final KaftpayTxStatus status;
  final String? statusRaw;
  final int? amount;
  final String? currency;
  final String? consumerGuid;
  final String? cardMask;
  final String? acquirerRef;
  final KaftpayOfdStatus ofdStatus;
  final String? cashierId;
  final String? cashierName;
  final DateTime? paidAt;

  const KaftpayPaymentStatus({
    this.idempotencyKey,
    this.requestId,
    this.requestStatus,
    this.transactionId,
    this.status = KaftpayTxStatus.unknown,
    this.statusRaw,
    this.amount,
    this.currency,
    this.consumerGuid,
    this.cardMask,
    this.acquirerRef,
    this.ofdStatus = KaftpayOfdStatus.unknown,
    this.cashierId,
    this.cashierName,
    this.paidAt,
  });

  factory KaftpayPaymentStatus.fromJson(Map<String, dynamic> j) =>
      KaftpayPaymentStatus(
        idempotencyKey: _str(j['idempotencyKey']),
        requestId: _str(j['requestId']),
        requestStatus: _str(j['requestStatus']),
        transactionId: _str(j['transactionId']),
        status: KaftpayTxStatus.parse(j['status']),
        statusRaw: _str(j['status']),
        amount: _int(j['amount']),
        currency: _str(j['currency']),
        consumerGuid: _str(j['consumerGuid']),
        cardMask: _str(j['cardMask']),
        acquirerRef: _str(j['acquirerRef']),
        ofdStatus: KaftpayOfdStatus.parse(j['ofdStatus']),
        cashierId: _str(j['cashierId']),
        cashierName: _str(j['cashierName']),
        paidAt: KaftpayTime.parse(j['paidAt']),
      );
}

// ─── /pay/{tx}/refund ────────────────────────────────────────────────────────

class KaftpayRefundResult {
  final String transactionId;
  final KaftpayTxStatus status;
  final int? amount;
  final String? refundAcquirerRef;
  final DateTime? refundedAt;

  const KaftpayRefundResult({
    required this.transactionId,
    required this.status,
    this.amount,
    this.refundAcquirerRef,
    this.refundedAt,
  });

  factory KaftpayRefundResult.fromJson(Map<String, dynamic> j) =>
      KaftpayRefundResult(
        transactionId: _str(j['transactionId']) ?? '',
        status: KaftpayTxStatus.parse(j['status']),
        amount: _int(j['amount']),
        refundAcquirerRef: _str(j['refundAcquirerRef']),
        refundedAt: KaftpayTime.parse(j['refundedAt']),
      );
}

// ─── /pay/{tx}/ofd-receipt ───────────────────────────────────────────────────

class KaftpayOfdReceiptResult {
  final String transactionId;
  final KaftpayOfdStatus ofdStatus;
  final String? terminalId;
  final int? receiptSeq;
  final String? fiscalDateTime;
  final String? fiscalSign;
  final String? ofdReceiptUrl;

  const KaftpayOfdReceiptResult({
    required this.transactionId,
    required this.ofdStatus,
    this.terminalId,
    this.receiptSeq,
    this.fiscalDateTime,
    this.fiscalSign,
    this.ofdReceiptUrl,
  });

  factory KaftpayOfdReceiptResult.fromJson(Map<String, dynamic> j) =>
      KaftpayOfdReceiptResult(
        transactionId: _str(j['transactionId']) ?? '',
        ofdStatus: KaftpayOfdStatus.parse(j['ofdStatus']),
        terminalId: _str(j['terminalId']),
        receiptSeq: _int(j['receiptSeq']),
        fiscalDateTime: _str(j['fiscalDateTime']),
        fiscalSign: _str(j['fiscalSign']),
        ofdReceiptUrl: _str(j['ofdReceiptUrl']),
      );

  /// Server havolani biz nazarda tutgandek o'qiganini tekshirish (swagger:
  /// "it is how the POS confirms we read its link the way it meant").
  bool matchesUrl(String url) {
    final q = Uri.tryParse(url)?.queryParameters;
    if (q == null) return false;
    return q['t'] == terminalId &&
        q['r'] == receiptSeq?.toString() &&
        q['c'] == fiscalDateTime &&
        q['s'] == fiscalSign;
  }
}

// ─── /enroll ─────────────────────────────────────────────────────────────────

class KaftpayEnrollResult {
  final String consumerGuid;

  /// `PENDING` / `ACTIVE` / `REVOKED`.
  final String? status;
  final DateTime? enrolledAt;

  const KaftpayEnrollResult({
    required this.consumerGuid,
    this.status,
    this.enrolledAt,
  });

  factory KaftpayEnrollResult.fromJson(Map<String, dynamic> j) =>
      KaftpayEnrollResult(
        consumerGuid: _str(j['consumerGuid']) ?? '',
        status: _str(j['status']),
        enrolledAt: KaftpayTime.parse(j['enrolledAt']),
      );

  bool get isActive => status == 'ACTIVE';
}
