// GS1 formatidagi ma'lumotlarni tahlil qilish.
//
// Sof funksiya: holatga, Hive'ga, tarmoqqa yoki Flutter'ga bog'liq emas.
// OrderingProvider4 dan ajratildi (2026-08-05) — tana o'zgartirilmadi.
// `isSameGtin` — 2026-10-21 (KM to'g'ridan skanerlanganda GTIN nollari).
// `stripScannerPrefix` — 2026-10-21 (skaner KM boshiga `-` qo'yadi).
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

  static const _gs1Start = r'(?=01\d{14}|\(01\)\d{14})';
  static final _dashPrefix = RegExp(r'^-+' + _gs1Start);
  static final _aimPrefix = RegExp(r'^\][dCQ]\d' + _gs1Start);
  static final _realSeparator = RegExp(r'[\x1D\x1C\x1E\x1F]');
  static final _dashSeparator = RegExp(r'-(?=93|8005)');

  /// Skaner GS1 kodi (KM) boshiga qo'shib yuboradigan ortiqcha belgilarni
  /// olib tashlaydi. Aks holda kod `01` bilan boshlanmaydi va mahsulot
  /// "topilmadi" bo'ladi.
  ///
  ///   * `-` — ba'zi skanerlar DataMatrix boshidagi FNC1 belgisini `-` qilib
  ///     uzatadi: `-0100049000033939217MG7...` (2026-10-21, do'kondan). Bunday
  ///     skaner kod ichidagi FNC1 ajratuvchisini (odatda GS, 0x1D) ham `-`
  ///     qilib yuboradi — shuning uchun shu holatda, kodda haqiqiy ajratuvchi
  ///     bo'lmasa, kripto (`93`) va narx (`8005`) AI oldidagi `-` GS ga
  ///     qaytariladi: aks holda KM `...Y?-` bilan tugab, soliqqa buzuq ketardi.
  ///   * `]d2` / `]C1` / `]Q3` — AIM simvologiya identifikatori (skaner
  ///     sozlamasida yoqilgan bo'lsa).
  ///
  /// Faqat orqasidan GS1 `01`+GTIN14 (yoki `(01)`+GTIN14) kelsa ishlaydi —
  /// oddiy shtrix-kod hech qachon `-` yoki `]` bilan boshlanmaydi, shuning
  /// uchun boshqa kodlar o'zgarmaydi.
  static String stripScannerPrefix(String code) {
    final dash = _dashPrefix.firstMatch(code);
    if (dash == null) return code.replaceFirst(_aimPrefix, '');

    final body = code.substring(dash.end);
    // Qavsli `(01)` shaklida ajratuvchi qavslarning o'zi; haqiqiy GS bo'lsa
    // skaner uni to'g'ri uzatgan — ichki `-` lar seriyaning o'zi.
    if (!body.startsWith('01') || _realSeparator.hasMatch(body)) return body;
    // "01" + GTIN14 = 16 belgi; ajratuvchi faqat undan keyin bo'lishi mumkin.
    return body.substring(0, 16) +
        body.substring(16).replaceAll(_dashSeparator, '\x1D');
  }
}
