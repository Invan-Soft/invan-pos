// `CartEditController` — to'g'ridan-to'g'ri (providersiz) testlar.
//
// `group_edit_test.dart` xatti-harakatni provider orqali tekshiradi (42 test).
// Bu yerda kontroller yuzasi va uning provider bilan SHARTNOMASI tekshiriladi:
// qaysi shoxda qaysi callback chaqiriladi. Ilgari buni umuman ko'rib
// bo'lmasdi — hammasi bitta sinf ichida private edi. Aynan shu joyda
// "narx qo'lda o'zgarganda tier reprice chaqirilmasligi kerak" kabi
// qoidalar bilinmay buzilishi mumkin.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/providers/ordering/cart_edit_controller.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

const kPid = 'suv-id';
const kBox = 12;

/// Provider o'rniga qo'yiladigan soxta muhit: har callback qayd etiladi.
class Harness {
  Harness({this.redDelete = false});

  final bool redDelete;
  final List<ReceiptModelSoldItem4> rows = [];
  final List<String> calls = [];
  final List<ReceiptModelSoldItem4> recorded = [];

  late final CartEditController c = CartEditController(
    rowsOf: () => rows,
    notify: () => calls.add('notify'),
    recordDeletedItem: (item, {quantity, approvedBy}) {
      recorded.add(item);
      calls.add('record');
    },
    reprice: (pid) => calls.add('reprice:$pid'),
    syncManualPrice: (e) => calls.add('syncManual'),
    refreshDiscountEffects: () => calls.add('discounts'),
    clearShowCounts: (pid) => calls.add('clearShowCounts:$pid'),
    resetClientDiscount: () => calls.add('resetClient'),
    flagOrphanDeletedItems: () => calls.add('orphan'),
    isRedDeleteOn: () => redDelete,
    currentEmployeeName: () => 'Test Kassir',
    posNameOf: () => 'Kassa-1',
    notifyDeleted: ({
      required String productName,
      required String productId,
      required String posName,
      required String employeeName,
      required String deleteTime,
      required String product_qunatity,
    }) async {
      calls.add('notifyDeleted:$productName');
    },
  );
}

ReceiptModelSoldItem4 mark(String id, {bool deleted = false}) => makeSoldItem(
    productId: kPid, marking: true, mark: id, isDeleted: deleted, price: 2000);

ReceiptModelSoldItem4 boxRow({bool deleted = false}) => makeSoldItem(
      productId: kPid,
      price: 24000,
      saleType: 2,
      boxValue: kBox,
      isDeleted: deleted,
    );

ReceiptModelSoldItem4 edit({
  required double value,
  double price = 2000,
  bool manual = false,
  int saleType = 1,
  int boxValue = 0,
}) =>
    makeSoldItem(
      productId: kPid,
      price: price,
      value: value,
      saleType: saleType,
      boxValue: boxValue,
      isPriceOnlyChanged: manual,
      isPriceChanged: manual,
    );

