// GS1 formatidagi ma'lumotlarni tahlil qilish.
//
// Sof funksiya: holatga, Hive'ga, tarmoqqa yoki Flutter'ga bog'liq emas.
// OrderingProvider4 dan ajratildi (2026-08-05) — tana o'zgartirilmadi.
// `isSameGtin` — 2026-10-21 (KM to'g'ridan skanerlanganda GTIN nollari).
//
// Testlar: test/gs1_test.dart

class Gs1 {
  const Gs1._();

  /// GS1 sana formati: YYMMDD → DateTime.
  ///
  /// YY <= 49 bo'lsa 2000-yillar, aks holda 1900-yillar.
  /// DD == 00 bo'lsa oyning oxirgi kuni olinadi.
  /// Format buzuq bo'lsa `null` qaytaradi.
  static DateTime? parseDate(String yymmdd) {
    try {
      int yy = int.parse(yymmdd.substring(0, 2));
      int mm = int.parse(yymmdd.substring(2, 4));
      int dd = int.parse(yymmdd.substring(4, 6));
      int year = yy <= 49 ? 2000 + yy : 1900 + yy;
      if (dd == 0) dd = DateTime(year, mm + 1, 0).day;
      return DateTime(year, mm, dd);
    } catch (_) {
      return null;
    }
  }

  static final _digitsOnly = RegExp(r'^\d+$');
  static final _leadingZeros = RegExp(r'^0+');

  /// GS1 GTIN tengligi: katalogdagi [barcode] skanerlangan GTIN bilan BITTA
  /// tovarmi.
  ///
  /// GS1 qoidasi: GTIN-8/12/13/14 chapdan nol bilan 14 xonagacha
  /// to'ldirilganda teng bo'lsa — bu bitta tovar. Masalan `049000033939`
  /// (UPC-12) = `0049000033939` (EAN-13) = `00049000033939` (KM ichidagi
  /// GTIN-14) = `49000033939` (nollari tushib qolgan yozuv).
  ///
  /// [gtinKey] — skanerlangan GTIN ning boshidagi NOLLARSIZ raqamlari
  /// (chaqiruvchi bir marta hisoblaydi; bo'sh bo'lsa hech narsa mos emas).
  ///
  /// [barcode] faqat 8..14 xonali SOF RAQAM bo'lsa solishtiriladi:
  ///   * 8 — eng qisqa GTIN (GTIN-8). Qisqaroq raqam GTIN emas: <= 5 belgi
  ///     bu tizimda SKU (narx yorlig'i), 6-7 — ichki kodlar. Ularni nol bilan
  ///     to'ldirib moslash fragment moslik bo'lardi ("206" ≠ "0206" qoidasi).
  ///   * 14 — eng uzun GTIN; uzunroq raqam GTIN emas.
  ///   * harf/belgi aralash kod hech qachon normalizatsiya qilinmaydi.
  ///
  /// `MarkValidator.matchesProduct` bundan kengroq (uzunlik cheklovisiz
  /// nollarsiz tenglik) — shuning uchun shu qoida bilan topilgan mahsulot
  /// KM tekshiruvidan doim o'tadi.
  static bool isSameGtin(String barcode, String gtinKey) =>
      gtinKey.isNotEmpty &&
      barcode.length >= 8 &&
      barcode.length <= 14 &&
      // Arzon filtr birinchi: katalog bo'ylab o'tishda regex faqat
      // shu oxiri mos kelgan nomzodlarda ishlaydi.
      barcode.endsWith(gtinKey) &&
      _digitsOnly.hasMatch(barcode) &&
      barcode.replaceFirst(_leadingZeros, '') == gtinKey;
}
