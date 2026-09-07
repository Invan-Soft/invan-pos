/*
    Server (backend) salomatligi — "oflayn" ni to'g'ri aniqlash uchun.

    Muammo: loyihada "oflayn" tushunchasi `InternetConnectionChecker` ga
    bog'langan edi — u 1.1.1.1 / 8.8.8.8 ga ping yuboradi, ya'ni *internet
    bormi?* degan savolga javob beradi. Kerakli savol esa boshqa: *bizning
    server javob beryaptimi?*

    Server yiqilganda internet BOR bo'ladi. Shu sabab ilova o'zini "onlayn"
    deb hisoblab, hamma joyda onlayn shoxni tanlaydi va har so'rov 500 yoki
    timeout bilan yiqiladi. Natijada server o'lishi internet o'lishidan
    YOMONROQ kechadi: internet uzilsa smena lokal ochiladi va sotuv ketadi,
    server o'lsa esa smena umuman ochilmaydi.

    Yechim: barcha so'rovlar bitta `ApiProvider` dan o'tadi — shu yerga
    "avtomatik o'chirgich" (circuit breaker) qo'yiladi. Ketma-ket bir necha
    xatodan keyin holat `down` bo'ladi va keyingi so'rovlar tarmoqqa umuman
    chiqmaydi: kassir har amalda 30 soniya kutmaydi, darhol javob oladi va
    mavjud oflayn shoxlar ishga tushadi.
*/

import 'dart:async';


import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/alice_service.dart';
import 'package:invan2/changes/services/log_helper.dart';

/// Xatolar chegaraga yetdi, lekin tekshiruv serverning tirikligini
/// ko'rsatdi — ya'ni muammo umumiy emas, aynan shu so'rovlarda.
class FalseAlarm {
  const FalseAlarm({required this.at, required this.paths});

  final DateTime at;
  final List<String> paths;

  @override
  String toString() => 'FalseAlarm(at: $at, paths: ${paths.join(", ")})';
}

/// Bizning backend hozir javob beryaptimi.
enum BackendStatus {
  /// Server javob beryapti (yoki hali yiqilgani aniqlanmagan).
  up,

  /// Server javob bermayapti — so'rovlar tarmoqqa chiqarilmaydi.
  down,
}

class BackendHealth {
  BackendHealth._();

  /// Holat `down` ga o'tishi uchun kerakli ketma-ket xatolar soni.
  ///
  /// Bittasi kam: tarmoqda tasodifiy uzilish bo'lishi mumkin, butun kassani
  /// oflayn rejimga o'tkazish uchun bu yetarli asos emas. Uchtasi — server
  /// haqiqatan yiqilganini bildiradigan ishonchli chegara.
  static const int failureThreshold = 3;

  /// `down` holatida serverni qayta tekshirish oralig'i.
  static const Duration probeInterval = Duration(seconds: 30);

  /// Tekshiruv so'rovining timeouti — u kassirni kutdirmaydi, fonda ketadi.
  static const Duration probeTimeout = Duration(seconds: 5);

  /// Gate to'sib qolgan so'rov shu status kod bilan qaytariladi.
  ///
  /// Manfiy kodlar `ApiProvider` da allaqachon ishlatiladi: -1 timeout,
  /// -2 kutilmagan xato. -3 — "server yiqilgan, so'rov yuborilmadi".
  static const int serverDownStatusCode = -3;

  /// UI shu orqali holatni kuzatadi (oflayn indikatori).
  static final ValueNotifier<BackendStatus> status =
      ValueNotifier<BackendStatus>(BackendStatus.up);

  /// Server yiqilganidan tiklangan payt chaqiriladi — navbatlarni
  /// (cheklar, smena) yuborishni shu yerdan qo'zg'atamiz.
  static VoidCallback? onRecovered;

  // ——— Test uchun almashtiriladigan bog'liqliklar ———

