import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';

/// Smenani yopish mumkinmi — `ShiftSingleton4.closeShift` ning oflayn
/// shoxidagi shart bilan bir xil bo'lishi kerak:
///
/// ```dart
/// if (closedCount == 0 && openedCount == 0) { ...yopiladi... }
/// ```
///
/// 2026-08-17 da UI shu shartni bilmasdi: kassirga "Smena yopildi" deb xabar
/// berilardi, kod esa smenani yopmasdi.
ShiftSnapshot _snapshot({
  bool internet = false,
  int openedCount = 0,
  int closedCount = 0,
  String pendingOpenAt = '',
  String pendingCloseAt = '',
  int unsentReceipts = 0,
  String cashboxId = 'kassa-1',
}) {
  return ShiftSnapshot(
    internet: internet,
    unsentReceipts: unsentReceipts,
    rejectedReceipts: 0,
    pendingCloseAt: pendingCloseAt,
    pendingOpenAt: pendingOpenAt,
    openedCount: openedCount,
    closedCount: closedCount,
    shiftsOpened: true,
    currentShiftKey: 1,
    posName: 'Kassa 1',
    cashboxId: cashboxId,
    cashierName: 'Test',
  );
}

void main() {
  group('canCloseOffline — ShiftSingleton4 sharti bilan bir xil', () {
    test('ikkala hisoblagich 0 bo\'lsa yopish mumkin', () {
      expect(_snapshot().canCloseOffline, isTrue);
    });

    test('oflayn ochilgan smena (openedCount=1) — yopib bo\'lmaydi', () {
      expect(_snapshot(openedCount: 1).canCloseOffline, isFalse);
    });

    test('navbatda yopish turibdi (closedCount=1) — yopib bo\'lmaydi', () {
      expect(_snapshot(closedCount: 1).canCloseOffline, isFalse);
    });
  });

  group('blockingCloseIssue', () {
    test('internet bor — hech qachon bloklamaydi (server hal qiladi)', () {
      expect(
        ShiftDiagnostics.blockingCloseIssue(
          _snapshot(internet: true, openedCount: 1, closedCount: 1),
        ),
        isNull,
      );
    });

    test('oflayn, hisoblagichlar toza — bloklamaydi', () {
      expect(ShiftDiagnostics.blockingCloseIssue(_snapshot()), isNull);
    });

    test('oflayn ochilgan smena — pendingOpen sababi bilan bloklanadi', () {
      expect(
        ShiftDiagnostics.blockingCloseIssue(_snapshot(openedCount: 1)),
        ShiftIssue.offlineCloseBlockedByPendingOpen,
      );
    });

    test('navbatdagi yopish — pendingClose sababi bilan bloklanadi', () {
      expect(
        ShiftDiagnostics.blockingCloseIssue(_snapshot(closedCount: 1)),
        ShiftIssue.offlineCloseBlockedByPendingClose,
      );
    });

    test('ikkalasi ham 1 bo\'lsa — ochish sababi ustun (asl sabab shu)', () {
      expect(
        ShiftDiagnostics.blockingCloseIssue(
          _snapshot(openedCount: 1, closedCount: 1),
        ),
        ShiftIssue.offlineCloseBlockedByPendingOpen,
      );
    });
  });

  group('Kassirga ko\'rsatiladigan matn', () {
    test('bloklovchi sabab — nima bo\'ldi / sabab / nima qilish kerak', () {
      final String uz = ShiftDiagnostics.explain(
        ShiftIssue.offlineCloseBlockedByPendingOpen,
        _snapshot(openedCount: 1, pendingOpenAt: '2026-08-17 09:00:00'),
        isUz: true,
      );

      expect(uz, contains('NIMA BO\'LDI'));
      expect(uz, contains('SABAB'));
      expect(uz, contains('NIMA QILISH KERAK'));
      // Kassir birinchi navbatda sotuvlar yo'qolishidan qo'rqadi.
      expect(uz, contains('yo\'qolmaydi'));
    });

    test('bloklovchi sabab sarlavhasi "yopilmadi" deyishi shart', () {
      for (final issue in [
        ShiftIssue.offlineCloseBlockedByPendingOpen,
        ShiftIssue.offlineCloseBlockedByPendingClose,
      ]) {
        expect(
          ShiftDiagnostics.title(issue, isUz: true).toLowerCase(),
          contains('yopilmadi'),
        );
        expect(
          ShiftDiagnostics.title(issue, isUz: false).toLowerCase(),
          contains('не закрыта'),
        );
      }
    });

    test(
        'serverCloseFailed — navbatga tushmagan bo\'lsa "qayta yuboriladi" '
        'deb va\'da bermaydi', () {
      final String notQueued = ShiftDiagnostics.explain(
        ShiftIssue.serverCloseFailed,
        _snapshot(internet: true),
        isUz: true,
      );
      expect(notQueued, contains('navbatga\ntushmadi'.replaceAll('\n', ' ')));
      expect(notQueued, isNot(contains('avtomatik qayta yuboriladi')));

      final String queued = ShiftDiagnostics.explain(
        ShiftIssue.serverCloseFailed,
        _snapshot(
          internet: true,
          closedCount: 1,
          pendingCloseAt: '2026-08-17 09:00:00',
        ),
        isUz: true,
      );
      expect(queued, contains('avtomatik qayta yuboriladi'));
    });

    test('har bir sabab uchun uz va ru matn bor', () {
      for (final issue in ShiftIssue.values) {
        for (final isUz in [true, false]) {
          expect(ShiftDiagnostics.title(issue, isUz: isUz), isNotEmpty);
          expect(
            ShiftDiagnostics.explain(issue, _snapshot(), isUz: isUz),
            isNotEmpty,
          );
        }
      }
    });
  });

  group('closeWarnings — yopish mumkin bo\'lgandagi ogohlantirishlar', () {
    test('internet yo\'q + ketmagan chek', () {
      final List<ShiftIssue> issues =
          ShiftDiagnostics.closeWarnings(_snapshot(unsentReceipts: 3));
      expect(issues, contains(ShiftIssue.noInternet));
      expect(issues, contains(ShiftIssue.unsentReceipts));
    });

    test('hammasi joyida — bo\'sh ro\'yxat', () {
      expect(
        ShiftDiagnostics.closeWarnings(_snapshot(internet: true)),
        isEmpty,
      );
    });

    test('kassa aktivlashtirilmagan', () {
      expect(
        ShiftDiagnostics.closeWarnings(_snapshot(internet: true, cashboxId: '')),
        contains(ShiftIssue.posNotActivated),
      );
    });
  });
}
