// Tarozi yorlig'i (shtrix-kod) formati.
//
// Do'kon tarozisi yorliqni shu ko'rinishda chop etadi:
//   prefiks(2) + PLU/SKU(5) + gramm(...) + nazorat raqami
// Masalan `2800206012340` → PLU "00206", 1.234 kg.
//
// PLU 5 xonaga nol bilan to'ldiriladi, katalogda esa SKU nolsiz saqlanishi
// mumkin — shuning uchun avval aynan, keyin nolsiz ko'rinishda qidiriladi.
// Bu tarozi FORMATINING qoidasi: ixtiyoriy kiritishdan raqam ajratib olish
// EMAS, shuning uchun boshqa mahsulot xato urilmaydi.
//
// `OrderingProvider4.scanWeightItem` / `scanPieceItem` dan ajratildi.

import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

class TaroziLabel {
  const TaroziLabel._();

  /// Yorliqdagi PLU (SKU) qismi — 3-7 belgilar.
  static String plu(String barcode) => barcode.substring(2, 7);

  /// Yorliqdagi og'irlik, kilogrammda (grammning 3 xonasigacha).
  static double weightKg(String barcode) {
    final gram = double.tryParse(barcode.substring(7, barcode.length)) ?? 0;
    final value = gram / 10000;
    return (value * 1000).floorToDouble() / 1000;
  }

  /// PLU bo'yicha mahsulot: avval aynan, topilmasa boshidagi nollar
  /// olib tashlangan ko'rinishda.
  static ItemModel? findProduct(String plu) {
    final exact = ItemsSingleton.getProductByBarcode(plu);
    if (exact != null) return exact;

    final noZeros = plu.replaceFirst(RegExp(r'^0+'), '');
    if (noZeros.isEmpty || noZeros == plu) return null;
    return ItemsSingleton.getProductByBarcode(noZeros);
  }
}
