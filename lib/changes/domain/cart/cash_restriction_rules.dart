// Naqd to'lovni cheklash qoidalari.
//
// To'lov ekranida naqd tugmasi ba'zi savatlar uchun ko'rsatilmaydi.
// Uch xil sabab bor va ular bir-biridan mustaqil:
//   1. FAQAT KARTA — kommunal xizmat MXIK lari (elektr, gaz, suv...)
//   2. MARKIROVKA — alkogol/tamaki guruhlari (OFD sozlamasiga bog'liq)
//   3. CASHSALE — katalogdagi `cashsale` bayrog'i: 0 = naqd taqiqlangan,
//      1 = ruxsat, lekin qator jami 25 mln dan oshsa yana taqiqlanadi
//
// `OrderingProvider4` dan ko'chirildi (Faza 9.3) — tanalar o'zgarmagan.
// Sozlama bayroqlari parametr sifatida keladi, shuning uchun qoidalar
// Pref/Hive'siz testlanadi.

import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/mxik_constants.dart';

class CashRestrictionRules {
  const CashRestrictionRules._();

  /// Naqd 25 mln dan oshgan `cashsale == 1` qator uchun yopiladi.
  static const double bigTotalLimit = 25000000;

  /// Kommunal xizmat kabi faqat karta bilan to'lanadigan MXIK bormi.
  /// QAYD: o'chirilgan qatorlar ham sanaladi (hozirgi xatti-harakat).
  static bool cardOnlyRequired(List<ReceiptModelSoldItem4> rows) {
    if (rows.isEmpty) return false;

    return rows.any((item) {
      final mxik = item.mxik.trim();
      return mxik.isNotEmpty && MxikConstants.cardOnlyMxikCodes.contains(mxik);
    });
  }

  /// Markirovka guruhlari (alkogol/tamaki) uchun naqd yopiladimi.
  /// QAYD: o'chirilgan qatorlar ham sanaladi (hozirgi xatti-harakat).
  static bool cashHiddenByMarking(
    List<ReceiptModelSoldItem4> rows, {
    required bool ofdOn,
    required bool markingSaleOn,
  }) {
    if (!ofdOn) return false;
    if (!markingSaleOn) return false;
    if (rows.isEmpty) return false;

    return rows.any((item) {
      final mxik = item.mxik.trim();
      if (mxik.isEmpty) return false;
      return mxik.startsWith('02203') ||
          mxik.startsWith('02204') ||
          mxik.startsWith('02205') ||
          mxik.startsWith('02206') ||
          mxik.startsWith('02207') ||
          mxik.startsWith('02208') ||
          mxik.startsWith('024');
    });
  }

  /// `cashsale == 0` mahsulot bormi — naqd qat'iy taqiqlanadi.
  /// Katalogda topilmagan mahsulot ruxsat etilgan (default 1) deb olinadi.
  static bool cashHiddenByCashsale(
    List<ReceiptModelSoldItem4> rows, {
    required bool ofdOn,
    required bool cashsaleCheckOn,
  }) {
    if (!ofdOn) return false;
    if (!cashsaleCheckOn) return false;
    if (rows.isEmpty) return false;

    for (final item in rows) {
      if (item.isDeleted == true) continue;
      final product = ItemsSingleton.getProductById(item.productId);
      final int cashsale = product?.cashsale ?? 1;
      if (cashsale == 0) return true;
    }
    return false;
  }

  /// `cashsale == 1` mahsulotning QATOR jami 25 mln dan oshdimi.
  /// QAYD: chegara qator bo'yicha — 2 × 20 mln savat jami 40 mln bo'lsa ham
  /// bu qoida ishlamaydi (hozirgi xatti-harakat).
  static bool bigTotalHidden(
    List<ReceiptModelSoldItem4> rows, {
    required bool ofdOn,
    required bool cashsaleCheckOn,
  }) {
    if (!ofdOn) return false;
    if (!cashsaleCheckOn) return false;
    if (rows.isEmpty) return false;

    for (final item in rows) {
      if (item.isDeleted == true) continue;
      final product = ItemsSingleton.getProductById(item.productId);
      if (product == null) continue;
      if ((product.cashsale ?? -1) != 1) continue;
      if (item.price * item.value > bigTotalLimit) return true;
    }
    return false;
  }
}
