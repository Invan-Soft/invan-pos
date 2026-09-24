// Server soati — sinxron kursori kassa soatiga emas, server soatiga
// tayanishi kerak.
//
// Muammo: kassa soati serverdan 2 daqiqadan ko'proq OLDINDA bo'lsa kursor
// "server kelajagi"ga yozilar va keyingi oyna o'sha kelajakdan boshlanardi —
// oradagi notification'lar hech qachon so'ralmasdi. Bu yerda farq HTTP
// `date` sarlavhasidan qanday o'rganilishi va saqlanishi tekshiriladi.

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/sync/server_clock.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('server_clock_test', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  final DateTime local = DateTime.utc(2026, 9, 24, 10, 0, 0);

  setUp(() async {
    await Pref.removeWithKey(PrefKeys.serverClockOffsetMs);
    ServerClock.reset();
    ServerClock.localNow = () => local;
  });

  tearDown(() {
    ServerClock.localNow = () => DateTime.now().toUtc();
    ServerClock.reset();
  });

  test('farq noma\'lum bo\'lsa nol — eski xulq saqlanadi', () {
    expect(ServerClock.isKnown, isFalse);
    expect(ServerClock.offset, Duration.zero);
    expect(ServerClock.nowUtc(), local);
    expect(ServerClock.toServer(local), local);
  });

  test('kassa soati 2 soat OLDINDA: server vaqti kassa - 2 soat', () {
    // Server javob berganda uning soati 08:00 edi, kassaniki 10:00.
    ServerClock.observe(DateTime.utc(2026, 9, 24, 8, 0, 0));

    expect(ServerClock.isKnown, isTrue);
    expect(ServerClock.offset, const Duration(hours: -2));
    expect(ServerClock.nowUtc(), DateTime.utc(2026, 9, 24, 8, 0, 0));
    expect(ServerClock.toServer(DateTime.utc(2026, 9, 24, 10, 30)),
        DateTime.utc(2026, 9, 24, 8, 30));
  });

  test('kassa soati orqada: server vaqti oldinda chiqadi', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 10, 5, 0));
    expect(ServerClock.offset, const Duration(minutes: 5));
    expect(ServerClock.nowUtc(), DateTime.utc(2026, 9, 24, 10, 5, 0));
  });

  test('HTTP `date` sarlavhasi (RFC 1123) o\'qiladi', () {
    final DateTime? server = ServerClock.observeHeaders(
        {'date': 'Thu, 24 Sep 2026 09:58:30 GMT'});

    expect(server, DateTime.utc(2026, 9, 24, 9, 58, 30));
    expect(ServerClock.offset, const Duration(seconds: -90));
  });

  test('sarlavha yo\'q yoki buzuq bo\'lsa farq o\'zgarmaydi', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 9, 0, 0));

    expect(ServerClock.observeHeaders(const {}), isNull);
    expect(ServerClock.observeHeaders({'date': 'bugun'}), isNull);
    expect(ServerClock.offset, const Duration(hours: -1));
  });

  test('farq Pref\'da saqlanadi — ilova qayta ochilganda darhol to\'g\'ri',
      () async {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 8, 0, 0));
    // Yozuv `unawaited` — navbatni bo'shatamiz.
    await Future<void>.delayed(Duration.zero);

    // "Qayta ochilish": xotira tozalanadi, Pref qoladi.
    ServerClock.reset();

    expect(ServerClock.isKnown, isTrue);
    expect(ServerClock.offset, const Duration(hours: -2));
  });

  test('API serveri farqi notification serveri farqini bosmaydi', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 10, 0, 0),
        host: ServerClock.hostNotification);
    // API serveri 3 daqiqa oldinda yuradi.
    ServerClock.observe(DateTime.utc(2026, 9, 24, 10, 3, 0),
        host: ServerClock.hostApi);

    expect(ServerClock.offset, Duration.zero,
        reason: 'sinxron soati — notification serverniki');
  });

  test('notification farqi hali yo\'q bo\'lsa API farqi zaxira', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 9, 0, 0),
        host: ServerClock.hostApi);
    expect(ServerClock.offset, const Duration(hours: -1));
  });

  test('mahalliy (UTC bo\'lmagan) vaqt ham to\'g\'ri o\'tkaziladi', () {
    ServerClock.observe(DateTime.utc(2026, 9, 24, 9, 0, 0));
    final DateTime asLocal = DateTime.utc(2026, 9, 24, 10, 0, 0).toLocal();

    expect(ServerClock.toServer(asLocal), DateTime.utc(2026, 9, 24, 9, 0, 0));
    expect(ServerClock.toServer(asLocal).isUtc, isTrue);
  });
}
