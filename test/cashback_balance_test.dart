// Cashback (bonus karta) balans chegarasi testi.
//
// MUAMMO (2026-08-12): "Bonus karta" tugmasi bir necha marta bosilganda
// balans tekshiruvi faqat SHU bosishdagi songa nisbatan qilinardi, chekka
// allaqachon kiritilgan cashback esa hisobga olinmasdi. `allPaymentType`
// yangi summani eskisining ustiga qo'shgani uchun yig'indi balansdan oshib
// ketardi (real holat: balans 78 000 -> chekka 131 000 cashback).
//
// Bu yerdagi testlar `typeFromCashbackBalance` ni REAL holida chaqiradi,
// shuning uchun widget test: unga BuildContext va AppLocalizations kerak
// (ichida ScaffoldMessenger orqali snackbar ko'rsatiladi).
//
// Hujjat: docs/sessions/2026-08-12-cashback-overspend-fix.md
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';

import 'support/provider_harness.dart';

const kCashbackId = 'cashback-id';
const kCardId = 'card-id';

Payment cashback() => Payment(
      id: kCashbackId,
      name: 'CASHBACK',
      title: 'Bonus karta',
      type: 0,
      enable: true,
    );

Payment card() => Payment(
      id: kCardId,
      name: 'Karta',
      title: 'Karta',
      type: 0,
      enable: true,
    );

/// To'lov sahifasi + tanlangan mijoz (balans bilan).
OrderingProvider4 paymentPage({
  double total = 100000,
  num balance = 78000,
}) {
  final p = freshProvider();
  p.initPaymentPageValues(
    sixClientModel4: SixClientModel4(
      clientNumber: 1,
      lastAddedIndex: -1,
      orderedProducts: [],
      discountAmountFromNewClient: 0,
      selectedClient: ClientModel(
        id: 'client-1',
        firstName: 'Test',
        lastName: 'Mijoz',
        pointBalance: balance,
      ),
    ),
    totalPrice: total,
    discountAmount: 0,
  );
  return p;
}

/// Klaviaturada summa terish (onNumPressed raqamma-raqam ishlaydi).
void typeAmount(OrderingProvider4 p, String digits) {
  for (final ch in digits.split('')) {
    p.onNumPressed(int.parse(ch));
  }
}

/// `typeFromCashbackBalance` uchun kerakli BuildContext.
Future<BuildContext> localizedContext(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('uz'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(builder: (c) {
          captured = c;
          // `mySnackBar` SizeConfig.h/v ni o'qiydi — initsializatsiyasiz
          // LateInitializationError beradi.
          SizeConfig().init(c);
          return const SizedBox.shrink();
        }),
      ),
    ),
  );
  return captured;
}

