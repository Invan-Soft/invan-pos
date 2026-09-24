// `GET /notifications` so'rovi va qo'llanishi — uchala oqim uchun yagona
// yo'l. Bu yerda tarmoq o'rniga MockClient ishlatiladi.
//
// Asosiy kafolatlar:
//   * bitta buzuq notification qolganlarini to'xtatmaydi va natijada
//     `applyFailed` bilan qaytadi (ilgari butun oyna `failed` bo'lib kursor
//     abadiy qotib qolardi);
//   * notification'lar `created_at` bo'yicha o'sish tartibida qo'llanadi;
//   * server vaqti (`date` sarlavhasi) natijada qaytadi;
//   * timeout va tarmoq xatosi farqlanadi.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invan2/changes/services/sync/notification_fetch.dart';
import 'package:invan2/changes/services/sync/server_clock.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('notification_fetch_test', withEmployee: false);
    await Pref.setString(PrefKeys.token, 'test-token');
    await Pref.setString(PrefKeys.orgID, 'org-1');
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ServerClock.reset();
    NotificationFetch.timeout = const Duration(seconds: 5);
    NotificationFetch.idleTimeout = const Duration(seconds: 5);
  });

  tearDown(() {
    NotificationFetch.client = null;
    NotificationFetch.timeout = const Duration(seconds: 30);
    NotificationFetch.idleTimeout = const Duration(seconds: 45);
    ServerClock.localNow = () => DateTime.now().toUtc();
    ServerClock.reset();
  });

  Map<String, dynamic> n(String id, int type, {String? createdAt, Map<String, dynamic>? data}) => {
        'id': id,
        'type': type,
        if (createdAt != null) 'created_at': createdAt,
        'data': data ?? <String, dynamic>{},
      };

  void serve(
    List<Map<String, dynamic>> notifications, {
    int status = 200,
    Map<String, String> headers = const {},
    String? rawBody,
    void Function(http.Request)? onRequest,
  }) {
    NotificationFetch.client = MockClient((req) async {
      onRequest?.call(req);
      return http.Response(
        rawBody ??
            jsonEncode({
              'notifications': notifications,
              'total_count': notifications.length,
            }),
        status,
        headers: headers,
      );
    });
  }

  Future<SyncFetchResult> run(
    ApplyNotification apply, {
    Future<void> Function()? afterBatch,
  }) =>
      NotificationFetch.run(
        label: 'Test',
        types: '1,2',
        startDate: '2026-09-24 09:00:00',
        endDate: '2026-09-24 10:00:00',
        apply: apply,
        afterBatch: afterBatch,
      );

  group('tartiblash (sof funksiya)', () {
    test('created_at bo\'yicha o\'sish tartibi — server desc qaytarsa ham',
        () {
      final sorted = NotificationFetch.sortByCreatedAt([
        n('c', 2, createdAt: '2026-09-24T09:03:00Z'),
        n('a', 1, createdAt: '2026-09-24T09:01:00Z'),
        n('b', 2, createdAt: '2026-09-24T09:02:00Z'),
      ]);
      expect(sorted.map((e) => e['id']).toList(), ['a', 'b', 'c']);
    });

    test('teng vaqt va vaqti yo\'qlar asl tartibini saqlaydi (barqaror)', () {
      final sorted = NotificationFetch.sortByCreatedAt([
        n('x', 1),
        n('b', 1, createdAt: '2026-09-24T09:02:00Z'),
        n('y', 1),
        n('a', 1, createdAt: '2026-09-24T09:02:00Z'),
      ]);
      expect(sorted.map((e) => e['id']).toList(), ['x', 'y', 'b', 'a']);
    });

    test('bo\'sh joyli sana formati ham o\'qiladi', () {
      expect(NotificationFetch.parseCreatedAt('2026-09-24 09:02:00'),
          isNotNull);
      expect(NotificationFetch.parseCreatedAt('bugun'), isNull);
      expect(NotificationFetch.parseCreatedAt(null), isNull);
    });
  });

  group('xatoga chidamlilik', () {
    test('bitta buzuq notification qolganlarini to\'xtatmaydi', () async {
      serve([
        n('1', 1, createdAt: '2026-09-24T09:01:00Z'),
        n('2', 1, createdAt: '2026-09-24T09:02:00Z'),
        n('3', 1, createdAt: '2026-09-24T09:03:00Z'),
      ]);
      final applied = <String>[];

      final r = await run((ws) async {
        if (ws['id'] == '2') throw const FormatException('images: []');
        applied.add(ws['id'] as String);
        return NotifyApply.applied;
      });

      expect(r.ok, isTrue);
      expect(r.applyFailed, isTrue, reason: 'to\'liq yuklash bilan qoplanadi');
      expect(applied, ['1', '3']);
      expect(r.received, 3);
    });

    test('abort → oyna muvaffaqiyatsiz, kursor surilmasin', () async {
      serve([n('1', 0), n('2', 1)]);

      final r = await run((ws) async =>
          ws['id'] == '1' ? NotifyApply.abort : NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(r.timedOut, isFalse);
    });

    test('afterBatch faqat BIR marta — qo\'llanganlar bo\'lsa', () async {
      serve([n('1', 1), n('2', 1), n('3', 1)]);
      int refreshed = 0;

      await run((_) async => NotifyApply.applied,
          afterBatch: () async => refreshed++);

      expect(refreshed, 1);
    });

    test('hech narsa qo\'llanmasa afterBatch chaqirilmaydi', () async {
      serve([n('1', 6)]);
      int refreshed = 0;

      final r = await run((_) async => NotifyApply.ignored,
          afterBatch: () async => refreshed++);

      expect(r.ok, isTrue);
      expect(refreshed, 0);
    });

    test('id\'siz notification o\'tkazib yuboriladi', () async {
      serve([
        {'type': 1, 'data': {}},
        n('ok', 1),
      ]);
      final seen = <String>[];

      await run((ws) async {
        seen.add(ws['id'] as String);
        return NotifyApply.applied;
      });

      expect(seen, ['ok']);
    });
  });

  group('HTTP', () {
    test('so\'rov parametrlari va token', () async {
      late http.Request captured;
      serve([], onRequest: (req) => captured = req);

      await run((_) async => NotifyApply.applied);

      final q = captured.url.queryParameters;
      expect(q['company_id'], 'org-1');
      expect(q['type'], '1,2');
      expect(q['start_date'], '2026-09-24 09:00:00');
      expect(q['end_date'], '2026-09-24 10:00:00');
      expect(q['limit'], '${NotificationFetch.limit}');
      expect(captured.headers['Authorization'], 'Bearer test-token');
      // `is_read=false` — 2026-08-21'da jonli tekshirilgan YAGONA
      // konfiguratsiya; ataylab o'zgartirilmagan (notification_fetch.dart
      // buildPath izohiga qarang).
      expect(q['is_read'], 'false');
      expect(captured.headers['Cache-Control'], contains('no-store'));
    });

    test('401/403 → unauthorized bayrog\'i', () async {
      serve([], status: 401);
      final r = await run((_) async => NotifyApply.applied);
      expect(r.ok, isFalse);
      expect(r.unauthorized, isTrue);
    });

    test('type 0 → fullReloadRequested, qolganlari qo\'llanmaydi', () async {
      serve([
        n('a', 1, createdAt: '2026-09-24T09:01:00Z'),
        n('z', 0, createdAt: '2026-09-24T09:02:00Z'),
        n('b', 1, createdAt: '2026-09-24T09:03:00Z'),
      ]);
      final seen = <String>[];

      final r = await run((ws) async {
        if (ws['type'] == 0) return NotifyApply.fullReload;
        seen.add(ws['id'] as String);
        return NotifyApply.applied;
      });

      expect(r.ok, isTrue);
      expect(r.fullReloadRequested, isTrue);
      expect(seen, ['a']);
    });

    test('200 bilan kelgan xato tanasi bo\'sh oyna deb qabul qilinmaydi',
        () async {
      serve([], rawBody: '{"error": "company not found"}');
      final r = await run((_) async => NotifyApply.applied);
      expect(r.ok, isFalse);
    });

    test('created_at epoch (soniya/ms) ham o\'qiladi', () {
      final expected = DateTime.utc(2026, 9, 21, 14, 13, 20);
      expect(NotificationFetch.parseCreatedAt(1790000000), expected);
      expect(NotificationFetch.parseCreatedAt(1790000000000), expected);
      expect(NotificationFetch.parseCreatedAt('1790000000'), expected);
    });

    test('`date` sarlavhasi → serverTime va ServerClock', () async {
      ServerClock.localNow = () => DateTime.utc(2026, 9, 24, 12, 0, 0);
      serve([], headers: {'date': 'Thu, 24 Sep 2026 10:00:00 GMT'});

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isTrue);
      expect(r.serverTime, DateTime.utc(2026, 9, 24, 10, 0, 0));
      expect(ServerClock.offset, const Duration(hours: -2));
    });

    test('timeout → failed(timedOut) — oyna bo\'linadi', () async {
      NotificationFetch.timeout = const Duration(milliseconds: 50);
      NotificationFetch.client =
          MockClient((_) => Completer<http.Response>().future);

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(r.timedOut, isTrue);
    });

    test('tarmoq xatosi → failed, lekin timedOut emas', () async {
      NotificationFetch.client =
          MockClient((_) async => throw const SocketException('yo\'q'));

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(r.timedOut, isFalse);
    });

    test('500 → failed, server vaqti baribir o\'qiladi', () async {
      serve([],
          status: 500, headers: {'date': 'Thu, 24 Sep 2026 10:00:00 GMT'});

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(r.serverTime, DateTime.utc(2026, 9, 24, 10, 0, 0));
    });

    test('buzuq JSON → failed', () async {
      serve([], rawBody: '<html>502</html>');

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
    });

    test('notifications: null → bo\'sh oyna (ok, 0)', () async {
      serve([], rawBody: '{"notifications": null, "total_count": 0}');

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isTrue);
      expect(r.received, 0);
      expect(r.truncated, isFalse);
    });

    test('limit\'ga teng miqdor → truncated', () async {
      serve(List.generate(NotificationFetch.limit, (i) => n('$i', 1)));

      final r = await run((_) async => NotifyApply.ignored);

      expect(r.ok, isTrue);
      expect(r.truncated, isTrue);
    });

    test('total_count qaytgan miqdordan ko\'p bo\'lsa ham truncated (server '
        '`limit`dan kichikroq sahifa cheklovi qo\'ygan bo\'lishi mumkin)',
        () async {
      NotificationFetch.client = MockClient((_) async => http.Response(
          jsonEncode({
            'notifications':
                List.generate(200, (i) => n('$i', 1)),
            'total_count': 950,
          }),
          200));

      final r = await run((_) async => NotifyApply.ignored);

      expect(r.ok, isTrue);
      expect(r.received, 200);
      expect(r.truncated, isTrue,
          reason: '200 < total_count(950) — ba\'zi notification\'lar '
              'yashirin kesilgan bo\'lishi mumkin');
    });

    test('total_count qaytgan miqdorga teng bo\'lsa truncated emas',
        () async {
      NotificationFetch.client = MockClient((_) async => http.Response(
          jsonEncode({
            'notifications': [n('1', 1), n('2', 1)],
            'total_count': 2,
          }),
          200));

      final r = await run((_) async => NotifyApply.ignored);

      expect(r.truncated, isFalse);
    });

    test('token yo\'q bo\'lsa so\'rov ham ketmaydi', () async {
      await Pref.setString(PrefKeys.token, '');
      bool requested = false;
      serve([], onRequest: (_) => requested = true);

      final r = await run((_) async => NotifyApply.applied);

      expect(r.ok, isFalse);
      expect(requested, isFalse);
      await Pref.setString(PrefKeys.token, 'test-token');
    });
  });
}