  /// Hozirgi vaqt. Testlarda soatni oldinga surish uchun almashtiriladi.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /// Internet bor-yo'qligini tekshiruvchi.
  @visibleForTesting
  static Future<bool> Function() internetCheck =
      () => InternetConnectionChecker().hasConnection;

  /// Serverni tekshiruvchi so'rov. `true` — server javob berdi.
  @visibleForTesting
  static Future<bool> Function() probeRequest = _defaultProbe;

  /// `down` holatida fon tekshiruvi taymeri yoqilsinmi.
  /// Testlarda haqiqiy taymer ishlamasligi uchun `false` qilinadi.
  @visibleForTesting
  static bool autoProbe = true;

  static int _consecutiveFailures = 0;
  static final Set<String> _failedPaths = <String>{};
  static bool _confirmInFlight = false;

  /// Oxirgi "yolg'on trevoga": xatolar bo'ldi-yu, server tirik chiqdi.
  /// Diagnostika uchun — muammoli endpointni ko'rsatadi.
  static FalseAlarm? lastFalseAlarm;
  static DateTime? _lastProbeAt;
  static DateTime? _downSince;
  static Timer? _probeTimer;
  static bool _probeInFlight = false;

  // ——— Holat ———

  static bool get isDown => status.value == BackendStatus.down;

  static bool get isUp => !isDown;

  /// Server qachondan beri yiqilgan (UI'da ko'rsatish uchun).
  static DateTime? get downSince => _downSince;

  /// Serverga borish MA'NOSI bormi — ya'ni internet ham bor, server ham tirik.
  ///
  /// Mavjud `InternetConnectionChecker().hasConnection` chaqiruvlari shunga
  /// almashtiriladi. Shunda server yiqilganda kod avtomatik ravishda
  /// oflayn shoxga tushadi — yangi oflayn mantiq yozish shart emas.
  static Future<bool> isUsable() async {
    if (isDown) return false; // internetni tekshirib o'tirmaymiz
    return internetCheck();
  }

  // ——— Natijalarni qayd etish ———

  /// Server javob berdi — holat sog'lom.
  static void recordSuccess() {
    _consecutiveFailures = 0;
    if (isDown) _goUp();
  }

  /// So'rov yiqildi (timeout / socket / 5xx).
  ///
  /// [path] — qaysi endpoint yiqildi (diagnostika uchun).
  ///
  /// Chegaraga yetilganda holat DARHOL `down` bo'lmaydi: avval serverning
  /// o'zi tekshiriladi. Sabab — 500 javob ikki xil ma'noni anglatishi
  /// mumkin:
  ///   1) server umuman yiqilgan (hamma so'rov 500);
  ///   2) server sog'lom, lekin AYNAN SHU so'rov serverda xatoga olib
  ///      keldi (masalan chekdagi ma'lumot serverda ishlov berilmayapti).
  ///
  /// Ikkinchi holatda butun kassani oflayn rejimga o'tkazish xato bo'lardi:
  /// bitta "buzuq" chek qayta-qayta yuborilib, sog'lom server bilan
  /// ishlayotgan kassani uzib qo'yardi. Shuning uchun qaror faqat
  /// tekshiruv so'rovi (`probeRequest`) natijasi bilan qabul qilinadi.
  static void recordFailure({String? path}) {
    if (isDown) return; // allaqachon yiqilgan, hisoblashning hojati yo'q
    _consecutiveFailures++;
    if (path != null && path.isNotEmpty) {
      _failedPaths.add(path);
    }
    if (_consecutiveFailures >= failureThreshold) {
      unawaited(_confirmThenDecide());
    }
  }

