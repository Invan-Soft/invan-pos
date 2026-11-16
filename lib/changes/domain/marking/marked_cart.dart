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

import 'package:invan2/changes/domain/barcode/keyboard_layout.dart';
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

  /// Skaner GS (0x1D) ajratuvchisini Alt-kod bilan yuborsa asosiy ekran
  /// tinglovchisiga u `029` raqamlari bo'lib keladi (do'kondagi haqiqiy KM:
  /// `...DLsWfiV02993SgJ5`), matn maydoniga esa kelmasligi mumkin.
  static const String _gsAsDigits = '029';

  /// Ikki KM satri BITTA markirovka kodimi.
  ///
  /// Aynan teng bo'lmasa ham bitta kod deb hisoblanadi, agar farq faqat
  /// skaner/klaviatura izidan bo'lsa:
  ///   * rus tartibi — biri kirill, biri lotin harflarda (eski savat qatori
  ///     yoki boshqa yo'ldan kirgan KM);
  ///   * GS ajratuvchisi — birida `029` bo'lib yozilgan, ikkinchisida yo'q.
  ///
  /// Soxta moslik xavfi yo'q: bitta GTIN ichida seriya uzunligi bir xil,
  /// `029` qo'shilgan satr esa har doim 3 belgi uzun — ikki HAQIQIY dona
  /// bir-biridan faqat shu bilan farq qila olmaydi.
  ///
  /// Bu faqat SOLISHTIRISH: savatga/soliqqa ketadigan satr o'zgarmaydi.
  static bool sameMark(String? a, String? b) {
    if (a == null || b == null || a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final x = KeyboardLayout.fixScan(a.trim());
    final y = KeyboardLayout.fixScan(b.trim());
    if (x == y) return true;
    if (x.length == y.length) return false;
    final longer = x.length > y.length ? x : y;
    final shorter = x.length > y.length ? y : x;
    if ((longer.length - shorter.length) % _gsAsDigits.length != 0) {
      return false;
    }
    return _equalIgnoringGsDigits(longer, shorter, 0, 0, <int>{});
  }

  /// [longer] dan bir nechta `029` olib tashlansa [shorter] chiqadimi.
  /// [dead] — natija bermagan (i, j) holatlar (qayta hisoblanmasin).
  static bool _equalIgnoringGsDigits(
      String longer, String shorter, int i, int j, Set<int> dead) {
    while (true) {
      if (j == shorter.length && i == longer.length) return true;
      final key = i * (shorter.length + 1) + j;
      if (dead.contains(key)) return false;
      if (longer.startsWith(_gsAsDigits, i) &&
          _equalIgnoringGsDigits(
              longer, shorter, i + _gsAsDigits.length, j, dead)) {
        return true;
      }
      if (i < longer.length &&
          j < shorter.length &&
          longer.codeUnitAt(i) == shorter.codeUnitAt(j)) {
        i++;
        j++;
        continue;
      }
      dead.add(key);
      return false;
    }
  }

  /// Savatdagi shu KM li aktiv qator indeksi (`-1` — yo'q).
  /// Mahsulotdan qat'i nazar qidiriladi: bitta KM butun chekda bir marta.
  /// Tenglik — [sameMark].
  static int indexOfMark(List<ReceiptModelSoldItem4> rows, String mark) =>
      rows.indexWhere(
          (e) => !(e.isDeleted ?? false) && sameMark(e.mark, mark));

  /// Shu mahsulotning KM si BO'SH qatori indeksi (`-1` — yo'q).
  static int indexOfWithoutMark(
          List<ReceiptModelSoldItem4> rows, String? productId) =>
      rows.indexWhere(
          (e) => e.productId == productId && (e.mark == null || e.mark!.isEmpty));

  /// Shu mahsulotda shu KM bormi. Tenglik — [sameMark].
  static bool hasMark(
          List<ReceiptModelSoldItem4> rows, String? productId, String mark) =>
      rows.any((e) => e.productId == productId && sameMark(e.mark, mark));

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
