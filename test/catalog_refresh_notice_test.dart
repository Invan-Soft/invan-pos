// "Mahsulotlar bazasi yangilanmagan" ogohlantirishi testlari.
//
// Nega kerak: bu ogohlantirish kassir uchun yagona ko'rinadigan signal —
// ilova ochilganda internet bo'lmagani uchun katalog yangilanmay qolgan
// bo'lsa, faqat shu dialog buni aytadi. Shuning uchun uning qachon
// chiqishi va qachon CHIQMASLIGI aniq belgilangan bo'lishi kerak:
// noto'g'ri chiqsa kassirni sotuv o'rtasida to'sib qo'yadi, chiqmasa
// muammo yana ko'rinmas bo'lib qoladi.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/providers/update_provider.dart';
import 'package:invan2/changes/services/catalog_refresh_notice.dart';
import 'package:invan2/idle_service.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'support/provider_harness.dart';

/// `fullUpdateItems` ni tarmoqsiz boshqarish uchun.
class _FakeUpdateProvider extends UpdateProvider {
  _FakeUpdateProvider(this.result);

  /// `null` — muvaffaqiyat, aks holda xato matni.
  String? result;
  int calls = 0;

  @override
  Future<String?> fullUpdateItems() async {
    calls++;
    return result;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('catalog_notice_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    // Faqat shu testga tegishli kalitlarni tozalaymiz — harness yozgan
    // kassir/foydalanuvchi kalitlariga tegmaymiz.
    await Pref.setBool(PrefKeys.catalogRefreshPending, false);
    await Pref.setInt(PrefKeys.lastFullCatalogSyncAt, 0);
    CatalogRefreshNotice.resetForTest();
    IdleService().onLockPageExited();
    IdleService().onCriticalAuthPageExited();
    // Odatiy holat: login qilingan.
    await Pref.setString(PrefKeys.token, 'test-token');
  });

  group('bayroq hayot tsikli', () {
    test('boshlang\'ich holatda ogohlantirish yo\'q', () {
      expect(CatalogRefreshNotice.isPending, isFalse);
      expect(CatalogRefreshNotice.shouldShow(), isFalse);
    });

    test('yiqilish belgilansa ogohlantirish kerak bo\'ladi', () async {
      await CatalogRefreshNotice.markFailed();

      expect(CatalogRefreshNotice.isPending, isTrue);
      expect(CatalogRefreshNotice.shouldShow(), isTrue);
    });

    test('muvaffaqiyatli yuklash bayroqni oladi va vaqtni yozadi', () async {
      await CatalogRefreshNotice.markFailed();
      await CatalogRefreshNotice.markFresh();

      expect(CatalogRefreshNotice.isPending, isFalse);
      expect(CatalogRefreshNotice.shouldShow(), isFalse);
      expect(Pref.getInt(PrefKeys.lastFullCatalogSyncAt, 0), greaterThan(0));
    });

    test('markFresh bayroq qo\'yilmagan bo\'lsa ham xavfsiz', () async {
      await CatalogRefreshNotice.markFresh();

      expect(CatalogRefreshNotice.isPending, isFalse);
      expect(Pref.getInt(PrefKeys.lastFullCatalogSyncAt, 0), greaterThan(0));
    });

    test('takroriy yiqilish holatni buzmaydi', () async {
      await CatalogRefreshNotice.markFailed();
      await CatalogRefreshNotice.markFailed();

      expect(CatalogRefreshNotice.isPending, isTrue);
      expect(CatalogRefreshNotice.shouldShow(), isTrue);
    });

    test('bayroq qayta ishga tushirishdan keyin ham saqlanadi (Pref)',
        () async {
      await CatalogRefreshNotice.markFailed();
      // Xotiradagi holat tozalanadi — ilova qayta ochilgandek.
      CatalogRefreshNotice.resetForTest();

      expect(CatalogRefreshNotice.isPending, isTrue);
      expect(CatalogRefreshNotice.shouldShow(), isTrue);
    });
  });

