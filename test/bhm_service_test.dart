// BhmService — naqd chegarasi (400 × BHM) manbai testlari.
//
// Nega kerak: bu qiymat noto'g'ri bo'lsa kassa yo qonunga zid naqd qabul
// qiladi, yo ruxsat etilgan sotuvda naqdni yopib qo'yadi. Shuning uchun
// fallback, kesh, TTL va xato holatlarida keshning buzilmasligi mixlanadi.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:invan2/changes/services/cash_limit/bhm_service.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStir = '200523221';

/// Soliq API'ning 2026-09-10 dagi real javob shakli.
http.Response okResponse(int amount) => http.Response(
      jsonEncode({
        'success': true,
        'reason': "So'rov bajarildi",
        'data': true,
        'percent': 12,
        'cashSaleAllowed': false,
        'fractionalSale': false,
        'baseCalculationAmount': amount,
      }),
      200,
    );

void main() {
  setUpAll(() => setUpPosTestEnv('bhm_service_test', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  late List<Uri> calls;

  setUp(() async {
    calls = [];
    await BhmService.clearCache();
    await Pref.setString(PrefKeys.organizationINN, kStir);
    BhmService.now = DateTime.now;
    BhmService.request = (uri) async {
      calls.add(uri);
      return okResponse(440000);
    };
  });

  group('fallback va kesh', () {
    test('kesh bo\'sh → fallback 440 000, chegara 176 mln', () {
      expect(BhmService.hasCached, isFalse);
      expect(BhmService.bhm, 440000);
      expect(BhmService.cashLimit, 176000000);
    });

    test('keshda qiymat bo\'lsa u ustun', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 500000);
      expect(BhmService.bhm, 500000);
      expect(BhmService.cashLimit, 200000000);
    });

    test('keshda 0 bo\'lsa fallback', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 0);
      expect(BhmService.hasCached, isFalse);
      expect(BhmService.bhm, 440000);
    });
  });

  group('refresh', () {
    test('muvaffaqiyat → kesh va vaqt yoziladi, URL STIR bilan', () async {
      final fixed = DateTime(2026, 9, 10, 12);
      BhmService.now = () => fixed;
      BhmService.request = (uri) async {
        calls.add(uri);
        return okResponse(450000);
      };

      expect(await BhmService.refresh(reason: 'test'), isTrue);
      expect(calls.single.toString(), '${BhmService.endpoint}$kStir');
      expect(BhmService.bhm, 450000);
      expect(BhmService.cashLimit, 180000000);
      expect(BhmService.fetchedAt, fixed);
    });

    test('STIR yo\'q → so\'rov yuborilmaydi', () async {
      await Pref.setString(PrefKeys.organizationINN, '');
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(calls, isEmpty);
      expect(BhmService.hasCached, isFalse);
    });

    test('HTTP 401 → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response('{"status":401}', 401);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('success:false → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response(
          jsonEncode({'success': false, 'baseCalculationAmount': 999999}),
          200);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('JSON buzuq → kesh o\'zgarmaydi', () async {
      await Pref.setInt(PrefKeys.bhmAmount, 430000);
      BhmService.request = (_) async => http.Response('<html>', 200);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.bhm, 430000);
    });

    test('so\'rov exception tashlasa → false, exception chiqmaydi', () async {
      BhmService.request = (_) async => throw Exception('timeout');
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.hasCached, isFalse);
    });

    test('amount 0 → rad etiladi', () async {
      BhmService.request = (_) async => okResponse(0);
      expect(await BhmService.refresh(reason: 'test'), isFalse);
      expect(BhmService.hasCached, isFalse);
    });

    test('parallel ikki chaqiruv → bitta so\'rov', () async {
      final results = await Future.wait([
        BhmService.refresh(reason: 'a'),
        BhmService.refresh(reason: 'b'),
      ]);
      expect(results, [true, true]);
      expect(calls.length, 1);
    });
  });

  group('refreshIfStale', () {
    test('kesh yo\'q → so\'raydi', () async {
      expect(await BhmService.refreshIfStale(reason: 'test'), isTrue);
      expect(calls.length, 1);
      expect(BhmService.hasCached, isTrue);
    });

    test('kesh yangi (TTL ichida) → so\'ramaydi', () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      calls.clear();

      BhmService.now = () => t0.add(const Duration(hours: 23));
      expect(await BhmService.refreshIfStale(reason: 'test'), isFalse);
      expect(calls, isEmpty);
    });

    test('kesh TTL dan eski → qayta so\'raydi', () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      calls.clear();

      BhmService.now = () => t0.add(BhmService.refreshInterval);
      expect(await BhmService.refreshIfStale(reason: 'test'), isTrue);
      expect(calls.length, 1);
    });

    test('yangilash yiqilsa eski kesh qoladi, keyingi safar yana urinadi',
        () async {
      final t0 = DateTime(2026, 9, 10, 8);
      BhmService.now = () => t0;
      await BhmService.refresh(reason: 'seed');
      BhmService.now = () => t0.add(const Duration(days: 2));
      BhmService.request = (_) async => throw Exception('offline');

      expect(await BhmService.refreshIfStale(reason: 'test'), isFalse);
      expect(BhmService.bhm, 440000);
      expect(BhmService.fetchedAt, t0);
      expect(BhmService.isStale, isTrue);
    });
  });

  group('parseAmount', () {
    test('to\'g\'ri javob', () {
      expect(
        BhmService.parseAmount(
            {'success': true, 'baseCalculationAmount': 440000}),
        440000,
      );
    });

    test('double ham qabul qilinadi', () {
      expect(BhmService.parseAmount({'baseCalculationAmount': 440000.0}),
          440000);
    });

    test('string rad etiladi', () {
      expect(
          BhmService.parseAmount({'baseCalculationAmount': '440000'}), isNull);
    });

    test('Map emas → null', () {
      expect(BhmService.parseAmount([1, 2]), isNull);
      expect(BhmService.parseAmount(null), isNull);
    });
  });
}
