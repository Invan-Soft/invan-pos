// Mijoz foizli chegirmasi — `setNewClientDiscountPercentage`.
//
// Mijoz kartasidagi foiz savatning HAR qatoriga qo'llanadi: narx tushadi,
// chekka "sum" turidagi chegirma qatori yoziladi va `discountPercent`
// katalog narxiga nisbatan hisoblanadi. Bu pul bilan bog'liq matematika,
// lekin hozirgacha bironta test uni tekshirmagan.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/discount_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import 'support/provider_harness.dart';

const kPid = 'suv-id';

ItemModel product({num retailPrice = 10000}) {
  final m = ItemModel();
  m.id = kPid;
  m.name = 'Suv';
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: 'shop-1', shopPriceTiers: [
      ShopPriceTiers(minQuantity: 1, retailPrice: retailPrice),
    ]),
  );
  return m;
}

List<ReceiptModelSoldItem4> cart(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

OrderingProvider4 withCart(List<ReceiptModelSoldItem4> rows) {
  final p = freshProvider();
  cart(p).addAll(rows);
  return p;
}

void main() {
  setUpAll(() => setUpPosTestEnv('client_discount_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(() => ItemsSingleton.products = [product()]);

  group('Narx hisobi', () {
    test('10% → narx 10 000 dan 9 000 ga tushadi', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).first.price, 9000);
    });

    test('0% → narx o\'zgarmaydi', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      p.setNewClientDiscountPercentage(0);
      expect(cart(p).first.price, 10000);
    });

    test('100% → narx 0', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      p.setNewClientDiscountPercentage(100);
      expect(cart(p).first.price, 0);
    });

    test('kasrli foiz (12.5%)', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      p.setNewClientDiscountPercentage(12.5);
      expect(cart(p).first.price, 8750);
    });

    test('foiz JORIY narxdan hisoblanadi (katalog narxidan emas)', () {
      // Qator allaqachon 8 000 ga tushirilgan; 10% shundan olinadi.
      final p = withCart([makeSoldItem(productId: kPid, price: 8000)]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).first.price, 7200);
    });
  });

  group('discountPercent — katalog narxiga nisbatan', () {
    test('joriy narx katalog narxiga teng bo\'lsa foiz aynan o\'sha', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).first.discountPercent, closeTo(10, 0.001));
    });

    test('joriy narx allaqachon pastroq bo\'lsa foiz KATTAROQ chiqadi', () {
      // katalog 10 000, joriy 8 000, 10% → 7 200 → katalogdan 28%
      final p = withCart([makeSoldItem(productId: kPid, price: 8000)]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).first.discountPercent, closeTo(28, 0.001));
    });

    test('narx o\'zgarganini bildiruvchi bayroq qo\'yiladi', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).first.isPriceChanged, isTrue);
    });
  });

  group('Chekka yoziladigan chegirma qatori', () {
    test('"sum" turidagi chegirma qo\'shiladi', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      p.setNewClientDiscountPercentage(10);
      final d = cart(p).first.discount.single;
      expect(d.type, 'sum');
      expect(d.value, 1000);
    });

    test('avvalgi "sum" chegirmasi olib tashlanadi', () {
      final row = makeSoldItem(productId: kPid, price: 10000);
      row.discount.add(DiscountModel(
          idd: 'eski', name: 'eski', total: 500, type: 'sum', value: 500));
      final p = withCart([row]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).first.discount.length, 1);
      expect(cart(p).first.discount.single.value, 1000);
    });

    test('"sum" bo\'lmagan chegirma saqlanadi', () {
      final row = makeSoldItem(productId: kPid, price: 10000);
      row.discount.add(DiscountModel(
          idd: 'p', name: 'promo', total: 0, type: 'percent', value: 5));
      final p = withCart([row]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).first.discount.map((e) => e.type), ['percent', 'sum']);
    });

    test('QAYD: ketma-ket ikkita "sum" bo\'lsa bittasi qolib ketadi', () {
      // Ichki tsikl o'chirish paytida indeksni surmaydi — ikkinchisi
      // o'tkazib yuboriladi. Hozirgi xatti-harakat, muzlatilgan.
      final row = makeSoldItem(productId: kPid, price: 10000);
      row.discount.addAll([
        DiscountModel(idd: 'a', name: 'a', total: 1, type: 'sum', value: 1),
        DiscountModel(idd: 'b', name: 'b', total: 2, type: 'sum', value: 2),
      ]);
      final p = withCart([row]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).first.discount.length, 2,
          reason: 'bittasi o\'chdi, bittasi qoldi, yangisi qo\'shildi');
    });
  });

  group('Savat va chetki holatlar', () {
    test('bo\'sh savatda xato bermaydi', () {
      final p = freshProvider();
      expect(() => p.setNewClientDiscountPercentage(10), returnsNormally);
    });

    test('bir nechta qator — hammasiga qo\'llanadi', () {
      final p = withCart([
        makeSoldItem(productId: kPid, price: 10000),
        makeSoldItem(productId: kPid, price: 10000),
      ]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).map((e) => e.price), [9000, 9000]);
    });

    test('savat qatorlari soni o\'zgarmaydi', () {
      final p = withCart([
        makeSoldItem(productId: kPid, price: 10000),
        makeSoldItem(productId: 'boshqa', price: 5000),
      ]);
      p.setNewClientDiscountPercentage(10);
      expect(cart(p).length, 2);
    });

    test('foiz saqlanadi (getter orqali o\'qiladi)', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      p.setNewClientDiscountPercentage(15);
      expect(p.getNewClientDiscountPercentage, 15);
    });

    test('notifyListeners chaqiriladi', () {
      final p = withCart([makeSoldItem(productId: kPid, price: 10000)]);
      var n = 0;
      p.addListener(() => n++);
      p.setNewClientDiscountPercentage(10);
      expect(n, 1);
    });
  });
}
