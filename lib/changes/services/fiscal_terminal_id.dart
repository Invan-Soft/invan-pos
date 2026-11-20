// Fiskal modul raqami (TerminalID) — ONKM so'rovi uchun.
//
// Soliq xizmati ONKM tekshiruvida (`validation-onkm`) `terminalId` ni talab
// qiladi; usiz "Fiskal modul raqami noto'g'ri ko'rsatilgan" qaytaradi va kassir
// markirovkali tovarni sota olmaydi.
//
// Manba — lokal fiskal drayver (`Api.GetInfo`, `BaseService.getTerminalID`).
// Har skanda drayverga bormaslik uchun raqam xotirada saqlanadi; drayver javob
// bermasa oxirgi ma'lum raqam (Pref) ishlatiladi. Drayver javob bergach raqam
// yana undan olinadi — modul almashtirilsa eski raqam qolib ketmaydi.

import 'package:invan2/fiscal_service/base_service.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class FiscalTerminalId {
  const FiscalTerminalId._();

  /// Drayverga so'rov kassirni kutdiradi (skan yo'li) — qisqa bo'lsin.
  static const Duration timeout = Duration(seconds: 3);

  static String? _memo;

  /// Test uchun almashtiriladi.
  static Future<String> Function() fetcher = BaseService.getTerminalID;
  static String Function() readCache =
      () => Pref.getString(PrefKeys.fiscalTerminalIdCache, '');
  static Future<void> Function(String) writeCache =
      (v) => Pref.setString(PrefKeys.fiscalTerminalIdCache, v);

  /// Drayver xatoda `'no result'` / `'Unauthorized catch'` satrini qaytaradi —
  /// ular raqam emas. Raqam: faqat harf-raqam, bo'shliqsiz (masalan
  /// `UZ191211501012`).
  static bool isValid(String? v) =>
      v != null && RegExp(r'^[A-Za-z0-9]{8,}$').hasMatch(v);

  /// Fiskal modul raqami; aniqlab bo'lmasa bo'sh satr.
  static Future<String> get() async {
    final memo = _memo;
    if (memo != null) return memo;

    String fetched = '';
    try {
      fetched = (await fetcher().timeout(timeout)).trim();
    } catch (_) {}

    if (isValid(fetched)) {
      _memo = fetched;
      try {
        if (readCache() != fetched) await writeCache(fetched);
      } catch (_) {}
      return fetched;
    }

    // Drayver javob bermadi: oxirgi ma'lum raqam. Xotiraga yozilmaydi —
    // keyingi skanda drayver yana so'raladi.
    try {
      final cached = readCache().trim();
      if (isValid(cached)) return cached;
    } catch (_) {}
    return '';
  }

  /// Xotiradagi raqamni tashlaydi (test; fiskal modul almashganda).
  static void reset() => _memo = null;
}
