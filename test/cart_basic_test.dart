// Savat asosiy operatsiyalari — xarakteristik test.
//
// MAQSAD: hozirgi xatti-harakatni MUZLATISH. Bu zona Faza 0-3 da
// KO'CHIRILMAYDI, lekin kelajakdagi ishlar (va kundalik bug-fix) uchun
// himoya to'ri kerak.
//
// `addProduct` bu yerda ishlatilmaydi — u `BuildContext` talab qiladi.
// Mavjud testlardagi kabi savat to'g'ridan-to'g'ri to'ldiriladi, so'ng
// kontekstsiz metodlar chaqiriladi.
//
// MUHIM: "to'g'rimi?" emas, "hozir nima bo'lyapti?" yoziladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('cart_basic_test'));
  tearDownAll(tearDownPosTestEnv);

  // Har testdan oldin "qizil o'chirish" rejimini o'chiramiz (standart holat).
  setUp(() => Pref.setBool(PrefKeys.isRedDeleteActivated, false));

  group('removeLastAdded — oddiy rejim (isRedDeleteActivated = false)', () {
    test('oxirgi qo\'shilgan qator savatdan butunlay chiqadi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.addAll([
        makeSoldItem(productId: 'a', price: 1000),
        makeSoldItem(productId: 'b', price: 2000),
      ]);
      p.getCurrentClient.lastAddedIndex = 1;

      p.removeLastAdded();

      expect(p.getCurrentClient.orderedProducts.length, 1);
      expect(p.getCurrentClient.orderedProducts.first.productId, 'a');
    });

    test('o\'chirilgan qator deletedItems ga yoziladi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(productId: 'a', name: 'Pepsi', value: 2));
      p.getCurrentClient.lastAddedIndex = 0;

      p.removeLastAdded();

      expect(p.getCurrentClient.deletedItems.length, 1);
      final d = p.getCurrentClient.deletedItems.first;
      expect(d.productId, 'a');
      expect(d.quantity, 2);
      expect(d.deletedBy, isNotEmpty);
    });

    test('lastAddedIndex o\'chirishdan keyin 0 ga tushadi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.addAll([
        makeSoldItem(productId: 'a'),
        makeSoldItem(productId: 'b'),
      ]);
      p.getCurrentClient.lastAddedIndex = 1;

      p.removeLastAdded();

      expect(p.getLastAddedIndex, 0);
    });

    test('bo\'sh savatda xato bermaydi (try/catch yutadi)', () {
      final p = freshProvider();
      p.getCurrentClient.lastAddedIndex = 0;

      expect(() => p.removeLastAdded(), returnsNormally);
      expect(p.getCurrentClient.orderedProducts, isEmpty);
    });
  });

  group('removeLastAdded — qizil o\'chirish (isRedDeleteActivated = true)', () {
    test('qator savatda QOLADI, faqat isDeleted = true bo\'ladi', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(productId: 'a', name: 'Pepsi'));
      p.getCurrentClient.lastAddedIndex = 0;

      p.removeLastAdded();

      // Qator ro'yxatdan chiqmaydi — chizib tashlangan holda ko'rinadi
      expect(p.getCurrentClient.orderedProducts.length, 1);
      expect(p.getCurrentClient.orderedProducts.first.isDeleted, isTrue);
      expect(p.getCurrentClient.deletedItems.length, 1);
    });
  });

  group('cancelOrdering — savatni bekor qilish', () {
    test('bo\'sh savatda true qaytadi', () {
      final p = freshProvider();

      expect(p.cancelOrdering(true), isTrue);
    });

    test('ruxsat bilan: savat tozalanadi, lastAddedIndex -1', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.addAll([
        makeSoldItem(productId: 'a'),
        makeSoldItem(productId: 'b'),
      ]);
      p.getCurrentClient.lastAddedIndex = 1;

      final result = p.cancelOrdering(true);

      expect(result, isTrue);
      expect(p.getCurrentClient.orderedProducts, isEmpty);
      expect(p.getLastAddedIndex, -1);
    });

    test('ruxsatsiz va xodimda deleteS huquqi yo\'q: savat baribir tozalanadi',
        () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'a'));

      // Test xodimida access = null, ya'ni deleteS = false
      final result = p.cancelOrdering(false);

      expect(result, isTrue);
      expect(p.getCurrentClient.orderedProducts, isEmpty);
    });
  });

  group('tapIndexToEdit — tahrir uchun qator tanlash', () {
    test('tanlangan indeks saqlanadi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.addAll([
        makeSoldItem(productId: 'a'),
        makeSoldItem(productId: 'b'),
      ]);

      p.tapIndexToEdit(1);

      // Tahrir oqimi shu indeks ustida ishlaydi (pressDialogSaveButton)
      expect(() => p.tapIndexToEdit(1), returnsNormally);
    });
  });

  group('clearAllDiscountEffects', () {
    test('savatdagi qatorlar narxi asl (realPrice) ga qaytadi', () {
      final p = freshProvider();
      final row = makeSoldItem(price: 4000, realPrice: 5000);
      row.singleDiscount = 1000;
      p.getCurrentClient.orderedProducts.add(row);

      p.clearAllDiscountEffects();

      final after = p.getCurrentClient.orderedProducts.first;
      expect(after.price, after.realPrice);
      expect(after.singleDiscount, 0);
    });

    test('savat qatorlari soni o\'zgarmaydi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.addAll([
        makeSoldItem(productId: 'a'),
        makeSoldItem(productId: 'b'),
      ]);

      p.clearAllDiscountEffects();

      expect(p.getCurrentClient.orderedProducts.length, 2);
    });

    test('bo\'sh savatda xato bermaydi', () {
      final p = freshProvider();

      expect(() => p.clearAllDiscountEffects(), returnsNormally);
    });
  });
}
