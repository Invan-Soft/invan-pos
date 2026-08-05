// Ko'p-mijoz (6 slot) rejimi — xarakteristik test.
//
// MAQSAD: hozirgi xatti-harakatni MUZLATISH. Bu zona Faza 0-3 da
// ko'chirilmaydi, lekin savat holatining eng chalkash qismi — bo'sh slotlar
// avtomatik yo'q qilinadi va ulardagi o'chirish yozuvlari "orphan" ro'yxatga
// ko'chiriladi. Kelajakdagi har qanday o'zgarish shu testlarga urilishi kerak.
//
// MUHIM: "to'g'rimi?" emas, "hozir nima bo'lyapti?" yoziladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('multi_client_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() => Pref.setBool(PrefKeys.isRedDeleteActivated, false));

  group('addClient — yangi slot ochish', () {
    test('savat bo\'sh bo\'lsa yangi slot OCHILMAYDI', () {
      final p = freshProvider();

      p.addClient();

      expect(p.getSixClient4List, isEmpty);
    });

    test('savatda mahsulot bo\'lsa: joriy + yangi = 2 slot', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));

      p.addClient();

      expect(p.getSixClient4List.length, 2);
      // Joriy slot yangi (bo'sh) slotga o'tadi
      expect(p.getCurrentClient.orderedProducts, isEmpty);
      expect(p.getSelectedIndex, 1);
    });

    test('slot raqamlari ketma-ket o\'sadi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));
      p.addClient();

      expect(p.getSixClient4List.length, 3);
      expect(
        p.getSixClient4List.map((e) => e.clientNumber).toList(),
        [1, 2, 3],
      );
    });

    test('har slotning savati mustaqil', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(productId: 'a', price: 1000));
      p.addClient();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(productId: 'b', price: 2000));

      expect(p.getSixClient4List[0].orderedProducts.first.productId, 'a');
      expect(p.getSixClient4List[1].orderedProducts.first.productId, 'b');
    });
  });

  group('selectClient — slot almashtirish', () {
    test('tanlangan slot joriy bo\'ladi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));

      p.selectClient(0);

      expect(p.getCurrentClient.orderedProducts.first.productId, 'a');
      expect(p.getSelectedIndex, 0);
    });

    test('to\'lgan slotlar orasida almashish ro\'yxatni o\'zgartirmaydi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));

      p.selectClient(0);
      p.selectClient(1);

      expect(p.getSixClient4List.length, 2);
    });
  });

  group('Bo\'sh slotlar avtomatik yo\'q qilinadi', () {
    test('slot bo\'shab qolsa, boshqasiga o\'tishda ro\'yxatdan chiqadi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));
      expect(p.getSixClient4List.length, 2);

      // 1-slotni bo'shatamiz
      p.getSixClient4List[0].orderedProducts.clear();
      p.selectClient(1);

      expect(p.getSixClient4List.length, 1);
      expect(p.getSixClient4List.first.orderedProducts.first.productId, 'b');
    });
  });

  group('Orphan deleted_items — slot yo\'qolganda yozuv saqlanadi', () {
    test('bo\'sh slotdagi o\'chirish yozuvi orphan ro\'yxatga ko\'chadi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));

      // 1-slotdagi yagona mahsulotni o'chiramiz -> slot bo'shaydi
      p.selectClient(0);
      p.getCurrentClient.lastAddedIndex = 0;
      p.removeLastAdded();
      expect(p.getCurrentClient.deletedItems.length, 1);

      // Boshqa slotga o'tamiz -> bo'sh slot yo'qoladi, yozuv saqlanadi
      p.selectClient(1);

      expect(p.getOrphanDeletedItems.length, 1);
      expect(p.getOrphanDeletedItems.first.productId, 'a');
    });

    test('chek raqami olmagan orphan yozuvga "-" qo\'yiladi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));

      p.selectClient(0);
      p.getCurrentClient.lastAddedIndex = 0;
      p.removeLastAdded();
      p.selectClient(1);

      // "-" = sotilmasdan o'chirilgan; keyingi chek raqamini o'zlashtirmaydi
      expect(p.getOrphanDeletedItems.first.checkNumber, '-');
    });

    test('bir mijoz orphani boshqasining savatiga o\'tmaydi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));
      p.addClient();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'b'));

      p.selectClient(0);
      p.getCurrentClient.lastAddedIndex = 0;
      p.removeLastAdded();
      p.selectClient(1);

      // 2-slotning o'z deletedItems ro'yxati toza qoladi
      expect(p.getCurrentClient.deletedItems, isEmpty);
      expect(p.getOrphanDeletedItems.length, 1);
    });
  });
}
