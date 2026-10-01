// Regression: bo'sh klient tanlash orqali access-siz mahsulot o'chirish
// (kassir hiylasi, 2026-09-30 da fix qilindi).
//
// Bug tarixi: selectClient() tanlangan bo'sh klientni _clearEmptyClients()
// bilan ro'yxatdan chiqarib, _currentClient'ni detached qoldirardi (savat UI
// bo'sh ko'rinardi — mahsulot "yo'qolardi"); keyingi to'lovda
// _paymentOnClients() indeks bo'yicha _sixClient4List[0] ni tozalab,
// 1-klientning mahsulotini access kodisiz va deletedItems/orphan yozuvisiz
// o'chirardi. 3+ klientda dangling _index RangeError ham berardi.
//
// Fix: selectClient tanlangan klientni ro'yxatda saqlaydi (keep) va _index'ni
// identity'dan qayta hisoblaydi; _paymentOnClients indeks emas,
// _currentClient (to'lagan klient) bo'yicha tozalaydi.
// Hujjat: docs/sessions/2026-09-30-multi-klient-access-bypass-fix.md
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('multi_client_access_bypass_regression'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() => Pref.setBool(PrefKeys.isRedDeleteActivated, false));

  test('bo\'sh klient tanlansa ro\'yxatda qoladi — current uzilmaydi', () {
    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
    p.addClient(); // list=[c1,c2], current=c2(bo'sh), index=1

    p.selectClient(1); // kassir "Mijoz 2" tugmasini bosdi

    // Bo'sh klient tanlangan bo'lsa ro'yxatdan CHIQMAYDI
    expect(p.getSixClient4List.length, 2);
    expect(p.getSixClient4List.contains(p.getCurrentClient), isTrue);
    expect(p.getSelectedIndex, 1);
    // 1-klient mahsuloti joyida
    expect(p.getSixClient4List.first.orderedProducts.length, 1);
  });

  testWidgets(
      'bo\'sh klient tanlangan holatda to\'lov — 1-klient savati saqlanadi',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final ctx = tester.element(find.byType(SizedBox));

    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
    final client1 = p.getCurrentClient;
    p.addClient();
    p.selectClient(1); // bo'sh "Mijoz 2" tanlandi (hiyla urinishi)

    // Kassir keyingi xaridorning mahsulotini skanladi
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'x'));

    p.initPaymentPageValues(
      sixClientModel4: p.getCurrentClient,
      totalPrice: 5000,
      discountAmount: 0,
    );
    await p.pressPaymentButton(ctx);

    // 1-klient mahsuloti to'lovdan keyin ham JOYIDA — jimgina o'chmaydi
    expect(client1.orderedProducts.length, 1);
    expect(client1.orderedProducts.first.productId, 'a');
    expect(p.getSixClient4List, [client1]);
    expect(p.getCurrentClient, same(client1));
    expect(p.getSelectedIndex, 0);
  });

  test('o\'rtadagi bo\'sh klient o\'chganda _index qayta hisoblanadi', () {
    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
    p.addClient();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));
    p.addClient();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'c'));
    // list=[c1(a), c2(b), c3(c)], index=2

    // c2 savati boshqa yo'l bilan bo'shadi (masalan PIN bilan o'chirilgan)
    p.getSixClient4List[1].orderedProducts.clear();

    p.selectClient(2); // kassir "Mijoz 3" ni bosdi

    // c2 chiqib ketdi, _index endi currentning REAL o'rnini ko'rsatadi
    expect(p.getSixClient4List.length, 2);
    expect(p.getSelectedIndex, 1);
    expect(p.getSixClient4List[1], same(p.getCurrentClient));
    expect(p.getCurrentClient.orderedProducts.first.productId, 'c');
  });

  testWidgets(
      'ko\'p klientda to\'lov faqat to\'lagan klient savatini tozalaydi',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final ctx = tester.element(find.byType(SizedBox));

    final p = freshProvider();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
    final client1 = p.getCurrentClient;
    p.addClient();
    p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));
    // list=[c1(a), c2(b)], current=c2, index=1

    p.initPaymentPageValues(
      sixClientModel4: p.getCurrentClient,
      totalPrice: 5000,
      discountAmount: 0,
    );
    await p.pressPaymentButton(ctx);

    // Faqat c2 (to'lagan) tozalanib chiqdi; c1 mahsuloti bilan joriy bo'ldi
    expect(p.getSixClient4List, [client1]);
    expect(p.getCurrentClient, same(client1));
    expect(p.getSelectedIndex, 0);
    expect(client1.orderedProducts.first.productId, 'a');
  });
}
