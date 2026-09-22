// ReturnBloc — vozvrat oqimining TARTIBI va holatlari.
//
// Nega kerak: 2026-09-22 gacha server (`refund_for_pos_new`) fiskal moduldan
// OLDIN chaqirilar va serverga asl SOTUV chekining QR URL'i ketardi. Endi
// tartib: fiskal → ObjectBox → server. Bu test o'sha tartibni va har bir
// chetki holatda bloc nima qilishini mixlaydi — tarmoqsiz, fiskal modulsiz,
// ObjectBox'siz (hammasi `ReturnBlocDeps` orqali soxta).
//
// Holatlar jadvali:
//   1. internet yo'q                         → NoInternet, hech narsa chaqirilmaydi
//   2. fiskal OK, server OK                  → fiskal→save→upload; url = vozvrat URL'i
//   3. fiskal OK, server 4xx (rejected)      → Succeed + warning, save bo'lgan
//   4. fiskal OK, server javob bermadi       → Succeed (warning yo'q), navbatda
//   5. fiskal OK, server yiqilgani ma'lum    → upload chaqirilmaydi, Succeed
//   6. fiskal XATO                           → Failed, save ham, upload ham YO'Q
//   7. fiskal exception                      → Failed, save/upload yo'q
//   8. OFD yoqiq, sotuv OFDda yo'q (pre-check)→ fiskal yo'q, fiskal maydonlar bo'sh
//   9. OFD o'chiq, sotuvda url bor           → fiskal yo'q, url bo'sh (sotuv URL'i ketmaydi)
//  10. vozvrat modeli: isRefund, CASH to'lov, rightList, yangi chek raqami
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/services/receipt/refund_upload_queue.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/bloc/return_bloc.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/return_dialog.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/l10n/app_localizations_uz.dart';

import 'support/provider_harness.dart';

const kSaleUrl =
    'https://ofd.soliq.uz/check?t=LG230110020538&r=38001&c=20260922090000&s=111111111111';
const kRefundUrl =
    'https://ofd.soliq.uz/check?t=LG230110020538&r=38002&c=20260922094049&s=513103888474';
const kTerminal = 'LG230110020538';

ReceiptModelSoldItem4 row({
  String productId = 'p1',
  double price = 4000,
  double value = 1,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: '4780000000001',
    sku: 7105,
    vatPercent: 12,
    vat: (price * 12) / 112,
    mxik: '01234567890123456',
    tin: '',
    onlyPrice: price,
    realPrice: price,
    price: price,
    cost: 0,
    vatName: 'НДС 12%',
    createdTime: DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: 'Test tovar',
    sellerId: kCashierId,
    soldBy: kCashierId,
    singleDiscount: 0,
    ownerType: 1,
    mark: null,
    marking: false,
    packageCode: '1512199',
    packageName: 'dona',
  );
}

/// Asl SOTUV cheki. [registeredOnOfd] — soliqqa yozilgan (url + pasport).
ReceiptModel4 sale({bool registeredOnOfd = true}) {
  final Info pasport = Info(
    qrCodeUrl: kSaleUrl,
    terminalId: kTerminal,
    receiptSeq: '38001',
    dateTime: '20260922090000',
    fiscalSign: '111111111111',
  );
  final r = ReceiptModel4(
    createdDate: '2026-09-22 09:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'DN-100',
    orderType: 'sale',
    shopId: 'shop-1',
    userId: kUserId,
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: kCashierId,
    cashierName: kCashierName,
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: false,
    totalPrice: 8000,
    uploaded: true,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: '',
    posName: 'Test POS',
    isDonate: false,
    refundInfo: registeredOnOfd ? jsonEncode(pasport.toJson()) : null,
    url: registeredOnOfd ? kSaleUrl : '',
    terminalId: registeredOnOfd ? kTerminal : null,
    receiptSeq: registeredOnOfd ? 38001 : null,
    dateTimeOFD: registeredOnOfd ? '20260922090000' : null,
    fiscalSign: registeredOnOfd ? '111111111111' : null,
  );
  r.soldItemList.addAll([row(productId: 'p1', value: 2)]);
  return r;
}

CommunicatorRESPONSE fiscalOk() => CommunicatorRESPONSE(
      error: false,
      paycheck: 'pdf',
      method: 'Api.SendRefundReceipt',
      info: Info(
        qrCodeUrl: kRefundUrl,
        terminalId: kTerminal,
        receiptSeq: '38002',
        dateTime: '20260922094049',
        fiscalSign: '513103888474',
      ),
      itemInfo: const [],
    );

