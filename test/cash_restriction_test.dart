// Naqd to'lovni yashirish/bloklash qoidalari.
//
// Bu to'rt getter to'lov ekranida naqd tugmasini ko'rsatish/yashirishni hal
// qiladi (`keyboard_of_payment_page.dart`). Ular sof qoidalar: savat + Pref +
// katalog. Faza 9 da alohida modulga ko'chiriladi — shuning uchun avval
// HOZIRGI xatti-harakat to'liq muzlatiladi.
//
// Qamrov: har getterning har bir `if` shoxi, chegaraviy qiymatlar (25 mln,
// cashsale 0/1/null), o'chirilgan qatorlar, bo'sh savat va Pref gate'lari.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kCashsaleOffMxik = '02202001001000000'; // oddiy tovar
const kAlcoholMxik = '02203001001000000'; // 02203 → alkogol guruhi
const kCardOnlyMxik = '09905001001000000'; // elektr energiya (faqat karta)

/// `cashsale` bayrog'i bilan katalog mahsuloti.
ItemModel productWithCashsale(String id, int? cashsale) {
  final m = ItemModel();
  m.id = id;
  m.name = 'Test $id';
  m.cashsale = cashsale;
  return m;
}

/// Cashsale getterlari uchun ikkala Pref gate'ini yoqadi.
Future<void> enableCashsaleGates() async {
  await Pref.setBool(PrefKeys.markCheckWithOfd, true);
  await Pref.setBool('checkProductByCashsale', true);
}

