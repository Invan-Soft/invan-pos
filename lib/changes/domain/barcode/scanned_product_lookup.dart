// Skan qilingan koddan katalog mahsulotini topish.
//
// `BarcodeClassifier` kodning TURINI aniqlaydi; bu modul esa aniqlangan
// "mahsulot" kodidan MAHSULOTNI topadi. Uch xil qidiruv bor:
//   1. blok (yaqin qadoq) shtrix-kodi — GS1 "01" + GTIN14
//   2. odatiy qidiruv — GS1 dan GTIN ajratish, keyin AYNAN teng moslik
//   3. narxi 0 bo'lgan mahsulot — sinab ko'rilgan variantlar bo'yicha
//
// `OrderingProvider4.onBarcodeScanned` dan ko'chirildi (Faza 9.4) — tanalar
// o'zgarmagan. Ilgari bu kodni UMUMAN testlab bo'lmasdi: unga faqat
// `GlobalKey<ScaffoldState>` va dialoglar bilan borilardi.

import 'package:collection/collection.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';

/// Qidiruv natijasi. [triedPatterns] — narxi=0 tekshiruvi uchun sinab
/// ko'rilgan barcode variantlari (asl kod + ajratib olingan GTIN lar).
class ScannedProductMatch {
  const ScannedProductMatch(this.item, this.triedPatterns);

  final ItemModel? item;
  final List<String> triedPatterns;

  bool get found => item != null;
}

class ScannedProductLookup {
  const ScannedProductLookup._();

  /// Blok shtrix-kodi (GS1 "01" + GTIN14) bo'yicha mahsulot.
  /// Uch variant ketma-ket sinaladi: EAN13, boshidagi nolsiz GTIN14, GTIN14.
  static ItemModel? findBoxProduct(String barcode) {
    if (!(barcode.startsWith('01') && barcode.length > 16)) return null;
    final boxGtinMatch = RegExp(r'^01(\d{14})').firstMatch(barcode);
    if (boxGtinMatch == null) return null;

    final gtin14 = boxGtinMatch.group(1)!;
    final ean13 = gtin14.substring(1);
    final gtin14NoLeadZero = gtin14.replaceFirst(RegExp(r'^0+'), '');

    return ItemsSingleton.getProductByBoxBarcodeOnly(ean13) ??
        ItemsSingleton.getProductByBoxBarcodeOnly(gtin14NoLeadZero) ??
        ItemsSingleton.getProductByBoxBarcodeOnly(gtin14);
  }

  /// Odatiy mahsulot qidiruvi.
  ///
  /// [isMarkable] / [cleanMark] — topilgan mahsulotga markirovka kodini
  /// biriktirish uchun (markirovkali bo'lsa skan vaqtidagi KM, aks holda null).
  static ScannedProductMatch find(
    String barcode, {
    required bool Function(ItemModel product) isMarkable,
    required String Function(String rawMark) cleanMark,
  }) {
    final String pattern = barcode;
    ItemModel? item;

  // Narxi=0 tekshiruvi uchun sinab ko'rilgan barcode variantlarini yig'amiz
  final List<String> triedPatterns = [barcode];

  if (barcode.contains('(01)')) {
    final gtinMatch = RegExp(r'\(01\)(\d{13,14})').firstMatch(barcode);
    if (gtinMatch != null) {
      String gtin = gtinMatch.group(1)!;
      gtin = gtin.replaceFirst(RegExp(r'^0+'), '');
      triedPatterns.add(gtin);
      item = ItemsSingleton.getProductByBarcode(gtin);
      if (item != null) {
        item.mark = isMarkable(item) ? cleanMark(barcode) : null;
      }
    }
  }

  if (item == null && barcode.startsWith('01') && barcode.length > 16) {
    final gtinMatch = RegExp(r'^01(\d{14})').firstMatch(barcode);
    if (gtinMatch != null) {
      String gtin = gtinMatch.group(1)!;
      gtin = gtin.replaceFirst(RegExp(r'^0+'), '');
      triedPatterns.add(gtin);
      item = ItemsSingleton.getProductByBarcode(gtin);
      if (item != null) {
        item.mark = isMarkable(item) ? cleanMark(barcode) : null;
      }
    }
  }

  if (item == null) {
    // Hech qanday "ichidan raqam ajratib olish" YO'Q: satr qanday o'qitilgan
    // bo'lsa shundayligicha 100% teng barcode sifatida solishtiriladi.
    // Ma'lum formatlar (GS1 "01"+GTIN14, tarozi prefiksi, utsenka QR)
    // yuqorida strukturaviy tarzda ochilgan; ularga tushmagan noto'g'ri
    // format hech narsa topmaydi — "topilmadi" dialogi chiqadi.
    //
    // SKU fallback skaner uchun ham OCHIQ: do'konlar narx yorlig'iga SKU'ni
    // barcode qilib chiqaradi, kassir uni skan qiladi. Fragment-himoya SKU
    // qidiruvining o'zida: faqat sof raqam va normalizatsiyasiz AYNAN teng
    // moslik ("0206" hech qachon "206" deb topilmaydi).
    item = ItemsSingleton.getProductByBarcode(pattern);
    if (item != null) {
      item.mark = null;
    }
  }

    return ScannedProductMatch(item, triedPatterns);
  }

  /// Narxi 0 bo'lgani uchun odatiy qidiruvga tushmagan mahsulot.
  static ItemModel? findZeroPriceProduct(List<String> triedPatterns) {
  ItemModel? zeroPriceItem;
  for (final tried in triedPatterns) {
    zeroPriceItem = ItemsSingleton.products.firstWhereOrNull(
      (p) => p.barcode?.any((b) => b.trim() == tried.trim()) ?? false,
    );
    if (zeroPriceItem != null) break;
  }
    return zeroPriceItem;
  }
}
