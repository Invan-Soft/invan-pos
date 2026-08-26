// Markirovkali qatorlarni savatdan qidirish — `MarkedCart`.
//
// Bu qoidalar bitta KM ikki marta sotilishining oldini oladi va yangi KM ni
// mavjud KM siz qatorga biriktiradi. `_markingCheck` da olti joyda
// takrorlangan edi va faqat ONKM so'rovi + dialoglar orqali ishga tushardi —
// testlab bo'lmasdi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/marking/marked_cart.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

const kPid = 'suv-id';

ReceiptModelSoldItem4 row({
  String productId = kPid,
  String? mark,
  bool deleted = false,
}) =>
    makeSoldItem(
        productId: productId, mark: mark, marking: mark != null, isDeleted: deleted);

void main() {
  group('indexOfMark — savatda shu KM bormi', () {
    test('bor bo\'lsa indeks qaytadi', () {
      expect(MarkedCart.indexOfMark([row(mark: 'A'), row(mark: 'B')], 'B'), 1);
    });

    test('yo\'q bo\'lsa -1', () {
      expect(MarkedCart.indexOfMark([row(mark: 'A')], 'Z'), -1);
    });

    test('o\'chirilgan qator sanalmaydi', () {
      expect(MarkedCart.indexOfMark([row(mark: 'A', deleted: true)], 'A'), -1);
    });

    test('KM si bo\'sh qator sanalmaydi', () {
      expect(MarkedCart.indexOfMark([row(mark: '')], ''), -1);
    });

    test('KM si yo\'q qator sanalmaydi', () {
      expect(MarkedCart.indexOfMark([row()], 'A'), -1);
    });

    test('BOSHQA mahsulotda bo\'lsa ham topiladi — KM chekda yagona', () {
      expect(
        MarkedCart.indexOfMark([row(productId: 'boshqa', mark: 'A')], 'A'),
        0,
      );
    });

    test('bo\'sh savatda -1', () {
      expect(MarkedCart.indexOfMark([], 'A'), -1);
    });
  });

  group('indexOfWithoutMark — KM siz qator', () {
    test('shu mahsulotning KM siz qatori topiladi', () {
      expect(MarkedCart.indexOfWithoutMark([row(mark: 'A'), row()], kPid), 1);
    });

    test('KM si bo\'sh string bo\'lsa ham topiladi', () {
      expect(MarkedCart.indexOfWithoutMark([row(mark: '')], kPid), 0);
    });

    test('boshqa mahsulotning KM siz qatori hisobga olinmaydi', () {
      expect(
          MarkedCart.indexOfWithoutMark([row(productId: 'boshqa')], kPid), -1);
    });

    test('hammasida KM bor bo\'lsa -1', () {
      expect(MarkedCart.indexOfWithoutMark([row(mark: 'A')], kPid), -1);
    });
  });

  group('hasMark — shu mahsulotda shu KM bormi', () {
    test('bor', () {
      expect(MarkedCart.hasMark([row(mark: 'A')], kPid, 'A'), isTrue);
    });

    test('boshqa mahsulotda bo\'lsa false', () {
      expect(
        MarkedCart.hasMark([row(productId: 'boshqa', mark: 'A')], kPid, 'A'),
        isFalse,
      );
    });

    test('boshqa KM bo\'lsa false', () {
      expect(MarkedCart.hasMark([row(mark: 'B')], kPid, 'A'), isFalse);
    });

    test('QAYD: o\'chirilgan qator ham sanaladi (filtr yo\'q)', () {
      expect(
        MarkedCart.hasMark([row(mark: 'A', deleted: true)], kPid, 'A'),
        isTrue,
      );
    });
  });

  group('decideWithoutOnkm — ONKM o\'chiq holat', () {
    test('bo\'sh savat → yangi qator', () {
      expect(MarkedCart.decideWithoutOnkm([], kPid, 'A'), MarkAction.addNew);
    });

    test('shu KM bor → ogohlantirish', () {
      expect(MarkedCart.decideWithoutOnkm([row(mark: 'A')], kPid, 'A'),
          MarkAction.warnDuplicate);
    });

    test('KM siz qator bor → o\'shanga biriktiriladi', () {
      expect(MarkedCart.decideWithoutOnkm([row()], kPid, 'A'),
          MarkAction.attachToExistingRow);
    });

    test('takror tekshiruvi USTUN: ikkalasi ham bo\'lsa ogohlantirish', () {
      expect(
        MarkedCart.decideWithoutOnkm([row(mark: 'A'), row()], kPid, 'A'),
        MarkAction.warnDuplicate,
      );
    });

    test('boshqa mahsulotning KM siz qatori → yangi qator', () {
      expect(MarkedCart.decideWithoutOnkm([row(productId: 'x')], kPid, 'A'),
          MarkAction.addNew);
    });

    test('o\'chirilgan KM li qator takror deb sanalmaydi → yangi qator', () {
      // KM si bor (bo'sh emas), shuning uchun "KM siz qator" ham emas.
      expect(
        MarkedCart.decideWithoutOnkm([row(mark: 'A', deleted: true)], kPid, 'A'),
        MarkAction.addNew,
      );
    });
  });

  group('decideAfterCheck — ONKM javobidan keyin', () {
    test('takror yo\'q → yangi qator', () {
      expect(MarkedCart.decideAfterCheck([], kPid, 'A'), MarkAction.addNew);
    });

    test('takror bor → ogohlantirish', () {
      expect(MarkedCart.decideAfterCheck([row(mark: 'A')], kPid, 'A'),
          MarkAction.warnDuplicate);
    });

    test('KM siz qator bo\'lsa ham yangi qator (biriktirilmaydi)', () {
      expect(MarkedCart.decideAfterCheck([row()], kPid, 'A'),
          MarkAction.addNew);
    });
  });
}