void main() {
  setUpAll(() => setUpPosTestEnv('cash_restriction_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    ItemsSingleton.products = [];
    await enableCashsaleGates();
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
  });

  group('isCardOnlyPaymentRequired — faqat karta qabul qiladigan MXIK', () {
    test('bo\'sh savatda false', () {
      expect(freshProvider().isCardOnlyPaymentRequired, isFalse);
    });

    test('ro\'yxatdagi MXIK bo\'lsa true', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(mxik: kCardOnlyMxik));
      expect(p.isCardOnlyPaymentRequired, isTrue);
    });

    test('oddiy MXIK bo\'lsa false', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(mxik: kCashsaleOffMxik));
      expect(p.isCardOnlyPaymentRequired, isFalse);
    });

    test('bo\'sh MXIK e\'tiborga olinmaydi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(mxik: ''));
      expect(p.isCardOnlyPaymentRequired, isFalse);
    });

    test('MXIK atrofidagi bo\'shliq trim qilinadi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(mxik: '  $kCardOnlyMxik  '));
      expect(p.isCardOnlyPaymentRequired, isTrue);
    });

    test('aralash savatda bittasi yetarli', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeSoldItem(mxik: kCashsaleOffMxik))
        ..add(makeSoldItem(mxik: kCardOnlyMxik));
      expect(p.isCardOnlyPaymentRequired, isTrue);
    });

    test('QAYD: o\'chirilgan qator ham hisobga olinadi (filtr yo\'q)', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(mxik: kCardOnlyMxik, isDeleted: true));
      expect(p.isCardOnlyPaymentRequired, isTrue);
    });

    test('Pref gate\'laridan mustaqil (OFD o\'chiq bo\'lsa ham ishlaydi)',
        () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, false);
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(mxik: kCardOnlyMxik));
      expect(p.isCardOnlyPaymentRequired, isTrue);
    });
  });

  group('isCashPaymentHidden — markirovka guruhlari bo\'yicha', () {
    OrderingProvider4 withMxik(String mxik) {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(mxik: mxik));
      return p;
    }

    test('markCheckWithOfd o\'chiq bo\'lsa false (default ham false)',
        () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, false);
      expect(withMxik(kAlcoholMxik).isCashPaymentHidden, isFalse);
    });

    test('sellProductsWithMarking o\'chiq bo\'lsa false', () async {
      await Pref.setBool(PrefKeys.sellProductsWithMarking, false);
      expect(withMxik(kAlcoholMxik).isCashPaymentHidden, isFalse);
    });

    test('bo\'sh savatda false', () {
      expect(freshProvider().isCashPaymentHidden, isFalse);
    });

    for (final prefix in ['02203', '02204', '02205', '02206', '02207', '02208']) {
      test('$prefix bilan boshlansa true', () {
        expect(withMxik('${prefix}001001000000').isCashPaymentHidden, isTrue);
      });
    }

    test('024 bilan boshlansa true', () {
      expect(withMxik('024001001001000').isCashPaymentHidden, isTrue);
    });

    test('02202 (ro\'yxatda yo\'q prefiks) false', () {
      expect(withMxik(kCashsaleOffMxik).isCashPaymentHidden, isFalse);
    });

    test('02209 (chegaradan tashqari) false', () {
      expect(withMxik('02209001001000000').isCashPaymentHidden, isFalse);
    });

    test('bo\'sh MXIK false', () {
      expect(withMxik('').isCashPaymentHidden, isFalse);
    });

    test('bo\'shliqli MXIK trim qilinadi', () {
      expect(withMxik('  02203001001000000 ').isCashPaymentHidden, isTrue);
    });

    test('QAYD: o\'chirilgan qator ham hisobga olinadi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
          .add(makeSoldItem(mxik: kAlcoholMxik, isDeleted: true));
      expect(p.isCashPaymentHidden, isTrue);
    });
  });

  group('isCashHiddenByCashsale — cashsale == 0 (qat\'iy taqiq)', () {
    /// [catalog] — productId → cashsale qiymati (null = maydon yo'q).
    OrderingProvider4 withCatalog(
      Map<String, int?> catalog, {
      bool deleted = false,
      double price = 5000,
      double value = 1,
    }) {
      ItemsSingleton.products = [
        for (final e in catalog.entries) productWithCashsale(e.key, e.value)
      ];
      final p = freshProvider();
      for (final id in catalog.keys) {
        p.getCurrentClient.orderedProducts.add(makeSoldItem(
          productId: id,
          isDeleted: deleted,
          price: price,
          value: value,
        ));
      }
      return p;
    }

    test('markCheckWithOfd o\'chiq bo\'lsa false', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, false);
      expect(withCatalog({'a': 0}).isCashHiddenByCashsale,
          isFalse);
    });

    test('checkProductByCashsale o\'chiq bo\'lsa false', () async {
      await Pref.setBool('checkProductByCashsale', false);
      expect(withCatalog({'a': 0}).isCashHiddenByCashsale,
          isFalse);
    });

    test('bo\'sh savatda false', () {
      expect(freshProvider().isCashHiddenByCashsale, isFalse);
    });

    test('cashsale == 0 bo\'lsa true', () {
      expect(
          withCatalog({'a': 0}).isCashHiddenByCashsale, isTrue);
    });

    test('cashsale == 1 bo\'lsa false', () {
      expect(withCatalog({'a': 1}).isCashHiddenByCashsale,
          isFalse);
    });

    test('cashsale == null bo\'lsa default 1 → false', () {
      expect(withCatalog({'a': null}).isCashHiddenByCashsale,
          isFalse);
    });

    test('katalogda topilmasa default 1 → false', () {
      ItemsSingleton.products = [];
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(productId: 'yoq'));
      expect(p.isCashHiddenByCashsale, isFalse);
    });

    test('o\'chirilgan qator hisobga olinmaydi', () {
      expect(
        withCatalog({'a': 0}, deleted: true)
            .isCashHiddenByCashsale,
        isFalse,
      );
    });

    test('aralash savatda bitta cashsale=0 yetarli', () {
      expect(
        withCatalog({'a': 1, 'b': 0})
            .isCashHiddenByCashsale,
        isTrue,
      );
    });
  });

  group('isBigTotalHidden — cashsale == 1 va qator jami > 25 mln', () {
    OrderingProvider4 withRow({
      int? cashsale = 1,
      double price = 5000,
      double value = 1,
      bool deleted = false,
      bool inCatalog = true,
    }) {
      ItemsSingleton.products =
          inCatalog ? [productWithCashsale('a', cashsale)] : [];
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(
        productId: 'a',
        price: price,
        value: value,
        isDeleted: deleted,
      ));
      return p;
    }

    test('markCheckWithOfd o\'chiq bo\'lsa false', () async {
      await Pref.setBool(PrefKeys.markCheckWithOfd, false);
      expect(withRow(price: 30000000).isBigTotalHidden, isFalse);
    });

    test('checkProductByCashsale o\'chiq bo\'lsa false', () async {
      await Pref.setBool('checkProductByCashsale', false);
      expect(withRow(price: 30000000).isBigTotalHidden, isFalse);
    });

    test('bo\'sh savatda false', () {
      expect(freshProvider().isBigTotalHidden, isFalse);
    });

    test('25 000 001 → true', () {
      expect(withRow(price: 25000001).isBigTotalHidden, isTrue);
    });

    test('CHEGARA: aynan 25 000 000 → false (qat\'iy >)', () {
      expect(withRow(price: 25000000).isBigTotalHidden, isFalse);
    });

    test('price × value hisoblanadi (10 mln × 3 = 30 mln → true)', () {
      expect(withRow(price: 10000000, value: 3).isBigTotalHidden, isTrue);
    });

    test('cashsale == 0 bo\'lsa bu getter false (u qat\'iy taqiqqa tegishli)',
        () {
      expect(withRow(cashsale: 0, price: 30000000).isBigTotalHidden, isFalse);
    });

    test('cashsale == null bo\'lsa false (-1 default, 1 ga teng emas)', () {
      expect(
          withRow(cashsale: null, price: 30000000).isBigTotalHidden, isFalse);
    });

    test('katalogda topilmasa false', () {
      expect(
          withRow(inCatalog: false, price: 30000000).isBigTotalHidden, isFalse);
    });

    test('o\'chirilgan qator hisobga olinmaydi', () {
      expect(withRow(price: 30000000, deleted: true).isBigTotalHidden, isFalse);
    });

    test('ikkita qatordan biri oshsa true', () {
      ItemsSingleton.products = [
        productWithCashsale('a', 1),
        productWithCashsale('b', 1),
      ];
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeSoldItem(productId: 'a', price: 1000))
        ..add(makeSoldItem(productId: 'b', price: 26000000));
      expect(p.isBigTotalHidden, isTrue);
    });

    test('QAYD: chegara QATOR bo\'yicha, savat jami bo\'yicha emas', () {
      // 2 × 20 mln = 40 mln, lekin hech bir QATOR 25 mln dan oshmaydi.
      ItemsSingleton.products = [
        productWithCashsale('a', 1),
        productWithCashsale('b', 1),
      ];
      final p = freshProvider();
      p.getCurrentClient.orderedProducts
        ..add(makeSoldItem(productId: 'a', price: 20000000))
        ..add(makeSoldItem(productId: 'b', price: 20000000));
      expect(p.isBigTotalHidden, isFalse);
    });
  });

  group('resetCashRestrictionWarnings — sozlama o\'zgarganda', () {
    test('notifyListeners chaqiriladi', () {
      final p = freshProvider();
      var notified = 0;
      p.addListener(() => notified++);
      p.resetCashRestrictionWarnings();
      expect(notified, 1);
    });

    test('bir necha marta chaqirsa ham xato bermaydi', () {
      final p = freshProvider();
      expect(() {
        p.resetCashRestrictionWarnings();
        p.resetCashRestrictionWarnings();
      }, returnsNormally);
    });
  });
}
