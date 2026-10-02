import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';

/// Smena yopishdagi ogohlantirishlar va kassirga ko'rsatiladigan matnlar.
///
/// Tarix: 2026-08-17 da oflayn yopish uchun shart (`closedCount == 0`,
/// keyin `openedCount == 0` ham) va uni UI'da oldindan tekshiradigan
/// `blockingCloseIssue` qo'shilgan edi — navbatda ochish va yopish uchun
/// bittadan joy bor edi. 2026-10-02 dan navbat ro'yxat (`ShiftSyncQueue`):
/// internetsiz ham istalgancha yopish mumkin, to'siq yo'q. Navbatning o'zi
/// test/server_down_behaviour_test.dart da sinaladi.
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
      const ShiftIssue issue = ShiftIssue.offlineCloseBlockedByPendingOpen;
      expect(
        ShiftDiagnostics.title(issue, isUz: true).toLowerCase(),
        contains('yopilmadi'),
      );
      expect(
        ShiftDiagnostics.title(issue, isUz: false).toLowerCase(),
        contains('не закрыта'),
      );
    });

    test(
        'internet yo\'q — "keyingi smenani yopib bo\'lmaydi" deb '
        'ogohlantirmaydi (navbat ro\'yxat, cheklov yo\'q)', () {
      final String uz = ShiftDiagnostics.explain(
        ShiftIssue.noInternet,
        _snapshot(closedCount: 1, pendingCloseAt: '2026-10-02 09:00:00'),
        isUz: true,
      );
      final String ru = ShiftDiagnostics.explain(
        ShiftIssue.noInternet,
        _snapshot(closedCount: 1, pendingCloseAt: '2026-10-02 09:00:00'),
        isUz: false,
      );
      expect(uz, isNot(contains('yopib bo\'lmaydi')));
      expect(ru, isNot(contains('не получится')));
      expect(uz, contains('navbatiga tushadi'));
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
