// Markirovka va blok GURUHI tahriri (OPD dialogidan "Saqlash" / "O'chirish").
//
// Savatda markirovkali mahsulot har skanda ALOHIDA qator bo'ladi, blok ham
// alohida qator. UI ularni bitta qator qilib ko'rsatadi, shuning uchun dialog
// butun guruhga qo'llanadi: qty kamaytirish = eng yangi qatorlarni o'chirish,
// narx o'zgarishi = butun guruhga (va mahsulotning boshqa qatorlariga).
//
// Faza 9.2 da bu klaster `GroupEditController` ga ko'chiriladi — bu fayl
// ko'chirishdan OLDIN hozirgi xatti-harakatni to'liq muzlatadi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kPid = 'suv-id';
const kBox = 12;

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

List<ReceiptModelSoldItem4> activeRows(OrderingProvider4 p) =>
    cart(p).where((e) => !(e.isDeleted ?? false)).toList();

ReceiptModelSoldItem4 mark(String id,
        {double price = 2000, bool deleted = false}) =>
    makeSoldItem(
        productId: kPid,
        price: price,
        marking: true,
        mark: id,
        isDeleted: deleted);

ReceiptModelSoldItem4 box({double price = 24000, bool deleted = false}) =>
    makeSoldItem(
      productId: kPid,
      price: price,
      value: 1,
      saleType: 2,
      boxValue: kBox,
      boxQuantity: 1,
      isDeleted: deleted,
    );

/// Guruh dialogidan qaytadigan "tahrirlangan nusxa".
/// [value] — marka guruhida marka soni, blok guruhida blok soni.
ReceiptModelSoldItem4 edited({
  required double price,
  required double value,
  bool manual = false,
  int saleType = 1,
  int boxValue = 0,
  double vatPercent = 12,
  String tin = '',
}) {
  final item = makeSoldItem(
    productId: kPid,
    price: price,
    value: value,
    marking: saleType != 2,
    saleType: saleType,
    boxValue: boxValue,
    vatPercent: vatPercent,
    isPriceOnlyChanged: manual,
    isPriceChanged: manual,
  );
  item.tin = tin;
  return item;
}

Future<void> saveMarkGroup(OrderingProvider4 p, ReceiptModelSoldItem4 e,
    {int tapIndex = 0}) async {
  p.beginMarkGroupEdit(kPid);
  p.tapIndexToEdit(tapIndex);
  await p.pressDialogSaveButton(e);
  p.endMarkGroupEdit();
}

Future<void> saveBoxGroup(OrderingProvider4 p, ReceiptModelSoldItem4 e,
    {int tapIndex = 0}) async {
  p.beginBoxGroupEdit(kPid);
  p.tapIndexToEdit(tapIndex);
  await p.pressDialogSaveButton(e);
  p.endBoxGroupEdit();
}

