// `CashRestrictionRules` — to'g'ridan-to'g'ri (providersiz) testlar.
//
// `cash_restriction_test.dart` (46) xatti-harakatni provider + Pref orqali
// qamraydi. Bu yerda qoidalarning O'ZI: sozlama bayroqlari endi parametr,
// shuning uchun har kombinatsiyani Pref'siz ko'rsatib bo'ladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/cash_restriction_rules.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

const kCardOnlyMxik = '09905001001000000'; // elektr energiya
const kAlcoholMxik = '02203001001000000';
const kPlainMxik = '02202001001000000';

ItemModel catalogItem(String id, int? cashsale) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.cashsale = cashsale;
  return m;
}

void main() {
  setUp(() => ItemsSingleton.products = []);

  group('cardOnlyRequired', () {
    test('bo\'sh savat → false', () {
      expect(CashRestrictionRules.cardOnlyRequired([]), isFalse);
    });

    test('kommunal MXIK → true', () {
      expect(
        CashRestrictionRules.cardOnlyRequired(
            [makeSoldItem(mxik: kCardOnlyMxik)]),
        isTrue,
      );
    });

    test('oddiy MXIK → false', () {
      expect(
        CashRestrictionRules.cardOnlyRequired([makeSoldItem(mxik: kPlainMxik)]),
        isFalse,
      );
    });

    test('sozlamalardan mustaqil (parametr olmaydi)', () {
      // Imzo bayroq qabul qilmaydi — qoida har doim ishlaydi.
      expect(
        CashRestrictionRules.cardOnlyRequired(
            [makeSoldItem(mxik: kCardOnlyMxik)]),
        isTrue,
      );
    });
  });

  group('cashHiddenByMarking — bayroq kombinatsiyalari', () {
    bool run({required bool ofd, required bool marking}) =>
        CashRestrictionRules.cashHiddenByMarking(
          [makeSoldItem(mxik: kAlcoholMxik)],
          ofdOn: ofd,
          markingSaleOn: marking,
        );

    test('OFD yoq + markirovka yoq → true', () {
      expect(run(ofd: true, marking: true), isTrue);
    });

    test('OFD o\'chiq → false', () {
      expect(run(ofd: false, marking: true), isFalse);
    });

    test('markirovka sotuvi o\'chiq → false', () {
      expect(run(ofd: true, marking: false), isFalse);
    });

    test('ikkalasi ham o\'chiq → false', () {
      expect(run(ofd: false, marking: false), isFalse);
    });

    test('bayroqlar yoqilgan, lekin savat bo\'sh → false', () {
      expect(
        CashRestrictionRules.cashHiddenByMarking([],
            ofdOn: true, markingSaleOn: true),
        isFalse,
      );
    });
  });

  group('cashHiddenByCashsale', () {
    bool run(List<ReceiptModelSoldItem4> rows,
            {bool ofd = true, bool check = true}) =>
        CashRestrictionRules.cashHiddenByCashsale(rows,
            ofdOn: ofd, cashsaleCheckOn: check);

    test('cashsale 0 → true', () {
      ItemsSingleton.products = [catalogItem('a', 0)];
      expect(run([makeSoldItem(productId: 'a')]), isTrue);
    });

    test('cashsale 1 → false', () {
      ItemsSingleton.products = [catalogItem('a', 1)];
      expect(run([makeSoldItem(productId: 'a')]), isFalse);
    });

    test('katalogda yo\'q → false (default ruxsat)', () {
      expect(run([makeSoldItem(productId: 'yoq')]), isFalse);
    });

    test('OFD o\'chiq → false', () {
      ItemsSingleton.products = [catalogItem('a', 0)];
      expect(run([makeSoldItem(productId: 'a')], ofd: false), isFalse);
    });

    test('cashsale tekshiruvi o\'chiq → false', () {
      ItemsSingleton.products = [catalogItem('a', 0)];
      expect(run([makeSoldItem(productId: 'a')], check: false), isFalse);
    });

    test('o\'chirilgan qator sanalmaydi', () {
      ItemsSingleton.products = [catalogItem('a', 0)];
      expect(run([makeSoldItem(productId: 'a', isDeleted: true)]), isFalse);
    });
  });

  group('bigTotalHidden', () {
    // 400 × 440 000. Qoida chegarani parametr sifatida oladi — manba
    // (`BhmService`) alohida testlanadi (bhm_service_test.dart).
    const kLimit = 176000000.0;

    bool run(double price,
        {double value = 1, int? cashsale = 1, double limit = kLimit}) {
      ItemsSingleton.products = [catalogItem('a', cashsale)];
      return CashRestrictionRules.bigTotalHidden(
        [makeSoldItem(productId: 'a', price: price, value: value)],
        ofdOn: true,
        cashsaleCheckOn: true,
        limit: limit,
      );
    }

    test('chegaradan 1 so\'m yuqori → true', () {
      expect(run(176000001), isTrue);
    });

    test('aynan chegara → false (qat\'iy >)', () {
      expect(run(176000000), isFalse);
    });

    test('chegara parametrdan olinadi — 10 000 bo\'lsa 10 001 → true', () {
      expect(run(10001, limit: 10000), isTrue);
      expect(run(10000, limit: 10000), isFalse);
    });

    test('narx × miqdor hisoblanadi', () {
      expect(run(90000000, value: 2), isTrue);
    });

    test('cashsale 0 bu qoidaga kirmaydi', () {
      expect(run(180000000, cashsale: 0), isFalse);
    });

    test('cashsale null bu qoidaga kirmaydi', () {
      expect(run(180000000, cashsale: null), isFalse);
    });

    test('OFD o\'chiq → false', () {
      ItemsSingleton.products = [catalogItem('a', 1)];
      expect(
        CashRestrictionRules.bigTotalHidden(
          [makeSoldItem(productId: 'a', price: 180000000)],
          ofdOn: false,
          cashsaleCheckOn: true,
          limit: kLimit,
        ),
        isFalse,
      );
    });

    test('QAYD: chegara QATOR bo\'yicha — 2 × 100 mln savat jami ishlamaydi',
        () {
      ItemsSingleton.products = [catalogItem('a', 1), catalogItem('b', 1)];
      expect(
        CashRestrictionRules.bigTotalHidden(
          [
            makeSoldItem(productId: 'a', price: 100000000),
            makeSoldItem(productId: 'b', price: 100000000),
          ],
          ofdOn: true,
          cashsaleCheckOn: true,
          limit: kLimit,
        ),
        isFalse,
      );
    });
  });
}
