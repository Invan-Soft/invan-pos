// Notification orqali kelgan mahsulot/narxning lokal katalogga qo'llanishi.
//
// Uchta tirqich yopilgani tekshiriladi:
//   * type 13 (narx) — mahsulotda hali shu do'kon narxi bo'lmasa ham
//     yaratiladi (ilgari faqat mavjud tier ro'yxati yangilanardi va narx
//     hech qachon yetib bormasdi);
//   * type 2 (yangilash) payload'ida `shop_prices` bo'lmasa mavjud narx
//     saqlanadi (ilgari mahsulot to'liq ustidan yozilib narxsiz qolardi);
//   * `images: []` va `category_ids: null` parserni yiqitmaydi (ilgari
//     RangeError/TypeError butun oynani abadiy bloklardi).

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/dialogs/creat_product/model/mes_vat_unit_model/mes_unit.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/product_price_edit_response.dart';
import 'package:invan2/changes/services/web_socket_service/product/products_ws_service.dart';
import 'package:invan2/features/get_categories/model/category.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kShop = 'shop-1';
const kOtherShop = 'shop-2';

ItemModel product(String id, {ShopPrices? price, List<String>? barcode}) =>
    ItemModel(
      id: id,
      sku: '1$id',
      name: 'Mahsulot $id',
      isActive: true,
      isMarking: false,
      barcode: barcode ?? ['478000$id'],
      shopPrices: price,
    );

ShopPrices priceOf(num retail, {String shop = kShop}) => ShopPrices(
      shID: ShID(
        shopId: shop,
        supplyPrice: retail - 100,
        shopPriceTiers: [ShopPriceTiers(minQuantity: 1, retailPrice: retail)],
      ),
    );

