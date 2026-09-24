// Sinxron oqimining asosiy kafolati:
//
//   kursor FAQAT muvaffaqiyatli olingan oynadan keyin suriladi.
//
// Aynan shu buzilgani uchun o'chiq turgan kassa narx o'zgarishini
// olmasdan qolib ketardi. Bu yerda tarmoq/HTTP o'rniga soxta `fetch`
// ishlatiladi, shuning uchun har xil uzilish stsenariysini aniq
// takrorlash mumkin.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/sync/server_clock.dart';
import 'package:invan2/changes/services/sync/stream_sync_runner.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('stream_sync_runner_test', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  const SyncStream stream = SyncStream.products;
  const StreamSyncRunner runner = StreamSyncRunner(stream: stream);

  /// So'ralgan oynalarni yozib boruvchi soxta fetch.
  late List<List<String>> asked;
  late int fullReloadCalls;

  setUp(() async {
    await Pref.setInt(stream.prefKey, 0);
    await Pref.setInt(stream.chunkPrefKey, 0);
    await Pref.removeWithKey(stream.reloadFailPrefKey);
    ServerClock.reset();
    asked = [];
    fullReloadCalls = 0;
  });

  tearDown(() {
    ServerClock.localNow = () => DateTime.now().toUtc();
    ServerClock.reset();
  });

  FetchWindow recording(
      SyncFetchResult Function(int callIndex) reply) {
    return (String s, String e) async {
      asked.add([s, e]);
      return reply(asked.length - 1);
    };
  }

  FullReload reloading({bool ok = true}) {
    return () async {
      fullReloadCalls++;
      return ok;
    };
  }

  group('kursor yo\'q — birinchi ishga tushish / yangilanishdan keyin', () {
    test('notification o\'rniga to\'liq yuklash bo\'ladi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1);
      expect(asked, isEmpty, reason: 'notification so\'ralmasligi kerak');
      expect(SyncCursor.raw(stream, end), end);
    });

    test('to\'liq yuklash yiqilsa kursor yozilmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(ok: false),
      );

      expect(ok, isFalse);
      expect(SyncCursor.has(stream), isFalse,
          reason: 'keyingi urinishda yana to\'liq yuklashi kerak');
    });

    test('to\'liq yuklash istisno tashlasa ham yiqilmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: () async => throw Exception('tarmoq yo\'q'),
      );

      expect(ok, isFalse);
      expect(SyncCursor.has(stream), isFalse);
    });
  });

  group('oddiy oqim', () {
    test('oynalar uzluksiz va kursor oxirigacha suriladi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(3)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 0);

      // Birinchi so'rov kursordan overlap qadar ortdan boshlanadi.
      expect(
        asked.first[0],
        SyncCursor.format(
            DateTime.utc(2026, 8, 12, 0).subtract(SyncCursor.overlap)),
      );
      // Oxirgi so'rov aynan `end` da tugaydi.
      expect(asked.last[1], SyncCursor.format(end));

      // Oynalar orasida bo'shliq yo'q — har keyingi oyna oldingisining
      // oxiridan overlap qadar ORTDAN boshlanadi (server chegarani qat'iy
      // solishtirsa ham chegaradagi soniya tushib qolmasin).
      for (int i = 1; i < asked.length; i++) {
        final DateTime prevEnd = SyncCursor.fmt.parseUtc(asked[i - 1][1]);
        expect(asked[i][0],
            SyncCursor.format(prevEnd.subtract(SyncCursor.overlap)));
      }

      expect(SyncCursor.raw(stream, end), end);
    });

    test('so\'ralgan sanalar UTC formatida ketadi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 9));

      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      for (final w in asked) {
        for (final s in w) {
          expect(s, matches(r'^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'));
        }
      }
      expect(asked.single[1], '2026-08-12 10:00:00');
    });

    test('yangilashga hojat yo\'q bo\'lsa so\'rov ham yubormaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      // Kursor `end` dan aynan overlap qadar keyinda — oyna bo'sh, lekin
      // bu hali "soat sakragan" emas (chegara), to'liq yuklash ham yo'q.
      await SyncCursor.commit(stream, end.add(SyncCursor.overlap));

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(asked, isEmpty);
      expect(fullReloadCalls, 0);
    });

    test('kursor `end` dan overlap\'dan ko\'proq keyinda — soat sakragan → '
        'to\'liq yuklash va kursor server vaqtiga qaytadi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      // Eski versiya kassaning 2 soat oldinda yurgan soati bilan yozgan.
      await SyncCursor.commit(stream, end.add(const Duration(hours: 2)));

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(asked, isEmpty);
      expect(fullReloadCalls, 1);
      expect(SyncCursor.raw(stream, end), end,
          reason: 'kursor endi kelajakda emas');
    });
  });

  group('uzilish va davom ettirish — asosiy stsenariy', () {
    test('o\'rtada yiqilsa kursor oxirgi muvaffaqiyatli bo\'lakda qoladi',
        () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));

      // 3-so'rov yiqiladi (timeout / 500).
      final ok = await runner.run(
        end: end,
        fetch: recording((i) =>
            i == 2 ? const SyncFetchResult.failed() : const SyncFetchResult.done(1)),
        fullReload: reloading(),
      );

      expect(ok, isFalse);
      expect(fullReloadCalls, 0);

      // Kursor 2-oynaning oxirida — 3-oyna qayta so'raladi.
      final expected = DateTime.utc(2026, 8, 12, 0)
          .subtract(SyncCursor.overlap)
          .add(const Duration(hours: 12));
      expect(SyncCursor.raw(stream, end), expected);
    });

    test('keyingi chaqiruv aynan uzilgan joydan davom etadi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));

      await runner.run(
        end: end,
        fetch: recording((i) =>
            i == 2 ? const SyncFetchResult.failed() : const SyncFetchResult.done(1)),
        fullReload: reloading(),
      );
      final DateTime afterFailure = SyncCursor.raw(stream, end);

      asked = [];
      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(1)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(asked.first[0],
          SyncCursor.format(afterFailure.subtract(SyncCursor.overlap)));
      expect(SyncCursor.raw(stream, end), end);
    });

    test('kassa 3 kun o\'chiq turdi — o\'sha davr to\'liq so\'raladi',
        () async {
      final off = DateTime.utc(2026, 8, 9, 18); // kassa o'chgan payt
      final end = DateTime.utc(2026, 8, 12, 18); // qayta yoqildi
      await SyncCursor.commit(stream, off);

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 0, reason: '3 kun < maxLookback');

      // Uch kunlik oraliq 6 soatlik bo'laklarga bo'linadi va butunlay
      // qamrab olinadi.
      expect(asked.length, 13);
      expect(asked.first[0],
          SyncCursor.format(off.subtract(SyncCursor.overlap)));
      expect(asked.last[1], SyncCursor.format(end));

      // Narx 10-avgust soat 09:00 da o'zgargan bo'lsa, uni qamragan oyna bor.
      final change = SyncCursor.format(DateTime.utc(2026, 8, 10, 9));
      final covered = asked.any((w) => w[0].compareTo(change) <= 0 && w[1].compareTo(change) > 0);
      expect(covered, isTrue);
    });

    test('bir chaqiruvda ulgurmasa qolgani keyingisiga qoladi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 11, 10));

      // 2 bo'lak bilan cheklaymiz: 24 soatlik oraliq bir chaqiruvda tugamaydi.
      const limited = StreamSyncRunner(stream: stream, maxChunksPerRun: 2);

      final ok = await limited.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(asked.length, 2);
      expect(SyncCursor.raw(stream, end).isBefore(end), isTrue);

      // Ikkinchi chaqiruv qolganini oladi.
      asked = [];
      await limited.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );
      expect(asked, isNotEmpty);
    });
  });

  group('server limitiga urilish', () {
    test('bir marta urilsa oyna bo\'linadi, to\'liq yuklash shart emas',
        () async {
      final end = DateTime.utc(2026, 8, 12, 6);
      // Kursorni overlap hisobga olib qo'yamiz: oyna aynan bitta bo'lak
      // (6 soat) bo'lsin, aks holda qoldiq uchun yana bir so'rov ketadi.
      await SyncCursor.commit(
          stream, DateTime.utc(2026, 8, 12, 0).add(SyncCursor.overlap));

      final ok = await runner.run(
        end: end,
        fetch: recording((i) => i == 0
            ? const SyncFetchResult.done(1000, truncated: true)
            : const SyncFetchResult.done(10)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 0);
      // 1 ta to'la oyna + 2 ta yarim oyna
      expect(asked.length, 3);
      expect(asked[1][0], asked[0][0], reason: 'birinchi yarim o\'sha joydan');
      expect(asked[2][1], asked[0][1], reason: 'ikkinchi yarim o\'sha joyda tugaydi');
      expect(SyncCursor.raw(stream, end), end);
    });

    test('bo\'lish ham yordam bermasa to\'liq yuklashga o\'tadi', () async {
      final end = DateTime.utc(2026, 8, 12, 6);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(1000, truncated: true)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1);
      expect(SyncCursor.raw(stream, end), end);
      // Cheksiz bo'linib ketmasligi kerak.
      expect(asked.length, lessThanOrEqualTo(16));
    });
  });

  group('qo\'lda to\'liq yangilash bilan bog\'lanish', () {
    // Galochkali "Yangilash" dialogi (UpdBloc) va drawer'dagi
    // sinxronizatsiya to'liq yuklagach kursorni surib qo'yadi. Shundan
    // keyin avto-sinxron eski notification'larni QAYTA o'qimasligi kerak.
    test('to\'liq yuklashdan keyin eski oyna qayta so\'ralmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      // Kassa 3 kun o'chiq turgan — kursor uzoqda.
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 9, 12));

      // Kassir galochkali dialogdan "Mahsulotlar"ni bosdi: to'liq yuklash
      // 11:59 da boshlandi va kursor o'sha vaqtga surildi.
      final startedAt = DateTime.utc(2026, 8, 12, 11, 59);
      await SyncCursor.commit(stream, startedAt);

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 0);
      // 3 kunlik 13 ta oyna emas, bittagina qisqa oyna.
      expect(asked.length, 1);
      expect(asked.single[0],
          SyncCursor.format(startedAt.subtract(SyncCursor.overlap)));
      expect(asked.single[1], SyncCursor.format(end));
    });

    test('yuklash davomidagi o\'zgarishlar oynadan tushib qolmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      // Yuklash 11:50 da boshlandi, 11:58 da tugadi. Kursor BOSHLANGAN
      // vaqtga surilgani uchun 11:50–11:58 oralig'i baribir so'raladi.
      final startedAt = DateTime.utc(2026, 8, 12, 11, 50);
      await SyncCursor.commit(stream, startedAt);

      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      final duringLoad = SyncCursor.format(DateTime.utc(2026, 8, 12, 11, 54));
      final covered = asked.any(
          (w) => w[0].compareTo(duringLoad) <= 0 && w[1].compareTo(duringLoad) > 0);
      expect(covered, isTrue);
    });
  });

  group('minInterval — sekin oqimlar (kategoriya / diskont)', () {
    const slow = StreamSyncRunner(
      stream: stream,
      minInterval: Duration(minutes: 10),
    );

    test('yaqinda sinxronlangan bo\'lsa so\'rov yubormaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, end.subtract(const Duration(minutes: 3)));

      final ok = await slow.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(asked, isEmpty);
      expect(fullReloadCalls, 0);
    });

    test('oraliq o\'tgach yana so\'raydi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, end.subtract(const Duration(minutes: 11)));

      final ok = await slow.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(asked.length, 1);
      expect(SyncCursor.raw(stream, end), end);
    });

    test('force cheklovni chetlab o\'tadi (ilova ochilganda / qo\'lda)',
        () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, end.subtract(const Duration(minutes: 3)));

      await slow.run(
        end: end,
        force: true,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(asked.length, 1);
    });

    test('kursor yo\'q bo\'lsa cheklov ushlab turmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);

      final ok = await slow.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1, reason: 'birinchi to\'liq yuklash kechikmasin');
    });

    test('mahsulot oqimida cheklov yo\'q — narx har chaqiruvda so\'raladi',
        () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, end.subtract(const Duration(minutes: 1)));

      // Standart runner (minInterval = zero) — mahsulot shunday sozlangan.
      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(asked.length, 1);
    });
  });

  group('kursor juda eskirgan', () {
    test('maxLookback dan eski bo\'lsa to\'g\'ridan-to\'g\'ri to\'liq yuklash',
        () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(
          stream, end.subtract(const Duration(days: 40)));

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1);
      expect(asked, isEmpty);
      expect(SyncCursor.raw(stream, end), end);
    });
  });
  group('server vaqti — kassa soati oldinda bo\'lsa ham kursor kelajakka ketmaydi',
      () {
    test('javobdagi server vaqti `end` dan oldin bo\'lsa kursor unga qisqaradi',
        () async {
      // Kassa soati bo'yicha `end` 10:00, server esa aslida 09:57.
      final end = DateTime.utc(2026, 8, 12, 10);
      final serverNow = DateTime.utc(2026, 8, 12, 9, 57);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 9));

      final ok = await runner.run(
        end: end,
        fetch: recording(
            (_) => SyncFetchResult.done(2, serverTime: serverNow)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(SyncCursor.raw(stream, end), serverNow,
          reason: 'keyingi oyna 09:55 dan boshlanadi — 09:57–10:00 '
              'orasidagi server notification\'lari tushib qolmaydi');
    });

    test('server vaqti `end` dan keyin bo\'lsa (oddiy holat) kursor `end` da',
        () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 9));

      await runner.run(
        end: end,
        fetch: recording((_) => SyncFetchResult.done(0,
            serverTime: end.add(const Duration(seconds: 1)))),
        fullReload: reloading(),
      );

      expect(SyncCursor.raw(stream, end), end);
    });

    test('oraliq bo\'laklar server vaqtidan ta\'sirlanmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      final serverNow = DateTime.utc(2026, 8, 12, 11, 58);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));

      // 3-so'rov yiqiladi: kursor 2-bo'lak oxirida qolishi kerak, server
      // vaqti (11:58) undan keyin bo'lgani uchun uni qisqartirmaydi.
      await runner.run(
        end: end,
        fetch: recording((i) => i == 2
            ? const SyncFetchResult.failed()
            : SyncFetchResult.done(1, serverTime: serverNow)),
        fullReload: reloading(),
      );

      final expected = DateTime.utc(2026, 8, 12, 0)
          .subtract(SyncCursor.overlap)
          .add(const Duration(hours: 12));
      expect(SyncCursor.raw(stream, end), expected);
    });

    test('to\'liq yuklashdan keyin kursor server vaqtida (mahalliy emas)',
        () async {
      // Kassa soati 2 soat oldinda: mahalliy 12:00, server 10:00.
      final end = DateTime.utc(2026, 8, 12, 10);
      ServerClock.localNow = () => DateTime.utc(2026, 8, 12, 12);
      ServerClock.observe(DateTime.utc(2026, 8, 12, 10),
          local: DateTime.utc(2026, 8, 12, 12));

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1);
      expect(SyncCursor.raw(stream, end), end,
          reason: 'mahalliy 12:00 emas, server 10:00');
    });
  });

  group('buzuq notification oqimni bloklamaydi', () {
    // Ilgari bitta parse xatosi butun oynani `failed` qilar, kursor joyida
    // qolar va har daqiqa o'sha xato takrorlanardi — 14 kungacha yoki
    // qo'lda to'liq yangilashgacha HECH NARSA yangilanmasdi.
    test('applyFailed → to\'liq yuklash va kursor oldinga suriladi',
        () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 9));

      final ok = await runner.run(
        end: end,
        fetch: recording(
            (_) => const SyncFetchResult.done(5, applyFailed: true)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1);
      expect(SyncCursor.raw(stream, end), end);

      // Keyingi chaqiruv eski (09:00 dan) oynani QAYTA so'ramaydi — faqat
      // odatdagi 2 daqiqalik overlap.
      asked = [];
      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );
      expect(asked.length, 1);
      expect(asked.single[0],
          SyncCursor.format(end.subtract(SyncCursor.overlap)));
    });

    test('to\'liq yuklash ham yiqilsa kursor joyida qoladi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      final before = DateTime.utc(2026, 8, 12, 9);
      await SyncCursor.commit(stream, before);

      final ok = await runner.run(
        end: end,
        fetch: recording(
            (_) => const SyncFetchResult.done(5, applyFailed: true)),
        fullReload: reloading(ok: false),
      );

      expect(ok, isFalse);
      expect(SyncCursor.raw(stream, end), before);
    });

    test('bo\'lingan oynaning birinchi yarmidagi applyFailed yo\'qolmaydi',
        () async {
      final end = DateTime.utc(2026, 8, 12, 6);
      await SyncCursor.commit(
          stream, DateTime.utc(2026, 8, 12, 0).add(SyncCursor.overlap));

      // To'la oyna limitga uriladi → bo'linadi; birinchi yarimda buzuq
      // notification bor, ikkinchi yarim toza.
      final ok = await runner.run(
        end: end,
        fetch: recording((i) {
          if (i == 0) return const SyncFetchResult.done(1000, truncated: true);
          if (i == 1) return const SyncFetchResult.done(10, applyFailed: true);
          return const SyncFetchResult.done(10);
        }),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1, reason: 'applyFailed e\'tiborsiz qolmasin');
    });
  });

  group('timeout — sekin internetda katta oyna', () {
    test('uzun oyna timeout bo\'lsa ikkiga bo\'lib qayta so\'raladi', () async {
      final end = DateTime.utc(2026, 8, 12, 6);
      await SyncCursor.commit(
          stream, DateTime.utc(2026, 8, 12, 0).add(SyncCursor.overlap));

      final ok = await runner.run(
        end: end,
        fetch: recording((i) => i == 0
            ? const SyncFetchResult.failed(timedOut: true)
            : const SyncFetchResult.done(3)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(asked.length, 3, reason: '1 to\'la + 2 yarim');
      expect(SyncCursor.raw(stream, end), end);
    });

    test('qisqa oyna (oddiy daqiqalik) timeout bo\'lsa bo\'linmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, end.subtract(const Duration(minutes: 1)));

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.failed(timedOut: true)),
        fullReload: reloading(),
      );

      expect(ok, isFalse);
      expect(asked.length, 1);
    });

    test('timeout\'dan keyin bo\'lak kichrayadi, muvaffaqiyatdan keyin qaytadi',
        () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));

      // Hamma so'rov timeout: oyna 6 soat → keyingi safar 3 soat.
      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.failed(timedOut: true)),
        fullReload: reloading(),
      );
      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
          const Duration(hours: 3));

      // Endi 3 soatlik bo'laklar bilan so'raladi va muvaffaqiyatli bo'lsa
      // bo'lak yana o'sadi.
      asked = [];
      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(1)),
        fullReload: reloading(),
      );
      final firstWindow = asked.first;
      final s = SyncCursor.fmt.parseUtc(firstWindow[0]);
      final e = SyncCursor.fmt.parseUtc(firstWindow[1]);
      expect(e.difference(s), const Duration(hours: 3));
      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
          const Duration(hours: 6));
    });

    test('bo\'lak hech qachon minChunk dan kichik bo\'lmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));

      for (int i = 0; i < 10; i++) {
        await runner.run(
          end: end,
          fetch:
              recording((_) => const SyncFetchResult.failed(timedOut: true)),
          fullReload: reloading(),
        );
      }
      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
          StreamSyncRunner.minChunk);
    });
  });
  group('monoton kursor va to\'xtatish (preempt)', () {
    test('oddiy commit kursorni orqaga surmaydi', () async {
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 12));
      final moved =
          await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 10));
      expect(moved, isFalse);
      expect(SyncCursor.raw(stream, DateTime.utc(2026, 8, 12, 13)),
          DateTime.utc(2026, 8, 12, 12));
    });

    test('force commit (to\'liq yuklash) orqaga ham yozadi', () async {
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 12));
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 10),
          force: true);
      expect(SyncCursor.raw(stream, DateTime.utc(2026, 8, 12, 13)),
          DateTime.utc(2026, 8, 12, 10));
    });

    test('qulf boshqa egaga o\'tsa run hech narsa yozmaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      final before = DateTime.utc(2026, 8, 12, 0);
      await SyncCursor.commit(stream, before);

      int calls = 0;
      final ok = await runner.run(
        end: end,
        // Ikkinchi oynadan boshlab qulf yo'qolgan.
        shouldContinue: () => calls < 1,
        fetch: recording((_) {
          calls++;
          return const SyncFetchResult.done(1);
        }),
        fullReload: reloading(),
      );

      expect(ok, isFalse);
      expect(asked.length, 1);
      expect(SyncCursor.raw(stream, end), before,
          reason: 'birinchi oyna ham commit qilinmaydi — commit oldidan '
              'qulf tekshiriladi');
    });

    test('beforeCommit har commit oldidan chaqiriladi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));
      int flushed = 0;

      await runner.run(
        end: end,
        beforeCommit: () async => flushed++,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(flushed, asked.length);
    });
  });

  group('server hozir, 401, type 0', () {
    test('server "hozir"iga yetgach qolgan (kelajak) oynalar so\'ralmaydi',
        () async {
      // Kassa soati 5 soat oldinda deylik: end 15:00, server aslida 10:00.
      final end = DateTime.utc(2026, 8, 12, 15);
      final serverNow = DateTime.utc(2026, 8, 12, 10);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 3));

      await runner.run(
        end: end,
        fetch: recording((_) => SyncFetchResult.done(0, serverTime: serverNow)),
        fullReload: reloading(),
      );

      // 03:00→15:00 = 12 soat = 2 oyna; birinchisi (03–09) server
      // hozirdan oldin, ikkinchisi (09–15) uni qamrab oladi → to'xtaydi.
      expect(asked.length, 2);
      expect(SyncCursor.raw(stream, end), serverNow);
    });

    test('401 → kursor joyida, bo\'lak kichraymaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      final before = DateTime.utc(2026, 8, 12, 0);
      await SyncCursor.commit(stream, before);

      final ok = await runner.run(
        end: end,
        fetch: recording(
            (_) => const SyncFetchResult.failed(unauthorized: true)),
        fullReload: reloading(),
      );

      expect(ok, isFalse);
      expect(asked.length, 1);
      expect(SyncCursor.raw(stream, end), before);
      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
          StreamSyncRunner.defaultChunk);
    });

    test('type 0 (fullReloadRequested) → bitta to\'liq yuklash, kursor end da',
        () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 0));

      final ok = await runner.run(
        end: end,
        fetch: recording((i) => i == 0
            ? const SyncFetchResult.done(3, fullReloadRequested: true)
            : const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1);
      expect(asked.length, 1, reason: 'qolgan oynalar so\'ralmaydi');
      expect(SyncCursor.raw(stream, end), end);
    });
  });

  group('eng kichik oyna timeout va backoff', () {
    test('minChunk oyna ham timeout bo\'lsa to\'liq yuklashga o\'tadi',
        () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 11));
      await SyncCursor.setChunk(stream, StreamSyncRunner.minChunk);

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.failed(timedOut: true)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(fullReloadCalls, 1);
      expect(SyncCursor.raw(stream, end), end);
    });

    test('yiqilgan to\'liq yuklash 5 daqiqa qayta urinilmaydi (backoff)',
        () async {
      final end = DateTime.utc(2026, 8, 12, 12);

      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(ok: false),
      );
      expect(fullReloadCalls, 1);

      // Bir daqiqadan keyin yana — urinilmaydi.
      await runner.run(
        end: end.add(const Duration(minutes: 1)),
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(ok: false),
      );
      expect(fullReloadCalls, 1);

      // force (ilova ochilganda / qo'lda) — chetlab o'tadi.
      await runner.run(
        end: end.add(const Duration(minutes: 2)),
        force: true,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(ok: false),
      );
      expect(fullReloadCalls, 2);

      // 5 daqiqadan keyin — yana uriniladi.
      await runner.run(
        end: end.add(const Duration(minutes: 8)),
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );
      expect(fullReloadCalls, 3);
      expect(SyncCursor.has(stream), isTrue);
    });

    test('qisqa (3 daqiqalik) oyna timeout bo\'lsa bo\'lak kichraymaydi',
        () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, end.subtract(const Duration(minutes: 1)));

      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.failed(timedOut: true)),
        fullReload: reloading(),
      );

      expect(SyncCursor.chunk(stream, StreamSyncRunner.defaultChunk),
          StreamSyncRunner.defaultChunk);
    });
  });

  group('migratsiya va tashlash', () {
    test('sxema versiyasi eski bo\'lsa hamma kursor tashlanadi (bir marta)',
        () async {
      for (final SyncStream st in SyncStream.values) {
        await SyncCursor.commit(st, DateTime.utc(2026, 8, 12, 10));
      }
      await Pref.setInt(PrefKeys.syncCursorSchema, 0);

      await SyncCursor.migrateIfNeeded();
      for (final SyncStream st in SyncStream.values) {
        expect(SyncCursor.has(st), isFalse);
      }

      // Ikkinchi marta — tegmaydi.
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 11));
      await SyncCursor.migrateIfNeeded();
      expect(SyncCursor.has(stream), isTrue);
    });

    test('reset → keyingi run to\'liq yuklaydi', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      await SyncCursor.commit(stream, DateTime.utc(2026, 8, 12, 11));
      await SyncCursor.reset(stream, reason: 'test');

      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );
      expect(fullReloadCalls, 1);
      expect(asked, isEmpty);
    });
  });

  group('to\'liq yuklash muddati tugashi — ish o\'zi to\'xtatiladi', () {
    setUp(() {
      StreamSyncRunner.fullReloadTimeout = const Duration(milliseconds: 50);
    });
    tearDown(() {
      StreamSyncRunner.fullReloadTimeout = const Duration(minutes: 15);
    });

    test(
        'muddat tugasa onFullReloadTimeout chaqiriladi (masalan yuklashni '
        'majburan to\'xtatish uchun)', () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      int cancelCalls = 0;

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        // Hech qachon tugamaydigan "yuklash" — Future.timeout uni real
        // hayotda ham to'xtata olmaydi, shuning uchun onFullReloadTimeout
        // orqali chaqiruvchi o'zi bekor qilishi kerak.
        fullReload: () => Completer<bool>().future,
        onFullReloadTimeout: () => cancelCalls++,
      );

      expect(ok, isFalse);
      expect(cancelCalls, 1,
          reason: '15 daqiqalik Future.timeout to\'xtagach chaqiruvchiga '
              'xabar berilishi kerak — aks holda yuklash fonda abadiy '
              'davom etar edi');
      expect(SyncCursor.has(stream), isFalse);
    });

    test('muvaffaqiyatli to\'liq yuklashda onFullReloadTimeout chaqirilmaydi',
        () async {
      final end = DateTime.utc(2026, 8, 12, 12);
      int cancelCalls = 0;

      await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
        onFullReloadTimeout: () => cancelCalls++,
      );

      expect(cancelCalls, 0);
    });
  });
}
