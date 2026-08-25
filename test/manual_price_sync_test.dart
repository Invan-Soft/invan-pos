// Qo'lda o'zgartirilgan narxni mahsulotning BARCHA qatorlariga sinxronlash.
//
// Mavjud qamrov (`box_price_edit_sync_test`, `mark_block_manual_price_test`)
// asosiy yo'nalishlarni (blok ⇄ dona, marka guruhi) tekshiradi. Bu fayl
// Faza 9.1 ko'chirishidan oldin QOLGAN shoxlarni yopadi: skip shartlari
// (o'chirilgan / tekin sovg'a / o'zi), maydonlarning ko'chishi
// (singleDiscount masshtabi, discountPercent, VAT, bayroqlar) va
// diskont ro'yxatlarining tozalanishi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/discount_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

const kPid = 'suv-id';
const kBox = 12;

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

/// OPD "Saqlash": [index] qatorini [edited] bilan almashtiradi.
Future<void> save(
    OrderingProvider4 p, int index, ReceiptModelSoldItem4 edited) async {
  p.tapIndexToEdit(index);
  await p.pressDialogSaveButton(edited);
}

/// Qo'lda narxi o'zgartirilgan tahrir nusxasi.
ReceiptModelSoldItem4 manualEdit({
  String productId = kPid,
  required double price,
  double value = 1,
  int saleType = 1,
  int boxValue = 0,
  double singleDiscount = 0,
  double discountPercent = 0,
}) {
  final item = makeSoldItem(
    productId: productId,
    price: price,
    value: value,
    saleType: saleType,
    boxValue: boxValue,
    singleDiscount: singleDiscount,
    isPriceOnlyChanged: true,
    isPriceChanged: true,
  );
  item.discountPercent = discountPercent;
  return item;
}

