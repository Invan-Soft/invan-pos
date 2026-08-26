// Markirovkali qatorlarni savatdan qidirish.
//
// KM tekshiruvidan o'tgach uchta savol tug'iladi:
//   1. Bu KM savatda ALLAQACHON bormi? (bo'lsa — ogohlantirish, ikkinchi
//      marta sotilmasin)
//   2. Shu mahsulotning KM siz qatori bormi? (bo'lsa — KM ni o'shanga
//      biriktiramiz, yangi qator ochmaymiz)
//   3. Aks holda — yangi qator.
//
// `OrderingProvider4._markingCheck` da bu qidiruvlar olti joyda takrorlangan
// edi. Qoidalar o'zgarmagan.

import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

/// KM skanerlangach savatga nima qilish kerakligi.
enum MarkAction {
  /// Yangi qator qo'shiladi.
  addNew,

  /// Shu mahsulotning KM siz qatoriga KM biriktiriladi.
  attachToExistingRow,

  /// Bu KM allaqachon savatda — ogohlantirish ko'rsatiladi.
  warnDuplicate,
}

class MarkedCart {
  const MarkedCart._();

  /// Savatdagi AYNAN shu KM li aktiv qator indeksi (`-1` — yo'q).
  /// Mahsulotdan qat'i nazar qidiriladi: bitta KM butun chekda bir marta.
  static int indexOfMark(List<ReceiptModelSoldItem4> rows, String mark) =>
      rows.indexWhere((e) =>
          !(e.isDeleted ?? false) &&
          e.mark != null &&
          e.mark!.isNotEmpty &&
          e.mark == mark);

  /// Shu mahsulotning KM si BO'SH qatori indeksi (`-1` — yo'q).
  static int indexOfWithoutMark(
          List<ReceiptModelSoldItem4> rows, String? productId) =>
      rows.indexWhere(
          (e) => e.productId == productId && (e.mark == null || e.mark!.isEmpty));

  /// Shu mahsulotda aynan shu KM bormi.
  static bool hasMark(
          List<ReceiptModelSoldItem4> rows, String? productId, String mark) =>
      rows.any((e) =>
          e.productId == productId && e.mark != null && e.mark == mark);

  /// ONKM tekshiruvi O'CHIQ bo'lgandagi qaror.
  static MarkAction decideWithoutOnkm(
      List<ReceiptModelSoldItem4> rows, String? productId, String mark) {
    if (indexOfMark(rows, mark) != -1) return MarkAction.warnDuplicate;
    if (indexOfWithoutMark(rows, productId) != -1) {
      return MarkAction.attachToExistingRow;
    }
    return MarkAction.addNew;
  }

  /// ONKM javobidan keyingi (yoki oflayn) qaror: faqat takror tekshiriladi.
  static MarkAction decideAfterCheck(
          List<ReceiptModelSoldItem4> rows, String? productId, String mark) =>
      hasMark(rows, productId, mark)
          ? MarkAction.warnDuplicate
          : MarkAction.addNew;
}
