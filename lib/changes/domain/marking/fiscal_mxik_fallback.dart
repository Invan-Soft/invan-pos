// Fiskal modulga ketadigan item uchun MXIK / shtrix-kod fallback qoidasi.
//
// MUAMMO (2026-09-11): adminkada mahsulot markirovkali deb belgilanMAGAN
// (`is_marking=false` — markirovkalilikni aniqlovchi BIRINCHI mezon), lekin
// unga markirovka talab qiladigan MXIK (02202..., 02203... va h.k. —
// `MxikRules.isMxikMarking` ro'yxati) XATO kiritilgan. Mahsulotning o'zida
// markirovka kodi (seriya raqami) yo'q. Bunday qator fiskal modulga
// `SPIC=02202..., Label=""` bo'lib ketsa, soliq uni rad etadi — kassir chekni
// umuman yopa olmaydi.
//
// QOIDA — uch shart BIRGA bajarilsa, FAQAT fiskal body'da:
//   1) `isMarkingProduct == false` — adminkada markirovkali emas
//   2) MXIK markirovka ro'yxatida
//   3) qatorda markirovka kodi (KM) yo'q
// natija:
//   - `classCode` (SPIC) → statik MXIK (`Pref mxikCode`, 01905012001000000)
//   - `barcode`          → bo'sh
// Boshqa hech narsa o'zgarmaydi: backend chek `order_pos` (`product_mxik`,
// `product_barcode`), savat qatori, `product_type`/`product_package` avvalgidek.
//
// Savat tomoni (2026-09-11): `is_marking=false` mahsulotga markirovka dialogi
// ham CHIQMAYDI — `MxikRules.isMxikAutoDetectCandidate`. Shuning uchun bunday
// qator savatga oddiy (KM siz) tushadi va shu qoida bilan fiskalga ketadi.
//
// Nega 3-shart ham kerak: qanday yo'l bilan bo'lmasin qatorda KM bor bo'lsa
// (masalan bayroq `null` mahsulotda avto-aniqlash ishlab KM skanerlangan)
// asl MXIK ketishi shart — aks holda KM statik SPIC bilan ketib, soliqda
// noto'g'ri ro'yxatga olinadi.
//
// Nega 1-shart kerak: `is_marking=true` bo'lsa mahsulot haqiqatan markirovkali;
// KM siz qolgan bo'lsa ham (masalan invoice qatori) uni statik MXIK bilan
// "oddiy tovar" qilib o'tkazib yubormaymiz.
//
// Qoida sotuv va vozvratga BIR XIL qo'llanadi (ikkalasi
// `ReceiptSingleton4.saleOnOFD` orqali o'tadi) — shunda vozvrat sotuv bilan
// mos keladi.
//
// Sof funksiya — Pref/Hive o'qimaydi: `isMarkingProduct` va statik MXIK
// parametr sifatida keladi. Testlar: test/fiscal_mxik_fallback_test.dart

import 'package:invan2/changes/domain/marking/mxik_rules.dart';

/// Fiskal item uchun yakuniy `classCode` (SPIC) va `barcode`.
class FiscalItemCodes {
  const FiscalItemCodes({
    required this.classCode,
    required this.barcode,
    required this.substituted,
  });

  final String classCode;
  final String barcode;

  /// Almashtirish qo'llandimi (log va test uchun).
  final bool substituted;
}

class FiscalMxikFallback {
  const FiscalMxikFallback._();

  /// Qatorda markirovka kodi bormi (bo'sh joy = yo'q).
  static bool hasMark(String? mark) => mark != null && mark.trim().isNotEmpty;

  /// Fallback UMUMAN mumkinmi — `is_marking` ga qaramasdan: MXIK markirovka
  /// ro'yxatida va KM yo'q. Chaqiruvchi katalog qidiruvini (qimmat) faqat shu
  /// `true` bo'lganda qiladi.
  static bool mayNeedFallback({required String mxik, required String? mark}) =>
      MxikRules.isMxikMarking(mxik.trim()) && !hasMark(mark);

  /// Qator fiskal fallback'ga muhtojmi.
  ///
  /// [isMarkingProduct] — katalogdagi mahsulotning `is_marking` bayrog'i
  /// (adminka). Mahsulot katalogda topilmasa chaqiruvchi `false` beradi.
  static bool needsFallback({
    required bool isMarkingProduct,
    required String mxik,
    required String? mark,
  }) =>
      !isMarkingProduct && mayNeedFallback(mxik: mxik, mark: mark);

  /// Fiskal body uchun `classCode`/`barcode` ni hisoblaydi.
  ///
  /// [staticMxik] bo'sh bo'lsa (Pref yozilmagan chetki holat) almashtirish
  /// QILINMAYDI — bo'sh SPIC yuborishdan ko'ra asl MXIK ketgani xavfsizroq
  /// (fiskal modul bo'sh SPIC ni har doim rad etadi).
  static FiscalItemCodes resolve({
    required bool isMarkingProduct,
    required String mxik,
    required String? mark,
    required String barcode,
    required String staticMxik,
  }) {
    final String fallback = staticMxik.trim();
    final bool needs = needsFallback(
      isMarkingProduct: isMarkingProduct,
      mxik: mxik,
      mark: mark,
    );
    if (fallback.isEmpty || !needs) {
      return FiscalItemCodes(
        classCode: mxik,
        barcode: barcode,
        substituted: false,
      );
    }
    return FiscalItemCodes(
      classCode: fallback,
      barcode: '',
      substituted: true,
    );
  }
}