CommunicatorRESPONSE fiscalFail(String msg) => CommunicatorRESPONSE(
      error: true,
      paycheck: msg,
      info: null,
      itemInfo: const [],
    );

/// Soxta bog'liqliklar: chaqiruvlar tartibini va modelning o'sha paytdagi
/// holatini yozib boradi.
class FakeDeps {
  bool internet = true;
  bool serverUp = true;
  bool ofd = true;
  Future<CommunicatorRESPONSE> Function(ReceiptModel4) fiscal =
      (_) async => fiscalOk();
  RefundUploadResult uploadResult =
      const RefundUploadResult(RefundUploadStatus.uploaded);

  final List<String> calls = [];
  ReceiptModel4? saved;
  CommunicatorRESPONSE? savedResponse;
  ReceiptModel4? uploaded;
  String? uploadedUrl; // upload paytidagi url (keyin o'zgarmasin)

  ReturnBlocDeps build() => ReturnBlocDeps(
        hasInternet: () async => internet,
        isServerUp: () => serverUp,
        withOfd: () => ofd,
        nextCheckNo: () async => 'DN-101',
        fiscalSell: (loc, r) {
          calls.add('fiscal');
          return fiscal(r);
        },
        saveLocal: (r, resp) async {
          calls.add('save');
          saved = r;
          savedResponse = resp;
        },
        uploadToServer: (r) async {
          calls.add('upload');
          uploaded = r;
          uploadedUrl = r.url;
          return uploadResult;
        },
      );
}

Future<List<ReturnState>> run(FakeDeps deps, {ReceiptModel4? original}) async {
  final bloc = ReturnBloc(deps: deps.build());
  final states = <ReturnState>[];
  final sub = bloc.stream.listen(states.add);
  final src = original ?? sale();
  bloc.add(ReturnReturnEvent(
    isRetry: false,
    clientNumber: '',
    receiptModel4: src,
    rightList: [row(productId: 'p1', value: 1)],
    loc: AppLocalizationsUz(),
  ));
  // Oqim tugashini kutamiz: oxirgi holat terminal bo'lguncha.
  for (int i = 0; i < 200; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    if (states.isNotEmpty &&
        (states.last is ReturnSuccedState ||
            states.last is ReturnFailedState ||
            states.last is ReturnNoInternetState)) {
      break;
    }
  }
  await sub.cancel();
  await bloc.close();
  return states;
}

