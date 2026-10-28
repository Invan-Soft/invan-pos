// Vozvratda markirovka (KM): chap ro'yxat qatorlari va skanerlangan KM tekshiruvi.
//
// Nega kerak: sotuvda har KM fiskalga alohida pozitsiya bo'lib ketadi —
// dona: `Amount 1000`, `Label` = bitta KM; blok: `Amount 1000`, `Price` = blok
// narxi, `Label` = blok KM (docs/markirovka-box-sotish.md §9). Vozvrat ilgari
// bitta qator, `Label ""` bilan ketardi: server `marking_names` /
// `box_marking_names` ni qaytarsa ham ilova o'qimasdi (2026-10-27).
//
// Qoida: chap ro'yxatda mahsulot bitta qator ("x 10", blok "x N blok") —
// qatorda shu chekda sotilgan KM'lar havzasi (`mark`, '\n' bilan). Kassir
// qatorni bosib qaytayotgan shisha/blokni skanerlaydi; KM havzada bo'lsa
// aynan o'sha 1 dona / 1 blok o'ngga o'sha KM bilan o'tadi, bo'lmasa
// "bu mahsulot shu chekda sotilmagan".

import 'package:invan2/changes/domain/barcode/barcode_classifier.dart';
import 'package:invan2/changes/domain/barcode/keyboard_layout.dart';
import 'package:invan2/changes/domain/marking/mark_cleaner.dart';

class RefundRow {
  /// Dona hisobida (blok qatorida ham — refund API, fiskal Price va DB dona bilan ishlaydi).
  final double units;

  /// `> 0` — blok qatori (`saleType 2`), qatordagi blok soni.
  final int blocks;

  /// Shu qatorga skanerlab qaytarish mumkin bo'lgan KM'lar. Bo'sh — KM'siz
  /// qator (avvalgidek miqdor dialogi).
  final List<String> marks;

  const RefundRow({required this.units, this.blocks = 0, this.marks = const []});

  bool get isBlock => blocks > 0;

  @override
  String toString() => 'RefundRow(units: $units, blocks: $blocks, marks: $marks)';
}

class RefundMarkSplit {
  RefundMarkSplit._();

  /// [remainingUnits] — qaytarish mumkin bo'lgan qoldiq (dona), shundan
  /// [blocksAvailable] × [boxValue] dona blok qatoriga, qolgani donaga.
  /// [refundedMarks] — shu chek bo'yicha oldingi vozvratlarda ketgan KM'lar.
  ///
  /// KM bo'lmasa natija avvalgidek: bitta blok qatori + bitta dona qatori.
  /// KM'lar qoldiqdan ko'p bo'lsa (boshqa kassada qaytarilgan — qaysi biri
  /// noma'lum) hammasi havzada qoladi, miqdor esa qoldiqdan oshmaydi. KM'lar
  /// kam bo'lsa (bir qismi KM'siz sotilgan) — qolgan qism alohida KM'siz qator.
  static List<RefundRow> plan({
    required double remainingUnits,
    int boxValue = 0,
    int blocksAvailable = 0,
    List<String> unitMarks = const [],
    List<String> boxMarks = const [],
    Set<String> refundedMarks = const {},
  }) {
    final rows = <RefundRow>[];

    if (blocksAvailable > 0 && boxValue > 0) {
      final marks = _available(boxMarks, refundedMarks);
      final int marked = marks.length < blocksAvailable ? marks.length : blocksAvailable;
      if (marked > 0) {
        rows.add(RefundRow(
            units: (marked * boxValue).toDouble(), blocks: marked, marks: marks));
      }
      final int rest = blocksAvailable - marked;
      if (rest > 0) {
        rows.add(RefundRow(units: (rest * boxValue).toDouble(), blocks: rest));
      }
    }

    final double loose = remainingUnits -
        (boxValue > 0 ? blocksAvailable * boxValue : 0).toDouble();
    if (loose > 0) {
      // Kasr qoldiq (kg) — markirovkali tovar emas.
      final marks =
          loose % 1 == 0 ? _available(unitMarks, refundedMarks) : const <String>[];
      final int marked = marks.length < loose ? marks.length : loose.toInt();
      if (marked > 0) {
        rows.add(RefundRow(units: marked.toDouble(), marks: marks));
      }
      final double rest = loose - marked;
      if (rest > 0) rows.add(RefundRow(units: rest));
    }

    return rows;
  }

