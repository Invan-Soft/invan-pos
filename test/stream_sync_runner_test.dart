// Sinxron oqimining asosiy kafolati:
//
//   kursor FAQAT muvaffaqiyatli olingan oynadan keyin suriladi.
//
// Aynan shu buzilgani uchun o'chiq turgan kassa narx o'zgarishini
// olmasdan qolib ketardi. Bu yerda tarmoq/HTTP o'rniga soxta `fetch`
// ishlatiladi, shuning uchun har xil uzilish stsenariysini aniq
// takrorlash mumkin.

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/sync/stream_sync_runner.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';
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
    asked = [];
    fullReloadCalls = 0;
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

      // Oynalar orasida bo'shliq yo'q — aks holda notification tushib qoladi.
      for (int i = 1; i < asked.length; i++) {
        expect(asked[i][0], asked[i - 1][1]);
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
      // Kursor `end` dan keyinda — overlap ham hisobga olinsa oyna bo'sh.
      await SyncCursor.commit(stream, end.add(const Duration(hours: 1)));

      final ok = await runner.run(
        end: end,
        fetch: recording((_) => const SyncFetchResult.done(0)),
        fullReload: reloading(),
      );

      expect(ok, isTrue);
      expect(asked, isEmpty);
      expect(fullReloadCalls, 0);
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
}
