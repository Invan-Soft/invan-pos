// ReceiptEpay — elektron to'lov ID'lari chekning o'zida (2026-10-02).
//
// Tuzatilgan ikki muammo:
//   1. Fiskal ExtraInfo (QRPaymentProvider/QRPaymentID/PhoneNumber) global
//      Pref'dan olinardi → oldingi Click/Payme/Uzum to'lovining ID'si keyingi
//      (hatto naqd) chekka ham ketardi.
//   2. Cheklar ro'yxatidan fiskalga qayta yuborilganda (PreOfd) provayderga
//      chekning emas, xotiradagi oxirgi to'lov ID'si ketardi.
//
// Testlar: sof qoida (capture / encode / targets), fiskal JSON'dagi ExtraInfo,
// nusxalash yo'llari (ReceiptApi4.func, PreOfd), servis holati bilan to'liq
// sotuv stsenariylari (EpayCapture).
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/receipt_epay.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/changes/services/payment/epay_capture.dart';
import 'package:invan2/changes/services/payment/paynet_service.dart';
import 'package:invan2/changes/services/payment/uzum_service.dart';
import 'package:invan2/changes/services/receipt_api_4.dart';
import 'package:invan2/features/checks/features/check_view/bloc/pre_ofd/preofd_bloc.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/epay_fixtures.dart';
import 'support/provider_harness.dart';

const kPaynetId = 'pay-paynet';

ReceiptModelPaymentType4 paynet(double v, {bool qr = false}) =>
    ReceiptModelPaymentType4(
        name: qr ? 'PAYNET QR' : 'PAYNET',
        payId: qr ? '@$kPaynetId' : kPaynetId,
        value: v);

/// To'lov sahifasidagi holat — servislar to'lovdan keyin qanday qoldiradi.
void simulateClickPaid(String id, {String phone = '998901111111'}) {
  ClickService.paymentId = id;
  Pref.setString('epay_Id', id);
  Pref.setInt('epayPay_Id', 64);
  Pref.setString('epay_phone', phone);
}

void simulatePaymePaid(String id, {String phone = '998902222222'}) {
  Pref.setString('p_id', id);
  Pref.setString('epay_Id', id);
  Pref.setInt('epayPay_Id', 141);
  Pref.setString('epay_phone', phone);
}

void simulateUzumPaid(String id, {String phone = '998903333333'}) {
  UzumService.paymentId = id;
  Pref.setString('epay_Id', id);
  Pref.setInt('epayPay_Id', 161);
  Pref.setString('epay_phone', phone);
}

/// ClickService.post `submit_qrcode` javobida Pref'ni qayta yozadi (fiskal
/// tozalashdan KEYIN keladi) — eski xatoning manbai.
void simulateLateClickSubmitResponse() {
  Pref.setString('epay_Id', '');
  Pref.setInt('epayPay_Id', 64);
  Pref.setString('epay_phone', '');
}

ReceiptModel4 sale(Map<Kind, double> amounts,
    {List<ReceiptModelPaymentType4> extra = const []}) {
  final double total =
      amounts.values.fold<double>(0, (a, b) => a + b) +
          extra.fold<double>(0, (a, p) => a + p.value);
  return receiptOf([row(realPrice: total)],
      [...buildPayments(amounts), ...extra]);
}

/// Fiskal modulga ketadigan ExtraInfo.
Map<String, dynamic> extraOf(ReceiptModel4 r) =>
    receiptPart(wireOf(r))['ExtraInfo'] as Map<String, dynamic>;

