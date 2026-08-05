// Markirovka (KM / GS1 DataMatrix) kodini tozalash.
//
// Sof funksiyalar: holatga, Hive'ga, tarmoqqa yoki Flutter'ga bog'liq emas.
// OrderingProvider4 dan ajratildi (2026-08-05) — tanalar o'zgartirilmadi.
//
// IKKI FUNKSIYA BIR XIL EMAS — ataylab birlashtirilmagan:
//   * [scanTime]   — skan vaqtida ishlaydi, marker (93) hali joyida.
//                    Unicode tozalash va markersiz fallback bor.
//   * [forFiscal]  — to'lov vaqtida ishlaydi, kod allaqachon bir marta
//                    tozalangan. Fallback YO'Q (u serialni buzardi).
//
// Testlar: test/marking_paren_strip_test.dart, test/mark_cleaner_test.dart

class MarkCleaner {
  const MarkCleaner._();

  /// Skan vaqtidagi tozalash.
  ///
  /// Kripto qism ((93) va keyingisi) kesiladi, AI qavslari olib tashlanadi
  /// (ichidagi 01/21 raqami SAQLANADI), boshqaruv belgilari o'chiriladi.
  static String scanTime(String rawMark) {
    if (rawMark.trim().isEmpty) return rawMark;

    // Kripto marker bormi? — (93) qavsli yoki <GS>93 ajratuvchili.
    // Bu qaror faqat SHU YERDA (skan vaqti) to'g'ri: marker hali joyida.
    final hasMarker = RegExp(r'\(93\)').hasMatch(rawMark) ||
        RegExp(r'[\x1D\x1C\x1E\x1F]93').hasMatch(rawMark);

    String clean = rawMark
        // 1) Kripto qism — (93) va undan keyingi hamma narsa (yoki <GS>93...).
        //    Bu qism sotuvga, soliqqa, OFD ga HECH QAYERGA yuborilmaydi.
        //    Marker BORda: aniq marker bo'yicha kesamiz — serial ichidagi
        //    tasodifiy "93" saqlanadi (u yalang'och, marker "kiyimi" yo'q).
        .replaceAll(RegExp(r'\(93\).*$'), '')
        .replaceAll(RegExp(r'[\x1D\x1C\x1E\x1F]93.*$'), '')
        // 2) AI qavslarini olib tashlaymiz, LEKIN ichidagi raqamni SAQLAYMIZ:
        //    (01)->01, (21)->21. Aks holda 01 GTIN bilan qo'shilib ketib, kod
        //    04... (GTIN) dan boshlanib qolardi — buzuq KM. (Eski `\(\d{2}\)`
        //    regexi qavs bilan birga 01/21 raqamini ham o'chirib yuborardi.)
        .replaceAllMapped(RegExp(r'\((\d{2,3})\)'), (m) => m.group(1)!)
        // 3) Qolgan barcha ASCII boshqaruv belgilari: GS(0x1D), FS, RS, US,
        //    NUL...DEL va C1 (0x80-0x9F). Aks holda chekda "▯" chiqadi.
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '')
        // Unicode replacement / object-replacement belgilari
        .replaceAll('￼', '')
        .replaceAll('�', '');

    // Marker YO'Q (yalang'och kod) bo'lsa — ESKI logika: 01+GTIN(14)+21 dan
    // keyin birinchi "93" gacha olamiz. Markersiz kodda chegarani boshqacha
    // aniqlashning iloji yo'q, shuning uchun serialda 93 kelib qolsa ham kesiladi.
    if (!hasMarker) {
      final match = RegExp(r'(01\d{14}21.*?)(?=93)').firstMatch(clean);
      if (match != null) return match.group(1)!;
    }

    return clean;
  }

  /// Fiskal chekka (OFD) yuborishdan oldingi tozalash.
  static String forFiscal(String rawMark) {
    if (rawMark.trim().isEmpty) return rawMark;

    // Kripto qism ((93) va keyin, yoki <GS>93...) — hech qayerga yuborilmaydi.
    // Faqat ANIQ marker (qavs yoki boshqaruv-ajratuvchi) bo'yicha kesamiz.
    // MUHIM: eski bare `(?=93)` fallback ishlatilmaydi — u serial ICHIDAGI
    // tasodifiy "93" substringda serialni kesib yuborardi (masalan serial
    // "93QWERTYuiop1" bo'lsa butunlay yo'qolardi). scanTime allaqachon
    // kriptoni marker bilan kesib bo'lgani uchun bu fallback keraksiz.
    return rawMark
        .replaceAll(RegExp(r'\(93\).*$'), '')
        .replaceAll(RegExp(r'[\x1D\x1C\x1E\x1F]93.*$'), '')
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .replaceAllMapped(RegExp(r'\((\d{2,3})\)'), (m) => m.group(1)!);
  }
}
