// YagonaQr — smena (X/Z) hisoboti: ALOHIDA summa (`salesSummary.yagonaQr`),
// "Plastik" (uzCard + humoCard) ichida ham, "Other" da ham emas
// (foydalanuvchi, 2026-11-19; 2026-10-20 dan beri Plastik ichida edi).
// Fiskalga avvalgidek karta bo'lib ketadi — bu fayl faqat hisobotni sinaydi.
//
// `ShiftSingleton4.getCurrentHiveShift` smenani ObjectBox'dagi cheklardan
// qayta hisoblaydi (`case 'yagonaqr'` → `yagonaQrPayment`).
//
// ObjectBox native kutubxonasi kerak (`libobjectbox.dylib` / `.so` / `.dll`
// loyiha ildizida yoki tizimda). Topilmasa ObjectBox guruhi SKIP qilinadi
// (adapter testlari baribir ishlaydi). Mac'da:
//   cp build/macos/Build/Products/Debug/invan2.app/Contents/Frameworks/ObjectBox.framework/Versions/A/ObjectBox libobjectbox.dylib
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
// ignore: implementation_imports
import 'package:hive/src/binary/binary_reader_impl.dart';
// ignore: implementation_imports
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/features/printing/api/print_smena_api.dart';
import 'package:invan2/features/report/features/shifts_opened/view/hive_content.dart';
import 'package:invan2/objectbox.g.dart' hide Box;
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/money_formatter.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

import 'support/epay_fixtures.dart';
import 'support/provider_harness.dart';

Store? _tryOpenStore() {
  try {
    final dir = Directory.systemTemp.createTempSync('yagonaqr_shift_obx');
    return Store(getObjectBoxModel(), directory: dir.path);
  } catch (_) {
    return null;
  }
}

ReceiptModelPaymentType4 p(String name, String id, double v) =>
    ReceiptModelPaymentType4(name: name, payId: id, value: v);

