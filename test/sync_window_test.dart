import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';

void main() {
  DateTime utc(int y, int m, int d, [int h = 0, int min = 0]) =>
      DateTime.utc(y, m, d, h, min);

  group('SyncWindow.split', () {
    test('bo\'sh oraliq uchun hech narsa qaytarmaydi', () {
      final t = utc(2026, 8, 12, 10);
      expect(SyncWindow.split(t, t, const Duration(hours: 6)), isEmpty);
      expect(
        SyncWindow.split(t, t.subtract(const Duration(hours: 1)),
            const Duration(hours: 6)),
        isEmpty,
      );
    });

    test('bo\'lakdan qisqa oraliq bitta oyna bo\'ladi', () {
      final start = utc(2026, 8, 12, 10);
      final end = utc(2026, 8, 12, 12);

      final windows = SyncWindow.split(start, end, const Duration(hours: 6));

      expect(windows.length, 1);
      expect(windows.first.start, start);
      expect(windows.first.end, end);
    });

    test('uzun oraliq uzluksiz bo\'laklarga bo\'linadi', () {
      final start = utc(2026, 8, 10);
      final end = utc(2026, 8, 11, 3);

      final windows = SyncWindow.split(start, end, const Duration(hours: 6));

      // 27 soat / 6 = 4 to'liq + 1 qisman
      expect(windows.length, 5);
      expect(windows.first.start, start);
      expect(windows.last.end, end);

      // bo'laklar orasida bo'shliq qolmasligi kerak — aks holda
      // notification tushib qoladi
      for (int i = 1; i < windows.length; i++) {
        expect(windows[i].start, windows[i - 1].end);
      }
    });

    test('oxirgi bo\'lak end dan oshib ketmaydi', () {
      final start = utc(2026, 8, 12, 0);
      final end = utc(2026, 8, 12, 7);

      final windows = SyncWindow.split(start, end, const Duration(hours: 6));

      expect(windows.length, 2);
      expect(windows.last.start, utc(2026, 8, 12, 6));
      expect(windows.last.end, end);
    });

    test('maxChunks cheklovi qolgan qismni keyingi chaqiruvga qoldiradi', () {
      final start = utc(2026, 7, 1);
      final end = utc(2026, 8, 1);

      final windows = SyncWindow.split(
        start,
        end,
        const Duration(hours: 6),
        maxChunks: 3,
      );

      expect(windows.length, 3);
      expect(windows.first.start, start);
      // Oxiri end emas — qolgani keyingi chaqiruvda davom etadi.
      expect(windows.last.end, utc(2026, 7, 1, 18));
      expect(windows.last.end.isBefore(end), isTrue);
    });

    test('noto\'g\'ri parametrlar cheksiz halqaga olib kelmaydi', () {
      final start = utc(2026, 8, 12);
      final end = utc(2026, 8, 13);

      expect(SyncWindow.split(start, end, Duration.zero), isEmpty);
      expect(
        SyncWindow.split(start, end, const Duration(hours: 6), maxChunks: 0),
        isEmpty,
      );
    });
  });
}