/// Snackbar animatsiyasi va avto-yopilish taymerini oxirigacha o'tkazadi —
/// aks holda test oxirida "A Timer is still pending" xatosi chiqadi.
Future<void> drainSnackBar(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// Chekdagi cashback qatorining qiymati (yo'q bo'lsa null).
double? cashbackValue(OrderingProvider4 p) => p.paymentsMap[kCashbackId]?.value;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('cashback_balance_test');
    await Pref.setString(PrefKeys.cashbackId, kCashbackId);
    await Pref.setString(PrefKeys.cardId, kCardId);
    await Pref.setString(PrefKeys.cashId, 'cash-id');
  });
  tearDownAll(tearDownPosTestEnv);

  group('Bitta bosish', () {
    testWidgets('balansdan katta summa rad etiladi', (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 100000, balance: 78000);

      typeAmount(p, '90000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), isNull);
      expect(p.getMustPay, 100000);
    });

    testWidgets('to\'liq balansni bir bosishda ishlatish mumkin',
        (tester) async {
      // Avval `balance > parsed` (qat'iy) edi — balansning aynan o'zini
      // kiritib bo'lmasdi va kassir summani bo'lishga majbur bo'lardi.
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 100000, balance: 78000);

      typeAmount(p, '78000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 78000);
      expect(p.getMustPay, 22000);
    });

    testWidgets('balansdan kichik summa o\'tadi', (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 100000, balance: 78000);

      typeAmount(p, '50000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 50000);
    });
  });

  group('REGRESSIYA — ko\'p marta bosish balansdan oshib ketmasin', () {
    testWidgets('50000 + 50000, balans 78000: ikkinchisi rad etiladi',
        (tester) async {
      // Bug'ning aynan o'zi: ilgari 50 000 + 50 000 = 100 000 o'tib ketardi.
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 100000, balance: 78000);

      typeAmount(p, '50000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);
      expect(cashbackValue(p), 50000);

      typeAmount(p, '50000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 50000, reason: 'qoldiq balans faqat 28 000');
      expect(p.getMustPay, 50000);
    });

    testWidgets('foydalanuvchidagi holat: 70000 + 61000 -> 131000 bo\'lmaydi',
        (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 200000, balance: 78000);

      typeAmount(p, '70000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      typeAmount(p, '61000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 70000);
      expect(cashbackValue(p), lessThanOrEqualTo(78000));
    });

    testWidgets('qoldiq balansgacha bo\'lib kiritish ishlaydi', (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 100000, balance: 78000);

      typeAmount(p, '50000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      typeAmount(p, '28000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 78000, reason: 'aynan balansgacha to\'lidi');
      expect(p.getMustPay, 22000);
    });

    testWidgets('uch marta bosish ham chegaradan chiqmaydi', (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 300000, balance: 78000);

      for (var i = 0; i < 3; i++) {
        typeAmount(p, '40000');
        p.typeFromCashbackBalance(ctx, cashback());
        await drainSnackBar(tester);
      }

      expect(cashbackValue(p), 40000, reason: '2- va 3- bosish rad etiladi');
    });
  });

  group('Summa kiritilmagan (butun qoldiqni yopish)', () {
    testWidgets('chek jami balansdan katta bo\'lsa rad etiladi',
        (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 100000, balance: 78000);

      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), isNull);
    });

    testWidgets('chek jami balansdan kichik bo\'lsa to\'liq yopiladi',
        (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 50000, balance: 78000);

      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 50000);
      expect(p.getMustPay, 0);
      expect(p.getIsButtonEnabled, isTrue);
    });

    testWidgets('boshqa to\'lov qoldiqni balansdan pastga tushirsa o\'tadi',
        (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 100000, balance: 78000);

      // Avval karta bilan 40 000 -> qoldiq 60 000 <= 78 000
      typeAmount(p, '40000');
      p.allPaymentType(card());

      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 60000);
      expect(p.getMustPay, 0);
    });
  });

  group('Chetki holatlar', () {
    testWidgets('cashback qatori o\'chirilsa hisob nolga qaytadi',
        (tester) async {
      // `used` chekdagi joriy qatordan olinadi — qator o'chirilsa butun
      // balans yana bo'shashi kerak, aks holda kassir xatosini tuzata olmaydi.
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 200000, balance: 78000);

      typeAmount(p, '78000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);
      expect(cashbackValue(p), 78000);

      p.removeFromPaymentList();
      expect(cashbackValue(p), isNull);

      typeAmount(p, '78000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 78000);
    });

    testWidgets('boshqa to\'lov turi orasiga kirsa ham hisob buzilmaydi',
        (tester) async {
      // `_selectedPaymentType` karta bosilganda o'zgaradi; cashback tugmasi
      // uni qaytadan o'ziga qo'yadi, shuning uchun `getSelectedPaymentSumma`
      // aynan cashback qatorini o'qishi shart.
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 300000, balance: 78000);

      typeAmount(p, '50000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      typeAmount(p, '100000');
      p.allPaymentType(card());

      typeAmount(p, '50000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 50000, reason: 'qoldiq balans 28 000 edi');
      expect(p.paymentsMap[kCardId]?.value, 100000);
    });

    testWidgets('kasrli balans: tiyingacha aniq cheklanadi', (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 200000, balance: 78000.5);

      typeAmount(p, '78000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);
      expect(cashbackValue(p), 78000);

      // Qoldiq atigi 0.5 — yana 1 so'm o'tmasligi kerak.
      typeAmount(p, '1');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 78000);
    });

    testWidgets('balans chek jamisiga teng: to\'liq yopiladi, oshmaydi',
        (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 78000, balance: 78000);

      typeAmount(p, '78000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 78000);
      expect(p.getMustPay, 0);
      expect(p.getIsButtonEnabled, isTrue);

      // Yana bosilsa qo'shilmasligi kerak (chek ham, balans ham to'lgan).
      typeAmount(p, '1000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), 78000);
    });
  });

  group('Mijoz yoki balans yo\'q', () {
    testWidgets('mijoz tanlanmagan: hech narsa qo\'shilmaydi', (tester) async {
      final ctx = await localizedContext(tester);
      final p = freshProvider();
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

      typeAmount(p, '10000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), isNull);
    });

    testWidgets('balans 0: hech narsa qo\'shilmaydi', (tester) async {
      final ctx = await localizedContext(tester);
      final p = paymentPage(total: 100000, balance: 0);

      typeAmount(p, '10000');
      p.typeFromCashbackBalance(ctx, cashback());
      await drainSnackBar(tester);

      expect(cashbackValue(p), isNull);
    });
  });
}
