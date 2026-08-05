// Kategoriya navigatsiyasi xarakteristik testi.
//
// MAQSAD: hozirgi xatti-harakatni MUZLATISH. Faza 2 da bu zona
// CatalogNavigationController ga ko'chiriladi — bu testlar ko'chirishdan
// keyin hech narsa o'zgarmaganini isbotlaydi.
//
// Bu zona savat/to'lov holatiga UMUMAN tegmaydi: faqat `_items` va
// `_pathList` maydonlari bilan ishlaydi, ma'lumotni CategorySingleton va
// ItemsSingleton statik ro'yxatlaridan oladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_categories/model/category.dart';
import 'package:invan2/features/get_categories/singleton/category_singleton.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

import 'support/provider_harness.dart';

/// Kategoriya daraxti:
///   ichimlik (top)
///     └── gazli (ichimlik farzandi)
///   nonushta (top)
CategoryData cat(String id, String name, {String? parentId}) =>
    CategoryData(id: id, name: name, parentId: parentId, children: []);

ItemModel product(String id, String name, {String? categoryId}) {
  final m = ItemModel();
  m.id = id;
  m.name = name;
  // Mahsulot qaysi kategoriyaga tegishli ekani `categories` ning OXIRGI
  // elementi bo'yicha aniqlanadi (ItemsSingleton.collectProductsByCategory).
  m.categories = categoryId == null
      ? []
      : [CategoriesFromProducts(id: categoryId, name: 'c')];
  return m;
}

Future<void> seedCatalog() async {
  final ichimlik = cat('ichimlik', 'Ichimliklar');
  final gazli = cat('gazli', 'Gazli', parentId: 'ichimlik');
  final nonushta = cat('nonushta', 'Nonushta');

  CategorySingleton.categories = [ichimlik, gazli, nonushta];
  CategorySingleton.topCategories = [ichimlik, nonushta];

  ItemsSingleton.products = [
    product('p1', 'Pepsi', categoryId: 'ichimlik'),
    product('p2', 'Fanta', categoryId: 'gazli'),
    product('p3', 'Non', categoryId: 'nonushta'),
  ];

  // getItems Hive'dagi kategoriyalar box'ini ham o'qiydi
  final box = HiveBoxes.getCategories();
  await box.clear();
  await box.addAll([ichimlik, gazli, nonushta]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('catalog_nav_test'));
  tearDownAll(tearDownPosTestEnv);

  setUp(seedCatalog);

  group('Boshlang\'ich holat', () {
    test('yo\'l (pathList) bo\'sh boshlanadi', () {
      final p = freshProvider();

      expect(p.getPathList, isEmpty);
    });
  });

  group('pressCategory — kategoriyaga kirish', () {
    test('yo\'lga qo\'shiladi', () {
      final p = freshProvider();

      p.pressCategory(cat('ichimlik', 'Ichimliklar'));

      expect(p.getPathList.length, 1);
      expect(p.getPathList.first.id, 'ichimlik');
    });

    test('ketma-ket kirishda yo\'l uzayadi', () {
      final p = freshProvider();

      p.pressCategory(cat('ichimlik', 'Ichimliklar'));
      p.pressCategory(cat('gazli', 'Gazli', parentId: 'ichimlik'));

      expect(p.getPathList.map((e) => e.id).toList(), ['ichimlik', 'gazli']);
    });

    test('kategoriya ichidagi mahsulotlar yig\'iladi', () {
      final p = freshProvider();

      p.pressCategory(cat('nonushta', 'Nonushta'));

      final products = p.getItems.whereType<ItemModel>().toList();
      expect(products.map((e) => e.id), contains('p3'));
    });
  });

  group('pressSubCategory — subkategoriyaga kirish', () {
    test('subkategoriya yo\'lga CategoryData sifatida qo\'shiladi', () {
      final p = freshProvider();

      p.pressSubCategory(
        SubCategoryModel(id: 'gazli', name: 'Gazli', parentId: 'ichimlik'),
      );

      expect(p.getPathList.length, 1);
      expect(p.getPathList.first.id, 'gazli');
      expect(p.getPathList.first.name, 'Gazli');
    });

    test('subkategoriya mahsulotlari yig\'iladi', () {
      final p = freshProvider();

      p.pressSubCategory(
        SubCategoryModel(id: 'gazli', name: 'Gazli', parentId: 'ichimlik'),
      );

      final products = p.getItems.whereType<ItemModel>().toList();
      expect(products.map((e) => e.id), contains('p2'));
    });
  });

  group('pressPath — yo\'ldagi oraliq nuqtaga qaytish', () {
    test('tanlangan nuqtadan keyingi qismlar kesiladi', () {
      final p = freshProvider();
      final ichimlik = cat('ichimlik', 'Ichimliklar');

      p.pressCategory(ichimlik);
      p.pressCategory(cat('gazli', 'Gazli', parentId: 'ichimlik'));
      expect(p.getPathList.length, 2);

      p.pressPath(ichimlik);

      expect(p.getPathList.length, 1);
      expect(p.getPathList.first.id, 'ichimlik');
    });
  });

  group('pressAllPath — boshiga qaytish', () {
    test('yo\'l tozalanadi va yuqori kategoriyalar tiklanadi', () {
      final p = freshProvider();
      p.pressCategory(cat('ichimlik', 'Ichimliklar'));
      p.pressCategory(cat('gazli', 'Gazli', parentId: 'ichimlik'));

      p.pressAllPath();

      expect(p.getPathList, isEmpty);
    });
  });

  group('clearPathList', () {
    test('faqat yo\'lni tozalaydi', () {
      final p = freshProvider();
      p.pressCategory(cat('ichimlik', 'Ichimliklar'));

      p.clearPathList();

      expect(p.getPathList, isEmpty);
    });
  });

  group('changeGridviewItems', () {
    test('berilgan ro\'yxat ko\'rsatiladi', () {
      final p = freshProvider();
      final only = [product('p9', 'Faqat shu')];

      p.changeGridviewItems(only);

      expect(p.getItems.whereType<ItemModel>().map((e) => e.id), contains('p9'));
    });

    test('null berilsa boshiga qaytadi (pressAllPath)', () {
      final p = freshProvider();
      p.pressCategory(cat('ichimlik', 'Ichimliklar'));

      p.changeGridviewItems(null);

      expect(p.getPathList, isEmpty);
    });
  });

  group('Savatdan mustaqillik (Faza 2 uchun asosiy shart)', () {
    test('navigatsiya savatga va to\'lovga tegmaydi', () {
      final p = freshProvider();
      p.getCurrentClient.orderedProducts.add(makeSoldItem(price: 5000));
      final cartBefore = p.getCurrentClient.orderedProducts.length;

      p.pressCategory(cat('ichimlik', 'Ichimliklar'));
      p.pressSubCategory(SubCategoryModel(id: 'gazli', name: 'Gazli'));
      p.pressAllPath();
      p.clearPathList();

      expect(p.getCurrentClient.orderedProducts.length, cartBefore);
      expect(p.getCurrentClient.orderedProducts.first.price, 5000);
    });
  });
}
