// RefundUploadQueue.uploadOne — bitta vozvratni serverga yuborish qoidasi.
//
// Nega kerak: onlayn vozvrat (`ReturnBloc`) va oflayn navbat (`flush`)
// endi shu bitta metoddan o'tadi. Qaror og'ir: `rejected` bo'lgan chek
// avtomatik navbatdan chiqadi va faqat kassir qo'lda yuborsagina ketadi.
//
//   200 / 201 / 409          → uploaded  (uploaded=true, rejected=false)
//   4xx                      → rejected  (rejected=true)
//   5xx, server TIRIK        → rejected
//   5xx, server O'LGAN       → pending   (bayroqlar tegilmaydi)
//   -3 (darvoza yopiq)       → pending
//   bir vaqtda ikki chaqiruv → bitta POST, ikkinchisi pending
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/health/backend_health.dart';
import 'package:invan2/changes/services/receipt/refund_upload_queue.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

ReceiptModel4 refund({String externalId = 'DN-7'}) => ReceiptModel4(
      createdDate: '2026-09-22 10:00:00',
      orderId: 'order-1',
      cashboxId: 'cashbox-1',
      externalId: externalId,
      orderType: 'refund',
      shopId: 'shop-1',
      userId: kUserId,
      discountVat: 0,
      discountID: '',
      newid: '',
      cashierId: kCashierId,
      cashierName: kCashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: true,
      totalPrice: 4000,
      uploaded: false,
      rejected: false,
      clientName: '',
      clientPhone: '',
      clientId: '',
      supplierId: '',
      cashback: 0,
      sdacha: 0,
      returnForCheck: 'DN-6',
      posName: 'Test POS',
      isDonate: false,
      url: 'https://ofd.soliq.uz/check?t=T&r=2&c=1&s=1',
    );

HttpResult http(int code, [String msg = 'msg']) => HttpResult(
      statusCode: code,
      isSuccess: code >= 200 && code < 300,
      result: msg,
      reBytes: '',
    );

void main() {
  setUpAll(() => setUpPosTestEnv('refund_upload_queue', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  late List<ReceiptModel4> persisted;
  late int sent;

  setUp(() {
    BackendHealth.reset();
    BackendHealth.autoProbe = false;
    BackendHealth.internetCheck = () async => true;
    BackendHealth.probeRequest = () async => true; // standart: server tirik
    RefundUploadQueue.resetForTest();
    persisted = [];
    sent = 0;
    RefundUploadQueue.persist = persisted.add;
  });

  tearDown(() {
    RefundUploadQueue.resetForTest();
    BackendHealth.reset();
    BackendHealth.autoProbe = true;
  });

  void answer(int code, [String msg = 'msg']) {
    RefundUploadQueue.sendRequest = (_) async {
      sent++;
      return http(code, msg);
    };
  }

  for (final code in [200, 201, 409]) {
    test('$code → uploaded, bayroqlar saqlanadi', () async {
      answer(code);
      final r = refund();
      final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
      expect(res.status, RefundUploadStatus.uploaded);
      expect(r.uploaded, isTrue);
      expect(r.rejected, isFalse);
      expect(persisted, [r]);
      expect(sent, 1);
    });
  }

  test('4xx → rejected, xabar qaytadi, rejected=true saqlanadi', () async {
    answer(422, 'Order already refunded');
    final r = refund();
    final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
    expect(res.status, RefundUploadStatus.rejected);
    expect(res.error, 'Order already refunded');
    expect(r.rejected, isTrue);
    expect(r.uploaded, isFalse);
    expect(persisted, [r]);
  });

  test('5xx, server tirik → rejected (ayb hujjatda)', () async {
    answer(500, 'boom');
    BackendHealth.probeRequest = () async => true;
    final r = refund();
    final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
    expect(res.status, RefundUploadStatus.rejected);
    expect(r.rejected, isTrue);
  });

  test('5xx, server o\'lgan → pending, bayroqlar tegilmaydi', () async {
    answer(502, 'bad gateway');
    BackendHealth.probeRequest = () async => false;
    final r = refund();
    final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
    expect(res.status, RefundUploadStatus.pending);
    expect(r.rejected, isFalse);
    expect(r.uploaded, isFalse);
    expect(persisted, isEmpty);
  });

  test('darvoza yopiq (-3) → pending', () async {
    answer(BackendHealth.serverDownStatusCode, "Server bilan aloqa yo'q");
    final r = refund();
    final res = await RefundUploadQueue.uploadOne(r, reason: 'test');
    expect(res.status, RefundUploadStatus.pending);
    expect(persisted, isEmpty);
  });

  test('bir vaqtda ikki chaqiruv (bloc + flush) → bitta POST', () async {
    final gate = Completer<void>();
    RefundUploadQueue.sendRequest = (_) async {
      sent++;
      await gate.future; // birinchi so'rov "ketayotgan" paytda
      return http(200);
    };
    final r = refund();
    final first = RefundUploadQueue.uploadOne(r, reason: 'bloc');
    await Future<void>.delayed(Duration.zero);
    final second = await RefundUploadQueue.uploadOne(r, reason: 'flush');
    expect(second.status, RefundUploadStatus.pending,
        reason: 'ikkinchi yo\'l kutmaydi va POST qilmaydi');
    gate.complete();
    final res = await first;
    expect(res.status, RefundUploadStatus.uploaded);
    expect(sent, 1);
    expect(r.uploaded, isTrue);
  });

  test('yuborish tugagach xuddi shu chek yana yuborilishi mumkin', () async {
    answer(500);
    BackendHealth.probeRequest = () async => false;
    final r = refund();
    expect((await RefundUploadQueue.uploadOne(r, reason: 'a')).status,
        RefundUploadStatus.pending);
    answer(200);
    expect((await RefundUploadQueue.uploadOne(r, reason: 'b')).status,
        RefundUploadStatus.uploaded);
    expect(sent, 2);
  });
}
