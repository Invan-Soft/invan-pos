/*
    Kaftpay javob/xato modeli.

    Swagger §2: har javob `{success, timestamp, data | code+reason}`.
    `success` — HTTP status'dan USTUN: kutilmagan server xatosi HTTP 200 +
    `success:false` + `9999` bo'lib keladi. Istisno — bean validation: HTTP 400
    va envelope'siz tekis `{"field": "message"}` xaritasi.

    Jonli serverda (2026-10-29) qo'shimcha shakl: imzo header'lari umuman
    bo'lmasa Spring'ning envelope'siz 403 `{"status":403,"error":"Forbidden"}`.

    Kod bo'yicha tarmoqlanamiz, `reason` matni bo'yicha emas (swagger talabi).
*/

enum KaftpayErrorKind {
  /// 401/403, `1100` (imzo/soat/nonce/terminal), `1108` (IP), `1002`.
  auth,

  /// HTTP 400 + kod — biznes rad etish.
  business,

  /// HTTP 400 + tekis `{field: message}` (envelope'siz).
  validation,

  /// `9999`, 5xx.
  server,

  /// Javob umuman kelmadi: timeout, ulanish yo'q, DNS.
  network,

  /// Javob keldi, lekin tushunib bo'lmadi.
  badResponse,

  /// So'rov yuborilmadi: sozlama yo'q yoki mahalliy tekshiruv o'tmadi.
  local,
}

class KaftpayError {
  final KaftpayErrorKind kind;

  /// To'rt xonali kod (`'1203'`); envelope'siz xatolarda null.
  final String? code;

  /// Server matni (Accept-Language bo'yicha) yoki mahalliy sabab.
  final String? reason;

  final int? httpStatus;

  /// Faqat [KaftpayErrorKind.validation] da.
  final Map<String, String> fieldErrors;

  /// [KaftpayErrorKind.network] da asl exception.
  final Object? cause;

  final bool isTimeout;

  const KaftpayError({
    required this.kind,
    this.code,
    this.reason,
    this.httpStatus,
    this.fieldErrors = const {},
    this.cause,
    this.isTimeout = false,
  });

  const KaftpayError.local(String this.reason)
      : kind = KaftpayErrorKind.local,
        code = null,
        httpStatus = null,
        fieldErrors = const {},
        cause = null,
        isTimeout = false;

  /// Kassirga ko'rsatiladigan matn: ma'lum kod → o'zbekcha izoh, aks holda
  /// server matni, u ham bo'lmasa tur bo'yicha umumiy matn.
  String get message {
    final known = KaftpayErrorCodes.describe(code);
    if (known != null) return known;
    if (kind == KaftpayErrorKind.validation && fieldErrors.isNotEmpty) {
      return 'Kaftpay so\'rovi noto\'g\'ri: '
          '${fieldErrors.entries.map((e) => '${e.key} — ${e.value}').join('; ')}';
    }
    final r = reason?.trim();
    if (r != null && r.isNotEmpty) return r;
    switch (kind) {
      case KaftpayErrorKind.network:
        return isTimeout
            ? 'Kaftpay serveri vaqtida javob bermadi'
            : 'Kaftpay serveriga ulanib bo\'lmadi (internet?)';
      case KaftpayErrorKind.auth:
        return 'Kaftpay: terminal ruxsati rad etildi (HTTP $httpStatus)';
      case KaftpayErrorKind.server:
        return 'Kaftpay serverida xato (HTTP $httpStatus)';
      case KaftpayErrorKind.badResponse:
        return 'Kaftpay javobini tushunib bo\'lmadi (HTTP $httpStatus)';
      default:
        return 'Kaftpay xatosi';
    }
  }

  @override
  String toString() =>
      'KaftpayError(${kind.name}, code: $code, http: $httpStatus, reason: $reason'
      '${fieldErrors.isEmpty ? '' : ', fields: $fieldErrors'}'
      '${cause == null ? '' : ', cause: $cause'})';
}

/// Muvaffaqiyat ([data]) yoki xato ([error]) — aynan bittasi.
class KaftpayResult<T> {
  final T? data;
  final KaftpayError? error;

  /// Envelope'dagi `timestamp` (server vaqti, UTC ga o'girilgan).
  final DateTime? serverTime;

  const KaftpayResult.ok(T this.data, {this.serverTime}) : error = null;

  const KaftpayResult.fail(KaftpayError this.error, {this.serverTime})
      : data = null;

  bool get isOk => error == null;
}

class KaftpayErrorCodes {
  const KaftpayErrorCodes._();

  static const String signature = '1100';
  static const String ipNotAllowed = '1108';
  static const String requestNotFound = '1200';
  static const String requestExpired = '1201';
  static const String otherTerminalRequest = '1202';
  static const String notACandidate = '1203';
  static const String amountMismatch = '1204';
  static const String noActiveCard = '1205';
  static const String declined = '1206';
  static const String alreadySettled = '1207';
  static const String keyMissing = '1208';
  static const String keyUsedElsewhere = '1209';
  static const String noPaymentForKey = '1210';
  static const String cashierMissing = '1211';
  static const String acquirerUnavailable = '1214';
  static const String acquirerAnswerLost = '1215';
  static const String refundOutcomeUnknown = '1223';
  static const String refundDeclined = '1224';
  static const String unexpected = '9999';

