// Savat qatorlarini qayta narxlash qoidalari.
//
// Uch xil narx manbai bor va ular bir-birini bosib ketmasligi kerak:
//   1. TIER — savatdagi umumiy dona soniga qarab avtomatik tanlanadi
//   2. QO'LDA (manual) — kassir OPD dialogida kiritgan narx, tier undan
//      ustun kelmasligi kerak (`isPriceOnlyChanged` himoyasi)
//   3. DISKONT — tier ustiga qo'llanadi, manual narxga qo'llanmaydi
//
// Bir mahsulotning savatdagi barcha qatorlari (dona / marka / blok) bitta
// DONA narx bazasida bo'lishi shart: blok qatori = dona narx x boxValue.
//
// `OrderingProvider4` dan ko'chirildi (Faza 9.1) — tanalar o'zgarmagan.
// Savat ro'yxati va diskont qo'llovchi parametr sifatida keladi, shuning
// uchun sinf provider holatiga bog'liq emas va to'g'ridan-to'g'ri testlanadi.

import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class RowRepricer {
  const RowRepricer._();

  /// Mahsulot kiloli (og'irlik bilan) sotiladimi.
  static bool isKg(ItemModel product) {
    final unit = product.measurementUnit?.shortName;
    return unit == 'кг' || unit == 'kg';
  }

  /// Mahsulot qatorlarini savatdagi UMUMIY dona soni bo'yicha qayta narxlaydi.
  /// Umumiy son = dona qatorlari value + blok qatorlari (value × boxValue).
  /// Biznes qoida: tier shu umumiy songa qarab tanlanadi (masalan 3 blok(12) +
  /// 1 dona = 37 dona → hammasi 3-tier narxida). Dona qatoriga tierUnit,
  /// blok qatoriga tierUnit × boxValue qo'yiladi. Qo'lda narxi o'zgartirilgan
  /// (isPriceOnlyChanged) qatorlarga tegilmaydi. Dona qatorlariga
  /// product/category chegirmalari qayta qo'llanadi (blokka qo'llanmaydi —
  /// _addBoxProduct bilan izchil).
  static void byTotalUnits(
    List<ReceiptModelSoldItem4> rows,
    String? productId, {
    required void Function(ItemModel product, ReceiptModelSoldItem4 row)
        applyDiscounts,
  }) {
    if (productId == null || productId.isEmpty) return;
    final product = ItemsSingleton.getProductById(productId);
    if (product == null) return;

    final kg = isKg(product);
    num totalUnits = 0;
    for (final e in rows) {
      if (e.productId == productId && !(e.isDeleted ?? false)) {
        totalUnits += (e.saleType == 2 && e.boxValue > 0)
            ? e.value * e.boxValue
            : e.value;
      }
    }
    if (totalUnits <= 0) return;

    final unitPrice =
        ItemsSingleton.finalPrice(product, totalUnits.toInt(), kg).toDouble();
    if (unitPrice <= 0) return;

    final vatPct = (product.vat?.percentage ?? 12);
    for (final e in rows) {
      if (e.productId != productId || (e.isDeleted ?? false)) continue;
      if (e.isPriceOnlyChanged) continue;

      final newPrice = (e.saleType == 2 && e.boxValue > 0)
          ? unitPrice * e.boxValue
          : unitPrice;
      e.price = newPrice;
      e.realPrice = newPrice;
      e.onlyPrice = newPrice;
      e.vat = newPrice == 0 ? 0 : (newPrice * vatPct) / (100 + vatPct);

      if (e.saleType != 2) {
        e.singleDiscount = 0;
        applyDiscounts(product, e);
      }
    }
  }

  /// OPD'da narx qo'lda o'zgartirilganda shu mahsulotning BARCHA qatorlarini
  /// bitta dona narxiga sinxronlaydi: blok qatori tahrirlansa dona qatorlari
  /// (yangi blok narxi / boxValue) bo'ladi, dona tahrirlansa blok qatorlari
  /// (dona narxi × boxValue) — bitta mahsulot, narxi bir xil bo'lishi kerak.
  /// Sinxronlangan qatorlar isPriceOnlyChanged bo'lib qoladi (tier reprice
  /// keyin tegmasligi uchun) va auto-diskontlari tozalanadi — OPD'dagi manual
  /// narx semantikasi bilan izchil (qo'lda narx = diskontsiz sotuv).
  static void syncManualPrice(
    List<ReceiptModelSoldItem4> rows,
    ReceiptModelSoldItem4 edited,
  ) {
    if (edited.productId.isEmpty) return;
    final int editedFactor =
        (edited.saleType == 2 && edited.boxValue > 0) ? edited.boxValue : 1;
    final double unitPrice = edited.price / editedFactor;
    final double unitRealPrice = edited.realPrice / editedFactor;
    final double unitOnlyPrice = edited.onlyPrice / editedFactor;
    final double unitSingleDiscount = edited.singleDiscount / editedFactor;

    for (final e in rows) {
      if (e.productId != edited.productId) continue;
      if (identical(e, edited)) continue;
      if (e.isDeleted ?? false) continue;
      if (e.isFreeGift) continue;

      final int factor = (e.saleType == 2 && e.boxValue > 0) ? e.boxValue : 1;
      e.price = unitPrice * factor;
      e.realPrice = unitRealPrice * factor;
      e.onlyPrice = unitOnlyPrice * factor;
      e.singleDiscount = unitSingleDiscount * factor;
      e.discountPercent = edited.discountPercent;
      e.vat =
          e.price == 0 ? 0 : (e.price * e.vatPercent) / (100 + e.vatPercent);
      e.isPriceOnlyChanged = true;
      e.isPriceChanged = true;
      e.discount.clear();
      e.productDiscount.clear();
    }
  }

  /// Mahsulotning savatda qo'lda narxi o'zgartirilgan (isPriceOnlyChanged) aktiv
  /// qatori bo'lsa — o'sha manual DONA narxini shu mahsulotning BARCHA aktiv
  /// qatorlariga (yangi skan qilingan dona/marka/blok ham) tarqatadi va `true`
  /// qaytaradi. Shunda yangi skan tier narxda emas, manual narxda qo'shiladi.
  ///
  /// Markirovkali mahsulotda har skan alohida marka qatori bo'ladi (merge yo'q),
  /// shuning uchun manual narx yangi markaga "yuqmasdan" guruh o'rtacha (blend)
  /// narx ko'rsatib qolardi; blok qatori ham tier narxda qolib ketardi. Bu helper
  /// izchillikni ta'minlaydi (bir xil mahsulot = bir xil dona narx).
  /// Manual narx yo'q bo'lsa `false` qaytaradi (odatdagi tier reprice ishlaydi).
  static bool applyExistingManualPrice(
    List<ReceiptModelSoldItem4> rows,
    String? productId,
  ) {
    if (productId == null || productId.isEmpty) return false;
    ReceiptModelSoldItem4? manualRow;
    for (final e in rows) {
      if (e.productId == productId &&
          !(e.isDeleted ?? false) &&
          !e.isFreeGift &&
          e.isPriceOnlyChanged) {
        manualRow = e;
        break;
      }
    }
    if (manualRow == null) return false;
    syncManualPrice(rows, manualRow);
    return true;
  }
}