  /// Chegaraga yetildi — endi serverning o'zi tirikmi, tekshiramiz.
  static Future<void> _confirmThenDecide() async {
    if (_confirmInFlight || isDown) return;
    _confirmInFlight = true;
    try {
      final bool alive = await probeRequest();
      if (isDown) return; // orada holat o'zgargan bo'lsa tegmaymiz
      if (alive) {
        // Server javob beryapti — muammo umumiy emas, aynan shu
        // so'rov(lar)da. Kassani oflayn rejimga o'tkazmaymiz.
        if (kDebugMode) {
          debugPrint('BackendHealth: server TIRIK, muammo so\'rovlarda: '
              '${_failedPaths.join(", ")}');
        }
        lastFalseAlarm = FalseAlarm(at: now(), paths: _failedPaths.toList());
        _consecutiveFailures = 0;
        _failedPaths.clear();
      } else {
        _goDown();
      }
    } catch (_) {
      _goDown();
    } finally {
      _confirmInFlight = false;
    }
  }

  /// HTTP javobining status kodi bo'yicha holatni yangilaydi.
  static void recordStatusCode(int statusCode, {String? path}) {
    if (isServerFailureStatus(statusCode)) {
      recordFailure(path: path);
    } else {
      recordSuccess();
    }
  }

  /// Bu status kod "server yiqilgan" degani bo'ladimi.
  ///
  /// 4xx (400/401/403/404/409/422) — server TIRIK, shunchaki so'rovni rad
  /// etdi. Bunday javob holatni buzmasligi kerak, aks holda bitta noto'g'ri
  /// so'rov butun kassani oflayn rejimga tashlab yuboradi.
  static bool isServerFailureStatus(int statusCode) =>
      statusCode >= 500 || statusCode <= 0;

  /// Bu istisno "server yiqilgan" degani bo'ladimi.
  ///
  /// Tarmoq/ulanish istisnolari — ha. Boshqa xatolar (JSON parse va h.k.)
  /// serverning holatiga aloqador emas.
  static bool isNetworkFailure(Object error) {
    if (error is TimeoutException) return true;
    final String name = error.runtimeType.toString().toLowerCase();
    if (name.contains('socketexception') ||
        name.contains('clientexception') ||
        name.contains('handshakeexception') ||
        name.contains('httpexception')) {
      return true;
    }
    return false;
  }

  /// Server hozir tirikmi — TEKSHIRIB bilamiz (natija kutiladi).
  ///
  /// `isUp`/`isDown` dan farqi: bu xotiradagi holat emas, ayni damdagi
  /// haqiqat. Chaqiruvchi shu javob asosida qaror qabul qilishi mumkin,
  /// masalan "chek rad etildimi yoki server yiqilganmi".
  ///
  /// Yon ta'siri bor va bu ataylab: tekshiruv natijasi holatga ham
  /// yoziladi — server tirik chiqsa hisoblagich tozalanadi, o'lgan chiqsa
  /// oflayn rejimga darhol o'tiladi (chegara kutilmaydi, chunki bizda
  /// to'g'ridan-to'g'ri dalil bor).
  static Future<bool> isServerAlive() async {
    try {
      final bool alive = await probeRequest();
      if (alive) {
        recordSuccess();
      } else if (!isDown) {
        _goDown();
      }
      return alive;
    } catch (_) {
      if (!isDown) _goDown();
      return false;
    }
  }

  /// Serverga yuborilgan hujjat (chek, qaytarish) RAD ETILDI deb
  /// hisoblansinmi.
  ///
  /// Bu qaror og'ir: "rad etilgan" hujjat avtomatik navbatdan chiqariladi
  /// va faqat kassir qo'lda qayta yuborsagina ketadi. Shuning uchun uchta
  /// holat aniq ajratiladi:
  ///
  /// * `< 400` (va manfiy kodlar: timeout, ulanmadi, darvoza to'sdi) —
  ///   javob umuman kelmagan. Rad etish EMAS, navbatda qoladi.
  /// * `4xx` — server so'rovni ko'rib chiqib rad etdi. Qayta yuborish ham
  ///   xuddi shu javobni beradi → rad etilgan.
  /// * `5xx` — ikki xil ma'no: server umuman yiqilgan bo'lishi ham,
  ///   AYNAN SHU hujjat serverda xatoga olib kelayotgan bo'lishi ham
  ///   mumkin. Shuning uchun serverning o'zidan so'raymiz: tirik bo'lsa
  ///   ayb hujjatda → rad etilgan; o'lgan bo'lsa navbatda qoladi.
  static Future<bool> isDocumentRejection(int statusCode) async {
    if (statusCode < 400) return false;
    if (statusCode < 500) return true;
    return isServerAlive();
  }