/// type 13 notification (server shakli).
ProductPriceEdit priceNotification(String productId, num retail,
        {String shop = kShop}) =>
    ProductPriceEdit.fromJson({
      'id': 'n-$productId',
      'type': 13,
      'data': {
        'product_values': [
          {
            'product_id': productId,
            'price': {
              'shop_id': shop,
              'retail_price': retail,
              'supply_price': retail - 100,
              'shop_price_tiers': [
                {'min_quantity': 1, 'retail_price': retail},
              ],
            },
          },
        ],
      },
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('items_singleton_notification_test',
        withEmployee: false);

    void reg<T>(int typeId, TypeAdapter<T> adapter) {
      if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
    }

    reg(ItemModelAdapter().typeId, ItemModelAdapter());
    reg(ShopPricesAdapter().typeId, ShopPricesAdapter());
    reg(ShIDAdapter().typeId, ShIDAdapter());
    reg(ShopPriceTiersAdapter().typeId, ShopPriceTiersAdapter());
    reg(CategoriesFromProductsAdapter().typeId,
        CategoriesFromProductsAdapter());
    reg(MeasurementUnitAdapter().typeId, MeasurementUnitAdapter());
    reg(VatAdapter().typeId, VatAdapter());
    reg(MesUnitModelAdapter().typeId, MesUnitModelAdapter());
    reg(VatUnitModelAdapter().typeId, VatUnitModelAdapter());

    await Hive.openBox<ItemModel>(HiveBoxNames.items);
    await Hive.openBox<MesUnitModel>(HiveBoxNames.mesUnit);
    await Hive.openBox<VatUnitModel>(HiveBoxNames.vatUnit);

    await Pref.setString(PrefKeys.storeId, kShop);
    await Pref.setString(PrefKeys.acceptService, kShop);
    await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
    await Pref.setString(PrefKeys.packageCode, '1');
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await HiveBoxes.getProducts().clear();
    await HiveBoxes.getCategories().clear();
    ItemsSingleton.clearTheProducts();
  });

  group('type 13 — narx (editItem)', () {
    test('narxi YO\'Q mahsulotga shu do\'kon narxi yaratiladi', () async {
      await ItemsSingleton.putItems([product('p1')]);
      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 0);

      final changed = await ItemsSingleton.editItem(priceNotification('p1', 5000));
      await ItemsSingleton.storeProducts();

      expect(changed, 1);
      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.shopPrices?.shID?.shopId, kShop);
      expect(ItemsSingleton.onePrice(saved.shopPrices), 5000);
      // Endi barcode skanerida ham topiladi (narx > 0 talab qilinadi).
      expect(ItemsSingleton.getProductByBarcode('478000p1')?.id, 'p1');
    });

    test('mavjud narx pog\'onalari almashtiriladi (eski xulq)', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      await ItemsSingleton.editItem(priceNotification('p1', 7000));

      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.shopPrices!.shID!.shopPriceTiers!.length, 1);
      expect(ItemsSingleton.onePrice(saved.shopPrices), 7000);
    });

    test('boshqa do\'kon narxi e\'tiborsiz qoladi', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      final changed = await ItemsSingleton.editItem(
          priceNotification('p1', 9999, shop: kOtherShop));

      expect(changed, 0);
      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 3000);
    });

    test('lokalda yo\'q mahsulot — hech narsa bo\'lmaydi, xato yo\'q', () async {
      final changed = await ItemsSingleton.editItem(priceNotification('ghost', 100));
      expect(changed, 0);
    });

    test('narx ma\'lumoti to\'liq bo\'lmasa (tiers yo\'q) o\'tkazib yuboriladi',
        () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);
      final edit = ProductPriceEdit.fromJson({
        'id': 'n', 'type': 13,
        'data': {
          'product_values': [
            {'product_id': 'p1', 'price': {'shop_id': kShop}},
          ],
        },
      });

      final changed = await ItemsSingleton.editItem(edit);

      expect(changed, 0);
      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 3000);
    });
  });

  group('type 1/2 — putItems va narxni saqlash', () {
    test(
        'mergeWithExisting + priceKeyPresent:false: shop_prices KALITI '
        'yo\'q bo\'lsa mavjud narx saqlanadi', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      // Adminkada faqat nom o'zgartirildi — payload'da shop_prices KALITI
      // umuman yo'q (ProductsWsService `data.containsKey('shop_prices')`
      // orqali shuni aniqlaydi).
      final update = product('p1')..name = 'Yangi nom';
      await ItemsSingleton.putItems([update],
          mergeWithExisting: true, priceKeyPresent: false);

      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.name, 'Yangi nom');
      expect(ItemsSingleton.onePrice(saved.shopPrices), 3000);
    });

    test(
        'priceKeyPresent:true (standart) — shop_prices KALITI bo\'lsa '
        'narxsiz yangilash ham narxni O\'CHIRADI (kalit yo\'qligi bilan '
        'chalkashtirilmaydi)', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      final update = product('p1')..name = 'Yangi nom';
      // priceKeyPresent standart bo'yicha true — bu chaqiruvchi shop_prices
      // KALITI payload'da BOR deb bilishini anglatadi (garchi natija narxi
      // bo'sh bo'lsa ham).
      await ItemsSingleton.putItems([update], mergeWithExisting: true);

      expect(HiveBoxes.getProducts().get('p1')!.shopPrices, isNull,
          reason: 'kalit bor edi — server ataylab narxni olib tashlagan '
              'deb hurmat qilinadi');
    });

    test('bayroqsiz (to\'liq yuklash kabi) narx ustidan yoziladi', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      await ItemsSingleton.putItems([product('p1')]);

      expect(HiveBoxes.getProducts().get('p1')!.shopPrices, isNull);
    });

    test('kelgan mahsulotda narx bo\'lsa u ustun', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      await ItemsSingleton.putItems([product('p1', price: priceOf(4500))],
          mergeWithExisting: true);

      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 4500);
    });

    test(
        'shop_prices KALITI bor-u, shu do\'kon narxi 0 (masalan '
        'retail_price:null) — server signali hurmat qilinadi, narx 0 '
        'bo\'ladi (eski narx SAQLANMAYDI)', () async {
      await ItemsSingleton.putItems([product('p1', price: priceOf(3000))]);

      // Jonli ko'rilgan shakl: tier bor, retail_price yo'q (null → 0).
      // `shop_prices` KALITI payload'da BOR — bu "narx yo'q" degan bilinch
      // signal emas, "narx 0/olib tashlangan" degan aniq signal.
      final incoming = product('p1',
          price: ShopPrices(
              shID: ShID(shopId: kShop, shopPriceTiers: [
            ShopPriceTiers(minQuantity: 1, retailPrice: null),
          ])));
      await ItemsSingleton.putItems([incoming], mergeWithExisting: true);

      expect(ItemsSingleton.onePrice(HiveBoxes.getProducts().get('p1')!.shopPrices), 0);
    });

    test('is_active YO\'Q (null) bo\'lsa mahsulot O\'CHIRILMAYDI', () async {
      final item = product('p1')..isActive = null;

      await ItemsSingleton.putItems([item], mergeWithExisting: true);

      expect(HiveBoxes.getProducts().get('p1'), isNotNull,
          reason: 'ilgari !(null ?? false) → o\'chirilardi');
    });

    test('is_active == false bo\'lsa o\'chiriladi', () async {
      await ItemsSingleton.putItems([product('p1')]);

      await ItemsSingleton.putItems([product('p1')..isActive = false],
          mergeWithExisting: true);

      expect(HiveBoxes.getProducts().get('p1'), isNull);
    });

    test('ownerType/commissionTin notification\'da yo\'q bo\'lsa mavjudi qoladi',
        () async {
      await ItemsSingleton.putItems([
        product('p1')
          ..ownerType = '2'
          ..commissionTin = '123456789'
      ]);

      await ItemsSingleton.putItems([product('p1')], mergeWithExisting: true);

      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.ownerType, '2');
      expect(saved.commissionTin, '123456789');

      // Kelgan qiymat bo'lsa u ustun.
      await ItemsSingleton.putItems([product('p1')..ownerType = '1'],
          mergeWithExisting: true);
      expect(HiveBoxes.getProducts().get('p1')!.ownerType, '1');
    });

    test('QQS/o\'lchov birligi lokalda topilmasa mavjudi qoladi', () async {
      await ItemsSingleton.putItems([
        product('p1')
          ..vat = Vat(id: 'vat-12', name: '12%', percentage: 12)
          ..measurementUnit = MeasurementUnit(id: 'u-1', longName: 'dona', shortName: 'd')
      ]);

      // Parser topolmagan → null keladi.
      await ItemsSingleton.putItems([product('p1')], mergeWithExisting: true);

      final saved = HiveBoxes.getProducts().get('p1')!;
      expect(saved.vat?.percentage, 12);
      expect(saved.measurementUnit?.id, 'u-1');
    });

    test('isMarking saqlanishi buzilmagan', () async {
      await ItemsSingleton.putItems([product('p1')..isMarking = true]);

      await ItemsSingleton.putItems([product('p1')], mergeWithExisting: true);

      expect(HiveBoxes.getProducts().get('p1')!.isMarking, isTrue);
    });
  });

  group('parser — buzuq payload oynani yiqitmaydi', () {
    Map<String, dynamic> payload({dynamic images, dynamic categoryIds}) => {
          'id': 'p-new',
          'sku': '777',
          'name': 'Rasmsiz mahsulot',
          'is_active': true,
          'barcode': ['4780001112223'],
          'images': images,
          'category_ids': categoryIds,
          'shop_prices': [
            {
              'shop_id': kShop,
              'supply_price': 900,
              'shop_price_tiers': [
                {'min_quantity': 1, 'retail_price': 1200},
              ],
            },
          ],
        };

    test('images: [] → rasm null, mahsulot saqlanadi', () {
      final item = ItemModel.fromWebSocketJson(payload(images: <dynamic>[]));
      expect(item.id, 'p-new');
      expect(item.image, isNull);
      expect(ItemsSingleton.onePrice(item.shopPrices), 1200);
    });

    test('images: [{image_url}] → to\'liq URL', () {
      final item = ItemModel.fromWebSocketJson(
          payload(images: [{'image_url': 'a/b.png'}]));
      expect(item.image, '${ApiProvider.imageUrl}a/b.png');
    });

    test('fromWebSocketJsonUpdate ham images: [] ga chidaydi', () {
      final item = ItemModel.fromWebSocketJsonUpdate(payload(images: <dynamic>[]));
      expect(item.id, 'p-new');
      expect(item.image, isNull);
    });

    test('type 1 parseri owner_type ni o\'qiydi (int kelsa ham)', () {
      final item = ItemModel.fromWebSocketJson(payload(images: null)..['owner_type'] = 2);
      expect(item.ownerType, '2');
    });

    test('min_quantity double / retail_price satr kelsa ham yiqilmaydi', () {
      final p = payload(images: null);
      (p['shop_prices'] as List)[0]['shop_price_tiers'] = [
        {'min_quantity': 1.0, 'retail_price': '1200'},
      ];
      final item = ItemModel.fromWebSocketJson(p);
      expect(item.shopPrices!.shID!.shopPriceTiers!.first.minQuantity, 1);
      expect(ItemsSingleton.onePrice(item.shopPrices), 1200);
    });

    test('ichki vat/measurement_unit obyekti bo\'lsa undan olinadi', () {
      final p = payload(images: null)
        ..['vat'] = {'id': 'vat-15', 'name': '15%', 'percentage': 15}
        ..['measurement_unit'] = {'id': 'u-kg', 'long_name': 'kilogramm', 'short_name': 'kg'};
      final item = ItemModel.fromWebSocketJson(p);
      expect(item.vat?.percentage, 15);
      expect(item.measurementUnit?.id, 'u-kg');
    });

    test('vat_id lokalda topilmasa null (bo\'sh obyekt emas)', () {
      final p = payload(images: null)..['vat_id'] = 'nomalum';
      final item = ItemModel.fromWebSocketJson(p);
      expect(item.vat, isNull);
    });

    test(
        'categories maydoni ikkala shaklda ham (sof id yoki obyekt '
        'ro\'yxati) xatosiz o\'qiladi — type 1 parseri ilgari faqat sof '
        'id\'ni kutar edi', () {
      final asIds =
          ItemModel.fromWebSocketJson(payload(images: null)..['categories'] = ['cat-1', 'cat-2']);
      expect(asIds.categories!.map((c) => c.id), ['cat-1', 'cat-2']);

      final asObjects = ItemModel.fromWebSocketJson(payload(images: null)
        ..['categories'] = [
          {'id': 'cat-1', 'name': 'Ichimlik', 'parent_id': null},
        ]);
      expect(asObjects.categories!.single.id, 'cat-1');
      expect(asObjects.categories!.single.name, 'Ichimlik');

      // fromWebSocketJsonUpdate (type 2) ham ikkala shaklga chidamli.
      final updateAsIds = ItemModel.fromWebSocketJsonUpdate(
          payload(images: null)..['categories'] = ['cat-9']);
      expect(updateAsIds.categories!.single.id, 'cat-9');
    });

    test('parseCatalog: buzuq yozuv o\'tkazib yuboriladi, qolgani kiradi',
        () async {
      final raw = <dynamic>[
        {'id': 'a', 'name': 'A', 'is_active': true, 'barcode': ['1']},
        'buzuq',
        {'id': 'b', 'name': 'B', 'is_active': true, 'barcode': 'satr-emas-list'},
        {'id': 'c', 'name': 'C', 'is_active': true},
      ];
      final r = await ItemsSingleton.parseCatalog(raw);
      expect(r.items.map((e) => e.id), containsAll(['a', 'c']));
      expect(r.failed, greaterThanOrEqualTo(1));
      expect(r.items.length + r.failed, raw.length);
      // 'b' — Map, id ma'lum, lekin parse bo'lmadi: preserveIds'ga tushadi
      // (clearAndPutItems bu id'ni "serverda yo'q" deb o'chirmasin).
      // 'buzuq' — Map emas, id chiqarib olib bo'lmaydi.
      expect(r.skippedIds, contains('b'));
      expect(r.skippedIds, isNot(contains('a')));
      expect(r.skippedIds, isNot(contains('c')));
    });

    test('category_ids: null / [] → kategoriya null, xato yo\'q', () {
      expect(ProductsWsService.categoriesFromIds(null), isNull);
      expect(ProductsWsService.categoriesFromIds(<dynamic>[]), isNull);
      expect(ProductsWsService.categoriesFromIds('cat'), isNull);
    });

    test('kategoriya hali lokalda bo\'lmasa ham id saqlanadi', () {
      final cats = ProductsWsService.categoriesFromIds(['cat-9']);
      expect(cats, isNotNull);
      expect(cats!.single.id, 'cat-9');
      expect(cats.single.name, isNull);
    });

    test('kategoriya lokalda bo\'lsa nomi ham keladi', () async {
      await HiveBoxes.getCategories()
          .add(CategoryData(id: 'cat-1', name: 'Ichimliklar', children: []));

      final cats = ProductsWsService.categoriesFromIds(['cat-1', 'cat-2']);
      expect(cats!.single.id, 'cat-1');
      expect(cats.single.name, 'Ichimliklar');
    });
  });
}
