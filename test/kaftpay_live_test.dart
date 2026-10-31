// Kaftpay — HAQIQIY serverga qarshi (pos-api.kaftpay.uz). Odatda skip.
//
//   KAFTPAY_LIVE=1 flutter test test/kaftpay_live_test.dart
//
// Terminal kalitlarisiz ham foydali: server soxta client_id'ni 401/1100
// bilan qaytaradi, lekin soat tekshiruvi undan OLDIN turadi — shuning uchun
// kassa soatini tuzatish mexanizmini haqiqiy serverda sinash mumkin.
//
// Kalitlar kelganda (onboarding) to'liq tekshiruv:
//   KAFTPAY_LIVE=1 KAFTPAY_CLIENT_ID=... KAFTPAY_SECRET=... \
//     flutter test test/kaftpay_live_test.dart
// Hech narsa yechilmaydi: faqat /ping va pul yechmaydigan so'rovlar.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_error.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_models.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_payment_flow.dart';

final _env = Platform.environment;
final bool _live = _env['KAFTPAY_LIVE'] == '1';
final String? _clientId = _env['KAFTPAY_CLIENT_ID'];
final String? _secret = _env['KAFTPAY_SECRET'];
final bool _hasKeys = (_clientId ?? '').isNotEmpty && (_secret ?? '').isNotEmpty;

void main() {
  setUpAll(() => KaftpayApi.onHttpResponse = (_) {});

  group('soxta client_id bilan', () {
    KaftpayApi api({DateTime Function()? now}) => KaftpayApi(
          config: const KaftpayConfig(
              clientId: 'invan-probe-no-such-terminal', secret: 'x'),
          now: now,
        );

    test('/ping → 401/1100 "unknown or inactive terminal", auth', () async {
      final r = await api().ping();
      expect(r.isOk, isFalse);
      expect(r.error!.kind, KaftpayErrorKind.auth);
      expect(r.error!.code, '1100');
      expect(r.error!.httpStatus, 401);
      expect(r.error!.reason, 'unknown or inactive terminal');
    });

    test('kassa soati 10 daqiqa orqada → Date header bilan tuzatilib, '
        'soat tekshiruvidan o\'tadi', () async {
      final a = api(
          now: () => DateTime.now().subtract(const Duration(minutes: 10)));
      final r = await a.ping();
      // Tuzatilmaganda reason "timestamp out of range" bo'lardi.
      expect(r.error!.reason, 'unknown or inactive terminal');
      expect(a.clockOffset.inSeconds, closeTo(600, 15));
    });

    test('/identify → 401 (auth body\'dan oldin), so\'rov to\'g\'ri ketadi',
        () async {
      final r = await api().identify(KaftpayPalmScan(
          ir: List<double>.generate(516, (i) => ((i % 23) - 11) / 11)));
      expect(r.error!.kind, KaftpayErrorKind.auth);
      expect(r.error!.code, '1100');
    });

    test('/pay/status → 401, flow uni "unknown" qiladi, pul yechmaydi',
        () async {
      final o = await KaftpayPaymentFlow(api(), statusAttempts: 1)
          .resolve(KaftpayPaymentFlow.newIdempotencyKey());
      expect(o.state, KaftpayChargeState.unknown);
      expect(o.error!.code, '1100');
    });
  }, skip: _live ? false : 'KAFTPAY_LIVE=1 berilmagan');

  group('haqiqiy terminal kalitlari bilan', () {
    late KaftpayApi api;
    setUp(() => api = KaftpayApi(
        config: KaftpayConfig(clientId: _clientId!, secret: _secret!)));

    test('/ping — imzo ishlaydi, terminal holati', () async {
      final r = await api.ping();
      expect(r.isOk, isTrue, reason: '${r.error}');
      final d = r.data!;
      // ignore: avoid_print
      print('Kaftpay terminal: clientId=${d.clientId} code=${d.terminalCode} '
          'tin=${d.committentTin} ofdEnabled=${d.ofdEnabled} '
          'isTest=${d.isTest} status=${d.status}');
      expect(d.isActive, isTrue);
    });

    test('/identify sun\'iy vektor bilan → shifr ochiladi (1106 emas), '
        'server "haqiqiy skan emas" deydi', () async {
      final r = await api.identify(KaftpayPalmScan(
          ir: List<double>.generate(516, (i) => ((i % 23) - 11) / 11)));
      // ignore: avoid_print
      print('Kaftpay identify (sun\'iy): ok=${r.isOk} code=${r.error?.code} '
          'reason=${r.error?.reason} data=${r.data?.reasonRaw}');
      expect(r.error?.code, isNot('1106'), reason: 'palmDataEnc ochilmadi');
      expect(r.error?.code, isNot('1100'), reason: 'imzo');
    });

    test('/pay/status noma\'lum kalit → 1210 (pul yechilmagan)', () async {
      final r = await api.payStatus(KaftpayPaymentFlow.newIdempotencyKey());
      expect(r.error?.code, KaftpayErrorCodes.noPaymentForKey,
          reason: '${r.error}');
    });
  },
      skip: _live && _hasKeys
          ? false
          : 'KAFTPAY_CLIENT_ID / KAFTPAY_SECRET berilmagan');
}