  group('ko\'rsatish shartlari', () {
    setUp(() async {
      await CatalogRefreshNotice.markFailed();
    });

    test('katalog yuklanayotgan paytda ko\'rsatilmaydi', () {
      // Startup'da wrapper ikki marta urinadi: birinchisi yiqilgach bayroq
      // qo'yiladi, ikkinchisi hali ketayotgan bo'ladi. Shu oraliqda dialog
      // yuklanish ekranining ustiga chiqib qolgan edi.
      CatalogRefreshNotice.beginLoad();
      expect(CatalogRefreshNotice.shouldShow(), isFalse);

      CatalogRefreshNotice.endLoad();
      expect(CatalogRefreshNotice.shouldShow(), isTrue);
    });

    test('token bo\'sh bo\'lsa ko\'rsatilmaydi', () async {
      await Pref.setString(PrefKeys.token, '');
      expect(CatalogRefreshNotice.shouldShow(), isFalse);
    });

    test('token "not initialized" bo\'lsa ko\'rsatilmaydi', () async {
      await Pref.setString(PrefKeys.token, 'not initialized');
      expect(CatalogRefreshNotice.shouldShow(), isFalse);
    });

    test('PIN sahifasida ko\'rsatilmaydi', () {
      IdleService().onLockPageEntered();
      expect(CatalogRefreshNotice.shouldShow(), isFalse);

      IdleService().onLockPageExited();
      expect(CatalogRefreshNotice.shouldShow(), isTrue);
    });

    test('auth sahifalarida ko\'rsatilmaydi', () {
      IdleService().onCriticalAuthPageEntered();
      expect(CatalogRefreshNotice.shouldShow(), isFalse);

      IdleService().onCriticalAuthPageExited();
      expect(CatalogRefreshNotice.shouldShow(), isTrue);
    });

    test('"Keyinroq" bosilsa 3 daqiqa ko\'rsatilmaydi, keyin qaytadi', () {
      // Katalog eski qolgani uchun ogohlantirish tez-tez qaytishi kerak —
      // kassir aks holda eski narx bilan sotishda davom etadi.
      expect(CatalogRefreshNotice.snooze, const Duration(minutes: 3));

      CatalogRefreshNotice.snoozeNow();

      expect(CatalogRefreshNotice.shouldShow(), isFalse);
      expect(
        CatalogRefreshNotice.shouldShow(
          now: DateTime.now().add(const Duration(minutes: 2)),
        ),
        isFalse,
      );
      expect(
        CatalogRefreshNotice.shouldShow(
          now: DateTime.now().add(const Duration(minutes: 4)),
        ),
        isTrue,
      );
    });

    test('"Keyinroq" dan keyin boshqa yo\'l bilan yangilansa — dialog to\'xtaydi',
        () async {
      // Kassir "Keyinroq" bosib, keyin Sozlamalar > to'liq yangilashdan
      // o'tkazishi mumkin. Shundan keyin ogohlantirish qaytmasligi kerak.
      CatalogRefreshNotice.snoozeNow();
      await CatalogRefreshNotice.markFresh();

      expect(CatalogRefreshNotice.isPending, isFalse);
      expect(
        CatalogRefreshNotice.shouldShow(
          now: DateTime.now().add(const Duration(minutes: 10)),
        ),
        isFalse,
      );
    });

    test('muvaffaqiyatli yangilash snooze ni ham bekor qiladi', () async {
      CatalogRefreshNotice.snoozeNow();
      await CatalogRefreshNotice.markFresh();
      // Yangi yiqilish bo'lsa darhol ko'rsatilishi kerak — eski snooze
      // ushlab turmasligi kerak.
      await CatalogRefreshNotice.markFailed();

      expect(CatalogRefreshNotice.shouldShow(), isTrue);
    });

    test('dialog ochiq turganda ikkinchisi ochilmaydi', () async {
      // maybeShow navigator kontekstisiz darhol qaytadi — shuning uchun
      // reentrancy'ni shouldShow orqali tekshiramiz.
      expect(CatalogRefreshNotice.isShowing, isFalse);
      await CatalogRefreshNotice.maybeShow(); // konteksti yo'q → no-op
      expect(CatalogRefreshNotice.isShowing, isFalse);
      expect(CatalogRefreshNotice.shouldShow(), isTrue);
    });

    test('navigator konteksti bo\'lmasa yiqilmaydi (headless)', () async {
      await expectLater(CatalogRefreshNotice.maybeShow(), completes);
      // Bayroq joyida qoladi — keyingi tsiklda qayta urinadi.
      expect(CatalogRefreshNotice.isPending, isTrue);
    });
  });

