import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/log_service.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/auth_backup.dart';
import 'package:invan2/utils/helpers/prefs.dart';

/// Tokenlarni va lokal keshni tozalash (logout) uchun yagona joy.
///
/// Ilgari bu qadamlar faqat Sozlamalar > "Tizimdan chiqish" ichida yozilgan
/// edi; endi startup'dagi muhit almashuvi tekshiruvi ham shu yerdan
/// foydalanadi — token faylini o'chirishni unutib qo'yish xavfi yo'q.
class AuthReset {
  const AuthReset._();

  /// Token, auth bayrog'i, disk backup va barcha Hive keshini tozalaydi.
  ///
  /// ObjectBox'dagi cheklarga TEGMAYDI — serverga ketmagan cheklar logout
  /// bo'lsa ham saqlanib qolishi kerak.
  ///
  /// Navigatsiya qilmaydi: chaqiruvchi tomon o'zi login sahifasiga o'tkazadi.
  static Future<void> clearAuthAndCache() async {
    await Pref.setBool(PrefKeys.authenticationBool, false);
    await AuthBackup.delete();

    // prefBox ham shu yerda tozalanadi — token, shop/pos ma'lumotlari
    // hammasi shu box ichida.
    await HiveBoxes.clearAllBoxes();
    ItemsSingleton.clearTheProducts();

    // clearAllBoxes prefBox'ni ham tozalagani uchun login sahifasigacha
    // kerak bo'ladigan qiymatlar qayta yoziladi.
    await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
    await Pref.setString(PrefKeys.version, await LogService.getAppVersion() ?? '');
    await Pref.setString(PrefKeys.apiEnv, ApiProvider.currentEnv);
  }

  /// Build API muhiti (dev↔pro) oldingi ishga tushirishdagidan farq qilsa
  /// tokenlarni tozalaydi va `true` qaytaradi — chaqiruvchi login sahifasiga
  /// o'tkazishi kerak.
  ///
  /// Nima uchun kerak: dev va pro tokenlari bir-biriga yaramaydi. Muhit
  /// almashtirilgach eski token bilan qolinsa, ilova "kirgan" ko'rinadi-yu
  /// har bir so'rov 401 bilan qaytadi.
  ///
  /// Kalit yo'q bo'lsa `pro` deb hisoblanadi: mavjud pro o'rnatishlar shu
  /// o'zgarishdan keyin ham logout bo'lib qolmaydi.
  static Future<bool> resetIfApiEnvChanged() async {
    final String saved = Pref.getString(PrefKeys.apiEnv, ApiProvider.envPro);
    final String current = ApiProvider.currentEnv;

    if (saved == current) {
      await Pref.setString(PrefKeys.apiEnv, current);
      return false;
    }

    await clearAuthAndCache();
    return true;
  }
}
