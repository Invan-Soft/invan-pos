// BLOK tovar + DISKONT birgalikda — xarakteristik test.
//
// NEGA KERAK: ko'chirilgan diskont kodida blok mantiqi 11 joyda bor
// (saleType == 2 -> value × boxValue). Lekin diskont testlarining hammasi
// dona hisobida edi, blok testlari esa (box_price_edit_sync, box_return_block)
// diskontsiz ishlaydi. Ya'ni "blok + diskont" kombinatsiyasi hech qayerda
// tekshirilmagan edi — bu eng zaif nuqta.
//
// Blok semantikasi: qator value = BLOK soni, boxValue = blokdagi dona soni.
// Effektiv dona = value × boxValue. Narx esa BLOK narxi (dona narxi × boxValue).
//
// MUHIM: "to'g'rimi?" emas, "hozir nima bo'lyapti?" yoziladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_discounts/model/discounts_response.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStoreId = 'shop-1';
const kSuvId = 'suv-id'; // blokli suv
const kBoxValue = 12; // 1 blok = 12 dona
const kUnitPrice = 5000.0; // 1 dona narxi
const kBoxPrice = kUnitPrice * kBoxValue; // 60000

const gGroupBuyXGetX = '316b623e-3bb7-43e2-b6d5-1028c927caba';
const gTypeBuyXGetX = '90d1f774-44bd-49be-9bbf-2e9a44558377';
const gGroupBuyXGetY = '86951e75-960f-45d7-9505-9b9cd2ce17a7';
const gTypeBuyXGetY = 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b';

ItemModel productWithPrice(String id, String name, num retailPrice) {
  final m = ItemModel();
  m.id = id;
  m.name = name;
  m.shopPrices = ShopPrices(
    shID: ShID(
      shopId: kStoreId,
      shopPriceTiers: [ShopPriceTiers(minQuantity: 1, retailPrice: retailPrice)],
    ),
  );
  return m;
}

DiscountItem bxgx({required int buy, required int get, bool repeat = false}) =>
    DiscountItem(
      id: 'bxgx-box',
      name: 'Buy X Get X',
      displayName: 'Blok aksiya',
      discountGroupType: DiscountGroupType(id: gGroupBuyXGetX),
      discountType: DiscountType(id: gTypeBuyXGetX),
      isExpirable: false,
      isForAllClients: true,
      isRepeatable: repeat,
      shopIds: [ShopIds(id: kStoreId)],
      buyXGetX: BuyXGetX(
        productsToBuy: [ProductsToBuy(id: kSuvId, name: 'Suv')],
        buyProductsAmount: buy,
        getProductsAmount: get,
      ),
    );

Future<void> seed(List<DiscountItem> d) async {
  final box = HiveBoxes.getDiscounts();
  await box.clear();
  await box.addAll(d);
}

/// Blok qatori: value = blok soni, price = blok narxi.
ReceiptModelSoldItem4 boxRow(double boxQty) => makeSoldItem(
      productId: kSuvId,
      name: 'Suv 1L (blok)',
      price: kBoxPrice,
      value: boxQty,
      saleType: 2,
      boxValue: kBoxValue,
      boxQuantity: boxQty.toInt(),
    );