void main() {
  group('Tahrir rejimi bayroqlari', () {
    test('boshida ikkala rejim ham o\'chiq', () {
      final h = Harness();
      expect(h.c.isMarkGroupEditing, isFalse);
      expect(h.c.isBoxGroupEditing, isFalse);
    });

    test('productId berilgach rejim yoqiladi', () {
      final h = Harness();
      h.c.markGroupProductId = kPid;
      expect(h.c.isMarkGroupEditing, isTrue);
      expect(h.c.isBoxGroupEditing, isFalse);
    });

    test('null qo\'yilsa rejim o\'chadi', () {
      final h = Harness()..c.boxGroupProductId = kPid;
      h.c.boxGroupProductId = null;
      expect(h.c.isBoxGroupEditing, isFalse);
    });
  });

  group('activeMarkIndices', () {
    test('markirovkali va o\'chirilmagan qatorlar indekslari', () {
      final h = Harness();
      h.rows.addAll([mark('m1'), makeSoldItem(productId: kPid), mark('m2')]);
      expect(h.c.activeMarkIndices(kPid), [0, 2]);
    });

    test('o\'chirilgan marka kirmaydi', () {
      final h = Harness();
      h.rows.addAll([mark('m1', deleted: true), mark('m2')]);
      expect(h.c.activeMarkIndices(kPid), [1]);
    });

    test('boshqa mahsulot markasi kirmaydi', () {
      final h = Harness();
      h.rows.addAll([
        mark('m1'),
        makeSoldItem(productId: 'boshqa', marking: true, mark: 'x'),
      ]);
      expect(h.c.activeMarkIndices(kPid), [0]);
    });

    test('marka yo\'q bo\'lsa bo\'sh ro\'yxat', () {
      expect(Harness().c.activeMarkIndices(kPid), isEmpty);
    });
  });

  group('activeBoxIndices', () {
    test('faqat saleType == 2 qatorlar', () {
      final h = Harness();
      h.rows.addAll([makeSoldItem(productId: kPid), boxRow(), boxRow()]);
      expect(h.c.activeBoxIndices(kPid), [1, 2]);
    });

    test('o\'chirilgan blok kirmaydi', () {
      final h = Harness();
      h.rows.addAll([boxRow(deleted: true), boxRow()]);
      expect(h.c.activeBoxIndices(kPid), [1]);
    });

    test('markirovkali dona qatori blok emas', () {
      final h = Harness();
      h.rows.add(mark('m1'));
      expect(h.c.activeBoxIndices(kPid), isEmpty);
    });
  });

  group('Shartnoma: qaysi shoxda qaysi callback', () {
    test('guruh bo\'sh bo\'lsa hech narsa chaqirilmaydi (notify ham)',
        () async {
      final h = Harness();
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1));
      expect(h.calls, isEmpty);
    });

    test('marka guruhi saqlanganda tartib: reprice → diskont → notify',
        () async {
      final h = Harness();
      h.rows.add(mark('m1'));
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1));
      expect(h.calls, ['reprice:$kPid', 'discounts', 'notify']);
    });

    test('qo\'lda narxda syncManual chaqiriladi', () async {
      final h = Harness();
      h.rows.add(mark('m1'));
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1, manual: true));
      expect(h.calls, contains('syncManual'));
    });

    test('qo\'lda EMAS narxda syncManual chaqirilmaydi', () async {
      final h = Harness();
      h.rows.add(mark('m1'));
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1));
      expect(h.calls, isNot(contains('syncManual')));
    });

    test('BLOK guruhida qo\'lda narx tier reprice O\'RNIGA syncManual qiladi',
        () async {
      final h = Harness();
      h.rows.add(boxRow());
      h.c.boxGroupProductId = kPid;
      await h.c.saveBoxGroup(
          edit(value: 1, manual: true, saleType: 2, boxValue: kBox));
      expect(h.calls, contains('syncManual'));
      expect(h.calls, isNot(contains('reprice:$kPid')),
          reason: 'qo\'lda narx tier bilan bosib ketilmasligi kerak');
    });

    test('BLOK guruhida qo\'lda EMAS narx tier reprice qiladi', () async {
      final h = Harness();
      h.rows.add(boxRow());
      h.c.boxGroupProductId = kPid;
      await h.c.saveBoxGroup(edit(value: 1, saleType: 2, boxValue: kBox));
      expect(h.calls, contains('reprice:$kPid'));
      expect(h.calls, isNot(contains('syncManual')));
    });

    test('qty kamayganda har o\'chgan qator uchun record chaqiriladi',
        () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), mark('m2'), mark('m3')]);
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1));
      expect(h.calls.where((e) => e == 'record').length, 2);
    });

    test('guruh bo\'shamasa clearShowCounts chaqirilmaydi', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), mark('m2')]);
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1));
      expect(h.calls, isNot(contains('clearShowCounts:$kPid')));
    });

    test('savatda boshqa mahsulot qolsa resetClient chaqirilmaydi', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), makeSoldItem(productId: 'boshqa')]);
      h.c.markGroupProductId = kPid;
      h.c.deleteMarkGroup(kPid);
      expect(h.calls, contains('clearShowCounts:$kPid'));
      expect(h.calls, isNot(contains('resetClient')));
      expect(h.calls, isNot(contains('orphan')));
    });

    test('savat butunlay bo\'shasa resetClient va orphan chaqiriladi', () {
      final h = Harness();
      h.rows.add(mark('m1'));
      h.c.deleteMarkGroup(kPid);
      expect(h.calls, containsAllInOrder(['resetClient', 'orphan']));
    });

    test('QAYD: saqlashda guruh bo\'shasa orphan chaqirilmaydi '
        '(faqat o\'chirishda)', () async {
      final h = Harness();
      h.rows.add(mark('m1'));
      h.c.markGroupProductId = kPid;
      // qty 0 → deleteMarkGroup yo'liga o'tadi, u orphan chaqiradi
      await h.c.saveMarkGroup(edit(value: 0));
      expect(h.calls, contains('orphan'));
    });

    test('blok guruhini o\'chirishda ham orphan belgilanadi', () {
      final h = Harness();
      h.rows.add(boxRow());
      h.c.deleteBoxGroup(kPid);
      expect(h.calls, contains('orphan'));
    });

    test('notify har amalda AYNAN bir marta', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), mark('m2')]);
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1));
      expect(h.calls.where((e) => e == 'notify').length, 1);
    });
  });

  group('Qizil o\'chirish rejimi callback orqali keladi', () {
    test('yoqilgan bo\'lsa qator ro\'yxatda qoladi', () async {
      final h = Harness(redDelete: true);
      h.rows.addAll([mark('m1'), mark('m2')]);
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1));
      expect(h.rows.length, 2);
      expect(h.rows[0].isDeleted, isTrue);
    });

    test('o\'chiq bo\'lsa qator ro\'yxatdan chiqadi', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), mark('m2')]);
      h.c.markGroupProductId = kPid;
      await h.c.saveMarkGroup(edit(value: 1));
      expect(h.rows.length, 1);
    });
  });

  group('deleteRow — bitta qator (guruh rejimisiz)', () {
    test('qator ro\'yxatdan chiqadi va yoziladi', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), makeSoldItem(productId: 'boshqa')]);
      await h.c.deleteRow(0);
      expect(h.rows.length, 1);
      expect(h.calls.where((e) => e == 'record').length, 1);
    });

    test('qizil o\'chirishda qator qoladi (isDeleted)', () async {
      final h = Harness(redDelete: true);
      h.rows.add(mark('m1'));
      await h.c.deleteRow(0);
      expect(h.rows.length, 1);
      expect(h.rows[0].isDeleted, isTrue);
    });

    test('shu mahsulotdan boshqa qator qolmasa showCount tozalanadi',
        () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), makeSoldItem(productId: 'boshqa')]);
      await h.c.deleteRow(0);
      expect(h.calls, contains('clearShowCounts:$kPid'));
    });

    test('shu mahsulotdan qator qolsa showCount tozalanmaydi', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), mark('m2')]);
      await h.c.deleteRow(0);
      expect(h.calls, isNot(contains('clearShowCounts:$kPid')));
    });

    test('savat bo\'shasa mijoz tanlovi bekor qilinadi', () async {
      final h = Harness();
      h.rows.add(mark('m1'));
      await h.c.deleteRow(0);
      expect(h.calls, contains('resetClient'));
    });

    test('savatda qator qolsa mijoz tanlovi saqlanadi', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), makeSoldItem(productId: 'boshqa')]);
      await h.c.deleteRow(0);
      expect(h.calls, isNot(contains('resetClient')));
    });

    test('QAYD: qizil o\'chirishda rows bo\'shamaydi — resetClient '
        'chaqirilmaydi, lekin orphan baribir belgilanadi', () async {
      final h = Harness(redDelete: true);
      h.rows.add(mark('m1'));
      await h.c.deleteRow(0);
      expect(h.calls, isNot(contains('resetClient')));
      expect(h.calls, contains('orphan'));
    });

    test('qolgan qatorlar qayta narxlanadi', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), mark('m2')]);
      await h.c.deleteRow(0);
      expect(h.calls, contains('reprice:$kPid'));
    });

    test('tashqi xabarnoma yuboriladi', () async {
      final h = Harness();
      h.rows.add(mark('m1'));
      await h.c.deleteRow(0);
      expect(h.calls.any((e) => e.startsWith('notifyDeleted:')), isTrue);
    });

    test('xabarnoma notify dan KEYIN yuboriladi (UI kutib qolmaydi)',
        () async {
      final h = Harness();
      h.rows.add(mark('m1'));
      await h.c.deleteRow(0);
      final iNotify = h.calls.indexOf('notify');
      final iTg = h.calls.indexWhere((e) => e.startsWith('notifyDeleted:'));
      expect(iNotify, lessThan(iTg));
    });

    test('notify aynan bir marta', () async {
      final h = Harness();
      h.rows.addAll([mark('m1'), mark('m2')]);
      await h.c.deleteRow(0);
      expect(h.calls.where((e) => e == 'notify').length, 1);
    });
  });
}
