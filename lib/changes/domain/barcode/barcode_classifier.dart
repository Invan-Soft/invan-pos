// Skanerdan kelgan kodni tasniflash: bu nima — mahsulot shtrix-kodimi,
// tarozi yorlig'imi, utsenka QR mi, yoki umuman kod emasmi?
//
// OrderingProvider4.onBarcodeScanned dan ajratildi (2026-08-06) —
// shartlar va ularning TARTIBI o'zgartirilmadi (tartib muhim: masalan
// bo'sh joy tekshiruvi raqam tekshiruvidan oldin keladi).
//
// BU YERDA YO'Q (ataylab): dialog, BuildContext, savat, Pref o'qish.
// Sozlamalar (tarozi prefikslari) parametr sifatida keladi — provider
// ularni Pref dan o'qib uzatadi.
//
// Testlar: test/barcode_classifier_test.dart

import 'package:invan2/changes/domain/marking/gs1.dart';

/// Skanerdan kelgan kod turi.
enum ScannedCodeKind {
  /// Tozalangandan keyin bo'sh qoldi — e'tiborsiz qoldiriladi.
  empty,

  /// URL (http/ftp/www/tel/mailto yoki `://`) — mahsulot emas.
  url,

  /// UUID formatdagi QR (masalan PayNet OTP) — mahsulot emas, jim o'tkaziladi.
  uuid,

  /// `{` bilan boshlanadi — utsenka QR (JSON).
  utsenkaQr,

  /// Ichida bo'sh joy bor — erkin matn (manzil, izoh), mahsulot emas.
  freeText,

  /// Birorta raqam yo'q — matn yoki noto'g'ri input.
  noDigits,

  /// Tarozi yorlig'i (kilo hisobida).
  weightItem,

  /// Tarozi yorlig'i (dona hisobida).
  pieceItem,

  /// Oddiy mahsulot shtrix-kodi / SKU / markirovka.
  product,
}

class BarcodeClassifier {
  const BarcodeClassifier._();

  /// Skaner qo'shib yuborgan ko'rinmas belgilarni olib tashlaydi.
  ///
  /// Skaner (ayniqsa macOS klaviatura-emulyatsiyasida) barcode oxiriga
  /// ko'rinmas maxsus belgi qo'shib yuborishi mumkin (masalan codeUnit
  /// 63233 = U+F701). Private-use (0xE000-0xF8FF) belgilarni olib
  /// tashlaymiz — ular hech qachon haqiqiy barcode qismi emas. Aks holda
  /// aniq/nol-farqli qidiruv mos kelmay mahsulot "topilmadi" bo'lardi.
  static String sanitize(String raw) => String.fromCharCodes(
        raw.codeUnits.where((c) => c < 0xE000 || c > 0xF8FF),
      ).trim();

  /// Kod turini aniqlaydi. Kirish [barcode] avval [sanitize] dan o'tgan
  /// bo'lishi kutiladi.
  ///
  /// Tekshiruvlar TARTIBI asl koddagidek saqlangan.
  static ScannedCodeKind classify(
    String barcode, {
    required int taroziPrefix,
    required int taroziPiecePrefix,
  }) {
    if (barcode.isEmpty) return ScannedCodeKind.empty;

    // URL'larni qat'iy rad qilish
    final lowerTrim = barcode.trim().toLowerCase();
    if (lowerTrim.startsWith('http') ||
        lowerTrim.startsWith('ftp') ||
        lowerTrim.startsWith('www.') ||
        lowerTrim.startsWith('tel:') ||
        lowerTrim.startsWith('mailto:') ||
        lowerTrim.contains('://')) {
      return ScannedCodeKind.url;
    }

    // UUID formatdagi QR kodlar (masalan, PayNet OTP) product emas
    if (RegExp(
            r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
        .hasMatch(barcode)) {
      return ScannedCodeKind.uuid;
    }

    if (barcode.trimLeft().startsWith('{')) return ScannedCodeKind.utsenkaQr;

    // Erkin matn (kompaniya manzili, telefon, izoh va h.k.) — bo'sh joy yoki
    // yangi qator bo'lsa, bu product barcode emas. Aks holda matndan tasodifan
    // raqam ajratib olib, SKU bo'yicha noto'g'ri mahsulot topib qo'shilib qoladi.
    if (RegExp(r'\s').hasMatch(barcode.trim())) return ScannedCodeKind.freeText;

    // Haqiqiy product barcode/SKU har doim kamida bitta raqam tutadi.
    // Faqat harflar bo'lsa — bu matn yoki noto'g'ri input.
    if (!RegExp(r'\d').hasMatch(barcode)) return ScannedCodeKind.noDigits;

    if (barcode.startsWith('$taroziPrefix') && barcode.length == 13) {
      return ScannedCodeKind.weightItem;
    }

    if (barcode.startsWith('$taroziPiecePrefix') && barcode.length == 13) {
      return ScannedCodeKind.pieceItem;
    }

    return ScannedCodeKind.product;
  }

  /// GS1 yaroqlilik muddatini ajratib oladi (AI 17, bo'lmasa AI 15).
  ///
  /// Uch xil format qo'llab-quvvatlanadi:
  ///   1. Qavsli: `(17)YYMMDD`
  ///   2. Qavsiz, `01`+GTIN(14) dan keyin: `17YYMMDD` yoki `15YYMMDD`
  ///   3. Qavsli: `(15)YYMMDD`
  static DateTime? parseExpiry(String barcode) {
    DateTime? expiryDate;

    final ai17Match = RegExp(r'\(17\)(\d{6})').firstMatch(barcode);
    if (ai17Match != null) expiryDate = Gs1.parseDate(ai17Match.group(1)!);

    // Qavsiz: 01(14 raqam) dan keyin kelgan AI larni parse qilish
    if (expiryDate == null && barcode.startsWith('01') && barcode.length > 16) {
      final rest = barcode.substring(16); // "1726032510BATCH123..."
      final ai17 = RegExp(r'^17(\d{6})').firstMatch(rest);
      if (ai17 != null) expiryDate = Gs1.parseDate(ai17.group(1)!);

      if (expiryDate == null) {
        final ai15 = RegExp(r'^15(\d{6})').firstMatch(rest);
        if (ai15 != null) expiryDate = Gs1.parseDate(ai15.group(1)!);
      }
    }

    // Qavsli AI 15
    if (expiryDate == null) {
      final ai15Match = RegExp(r'\(15\)(\d{6})').firstMatch(barcode);
      if (ai15Match != null) expiryDate = Gs1.parseDate(ai15Match.group(1)!);
    }

    return expiryDate;
  }

  /// Muddat o'tganmi (bugungi kun bilan solishtiriladi).
  static bool isExpired(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return expiryDate.isBefore(today);
  }
}
