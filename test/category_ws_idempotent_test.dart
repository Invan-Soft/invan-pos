// Kategoriya notification'lari (type 10/11/12) idempotent bo'lishi kerak:
// sinxron oynalari 2 daqiqa overlap bilan qayta so'raladi, ya'ni bir xil
// "kategoriya yaratildi" xabari 2-3 marta qo'llanadi. Ilgari `box.addAll`
// har safar yangi qator qo'shar, gridda dublikat chiqar, update esa faqat
// birinchisini o'zgartirardi.

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_categories/model/category.dart';
import 'package:invan2/features/get_categories/service/category_service.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

import 'support/provider_harness.dart';

CategoryData cat(String id, String name, {String? parent}) =>
    CategoryData(id: id, name: name, parentId: parent, children: []);

List<String?> idsInBox() =>
    HiveBoxes.getCategories().values.map((c) => c.id).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('category_ws_idempotent_test', withEmployee: false);
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
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    await HiveBoxes.getCategories().clear();
    await HiveBoxes.getProducts().clear();
  });

  test('type 10 uch marta kelsa ham bitta qator', () async {
    for (int i = 0; i < 3; i++) {
      await CategoryService.categoriesCreateForWebSocket([cat('c1', 'Suv')]);
    }
    expect(idsInBox().where((id) => id == 'c1').length, 1);
  });

  test('type 11 nomni o\'zgartiradi, dublikat yaratmaydi', () async {
    await CategoryService.categoriesCreateForWebSocket([cat('c1', 'Suv')]);
    await CategoryService.categoriesUpdateForWebSocket(cat('c1', 'Ichimlik'));
    await CategoryService.categoriesUpdateForWebSocket(cat('c1', 'Ichimlik'));

    final rows = HiveBoxes.getCategories().values.where((c) => c.id == 'c1');
    expect(rows.length, 1);
    expect(rows.single.name, 'Ichimlik');
  });

  test('type 11 lokalda yo\'q kategoriya uchun yaratadi', () async {
    await CategoryService.categoriesUpdateForWebSocket(cat('c9', 'Yangi'));
    expect(idsInBox(), contains('c9'));
  });

  test('eski dublikatlar upsert\'da yig\'ishtiriladi', () async {
    final box = HiveBoxes.getCategories();
    await box.addAll([cat('c1', 'Suv'), cat('c1', 'Suv'), cat('c1', 'Suv')]);

    await CategoryService.categoriesUpdateForWebSocket(cat('c1', 'Suv 2'));

    expect(idsInBox().where((id) => id == 'c1').length, 1);
  });

  test('type 12 hamma nusxani o\'chiradi va mahsulot kategoriyasini tozalaydi',
      () async {
    final box = HiveBoxes.getCategories();
    await box.addAll([cat('c1', 'Suv'), cat('c1', 'Suv'), cat('c2', 'Non')]);
    final items = HiveBoxes.getProducts();
    await items.put(
        'p1',
        ItemModel(
            id: 'p1',
            name: 'P',
            isActive: true,
            categories: [CategoriesFromProducts(id: 'c1', name: 'Suv')]));

    await CategoryService.categoriesDeleteForWebSocket('c1');

    expect(idsInBox(), ['c2']);
    expect(items.get('p1')!.categories, isNull);
  });

  test('type 12 ikkinchi marta kelsa xato yo\'q', () async {
    await HiveBoxes.getCategories().add(cat('c1', 'Suv'));
    await CategoryService.categoriesDeleteForWebSocket('c1');
    expect(await CategoryService.categoriesDeleteForWebSocket('c1'), isNull);
  });
}