void main() {
  setUpAll(() => setUpPosTestEnv('return_bloc_flow', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await Pref.setString(PrefKeys.cashId, 'cash-id');
  });

  test('1. internet yo\'q — hech narsa chaqirilmaydi', () async {
    final d = FakeDeps()..internet = false;
    final states = await run(d);
    expect(states.last, isA<ReturnNoInternetState>());
    expect(d.calls, isEmpty);
  });

  test('2. fiskal OK, server OK — tartib fiskal→save→upload, url vozvratniki',
      () async {
    final d = FakeDeps();
    final states = await run(d);

    expect(d.calls, ['fiscal', 'save', 'upload'],
        reason: 'server FISKALDAN KEYIN chaqirilishi shart');
    expect(states.last, isA<ReturnSuccedState>());
    expect((states.last as ReturnSuccedState).warning, isNull);

    expect(d.uploadedUrl, kRefundUrl,
        reason: 'serverga vozvratning o\'z QR URL\'i ketadi, sotuvniki emas');
    expect(d.uploaded!.url, isNot(kSaleUrl));
    expect(d.uploaded!.receiptSeq, 38002);
    expect(d.uploaded!.fiscalSign, '513103888474');
    expect(d.uploaded!.dateTimeOFD, '20260922094049');
    final Info saved = Info.fromJson(jsonDecode(d.saved!.refundInfo!));
    expect(saved.qrCodeUrl, kRefundUrl,
        reason: 'qayta chop etishda vozvrat QR\'i chiqadi');
    expect(identical(d.saved, d.uploaded), isTrue,
        reason: 'ObjectBox\'dagi va serverga ketgan model bitta obyekt');
    expect(d.savedResponse, isNotNull,
        reason: 'chek fiskal javob bilan chop etiladi (QR bilan)');
  });

  test('3. fiskal OK, server rad etdi — Succeed + ogohlantirish, save bo\'lgan',
      () async {
    final d = FakeDeps()
      ..uploadResult = const RefundUploadResult(RefundUploadStatus.rejected,
          error: 'Order already refunded');
    final states = await run(d);

    expect(d.calls, ['fiscal', 'save', 'upload']);
    final last = states.last;
    expect(last, isA<ReturnSuccedState>(),
        reason: 'fiskal chek chiqqan — "Qayta urinish" BO\'LMASLIGI kerak '
            '(ikkinchi fiskal vozvrat chiqarardi)');
    expect((last as ReturnSuccedState).warning, contains('Order already refunded'));
    expect(states.whereType<ReturnFailedState>(), isEmpty);
  });

  test('4. fiskal OK, server javob bermadi (pending) — Succeed, warning yo\'q',
      () async {
    final d = FakeDeps()
      ..uploadResult = const RefundUploadResult(RefundUploadStatus.pending);
    final states = await run(d);
    expect(d.calls, ['fiscal', 'save', 'upload']);
    expect((states.last as ReturnSuccedState).warning, isNull,
        reason: 'navbatda qoladi, kassirga xato ko\'rsatilmaydi');
  });

  test('5. server yiqilgani ma\'lum — upload umuman chaqirilmaydi', () async {
    final d = FakeDeps()..serverUp = false;
    final states = await run(d);
    expect(d.calls, ['fiscal', 'save']);
    expect(states.last, isA<ReturnSuccedState>());
    expect(d.saved!.uploaded, isFalse, reason: 'navbat uni keyin yuboradi');
    expect(d.saved!.url, kRefundUrl);
  });

  test('6. fiskal XATO — Failed, lokalga yozilmaydi, serverga ketmaydi',
      () async {
    final d = FakeDeps()..fiscal = (_) async => fiscalFail('Modul javob bermadi');
    final states = await run(d);
    expect(d.calls, ['fiscal']);
    expect(states.last, isA<ReturnFailedState>());
    expect((states.last as ReturnFailedState).error, 'Modul javob bermadi');
    expect(d.saved, isNull);
    expect(d.uploaded, isNull);
  });

  test('7. fiskal exception — Failed, save/upload yo\'q', () async {
    final d = FakeDeps()..fiscal = (_) async => throw Exception('timeout');
    final states = await run(d);
    expect(d.calls, ['fiscal']);
    expect(states.last, isA<ReturnFailedState>());
    expect(d.saved, isNull);
  });

  test('8. OFD yoqiq, sotuv OFDda yo\'q (pre-check) — fiskal yo\'q, maydonlar bo\'sh',
      () async {
    final d = FakeDeps();
    final states = await run(d, original: sale(registeredOnOfd: false));
    expect(d.calls, ['save', 'upload']);
    expect(states.last, isA<ReturnSuccedState>());
    expect(d.uploaded!.url, '');
    expect(d.uploaded!.refundInfo, isNull);
    expect(d.uploaded!.terminalId, isNull);
    expect(d.uploaded!.fiscalSign, isNull);
    expect(d.savedResponse, isNull, reason: 'QR\'siz chek');
  });

  test('9. OFD o\'chiq, sotuvda url bor — sotuv URL\'i vozvratga o\'tmaydi',
      () async {
    final d = FakeDeps()..ofd = false;
    final states = await run(d);
    expect(d.calls, ['save', 'upload']);
    expect(states.last, isA<ReturnSuccedState>());
    expect(d.uploaded!.url, '',
        reason: 'ilgari sotuv URL\'i vozvrat yozuvida qolib serverga ketardi');
    expect(d.uploaded!.refundInfo, isNull,
        reason: 'qayta chop etishda sotuv QR\'i chiqmasin');
  });

  test('10. vozvrat modeli: isRefund, CASH, rightList, yangi chek raqami',
      () async {
    final d = FakeDeps();
    await run(d);
    final r = d.saved!;
    expect(r.isRefund, isTrue);
    expect(r.externalId, 'DN-101');
    expect(r.comment, 'Refund made from DN-100');
    expect(r.payment.length, 1);
    expect(r.payment.single.name, 'CASH');
    expect(r.payment.single.payId, 'cash-id');
    expect(r.payment.single.value, 4000);
    expect(r.totalPrice, 4000);
    expect(r.soldItemList.length, 1);
    expect(r.soldItemList.single.productId, 'p1');
  });

  test('holatlar ketma-ketligi: internet → returnig → Succeed', () async {
    final d = FakeDeps();
    final states = await run(d);
    expect(states[0], isA<ReturnLoadingState>());
    expect((states[0] as ReturnLoadingState).message, ReturnMessage.internet);
    expect(states[1], isA<ReturnLoadingState>());
    expect((states[1] as ReturnLoadingState).message, ReturnMessage.returnig);
    expect(states[2], isA<ReturnSuccedState>());
    expect(states.length, 3);
  });
}
