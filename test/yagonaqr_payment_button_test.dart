// YagonaQr — to'lov ekranidagi tugma (KeyboardOfPaymentPage._buildPayments).
//
// `PrefKeys.yagonaQrId` dagi tur uchun alohida tugma: matni admin `title`
// (bo'sh bo'lsa "YagonaQR"), bosilganda `typeYagonaQr` — summa YagonaQr
// id'si bilan yoziladi, cardType 2. Fiskalda karta bo'lgani uchun "faqat
// karta" (kommunal MXIK) rejimida ham ko'rinadi.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/payment/right/complete_button/complete_bloc/comlete_bloc.dart';
import 'package:invan2/features/payment/right/complete_button/pre_complete_bloc/per_comlete_bloc.dart';
import 'package:invan2/features/payment/right/keyboard_of_payment_page.dart';
import 'package:invan2/utils/constants/mxik_constants.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'support/provider_harness.dart';

const kCashId = 'cash-id';
const kYagonaId = 'yagona-qr-id';

final cashPayment =
    Payment(id: kCashId, name: 'CASH', title: 'Naqd', isAdded: true);

Payment yagonaPayment({String? title = 'Yagona QR', bool? isAdded = true}) =>
    Payment(
        id: kYagonaId, name: 'YagonaQr', title: title, isAdded: isAdded);

OrderingProvider4 paymentPage(List<ReceiptModelSoldItem4> rows,
    {double total = 100000}) {
  // goToPaymentPage dagidek: to'lov sahifasi joriy klient savati bilan ochiladi
  final p = freshProvider();
  p.getCurrentClient.orderedProducts.addAll(rows);
  p.initPaymentPageValues(
    sixClientModel4: p.getCurrentClient,
    totalPrice: total,
    discountAmount: 0,
  );
  return p;
}

Future<void> pumpKeyboard(WidgetTester tester, OrderingProvider4 p) async {
  tester.view.physicalSize = const Size(1920, 1080);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<OrderingProvider4>.value(value: p),
        BlocProvider<CmtBBloc>(create: (_) => CmtBBloc()),
        BlocProvider<PreCmtBBloc>(create: (_) => PreCmtBBloc()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('uz'),
        home: Builder(builder: (context) {
          SizeConfig().init(context);
          return Scaffold(body: KeyboardOfPaymentPage(context));
        }),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('yagonaqr_payment_button');
    // VisibilityDetector taymeri test oxirida "pending timer" qoldirmasin
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    await Pref.setString(PrefKeys.cashId, kCashId);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await Pref.setString(PrefKeys.yagonaQrId, kYagonaId);
    otherPaymentsGlobal = [cashPayment, yagonaPayment()];
  });
  tearDown(() => otherPaymentsGlobal = []);

  testWidgets('tugma admin title bilan chiqadi', (tester) async {
    await pumpKeyboard(tester, paymentPage([makeSoldItem(productId: 'a')]));
    expect(find.text('Yagona QR'), findsOneWidget);
    expect(find.text('YagonaQr'), findsNothing); // xom name emas
  });

  testWidgets('admin "Apps" da o\'chirilgan (isAdded: false) — tugma yo\'q',
      (tester) async {
    otherPaymentsGlobal = [cashPayment, yagonaPayment(isAdded: false)];
    await pumpKeyboard(tester, paymentPage([makeSoldItem(productId: 'a')]));
    expect(find.text('Yagona QR'), findsNothing);
    expect(find.text('YagonaQr'), findsNothing); // umumiy tugma ham emas
    expect(find.text('Naqd pul'), findsOneWidget);
  });

  testWidgets('holati noma\'lum (isAdded: null) — tugma yo\'q', (tester) async {
    otherPaymentsGlobal = [cashPayment, yagonaPayment(isAdded: null)];
    await pumpKeyboard(tester, paymentPage([makeSoldItem(productId: 'a')]));
    expect(find.text('Yagona QR'), findsNothing);
    expect(find.text('YagonaQr'), findsNothing);
  });

  testWidgets('title bo\'sh — "YagonaQR"', (tester) async {
    otherPaymentsGlobal = [cashPayment, yagonaPayment(title: '  ')];
    await pumpKeyboard(tester, paymentPage([makeSoldItem(productId: 'a')]));
    expect(find.text('YagonaQR'), findsOneWidget);
  });

  testWidgets('bosilganda qoldiq YagonaQr id\'si bilan yoziladi, cardType 2',
      (tester) async {
    final p = paymentPage([makeSoldItem(productId: 'a')]);
    await pumpKeyboard(tester, p);

    await tester.tap(find.text('Yagona QR'));
    await tester.pump();

    expect(p.paymentsMap.keys, [kYagonaId]);
    final row = p.paymentsMapAsList.single;
    expect(row.name, 'YAGONAQR');
    expect(row.payId, kYagonaId);
    expect(row.value, 100000);
    expect(p.lastCardType, 2);
  });

  testWidgets('aralash: naqd 30 000 (klaviatura) + YagonaQr qoldiq',
      (tester) async {
    final p = paymentPage([makeSoldItem(productId: 'a')]);
    await pumpKeyboard(tester, p);

    p.controller.text = '30000';
    await tester.tap(find.text('Naqd pul'));
    await tester.pump();
    await tester.tap(find.text('Yagona QR'));
    await tester.pump();

    final byId = {for (final e in p.paymentsMapAsList) e.payId: e};
    expect(byId[kCashId]?.name, 'CASH');
    expect(byId[kCashId]?.value, 30000);
    expect(byId[kYagonaId]?.name, 'YAGONAQR');
    expect(byId[kYagonaId]?.value, 70000);
  });

  testWidgets('"faqat karta" (kommunal MXIK): YagonaQr ko\'rinadi, naqd yo\'q',
      (tester) async {
    final kommunal = makeSoldItem(
        productId: 'k', mxik: MxikConstants.cardOnlyMxikCodes.first);
    final p = paymentPage([kommunal]);
    await pumpKeyboard(tester, p);

    expect(p.isCardOnlyPaymentRequired, isTrue);
    expect(find.text('Yagona QR'), findsOneWidget);
    expect(find.text('Naqd pul'), findsNothing);
  });

  testWidgets('serverdan YagonaQr umuman kelmasa (eski id qolgan bo\'lsa ham) — tugma yo\'q',
      (tester) async {
    otherPaymentsGlobal = [cashPayment]; // payment_types da YagonaQr yo'q
    await pumpKeyboard(tester, paymentPage([makeSoldItem(productId: 'a')]));
    expect(find.text('Yagona QR'), findsNothing);
    expect(find.text('YagonaQR'), findsNothing);
    expect(find.text('YagonaQr'), findsNothing);
    expect(find.text('Naqd pul'), findsOneWidget);
  });

  testWidgets('yagonaQrId sozlanmagan — oddiy tugma (xom nom), cardType 0',
      (tester) async {
    // Hive yozuvi fake-async zonada tugamaydi — haqiqiy async'da.
    await tester.runAsync(() => Pref.setString(PrefKeys.yagonaQrId, ''));
    final p = paymentPage([makeSoldItem(productId: 'a')]);
    await pumpKeyboard(tester, p);

    expect(find.text('YagonaQr'), findsOneWidget); // eski umumiy tugma
    await tester.tap(find.text('YagonaQr'));
    await tester.pump();
    expect(p.paymentsMap.keys, [kYagonaId]);
    expect(p.lastCardType, 0);
  });
}
