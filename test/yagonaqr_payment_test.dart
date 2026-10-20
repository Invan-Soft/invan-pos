// YagonaQr — admin paneldagi alohida to'lov turi (2026-10-20, Odoo forkidan).
//
// Talab:
//   - alohida tugma, kassir belgilaydi (terminal integratsiyasi yo'q);
//   - serverga YagonaQr to'lov turining O'Z id'si bilan (`payment_type_id`);
//   - soliqqa KARTA: `ReceivedCard`, `ExtraInfo.CardType` 2, QQS to'liq;
//   - aralash to'lov (naqd + karta + YagonaQr va h.k.) to'g'ri taqsimlanadi;
//   - chekdagi nom 'YAGONAQR'.
//
// Fiskal qismi modulga ketadigan haqiqiy JSON'ni tekshiradi: to'lov ekrani
// xaritasi → `ReceiptPayments.build` → `saleOnOFD` → `FiscalReceiptModel`
// (`support/epay_fixtures.dart`). Har holatda §10.2.1 va QQS bazasi
// invariantlari (`expectModuleInvariants`).
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/domain/payment/yagona_qr.dart';
import 'package:invan2/changes/domain/receipt/receipt_payments.dart';
import 'package:invan2/changes/domain/receipt/receipt_vat.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/services/web_socket_service/product/products_ws_service.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/printing/api/printing_api_helper.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/epay_fixtures.dart';
import 'support/provider_harness.dart';

const kYagonaId = 'pay-yagona';

/// Fixture'dagi `ids` + YagonaQr.
const yIds = PaymentIds(
  cash: 'pay-cash',
  card: 'pay-card',
  cashback: 'pay-cashback',
  debt: 'pay-debt',
  payme: 'pay-payme',
  click: 'pay-click',
  uzum: 'pay-uzum',
  yagonaQr: kYagonaId,
);

/// Admin yozgan nom (normallashtirishdan oldin).
const kAdminName = 'YagonaQr';

Payment pay(String id, String name, {int? type}) =>
    Payment(id: id, name: name, title: name, enable: true, type: type);

Payment get yagona => pay(kYagonaId, kAdminName);

/// To'lov ekrani xaritasi (Kind'lar + YagonaQr) → haqiqiy `ReceiptPayments.build`.
List<ReceiptModelPaymentType4> paysWithYagona(
  Map<Kind, double> amounts, {
  double yagona = 0,
  double sdacha = 0,
}) {
  final map = <String, Payment>{
    for (final e in amounts.entries)
      e.key.key: Payment(
        name: e.key.name,
        id: e.key.key.replaceFirst('@', ''),
        type: e.key.type,
        value: e.value,
      ),
    if (yagona > 0)
      kYagonaId: Payment(
          name: kAdminName, id: kYagonaId, type: null, value: yagona),
  };
  return ReceiptPayments.build(map,
      ids: yIds, sdacha: sdacha, zdachaToCashBack: 0);
}

/// YagonaQr ishtirokidagi chek (provider'dagidek cardType 2).
ReceiptModel4 saleWithYagona(
  List<ReceiptModelSoldItem4> rows,
  Map<Kind, double> amounts, {
  required double yagona,
  double sdacha = 0,
}) =>
    receiptOf(rows, paysWithYagona(amounts, yagona: yagona, sdacha: sdacha))
      ..cardType = 2;

/// Kutilgan fiskal maydonlar: YagonaQr — karta.
void expectBucketsWithYagona(
  Map<String, dynamic> w,
  Map<Kind, double> amounts,
  double yagona,
  String why, {
  int rows = 1,
}) {
  double cash = 0, card = yagona, other = 0;
  amounts.forEach((k, v) {
    switch (k.bucket) {
      case Bucket.cash:
        cash += v;
        break;
      case Bucket.card:
        card += v;
        break;
      case Bucket.other:
        other += v;
        break;
    }
  });
  final rp = receiptPart(w);
  expect(rp['ReceivedCash'], (cash * 100).round(), reason: '$why: ReceivedCash');
  expect(rp['ReceivedCard'], (card * 100).round(), reason: '$why: ReceivedCard');
  expect(sumOf(w, 'Other'), closeTo(other * 100, rows * 100.0),
      reason: '$why: ΣOther');
  if (other == 0) expect(sumOf(w, 'Other'), 0, reason: '$why: Other 0');
}

