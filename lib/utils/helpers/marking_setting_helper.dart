import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/ofd_admin_setting.dart';
import 'package:invan2/utils/helpers/prefs.dart';

/// "Avto markirovkani aniqlash" (`sellProductsWithMarking`) sozlamasi uchun
/// yagona haqiqat manbai.
///
/// Bu sozlama MXIK kodiga qarab mahsulotni markirovkali deb hisoblashni
/// boshqaradi. Markirovka talabi soliq/OFD dan kelib chiqadi, shuning uchun
/// adminkada OFD o'chirilgan bo'lsa sozlama majburan `false` bo'ladi va kassir
/// uni sozlamalar sahifasidan yoqa olmaydi.
///
/// Juftligi: [CashsaleSettingHelper].
class MarkingSettingHelper {
  const MarkingSettingHelper._();

  /// Kassir sozlamalar sahifasida bu switch'ni o'zgartira oladimi.
  static bool get isEditable => OfdAdminSetting.isEnabled;

  /// MXIK bo'yicha avto-aniqlash amalda ishlayaptimi (UI ham, biznes logika
  /// ham shuni ishlatadi).
  static bool get isAutoDetectEnabled =>
      OfdAdminSetting.isEnabled &&
      Pref.getBool(PrefKeys.sellProductsWithMarking, true);
}
