// GS1 formatidagi ma'lumotlarni tahlil qilish.
//
// Sof funksiya: holatga, Hive'ga, tarmoqqa yoki Flutter'ga bog'liq emas.
// OrderingProvider4 dan ajratildi (2026-08-05) — tana o'zgartirilmadi.
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
}
