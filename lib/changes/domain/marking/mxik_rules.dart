// MXIK kodi bo'yicha markirovka qoidalari.
//
// OrderingProvider4 dan ajratildi (2026-08-05) — tanalar o'zgartirilmadi.
// Holatga bog'liq emas; [isProductMarkable] va undan kelib chiqadigan
// funksiyalar faqat `Pref` sozlamalarini o'qiydi.
//
// Testlar: test/mxik_rules_test.dart

import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/utils/helpers/marking_setting_helper.dart';
import 'package:invan2/utils/helpers/ofd_admin_setting.dart';

class MxikRules {
  const MxikRules._();

  /// MXIK kod markirovka talab qiladigan ro'yxatdami.
  static bool isMxikMarking(String mxikStr) =>
      mxikStr.startsWith('02009') ||
      mxikStr.startsWith('02201') ||
      mxikStr.startsWith('02202') ||
      isAlcoholMxik(mxikStr);

  /// MXIK kod alkogol mahsulotimi.
  static bool isAlcoholMxik(String mxikStr) =>
      mxikStr.startsWith('02203') ||
      mxikStr.startsWith('02204') ||
      mxikStr.startsWith('02205') ||
      mxikStr.startsWith('02206') ||
      mxikStr.startsWith('02207') ||
      mxikStr.startsWith('02208') ||
      mxikStr.startsWith('024');

  /// MXIK bo'yicha avto-aniqlash shu mahsulotga qo'llanadimi (sozlamalardan
  /// qat'i nazar — OFD va "Avto markirovkani aniqlash" ni chaqiruvchi tekshiradi).
  ///
  /// `is_marking` (adminka bayrog'i) — markirovkalilikning BIRINCHI mezoni:
  ///   - `false` — adminka aniq "markirovkali emas" degan. MXIK markirovka
  ///     ro'yxatida bo'lsa ham (adminkada MXIK xato kiritilgan) mahsulot
  ///     markirovkali deb HISOBLANMAYDI: markirovka dialogi chiqmaydi, savatga
  ///     oddiy qator tushadi; fiskalga statik MXIK ketadi (`FiscalMxikFallback`).
  ///     (2026-09-11, foydalanuvchi talabi)
  ///   - `null` — bayroq kelmagan: eski xatti-harakat, MXIK bo'yicha aniqlanadi.
  ///   - `true` — bu yerga kelmaydi (`isProductMarkable` avvalroq true qaytaradi).
  static bool isMxikAutoDetectCandidate(ItemModel product) =>
      product.isMarking != false &&
      isMxikMarking((product.mxikCode ?? '').trim());

  /// Mahsulot markirovkali deb hisoblanadimi.
  /// Qoidalar:
  ///   0) Adminkada OFD o'chiq bo'lsa — hech narsa markirovkali emas
  ///   1) `product.isMarking == true` → markirovkali (sozlamadan qat'iy nazar, OFD ON bo'lsa)
  ///   2) `product.isMarking == false` → markirovkali EMAS (MXIK tekshirilmaydi)
  ///   3) Aks holda (`null`) "Avto markirovkani aniqlash" sozlamasi yoqilgan
  ///      bo'lsa va MXIK kod ro'yxatda bo'lsa (`isMxikMarking`) → markirovkali
  ///   4) "Avto markirovkani aniqlash" o'chirilgan bo'lsa MXIK umuman tekshirilmaydi
  ///
  /// Savat qatorining `marking` bayrog'i ham shu qarorni ishlatadi
  /// (`SoldItemBuilder`) — aks holda OFD o'chiq bo'lsa ham qator markirovka
  /// guruhi bo'lib qolib, qty tahriri bloklanardi.
  /// `addProduct` va skaner yo'li (`OrderingProvider4`) ham xuddi shu
  /// [isMxikAutoDetectCandidate] ni ishlatadi — qoida bitta joyda.
  static bool isProductMarkable(ItemModel product) {
    if (!OfdAdminSetting.isEnabled) return false;
    if (product.isMarking ?? false) return true;
    if (!MarkingSettingHelper.isAutoDetectEnabled) return false;
    return isMxikAutoDetectCandidate(product);
  }

  /// Mahsulot uchun product_type ni aniqlaydi.
  /// Mahsulot markirovkali bo'lsagina type qaytaradi:
  ///   1) MXIK ro'yxatda topilsa → MXIK type ni qaytaradi
  ///   2) Aks holda default '5'
  ///   3) Markirovkali bo'lmasa bo'sh
  static String resolveProductType(ItemModel product) {
    if (!isProductMarkable(product)) return '';
    final mxikType = getProductType((product.mxikCode ?? '').trim());
    return mxikType.isNotEmpty ? mxikType : '5';
  }

  static String resolveProductPackage(ItemModel product) =>
      resolveProductType(product).isNotEmpty ? 'KIZ' : '';

  /// MXIK kodiga qarab product_type qaytaradi.
  /// Bo'sh string = bu mahsulot uchun type yo'q.
  static String getProductType(String mxik) {
    if (mxik.startsWith('024')) return '1'; // Sigareta
    if (mxik.startsWith('02203')) return '3'; // Pivo
    if (mxik.startsWith('02204') ||
        mxik.startsWith('02205') ||
        mxik.startsWith('02206') ||
        mxik.startsWith('02207') ||
        mxik.startsWith('02208')) {
      return '2'; // Alkogol (pivo emas)
    }
    if (mxik.startsWith('02009') ||
        mxik.startsWith('02201') ||
        mxik.startsWith('02202')) {
      return '5'; // Sharbat, suv va sovutuvchi ichimliklar
    }
    if (mxik.startsWith('030')) return '4'; // MXIK 030 → type 4, package KIZ
    if (mxik.startsWith('085')) return '6'; // MXIK 085 → type 6, package KIZ
    return '';
  }
}