Map<String, dynamic> extraOf(Map<String, dynamic> w) =>
    receiptPart(w)['ExtraInfo'] as Map<String, dynamic>;

OrderingProvider4 paymentPage({double total = 100000}) {
  final p = freshProvider();
  p.initPaymentPageValues(
    sixClientModel4: SixClientModel4(
      clientNumber: 1,
      lastAddedIndex: -1,
      orderedProducts: [],
      discountAmountFromNewClient: 0,
    ),
    totalPrice: total,
    discountAmount: 0,
  );
  return p;
}

Map<String, ReceiptModelPaymentType4> chekOf(OrderingProvider4 p) =>
    {for (final e in p.paymentsMapAsList) e.payId: e};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('yagonaqr_payment_test', withEmployee: false);
    // setOrgPrefs: Pref'ga OrganizationModel, `other_payments` qutisiga Payment.
    final org = OrganizationModelAdapter(), payment = PaymentAdapter();
    if (!Hive.isAdapterRegistered(org.typeId)) {
      Hive.registerAdapter<OrganizationModel>(org);
    }
    if (!Hive.isAdapterRegistered(payment.typeId)) {
      Hive.registerAdapter<Payment>(payment);
    }
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashId, ids.cash);
    await Pref.setString(PrefKeys.cardId, ids.card);
    await Pref.setString(PrefKeys.cashbackId, ids.cashback);
    await Pref.setString(PrefKeys.debtId, ids.debt);
    await Pref.setString(PrefKeys.clickId, ids.click);
    await Pref.setString(PrefKeys.paymeId, ids.payme);
    await Pref.setString(PrefKeys.uzumId, ids.uzum);
    await Pref.setString(PrefKeys.yagonaQrId, kYagonaId);
  });
  tearDownAll(tearDownPosTestEnv);

  // ───────────────────────────────────────────────────────────────────────
  group('YagonaQr.isName — admin nomini tanish', () {
    for (final n in [
      'YagonaQr',
      'YAGONAQR',
      'Yagona QR',
      'yagona_qr',
      'Yagona-QR',
      'YAGONA_QR',
      '  yagona qr  ',
      'yagonaqr',
      'YAGONA QR',
      'Yagona.QR',
      'Yagona / QR',
      'yagona  qr',
      'YaGoNa-Qr',
    ]) {
      test('"$n" → true', () => expect(YagonaQr.isName(n), isTrue));
    }
    for (final n in ['Card', 'CARD', 'CLICK QR', 'Payme QR', 'UZCARD', 'Yagona', '', null]) {
      test('"$n" → false', () => expect(YagonaQr.isName(n), isFalse));
    }
  });

  // ───────────────────────────────────────────────────────────────────────
  group('To\'lov turlarini yuklash (OrganizationSingleton)', () {
    final cash = Payment(id: ids.cash, name: 'CASH', title: 'Naqd', isAdded: true);
    final card = Payment(id: ids.card, name: 'CARD', title: 'Karta', isAdded: true);

    Future<void> load(List<Payment> pl) =>
        OrganizationSingleton.setOrgPrefs(OrganizationModel(name: 'Org'), pl);

    tearDown(() async {
      // Keyingi guruhlar uchun asl holat.
      // setOrgPrefs ro'yxatda yo'q turlarning id'larini bo'shatadi.
      await Pref.setString(PrefKeys.cashId, ids.cash);
      await Pref.setString(PrefKeys.cardId, ids.card);
      await Pref.setString(PrefKeys.cashbackId, ids.cashback);
      await Pref.setString(PrefKeys.debtId, ids.debt);
      await Pref.setString(PrefKeys.clickId, ids.click);
      await Pref.setString(PrefKeys.paymeId, ids.payme);
      await Pref.setString(PrefKeys.uzumId, ids.uzum);
      await Pref.setString(PrefKeys.yagonaQrId, kYagonaId);
      otherPaymentsGlobal = [];
    });

    test('YagonaQr id Pref\'ga yoziladi, karta id\'si ustidan yozilmaydi, '
        'tugma ro\'yxatida bor', () async {
      await load([
        cash,
        card,
        Payment(id: 'srv-yagona', name: 'YagonaQr', title: 'Yagona QR', isAdded: true),
      ]);
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), 'srv-yagona');
      expect(Pref.getString(PrefKeys.cardId, ''), ids.card);
      expect(Pref.getString(PrefKeys.cashId, ''), ids.cash);
      expect(otherPaymentsGlobal.map((e) => e.id), contains('srv-yagona'));
    });

    test('server nomi "YAGONA_QR" bo\'lsa ham taniladi', () async {
      await load([cash, Payment(id: 'srv-y2', name: 'YAGONA_QR', isAdded: true)]);
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), 'srv-y2');
    });

    test('admin YagonaQr ni olib tashlasa — id tozalanadi', () async {
      await load([cash, card, Payment(id: 'srv-y3', name: 'YagonaQr', isAdded: true)]);
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), 'srv-y3');
      await load([cash, card]);
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), '');
    });

    test('tur qutida bor, Pref bo\'sh (patch\'dan oldin yuklangan) — '
        'ishga tushishda tiklanadi', () async {
      await load([cash, card, Payment(id: 'srv-y4', name: 'Yagona QR', isAdded: true)]);
      await Pref.setString(PrefKeys.yagonaQrId, ''); // eski kod yozmagan holat
      await OrganizationSingleton.setOtherPayments(); // main.dart dagi chaqiruv
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), 'srv-y4');
    });

    test('qutida YagonaQr yo\'q — Pref bo\'sh qoladi', () async {
      await load([cash, card]);
      await OrganizationSingleton.setOtherPayments();
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), '');
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Apps yoqish/o\'chirish (WS type 40)', () {
    final cash = Payment(id: ids.cash, name: 'CASH', title: 'Naqd', isAdded: true);

    Payment? yagonaInList() {
      for (final e in otherPaymentsGlobal) {
        if (e.id == 'srv-ya') return e;
      }
      return null;
    }

    tearDown(() async {
      // setOrgPrefs ro'yxatda yo'q turlarning id'larini bo'shatadi.
      await Pref.setString(PrefKeys.cashId, ids.cash);
      await Pref.setString(PrefKeys.cardId, ids.card);
      await Pref.setString(PrefKeys.cashbackId, ids.cashback);
      await Pref.setString(PrefKeys.debtId, ids.debt);
      await Pref.setString(PrefKeys.clickId, ids.click);
      await Pref.setString(PrefKeys.paymeId, ids.payme);
      await Pref.setString(PrefKeys.uzumId, ids.uzum);
      await Pref.setString(PrefKeys.yagonaQrId, kYagonaId);
      await Pref.setBool(PrefKeys.clickEnable, false);
      otherPaymentsGlobal = [];
    });

    test('WS xabaridagi nom qutidagidan farq qilsa ham (YAGONAQR / YagonaQr) — id bo\'yicha o\'chadi',
        () async {
      await OrganizationSingleton.setOrgPrefs(OrganizationModel(name: 'Org'), [
        cash,
        Payment(id: 'srv-ya', name: 'YagonaQr', title: 'Yagona QR', isAdded: true),
      ]);
      await ProductsWsService.applyPaymentToggle(
          {'name': 'YAGONAQR', 'id': 'srv-ya', 'is_used': false});
      expect(yagonaInList()?.isAdded, isFalse);
      await ProductsWsService.applyPaymentToggle(
          {'name': 'YAGONAQR', 'id': 'srv-ya', 'is_used': true});
      expect(yagonaInList()?.isAdded, isTrue);
    });

    test('o\'chirildi → isAdded false (id qoladi), yoqildi → isAdded true',
        () async {
      await OrganizationSingleton.setOrgPrefs(OrganizationModel(name: 'Org'), [
        cash,
        Payment(id: 'srv-ya', name: 'YagonaQr', title: 'Yagona QR', isAdded: true),
      ]);
      expect(yagonaInList()?.isAdded, isTrue);
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), 'srv-ya');

      await ProductsWsService.applyPaymentToggle(
          {'name': 'YagonaQr', 'id': 'srv-ya', 'is_used': false});
      expect(yagonaInList()?.isAdded, isFalse);
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), 'srv-ya');
      // Qutining o'zida ham (keyingi ishga tushishda ham o'chiq qoladi).
      final fromBox = (await OrganizationSingleton.getOtherPayments())
          .firstWhere((e) => e.id == 'srv-ya');
      expect(fromBox.isAdded, isFalse);

      await ProductsWsService.applyPaymentToggle(
          {'name': 'YagonaQr', 'id': 'srv-ya', 'is_used': true});
      expect(yagonaInList()?.isAdded, isTrue);
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), 'srv-ya');
    });

    test('Click toggle eski xatti-harakati: clickEnable va clickId', () async {
      await OrganizationSingleton.setOrgPrefs(OrganizationModel(name: 'Org'), [
        cash,
        Payment(id: 'srv-click', name: 'CLICK', title: 'Click', isAdded: false),
      ]);
      await ProductsWsService.applyPaymentToggle(
          {'name': 'CLICK', 'id': 'srv-click', 'is_used': true});
      expect(Pref.getBool(PrefKeys.clickEnable, false), isTrue);
      expect(Pref.getString(PrefKeys.clickId, ''), 'srv-click');
      expect(
          otherPaymentsGlobal.firstWhere((e) => e.id == 'srv-click').isAdded,
          isTrue);
      // Click toggle YagonaQr id'siga tegmaydi.
      expect(Pref.getString(PrefKeys.yagonaQrId, ''), '');

      await ProductsWsService.applyPaymentToggle(
          {'name': 'CLICK', 'id': 'srv-click', 'is_used': false});
      expect(Pref.getBool(PrefKeys.clickEnable, true), isFalse);
      expect(
          otherPaymentsGlobal.firstWhere((e) => e.id == 'srv-click').isAdded,
          isFalse);
    });
  });

  group('Provider: to\'lov ekrani (aralash to\'lov)', () {
    test('naqd 30 000 + YagonaQr qoldiq 70 000 — chekda CASH va YAGONAQR', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '30000';
      p.allPaymentType(pay(ids.cash, 'CASH'));
      p.typeYagonaQr(yagona);

      expect(p.paymentsMap[ids.cash]?.value, 30000);
      expect(p.paymentsMap[kYagonaId]?.value, 70000);
      final chek = chekOf(p);
      expect(chek[ids.cash]?.name, 'CASH');
      expect(chek[kYagonaId]?.name, 'YAGONAQR');
      expect(p.lastCardType, 2);
    });

    test('Uzcard 40 000 + YagonaQr 60 000 — kalit "@" siz (serverga o\'z id\'si)',
        () {
      final p = paymentPage(total: 100000);
      p.controller.text = '40000';
      p.allPaymentType(pay(ids.card, 'CARD'));
      final y = pay(kYagonaId, kAdminName, type: 1); // eski tanlov qolsa ham
      p.typeYagonaQr(y);

      expect(p.paymentsMap.containsKey('@$kYagonaId'), isFalse);
      expect(p.paymentsMap[kYagonaId]?.value, 60000);
      expect(p.paymentsMap[ids.card]?.value, 40000);
      final chek = chekOf(p);
      expect(chek[ids.card]?.name, 'UZCARD');
      expect(chek[kYagonaId]?.name, 'YAGONAQR');
      // Serverga ketadigan JSON: payment_type_id = YagonaQr id.
      expect(chek[kYagonaId]!.toJson(),
          {'payment_type_id': kYagonaId, 'value': 60000.0});
    });

    test('Humo 25 000 + YagonaQr 75 000', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '25000';
      p.allPaymentType(pay(ids.card, 'CARD', type: 1));
      p.typeYagonaQr(yagona);
      final chek = chekOf(p);
      expect(chek['@${ids.card}']?.name, 'HUMO');
      expect(chek[kYagonaId]?.value, 75000);
    });

    test('avval YagonaQr 60 000 (klaviaturada), keyin naqd qoldiq 40 000', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '60000';
      p.typeYagonaQr(yagona);
      p.allPaymentType(pay(ids.cash, 'CASH'));
      expect(p.paymentsMap[kYagonaId]?.value, 60000);
      expect(p.paymentsMap[ids.cash]?.value, 40000);
    });

    test('YagonaQr summadan oshmaydi (klaviaturada 90 000, jami 50 000)', () {
      final p = paymentPage(total: 50000);
      p.controller.text = '90000';
      p.typeYagonaQr(yagona);
      expect(p.paymentsMap[kYagonaId]?.value, 50000);
    });

    test('hammasi to\'langan bo\'lsa YagonaQr qo\'shilmaydi', () {
      final p = paymentPage(total: 50000);
      p.allPaymentType(pay(ids.cash, 'CASH'));
      p.typeYagonaQr(yagona);
      expect(p.paymentsMap.containsKey(kYagonaId), isFalse);
      expect(p.paymentsMap[ids.cash]?.value, 50000);
      // Adashib bosildi — naqd chekka CardType 2 ketmasin.
      expect(p.lastCardType, 0);
    });

    test('qaytim faqat naqddan: YagonaQr 70 000 + naqd 50 000 (jami 100 000)',
        () {
      final p = paymentPage(total: 100000);
      p.controller.text = '70000';
      p.typeYagonaQr(yagona);
      p.controller.text = '50000';
      p.allPaymentType(pay(ids.cash, 'CASH'));

      expect(p.getSdacha, 20000);
      final chek = chekOf(p);
      expect(chek[kYagonaId]?.value, 70000); // YagonaQr'dan ayrilmaydi
      expect(chek[ids.cash]?.value, 30000); // 50 000 − qaytim 20 000
    });

    test('naqd + Uzcard + YagonaQr (uchtasi)', () {
      final p = paymentPage(total: 100000);
      p.controller.text = '30000';
      p.allPaymentType(pay(ids.cash, 'CASH'));
      p.controller.text = '20000';
      p.allPaymentType(pay(ids.card, 'CARD'));
      p.typeYagonaQr(yagona);
      final chek = chekOf(p);
      expect(chek.values.map((e) => e.name),
          unorderedEquals(['CASH', 'UZCARD', 'YAGONAQR']));
      expect(chek[kYagonaId]?.value, 50000);
    });

    test('cardType: boshida 0, YagonaQr → 2, yangi to\'lov sahifasi → 0', () {
      final p = paymentPage(total: 100000);
      expect(p.lastCardType, 0);
      p.typeYagonaQr(yagona);
      expect(p.lastCardType, 2);
      p.initPaymentPageValues(
        sixClientModel4: SixClientModel4(
          clientNumber: 1,
          lastAddedIndex: -1,
          orderedProducts: [],
          discountAmountFromNewClient: 0,
        ),
        totalPrice: 100000,
        discountAmount: 0,
      );
      expect(p.lastCardType, 0);
    });

    test('faqat naqd — cardType 0 qoladi', () {
      final p = paymentPage(total: 100000);
      p.allPaymentType(pay(ids.cash, 'CASH'));
      expect(p.lastCardType, 0);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('ReceiptPayments.build — chekdagi nom', () {
    test('id bo\'yicha YAGONAQR (admin nomi qanday bo\'lishidan qat\'iy nazar)',
        () {
      for (final adminName in ['YagonaQr', 'Yagona QR', 'yagona_qr', 'Boshqa']) {
        final list = ReceiptPayments.build(
          {kYagonaId: Payment(id: kYagonaId, name: adminName, value: 1000)},
          ids: yIds,
          sdacha: 0,
          zdachaToCashBack: 0,
        );
        expect(list.single.name, 'YAGONAQR', reason: adminName);
        expect(list.single.payId, kYagonaId);
      }
    });

    test('YagonaQr id sozlanmagan — nom o\'zgarmaydi (eski xatti-harakat)', () {
      final list = ReceiptPayments.build(
        {kYagonaId: Payment(id: kYagonaId, name: 'YagonaQr', value: 1000)},
        ids: ids, // yagonaQr: ''
        sdacha: 0,
        zdachaToCashBack: 0,
      );
      expect(list.single.name, 'YagonaQr');
    });

    test('boshqa turlar nomi o\'zgarmaydi', () {
      final list = paysWithYagona({
        Kind.cash: 1,
        Kind.uzcard: 1,
        Kind.humo: 1,
        Kind.clickPass: 1,
        Kind.clickQr: 1,
        Kind.paymeGo: 1,
        Kind.paymeQr: 1,
        Kind.uzum: 1,
        Kind.uzumQr: 1,
      }, yagona: 1);
      expect(list.map((e) => e.name).toList(), [
        'CASH',
        'UZCARD',
        'HUMO',
        'CLICK PASS',
        'CLICK QR',
        'PAYME GO',
        'PAYME QR',
        'UZUM',
        'UZUM QR',
        'YAGONAQR',
      ]);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Fiskal JSON: faqat YagonaQr × savat', () {
    for (final cart in [...carts, scaleCart]) {
      test(cart.name, () {
        final rows = cart.rows();
        final r = saleWithYagona(rows, {}, yagona: cartTotal(rows));
        final w = wireOf(r);
        final why = 'YagonaQr / ${cart.name}';

        expectModuleInvariants(w, why);
        final rp = receiptPart(w);
        expect(rp['ReceivedCash'], 0, reason: why);
        expect(rp['ReceivedCard'], (r.payment.single.value * 100).round(),
            reason: why);
        expect(sumOf(w, 'Other'), 0, reason: '$why: Other 0');
        expect(extraOf(w)['CardType'], 2, reason: '$why: CardType');
        // Provayder bayroqlari yo'q — YagonaQr Click/Payme/Uzum emas.
        expectFlags(paramsOf(r), <Kind>{}, why);
        // Karta — QQS to'liq.
        if (rows.any((x) => x.vatPercent > 0)) {
          expect(sumOf(w, 'VAT'), greaterThan(0), reason: '$why: VAT');
        }
      });
    }

    test('aniq raqamlar: 112 000 (12%) — ReceivedCard 11 200 000, VAT 12 000 so\'m',
        () {
      final r = saleWithYagona([row(realPrice: 112000)], {}, yagona: 112000);
      final w = wireOf(r);
      expect(receiptPart(w)['ReceivedCard'], 11200000);
      expect(receiptPart(w)['ReceivedCash'], 0);
      expect(sumOf(w, 'Other'), 0);
      expect(sumOf(w, 'VAT'), closeTo(1200000, 100));
    });

    test('qog\'oz chek QQS\'i fiskal bilan bir xil (karta — ayrilmaydi)', () {
      final r = saleWithYagona([row(realPrice: 112000)], {}, yagona: 112000);
      expect(ReceiptVat.total(r), closeTo(12000, 0.01));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Fiskal JSON: YagonaQr + har bir to\'lov turi (1/3 + 2/3)', () {
    for (final k in Kind.values) {
      test('${k.name} + YagonaQr', () {
        for (final cart in carts) {
          final rows = cart.rows();
          final double total = cartTotal(rows);
          final double first = (total / 3).floorToDouble();
          final amounts = {k: first};
          final r = saleWithYagona(rows, amounts, yagona: total - first);
          final w = wireOf(r);
          final why = '${k.name}+YagonaQr / ${cart.name}';
          expectModuleInvariants(w, why);
          expectBucketsWithYagona(w, amounts, total - first, why,
              rows: rows.length);
          expectFlags(paramsOf(r), {k}, why);
          expect(extraOf(w)['CardType'], 2, reason: why);
        }
      });
    }
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Fiskal JSON: murakkab holatlar', () {
    test('naqd 30 000 + Uzcard 20 000 + YagonaQr 50 000 → Cash 3 000 000, Card 7 000 000',
        () {
      final rows = [
        row(realPrice: 37500, value: 2, name: 'A'),
        row(realPrice: 25000, name: 'B'),
      ];
      final r = saleWithYagona(rows, {Kind.cash: 30000, Kind.uzcard: 20000},
          yagona: 50000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'naqd+karta+yagona');
      expect(receiptPart(w)['ReceivedCash'], 3000000);
      expect(receiptPart(w)['ReceivedCard'], 7000000);
      expect(sumOf(w, 'Other'), 0);
    });

    test('naqd qaytim: naqd 50 000 (qaytim 20 000) + YagonaQr 70 000', () {
      final r = saleWithYagona([row(realPrice: 100000)], {Kind.cash: 50000},
          yagona: 70000, sdacha: 20000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'sdacha');
      expect(receiptPart(w)['ReceivedCash'], 3000000);
      expect(receiptPart(w)['ReceivedCard'], 7000000);
    });

    test('cashback 10 000 + YagonaQr 90 000: Other = cashback, karta = YagonaQr',
        () {
      final r = saleWithYagona([row(realPrice: 100000)], {Kind.cashback: 10000},
          yagona: 90000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'cashback+yagona');
      expect(receiptPart(w)['ReceivedCard'], 9000000);
      expect(sumOf(w, 'Other'), 1000000);
      // QQS bazasi faqat cashback'ga kamayadi: (100 000 − 10 000) × 12/112.
      expect(sumOf(w, 'VAT'), closeTo(90000 * 12 / 112 * 100, 100));
    });

    test('Click QR 40 000 + YagonaQr 60 000: QR → Other, YagonaQr → karta', () {
      final r = saleWithYagona([row(realPrice: 100000)], {Kind.clickQr: 40000},
          yagona: 60000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'clickQr+yagona');
      expect(receiptPart(w)['ReceivedCard'], 6000000);
      expect(sumOf(w, 'Other'), 4000000);
      expect(paramsOf(r)['receivedClick'], false);
    });

    test('Click Pass + Payme Go + YagonaQr: hammasi karta, bayroqlar faqat Pass/Go',
        () {
      final r = saleWithYagona([row(realPrice: 90000)],
          {Kind.clickPass: 30000, Kind.paymeGo: 30000},
          yagona: 30000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'pass+go+yagona');
      expect(receiptPart(w)['ReceivedCard'], 9000000);
      expectFlags(paramsOf(r), {Kind.clickPass, Kind.paymeGo}, 'pass+go+yagona');
    });

    test('hamma 11 tur + YagonaQr bitta chekda', () {
      final rows = [
        row(realPrice: 125000, name: 'X'),
        row(realPrice: 55000, vatPercent: 0, name: 'Y'),
      ];
      final amounts = {for (final k in Kind.values) k: 15000.0};
      final r = saleWithYagona(rows, amounts, yagona: 15000);
      final w = wireOf(r);
      expectModuleInvariants(w, 'hammasi');
      expectBucketsWithYagona(w, amounts, 15000, 'hammasi', rows: 2);
    });

    test('tarozi (yarim so\'m) + naqd + YagonaQr: §10.2.1 balans saqlanadi', () {
      final rows = scaleCart.rows();
      final total = cartTotal(rows);
      final r = saleWithYagona(rows, {Kind.cash: 10000}, yagona: total - 10000);
      expectModuleInvariants(wireOf(r), 'tarozi');
    });

    test('serverdan qaytgan chek: nomi YAGONAQR, Pref id bo\'sh — baribir karta',
        () async {
      await Pref.setString(PrefKeys.yagonaQrId, '');
      try {
        final r = receiptOf([row(realPrice: 50000)], [
          ReceiptModelPaymentType4(name: 'YAGONAQR', payId: 'other-id', value: 50000),
        ]);
        final w = wireOf(r);
        expectModuleInvariants(w, 'server');
        expect(receiptPart(w)['ReceivedCard'], 5000000);
        expect(sumOf(w, 'Other'), 0);
      } finally {
        await Pref.setString(PrefKeys.yagonaQrId, kYagonaId);
      }
    });

    test('nom normallashmagan ("YagonaQr"), id bo\'yicha — karta', () {
      final r = receiptOf([row(realPrice: 50000)], [
        ReceiptModelPaymentType4(name: 'Yagona QR', payId: kYagonaId, value: 50000),
      ]);
      expect(receiptPart(wireOf(r))['ReceivedCard'], 5000000);
    });

    test('vozvrat: YagonaQr chekining qaytarilishi — hammasi ReceivedCash', () {
      final r = receiptOf(
        [row(realPrice: 50000)],
        [ReceiptModelPaymentType4(name: 'CASH', payId: ids.cash, value: 50000)],
        isRefund: true,
      );
      // Asl to'lovlar qolgan bo'lsa ham (return_bloc faqat CASH yozadi).
      final r2 = receiptOf(
        [row(realPrice: 50000)],
        [ReceiptModelPaymentType4(name: 'YAGONAQR', payId: kYagonaId, value: 50000)],
        isRefund: true,
      );
      for (final x in [r, r2]) {
        final w = wireOf(x);
        expectModuleInvariants(w, 'vozvrat');
        expect(receiptPart(w)['ReceivedCash'], 5000000);
        expect(receiptPart(w)['ReceivedCard'], 0);
      }
    });

    test('saleOnOFD qayta chaqirilsa (PreOfd qayta urinish) natija bir xil', () {
      final rows = [row(realPrice: 100000)];
      final r = saleWithYagona(rows, {Kind.cash: 40000}, yagona: 60000);
      final a = receiptPart(wireOf(r));
      final b = receiptPart(wireOf(r));
      expect(a['ReceivedCash'], b['ReceivedCash']);
      expect(a['ReceivedCard'], b['ReceivedCard']);
      expect(a['ReceivedCard'], 6000000);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  group('Ko\'rinadigan nom', () {
    test('qog\'oz chek: "yagonaqr" → "YagonaQR"', () {
      expect(PrintingApiHelper.getTulovTuri('yagonaqr'), 'YagonaQR');
      // sold_api_components.dart nomni kichik harfga o'giradi.
      expect(PrintingApiHelper.getTulovTuri(YagonaQr.code.toLowerCase()),
          'YagonaQR');
    });
  });
}