  // ——— So'rov darvozasi ———

  /// So'rovni tarmoqqa chiqarish mumkinmi.
  ///
  /// `up` bo'lsa — doim ha. `down` bo'lsa — yo'q, faqat har
  /// [probeInterval] da bittasi o'tkaziladi (half-open tekshiruv).
  ///
  /// [force] — foydalanuvchi qo'lda boshlagan amal (login, "Yangilash"
  /// tugmasi). Kassir o'zi bosgan tugma "server o'chgan" degan xotira
  /// tufayli javobsiz qolmasligi kerak.
  static bool allowRequest({bool force = false}) {
    if (isUp) return true;
    if (force) {
      _lastProbeAt = now();
      return true;
    }
    final DateTime? last = _lastProbeAt;
    if (last == null || now().difference(last) >= probeInterval) {
      _lastProbeAt = now();
      return true;
    }
    return false;
  }

  /// Foydalanuvchi qo'lda amal boshladi — keyingi so'rov darvozadan
  /// o'tkazilsin.
  ///
  /// Kassir "Kirish" yoki "Yangilash" tugmasini bosganda javob o'rniga
  /// "server yiqilgan" degan XOTIRA tufayli jim qolish yomon: server allaqachon
  /// tiklangan bo'lishi mumkin, kassir esa buni bilmaydi. Bunday amallar
  /// har doim haqiqiy urinishga aylanadi.
  static void markUserInitiatedAction() {
    if (isDown) _lastProbeAt = null;
  }

  // ——— Ichki ———

  static void _goDown() {
    _failedPaths.clear();
    _downSince = now();
    _lastProbeAt = now();
    status.value = BackendStatus.down;
    if (kDebugMode) {
      debugPrint('BackendHealth: server DOWN (${DateTime.now()})');
    }
    _startProbing();
  }

  static void _goUp() {
    _consecutiveFailures = 0;
    _failedPaths.clear();
    _downSince = null;
    _stopProbing();
    status.value = BackendStatus.up;
    if (kDebugMode) {
      debugPrint('BackendHealth: server UP (${DateTime.now()})');
    }
    onRecovered?.call();
  }

  /// `down` holatida serverni o'zimiz tekshirib turamiz.
  ///
  /// Bu shart: oflayn rejimda kod serverga umuman murojaat qilmaydi, demak
  /// gate orqali o'tadigan so'rov ham bo'lmaydi. Tekshiradigan hech kim
  /// bo'lmasa holat abadiy `down` bo'lib qolardi.
  static void _startProbing() {
    if (!autoProbe || _probeTimer != null) return;
    _probeTimer = Timer.periodic(probeInterval, (_) => _runProbe());
  }

  static void _stopProbing() {
    _probeTimer?.cancel();
    _probeTimer = null;
  }

  static Future<void> _runProbe() async {
    if (_probeInFlight || isUp) return;
    _probeInFlight = true;
    try {
      _lastProbeAt = now();
      final bool alive = await probeRequest();
      if (alive) _goUp();
    } catch (_) {
      // Tekshiruv yiqildi — `down` holatida qolamiz.
    } finally {
      _probeInFlight = false;
    }
  }

  /// Tekshiruv so'raladigan yo'l.
  ///
  /// Ataylab HAQIQIY API endpointi, sayt ildizi emas: ildizni ko'pincha
  /// proksi/CDN o'zi qaytaradi va backend o'lgan bo'lsa ham 200 beradi.
  /// Bu yo'l esa API qatlamining tirikligini ko'rsatadi.
  static const String probePath = 'api/v1/shift_statuses';