  /// Swagger (2026-10-29) dagi barcha kodlar — kassir uchun o'zbekcha.
  static const Map<String, String> _uz = {
    // Autentifikatsiya (HTTP 401)
    '1100': 'Kaftpay terminal imzosini rad etdi: client_id/secret noto\'g\'ri, '
        'terminal faol emas yoki kompyuter soati noto\'g\'ri',
    '1108': 'Kaftpay: bu kassaning IP manzilidan ruxsat yo\'q (IP whitelist)',
    // Kaft va ro'yxatdan o'tkazish
    '1103': 'Kaft aniqlash xizmati vaqtincha ishlamayapti — birozdan keyin '
        'qayta urining',
    '1104': 'Skaner noto\'g\'ri ma\'lumot berdi (516 ta qiymat kerak) — '
        'kaftni qayta skanerlang',
    '1105': 'Skaner noto\'g\'ri ma\'lumot berdi (NaN/Infinity) — kaftni '
        'qayta skanerlang',
    '1106': 'Kaft ma\'lumotini shifrdan ochib bo\'lmadi (secret mos emas?)',
    '1107': 'Kaft ma\'lumoti noto\'g\'ri shaklda yuborildi',
    '1109': 'Skaner ma\'lumoti haqiqiy qurilmaniki emasdek — kaftni qayta '
        'skanerlang',
    '1150': 'Ro\'yxatdan o\'tish QR kodi topilmadi',
    '1151': 'QR kod muddati o\'tgan — mijoz ilovada yangi QR ochsin',
    '1152': 'Bu QR kod allaqachon ishlatilgan',
    '1153': 'Bu kaft boshqa mijoz nomiga ro\'yxatdan o\'tgan',
    // To'lov
    '1200': 'To\'lov so\'rovi topilmadi — kaftni qayta skanerlang',
    '1201': 'Skanerlash muddati o\'tdi (~2 daqiqa) — kaftni qayta skanerlang',
    '1202': 'Bu to\'lov so\'rovi boshqa terminalga tegishli',
    '1203': 'Tanlangan mijoz aniqlanganlar ro\'yxatida yo\'q',
    '1204': 'To\'lov summasi mahsulotlar jamiga teng emas',
    '1205': 'Mijozda faol karta yo\'q',
    '1206': 'To\'lov bank tomonidan rad etildi',
    '1207': 'Bu so\'rov boshqa summa yoki mijoz bilan allaqachon to\'langan',
    '1208': 'To\'lov kaliti (Idempotency-Key) yo\'q',
    '1209': 'Bu to\'lov kaliti boshqa to\'lovda ishlatilgan',
    '1210': 'Bu kalit bo\'yicha to\'lov yo\'q — pul yechilmagan',
    '1211': 'Kassir ma\'lumoti (id/ism) yo\'q',
    '1212': 'Mijoz telefoni bu do\'kondan uzoqda ko\'rinmoqda — to\'lov rad '
        'etildi',
    '1213': 'Mijoz joylashuvi yangilanmagan — mijoz ilovani ochsin',
    '1214': 'Bank (ekvayer) vaqtincha ishlamayapti',
    '1215': 'Bank javobi yo\'qoldi, natija noma\'lum — QAYTA YECHMANG, '
        'to\'lov holatini tekshiring',
    '1216': 'Tranzaksiya topilmadi',
    '1217': 'Bu tranzaksiya boshqa terminalniki',
    '1218': 'Bu to\'lov muvaffaqiyatli bo\'lmagan',
    '1219': 'Bu tranzaksiyaga boshqa fiskal chek bog\'langan',
    '1221': 'Faqat muvaffaqiyatli to\'lovni qaytarish mumkin',
    '1222': 'Qaytarish uchun asos yo\'q',
    '1223': 'Vozvrat natijasi noma\'lum — QAYTA YUBORMANG, Kaftpay '
        'qo\'llab-quvvatlash xizmatiga murojaat qiling',
    '1224': 'Vozvrat bank tomonidan rad etildi (pul qaytmadi)',
    // Fiskal
    '1050': 'Fiskal chek yuborilmadi',
    '1051': 'OFD chekni rad etdi',
    '1052': 'MXIK (SPIC) noma\'lum yoki faol emas',
    '1053': 'Qadoq kodi bu MXIK ga tegishli emas yoki faol emas',
    '1054': 'Qadoq kodi MXIK siz yuborildi',
    '1055': 'Kamida bitta mahsulotda MXIK bo\'lishi kerak',
    '1057': 'Fiskal chek havolasi o\'qilmadi (t, r, c, s kerak)',
    '1058': 'Bu terminal chekini Kaftpay o\'zi fiskallaydi — chek havolasi '
        'qabul qilinmaydi',
    // Umumiy
    '1002': 'Kaftpay: ruxsat yo\'q',
    '9999': 'Kaftpay serverida kutilmagan xato',
  };

  static String? describe(String? code) => code == null ? null : _uz[code];

  static bool isKnown(String? code) => code != null && _uz.containsKey(code);
}