/// Dona qatori.
ReceiptModelSoldItem4 unitRow(double qty) => makeSoldItem(
      productId: kSuvId,
      name: 'Suv 1L',
      price: kUnitPrice,
      value: qty,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('discount_box_test');
    await Pref.setString(PrefKeys.storeId, kStoreId);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [productWithPrice(kSuvId, 'Suv 1L', kUnitPrice)];
  });

  tearDown(() => HiveBoxes.getDiscounts().clear());

  OrderingProvider4 cartOf(List<ReceiptModelSoldItem4> rows) {
    final p = freshProvider();
    p.getCurrentClient.orderedProducts.addAll(rows);
    return p;
  }

  ReceiptModelSoldItem4 boxOf(OrderingProvider4 p) =>
      p.getCurrentClient.orderedProducts.firstWhere((e) => e.saleType == 2);
  ReceiptModelSoldItem4 unitOf(OrderingProvider4 p) =>
      p.getCurrentClient.orderedProducts.firstWhere((e) => e.saleType != 2);

  group('Blok dona hisobida ko\'riladi (effektiv qty = value × boxValue)', () {
    test('1 blok (12 dona) "10 olsang 2 tekin" shartini qondiradi', () async {
      await seed([bxgx(buy: 10, get: 2)]);
      final p = cartOf([boxRow(1)]);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // setSize = 12, effektiv qty = 12 -> 2 tekin, paid = 10, ratio = 10/12
      expect(boxOf(p).discountPercent, closeTo(100 - (10 / 12 * 100), 0.001));
      expect(boxOf(p).price, closeTo(boxOf(p).realPrice * (10 / 12), 0.001));
    });

    test('blok narxi dona narxidan boxValue marta katta bo\'lib qoladi',
        () async {
      await seed([bxgx(buy: 10, get: 2)]);
      final p = cartOf([boxRow(1)]);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // realPrice blok narxi bo'lib qolishi kerak (dona narxi × 12), 5000 emas
      expect(boxOf(p).realPrice, kBoxPrice);
    });

    test('shart qondirilmasa (setSize > 12 dona) tegilmaydi', () async {
      await seed([bxgx(buy: 20, get: 5)]);
      final p = cartOf([boxRow(1)]);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      expect(boxOf(p).price, kBoxPrice);
      expect(boxOf(p).singleDiscount, 0);
    });
  });

  group('Blok + dona bir savatda', () {
    // ⚠️ QAYD ETILGAN XATTI-HARAKAT (tuzatilmadi — 4-qoida)
    //
    // Aralash savatda (blok + dona) kod `perSetSize = buyAmount × 2` deb
    // hisoblaydi, ya'ni "get == buy" (simmetrik) deb FARAZ qiladi — kodning
    // o'z izohi ham shuni aytadi:
    //   "BuyXGetX: perSetGet == perSetBuy (symmetric), perSet = buy + get"
    //
    // Shuning uchun buy=10, get=2 bo'lganda perSetSize = 20 bo'lib qoladi
    // (aslida 12 bo'lishi kerak edi). 1 blok = 12 dona < 20 -> blok qatori
    // uchun naturalCap = 0 -> blokka chegirma UMUMAN tegmaydi.
    //
    // Bu refaktoringdan OLDIN ham shunday edi (kod bayt-ma-bayt bir xil,
    // ayyubxon branchi bilan solishtirilgan). Test hozirgi holatni
    // muzlatadi; to'g'ri yoki noto'g'ri ekani alohida ko'rib chiqilishi kerak.
    test('QAYD: get != buy bo\'lsa aralash savatda blokka chegirma tegmaydi',
        () async {
      // 1 blok (12) + 3 dona = 15 dona; "10 olsang 2 tekin"
      await seed([bxgx(buy: 10, get: 2)]);
      final p = cartOf([boxRow(1), unitRow(3)]);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // Dona qatoriga tegadi (naturalCap = itemQty)
      expect(unitOf(p).singleDiscount, greaterThan(0));
      // Blok qatoriga TEGMAYDI: (12 / 20).floor() × 10 = 0
      expect(boxOf(p).singleDiscount, 0);
    });

    test('get == buy (simmetrik) bo\'lsa blokka ham chegirma tegadi', () async {
      // Kod aynan shu holatga mo'ljallangan: perSetSize = 6 × 2 = 12
      await seed([bxgx(buy: 6, get: 6)]);
      final p = cartOf([boxRow(1), unitRow(3)]);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      expect(boxOf(p).singleDiscount, greaterThan(0));
    });

    test('dona qatori narxi blok narxiga aylanib ketmaydi', () async {
      await seed([bxgx(buy: 10, get: 2)]);
      final p = cartOf([boxRow(1), unitRow(3)]);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // Dona qatori realPrice dona narxida qolishi kerak
      expect(unitOf(p).realPrice, kUnitPrice);
      expect(boxOf(p).realPrice, kBoxPrice);
    });
  });

  group('Takrorlanadigan aksiya blokda', () {
    test('2 blok (24 dona), 10+2: 2 set -> 4 tekin', () async {
      await seed([bxgx(buy: 10, get: 2, repeat: true)]);
      final p = cartOf([boxRow(2)]);

      p.findFreeProducts();
      p.useBuyXGetXProducts();

      // setSize = 12; 24/12 = 2 set -> 4 tekin; paid = 20; ratio = 20/24
      expect(boxOf(p).price, closeTo(boxOf(p).realPrice * (20 / 24), 0.001));
    });
  });

  group('Buy X Get Y — blok sotib olinadi, dona tekin beriladi', () {
    test('1 blok suv olsa, tekin mahsulot beriladi', () async {
      await seed([
        DiscountItem(
          id: 'bxgy-box',
          name: 'BXGY',
          displayName: 'Blok olsang sovg\'a',
          discountGroupType: DiscountGroupType(id: gGroupBuyXGetY),
          discountType: DiscountType(id: gTypeBuyXGetY),
          isExpirable: false,
          isForAllClients: true,
          shopIds: [ShopIds(id: kStoreId)],
          buyXGetY: BuyXGetY(
            productsToBuy: [ProductsToBuy(id: kSuvId, name: 'Suv')],
            buyProductsAmount: 12, // 12 dona = 1 blok
            productToGet: ProductsToGet(id: 'gift-id', name: 'Sovg\'a'),
            getProductsAmount: 1,
          ),
        ),
      ]);
      ItemsSingleton.products = [
        productWithPrice(kSuvId, 'Suv 1L', kUnitPrice),
        productWithPrice('gift-id', 'Sovg\'a', 3000),
      ];
      final p = cartOf([
        boxRow(1),
        makeSoldItem(productId: 'gift-id', name: 'Sovg\'a', price: 3000),
      ]);

      p.findFreeProducts();
      p.useFreeProducts();

      final gift = p.getCurrentClient.orderedProducts
          .firstWhere((e) => e.productId == 'gift-id');
      expect(gift.price, 0);
      expect(gift.discountPercent, 100);
    });
  });

  group('clearAllDiscountEffects blokda', () {
    test('blok narxi asl holatiga qaytadi', () async {
      await seed([bxgx(buy: 10, get: 2)]);
      final p = cartOf([boxRow(1)]);
      p.findFreeProducts();
      p.useBuyXGetXProducts();

      p.clearAllDiscountEffects();

      expect(boxOf(p).price, boxOf(p).realPrice);
      expect(boxOf(p).singleDiscount, 0);
      expect(boxOf(p).productDiscount, isEmpty);
    });
  });
}