ReceiptEpay capture(
  ReceiptModel4 r, {
  String? click,
  String? payme,
  String? uzum,
  int? paynetPid,
  int last = 0,
  String phone = '',
}) =>
    ReceiptEpay.capture(
      receipt: r,
      clickId: ids.click,
      paymeId: ids.payme,
      uzumId: ids.uzum,
      paynetId: kPaynetId,
      clickPaymentId: click,
      paymeReceiptId: payme,
      uzumPaymentId: uzum,
      paynetPaymentId: paynetPid,
      lastProvider: last,
      lastPhone: phone,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('receipt_epay', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashId, ids.cash);
    await Pref.setString(PrefKeys.cardId, ids.card);
    await Pref.setString(PrefKeys.cashbackId, ids.cashback);
    await Pref.setString(PrefKeys.clickId, ids.click);
    await Pref.setString(PrefKeys.paymeId, ids.payme);
    await Pref.setString(PrefKeys.uzumId, ids.uzum);
    await Pref.setString(PrefKeys.paynetId, kPaynetId);
  });

  setUp(EpayCapture.reset);

  group('ReceiptEpay.capture — faqat shu chekdagi Pass/Go', () {
    test('naqd chek: manbalarda eski ID bo\'lsa ham bo\'sh', () {
      final e = capture(sale({Kind.cash: 50000}),
          click: 'OLD-C', payme: 'OLD-P', uzum: 'OLD-U', paynetPid: 9,
          last: 64, phone: '998900000000');
      expect(e.isEmpty, isTrue);
      expect(e.encode(), isNull);
    });

    test('har bir to\'lov turi yakka: faqat Pass/Go ID oladi', () {
      for (final k in Kind.values) {
        final e = capture(sale({k: 50000}),
            click: 'C1', payme: 'P1', uzum: 'U1', last: 0);
        final why = k.name;
        expect(e.clickPaymentId, k == Kind.clickPass ? 'C1' : '', reason: why);
        expect(e.paymeReceiptId, k == Kind.paymeGo ? 'P1' : '', reason: why);
        expect(e.uzumPaymentId, k == Kind.uzum ? 'U1' : '', reason: why);
        final int provider = const {
              Kind.clickPass: 64,
              Kind.paymeGo: 141,
              Kind.uzum: 161,
            }[k] ??
            0;
        expect(e.qrPaymentProvider, provider, reason: why);
        expect(e.qrPaymentId, provider == 0 ? '' : isNotEmpty, reason: why);
      }
    });

    test('Click Pass: ExtraInfo 64 + ID + telefon (oxirgi to\'lov Click)', () {
      final e = capture(sale({Kind.clickPass: 50000}),
          click: '123456', last: 64, phone: '998901234567');
      expect(e.qrPaymentProvider, 64);
      expect(e.qrPaymentId, '123456');
      expect(e.phoneNumber, '998901234567');
    });

    test('Click QR: eski ClickService ID\'si bo\'lsa ham olinmaydi', () {
      final e = capture(sale({Kind.clickQr: 50000}), click: 'OLD', last: 64);
      expect(e.isEmpty, isTrue);
    });

    test('Payme Go + Click Pass: ExtraInfo oxirgi to\'langan provayder, ikkala ID saqlanadi',
        () {
      final r = sale({Kind.clickPass: 20000, Kind.paymeGo: 30000});
      final e = capture(r, click: 'C', payme: 'P', last: 141, phone: '99890');
      expect(e.qrPaymentProvider, 141);
      expect(e.qrPaymentId, 'P');
      expect(e.phoneNumber, '99890');
      expect(e.clickPaymentId, 'C');
      expect(e.paymeReceiptId, 'P');
    });

    test('oxirgi provayder noma\'lum: Click → Payme → Uzum tartibi, telefon yo\'q',
        () {
      final r = sale({Kind.paymeGo: 20000, Kind.uzum: 30000, Kind.clickPass: 1});
      final e = capture(r, click: 'C', payme: 'P', uzum: 'U', last: 0,
          phone: '99890');
      expect(e.qrPaymentProvider, 64);
      expect(e.phoneNumber, '');
    });

    test('Pref\'dagi oxirgi provayder chekda yo\'q: uning telefoni oqib ketmaydi',
        () {
      final e = capture(sale({Kind.clickPass: 50000}),
          click: 'C', last: 141, phone: 'PAYME-PHONE');
      expect(e.qrPaymentProvider, 64);
      expect(e.phoneNumber, '');
    });

    test('Pass bor, lekin ID yo\'q (to\'lov ID\'si olinmagan): ExtraInfo bo\'sh',
        () {
      for (final id in [null, '', '   ']) {
        final e = capture(sale({Kind.clickPass: 50000}), click: id, last: 64);
        expect(e.qrPaymentProvider, 0, reason: '"$id"');
        expect(e.clickPaymentId, '', reason: '"$id"');
      }
    });

    test('ID atrofidagi bo\'shliq olib tashlanadi', () {
      final e = capture(sale({Kind.clickPass: 50000}), click: ' 77 ');
      expect(e.clickPaymentId, '77');
    });

    test('Paynet (Pass ham, QR ham): ID chekda Paynet bo\'lsa saqlanadi', () {
      for (final qr in [false, true]) {
        final r = sale({}, extra: [paynet(50000, qr: qr)]);
        expect(capture(r, paynetPid: 555).paynetPaymentId, 555, reason: 'qr=$qr');
        expect(capture(r, paynetPid: null).paynetPaymentId, isNull);
        expect(capture(r, paynetPid: 0).paynetPaymentId, isNull);
      }
      expect(capture(sale({Kind.cash: 1}), paynetPid: 555).paynetPaymentId,
          isNull,
          reason: 'chekda Paynet yo\'q — eski ID olinmaydi');
    });

    test('vozvrat: hech narsa olinmaydi', () {
      final r = receiptOf([row(realPrice: 50000)],
          buildPayments({Kind.clickPass: 50000}),
          isRefund: true);
      expect(capture(r, click: 'C', last: 64).isEmpty, isTrue);
    });
  });

  group('encode / decode', () {
    test('to\'liq qaytish (round-trip)', () {
      const e = ReceiptEpay(
        qrPaymentProvider: 141,
        qrPaymentId: 'P',
        phoneNumber: '998',
        clickPaymentId: 'C',
        paymeReceiptId: 'P',
        uzumPaymentId: 'U',
        paynetPaymentId: 42,
      );
      final d = ReceiptEpay.decode(e.encode());
      expect(d.toJson(), e.toJson());
    });

    test('null / bo\'sh / buzilgan / boshqa tur → bo\'sh, xato tashlamaydi', () {
      for (final raw in [null, '', '{', '[]', '"x"', 'null', '{"qrPaymentProvider":"abc"}']) {
        expect(() => ReceiptEpay.decode(raw), returnsNormally, reason: '$raw');
      }
      expect(ReceiptEpay.decode(null).isEmpty, isTrue);
      expect(ReceiptEpay.decode('{').isEmpty, isTrue);
      expect(ReceiptEpay.decode('[]').isEmpty, isTrue);
    });

    test('kalitlari yetishmagan JSON: mavjudi o\'qiladi', () {
      final d = ReceiptEpay.decode('{"clickPaymentId":"C"}');
      expect(d.clickPaymentId, 'C');
      expect(d.qrPaymentProvider, 0);
      expect(d.paynetPaymentId, isNull);
    });
  });

  group('targets — fiskal URL qaysi provayderga qaytariladi', () {
    const full = ReceiptEpay(
        clickPaymentId: 'C', paymeReceiptId: 'P', uzumPaymentId: 'U',
        paynetPaymentId: 1);

    test('bayroq + ID → yuboriladi', () {
      expect(
          full.targets({
            'receivedClick': true,
            'receivedPayme': true,
            'receivedUzum': true,
            'receivedPaynet': true,
          }),
          EpayTarget.values.toSet());
    });

    test('bayroq bor, ID yo\'q (eski chek) → yuborilmaydi', () {
      expect(
          ReceiptEpay.empty.targets({
            'receivedClick': true,
            'receivedPayme': true,
            'receivedUzum': true,
            'receivedPaynet': true,
          }),
          isEmpty);
    });

    test('ID bor, bayroq yo\'q (QR yoki naqd) → yuborilmaydi', () {
      expect(
          full.targets({
            'receivedClick': false,
            'receivedPayme': false,
            'receivedUzum': false,
            'receivedPaynet': false,
          }),
          isEmpty);
      expect(full.targets(<String, dynamic>{}), isEmpty);
    });

    test('haqiqiy saleOnOFD params bilan: Click Pass + Payme QR → faqat Click', () {
      final r = sale({Kind.clickPass: 20000, Kind.paymeQr: 30000});
      r.epayJson = capture(r, click: 'C', payme: 'STALE').encode();
      final params = paramsOf(r);
      expect(ReceiptEpay.decode(r.epayJson).targets(params), {EpayTarget.click});
    });
  });

  group('Fiskal JSON ExtraInfo — chekdan, Pref\'dan emas', () {
    test('naqd chek, Pref\'da oldingi Click qoldig\'i: ExtraInfo bo\'sh', () {
      simulateClickPaid('OLD-111');
      simulateLateClickSubmitResponse();
      Pref.setString('epay_Id', 'OLD-111');
      final x = extraOf(sale({Kind.cash: 50000}));
      expect(x['QRPaymentProvider'], 0);
      expect(x['QRPaymentID'], '');
      expect(x['PhoneNumber'], '');
    });

    test('Click Pass chek: ExtraInfo chekdagi ID, Pref\'da boshqa to\'lov bo\'lsa ham',
        () {
      final r = sale({Kind.clickPass: 50000});
      r.epayJson = capture(r, click: 'C-1', last: 64, phone: '998901').encode();
      simulatePaymePaid('OTHER'); // keyingi mijozning to'lovi
      final x = extraOf(r);
      expect(x['QRPaymentProvider'], 64);
      expect(x['QRPaymentID'], 'C-1');
      expect(x['PhoneNumber'], '998901');
    });

    test('har bir Pass/Go turi: provayder kodi to\'g\'ri', () {
      const codes = {Kind.clickPass: 64, Kind.paymeGo: 141, Kind.uzum: 161};
      for (final k in codes.keys) {
        final int code = codes[k]!;
        final r = sale({k: 50000});
        r.epayJson =
            capture(r, click: 'C', payme: 'P', uzum: 'U', last: code).encode();
        expect(extraOf(r)['QRPaymentProvider'], code, reason: k.name);
      }
    });

    test('QR chek: ExtraInfo bo\'sh, pul Other\'da (o\'zgarishsiz)', () {
      for (final k in [Kind.clickQr, Kind.paymeQr, Kind.uzumQr]) {
        final r = sale({k: 50000});
        r.epayJson = capture(r, click: 'X', payme: 'X', uzum: 'X').encode();
        expect(r.epayJson, isNull, reason: k.name);
        expect(extraOf(r)['QRPaymentProvider'], 0, reason: k.name);
        expect(sumOf(wireOf(r), 'Other'), 5000000, reason: k.name);
      }
    });

    test('vozvrat: chekda epayJson bo\'lsa ham ExtraInfo bo\'sh', () {
      final r = receiptOf([row(realPrice: 50000)],
          [ReceiptModelPaymentType4(name: 'CASH', payId: ids.cash, value: 50000)],
          isRefund: true);
      r.epayJson = const ReceiptEpay(
              qrPaymentProvider: 64, qrPaymentId: 'C', clickPaymentId: 'C')
          .encode();
      final x = extraOf(r);
      expect(x['QRPaymentProvider'], 0);
      expect(x['QRPaymentID'], '');
    });

    test('ExtraInfo qo\'shilishi pul maydonlarini o\'zgartirmaydi', () {
      final r = sale({Kind.clickPass: 30000, Kind.cash: 20000});
      final before = jsonEncode(receiptPart(wireOf(r))['Items']);
      r.epayJson = capture(r, click: 'C', last: 64, phone: '9').encode();
      final w = wireOf(r);
      expect(jsonEncode(receiptPart(w)['Items']), before);
      expect(receiptPart(w)['ReceivedCard'], 3000000);
      expect(receiptPart(w)['ReceivedCash'], 2000000);
    });
  });

  group('Nusxalash yo\'llari epayJson\'ni yo\'qotmaydi', () {
    test('ReceiptApi4.func (saleOnOFD ishlatadi)', () {
      final r = sale({Kind.clickPass: 50000});
      r.epayJson = capture(r, click: 'C').encode();
      expect(ReceiptApi4.func(r).epayJson, r.epayJson);
    });

    test('PreOfdBloc.receiptForResend', () {
      final r = sale({Kind.paymeGo: 50000});
      r.epayJson = capture(r, payme: 'P').encode();
      final copy = PreOfdBloc.receiptForResend(r, '');
      expect(copy.epayJson, r.epayJson);
      expect(copy.payment.map((p) => p.payId), r.payment.map((p) => p.payId));
    });

    test('eski chek (epayJson null) nusxada ham null', () {
      final r = sale({Kind.clickPass: 50000});
      expect(PreOfdBloc.receiptForResend(r, '').epayJson, isNull);
      expect(ReceiptApi4.func(r).epayJson, isNull);
    });
  });

  group('Click payload — payment_id chekdan', () {
    test('fromReceipt4ToClick ClickService.paymentId ni emas, berilganini oladi',
        () {
      ClickService.paymentId = '999999';
      final r = sale({Kind.clickPass: 50000});
      final data = ReceiptSingleton4.fromReceipt4ToClick(
          receipt: ReceiptSingleton4.saleOnOFD(r), clickPaymentId: '123');
      expect(data['payment_id'], 123);
    });
  });

  group('EpayCapture — servis holati bilan to\'liq stsenariylar', () {
    test('reset: barcha global manbalar tozalanadi', () {
      simulateClickPaid('C');
      simulatePaymePaid('P');
      simulateUzumPaid('U');
      PaynetService.paymentId = 5;
      EpayCapture.reset();
      expect(ClickService.paymentId, isNull);
      expect(UzumService.paymentId, isNull);
      expect(PaynetService.paymentId, isNull);
      expect(Pref.getString('p_id', 'x'), '');
      expect(Pref.getInt('epayPay_Id', -1), 0);
      expect(Pref.getString('epay_Id', 'x'), '');
      expect(Pref.getString('epay_phone', 'x'), '');
    });

    test('1-muammo: Click Pass sotuvi fiskalda yiqildi → keyingi naqd chekda ExtraInfo bo\'sh',
        () {
      // Sotuv 1: Click Pass.
      simulateClickPaid('111');
      final r1 = sale({Kind.clickPass: 50000});
      r1.epayJson = EpayCapture.forReceipt(r1);
      // Fiskal yiqildi — LocalService Pref'ni tozalamadi; Click javobi ham keldi.
      simulateLateClickSubmitResponse();
      // Sotuv 2: yangi to'lov sahifasi, naqd.
      EpayCapture.reset();
      final r2 = sale({Kind.cash: 30000});
      r2.epayJson = EpayCapture.forReceipt(r2);
      expect(r2.epayJson, isNull);
      expect(extraOf(r2)['QRPaymentProvider'], 0);
      expect(extraOf(r2)['QRPaymentID'], '');
      // Sotuv 1 o'z ma'lumotini saqlab qolgan.
      expect(extraOf(r1)['QRPaymentProvider'], 64);
      expect(extraOf(r1)['QRPaymentID'], '111');
    });

    test('reset\'dan keyin ham kech kelgan Click javobi: naqd chekka 64 tushmaydi',
        () {
      EpayCapture.reset();
      simulateLateClickSubmitResponse(); // epayPay_Id = 64
      final r = sale({Kind.cash: 30000});
      r.epayJson = EpayCapture.forReceipt(r);
      expect(extraOf(r)['QRPaymentProvider'], 0);
    });

    test('Payme Go to\'lovidan keyin kech Click javobi: ExtraInfo baribir Payme',
        () {
      EpayCapture.reset();
      simulatePaymePaid('PM-2');
      simulateLateClickSubmitResponse(); // epayPay_Id 141 → 64 bo'lib qoldi
      final r = sale({Kind.paymeGo: 40000});
      r.epayJson = EpayCapture.forReceipt(r);
      final x = extraOf(r);
      expect(x['QRPaymentProvider'], 141);
      expect(x['QRPaymentID'], 'PM-2');
      expect(x['PhoneNumber'], '', reason: 'telefon kimniki ekani noma\'lum');
    });

    test('2-muammo: PreOfd qayta yuborish — provayderga chekning o\'z ID\'si', () {
      // Sotuv 1: Click Pass, fiskalsiz saqlandi.
      simulateClickPaid('111');
      final r1 = sale({Kind.clickPass: 50000});
      r1.epayJson = EpayCapture.forReceipt(r1);
      // Sotuv 2: boshqa mijoz, Click Pass 222 va Payme Go.
      EpayCapture.reset();
      simulateClickPaid('222');
      simulatePaymePaid('PM-9');
      final r2 = sale({Kind.clickPass: 10000, Kind.paymeGo: 10000});
      r2.epayJson = EpayCapture.forReceipt(r2);

      // Keyinroq cheklar ro'yxatidan sotuv 1 fiskalga qayta yuboriladi.
      final resend = PreOfdBloc.receiptForResend(r1, '');
      final body = ReceiptSingleton4.saleOnOFD(resend);
      final epay = ReceiptEpay.decode(resend.epayJson);
      expect(epay.targets(body['params']), {EpayTarget.click});
      expect(epay.clickPaymentId, '111');
      expect(
          ReceiptSingleton4.fromReceipt4ToClick(
              receipt: body, clickPaymentId: epay.clickPaymentId)['payment_id'],
          111);
      expect(extraOf(resend)['QRPaymentID'], '111');

      // Sotuv 2 o'z ID'lari bilan.
      final e2 = ReceiptEpay.decode(r2.epayJson);
      expect(e2.clickPaymentId, '222');
      expect(e2.paymeReceiptId, 'PM-9');
      expect(e2.targets(paramsOf(r2)), {EpayTarget.click, EpayTarget.payme});
    });

    test('dastur qayta ochilgandan keyin (statik ID\'lar yo\'q) qayta yuborish', () {
      simulateClickPaid('111');
      final r1 = sale({Kind.clickPass: 50000});
      r1.epayJson = EpayCapture.forReceipt(r1);
      // Qayta ishga tushish: xotira tozalandi.
      ClickService.paymentId = null;
      final resend = PreOfdBloc.receiptForResend(r1, '');
      final epay = ReceiptEpay.decode(resend.epayJson);
      expect(epay.targets(paramsOf(resend)), {EpayTarget.click});
      expect(epay.clickPaymentId, '111');
    });

    test('yangilanishdan oldingi chek (epayJson yo\'q): provayderga yuborilmaydi, ExtraInfo bo\'sh',
        () {
      ClickService.paymentId = 'SOMEONE-ELSE';
      Pref.setInt('epayPay_Id', 64);
      Pref.setString('epay_Id', 'SOMEONE-ELSE');
      final old = sale({Kind.clickPass: 50000}); // epayJson null
      final resend = PreOfdBloc.receiptForResend(old, '');
      expect(ReceiptEpay.decode(resend.epayJson).targets(paramsOf(resend)),
          isEmpty);
      expect(extraOf(resend)['QRPaymentID'], '');
      // Pul maydonlari o'zgarmagan: Pass → ReceivedCard.
      expect(receiptPart(wireOf(resend))['ReceivedCard'], 5000000);
    });

    test('Uzum Pass va Paynet: ID chekdan', () {
      simulateUzumPaid('UZ-1');
      PaynetService.paymentId = 77;
      final r = sale({Kind.uzum: 20000}, extra: [paynet(30000)]);
      r.epayJson = EpayCapture.forReceipt(r);
      final e = ReceiptEpay.decode(r.epayJson);
      expect(e.uzumPaymentId, 'UZ-1');
      expect(e.paynetPaymentId, 77);
      expect(e.qrPaymentProvider, 161);
      final params = paramsOf(r);
      expect(params['receivedPaynet'], true);
      expect(e.targets(params), {EpayTarget.uzum, EpayTarget.paynet});
    });
  });
}
