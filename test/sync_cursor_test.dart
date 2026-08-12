// Sinxron kursori — vaqt konvensiyasi va turg'unlik testi.
//
// Eng muhim savol: `start_date`/`end_date` UTC bo'yicha ketyaptimi yoki
// mahalliy vaqt bo'yicha? Backend UTC kutadi (eski kod ham `toUtc()`
// ishlatgan), shuning uchun bu yerda mahalliy vaqt hech qachon
// so'rovga tushmasligi tekshiriladi.

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('sync_cursor_test', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    for (final SyncStream s in SyncStream.values) {
      await Pref.setInt(s.prefKey, 0);
    }
  });

  group('vaqt formati', () {
    test('format UTC devor-soatini beradi, mahalliy vaqtni emas', () {
      // 2026-08-12 09:30:00 UTC. Toshkentda bu 14:30 — agar biror joyda
      // mahalliy vaqtga o'tib ketilsa, natija "14:30" bo'lib qolardi.
      final utc = DateTime.utc(2026, 8, 12, 9, 30, 0);

      expect(SyncCursor.format(utc), '2026-08-12 09:30:00');
    });

    test('mahalliy DateTime ham UTC ga keltirilgach to\'g\'ri chiqadi', () {
      final local = DateTime(2026, 8, 12, 9, 30, 0);

      final formatted = SyncCursor.format(local.toUtc());
      final expected = SyncCursor.format(
        DateTime.utc(
          local.toUtc().year,
          local.toUtc().month,
          local.toUtc().day,
          local.toUtc().hour,
          local.toUtc().minute,
          local.toUtc().second,
        ),
      );

      expect(formatted, expected);
      // Mahalliy zona UTC bo'lmasa, mahalliy devor-soati bilan bir xil
      // bo'lmasligi kerak.
      if (local.timeZoneOffset != Duration.zero) {
        expect(formatted, isNot('2026-08-12 09:30:00'));
      }
    });

    test('formatlangan qator har doim 19 belgili va zonasiz', () {
      final s = SyncCursor.format(DateTime.utc(2026, 1, 2, 3, 4, 5));

      expect(s, '2026-01-02 03:04:05');
      expect(s.length, 19);
      expect(s.contains('Z'), isFalse);
      expect(s.contains('+'), isFalse);
    });
  });

  group('kursor turg\'unligi', () {
    test('commit qilingan vaqt aynan o\'sha instant bo\'lib qaytadi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      final commitAt = DateTime.utc(2026, 8, 12, 8);

      await SyncCursor.commit(SyncStream.products, commitAt);

      final raw = SyncCursor.raw(SyncStream.products, end);
      expect(raw.isUtc, isTrue);
      expect(raw.millisecondsSinceEpoch, commitAt.millisecondsSinceEpoch);
    });

    test('mahalliy DateTime commit qilinsa ham instant buzilmaydi', () async {
      final end = DateTime.now().toUtc();
      final local = DateTime.now().subtract(const Duration(hours: 3));

      await SyncCursor.commit(SyncStream.products, local);

      // millisecondsSinceEpoch zonaga bog'liq emas — 3 soat oldingi
      // instant o'sha-o'sha bo'lib qolishi kerak.
      final raw = SyncCursor.raw(SyncStream.products, end);
      expect(raw.millisecondsSinceEpoch, local.millisecondsSinceEpoch);
      expect(raw.isUtc, isTrue);
    });

    test('oqimlar bir-birining kursorini bosmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);

      await SyncCursor.commit(SyncStream.products, DateTime.utc(2026, 8, 12, 8));
      await SyncCursor.commit(
          SyncStream.categories, DateTime.utc(2026, 8, 12, 9));

      expect(SyncCursor.raw(SyncStream.products, end).hour, 8);
      expect(SyncCursor.raw(SyncStream.categories, end).hour, 9);
      expect(SyncCursor.has(SyncStream.discounts), isFalse);
    });
  });

  group('start — overlap va lookback', () {
    test('start kursordan overlap qadar ortga suriladi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      final commitAt = DateTime.utc(2026, 8, 12, 8);
      await SyncCursor.commit(SyncStream.products, commitAt);

      final start = SyncCursor.start(SyncStream.products, end);

      expect(start, commitAt.subtract(SyncCursor.overlap));
      expect(start.isUtc, isTrue);
    });

    test('juda eski kursor maxLookback bilan cheklanadi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(SyncStream.products, DateTime.utc(2020, 1, 1));

      final start = SyncCursor.start(SyncStream.products, end);

      expect(start, end.subtract(SyncCursor.maxLookback));
    });
  });

  group('needsFullReload', () {
    test('kursor yo\'q (yangi o\'rnatish / yangilanish) -> true', () {
      final end = DateTime.utc(2026, 8, 12, 10);

      expect(SyncCursor.needsFullReload(SyncStream.products, end), isTrue);
    });

    test('yangi kursor -> false', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(SyncStream.products, DateTime.utc(2026, 8, 12, 8));

      expect(SyncCursor.needsFullReload(SyncStream.products, end), isFalse);
    });

    test('maxLookback chegarasidan eski kursor -> true', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(
        SyncStream.products,
        end.subtract(SyncCursor.maxLookback + const Duration(minutes: 1)),
      );

      expect(SyncCursor.needsFullReload(SyncStream.products, end), isTrue);
    });

    test('chegaradagi kursor (roppa-rosa maxLookback) -> false', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(
          SyncStream.products, end.subtract(SyncCursor.maxLookback));

      expect(SyncCursor.needsFullReload(SyncStream.products, end), isFalse);
    });
  });
}
