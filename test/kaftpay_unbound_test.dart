// Kaftpay: to'lov chekka bog'lanadi.
//
// - Chekda (`epayJson` → ReceiptEpay.kaftpayTx) shu sotuvdagi Kaftpay
//   tranzaksiyalari; fiskal ExtraInfo'ga ta'sir qilmaydi.
// - Chek saqlangach jurnalda chek raqami (`KaftpayJournalEntry.receipt`).
// - Pul yechilgan, chek chiqmagan to'lov — sotuv ekranida ogohlantirish
//   (KaftpayUnboundNotice) va "Vozvrat".
//
// Sotuv → ObjectBox qismi native kutubxona bo'lsa ishlaydi
// (yagonaqr_shift_report_test.dart dagi izohga qarang), bo'lmasa SKIP.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/receipt_epay.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/services/payment/epay_capture.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_api.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_lang.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_sale.dart';
import 'package:invan2/changes/services/payment/kaftpay/kaftpay_settings.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_entry_actions.dart';
import 'package:invan2/features/payment/right/dilogs/kaftpay/kaftpay_unbound_notice.dart';
import 'package:invan2/objectbox.g.dart' hide Box;
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/epay_fixtures.dart';
import 'support/kaftpay_fake_server.dart';
import 'support/provider_harness.dart';

const kKaftpayId = 'pay-kaftpay';

Store? _tryOpenStore() {
  try {
    final dir = Directory.systemTemp.createTempSync('kaftpay_unbound_obx');
    return Store(getObjectBoxModel(), directory: dir.path);
  } catch (_) {
    return null;
  }
}

KaftpayJournalEntry entry(
  String key, {
  KaftpayJournalStatus status = KaftpayJournalStatus.charged,
  String? receipt = '',
  String? tx,
  int amount = 2000000,
  String? note,
}) =>
    KaftpayJournalEntry(
      key: key,
      requestId: 'r-$key',
      consumerGuid: 'g',
      consumerName: 'Ayyubxon',
      amount: amount,
      createdAt: DateTime(2026, 10, 31, 13, 24),
      status: status,
      transactionId: tx ?? 'tx-$key',
      receipt: receipt,
      note: note,
    );

