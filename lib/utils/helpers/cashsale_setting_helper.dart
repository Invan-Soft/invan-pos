import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/ofd_admin_setting.dart';
import 'package:invan2/utils/helpers/prefs.dart';

/// "Mahsulotning naqd to'lov cheklovini tekshirish" (cash_sale) sozlamasi
/// uchun yagona haqiqat manbai.
///
/// Bu cheklov soliq/OFD talabidan kelib chiqadi, shuning uchun u faqat
/// adminkada OFD (`apps_soliq_app`) yoqilgan bo'lsagina ma'noga ega.
/// Adminkadan OFD o'chirilgan bo'lsa — sozlama majburan `false` bo'ladi va
/// kassir uni sozlamalar sahifasidan yoqa olmaydi.
///
/// Juftligi: [MarkingSettingHelper].
class CashsaleSettingHelper {
  const CashsaleSettingHelper._();

  /// Kassir sozlamalar sahifasida bu switch'ni o'zgartira oladimi.
  static bool get isEditable => OfdAdminSetting.isEnabled;

  /// Cheklov amalda ishlayaptimi (UI ham, biznes logika ham shuni ishlatadi).
  static bool get isEnabled =>
      OfdAdminSetting.isEnabled &&
      Pref.getBool(PrefKeys.checkProductByCashsale, true);
}
