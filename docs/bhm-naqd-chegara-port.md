# BHM naqd chegarasi: port qilish qo'llanmasi

**Manba:** `ayyubxon` branch, commitlar `cc66526` (BHM servis) va `c0ae23a` (to'liq yangilash + Alice), reliz 1.1.2+124 (2026-09-10).
**Diff bazasi:** `11a4770` → `efa4727` (faqat feature fayllari, `api_provider.dart` PRO almashuvi va `pubspec` kirmaydi).

Bu hujjat o'zgarishlarni **xuddi shu loyihaning boshqa nusxasiga** qo'lda ko'chirish uchun yozilgan. Yangi fayllar to'liq, o'zgargan fayllar diff ko'rinishida berilgan.

---

## 1. Nima va nima uchun

2026-07-20 393-son qaror va 2026-08-27 PF-175-son Farmon: **narxi BHMning 400 baravaridan oshadigan tovar/xizmat uchun naqd to'lov taqiqlanadi**, faqat karta yoki elektron to'lov.

Ilgari POS'da bu chegara kodga qattiq yozilgan edi (25 mln, `CashRestrictionRules.bigTotalLimit`). Endi:

- BHM (bazaviy hisoblash miqdori, ruscha БРВ) Soliq qo'mitasining ochiq API'sidan olinadi.
- Chegara = **BHM × 400**. 2026-09-10 holatiga BHM = 440 000 so'm → chegara **176 000 000** so'm.
- Qiymat lokalga (Hive `prefs`) saqlanadi, cheklov qoidasi faqat lokaldan o'qiydi.
- Yangilash kam bo'ladigan amalga bog'langan: "To'liq yangilash" dialogi (Сервис bosqichi) + startup (24 soat TTL).
- Har so'rov Alice'da ko'rinadi.

## 2. Soliq API

```
GET https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/<STIR>
accept: */*
```
Javob (2026-09-10):
```json
{"success":true,"reason":"So'rov bajarildi","data":true,"percent":12,
 "cashSaleAllowed":false,"fractionalSale":false,"baseCalculationAmount":440000}
```
- Auth kerak emas. Javob ~0.06 s.
- `<STIR>` — tashkilotning soliq raqami (`tax_payer_id`). POS'da u `PrefKeys.organizationINN` (`organization_inn`) Pref'ida turadi, `OrganizationSingleton.setOrgPrefs` yozadi (aktivlashtirish va "To'liq yangilash" → Организация bosqichi).
- Bizga faqat `baseCalculationAmount` kerak. `cashSaleAllowed`, `percent`, `data` hozircha ishlatilmaydi.
- STIR bo'sh bo'lsa (`tax_payer_id: ""`) so'rov yuborilmaydi, fallback ishlaydi.

## 3. Qanday ishlaydi

```
"To'liq yangilash" → Обновить
   Скидки → Товары → Категория → Организация (STIR Pref'ga yoziladi) → Сотрудники → Сервис
                                                                                      │
                                                                  BhmService.refresh('full-update')
                                                                                      │
                                    GET .../is-vat/<STIR> ──► 200 + baseCalculationAmount
                                                                                      │
                                                Pref: bhm_amount = 440000, bhm_fetched_at = now
                                                                                      │
Ilova startup (auth'dan keyin) ── refreshIfStale('startup') ── kesh 24 soatdan eski bo'lsagina ──┘

Sotuv paytida (tarmoqsiz):
   BhmService.cashLimit = (Pref bhm_amount > 0 ? bhm_amount : 440000) × 400
   CashRestrictionRules.bigTotalHidden(rows, ofdOn, cashsaleCheckOn, limit: cashLimit)
      → cashsale == 1 mahsulot qatorida price × qty > limit  →  naqd tugmasi yopiladi + ogohlantirish
```

**Hisoblash:** `cashLimit = bhm × multiplier`, `multiplier = 400`. Qat'iy `>`: aynan 176 000 000 ruxsat, 176 000 001 taqiq. Chegara **qator bo'yicha** (price × qty), chek jami bo'yicha emas (oldingi xatti-harakat saqlangan).

**Xato holatlari** (hammasi `false` qaytaradi, kesh O'ZGARMAYDI, exception chiqmaydi):
- STIR bo'sh → so'rov yuborilmaydi.
- HTTP ≠ 200, `success:false`, buzuq JSON, `baseCalculationAmount` yo'q yoki 0.
- Timeout (10 s), tarmoq yo'q.
- Xatoda `bhm_fetched_at` yangilanmaydi → kesh "eskirgan" qoladi → keyingi startup/to'liq yangilashda yana urinadi.

**Kesh bo'sh bo'lsa** (yangi o'rnatilgan, hech qachon so'ralmagan): `fallbackBhm = 440000` → chegara baribir 176 mln. Hech qachon 0 yoki eski 25 mln bo'lmaydi.

**Alice:** `BackendHealth` kabi qo'lda `alice.onHttpResponse(res)`. Javob kelmasa yoki STIR bo'sh bo'lsa **status 599** bilan sun'iy yozuv (tanasida sabab). 0 ishlatib bo'lmaydi: `http` 1.6.0 `statusCode < 100` ni `ArgumentError` bilan rad etadi.

## 4. O'zgarishlar ro'yxati

| Fayl | Tur | Nima |
|---|---|---|
| `lib/changes/services/cash_limit/bhm_service.dart` | YANGI | Servis: API → Pref kesh, `cashLimit`, fallback, TTL, in-flight guard, Alice, test inyeksiyalari |
| `test/bhm_service_test.dart` | YANGI | 19 test: fallback/kesh, refresh xato holatlari, TTL, parseAmount |
| `lib/utils/constants/pref_keys.dart` | o'zgargan | Ikkita yangi Pref kaliti (`bhm_amount`, `bhm_fetched_at`). |
| `lib/changes/domain/cart/cash_restriction_rules.dart` | o'zgargan | Qattiq `bigTotalLimit` konstantasi olib tashlandi, `bigTotalHidden` ga `required double limit` parametri qo'shildi. Sinf Pref'ga bog'lanmaydi. |
| `lib/changes/providers/ordering_provider_4.dart` | o'zgargan | `isBigTotalHidden` getteri `limit: BhmService.cashLimit` uzatadi. Import qo'shildi. |
| `lib/features/home/features/home_orders/order_list/order_list_item.dart` | o'zgargan | Savat qatoridagi takroriy qattiq son o'rniga `BhmService.cashLimit`. |
| `lib/changes/dialogs/upd/bloc/upd_bloc.dart` | o'zgargan | "To'liq yangilash" dialogining Сервис bosqichida `BhmService.refresh(reason: 'full-update')`. ASOSIY yangilash nuqtasi. |
| `lib/app/wrapper/wrapper.dart` | o'zgargan | Startup'da (auth'dan keyin, navbatlar flush'i yonida) `refreshIfStale` — 24 soat TTL bilan xavfsizlik to'ri. |
| `lib/utils/l10n/app_uz.arb` | o'zgargan | Ogohlantirish matni raqamsiz (eskirmaydi). Keyin `flutter gen-l10n`. |
| `lib/utils/l10n/app_ru.arb` | o'zgargan | Xuddi shu, ruscha. |
| `test/cash_restriction_rules_test.dart` | o'zgargan | `bigTotalHidden` guruhiga `limit:` parametri, qiymatlar 176 mln ga. |
| `test/cash_restriction_test.dart` | o'zgargan | Provider testlari 176 mln ga, `BhmService.clearCache()` setUp'da, Pref'dagi BHM chegarani boshqarishi testi. |

**Olib tashlangan:** `CashRestrictionRules.bigTotalLimit` konstantasi va `order_list_item.dart` dagi takroriy `25000000`.

**Bog'liqliklar:** yangi paket yo'q. `http` (mavjud), `alice` 0.4.2 (mavjud, `lib/alice_service.dart` dagi global `alice`), `LogHelper` (mavjud). Agar nusxada `lib/changes/domain/cart/cash_restriction_rules.dart` bo'lmasa (Faza 9.3 gacha), chegara `OrderingProvider4.isBigTotalHidden` ichida bo'ladi: u yerda `> 25000000` ni `> BhmService.cashLimit` ga almashtiring.

## 5. Qo'llash tartibi

1. `lib/utils/constants/pref_keys.dart` ga ikkita kalit qo'shing (diff 6.3).
2. `lib/changes/services/cash_limit/bhm_service.dart` ni to'liq yarating (6.1).
3. `cash_restriction_rules.dart` da konstantani olib, `limit` parametrini qo'shing (6.4). Chaqiruvchilar: `ordering_provider_4.dart` (6.5), `order_list_item.dart` (6.6).
4. `upd_bloc.dart` Сервис bosqichiga `refresh` (6.7). `wrapper.dart` startup'ga `refreshIfStale` (6.8).
5. l10n arb matnlari (6.9, 6.10), keyin `flutter gen-l10n`.
6. Testlar: `test/bhm_service_test.dart` (6.2), ikkita cheklov testi (6.11, 6.12). Testlar `test/support/provider_harness.dart` (`setUpPosTestEnv`, `makeSoldItem`) ga tayanadi.
7. `dart analyze` va `flutter test`.
8. Loyihada eski `25000000` / `bigTotalLimit` qolmaganini tekshiring: `grep -rnE "25000000|bigTotalLimit" lib test`.

## 6. Kod

### 6.1. YANGI: `lib/changes/services/cash_limit/bhm_service.dart`

```dart
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
```

### 6.2. YANGI: `test/bhm_service_test.dart`

```dart
// BhmService — naqd chegarasi (400 × BHM) manbai testlari.
//
// Nega kerak: bu qiymat noto'g'ri bo'lsa kassa yo qonunga zid naqd qabul
// qiladi, yo ruxsat etilgan sotuvda naqdni yopib qo'yadi. Shuning uchun
// fallback, kesh, TTL va xato holatlarida keshning buzilmasligi mixlanadi.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStir = '200523221';

/// Soliq API'ning 2026-09-10 dagi real javob shakli.
http.Response okResponse(int amount) => http.Response(
      jsonEncode({
        'success': true,
        'reason': "So'rov bajarildi",
        'data': true,
        'percent': 12,
        'cashSaleAllowed': false,
        'fractionalSale': false,
        'baseCalculationAmount': amount,
      }),
      200,
    );

void main() {
  setUpAll(() => setUpPosTestEnv('bhm_service_test', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  late List<Uri> calls;

  setUp(() async {
    calls = [];
    await BhmService.clearCache();
    await Pref.setString(PrefKeys.organizationINN, kStir);
    BhmService.now = DateTime.now;
    BhmService.request = (uri) async {
      calls.add(uri);
      return okResponse(440000);
    };
  });

  group('fallback va kesh', () {
    test('kesh bo\'sh → fallback 440 000, chegara 176 mln', () {
      expect(BhmService.hasCached, isFalse);
      expect(BhmService.bhm, 440000);
      expect(BhmService.cashLimit, 176000000);
    });

    test('keshda qiymat bo\'lsa u ustun', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 500000);
      expect(BhmService.bhm, 500000);
      expect(BhmService.cashLimit, 200000000);
    });

    test('keshda 0 bo\'lsa fallback', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 0);
      expect(BhmService.hasCached, isFalse);
      expect(BhmService.bhm, 440000);
    });
  });

  group('refresh', () {
    test('muvaffaqiyat → kesh va vaqt yoziladi, URL STIR bilan', () async {
      final fixed = DateTime(2026, 9, 10, 12);
      BhmService.now = () => fixed;
      BhmService.request = (uri) async {
        calls.add(uri);
        return okResponse(450000);
      };

      expect(await BhmService.refresh(reason: 'test'), isTrue);
      expect(calls.single.toString(), '${BhmService.endpoint}$kStir');
      expect(BhmService.bhm, 450000);
      expect(BhmService.cashLimit, 180000000);
      expect(BhmService.fetchedAt, fixed);
    });

    test('STIR yo\'q → so\'rov yuborilmaydi', () async {
      await Pref.setString(PrefKeys.organizationINN, '');
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(calls, isEmpty);
      expect(BhmService.hasCached, isFalse);
    });

    test('HTTP 401 → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response('{"status":401}', 401);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('success:false → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response(
          jsonEncode({'success': false, 'baseCalculationAmount': 999999}),
          200);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('JSON buzuq → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response('<html>', 200);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('so\'rov exception tashlasa → false, exception chiqmaydi', () async {
      BhmService.request = (_) async => throw Exception('timeout');
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.hasCached, isFalse);
    });

    test('amount 0 → rad etiladi', () async {
      BhmService.request = (_) async => okResponse(0);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.hasCached, isFalse);
    });

    test('parallel ikki chaqiruv → bitta so\'rov', () async {
      final results = await Future.wait([
        BhmService.refresh(reason: 'a'),
        BhmService.refresh(reason: 'b'),
      ]);
      expect(results, [true, true]);
      expect(calls.length, 1);
    });
  });

  group('refreshIfStale', () {
    test('kesh yo\'q → so\'raydi', () async {
      expect(await BhmService.refreshIfStale(reason: 'test'), isTrue);
      expect(calls.length, 1);
      expect(BhmService.hasCached, isTrue);
    });

    test('kesh yangi (TTL ichida) → so\'ramaydi', () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      calls.clear();

      BhmService.now = () => t0.add(const Duration(hours: 23));
      expect(await BhmService.refreshIfStale(reason: 'test'), isFalse);
      expect(calls, isEmpty);
    });

    test('kesh TTL dan eski → qayta so\'raydi', () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      calls.clear();

      BhmService.now = () => t0.add(BhmService.refreshInterval);
      expect(await BhmService.refreshIfStale(reason: 'test'), isTrue);
      expect(calls.length, 1);
    });

    test('yangilash yiqilsa eski kesh qoladi, keyingi safar yana urinadi',
        () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      BhmService.now = () => t0.add(const Duration(days: 2));
      BhmService.request = (_) async => throw Exception('offline');

      expect(await BhmService.refreshIfStale(reason: 'test'), isFalse);
      expect(BhmService.bhm, 440000);
      expect(BhmService.fetchedAt, t0);
      expect(BhmService.isStale, isTrue);
    });
  });

  group('parseAmount', () {
    test('to\'g\'ri javob', () {
      expect(
        BhmService.parseAmount(
            {'success': true, 'baseCalculationAmount': 440000}),
        440000,
      );
    });

    test('double ham qabul qilinadi', () {
      expect(BhmService.parseAmount({'baseCalculationAmount': 440000.0}),
          440000);
    });

    test('string rad etiladi', () {
      expect(
          BhmService.parseAmount({'baseCalculationAmount': '440000'}), isNull);
    });

    test('Map emas → null', () {
      expect(BhmService.parseAmount([1, 2]), isNull);
      expect(BhmService.parseAmount(null), isNull);
    });
  });
}
```

### 6.3. `lib/utils/constants/pref_keys.dart`

Ikkita yangi Pref kaliti (`bhm_amount`, `bhm_fetched_at`).

```diff
diff --git a/lib/utils/constants/pref_keys.dart b/lib/utils/constants/pref_keys.dart
index 1cd90a6..5c868b8 100644
--- a/lib/utils/constants/pref_keys.dart
+++ b/lib/utils/constants/pref_keys.dart
@@ -209,6 +209,13 @@ class PrefKeys {
   /// kalitga qarab tokenlarni tozalab, login sahifasiga qaytaradi.
   static const String apiEnv = 'api_env';
 
+  /// Soliq API'dan olingan BHM (Bazaviy Hisoblash Miqdori, so'm).
+  /// Naqd to'lov chegarasi = BHM × 400. Qarang: `BhmService`.
+  static const String bhmAmount = 'bhm_amount';
+
+  /// [bhmAmount] oxirgi marta qachon olingan (ms since epoch).
+  static const String bhmFetchedAt = 'bhm_fetched_at';
+
 
 
 }
```

### 6.4. `lib/changes/domain/cart/cash_restriction_rules.dart`

Qattiq `bigTotalLimit` konstantasi olib tashlandi, `bigTotalHidden` ga `required double limit` parametri qo'shildi. Sinf Pref'ga bog'lanmaydi.

```diff
diff --git a/lib/changes/domain/cart/cash_restriction_rules.dart b/lib/changes/domain/cart/cash_restriction_rules.dart
index 91b9a61..878996b 100644
--- a/lib/changes/domain/cart/cash_restriction_rules.dart
+++ b/lib/changes/domain/cart/cash_restriction_rules.dart
@@ -5,7 +5,8 @@
 //   1. FAQAT KARTA — kommunal xizmat MXIK lari (elektr, gaz, suv...)
 //   2. MARKIROVKA — alkogol/tamaki guruhlari (OFD sozlamasiga bog'liq)
 //   3. CASHSALE — katalogdagi `cashsale` bayrog'i: 0 = naqd taqiqlangan,
-//      1 = ruxsat, lekin qator jami 25 mln dan oshsa yana taqiqlanadi
+//      1 = ruxsat, lekin qator jami 400 × BHM dan oshsa yana taqiqlanadi
+//      (chegara `BhmService.cashLimit` dan parametr sifatida keladi)
 //
 // `OrderingProvider4` dan ko'chirildi (Faza 9.3) — tanalar o'zgarmagan.
 // Sozlama bayroqlari parametr sifatida keladi, shuning uchun qoidalar
@@ -18,9 +19,6 @@ import 'package:invan2/utils/constants/mxik_constants.dart';
 class CashRestrictionRules {
   const CashRestrictionRules._();
 
-  /// Naqd 25 mln dan oshgan `cashsale == 1` qator uchun yopiladi.
-  static const double bigTotalLimit = 25000000;
-
   /// Kommunal xizmat kabi faqat karta bilan to'lanadigan MXIK bormi.
   /// QAYD: o'chirilgan qatorlar ham sanaladi (hozirgi xatti-harakat).
   static bool cardOnlyRequired(List<ReceiptModelSoldItem4> rows) {
@@ -76,13 +74,16 @@ class CashRestrictionRules {
     return false;
   }
 
-  /// `cashsale == 1` mahsulotning QATOR jami 25 mln dan oshdimi.
-  /// QAYD: chegara qator bo'yicha — 2 × 20 mln savat jami 40 mln bo'lsa ham
+  /// `cashsale == 1` mahsulotning QATOR jami [limit] dan oshdimi.
+  /// [limit] — 400 × BHM (`BhmService.cashLimit`). Parametr sifatida keladi,
+  /// shunda qoida Pref/tarmoqsiz testlanadi.
+  /// QAYD: chegara qator bo'yicha — 2 × 100 mln savat jami 200 mln bo'lsa ham
   /// bu qoida ishlamaydi (hozirgi xatti-harakat).
   static bool bigTotalHidden(
     List<ReceiptModelSoldItem4> rows, {
     required bool ofdOn,
     required bool cashsaleCheckOn,
+    required double limit,
   }) {
     if (!ofdOn) return false;
     if (!cashsaleCheckOn) return false;
@@ -93,7 +94,7 @@ class CashRestrictionRules {
       final product = ItemsSingleton.getProductById(item.productId);
       if (product == null) continue;
       if ((product.cashsale ?? -1) != 1) continue;
-      if (item.price * item.value > bigTotalLimit) return true;
+      if (item.price * item.value > limit) return true;
     }
     return false;
   }
```

### 6.5. `lib/changes/providers/ordering_provider_4.dart`

`isBigTotalHidden` getteri `limit: BhmService.cashLimit` uzatadi. Import qo'shildi.

```diff
diff --git a/lib/changes/providers/ordering_provider_4.dart b/lib/changes/providers/ordering_provider_4.dart
index 3a40a9a..73f9e66 100644
--- a/lib/changes/providers/ordering_provider_4.dart
+++ b/lib/changes/providers/ordering_provider_4.dart
@@ -26,6 +26,7 @@ import 'package:invan2/changes/domain/barcode/scanned_product_lookup.dart';
 import 'package:invan2/changes/domain/barcode/tarozi_label.dart';
 import 'package:invan2/changes/domain/barcode/utsenka_qr.dart';
 import 'package:invan2/changes/domain/cart/cash_restriction_rules.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/changes/services/telegram_notifier.dart';
 import 'package:invan2/changes/domain/cart/deleted_item_recorder.dart';
 import 'package:invan2/changes/domain/cart/row_repricer.dart';
@@ -465,6 +466,7 @@ class OrderingProvider4 extends ChangeNotifier {
         _currentClient.orderedProducts,
         ofdOn: Pref.getBool(PrefKeys.markCheckWithOfd, true),
         cashsaleCheckOn: Pref.getBool('checkProductByCashsale', true),
+        limit: BhmService.cashLimit,
       );
 
   void resetCashRestrictionWarnings() {
```

### 6.6. `lib/features/home/features/home_orders/order_list/order_list_item.dart`

Savat qatoridagi takroriy qattiq son o'rniga `BhmService.cashLimit`.

```diff
diff --git a/lib/features/home/features/home_orders/order_list/order_list_item.dart b/lib/features/home/features/home_orders/order_list/order_list_item.dart
index a6e92c5..9df7ed8 100644
--- a/lib/features/home/features/home_orders/order_list/order_list_item.dart
+++ b/lib/features/home/features/home_orders/order_list/order_list_item.dart
@@ -1,4 +1,5 @@
 import 'package:flutter/material.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/features/get_products/singletons/items_singleton.dart';
 import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
 import 'package:invan2/features/home/features/home_orders/order_list/order_list_top.dart';
@@ -47,13 +48,13 @@ class OrderListItem extends StatelessWidget {
     return (product?.cashsale ?? 1) == 0;
   }
 
-  // Shartli taqiq: cashsale==1 va umumiy narx 25mln dan oshgan
+  // Shartli taqiq: cashsale==1 va qator jami 400 × BHM dan oshgan
   bool _isBigTotalRestricted() {
     if (!CashsaleSettingHelper.isEnabled) return false;
     final product = ItemsSingleton.getProductById(orderedProduct.productId);
     if (product == null) return false;
     if ((product.cashsale ?? -1) != 1) return false;
-    return (orderedProduct.price * orderedProduct.value) > 25000000;
+    return (orderedProduct.price * orderedProduct.value) > BhmService.cashLimit;
   }
 
   @override
```

### 6.7. `lib/changes/dialogs/upd/bloc/upd_bloc.dart`

"To'liq yangilash" dialogining Сервис bosqichida `BhmService.refresh(reason: 'full-update')`. ASOSIY yangilash nuqtasi.

```diff
diff --git a/lib/changes/dialogs/upd/bloc/upd_bloc.dart b/lib/changes/dialogs/upd/bloc/upd_bloc.dart
index ddce746..c3997f0 100644
--- a/lib/changes/dialogs/upd/bloc/upd_bloc.dart
+++ b/lib/changes/dialogs/upd/bloc/upd_bloc.dart
@@ -4,6 +4,7 @@ import 'package:flutter_bloc/flutter_bloc.dart';
 import 'package:hive_flutter/hive_flutter.dart';
 import 'package:invan2/changes/models/organization_model.dart';
 import 'package:invan2/changes/services/api/result_http_model.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/changes/services/get_items_service.dart';
 import 'package:invan2/changes/services/sync/sync_cursor.dart';
 import 'package:invan2/changes/services/company_app_service.dart';
@@ -115,6 +116,13 @@ class UpdBloc extends Bloc<UpdEvent, UpdState> {
         case APDstatus.service:
           {
             String? v = await _service(emit);
+            // Naqd chegarasi uchun BHM (400 × BHM) ni Soliq API'dan yangilash.
+            // Aynan shu yerda: "Организация" bosqichi STIR'ni Pref'ga yozib
+            // bo'lgan, va to'liq yangilash kassir ataylab bosadigan kam
+            // uchraydigan amal. Natija qatorning belgisiga ta'sir qilmaydi —
+            // BHM kelmasa eski kesh yoki fallback (176 mln) ishlayveradi.
+            // So'rov Alice'da ko'rinadi.
+            await BhmService.refresh(reason: 'full-update');
             List<UpdFailedRepo> r = _changeRepoStatus(i, v);
             emit(UpdLoadingState(repos: r));
           }
```

### 6.8. `lib/app/wrapper/wrapper.dart`

Startup'da (auth'dan keyin, navbatlar flush'i yonida) `refreshIfStale` — 24 soat TTL bilan xavfsizlik to'ri.

```diff
diff --git a/lib/app/wrapper/wrapper.dart b/lib/app/wrapper/wrapper.dart
index d422ad3..80a0a54 100644
--- a/lib/app/wrapper/wrapper.dart
+++ b/lib/app/wrapper/wrapper.dart
@@ -22,6 +22,7 @@ import 'package:invan2/changes/services/catalog_refresh_notice.dart';
 import 'package:invan2/changes/services/startup_progress.dart';
 import 'package:invan2/changes/services/discount_auto_sync_service.dart';
 import 'package:invan2/changes/services/health/backend_health.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/changes/services/receipt/refund_upload_queue.dart';
 import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
 import 'package:invan2/utils/helpers/network_error_helper.dart';
@@ -144,6 +145,11 @@ class _WrapperState extends State<Wrapper> {
           /// butunlay boshqa endpointdan boradi.
           unawaited(RefundUploadQueue.flush(reason: 'startup'));
 
+          /// Naqd chegarasi uchun BHM (400 × BHM). Kesh 24 soatdan eski
+          /// bo'lsagina Soliq API'ga boradi; "To'liq yangilash" (Сервис
+          /// bosqichi) ham yangilaydi. Fonda ketadi, startup'ni kutdirmaydi.
+          unawaited(BhmService.refreshIfStale(reason: 'startup'));
+
           // Startup yuklashi davomida "baza yangilanmagan" dialogi
           // chiqmasligi kerak — u yuklanish ekranining ustiga tushib qolardi.
           CatalogRefreshNotice.beginLoad();
```

### 6.9. `lib/utils/l10n/app_uz.arb`

Ogohlantirish matni raqamsiz (eskirmaydi). Keyin `flutter gen-l10n`.

```diff
diff --git a/lib/utils/l10n/app_uz.arb b/lib/utils/l10n/app_uz.arb
index 7bdf102..c63337f 100644
--- a/lib/utils/l10n/app_uz.arb
+++ b/lib/utils/l10n/app_uz.arb
@@ -260,7 +260,7 @@
   "perecisleniya": "Transferlar",
   "naqd_tolov_mumkin_emas": "Bu mahsulot basketga qo'shilganiga naqd pul orqali to'lab bo'lmaydi",
   "naqd_tolov_taqiq": "Naqd to'lov mumkin emas",
-  "narx_limit_oshdi": "Umumiy narx 25 mln dan oshdi",
+  "narx_limit_oshdi": "Umumiy narx BHMning 400 baravaridan oshdi",
   "notogri_format_qr": "Noto'g'ri formatdagi QR kod skanerlandi",
   "upd_discounts": "Chegirmalar",
   "upd_items": "Mahsulotlar",
```

### 6.10. `lib/utils/l10n/app_ru.arb`

Xuddi shu, ruscha.

```diff
diff --git a/lib/utils/l10n/app_ru.arb b/lib/utils/l10n/app_ru.arb
index a1bbe31..2b7b956 100644
--- a/lib/utils/l10n/app_ru.arb
+++ b/lib/utils/l10n/app_ru.arb
@@ -609,7 +609,7 @@
   "perecisleniya":"Перечисления",
   "naqd_tolov_mumkin_emas": "Оплата данного товара наличными невозможна",
   "naqd_tolov_taqiq": "Оплата наличными запрещена",
-  "narx_limit_oshdi": "Общая сумма превысила 25 млн",
+  "narx_limit_oshdi": "Общая сумма превысила 400 БРВ",
   "notogri_format_qr": "Отсканирован QR-код неправильного формата",
   "upd_discounts": "Скидки",
   "upd_items": "Товары",
```

### 6.11. `test/cash_restriction_rules_test.dart`

`bigTotalHidden` guruhiga `limit:` parametri, qiymatlar 176 mln ga.

```diff
diff --git a/test/cash_restriction_rules_test.dart b/test/cash_restriction_rules_test.dart
index 5564f7f..0bc9c6d 100644
--- a/test/cash_restriction_rules_test.dart
+++ b/test/cash_restriction_rules_test.dart
@@ -126,62 +126,71 @@ void main() {
   });
 
   group('bigTotalHidden', () {
-    bool run(double price, {double value = 1, int? cashsale = 1}) {
+    // 400 × 440 000. Qoida chegarani parametr sifatida oladi — manba
+    // (`BhmService`) alohida testlanadi (bhm_service_test.dart).
+    const kLimit = 176000000.0;
+
+    bool run(double price,
+        {double value = 1, int? cashsale = 1, double limit = kLimit}) {
       ItemsSingleton.products = [catalogItem('a', cashsale)];
       return CashRestrictionRules.bigTotalHidden(
         [makeSoldItem(productId: 'a', price: price, value: value)],
         ofdOn: true,
         cashsaleCheckOn: true,
+        limit: limit,
       );
     }
 
-    test('chegara konstantasi 25 mln', () {
-      expect(CashRestrictionRules.bigTotalLimit, 25000000);
-    });
-
     test('chegaradan 1 so\'m yuqori → true', () {
-      expect(run(25000001), isTrue);
+      expect(run(176000001), isTrue);
     });
 
     test('aynan chegara → false (qat\'iy >)', () {
-      expect(run(25000000), isFalse);
+      expect(run(176000000), isFalse);
+    });
+
+    test('chegara parametrdan olinadi — 10 000 bo\'lsa 10 001 → true', () {
+      expect(run(10001, limit: 10000), isTrue);
+      expect(run(10000, limit: 10000), isFalse);
     });
 
     test('narx × miqdor hisoblanadi', () {
-      expect(run(13000000, value: 2), isTrue);
+      expect(run(90000000, value: 2), isTrue);
     });
 
     test('cashsale 0 bu qoidaga kirmaydi', () {
-      expect(run(30000000, cashsale: 0), isFalse);
+      expect(run(180000000, cashsale: 0), isFalse);
     });
 
     test('cashsale null bu qoidaga kirmaydi', () {
-      expect(run(30000000, cashsale: null), isFalse);
+      expect(run(180000000, cashsale: null), isFalse);
     });
 
     test('OFD o\'chiq → false', () {
       ItemsSingleton.products = [catalogItem('a', 1)];
       expect(
         CashRestrictionRules.bigTotalHidden(
-          [makeSoldItem(productId: 'a', price: 30000000)],
+          [makeSoldItem(productId: 'a', price: 180000000)],
           ofdOn: false,
           cashsaleCheckOn: true,
+          limit: kLimit,
         ),
         isFalse,
       );
     });
 
-    test('QAYD: chegara QATOR bo\'yicha — 2 × 20 mln savat jami ishlamaydi',
+    test('QAYD: chegara QATOR bo\'yicha — 2 × 100 mln savat jami ishlamaydi',
         () {
       ItemsSingleton.products = [catalogItem('a', 1), catalogItem('b', 1)];
       expect(
         CashRestrictionRules.bigTotalHidden(
           [
-            makeSoldItem(productId: 'a', price: 20000000),
-            makeSoldItem(productId: 'b', price: 20000000),
+            makeSoldItem(productId: 'a', price: 100000000),
+            makeSoldItem(productId: 'b', price: 100000000),
           ],
           ofdOn: true,
           cashsaleCheckOn: true,
+          limit: kLimit,
         ),
         isFalse,
       );
```

### 6.12. `test/cash_restriction_test.dart`

Provider testlari 176 mln ga, `BhmService.clearCache()` setUp'da, Pref'dagi BHM chegarani boshqarishi testi.

```diff
diff --git a/test/cash_restriction_test.dart b/test/cash_restriction_test.dart
index 56cd503..a267d94 100644
--- a/test/cash_restriction_test.dart
+++ b/test/cash_restriction_test.dart
@@ -5,11 +5,12 @@
 // katalog. Faza 9 da alohida modulga ko'chiriladi — shuning uchun avval
 // HOZIRGI xatti-harakat to'liq muzlatiladi.
 //
-// Qamrov: har getterning har bir `if` shoxi, chegaraviy qiymatlar (25 mln,
+// Qamrov: har getterning har bir `if` shoxi, chegaraviy qiymatlar (400 × BHM = 176 mln,
 // cashsale 0/1/null), o'chirilgan qatorlar, bo'sh savat va Pref gate'lari.
 import 'package:flutter_test/flutter_test.dart';
 import 'package:invan2/changes/models/product/item_model.dart';
 import 'package:invan2/changes/providers/ordering_provider_4.dart';
+import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
 import 'package:invan2/features/get_products/singletons/items_singleton.dart';
 import 'package:invan2/utils/constants/pref_keys.dart';
 import 'package:invan2/utils/helpers/prefs.dart';
@@ -42,6 +43,8 @@ void main() {
   setUp(() async {
     ItemsSingleton.products = [];
     await enableCashsaleGates();
+    // Kesh bo'sh → fallback 440 000 × 400 = 176 mln.
+    await BhmService.clearCache();
     await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
   });
 
@@ -234,7 +237,7 @@ void main() {
     });
   });
 
-  group('isBigTotalHidden — cashsale == 1 va qator jami > 25 mln', () {
+  group('isBigTotalHidden — cashsale == 1 va qator jami > 400 × BHM (176 mln)', () {
     OrderingProvider4 withRow({
       int? cashsale = 1,
       double price = 5000,
@@ -256,47 +259,54 @@ void main() {
 
     test('markCheckWithOfd o\'chiq bo\'lsa false', () async {
       await Pref.setBool(PrefKeys.markCheckWithOfd, false);
-      expect(withRow(price: 30000000).isBigTotalHidden, isFalse);
+      expect(withRow(price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('checkProductByCashsale o\'chiq bo\'lsa false', () async {
       await Pref.setBool('checkProductByCashsale', false);
-      expect(withRow(price: 30000000).isBigTotalHidden, isFalse);
+      expect(withRow(price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('bo\'sh savatda false', () {
       expect(freshProvider().isBigTotalHidden, isFalse);
     });
 
-    test('25 000 001 → true', () {
-      expect(withRow(price: 25000001).isBigTotalHidden, isTrue);
+    test('176 000 001 → true', () {
+      expect(withRow(price: 176000001).isBigTotalHidden, isTrue);
     });
 
-    test('CHEGARA: aynan 25 000 000 → false (qat\'iy >)', () {
-      expect(withRow(price: 25000000).isBigTotalHidden, isFalse);
+    test('CHEGARA: aynan 176 000 000 → false (qat\'iy >)', () {
+      expect(withRow(price: 176000000).isBigTotalHidden, isFalse);
     });
 
-    test('price × value hisoblanadi (10 mln × 3 = 30 mln → true)', () {
-      expect(withRow(price: 10000000, value: 3).isBigTotalHidden, isTrue);
+    test('chegara Pref\'dagi BHM dan hisoblanadi (500 000 × 400 = 200 mln)',
+        () async {
+      await Pref.setInt(PrefKeys.bhmAmount, 500000);
+      expect(withRow(price: 176000001).isBigTotalHidden, isFalse);
+      expect(withRow(price: 200000001).isBigTotalHidden, isTrue);
+    });
+
+    test('price × value hisoblanadi (60 mln × 3 = 180 mln → true)', () {
+      expect(withRow(price: 60000000, value: 3).isBigTotalHidden, isTrue);
     });
 
     test('cashsale == 0 bo\'lsa bu getter false (u qat\'iy taqiqqa tegishli)',
         () {
-      expect(withRow(cashsale: 0, price: 30000000).isBigTotalHidden, isFalse);
+      expect(withRow(cashsale: 0, price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('cashsale == null bo\'lsa false (-1 default, 1 ga teng emas)', () {
       expect(
-          withRow(cashsale: null, price: 30000000).isBigTotalHidden, isFalse);
+          withRow(cashsale: null, price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('katalogda topilmasa false', () {
       expect(
-          withRow(inCatalog: false, price: 30000000).isBigTotalHidden, isFalse);
+          withRow(inCatalog: false, price: 180000000).isBigTotalHidden, isFalse);
     });
 
     test('o\'chirilgan qator hisobga olinmaydi', () {
-      expect(withRow(price: 30000000, deleted: true).isBigTotalHidden, isFalse);
+      expect(withRow(price: 180000000, deleted: true).isBigTotalHidden, isFalse);
     });
 
     test('ikkita qatordan biri oshsa true', () {
@@ -307,20 +317,20 @@ void main() {
       final p = freshProvider();
       p.getCurrentClient.orderedProducts
         ..add(makeSoldItem(productId: 'a', price: 1000))
-        ..add(makeSoldItem(productId: 'b', price: 26000000));
+        ..add(makeSoldItem(productId: 'b', price: 177000000));
       expect(p.isBigTotalHidden, isTrue);
     });
 
     test('QAYD: chegara QATOR bo\'yicha, savat jami bo\'yicha emas', () {
-      // 2 × 20 mln = 40 mln, lekin hech bir QATOR 25 mln dan oshmaydi.
+      // 2 × 100 mln = 200 mln, lekin hech bir QATOR 176 mln dan oshmaydi.
       ItemsSingleton.products = [
         productWithCashsale('a', 1),
         productWithCashsale('b', 1),
       ];
       final p = freshProvider();
       p.getCurrentClient.orderedProducts
-        ..add(makeSoldItem(productId: 'a', price: 20000000))
-        ..add(makeSoldItem(productId: 'b', price: 20000000));
+        ..add(makeSoldItem(productId: 'a', price: 100000000))
+        ..add(makeSoldItem(productId: 'b', price: 100000000));
       expect(p.isBigTotalHidden, isFalse);
     });
   });
```

## 7. Tekshirish

```bash
flutter test test/bhm_service_test.dart test/cash_restriction_rules_test.dart test/cash_restriction_test.dart
dart analyze lib/changes/services/cash_limit/bhm_service.dart lib/changes/domain/cart/cash_restriction_rules.dart
curl -s 'https://txkm.soliq.uz/api/txkm-api/ccm-api/info/check/is-vat/<STIR>' -H 'accept: */*'
```
Ilovada: "To'liq yangilash" → Обновить → Sozlamalar → Alice: `txkm.soliq.uz` GET, 200, `baseCalculationAmount`. Jurnal (`request_logs_of_invan_pos.txt`): `BHM (full-update): 0 → 440000, naqd chegarasi 176000000`. Keyin `cashsale == 1` mahsulotdan 176 000 001 so'mlik qator → naqd tugmasi yopiq, 176 000 000 → ochiq.

STIR bo'sh kompaniyada: jurnalda `BHM (full-update): STIR yo'q, so'rov yuborilmadi`, Alice'da 599 yozuv, chegara fallback 176 mln.

## 8. Eslatmalar va ochiq savollar

- **`http` ≥ 1.3:** `http.Response(..., 0)` ArgumentError tashlaydi. Sun'iy Alice yozuvlarida 599 ishlating. Asl loyihadagi `BackendHealth` (backend_health.dart ~406) hali 0 ishlatadi va shu sabab u yozuv Alice'da chiqmaydi — nusxada ham bir xil bo'lsa 599 ga o'zgartiring.
- **Qator vs chek jami:** qonun matni "tovar va xizmatlar uchun to'lovlar" deydi, aniq emas. Hozir qator bo'yicha (2 × 100 mln savat naqdga ochiq). Soliq texnik qo'llanmasi bilan aniqlashtirish kerak.
- **`cashSaleAllowed`** maydoni (API javobida `false` keldi) nimani anglatishi aniqlanmagan. Ishlatilmaydi.
- **STIR bo'sh** (`tax_payer_id: ""`) tashkilotda BHM hech qachon so'ralmaydi, fallback 176 mln ishlaydi. STIR fiskal chekda `ownerTin` sifatida ham ketadi, demak do'konlarda odatda to'ldirilgan.
- **Startup hook** ixtiyoriy: uni olib tashlasangiz faqat "To'liq yangilash" qoladi. Fallback tufayli xavfsiz.
- **BHM o'zgarsa** (yiliga bir-ikki marta): kodga tegish shart emas, keyingi to'liq yangilash yoki startup yangi qiymatni oladi. `fallbackBhm` ni ham yangilab qo'yish foydali, shart emas.
