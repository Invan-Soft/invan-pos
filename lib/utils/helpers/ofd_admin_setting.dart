import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

/// Adminkadan kelgan OFD (`apps_soliq_app`) holati uchun yagona haqiqat manbai.
///
/// OFD dan kelib chiqadigan sozlamalar (naqd to'lov cheklovi, avto markirovkani
/// aniqlash) faqat OFD yoqilgan bo'lsagina ma'noga ega. Adminkada OFD o'chiq
/// bo'lsa ular majburan `false` bo'ladi va kassir ularni yoqa olmaydi.
///
/// Ilgari `markCheckWithOfd` loyiha bo'ylab har xil default bilan o'qilardi
/// (ba'zi joyda `false`, ba'zi joyda `true`) — shu sinf o'sha chalkashlikni
/// yopadi.
class OfdAdminSetting {
  const OfdAdminSetting._();

  /// Kalit umuman yozilmagan holatdagi qiymat.
  ///
  /// `true` — fail-safe yo'nalish: kalit yo'qolsa OFD cheklovlari o'chib
  /// qolgandan ko'ra yoqiq qolgani xavfsizroq. Amalda kalit Activate POS va
  /// Update POS oqimlarida doim yoziladi, shuning uchun bu faqat aktivatsiyaga
  /// qadar bo'lgan chetki holat.
  static const bool _fallback = true;

  /// Adminkada OFD yoqilganmi.
  static bool get isEnabled =>
      Pref.getBool(PrefKeys.markCheckWithOfd, _fallback);

  /// Adminkadan kelgan OFD holatiga qarab bog'liq sozlamalarni sinxronlaydi.
  ///
  /// OFD o'chirilgan bo'lsa sozlamalar diskda ham `false` ga tushiriladi,
  /// shunda keyin OFD qayta yoqilsa kassir ularni ongli ravishda yoqishi kerak.
  /// Activate POS / Update POS oqimlarida chaqiriladi.
  static Future<void> syncDependentSettings(bool ofdEnabledByAdmin) async {
    if (ofdEnabledByAdmin) return;
    await Pref.setBool(PrefKeys.checkProductByCashsale, false);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, false);
  }
}