void main() {
  setUpAll(() => setUpPosTestEnv('group_edit_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    // Katalog bo'sh: tier reprice early-return qiladi, testlar faqat guruh
    // mantiqini o'lchaydi. Tier kerak bo'lgan testlar o'zi katalog beradi.
    ItemsSingleton.products = [];
    await Pref.setBool(PrefKeys.isRedDeleteActivated, false);
  });

  group('Guruh rejimi bayrog\'i', () {
    test('beginMarkGroupEdit\'siz saqlash faqat BITTA qatorga ta\'sir qiladi',
        () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(edited(price: 9000, value: 1));
      expect(cart(p).length, 2);
      expect(cart(p)[0].price, 9000);
      expect(cart(p)[1].price, 2000, reason: 'guruh rejimi yoqilmagan');
    });

    test('endMarkGroupEdit\'dan keyin guruh rejimi o\'chadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2'), mark('m3')]);
      p.beginMarkGroupEdit(kPid);
      p.endMarkGroupEdit();
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(edited(price: 2000, value: 1));
      expect(cart(p).length, 3, reason: 'guruh qisqartirilmadi');
    });

    test('endBoxGroupEdit\'dan keyin blok guruh rejimi o\'chadi', () async {
      final p = freshProvider();
      cart(p).addAll([box(), box()]);
      p.beginBoxGroupEdit(kPid);
      p.endBoxGroupEdit();
      p.tapIndexToEdit(0);
      await p.pressDialogSaveButton(edited(
          price: 24000, value: 1, saleType: 2, boxValue: kBox));
      expect(cart(p).length, 2);
    });
  });

  group('Marka guruhi — qty kamaytirish', () {
    test('3 → 2: eng yangi (indeks 0) marka chiqadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('yangi'), mark('o\'rta'), mark('eski')]);
      await saveMarkGroup(p, edited(price: 2000, value: 2));
      expect(cart(p).map((e) => e.mark), ['o\'rta', 'eski']);
    });

    test('3 → 1: ikkita eng yangi chiqadi, eng eskisi qoladi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2'), mark('m3')]);
      await saveMarkGroup(p, edited(price: 2000, value: 1));
      expect(cart(p).map((e) => e.mark), ['m3']);
    });

    test('kasrli qty pastga yaxlitlanadi (2.9 → 2)', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2'), mark('m3')]);
      await saveMarkGroup(p, edited(price: 2000, value: 2.9));
      expect(cart(p).length, 2);
    });

    test('o\'chirilgan markalar deleted_items ga yoziladi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2'), mark('m3')]);
      await saveMarkGroup(p, edited(price: 2000, value: 1));
      expect(p.getCurrentClient.deletedItems.length, 2);
      expect(p.getCurrentClient.deletedItems.first.quantity, 1);
    });

    test('qizil o\'chirishda qatorlar savatda QOLADI (isDeleted = true)',
        () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2'), mark('m3')]);
      await saveMarkGroup(p, edited(price: 2000, value: 2));
      expect(cart(p).length, 3, reason: 'qator o\'chmaydi');
      expect(cart(p)[0].isDeleted, isTrue);
      expect(activeRows(p).length, 2);
    });
  });

  group('Marka guruhi — qty oshirib bo\'lmaydi', () {
    test('2 → 5: qator qo\'shilmaydi (yangi marka skanerlanishi kerak)',
        () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      await saveMarkGroup(p, edited(price: 2000, value: 5));
      expect(cart(p).length, 2);
    });

    test('teng qty: hech narsa o\'chmaydi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      await saveMarkGroup(p, edited(price: 2000, value: 2));
      expect(cart(p).length, 2);
      expect(p.getCurrentClient.deletedItems, isEmpty);
    });
  });

  group('Marka guruhi — qty 0 va bo\'sh guruh', () {
    test('qty 0 → butun guruh o\'chadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      await saveMarkGroup(p, edited(price: 2000, value: 0));
      expect(cart(p), isEmpty);
    });

    test('qty manfiy → butun guruh o\'chadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1')]);
      await saveMarkGroup(p, edited(price: 2000, value: -1));
      expect(cart(p), isEmpty);
    });

    test('guruhda aktiv marka bo\'lmasa hech narsa o\'zgarmaydi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1', deleted: true), makeSoldItem(price: 111)]);
      await saveMarkGroup(p, edited(price: 9999, value: 1));
      expect(cart(p).length, 2);
      expect(cart(p)[1].price, 111);
    });

    test('markirovkasiz qator guruhga kirmaydi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), makeSoldItem(productId: kPid, price: 111)]);
      await saveMarkGroup(p, edited(price: 5000, value: 1));
      expect(cart(p)[1].price, 111, reason: 'oddiy qator guruhdan tashqarida');
    });

    test('boshqa mahsulotning markasiga tegilmaydi', () async {
      final p = freshProvider();
      cart(p).addAll([
        mark('m1'),
        makeSoldItem(
            productId: 'boshqa-id', price: 111, marking: true, mark: 'x1'),
      ]);
      await saveMarkGroup(p, edited(price: 5000, value: 1));
      expect(cart(p)[1].price, 111);
    });
  });

  group('Marka guruhi — narx va maydonlar', () {
    test('narx guruhdagi BARCHA markalarga qo\'llanadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2'), mark('m3')]);
      await saveMarkGroup(p, edited(price: 4000, value: 3));
      expect(cart(p).map((e) => e.price), [4000, 4000, 4000]);
    });

    test('realPrice, onlyPrice ham ko\'chadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      await saveMarkGroup(p, edited(price: 4000, value: 2));
      expect(cart(p)[1].realPrice, 4000);
      expect(cart(p)[1].onlyPrice, 4000);
    });

    test('VAT qatorning O\'Z vatPercent i bo\'yicha hisoblanadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      await saveMarkGroup(p, edited(price: 4480, value: 2));
      expect(cart(p)[0].vat, closeTo(4480 * 12 / 112, 0.001));
    });

    test('tin (komissiya INN) ko\'chadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      await saveMarkGroup(p, edited(price: 4000, value: 2, tin: '123456789'));
      expect(cart(p)[1].tin, '123456789');
    });

    test('qty kamayishi va narx o\'zgarishi BIRGA ishlaydi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2'), mark('m3')]);
      await saveMarkGroup(p, edited(price: 4000, value: 2));
      expect(cart(p).length, 2);
      expect(cart(p).map((e) => e.price), [4000, 4000]);
    });

    test('qo\'lda narx blok qatoriga ham sinxronlanadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), box(price: 24000)]);
      await saveMarkGroup(p, edited(price: 3000, value: 1, manual: true));
      expect(cart(p)[1].price, 3000 * kBox);
    });

    test('qo\'lda EMAS narxda blok qatori tier bo\'yicha qayta narxlanadi',
        () async {
      final m = ItemModel();
      m.id = kPid;
      m.name = 'Suv';
      m.vat = Vat(percentage: 12);
      m.measurementUnit = MeasurementUnit(shortName: 'dona');
      m.shopPrices = ShopPrices(
        shID: ShID(shopId: 'shop-1', shopPriceTiers: [
          ShopPriceTiers(minQuantity: 1, retailPrice: 5000),
          ShopPriceTiers(minQuantity: 12, retailPrice: 4500),
        ]),
      );
      ItemsSingleton.products = [m];

      final p = freshProvider();
      cart(p).addAll([mark('m1'), box(price: 1)]);
      // 1 marka + 12 blok donasi = 13 dona → 2-tier (4500)
      await saveMarkGroup(p, edited(price: 4500, value: 1));
      expect(cart(p)[1].price, 4500 * kBox);
    });
  });

  group('Marka guruhini butunlay o\'chirish (dialog "O\'chirish")', () {
    test('barcha markalar savatdan chiqadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2'), mark('m3')]);
      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();
      expect(cart(p), isEmpty);
    });

    test('boshqa mahsulot qatori qoladi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), makeSoldItem(productId: 'boshqa', price: 77)]);
      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();
      expect(cart(p).length, 1);
      expect(cart(p)[0].price, 77);
    });

    test('qizil o\'chirishda qatorlar isDeleted bo\'lib qoladi', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();
      expect(cart(p).length, 2);
      expect(cart(p).every((e) => e.isDeleted == true), isTrue);
    });

    test('hammasi o\'chgach mijoz tanlovi bekor qilinadi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1')]);
      p.setNewClientDiscountPercentage(10);
      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();
      expect(p.getCurrentClient.selectedClient, isNull);
    });

    test('savat sotuvsiz bo\'shasa o\'chirilganlar "-" deb belgilanadi',
        () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();
      expect(p.getCurrentClient.deletedItems.length, 2);
      expect(p.getCurrentClient.deletedItems.every((d) => d.checkNumber == '-'),
          isTrue);
    });

    test('savatda boshqa mahsulot qolsa "-" qo\'yilmaydi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), makeSoldItem(productId: 'boshqa')]);
      p.beginMarkGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endMarkGroupEdit();
      expect(p.getCurrentClient.deletedItems.first.checkNumber, isEmpty);
    });
  });

  group('Blok guruhi — qty', () {
    test('3 blok → 2: eng yangi blok chiqadi', () async {
      final p = freshProvider();
      cart(p).addAll([box(), box(), box()]);
      await saveBoxGroup(
          p, edited(price: 24000, value: 2, saleType: 2, boxValue: kBox));
      expect(cart(p).length, 2);
    });

    test('qty 0 → butun blok guruhi o\'chadi', () async {
      final p = freshProvider();
      cart(p).addAll([box(), box()]);
      await saveBoxGroup(
          p, edited(price: 24000, value: 0, saleType: 2, boxValue: kBox));
      expect(cart(p), isEmpty);
    });

    test('qty oshirib bo\'lmaydi (1 → 4)', () async {
      final p = freshProvider();
      cart(p).addAll([box()]);
      await saveBoxGroup(
          p, edited(price: 24000, value: 4, saleType: 2, boxValue: kBox));
      expect(cart(p).length, 1);
    });

    test('dona qatori blok guruhiga kirmaydi', () async {
      final p = freshProvider();
      cart(p).addAll([box(), makeSoldItem(productId: kPid, price: 111)]);
      await saveBoxGroup(
          p, edited(price: 24000, value: 0, saleType: 2, boxValue: kBox));
      expect(cart(p).length, 1);
      expect(cart(p)[0].price, 111);
    });

    test('aktiv blok bo\'lmasa hech narsa o\'zgarmaydi', () async {
      final p = freshProvider();
      cart(p).addAll([box(deleted: true), makeSoldItem(price: 111)]);
      await saveBoxGroup(
          p, edited(price: 9999, value: 1, saleType: 2, boxValue: kBox));
      expect(cart(p).length, 2);
      expect(cart(p)[1].price, 111);
    });

    test('qizil o\'chirishda blok qatori savatda qoladi', () async {
      await Pref.setBool(PrefKeys.isRedDeleteActivated, true);
      final p = freshProvider();
      cart(p).addAll([box(), box()]);
      await saveBoxGroup(
          p, edited(price: 24000, value: 1, saleType: 2, boxValue: kBox));
      expect(cart(p).length, 2);
      expect(activeRows(p).length, 1);
    });
  });

  group('Blok guruhi — narx', () {
    test('qo\'lda narx qolgan bloklarga aynan qo\'llanadi', () async {
      final p = freshProvider();
      cart(p).addAll([box(), box()]);
      await saveBoxGroup(
          p,
          edited(
              price: 36000,
              value: 2,
              saleType: 2,
              boxValue: kBox,
              manual: true));
      expect(cart(p).map((e) => e.price), [36000, 36000]);
    });

    test('qo\'lda narx blok qatorlarini manual deb belgilaydi', () async {
      final p = freshProvider();
      cart(p).addAll([box()]);
      await saveBoxGroup(
          p,
          edited(
              price: 36000,
              value: 1,
              saleType: 2,
              boxValue: kBox,
              manual: true));
      expect(cart(p)[0].isPriceOnlyChanged, isTrue);
    });

    test('qo\'lda narx dona qatoriga bo\'linib sinxronlanadi', () async {
      final p = freshProvider();
      cart(p).addAll([box(), makeSoldItem(productId: kPid, price: 2000)]);
      await saveBoxGroup(
          p,
          edited(
              price: 36000,
              value: 1,
              saleType: 2,
              boxValue: kBox,
              manual: true));
      expect(cart(p)[1].price, 3000, reason: '36000 / 12');
    });

    test('qo\'lda EMAS narxda tier reprice yo\'li ishlaydi', () async {
      final m = ItemModel();
      m.id = kPid;
      m.name = 'Suv';
      m.vat = Vat(percentage: 12);
      m.measurementUnit = MeasurementUnit(shortName: 'dona');
      m.shopPrices = ShopPrices(
        shID: ShID(shopId: 'shop-1', shopPriceTiers: [
          ShopPriceTiers(minQuantity: 1, retailPrice: 5000),
          ShopPriceTiers(minQuantity: 12, retailPrice: 4500),
        ]),
      );
      ItemsSingleton.products = [m];

      final p = freshProvider();
      cart(p).addAll([box(price: 1)]);
      await saveBoxGroup(
          p, edited(price: 1, value: 1, saleType: 2, boxValue: kBox));
      expect(cart(p)[0].price, 4500 * kBox);
    });
  });

  group('Blok guruhini butunlay o\'chirish', () {
    test('barcha bloklar chiqadi', () async {
      final p = freshProvider();
      cart(p).addAll([box(), box()]);
      p.beginBoxGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endBoxGroupEdit();
      expect(cart(p), isEmpty);
    });

    test('savat bo\'shasa o\'chirilganlar "-" deb belgilanadi', () async {
      final p = freshProvider();
      cart(p).addAll([box()]);
      p.beginBoxGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endBoxGroupEdit();
      expect(p.getCurrentClient.deletedItems.first.checkNumber, '-');
    });
  });

  group('notifyListeners ulanishi', () {
    test('marka guruhini saqlash UI ni xabardor qiladi', () async {
      final p = freshProvider();
      cart(p).addAll([mark('m1'), mark('m2')]);
      var n = 0;
      p.addListener(() => n++);
      await saveMarkGroup(p, edited(price: 4000, value: 1));
      expect(n, greaterThan(0));
    });

    test('blok guruhini o\'chirish UI ni xabardor qiladi', () async {
      final p = freshProvider();
      cart(p).addAll([box()]);
      var n = 0;
      p.addListener(() => n++);
      p.beginBoxGroupEdit(kPid);
      p.tapIndexToEdit(0);
      p.pressDialogDeleteButton();
      p.endBoxGroupEdit();
      expect(n, greaterThan(0));
    });
  });
}
