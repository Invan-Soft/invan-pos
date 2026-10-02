// Click Pass / Payme Go / QR / Uzum — fiskal modulga ketadigan JSON matritsasi.
//
// f007377 (Click Pass / Payme Go → ReceivedCard, QQS to'liq; QR → Other;
// receivedClick/Payme/Uzum faqat Pass/Go) ni keng qamrovda tekshiradi.
//
// receipt_vat_test.dart dan farqi: to'lovlar QO'LDA yasalmaydi — to'lov
// ekranidagi xarita (`Map<String, Payment>`, QR `type: 1` → '@id' kalit)
// haqiqiy `ReceiptPayments.build` dan o'tadi, so'ng `saleOnOFD` →
// `RequestSaleModel` → `FiscalReceiptModel.toJson` (modulga ketadigan JSON).
//
// Har bir holatda modul invariantlari:
//   - ReceivedCash / ReceivedCard / ΣOther — to'lov turiga qarab kutilgan;
//   - Σ(Price − Discount) == ReceivedCash + ReceivedCard + ΣOther (§10.2.1);
//   - har qatorda 0 ≤ Other, Other + Discount ≤ Price;
//   - VAT == (Price − Discount − Other) × p / (100 + p), 0% da 0;
//   - receivedClick / receivedPayme / receivedUzum faqat Pass/Go bo'lsa.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'dart:convert';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/epay_fixtures.dart';
import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('epay_fiscal_matrix', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashId, ids.cash);
    await Pref.setString(PrefKeys.cardId, ids.card);
    await Pref.setString(PrefKeys.cashbackId, ids.cashback);
    await Pref.setString(PrefKeys.clickId, ids.click);
    await Pref.setString(PrefKeys.paymeId, ids.payme);
    await Pref.setString(PrefKeys.uzumId, ids.uzum);
  });

  group('ReceiptPayments.build — to\'lov ekranidan chekka nomlar', () {
    test('Pass/Go — \'@\' siz, QR — \'@id\' va nomda QR', () {
      final ps = buildPayments({
        for (final k in Kind.values) k: 1000,
      });
      final byKey = {for (final p in ps) p.payId: p.name};
      expect(byKey['pay-click'], 'CLICK PASS');
      expect(byKey['@pay-click'], 'CLICK QR');
      expect(byKey['pay-payme'], 'PAYME GO');
      expect(byKey['@pay-payme'], 'PAYME QR');
      expect(byKey['pay-uzum'], 'UZUM');
      expect(byKey['@pay-uzum'], 'UZUM QR');
      expect(byKey['pay-card'], 'UZCARD');
      expect(byKey['@pay-card'], 'HUMO');
      expect(byKey['pay-cash'], 'CASH');
      expect(byKey['pay-cashback'], 'CASHBACK');
      expect(byKey['pay-debt'], 'DEBT');
    });
  });

  group('Yakka to\'lov turi × savat — fiskal JSON', () {
    for (final cart in [...carts, scaleCart]) {
      for (final kind in Kind.values) {
        test('${kind.name} | ${cart.name}', () {
          final rows = cart.rows();
          final double total = cartTotal(rows);
          final amounts = {kind: total};
          final r = receiptOf(rows, buildPayments(amounts));
          final w = wireOf(r);
          final why = '${kind.name} / ${cart.name}';

          expectModuleInvariants(w, why);
          // Tarozida to'lov so'mga yaxlitlanadi — summa emas, bucket muhim.
          final paid = {kind: r.payment.single.value};
          if (cart != scaleCart) {
            expectBuckets(w, paid, why, rows: rows.length);
          } else {
            final rp = receiptPart(w);
            switch (kind.bucket) {
              case Bucket.cash:
                expect(rp['ReceivedCard'], 0, reason: why);
                expect(sumOf(w, 'Other'), 0, reason: why);
                break;
              case Bucket.card:
                expect(rp['ReceivedCash'], 0, reason: why);
                expect(sumOf(w, 'Other'), 0, reason: why);
                break;
              case Bucket.other:
                expect(rp['ReceivedCash'], 0, reason: why);
                expect(rp['ReceivedCard'], 0, reason: why);
                break;
            }
          }
          expectFlags(paramsOf(r), {kind}, why);

          // Karta guruhi (Pass/Go ham) — QQS to'liq; Other guruhi — 0.
          final num vat = sumOf(w, 'VAT');
          if (kind.bucket == Bucket.other) {
            expect(vat, 0, reason: '$why: Other → VAT 0');
          } else if (rows.any((x) => x.vatPercent > 0)) {
            expect(vat, greaterThan(0), reason: '$why: VAT to\'liq');
          }
        });
      }
    }
  });

  group('Pass/Go oldin vs hozir — aniq raqamlar', () {
    test('Click Pass 112 000 (12%): ReceivedCard, Other 0, VAT 12 000 so\'m', () {
      final rows = [row(realPrice: 112000)];
      final w = wireOf(receiptOf(rows, buildPayments({Kind.clickPass: 112000})));
      final it = itemsOf(w).single;
      expect(receiptPart(w)['ReceivedCash'], 0);
      expect(receiptPart(w)['ReceivedCard'], 11200000);
      expect(it['Price'], 11200000);
      expect(it['Other'], 0);
      expect(it['VAT'], closeTo(1200000, 1));
    });

    test('Payme Go 112 000: xuddi shunday', () {
      final w = wireOf(receiptOf(
          [row(realPrice: 112000)], buildPayments({Kind.paymeGo: 112000})));
      expect(receiptPart(w)['ReceivedCard'], 11200000);
      expect(itemsOf(w).single['Other'], 0);
      expect(itemsOf(w).single['VAT'], closeTo(1200000, 1));
    });

    test('Click QR / Payme QR 112 000: o\'zgarishsiz — Other, VAT 0', () {
      for (final k in [Kind.clickQr, Kind.paymeQr]) {
        final w = wireOf(
            receiptOf([row(realPrice: 112000)], buildPayments({k: 112000})));
        expect(receiptPart(w)['ReceivedCard'], 0, reason: k.name);
        expect(receiptPart(w)['ReceivedCash'], 0, reason: k.name);
        expect(itemsOf(w).single['Other'], 11200000, reason: k.name);
        expect(itemsOf(w).single['VAT'], 0, reason: k.name);
      }
    });
  });

  group('Aralash: har juft to\'lov turi (1/3 + 2/3)', () {
    final kinds = Kind.values;
    for (var i = 0; i < kinds.length; i++) {
      for (var j = i + 1; j < kinds.length; j++) {
        final a = kinds[i], b = kinds[j];
        test('${a.name} + ${b.name}', () {
          for (final cart in carts) {
            final rows = cart.rows();
            final double total = cartTotal(rows);
            final double first = (total / 3).floorToDouble();
            final amounts = {a: first, b: total - first};
            final r = receiptOf(rows, buildPayments(amounts));
            final w = wireOf(r);
            final why = '${a.name}+${b.name} / ${cart.name}';
            expectModuleInvariants(w, why);
            expectBuckets(w, amounts, why, rows: rows.length);
            expectFlags(paramsOf(r), {a, b}, why);
          }
        });
      }
    }
  });

  group('Murakkab holatlar', () {
    test('hamma 11 tur bitta chekda', () {
      final rows = [
        row(realPrice: 110000, name: 'X'),
        row(realPrice: 55000, vatPercent: 0, name: 'Y'),
      ];
      final amounts = {for (final k in Kind.values) k: 15000.0};
      final r = receiptOf(rows, buildPayments(amounts));
      final w = wireOf(r);
      expectModuleInvariants(w, 'hammasi');
      expectBuckets(w, amounts, 'hammasi', rows: 2);
      expectFlags(paramsOf(r), Kind.values.toSet(), 'hammasi');
    });

    test('bir provayderning Pass + QR bitta chekda: Pass → karta, QR → Other, bayroq true',
        () {
      final rows = [row(realPrice: 100000)];
      for (final pair in [
        [Kind.clickPass, Kind.clickQr],
        [Kind.paymeGo, Kind.paymeQr],
        [Kind.uzum, Kind.uzumQr],
      ]) {
        final amounts = {pair[0]: 60000.0, pair[1]: 40000.0};
        final r = receiptOf(rows, buildPayments(amounts));
        final w = wireOf(r);
        expectModuleInvariants(w, pair.toString());
        expectBuckets(w, amounts, pair.toString());
        expectFlags(paramsOf(r), pair.toSet(), pair.toString());
      }
    });

    test('naqd qaytim (sdacha) + Click Pass: naqd qatoridan qaytim ayriladi', () {
      final rows = [row(realPrice: 50000)];
      // Mijoz 20 000 Click Pass + 40 000 naqd berdi, qaytim 10 000.
      final payments = buildPayments(
          {Kind.clickPass: 20000, Kind.cash: 40000},
          sdacha: 10000);
      final r = receiptOf(rows, payments);
      final w = wireOf(r);
      expectModuleInvariants(w, 'sdacha');
      expect(receiptPart(w)['ReceivedCash'], 3000000);
      expect(receiptPart(w)['ReceivedCard'], 2000000);
      expect(sumOf(w, 'Other'), 0);
      expect(paramsOf(r)['receivedClick'], true);
    });

    test('cashback + Click QR + Payme Go: Other = cashback + QR, karta = Go', () {
      final rows = [
        row(realPrice: 30000, name: 'A'),
        row(realPrice: 70000, name: 'B'),
      ];
      final amounts = {
        Kind.cashback: 10000.0,
        Kind.clickQr: 25000.0,
        Kind.paymeGo: 65000.0,
      };
      final r = receiptOf(rows, buildPayments(amounts));
      final w = wireOf(r);
      expectModuleInvariants(w, 'cb+qr+go');
      expectBuckets(w, amounts, 'cb+qr+go', rows: 2);
      expectFlags(paramsOf(r), amounts.keys.toSet(), 'cb+qr+go');
    });

    test('serverdan qaytgan chek: QR\'da \'@\' yo\'q, nomi QR → baribir Other',
        () {
      final rows = [row(realPrice: 50000)];
      final r = receiptOf(rows, [
        ReceiptModelPaymentType4(name: 'CLICK QR', payId: 'pay-click', value: 20000),
        ReceiptModelPaymentType4(name: 'PAYME QR', payId: 'pay-payme', value: 30000),
      ]);
      final w = wireOf(r);
      expectModuleInvariants(w, 'server QR');
      expect(receiptPart(w)['ReceivedCard'], 0);
      expect(sumOf(w, 'Other'), 5000000);
      expectFlags(paramsOf(r), const {}, 'server QR');
    });

    test('nomi kichik harfda (eski chek): click pass → karta', () {
      final r = receiptOf([row(realPrice: 50000)], [
        ReceiptModelPaymentType4(name: 'click pass', payId: 'pay-click', value: 50000),
      ]);
      final w = wireOf(r);
      expect(receiptPart(w)['ReceivedCard'], 5000000);
      expect(paramsOf(r)['receivedClick'], true);
    });
  });

  group('Vozvrat — to\'lov turidan qat\'iy nazar naqd', () {
    test('Click Pass / Payme Go / QR chekining vozvrati (return_bloc: faqat CASH)',
        () {
      for (final k in [Kind.clickPass, Kind.paymeGo, Kind.clickQr, Kind.paymeQr]) {
        final rows = [row(realPrice: 50000)];
        // return_bloc.dart: vozvrat cheki to'lovi har doim bitta CASH.
        final refund = receiptOf(
          rows,
          [ReceiptModelPaymentType4(name: 'CASH', payId: ids.cash, value: 50000)],
          isRefund: true,
        );
        final w = wireOf(refund);
        expectModuleInvariants(w, 'vozvrat ${k.name}');
        expect(receiptPart(w)['ReceivedCash'], 5000000, reason: k.name);
        expect(receiptPart(w)['ReceivedCard'], 0, reason: k.name);
        expect(sumOf(w, 'Other'), 0, reason: k.name);
        expectFlags(paramsOf(refund), const {}, 'vozvrat ${k.name}');
      }
    });

    test('vozvrat chekida asl to\'lovlar qolgan bo\'lsa ham — hammasi ReceivedCash',
        () {
      final rows = [row(realPrice: 50000)];
      final refund = receiptOf(
        rows,
        buildPayments({Kind.clickPass: 20000, Kind.paymeQr: 30000}),
        isRefund: true,
      );
      final w = wireOf(refund);
      expectModuleInvariants(w, 'vozvrat aralash');
      expect(receiptPart(w)['ReceivedCash'], 5000000);
      expect(receiptPart(w)['ReceivedCard'], 0);
      expect(sumOf(w, 'Other'), 0);
    });
  });

  group('Barqarorlik', () {
    test('saleOnOFD qayta chaqirilsa (PreOfd qayta urinish) natija bir xil', () {
      final rows = [
        row(realPrice: 37500, value: 2, name: 'A'),
        row(realPrice: 9990, name: 'C'),
      ];
      final total = cartTotal(rows);
      final r = receiptOf(rows,
          buildPayments({Kind.clickPass: 30000, Kind.clickQr: total - 30000}));
      final before = jsonEncode(r.payment.map((p) => [p.name, p.payId, p.value]).toList());
      final first = jsonEncode(wireOf(r));
      final second = jsonEncode(wireOf(r));
      expect(second, first);
      expect(
          jsonEncode(r.payment.map((p) => [p.name, p.payId, p.value]).toList()),
          before,
          reason: 'saleOnOFD chek to\'lovlarini o\'zgartirmasligi kerak');
    });

    test('provayder ID sozlanmagan (clickId bo\'sh): Pass bayrog\'i false', () async {
      final saved = Pref.getString(PrefKeys.clickId, '');
      await Pref.setString(PrefKeys.clickId, '');
      try {
        final r = receiptOf(
            [row(realPrice: 50000)], buildPayments({Kind.clickPass: 50000}));
        expect(paramsOf(r)['receivedClick'], false);
        expectModuleInvariants(wireOf(r), 'clickId bo\'sh');
      } finally {
        await Pref.setString(PrefKeys.clickId, saved);
      }
    });
  });
}