ReceiptModelPaymentType4 pay(String name, String id, double v) =>
    ReceiptModelPaymentType4(name: name, payId: id, value: v);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('kaftpay_unbound', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashId, ids.cash);
    await Pref.setString(PrefKeys.cardId, ids.card);
    await Pref.setString(PrefKeys.cashbackId, ids.cashback);
    await Pref.setString(PrefKeys.clickId, ids.click);
    await Pref.setString(PrefKeys.paymeId, ids.payme);
    await Pref.setString(PrefKeys.uzumId, ids.uzum);
    await Pref.setString(PrefKeys.kaftpayId, kKaftpayId);
    await Pref.setString(PrefKeys.kaftpayClientId, 'pos-test');
    await Pref.setString(PrefKeys.kaftpaySecret, 'test-secret');
    await Pref.setString(PrefKeys.token, 'tok');
    await Pref.setString(PrefKeys.cashierName, 'Nodira');
  });
  tearDownAll(tearDownPosTestEnv);

  final journal = KaftpayJournal();
  Future<void> seed(List<KaftpayJournalEntry> list) async {
    await Pref.setString(PrefKeys.kaftpayJournal, '');
    for (final e in list.reversed) {
      await journal.put(e);
    }
  }

  setUp(() async {
    await Pref.setString(PrefKeys.kaftpayJournal, '');
    KaftpayUnboundNotice.resetForTest();
    KaftpayLang.uz = true;
  });

  // ─────────────────────────────────────────────────────────────────────
  group('Jurnal: chek maydoni', () {
    test('JSON orqali saqlanadi; eski yozuv (maydonsiz) kuzatilmaydi',
        () async {
      await seed([
        entry('new'),
        entry('bound', receipt: 'DN-7'),
        entry('old', receipt: null),
      ]);
      final all = {for (final e in journal.all()) e.key: e};
      expect(all['new']!.receipt, '');
      expect(all['bound']!.receipt, 'DN-7');
      expect(all['old']!.receipt, isNull);
      expect(journal.unbound().map((e) => e.key), ['new']);
    });

    test('faqat "yechildi" holati chek kutadi', () async {
      for (final st in KaftpayJournalStatus.values) {
        expect(entry('k', status: st).isUnbound,
            st == KaftpayJournalStatus.charged,
            reason: st.name);
      }
    });

    test('bindReceipt: faqat berilgan kalitlar; izoh va holat saqlanadi',
        () async {
      await seed([
        entry('a', note: 'izoh'),
        entry('b'),
        entry('c'),
      ]);
      await journal.bindReceipt(['a', 'c'], 'DN-12');
      final all = {for (final e in journal.all()) e.key: e};
      expect(all['a']!.receipt, 'DN-12');
      expect(all['a']!.note, 'izoh');
      expect(all['a']!.status, KaftpayJournalStatus.charged);
      expect(all['b']!.receipt, '');
      expect(all['c']!.receipt, 'DN-12');
      expect(journal.unbound().map((e) => e.key), ['b']);
      expect(journal.all().map((e) => e.key), ['a', 'b', 'c'],
          reason: 'tartib o\'zgarmaydi');
    });

    test('chek raqami bo\'sh kelsa ham belgilanadi', () async {
      await seed([entry('a')]);
      await journal.bindReceipt(['a'], '');
      expect(journal.unbound(), isEmpty);
    });

    test('vozvrat holati chekni o\'chirmaydi (copyWith)', () {
      final e = entry('a', receipt: 'DN-1')
          .copyWith(status: KaftpayJournalStatus.refunded);
      expect(e.receipt, 'DN-1');
    });

    test('200 tadan oshganda chek chiqmaganlar tushib qolmaydi', () async {
      await seed([entry('lost', amount: 1)]);
      for (var i = 0; i < KaftpayJournal.maxEntries + 5; i++) {
        await journal.put(entry('x$i', receipt: 'DN-$i'));
      }
      expect(journal.byKey('lost'), isNotNull);
      expect(journal.unbound().single.key, 'lost');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  group('KaftpaySaleCharges', () {
    test('qo\'shish, tranzaksiyalar, belgilash, tozalash', () async {
      await seed([entry('k1'), entry('k2'), entry('k3')]);
      final sale = KaftpaySaleCharges();
      expect(sale.isEmpty, isTrue);
      sale.add(journalKey: 'k1', transactionId: 'tx-1');
      sale.add(journalKey: 'k2', transactionId: null);
      sale.add(journalKey: '', transactionId: 'tx-x');
      expect(sale.journalKeys, ['k1', 'k2']);
      expect(sale.transactionIds, ['tx-1']);

      await sale.bind('DN-5');
      expect(sale.isEmpty, isTrue);
      expect(journal.unbound().map((e) => e.key), ['k3']);

      sale.add(journalKey: 'k3', transactionId: 'tx-3');
      sale.clear();
      await sale.bind('DN-6');
      expect(journal.unbound().map((e) => e.key), ['k3'],
          reason: 'tozalangan — belgilanmaydi');
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  group('Chekda Kaftpay tranzaksiyasi (ReceiptEpay.kaftpayTx)', () {
    final rows = [row(realPrice: 100000)];

    test('chekda Kaftpay bor — tx yoziladi; ExtraInfo provayderi yo\'q', () {
      final r = receiptOf(rows, [
        pay('CASH', ids.cash, 40000),
        pay('KAFTPAY', kKaftpayId, 60000),
      ]);
      final raw = EpayCapture.forReceipt(r, kaftpayTx: ['tx-1', ' ', 'tx-2']);
      final e = ReceiptEpay.decode(raw);
      expect(e.kaftpayTx, ['tx-1', 'tx-2']);
      expect(e.qrPaymentProvider, 0);
      expect(e.qrPaymentId, '');

      r.epayJson = raw;
      final w = wireOf(r);
      final extra = receiptPart(w)['ExtraInfo'] as Map<String, dynamic>;
      expect(extra['QRPaymentProvider'], anyOf(0, isNull));
      expect(extra['QRPaymentID'], anyOf('', isNull));
    });

    test('chekda Kaftpay yo\'q — eski tx yozilmaydi', () {
      final r = receiptOf(rows, [pay('CASH', ids.cash, 100000)]);
      expect(EpayCapture.forReceipt(r, kaftpayTx: ['tx-old']), isNull);
    });

    test('vozvrat chekiga yozilmaydi', () {
      final r =
          receiptOf(rows, [pay('KAFTPAY', kKaftpayId, 100000)], isRefund: true);
      expect(EpayCapture.forReceipt(r, kaftpayTx: ['tx-1']), isNull);
    });

    test('Click Pass + Kaftpay: Click provayderi saqlanadi, Kaftpay tx ham',
        () {
      final r = receiptOf(rows, [
        pay('CLICK PASS', ids.click, 50000),
        pay('KAFTPAY', kKaftpayId, 50000),
      ]);
      final e = ReceiptEpay.capture(
        receipt: r,
        clickId: ids.click,
        paymeId: ids.payme,
        uzumId: ids.uzum,
        paynetId: '',
        clickPaymentId: 'click-77',
        kaftpayId: kKaftpayId,
        kaftpayTx: ['tx-9'],
      );
      expect(e.qrPaymentProvider, ReceiptEpay.clickProvider);
      expect(e.qrPaymentId, 'click-77');
      expect(e.kaftpayTx, ['tx-9']);
      final back = ReceiptEpay.decode(e.encode());
      expect(back.kaftpayTx, ['tx-9']);
      expect(back.clickPaymentId, 'click-77');
    });

    test('eski chek JSON\'ida kaftpayTx yo\'q — bo\'sh ro\'yxat', () {
      final e = ReceiptEpay.decode('{"qrPaymentProvider":64,'
          '"qrPaymentId":"c","clickPaymentId":"c"}');
      expect(e.kaftpayTx, isEmpty);
      expect(e.qrPaymentProvider, 64);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  group('Ogohlantirish shartlari', () {
    test('chek chiqmagan to\'lov bo\'lsa — ko\'rsatiladi', () async {
      await seed([entry('a')]);
      expect(KaftpayUnboundNotice.shouldShow(), isTrue);
    });

    test('hammasi chekda / eski yozuvlar — ko\'rsatilmaydi', () async {
      await seed([
        entry('a', receipt: 'DN-1'),
        entry('b', receipt: null),
        entry('c', status: KaftpayJournalStatus.refunded),
      ]);
      expect(KaftpayUnboundNotice.shouldShow(), isFalse);
    });

    test('Kaftpay o\'chirilgan yoki login yo\'q — ko\'rsatilmaydi', () async {
      await seed([entry('a')]);
      await Pref.setString(PrefKeys.kaftpayId, '');
      expect(KaftpayUnboundNotice.shouldShow(), isFalse);
      await Pref.setString(PrefKeys.kaftpayId, kKaftpayId);
      await Pref.setString(PrefKeys.token, '');
      expect(KaftpayUnboundNotice.shouldShow(), isFalse);
      await Pref.setString(PrefKeys.token, 'tok');
      expect(KaftpayUnboundNotice.shouldShow(), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  group('Ogohlantirish oynasi', () {
    late FakeKaftpay server;
    // Oyna jurnalga widget ichidan (FakeAsync zonasida) yozadi — Hive yozuvi
    // u yerda tugamaydi va keyingi testlarning yozuvlarini osiltirib qo'yadi
    // (provider_harness izohi). Shuning uchun xotiradagi jurnal.
    String raw = '';
    final mem = KaftpayJournal(read: () => raw, write: (v) async => raw = v);
    Future<void> seedMem(List<KaftpayJournalEntry> list) async {
      raw = '';
      for (final e in list.reversed) {
        await mem.put(e);
      }
    }

    setUp(() async {
      // testWidgets ichidagi tearDown'da Hive yozuvi FakeAsync zonasida
      // tugamaydi (provider_harness izohi) — kalitlar shu yerda tiklanadi.
      await Pref.setString(PrefKeys.kaftpayClientId, 'pos-test');
      server = FakeKaftpay();
      KaftpayApi.onHttpResponse = (_) {};
      KaftpayEntryActions.apiFor = (c) => KaftpayApi(
          config:
              const KaftpayConfig(clientId: 'pos-test', secret: 'test-secret'),
          client: server.client);
    });
    tearDown(() {
      KaftpayEntryActions.apiFor = (c) => KaftpayApi(config: c);
    });

    Future<void> settle(WidgetTester tester) async {
      for (var i = 0; i < 12; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    Future<bool? Function()> open(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      bool? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: TextButton(
                  onPressed: () async => result =
                      await KaftpayUnboundDialog.show(ctx, journal: mem),
                  child: const Text('open')),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await settle(tester);
      return () => result;
    }

    testWidgets('faqat chek chiqmaganlar ko\'rinadi; "Keyinroq" → true',
        (tester) async {
      await seedMem([
        entry('a', amount: 2000000),
        entry('b', receipt: 'DN-1'),
        entry('c', receipt: null),
      ]);
      final result = await open(tester);
      expect(
          find.byKey(const ValueKey('kaftpay_unbound_row_a')), findsOneWidget);
      expect(find.byKey(const ValueKey('kaftpay_unbound_row_b')), findsNothing);
      expect(find.byKey(const ValueKey('kaftpay_unbound_row_c')), findsNothing);
      expect(find.text("20,000 so'm"), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('kaftpay_unbound_later')));
      await settle(tester);
      expect(find.byType(KaftpayUnboundDialog), findsNothing);
      expect(result(), isTrue);
    });

    testWidgets('Vozvrat → pul qaytdi, jurnalda "qaytarildi", oyna yopiladi',
        (tester) async {
      await seedMem([entry('a', tx: kTx)]);
      server.on(
          'POST',
          '/api/v1/pay/$kTx/refund',
          FakeKaftpay.ok({
            'transactionId': kTx,
            'status': 'REFUNDED',
            'amount': 2000000,
            'refundAcquirerRef': 'R-1',
          }));
      final result = await open(tester);
      await tester.tap(find.byKey(const ValueKey('kaftpay_unbound_refund_a')));
      await settle(tester);
      // Tasdiq oynasi → "Qaytarish".
      await tester.tap(find.byKey(const ValueKey('kaftpay_action_confirm')));
      await settle(tester);
      expect(
          find.byKey(const ValueKey('kaftpay_action_title')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('kaftpay_action_close')));
      await settle(tester);

      expect(server.calls('POST', '/api/v1/pay/$kTx/refund'), hasLength(1));
      expect(mem.byKey('a')!.status, KaftpayJournalStatus.refunded);
      expect(find.byType(KaftpayUnboundDialog), findsNothing,
          reason: 'boshqa chek chiqmagan to\'lov qolmadi');
      expect(result(), isFalse);
    });

    testWidgets('kalitlar yo\'q — Vozvrat o\'chiq, ogohlantirish',
        (tester) async {
      await seedMem([entry('a')]);
      await tester.runAsync(() => Pref.setString(PrefKeys.kaftpayClientId, ''));
      await open(tester);
      final btn = tester.widget<ButtonStyleButton>(
          find.byKey(const ValueKey('kaftpay_unbound_refund_a')));
      expect(btn.onPressed, isNull);
      expect(find.text('Kaftpay kalitlari kiritilmagan'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────
  final Store? store = _tryOpenStore();
  group('Sotuv: chek saqlanganda jurnal belgilanadi (ObjectBox)',
      skip: store == null
          ? 'ObjectBox kutubxonasi topilmadi (libobjectbox) — '
              'yagonaqr_shift_report_test.dart izohiga qarang'
          : false, () {
    setUpAll(() => MyObjectbox.saleStore = store!);
    tearDownAll(() => store?.close());

    Payment kaftpay() => Payment(
        id: kKaftpayId, name: 'Kaftpay', title: 'Kaftpay', enable: true);

    testWidgets(
        'Kaftpay bilan yakunlangan sotuv — chek raqami jurnalga, tx '
        'chekka (chop etish yiqilsa ham)', (tester) async {
      await tester.runAsync(() => seed([entry('k1', tx: 'tx-1')]));
      await tester.pumpWidget(const MaterialApp(home: SizedBox()));
      final ctx = tester.element(find.byType(SizedBox));

      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(productId: 'a', price: 50000, realPrice: 50000));
      p.initPaymentPageValues(
          sixClientModel4: p.getCurrentClient,
          totalPrice: 50000,
          discountAmount: 0);
      p.recordKaftpay(kaftpay(), 50000,
          journalKey: 'k1', transactionId: 'tx-1');
      // Testda printer qutisi yo'q — chop etish yiqiladi; chek esa undan
      // OLDIN saqlangan, to'lov baribir bog'lanishi kerak.
      Object? printError;
      await tester.runAsync(() async {
        try {
          await p.pressPaymentButton(ctx);
        } catch (e) {
          printError = e;
        }
      });
      expect(printError, isNotNull, reason: 'printer qutisi yo\'q');

      final e = await tester.runAsync(() async => journal.byKey('k1'));
      expect(e!.isUnbound, isFalse);
      expect(e.receipt, isNotEmpty);
      final saved = MyObjectbox.saleStore.box<ReceiptModel4>().getAll().last;
      expect(saved.externalId, e.receipt);
      expect(ReceiptEpay.decode(saved.epayJson).kaftpayTx, ['tx-1']);
      expect(p.kaftpaySale.isEmpty, isTrue);
    });

    testWidgets(
        'to\'lov sahifasidan chiqib ketilsa — chek yo\'q bo\'lib qoladi',
        (tester) async {
      await tester.runAsync(() => seed([entry('k2', tx: 'tx-2')]));
      final p = freshProvider();
      p.initPaymentPageValues(
          sixClientModel4: p.getCurrentClient,
          totalPrice: 50000,
          discountAmount: 0);
      p.recordKaftpay(kaftpay(), 50000,
          journalKey: 'k2', transactionId: 'tx-2');
      // Kassir sotuvni yakunlamay chiqdi, keyingi sotuv boshlandi.
      p.initPaymentPageValues(
          sixClientModel4: p.getCurrentClient,
          totalPrice: 10000,
          discountAmount: 0);
      expect(p.kaftpaySale.isEmpty, isTrue);
      final left = await tester.runAsync(() async => journal.unbound());
      expect(left!.map((e) => e.key), ['k2']);
    });
  });
}