  /// Server ro'yxati (`'\n'` bilan birlashgan) bo'sh bo'lsa lokal originaldan.
  static List<String> marksOf(String? fromServer, [String? fromLocal]) {
    final String src = (fromServer != null && fromServer.isNotEmpty)
        ? fromServer
        : (fromLocal ?? '');
    return src.split('\n').where((m) => m.isNotEmpty).toList();
  }

  static List<String> _available(List<String> marks, Set<String> refunded) =>
      {...marks}.where((m) => !refunded.contains(m)).toList();
}

enum RefundScanResult {
  /// KM shu qator havzasida — 1 dona / 1 blok o'ngga o'tadi.
  matched,

  /// Bo'sh yoki juda qisqa kod.
  empty,

  /// KM allaqachon o'ng ro'yxatda.
  alreadyAdded,

  /// KM shu kassadagi oldingi vozvratda ketgan.
  alreadyRefunded,

  /// Dona qatorida blok KM'i skanerlandi.
  boxMarkOnUnitRow,

  /// Blok qatorida dona KM'i skanerlandi.
  unitMarkOnBoxRow,

  /// KM shu chekdagi boshqa mahsulotniki (boshqa qator bosilgan).
  otherProduct,

  /// KM shu chekda sotilmagan.
  notInReceipt,
}

class RefundMarkScan {
  RefundMarkScan._();

  /// Skanerlangan kodning chekdagi KM bo'lishi mumkin bo'lgan shakllari —
  /// sotuvdagi bilan bir xil tozalash. Sotuvda ikki yo'l bor:
  /// * dona KM — `MarkCleaner.scanTime` (kripto qism kesiladi);
  /// * blok KM — faqat `BarcodeClassifier.sanitize` (`_addBoxProduct`), kripto
  ///   qism QOLADI: `0114780101733764217DtZ53Oi"RYhH02993zdxZ` (skaner GS ni
  ///   `029` qilib yuboradi). `scanTime` uni birinchi "93" da kesib qo'yardi.
  /// Ikkalasi ham chekda `forFiscal` dan o'tadi.
  ///
  /// Kassada rus tartibi yoqiq bo'lishi mumkin — kod o'zi, sotuvdagidek harf
  /// tugmalari o'girilgani (asosiy ekran skaneri) va to'liq o'girilgani sinanadi.
  static List<String> candidates(String raw) {
    final String text = raw.trim();
    return {
      for (final t in {
        text,
        KeyboardLayout.ruLettersToEn(text),
        KeyboardLayout.ruToEnFull(text),
      }) ...[
        MarkCleaner.forFiscal(MarkCleaner.scanTime(t)),
        MarkCleaner.forFiscal(BarcodeClassifier.sanitize(t)),
      ],
    }.where((m) => m.isNotEmpty).toList();
  }

  /// [candidates] dan havzadagi (saqlangan) KM — o'ngga aynan shu shakl o'tadi,
  /// soliqqa sotuvdagi `Label` ketadi.
  static String? matchIn(List<String> candidates, List<String> pool) {
    for (final c in candidates) {
      if (pool.contains(c)) return c;
    }
    return null;
  }

  /// [candidates] — [RefundMarkScan.candidates] natijasi. [pool] — bosilgan
  /// qatorning havzasi, [otherKindPool] — shu mahsulotning boshqa turdagi
  /// (dona ↔ blok) havzasi.
  static RefundScanResult check({
    required List<String> candidates,
    required bool isBlockRow,
    required List<String> pool,
    List<String> otherKindPool = const [],
    Set<String> inRight = const {},
    Set<String> refunded = const {},
  }) {
    // Sotuvdagi MarkingDialog bilan bir xil chegara.
    if (candidates.every((c) => c.length <= 15)) return RefundScanResult.empty;
    if (candidates.any(inRight.contains)) return RefundScanResult.alreadyAdded;
    if (matchIn(candidates, pool) != null) return RefundScanResult.matched;
    if (candidates.any(refunded.contains)) {
      return RefundScanResult.alreadyRefunded;
    }
    if (matchIn(candidates, otherKindPool) != null) {
      return isBlockRow
          ? RefundScanResult.unitMarkOnBoxRow
          : RefundScanResult.boxMarkOnUnitRow;
    }
    return RefundScanResult.notInReceipt;
  }
}
