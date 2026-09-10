/*
    BHM (Bazaviy Hisoblash Miqdori) — naqd to'lov chegarasining manbai.

    Qonun (2026-07-20 393-son qaror, 2026-08-27 PF-175 Farmon): narxi
    400 × BHM dan oshadigan tovar/xizmat uchun naqd to'lov taqiqlanadi.
    BHM qiymati kodga qattiq yozilmaydi — Soliq qo'mitasining ochiq
    API'sidan olinadi (auth talab qilinmaydi, tashkilot STIR'i URL'ga
    qo'shiladi):

      GET https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/<STIR>
      → {"success":true, ..., "baseCalculationAmount":440000}

    Oqim:
      1. API'dan olingan qiymat darhol Pref'ga yoziladi
         (`bhm_amount` + `bhm_fetched_at`).
      2. Cheklov qoidasi (`CashRestrictionRules.bigTotalHidden`) faqat
         Pref'dagi qiymatdan hisoblangan [cashLimit] ni oladi — sotuv
         paytida tarmoqqa hech qachon chiqilmaydi.
      3. Yangilash ikki joyda:
         - "To'liq yangilash" dialogining "Сервис" bosqichi (`UpdBloc`) —
           har doim so'raydi. "Организация" bosqichi STIR'ni yozib
           bo'lgan, va bu kassir ataylab bosadigan kam uchraydigan amal.
         - Ilova ishga tushganda (`Wrapper`) — [refreshInterval] TTL bilan,
           xavfsizlik to'ri sifatida.
         BHM yiliga bir-ikki marta o'zgaradi, tez-tez so'rash shart emas.
      4. Kesh bo'sh bo'lsa (birinchi ishga tushish, oflayn) [fallbackBhm]
         ishlatiladi — 2026-09-10 holatiga ko'ra API bergan qiymat.
      5. Har so'rov Alice'da ko'rinadi (`BackendHealth` kabi qo'lda qayd
         etiladi, chunki bu so'rov `ApiProvider` dan o'tmaydi). Javob umuman
         kelmasa status 599 bilan sun'iy yozuv qo'shiladi — aks holda
         tashqaridan "kassa hech narsa so'ramadi" bo'lib ko'rinardi.
*/

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:invan2/alice_service.dart';
import 'package:invan2/changes/services/log_helper.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class BhmService {
  BhmService._();

  /// Soliq API. Oxiriga tashkilot STIR'i qo'shiladi.
  static const String endpoint =
      'https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/';

  /// Kesh bo'sh bo'lganda ishlatiladigan BHM (so'm).
  ///
  /// 2026-09-10 da API qaytargan qiymat. Yangi BHM e'lon qilinsa buni ham
  /// yangilab qo'yish foydali, lekin shart emas — birinchi muvaffaqiyatli
  /// so'rov keshni to'ldiradi va shundan keyin bu son ishlatilmaydi.
  static const int fallbackBhm = 440000;

  /// Naqd chegarasi = BHM × shu ko'paytma (qonunda 400).
  static const int multiplier = 400;

  /// Keshdagi qiymat shu muddatdan eski bo'lsa qayta so'raladi.
  static const Duration refreshInterval = Duration(hours: 24);

  /// So'rov timeouti — fonda ketadi, kassirni kutdirmaydi.
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Alice'dagi sun'iy yozuv uchun status: javob umuman kelmadi.
  /// 599 — "Network Connect Timeout Error" (norasmiy, lekin keng tarqalgan);
  /// haqiqiy server kodlari bilan aralashmaydi va Alice'da qizil ko'rinadi.
  static const int noResponseStatus = 599;

  /// Test uchun almashtiriladigan HTTP so'rov.
  static Future<http.Response> Function(Uri uri) request = _defaultRequest;

  /// Test uchun almashtiriladigan soat.
  static DateTime Function() now = DateTime.now;

  static Future<http.Response> _defaultRequest(Uri uri) =>
      http.get(uri, headers: const {'accept': '*/*'}).timeout(requestTimeout);

  /// Bir vaqtda ikki so'rov ketmasin (startup va smena ochilishi ustma-ust
  /// tushishi mumkin) — ikkinchisi birinchisining natijasini kutadi.
  static Future<bool>? _inFlight;

  /// Joriy BHM (so'm): keshdan, u bo'lmasa [fallbackBhm].
  static int get bhm {
    final cached = Pref.getInt(PrefKeys.bhmAmount, 0);
    return cached > 0 ? cached : fallbackBhm;
  }

  /// Naqd to'lov chegarasi (so'm) = [bhm] × [multiplier].
  static double get cashLimit => (bhm * multiplier).toDouble();

  /// Keshda API'dan olingan qiymat bormi.
  static bool get hasCached => Pref.getInt(PrefKeys.bhmAmount, 0) > 0;

  /// Oxirgi muvaffaqiyatli so'rov vaqti; hech qachon olinmagan bo'lsa null.
  static DateTime? get fetchedAt {
    final ms = Pref.getInt(PrefKeys.bhmFetchedAt, 0);
    return ms > 0 ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
  }

  /// Kesh yo'q yoki [refreshInterval] dan eski.
  static bool get isStale {
    final at = fetchedAt;
    if (at == null) return true;
    return now().difference(at) >= refreshInterval;
  }

  /// Kesh eskirgan bo'lsagina API'ga boradi. Qaytaradi: kesh yangilandimi.
  static Future<bool> refreshIfStale({required String reason}) {
    if (!isStale) return Future.value(false);
    return refresh(reason: reason);
  }

  /// API'dan BHM olib keshga yozadi.
  ///
  /// Har qanday xatoda kesh O'ZGARMAYDI va `false` qaytadi — chaqiruvchi
  /// tomonga exception chiqmaydi, chunki bu fon amali va uning yiqilishi
  /// smena ochilishi yoki startup'ni to'xtatmasligi kerak.
  static Future<bool> refresh({required String reason}) {
    final running = _inFlight;
    if (running != null) return running;
    final f = _refresh(reason).whenComplete(() => _inFlight = null);
    _inFlight = f;
    return f;
  }

  static Future<bool> _refresh(String reason) async {
    final stir = Pref.getString(PrefKeys.organizationINN, '').trim();
    final uri = Uri.parse('$endpoint$stir');
    if (stir.isEmpty) {
      // Tashkilotda `tax_payer_id` bo'sh — so'rov yuborib bo'lmaydi.
      // Alice'da ham ko'rinsin, aks holda "nega so'ramadi" degan savol
      // tashqaridan javobsiz qoladi.
      _toAlice(http.Response(
        'BHM ($reason): tashkilot STIR\'i (tax_payer_id) bo\'sh, so\'rov yuborilmadi. '
        'Fallback: $fallbackBhm × $multiplier = ${fallbackBhm * multiplier}',
        noResponseStatus,
        request: http.Request('GET', uri),
      ));
      await _log(LogLevel.warn, 'BHM ($reason): STIR yo\'q, so\'rov yuborilmadi');
      return false;
    }
    try {
      final res = await request(uri);
      _toAlice(res);
      if (res.statusCode != 200) {
        await _log(LogLevel.warn, 'BHM ($reason): HTTP ${res.statusCode}');
        return false;
      }
      final amount = parseAmount(jsonDecode(res.body));
      if (amount == null) {
        await _log(LogLevel.warn,
            'BHM ($reason): javobda baseCalculationAmount yo\'q: ${res.body}');
        return false;
      }
      final previous = Pref.getInt(PrefKeys.bhmAmount, 0);
      await Pref.setInt(PrefKeys.bhmAmount, amount);
      await Pref.setInt(PrefKeys.bhmFetchedAt, now().millisecondsSinceEpoch);
      await _log(LogLevel.info,
          'BHM ($reason): $previous → $amount, naqd chegarasi ${amount * multiplier}');
      return true;
    } catch (e) {
      // Javob UMUMAN kelmadi (timeout, ulanish yo'q, DNS). Alice faqat
      // haqiqiy javobni ko'rsata oladi — sun'iy yozuv, tanasida sabab.
      // Status [noResponseStatus]: `http` paketi 100 dan kichik kodni
      // (masalan 0) qabul qilmaydi — `ArgumentError: Invalid status code`.
      _toAlice(http.Response(
        'BHM ($reason): Soliq API javob bermadi\n$e',
        noResponseStatus,
        request: http.Request('GET', uri),
      ));
      await _log(LogLevel.warn, 'BHM ($reason): so\'rov yiqildi: $e');
      return false;
    }
  }

  /// Alice'ga qayd etadi. Alice `request` maydoni bo'sh javobni (testlardagi
  /// sun'iy javob) o'zi o'tkazib yuboradi; boshqa har qanday xato ham asosiy
  /// oqimni to'xtatmasligi kerak.
  static void _toAlice(http.Response res) {
    try {
      alice.onHttpResponse(res);
    } catch (_) {}
  }

  /// API javobidan BHM ni ajratadi. Shakl noto'g'ri bo'lsa null.
  static int? parseAmount(dynamic body) {
    if (body is! Map) return null;
    if (body['success'] == false) return null;
    final raw = body['baseCalculationAmount'];
    if (raw is! num) return null;
    final v = raw.toInt();
    return v > 0 ? v : null;
  }

  /// Keshni tozalaydi (testlar uchun).
  static Future<void> clearCache() async {
    await Pref.removeWithKey(PrefKeys.bhmAmount);
    await Pref.removeWithKey(PrefKeys.bhmFetchedAt);
  }

  static Future<void> _log(LogLevel level, String msg) async {
    try {
      await LogHelper.write(level, msg);
    } catch (_) {
      // Log yozilmasa ham asosiy oqim to'xtamasin.
    }
  }
}