const kYagonaId = 'pay-yagona';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Store? store = _tryOpenStore();

  group('Smena hisoboti: YagonaQr alohida',
      skip: store == null
          ? "ObjectBox kutubxonasi topilmadi (libobjectbox) — fayl boshidagi izohga qarang"
          : false, () {
    setUpAll(() async {
      await setUpPosTestEnv('yagonaqr_shift_report', withEmployee: false);
      if (!Hive.isAdapterRegistered(ShiftModelHiveAdapter().typeId)) {
        Hive.registerAdapter<ShiftModelHive>(ShiftModelHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(CashDrawerHiveAdapter().typeId)) {
        Hive.registerAdapter<CashDrawerHive>(CashDrawerHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(SalesSummaryHiveAdapter().typeId)) {
        Hive.registerAdapter<SalesSummaryHive>(SalesSummaryHiveAdapter());
      }
      if (!Hive.isAdapterRegistered(PaysHiveAdapter().typeId)) {
        Hive.registerAdapter<PaysHive>(PaysHiveAdapter());
      }
      await Hive.openBox<ShiftModelHive>(HiveBoxNames.shifts);
      MyObjectbox.saleStore = store!;

      // Ochiq smena (Hive'da yozuv yo'q — getCurrentHiveShift tiklaydi).
      final opened = DateTime.now().subtract(const Duration(hours: 1));
      await Pref.setInt(PrefKeys.currentShiftKey, 7);
      await Pref.setInt(
          PrefKeys.shiftOpenedTime, opened.millisecondsSinceEpoch);
      await Pref.setBool(PrefKeys.shiftsOpened, true);
    });
    tearDownAll(() async {
      store?.close();
      await tearDownPosTestEnv();
    });

    SalesSummaryHive summaryOf(List<ReceiptModel4> receipts) {
      final box = MyObjectbox.saleStore.box<ReceiptModel4>();
      box.removeAll();
      box.putMany(receipts);
      return ShiftSingleton4.getCurrentHiveShift()!.salesSummary!;
    }

    test('naqd + YagonaQr, Uzcard, Humo + YagonaQr — YagonaQr alohida, '
        'Plastik faqat Uzcard + HUMO', () {
      final s = summaryOf([
        receiptOf([row(realPrice: 100000)], [
          p('CASH', ids.cash, 30000),
          p('YAGONAQR', kYagonaId, 70000),
        ]),
        receiptOf([row(realPrice: 50000)], [p('UZCARD', ids.card, 50000)]),
        receiptOf([row(realPrice: 50000)], [
          p('HUMO', '@${ids.card}', 20000),
          p('YAGONAQR', kYagonaId, 30000),
        ]),
      ]);
      expect(s.yagonaQr, 100000); // 70 000 + 30 000
      expect(s.uzCard, 50000, reason: 'YagonaQr endi Uzcard ga qo\'shilmaydi');
      expect(s.humoCard, 20000);
      expect((s.uzCard ?? 0) + (s.humoCard ?? 0), 70000); // "Plastik"
      expect(s.card, 70000);
      expect(s.cash, 30000);
      expect(s.other, 0);
      expect(s.grossSales, 200000, reason: 'jami sotuv o\'zgarmaydi');
    });

    test('100% YagonaQr cheki — hammasi YagonaQr qatorida', () {
      final s = summaryOf([
        receiptOf([row(realPrice: 77050)], [p('YAGONAQR', kYagonaId, 77050)]),
      ]);
      expect(s.yagonaQr, 77050);
      expect(s.uzCard, 0);
      expect(s.card, 0);
      expect(s.cash, 0);
      expect(s.grossSales, 77050);
    });

    test('nom har xil yozilgan ("YagonaQr", "Yagona QR", "Yagona Qr", '
        '"yagona_qr") — hammasi bitta YagonaQr qatorida', () {
      final s = summaryOf([
        receiptOf([row(realPrice: 10000)], [p('YagonaQr', kYagonaId, 10000)]),
        receiptOf([row(realPrice: 20000)], [p('Yagona QR', kYagonaId, 20000)]),
        receiptOf([row(realPrice: 30000)], [p('Yagona Qr', kYagonaId, 30000)]),
        receiptOf([row(realPrice: 40000)], [p('yagona_qr', kYagonaId, 40000)]),
      ]);
      expect(s.yagonaQr, 100000);
      expect(s.other, 0, reason: 'avval bo\'sh joyli nom "Other" ga tushardi');
      expect(s.uzCard, 0);
      expect(s.grossSales, 100000);
    });

    test('YagonaQr + Click QR + Payme Go + cashback + qarz bitta chekda — '
        'har biri o\'z qatorida', () {
      final s = summaryOf([
        receiptOf([row(realPrice: 100000)], [
          p('YAGONAQR', kYagonaId, 50000),
          p('CLICK QR', '@${ids.click}', 20000),
          p('PAYME GO', ids.payme, 10000),
          p('CASHBACK', ids.cashback, 5000),
          p('DEBT', ids.debt, 15000),
        ]),
      ]);
      expect(s.yagonaQr, 50000);
      expect(s.clickQr, 20000);
      expect(s.payme, 10000);
      expect(s.cashbackOut, 5000);
      expect(s.debt, 15000);
      expect(s.uzCard, 0);
      expect(s.other, 0);
      expect(s.grossSales, 100000);
    });

    test('YagonaQr cheki vozvrati — naqd qaytim, YagonaQr summasi kamaymaydi '
        '(vozvrat hammasi naqd)', () {
      final sale = receiptOf(
          [row(realPrice: 40000)], [p('YAGONAQR', kYagonaId, 40000)]);
      final refund =
          receiptOf([row(realPrice: 40000)], [p('CASH', ids.cash, 40000)])
            ..isRefund = true;
      final box = MyObjectbox.saleStore.box<ReceiptModel4>();
      box.removeAll();
      box.putMany([sale, refund]);

      final shift = ShiftSingleton4.getCurrentHiveShift()!;
      final s = shift.salesSummary!;
      expect(s.yagonaQr, 40000);
      expect(s.refunds, 40000);
      expect(s.cash, 0);
      expect(s.grossSales, 0);
      // Kassadagi naqd: qaytim naqd puldan berilgan.
      expect(shift.cashDrawerHive!.cashRefund, 40000);
    });

    test('YagonaQr yo\'q smena — yagonaQr 0, qolgani o\'zgarmagan', () {
      final s = summaryOf([
        receiptOf([row(realPrice: 50000)], [p('UZCARD', ids.card, 50000)]),
        receiptOf([row(realPrice: 20000)], [p('CASH', ids.cash, 20000)]),
      ]);
      expect(s.yagonaQr, 0);
      expect(s.uzCard, 50000);
      expect(s.cash, 20000);
      expect(s.grossSales, 70000);
    });

    group('X/Z ekrani va cheki: "Yagona QR" qatori', () {
      Future<void> pumpReport(WidgetTester tester) async {
        tester.view.physicalSize = const Size(1920, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(
          locale: const Locale('uz'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(builder: (c) {
              SizeConfig().init(c);
              return SingleChildScrollView(child: ShiftContennt());
            }),
          ),
        ));
        await tester.pump();
      }

      String fmt(num v) => MoneyFormatter.formatter.format(v);

      /// "Sarlavha" matni turgan qatordagi summa matni.
      String amountOf(WidgetTester tester, String label) {
        final rowFinder = find
            .ancestor(of: find.text(label), matching: find.byType(Row))
            .first;
        final texts = tester
            .widgetList<Text>(
                find.descendant(of: rowFinder, matching: find.byType(Text)))
            .map((t) => t.data)
            .toList();
        return texts.last!;
      }

      testWidgets('YagonaQr bor: alohida qator, Plastik faqat Uzcard + HUMO',
          (tester) async {
        final box = MyObjectbox.saleStore.box<ReceiptModel4>();
        box.removeAll();
        box.putMany([
          receiptOf([row(realPrice: 50000)], [p('UZCARD', ids.card, 50000)]),
          receiptOf(
              [row(realPrice: 20000)], [p('HUMO', '@${ids.card}', 20000)]),
          receiptOf([row(realPrice: 77050)], [
            p('CASH', ids.cash, 30000),
            p('YAGONAQR', kYagonaId, 47050),
          ]),
        ]);

        await pumpReport(tester);

        expect(find.text('Yagona QR'), findsOneWidget);
        expect(amountOf(tester, 'Yagona QR'), fmt(47050));
        final loc = AppLocalizations.of(tester.element(find.byType(Scaffold)))!;
        expect(amountOf(tester, loc.plastik), fmt(70000),
            reason: 'Plastik = 50 000 Uzcard + 20 000 HUMO, YagonaQr siz');
        expect(amountOf(tester, loc.naqdPulda), fmt(30000));
        expect(amountOf(tester, loc.savdolar), fmt(147050));
      });

      testWidgets('YagonaQr yo\'q: qator chiqmaydi', (tester) async {
        final box = MyObjectbox.saleStore.box<ReceiptModel4>();
        box.removeAll();
        box.put(
            receiptOf([row(realPrice: 50000)], [p('UZCARD', ids.card, 50000)]));

        await pumpReport(tester);

        expect(find.text('Yagona QR'), findsNothing);
      });

      test('chek (PDF 57 va 80 mm, X va Z): YagonaQr bilan ham, usiz ham '
          'yasaladi', () async {
        final loc = lookupAppLocalizations(const Locale('uz'));
        final box = MyObjectbox.saleStore.box<ReceiptModel4>();
        for (final withYagona in [true, false]) {
          box.removeAll();
          box.put(receiptOf([
            row(realPrice: 70000)
          ], [
            withYagona
                ? p('YAGONAQR', kYagonaId, 70000)
                : p('UZCARD', ids.card, 70000)
          ]));
          final shift = ShiftSingleton4.getCurrentHiveShift()!;
          expect(shift.salesSummary!.yagonaQr, withYagona ? 70000 : 0);
          for (final isZ in [true, false]) {
            expect((await PrintSmenaApi.generatePdf80(shift, loc, isZ)).length,
                greaterThan(1000));
            expect((await PrintSmenaApi.generatePdf57(shift, loc, isZ)).length,
                greaterThan(1000));
          }
        }
        // Yangilanishdan oldin ochilgan smena: yagonaQr maydoni null.
        final old = ShiftSingleton4.getCurrentHiveShift()!
          ..salesSummary!.yagonaQr = null;
        expect((await PrintSmenaApi.generatePdf80(old, loc, true)).length,
            greaterThan(1000));
      });
    });
  });

  group('SalesSummaryHive adapteri — yagonaQr maydoni (20)', () {
    test('yozib-o\'qish: yagonaQr saqlanadi', () async {
      final dir = Directory.systemTemp.createTempSync('yagonaqr_hive_rw');
      Hive.init(dir.path);
      if (!Hive.isAdapterRegistered(SalesSummaryHiveAdapter().typeId)) {
        Hive.registerAdapter<SalesSummaryHive>(SalesSummaryHiveAdapter());
      }
      final box = await Hive.openBox<SalesSummaryHive>('ss_rw');
      await box.put(1, SalesSummaryHive(uzCard: 5, other: 2, yagonaQr: 77));
      await box.close();
      final again = await Hive.openBox<SalesSummaryHive>('ss_rw');
      expect(again.get(1)!.yagonaQr, 77);
      expect(again.get(1)!.uzCard, 5);
      expect(again.get(1)!.other, 2);
      await again.close();
    });

    test('eski yozuv (19 maydon, yagonaQr yo\'q) — o\'qiladi, yagonaQr null',
        () {
      // Yangilanishdan oldingi adapter yozgan baytlar: 19 ta maydon (0..18).
      final w = BinaryWriterImpl(Hive);
      w.writeByte(19);
      for (var i = 0; i < 19; i++) {
        w.writeByte(i);
        w.write(i == 16 ? 150000 : (i == 18 ? 0 : i));
      }
      final s = SalesSummaryHiveAdapter().read(BinaryReaderImpl(w.toBytes(), Hive));
      expect(s.uzCard, 150000);
      expect(s.yagonaQr, isNull);
      expect(s.other, 0);
    });

    test('19-maydon (Kaftpay branchi) bor yozuv ham buzilmaydi — yagonaQr '
        '20 dan o\'qiladi', () {
      // `feat/kaftpay-xz-alohida` merge bo'lgach adapter 19 (kaftpay) ni ham
      // yozadi; bu versiya uni o'tkazib yuborishi va 20 ni to'g'ri o'qishi kerak.
      final w = BinaryWriterImpl(Hive);
      w.writeByte(21);
      for (var i = 0; i < 21; i++) {
        w.writeByte(i);
        w.write(i == 19 ? 1111 : (i == 20 ? 2222 : i));
      }
      final s = SalesSummaryHiveAdapter().read(BinaryReaderImpl(w.toBytes(), Hive));
      expect(s.yagonaQr, 2222);
      expect(s.other, 18);
    });

    test('toJson da yagonaqr bor', () {
      expect(SalesSummaryHive(yagonaQr: 12).toJson()['yagonaqr'], 12);
    });
  });
}
