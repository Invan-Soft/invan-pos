// Katta hajmdagi katalogni lokalga yozish testi.
//
// Nega kerak: shu tuzatishdan keyin kassa birinchi ishga tushganda (kursor
// bo'sh bo'lgani uchun) butun katalogni bir marta to'liq qayta yuklaydi —
// `clearAndPutItems` + `storeProducts`. Katta do'konda bu o'n minglab
// yozuv degani, shuning uchun uning to'g'ri va oqilona vaqtda
// bajarilishi tekshiriladi.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

/// Real katalogga yaqin hajm. Katta do'konlarda mahsulot soni shu atrofda.
const int kCatalogSize = 30000;

ItemModel makeItem(int i) => ItemModel(
      id: 'prod-$i',
      sku: '$i',
      name: 'Mahsulot $i',
      isActive: true,
      isMarking: false,
      mxikCode: '02202001001000000',
      barcode: ['478${i.toString().padLeft(10, '0')}'],
      shopPrices: ShopPrices(
        shID: ShID(
          shopId: 'shop-1',
          supplyPrice: 1000 + i,
          shopPriceTiers: [
            ShopPriceTiers(minQuantity: 1, retailPrice: 1500 + i),
          ],
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('items_bulk_write_test');
    Hive.init(tempDir.path);

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

    await Hive.openBox<ItemModel>(HiveBoxNames.items);
    await Hive.openBox(HiveBoxNames.prefs);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    await HiveBoxes.getProducts().clear();
    ItemsSingleton.clearTheProducts();
  });

  test('$kCatalogSize ta mahsulot to\'liq yoziladi va o\'qiladi', () async {
    final items = List.generate(kCatalogSize, makeItem);

    final sw = Stopwatch()..start();
    await ItemsSingleton.clearAndPutItems(items);
    final writeMs = sw.elapsedMilliseconds;

    await ItemsSingleton.storeProducts();
    sw.stop();

    // ignore: avoid_print
    print('clearAndPutItems: ${writeMs}ms, '
        'jami (storeProducts bilan): ${sw.elapsedMilliseconds}ms');

    expect(HiveBoxes.getProducts().length, kCatalogSize);
    expect(ItemsSingleton.products.length, kCatalogSize);

    // Kesh Hive bilan mos: tasodifiy yozuv to'g'ri o'qilyapti.
    final probe = ItemsSingleton.getProductById('prod-17777');
    expect(probe, isNotNull);
    expect(probe!.name, 'Mahsulot 17777');
    expect(ItemsSingleton.onePrice(probe.shopPrices), 1500 + 17777);
  });

  test('takroriy to\'liq yuklash yozuvlarni ko\'paytirmaydi', () async {
    final items = List.generate(kCatalogSize, makeItem);

    await ItemsSingleton.clearAndPutItems(items);
    await ItemsSingleton.storeProducts();
    final first = HiveBoxes.getProducts().length;

    // Aynan shu narsa yuz beradi: to'liq yuklash bir necha marta ketma-ket
    // ishga tushsa ham (masalan qayta urinish) katalog ikkilanmasligi kerak.
    await ItemsSingleton.clearAndPutItems(items);
    await ItemsSingleton.storeProducts();

    expect(HiveBoxes.getProducts().length, first);
    expect(ItemsSingleton.products.length, kCatalogSize);
  });

  test('to\'liq yuklash eski, endi mavjud bo\'lmagan mahsulotni o\'chiradi',
      () async {
    await ItemsSingleton.clearAndPutItems(List.generate(100, makeItem));
    await ItemsSingleton.storeProducts();
    expect(ItemsSingleton.getProductById('prod-99'), isNotNull);

    // Serverdan endi 50 ta keldi — qolgani o'chirilgan bo'lishi kerak.
    await ItemsSingleton.clearAndPutItems(List.generate(50, makeItem));
    await ItemsSingleton.storeProducts();

    expect(HiveBoxes.getProducts().length, 50);
    expect(ItemsSingleton.getProductById('prod-99'), isNull);
    expect(ItemsSingleton.getProductById('prod-49'), isNotNull);
  });

  test('notification orqali kelgan katta paket (putItems) qo\'shiladi',
      () async {
    await ItemsSingleton.clearAndPutItems(List.generate(1000, makeItem));
    await ItemsSingleton.storeProducts();

    // 5000 ta yangi mahsulot bitta notification paketida kelgan holat.
    final batch = List.generate(5000, (i) => makeItem(10000 + i));

    final sw = Stopwatch()..start();
    await ItemsSingleton.putItems(batch);
    await ItemsSingleton.storeProducts();
    sw.stop();

    // ignore: avoid_print
    print('putItems(5000): ${sw.elapsedMilliseconds}ms');

    expect(HiveBoxes.getProducts().length, 6000);
    expect(ItemsSingleton.getProductById('prod-10000'), isNotNull);
    expect(ItemsSingleton.getProductById('prod-0'), isNotNull);
  });

  test('barcode keshi faqat narxi va shtrix-kodi borlarni oladi', () async {
    final items = [
      makeItem(1),
      // narxsiz
      ItemModel(
        id: 'prod-narxsiz',
        isActive: true,
        barcode: ['4780000000001'],
        shopPrices: ShopPrices(
          shID: ShID(shopId: 'shop-1', shopPriceTiers: [
            ShopPriceTiers(minQuantity: 1, retailPrice: 0),
          ]),
        ),
      ),
      // shtrix-kodsiz
      ItemModel(
        id: 'prod-barcodesiz',
        isActive: true,
        barcode: const [],
        shopPrices: ShopPrices(
          shID: ShID(shopId: 'shop-1', shopPriceTiers: [
            ShopPriceTiers(minQuantity: 1, retailPrice: 5000),
          ]),
        ),
      ),
    ];

    await ItemsSingleton.clearAndPutItems(items);
    await ItemsSingleton.storeProducts();

    expect(ItemsSingleton.products.length, 3);
    expect(ItemsSingleton.barcodeProducts.length, 1);
    expect(ItemsSingleton.barcodeProducts.single.id, 'prod-1');
  });
}