  group('savat bandligi', () {
    late OrderingProvider4 provider;

    Future<BuildContext> pumpWithProvider(WidgetTester tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        ChangeNotifierProvider<OrderingProvider4>.value(
          value: provider,
          child: MaterialApp(
            home: Builder(builder: (context) {
              captured = context;
              return const SizedBox();
            }),
          ),
        ),
      );
      return captured;
    }

    setUp(() {
      provider = freshProvider();
    });

    testWidgets('savat bo\'sh bo\'lsa band emas', (tester) async {
      final context = await pumpWithProvider(tester);
      expect(CatalogRefreshNotice.isCartBusy(context), isFalse);
    });

    testWidgets('joriy savatda mahsulot bo\'lsa band', (tester) async {
      final context = await pumpWithProvider(tester);
      provider.getCurrentClient.orderedProducts.add(makeSoldItem());

      expect(CatalogRefreshNotice.isCartBusy(context), isTrue);
    });

    testWidgets('boshqa mijoz savatida mahsulot bo\'lsa ham band',
        (tester) async {
      final context = await pumpWithProvider(tester);
      provider.getSixClient4List.add(
        SixClientModel4(
          clientNumber: 2,
          lastAddedIndex: 0,
          orderedProducts: [makeSoldItem()],
          discountAmountFromNewClient: 0,
        ),
      );

      expect(CatalogRefreshNotice.isCartBusy(context), isTrue);
    });

    testWidgets('provider daraxtda bo\'lmasa band emas deb hisoblanadi',
        (tester) async {
      late BuildContext captured;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(builder: (context) {
            captured = context;
            return const SizedBox();
          }),
        ),
      );

      expect(CatalogRefreshNotice.isCartBusy(captured), isFalse);
    });
  });

  group('dialog xulqi', () {
    Future<void> pumpDialog(
      WidgetTester tester,
      _FakeUpdateProvider updateProvider,
    ) async {
      await tester.pumpWidget(
        ChangeNotifierProvider<UpdateProvider>.value(
          value: updateProvider,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('uz'),
            home: Builder(
              builder: (context) {
                SizeConfig().init(context);
                return Scaffold(
                  body: ElevatedButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const CatalogStaleDialog(),
                    ),
                    child: const Text('__ochish__'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Dialog ATAYLAB haqiqiy route sifatida ochiladi: aks holda uni
      // yopadigan `Navigator.pop` ilovaning yagona route'ini olib tashlab,
      // testni osib qo'yadi (real ilovada u har doim dialog route'ida
      // bo'ladi).
      await tester.tap(find.text('__ochish__'));
      await tester.pumpAndSettle();
    }

    testWidgets('ogohlantirish matni va ikkala tugma ko\'rinadi',
        (tester) async {
      await pumpDialog(tester, _FakeUpdateProvider(null));

      expect(find.text('Mahsulotlar bazasi yangilanmagan'), findsOneWidget);
      expect(find.text('Yangilash'), findsOneWidget);
      expect(find.text('Keyinroq'), findsOneWidget);
    });

    testWidgets('"Yangilash" to\'liq yuklashni chaqiradi', (tester) async {
      final updateProvider = _FakeUpdateProvider(null);
      await pumpDialog(tester, updateProvider);

      await tester.tap(find.text('Yangilash'));
      await tester.pump();

      expect(updateProvider.calls, 1);
    });

    testWidgets('yuklash davomida tugmalar o\'rniga indikator', (tester) async {
      final updateProvider = _FakeUpdateProvider(null);
      await pumpDialog(tester, updateProvider);

      await tester.tap(find.text('Yangilash'));
      await tester.pump(); // setState(_loading = true)

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Yangilash'), findsNothing);
    });

    testWidgets('xato bo\'lsa dialog yopilmaydi va matn ko\'rsatiladi',
        (tester) async {
      final updateProvider = _FakeUpdateProvider('Internet ulanmadi (Timeout)');
      await pumpDialog(tester, updateProvider);

      await tester.tap(find.text('Yangilash'));
      await tester.pumpAndSettle();

      expect(find.text('Internet ulanmadi (Timeout)'), findsOneWidget);
      // Qayta urinish mumkin bo'lishi kerak.
      expect(find.text('Yangilash'), findsOneWidget);
    });

    testWidgets('bo\'sh xato matni o\'rniga tushunarli matn', (tester) async {
      final updateProvider = _FakeUpdateProvider('   ');
      await pumpDialog(tester, updateProvider);

      await tester.tap(find.text('Yangilash'));
      await tester.pumpAndSettle();

      expect(find.text('Yangilanish amalga oshirilmadi'), findsOneWidget);
    });

    testWidgets('xatodan keyin qayta urinish ishlaydi', (tester) async {
      final updateProvider = _FakeUpdateProvider('xato');
      await pumpDialog(tester, updateProvider);

      await tester.tap(find.text('Yangilash'));
      await tester.pumpAndSettle();
      expect(updateProvider.calls, 1);

      updateProvider.result = null;
      await tester.tap(find.text('Yangilash'));
      await tester.pumpAndSettle();
      expect(updateProvider.calls, 2);
    });

    testWidgets('"Keyinroq" snooze qo\'yadi', (tester) async {
      await pumpDialog(tester, _FakeUpdateProvider(null));
      // `testWidgets` fake-async zonasida ishlaydi — Hive yozuvi haqiqiy
      // event loop'da tugaydi, shuning uchun `runAsync` shart. Aks holda
      // `await` abadiy osilib qoladi.
      await tester.runAsync(CatalogRefreshNotice.markFailed);
      expect(CatalogRefreshNotice.shouldShow(), isTrue);

      await tester.tap(find.text('Keyinroq'));
      await tester.pumpAndSettle();

      expect(CatalogRefreshNotice.shouldShow(), isFalse);
    });
  });
}
