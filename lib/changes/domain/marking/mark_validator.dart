// Skanerlangan markirovka kodini (KM) tekshirish.
//
// Tarmoq (ONKM) so'roviga BORISHDAN OLDIN bajariladigan mahalliy
// tekshiruvlar. Uchtasi ham sotuvni to'xtatadi:
//   1. FORMAT — KM GS1 DataMatrix bo'lishi kerak (URL yoki GTIN'siz matn emas)
//   2. MAHSULOT — KM ichidagi GTIN skanerlangan mahsulot shtrix-kodiga
//      mos kelishi kerak (aks holda boshqa tovarning KM i urilgan bo'ladi)
//   3. MUDDAT — (17) yoki (15) sanasi o'tgan bo'lmasligi kerak
//
// `OrderingProvider4._markingCheck` dan ajratildi — qoidalar o'zgarmagan.

import 'package:invan2/changes/domain/marking/gs1.dart';
import 'package:invan2/changes/models/product/item_model.dart';

/// Tekshiruv natijasi.
enum MarkIssue {
  /// Muammo yo'q — KM qabul qilinadi.
  none,

  /// GS1 DataMatrix emas: URL yoki ichida GTIN topilmadi.
  invalidFormat,

  /// KM boshqa mahsulotga tegishli (GTIN mos kelmadi).
  wrongProduct,

  /// Muddati o'tgan.
  expired,
}

class MarkValidation {
  const MarkValidation(this.issue, this.mark, {this.gtin, this.expiry});

  final MarkIssue issue;

  /// Tozalangan KM (boshqaruv belgilarisiz) — savatga shu yoziladi.
  final String mark;

  /// KM ichidan ajratilgan GTIN (boshidagi nollarsiz).
  final String? gtin;

  /// KM ichidagi muddat sanasi (bo'lsa).
  final DateTime? expiry;

  bool get isOk => issue == MarkIssue.none;
}

class MarkValidator {
  const MarkValidator._();

  /// KM dan boshqaruv belgilarini (GS1 `<GS>`=0x1D, FS, RS, US va boshqa
  /// ko'rinmas kodlar) olib tashlaydi. Aks holda chekda/JSON da "▯" kabi
  /// belgilar chiqib qoladi. (17)/(15) AI qavslari saqlanadi.
  static String sanitize(String raw) => raw
      .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '')
      .replaceAll('￼', '')
      .replaceAll('�', '');

  /// KM ichidan GTIN ni ajratadi (boshidagi nollar olib tashlanadi).
  /// Avval GS1 AI (01/02) bo'yicha, topilmasa har qanday 12-14 xonali raqam.
  static String? extractGtin(String mark) {
    final gtinMatch = RegExp(r'(?:01|02)(\d{12,14})').firstMatch(mark);
    if (gtinMatch != null) {
      return gtinMatch.group(1)!.replaceFirst(RegExp(r'^0+'), '');
    }
    final numbers = RegExp(r'\d{12,14}').firstMatch(mark);
    if (numbers != null) {
      return numbers.group(0)!.replaceFirst(RegExp(r'^0+'), '');
    }
    return null;
  }

  /// KM ichidagi muddat sanasi: (17) ustun, keyin qavssiz "01"+GTIN14 dan
  /// keyingi 17/15, oxirida (15).
  static DateTime? extractExpiry(String mark) {
    final ai17 = RegExp(r'\(17\)(\d{6})').firstMatch(mark);
    if (ai17 != null) {
      final d = Gs1.parseDate(ai17.group(1)!);
      if (d != null) return d;
    }

    if (mark.startsWith('01') && mark.length > 16) {
      final clean = mark.replaceAll(RegExp(r'[\x1D\x1C\x1E]'), '');
      final rest = clean.substring(16);

      final ai17rest = RegExp(r'^17(\d{6})').firstMatch(rest);
      if (ai17rest != null) {
        final d = Gs1.parseDate(ai17rest.group(1)!);
        if (d != null) return d;
      }

      final ai15rest = RegExp(r'^15(\d{6})').firstMatch(rest);
      if (ai15rest != null) {
        final d = Gs1.parseDate(ai15rest.group(1)!);
        if (d != null) return d;
      }
    }

    final ai15 = RegExp(r'\(15\)(\d{6})').firstMatch(mark);
    if (ai15 != null) return Gs1.parseDate(ai15.group(1)!);

    return null;
  }

  /// Mahsulotning biror shtrix-kodi [gtin] ga mos keladimi (nollarsiz).
  static bool matchesProduct(ItemModel product, String gtin) =>
      (product.barcode ?? [])
          .any((b) => b.replaceFirst(RegExp(r'^0+'), '') == gtin);

  /// To'liq tekshiruv. [now] berilmasa bugungi sana ishlatiladi.
  static MarkValidation validate(String rawMark, ItemModel product,
      {DateTime? now}) {
    final mark = sanitize(rawMark);

    if (mark.startsWith('http://') || mark.startsWith('https://')) {
      return MarkValidation(MarkIssue.invalidFormat, mark);
    }

    final gtin = extractGtin(mark);
    if (gtin == null) {
      return MarkValidation(MarkIssue.invalidFormat, mark);
    }

    if (!matchesProduct(product, gtin)) {
      return MarkValidation(MarkIssue.wrongProduct, mark, gtin: gtin);
    }

    final expiry = extractExpiry(mark);
    if (expiry != null) {
      final n = now ?? DateTime.now();
      final today = DateTime(n.year, n.month, n.day);
      if (expiry.isBefore(today)) {
        return MarkValidation(MarkIssue.expired, mark,
            gtin: gtin, expiry: expiry);
      }
    }

    return MarkValidation(MarkIssue.none, mark, gtin: gtin, expiry: expiry);
  }
}