  /// Standart tekshiruv.
  ///
  /// 5xx dan boshqa HAR QANDAY javob (401, 404 ham) "server tirik" degani —
  /// javob bera olayotgan bo'lsa demak API qatlami ishlayapti. Faqat 5xx,
  /// timeout yoki ulanmaslik "server yiqilgan" degani.
  ///
  /// Tekshiruv ATAYLAB `ApiProvider` orqali emas: u darvozadan o'tishi va
  /// natijani qayd etishi kerak emas — aks holda o'zini-o'zi chaqirgan
  /// halqa hosil bo'lardi.
  static Future<bool> _defaultProbe() async {
    if (_probeUrl.isEmpty) return false;
    try {
      final http.Response res = await http
          .get(Uri.parse('$_probeUrl$probePath'), headers: _probeHeaders())
          .timeout(probeTimeout);

      // Tekshiruv Alice va jurnalda KO'RINISHI kerak. U `ApiProvider` dan
      // o'tmaydi (o'zini-o'zi chaqirgan halqa bo'lardi), shuning uchun
      // qayd etishni shu yerda o'zimiz qilamiz. Aks holda kassa serverni
      // so'rab turgani holda tashqaridan "hech narsa qilmayapti" bo'lib
      // ko'rinadi — 2026-09-03 da aynan shunday chalkashlik bo'ldi.
      alice.onHttpResponse(res);
      unawaited(LogHelper.logRequest(
        method: "GET",
        path: '$probePath (BackendHealth tekshiruvi)',
        statusCode: res.statusCode,
        response: res.body,
      ));

      return res.statusCode < 500;
    } catch (e) {
      // Javob UMUMAN kelmadi (ulanish rad etildi / timeout). Alice faqat
      // haqiqiy javobni ko'rsata oladi, shuning uchun bu urinish u yerda
      // ko'rinmay qolardi va tashqaridan "kassa hech narsa qilmayapti"
      // degan taassurot tug'ilardi. Sun'iy yozuv qo'shamiz: status 0 —
      // "javob yo'q" degani, tanasida esa sababi turadi.
      try {
        alice.onHttpResponse(
          http.Response(
            'BackendHealth tekshiruvi: server javob bermadi\n$e',
            0,
            request: http.Request('GET', Uri.parse('$_probeUrl$probePath')),
          ),
        );
      } catch (_) {
        // Alice yozuvi ixtiyoriy — u yiqilsa tekshiruv baribir davom etadi.
      }
      unawaited(LogHelper.write(
        LogLevel.warn,
        'BackendHealth tekshiruvi yiqildi: $e',
      ));
      return false;
    }
  }

  /// Token bo'lsa qo'shamiz. Bo'lmasa ham muhim emas: 401 javobi ham
  /// serverning tirikligini isbotlaydi.
  static Map<String, String> Function() probeHeaders = () => const {};

  static Map<String, String> _probeHeaders() => probeHeaders();

  /// `ApiProvider.baseUrlINVAN2` shu yerga o'rnatiladi (aylanma importsiz).
  static String _probeUrl = '';

  static void configureProbeUrl(String baseUrl) => _probeUrl = baseUrl;

  /// Testlar uchun: holatni boshlang'ich ko'rinishga qaytaradi.
  @visibleForTesting
  static void reset() {
    _stopProbing();
    _consecutiveFailures = 0;
    _failedPaths.clear();
    _confirmInFlight = false;
    lastFalseAlarm = null;
    _lastProbeAt = null;
    _downSince = null;
    _probeInFlight = false;
    status.value = BackendStatus.up;
    onRecovered = null;
  }

  @visibleForTesting
  static int get consecutiveFailures => _consecutiveFailures;
}