void main() {
  setUpAll(() => setUpPosTestEnv('manual_price_sync_test'));
  tearDownAll(tearDownPosTestEnv);

  // Katalog bo'sh: tier reprice early-return qiladi, shuning uchun testlar
  // FAQAT manual sinxronni o'lchaydi (tier aralashmaydi).
  setUp(() => ItemsSingleton.products = []);

  group('Sinxron ishga tushish sharti', () {
    test('narx o\'zgarmagan bo\'lsa (faqat qty) boshqa qatorga tegilmaydi',
        () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000, value: 2))
        ..add(makeSoldItem(
            productId: kPid, price: 24000, value: 1, saleType: 2, boxValue: kBox));
      await save(p, 0, manualEdit(price: 2000, value: 1));
      expect(cart(p)[1].price, 24000);
    });

    test('isPriceOnlyChanged bo\'lmasa sinxron bo\'lmaydi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(productId: kPid, price: 2000, value: 3));
      final edited = makeSoldItem(productId: kPid, price: 9999);
      await save(p, 0, edited);
      expect(cart(p)[1].price, 2000);
    });

    test('productId bo\'sh bo\'lsa hech narsa sinxronlanmaydi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: '', price: 2000))
        ..add(makeSoldItem(productId: '', price: 2000));
      await save(p, 0, manualEdit(productId: '', price: 5000));
      expect(cart(p)[1].price, 2000);
    });

    test('boshqa mahsulot qatoriga tegilmaydi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(productId: 'boshqa-id', price: 2000));
      await save(p, 0, manualEdit(price: 5000));
      expect(cart(p)[1].price, 2000);
    });
  });

  group('Skip shartlari', () {
    test('o\'chirilgan qator sinxronlanmaydi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(productId: kPid, price: 2000, isDeleted: true));
      await save(p, 0, manualEdit(price: 5000));
      expect(cart(p)[1].price, 2000);
      expect(cart(p)[1].isPriceOnlyChanged, isFalse);
    });

    test('tekin sovg\'a qatori sinxronlanmaydi (narxi 0 qoladi)', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(productId: kPid, price: 0, isFreeGift: true));
      await save(p, 0, manualEdit(price: 5000));
      expect(cart(p)[1].price, 0);
    });

    test('tahrirlangan qatorning o\'zi qayta hisoblanmaydi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(productId: kPid, price: 2000));
      final edited = manualEdit(price: 5000, singleDiscount: 300);
      await save(p, 0, edited);
      expect(cart(p)[0].price, 5000);
      expect(cart(p)[0].singleDiscount, 300, reason: 'aynan berilgani qoladi');
    });
  });

  group('Maydonlarning ko\'chishi', () {
    test('singleDiscount dona bazasida masshtablanadi (dona → blok)', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(
            productId: kPid, price: 24000, saleType: 2, boxValue: kBox));
      await save(p, 0, manualEdit(price: 3000, singleDiscount: 500));
      expect(cart(p)[1].price, 3000 * kBox);
      expect(cart(p)[1].singleDiscount, 500 * kBox);
    });

    test('singleDiscount blokdan donaga bo\'linadi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(
            productId: kPid, price: 24000, saleType: 2, boxValue: kBox))
        ..add(makeSoldItem(productId: kPid, price: 2000));
      await save(
          p,
          0,
          manualEdit(
              price: 36000, saleType: 2, boxValue: kBox, singleDiscount: 1200));
      expect(cart(p)[1].price, 3000);
      expect(cart(p)[1].singleDiscount, 100, reason: '1200 / 12');
    });

    test('discountPercent tahrirdan ko\'chiriladi (masshtabsiz)', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(
            productId: kPid, price: 24000, saleType: 2, boxValue: kBox));
      await save(p, 0, manualEdit(price: 3000, discountPercent: 15));
      expect(cart(p)[1].discountPercent, 15);
    });

    test('realPrice va onlyPrice ham masshtablanadi', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(
            productId: kPid, price: 24000, saleType: 2, boxValue: kBox));
      await save(p, 0, manualEdit(price: 3000));
      expect(cart(p)[1].realPrice, 3000 * kBox);
      expect(cart(p)[1].onlyPrice, 3000 * kBox);
    });

    test('VAT qatorning O\'Z vatPercent i bo\'yicha qayta hisoblanadi',
        () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000, vatPercent: 12))
        ..add(makeSoldItem(productId: kPid, price: 2000, vatPercent: 0));
      await save(p, 0, manualEdit(price: 5000));
      expect(cart(p)[1].vat, 0, reason: '0% qatorda VAT 0 bo\'ladi');
    });

    test('narx 0 bo\'lsa VAT ham 0', () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(productId: kPid, price: 2000));
      await save(p, 0, manualEdit(price: 0));
      expect(cart(p)[1].price, 0);
      expect(cart(p)[1].vat, 0);
    });

    test('sinxronlangan qator manual deb belgilanadi (ikkala bayroq)',
        () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(productId: kPid, price: 2000));
      await save(p, 0, manualEdit(price: 5000));
      expect(cart(p)[1].isPriceOnlyChanged, isTrue);
      expect(cart(p)[1].isPriceChanged, isTrue);
    });
  });

  group('Diskont ro\'yxatlari tozalanadi', () {
    test('discount ro\'yxati bo\'shatiladi (qo\'lda narx = diskontsiz sotuv)',
        () async {
      final p = freshProvider();
      final other = makeSoldItem(productId: kPid, price: 2000);
      other.discount.add(DiscountModel(
          idd: 'd1', name: 'aksiya', total: 500, type: 'sum', value: 500));
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(other);
      await save(p, 0, manualEdit(price: 5000));
      expect(cart(p)[1].discount, isEmpty);
    });
  });

  group('Uch qatorli savat', () {
    test('dona narxi o\'zgarsa qolgan IKKALA qator ham sinxronlanadi',
        () async {
      final p = freshProvider();
      cart(p)
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(productId: kPid, price: 2000))
        ..add(makeSoldItem(
            productId: kPid, price: 24000, saleType: 2, boxValue: kBox));
      await save(p, 0, manualEdit(price: 3000));
      expect(cart(p)[1].price, 3000);
      expect(cart(p)[2].price, 3000 * kBox);
    });
  });
}
