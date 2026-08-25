// `_recordDeletedItem` va orphan belgilashning QOLGAN shoxlari.
//
// Asosiy oqim `deleted_items_orderpos_test.dart` da (54 test) qoplangan:
// OPD o'chirish, qty kamaytirish, guruhlar, JSON, PIN egasi, ko'p-mijoz.
// Bu fayl Faza 9.3 ko'chirishidan oldin faqat O'SHA YERDA YO'Q shoxlarni
// yopadi: takroriy yozuv guardi, qty <= 0, xodim IDsining oxirgi fallback'i,
// totalPrice yaxlitlashi, bo'sh addedTime va orphan belgilashning
// "allaqachon raqamli" holati.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kPid = 'pepsi-id';

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

/// OPD dialogidan "O'chirish" (guruh rejimisiz).
void deleteRow(OrderingProvider4 p, int index) {
  p.tapIndexToEdit(index);
  p.pressDialogDeleteButton();
}

void main() {
  setUpAll(() => setUpPosTestEnv('deleted_item_record_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    ItemsSingleton.products = [];
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
    await Pref.setString(PrefKeys.cashierId, kCashierId);
  });

  group('Takroriy yozuv guardi', () {
    test('qizil o\'chirishda o\'sha qatorga qayta X bosilsa ikkinchi marta '
        'yozilmaydi', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 5000));

      deleteRow(p, 0);
      deleteRow(p, 0); // qator hali savatda (isDeleted = true)

      expect(p.getCurrentClient.deletedItems.length, 1);
    });

    test('allaqachon o\'chirilgan qatorni guruh o\'chirishi qayta yozmaydi',
        () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: kPid, marking: true, mark: 'm1'),
        makeSoldItem(
            productId: kPid, marking: true, mark: 'm2', isDeleted: true),
      ]);

      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();

      expect(p.getCurrentClient.deletedItems.length, 1,
          reason: 'faqat aktiv marka yoziladi');
    });
  });

  group('Nol yoki manfiy miqdor yozilmaydi', () {
    test('value = 0 qatorni o\'chirish yozuv qoldirmaydi', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 5000, value: 0));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems, isEmpty);
    });

    test('qty o\'zgarmagan saqlashda yozuv qoldirilmaydi', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 5000, value: 3));
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(
          makeSoldItem(productId: kPid, price: 5000, value: 3));
      expect(p.getCurrentClient.deletedItems, isEmpty);
    });
  });

  group('deleted_by — xodim IDsini aniqlash zanjiri', () {
    test('joriy kassir topilmasa Pref dagi cashierId ga tushadi', () async {
      // QAYD: provider konstruktori `getCurrentEmployee!` ni talab qiladi,
      // shuning uchun bu fallback FAQAT kassir IDsi provider yaratilgandan
      // KEYIN o'zgarganda ishlaydi (smena almashishi kabi). Test aynan shu
      // ketma-ketlikni qayta tiklaydi.
      final p = freshProvider();
      await Pref.setString(PrefKeys.cashierId, 'pin-siz-kassir');
      cart(p).addAll([
        makeSoldItem(productId: kPid, marking: true, mark: 'm1'),
      ]);

      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();

      expect(p.getCurrentClient.deletedItems.first.deletedBy, 'pin-siz-kassir');
    });

    test('xodim topilsa uning IDsi yoziladi', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.deletedBy, kCashierId);
    });
  });

  group('totalPrice hisobi', () {
    test('butun songa yaxlitlanadi (1500.4 → 1500)', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1500.4, value: 1));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.totalPrice, 1500);
    });

    test('yuqoriga yaxlitlanadi (1500.6 → 1501)', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 1500.6, value: 1));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.totalPrice, 1501);
    });

    test('price × qty (3 × 5000 = 15000)', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 5000, value: 3));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.totalPrice, 15000);
    });

    test('qisman o\'chirishda ESKI narx × farq ishlatiladi', () async {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, price: 5000, value: 3));
      p.tapIndexToEdit(0);
      // Narx ham, qty ham o'zgardi: yozuvda ESKI narx (5000) × farq (1)
      await p.pressDialogSaveButton(
          makeSoldItem(productId: kPid, price: 9000, value: 2));
      final d = p.getCurrentClient.deletedItems.first;
      expect(d.quantity, 1);
      expect(d.totalPrice, 5000);
    });

    test('kasr miqdorda ham yaxlitlanadi (0.5 × 1499 = 749.5 → 750)',
        () async {
      final p = freshProvider();
      cart(p).add(
          makeSoldItem(productId: kPid, price: 1499, value: 1.5, isKg: true));
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(makeSoldItem(
          productId: kPid, price: 1499, value: 1.0, isKg: true));
      expect(p.getCurrentClient.deletedItems.first.totalPrice, 750);
    });
  });

  group('added_time', () {
    test('createdTime = 0 bo\'lsa added_time bo\'sh string bo\'ladi', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(productId: kPid, createdTime: 0));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.addedTime, isEmpty);
    });

    test('createdTime bor bo\'lsa "yyyy-MM-dd HH:mm:ss" formatida', () {
      final p = freshProvider();
      cart(p).add(makeSoldItem(
          productId: kPid,
          createdTime: DateTime.utc(2026, 3, 4, 5, 6, 7).millisecondsSinceEpoch));
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.addedTime,
          '2026-03-04 05:06:07');
    });
  });

  group('Orphan ("-") belgilash chetki holatlari', () {
    test('allaqachon chek raqami bor yozuvga tegilmaydi', () {
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: kPid),
        makeSoldItem(productId: 'boshqa'),
      ]);
      deleteRow(p, 0); // savatda hali aktiv qator bor
      p.getCurrentClient.deletedItems.first.checkNumber = 'CHEK-1';

      deleteRow(p, 0); // endi savat bo'shadi
      final items = p.getCurrentClient.deletedItems;
      expect(items[0].checkNumber, 'CHEK-1', reason: 'eski raqam saqlanadi');
      expect(items[1].checkNumber, '-');
    });

    test('savatda aktiv qator qolsa hech biriga "-" qo\'yilmaydi', () {
      final p = freshProvider();
      cart(p).addAll([
        makeSoldItem(productId: kPid),
        makeSoldItem(productId: 'boshqa'),
      ]);
      deleteRow(p, 0);
      expect(p.getCurrentClient.deletedItems.first.checkNumber, isEmpty);
    });
  });
}
