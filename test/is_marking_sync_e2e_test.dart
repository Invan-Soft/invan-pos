// `is_marking` o'zgarishining notification orqali kassaga TO'LIQ yo'l
// bo'ylab yetib borishi: HTTP javob → NotificationFetch → ProductsWsService
// parseri → ItemsSingleton.putItems → Hive → xotira keshi (skaner) →
// markirovka qarori.
//
// Asos — 2026-09-30 jonli hodisasi (Tiin Optom): Alice'dagi aynan o'sha
// 4 ta type 2 notification (Marmelad, Qimiz, Konfet, Ponchiki). Qimiz
// adminkada true→false qilingan, notification kelgan, lekin kassalar
// markirovka so'rayverdi (putItems'dagi "lokal true doim true" sticky).
//
// Markirovka dialogining ikkala kirish nuqtasi (OrderingProvider4):
//   * addProduct:  markCheck && (product.isMarking == true || byMxik)
//   * skaner:      byMxik
//   byMxik = markCheck && autoDetect && MxikRules.isMxikAutoDetectCandidate
// Demak `isMarking != true` va `isMxikAutoDetectCandidate == false` bo'lsa
// dialog CHIQMAYDI — `expectNoMarkingDialog` shu ikkisini tekshiradi.
// Sozlamalar eng og'ir holatda: OFD tekshiruvi YOQIQ, MXIK avto-aniqlash
// YOQIQ.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invan2/changes/dialogs/creat_product/model/mes_vat_unit_model/mes_unit.dart';
import 'package:invan2/changes/domain/marking/mxik_rules.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/models/product/soliq_mxik_model.dart';
import 'package:invan2/changes/services/get_items_service.dart';
import 'package:invan2/changes/services/sync/notification_fetch.dart';
import 'package:invan2/changes/services/sync/server_clock.dart';
import 'package:invan2/changes/services/sync/sync_cursor.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/mxik_updates.dart';
import 'package:invan2/changes/services/web_socket_service/product/model/product_price_edit_response.dart';
import 'package:invan2/changes/services/web_socket_service/product/products_ws_service.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kShop = 'aa954511-3801-46f8-a0bd-d41fa7e40369';
const kQimizId = 'c2fc90bf-4a69-4304-9e8b-b64b4e32e4d5';
const kQimizBarcode = '4673741534682';
const kQimizBarcode2 = '4603735722092';
const kMarmeladId = 'd2bbb614-c910-4656-86b2-92007a180546';
const kKonfetId = '9c54313f-f869-477f-a2a9-46fa233a6700';
const kPonchikiId = '1ca89117-bdf5-41ef-9f8f-f424daf3c2aa';
const kOrgDefaultMxik = '01905012001000000';

/// Markirovka ro'yxatidagi MXIK (`02202` — ichimliklar).
const kMarkingMxik = '02202001001000000';

/// Kontekst faqat type 40 (to'lov turi) uchun kerak; `mounted: false`
/// bilan boshqa turlarda umuman ishlatilmaydi.
class _NoContext extends Fake implements BuildContext {}

/// Server shaklidagi type 2 notification (Alice skrinshotidagi maydonlar).
///
/// [omitIsMarking] — `is_marking` KALITI umuman bo'lmasin (payload bu
/// haqda gapirmayapti). [isMarking] ga `null` berilsa kalit bor, qiymati
/// null.
Map<String, dynamic> productNotification({
  required String notifId,
  required String productId,
  required String sku,
  required String name,
  required List<String>? barcode,
  required String mxik,
  required num price,
  required String createdAt,
  bool? isMarking = false,
  bool omitIsMarking = false,
  List<Map<String, dynamic>>? tiers,
  dynamic images,
  String packageCode = '1',
  String categoryId = '020cccdf-a19a-4aa4-b895-b46c56c2c8f0',
}) {
  return {
    'id': notifId,
    'company_id': '721e713b-d709-45e9-9bef-ade95fb6f2f8',
    'shop_id': null,
    'type': 2,
    'data': {
      'id': productId,
      'sku': sku,
      'name': name,
      'images': images,
      'vat_id': 'a60d1751-3f88-42cd-b6b3-0e8a7d890f49',
      'barcode': barcode,
      'request': {
        'user_id': '193ad7ee-2c80-4da0-a2f6-9289b6eceded',
        'timezone': -300,
        'company_id': '721e713b-d709-45e9-9bef-ade95fb6f2f8',
        'user_type_id': '1fe92aa8-2a61-4bf1-b907-182b497584ad',
      },
      'tag_ids': null,
      'brand_id': '',
      'cash_sale': 1,
      'employees': null,
      'is_active': true,
      'mxik_code': mxik,
      'parent_id': '',
      'components': null,
      if (!omitIsMarking) 'is_marking': isMarking,
      'no_loyalty': false,
      'owner_type': '0',
      'box_barcode': '',
      'description': '',
      'shop_prices': [
        {
          'shop_id': kShop,
          'shop_name': 'Tiin Optom',
          'retail_price': price,
          'supply_price': price - 1000,
          'shop_price_tiers':
              tiers ?? [{'min_quantity': 1, 'retail_price': price}],
          'last_supply_price': price - 1000,
        },
      ],
      'supplier_id': '2541f795-915f-422e-bb52-03732622ee69',
      'category_ids': [categoryId],
      'is_composite': false,
      'package_code': packageCode,
      'package_name': 'dona',
      'package_type': '1',
      'custom_fields': null,
      'serial_number': false,
      'has_box_barcode': false,
      'product_type_id': '8b0bf29c-58e8-4310-8bb1-a1b9771f9c47',
      'is_stock_changed': false,
      'measurement_values': [
        {
          'amount': 26,
          'shop_id': kShop,
          'shop_name': 'Tiin Optom',
          'has_trigger': true,
          'is_available': true,
        },
      ],
      'measurement_unit_id': '4bb624a5-7eb8-41ff-8f52-bcde11af5324',
      'box_barcode_quantity': 0,
    },
    'is_read': false,
    'created_at': createdAt,
  };
}

/// Qimiz notification'i — hodisadagi shakl (mxik_code BO'SH, is_marking false).
Map<String, dynamic> qimiz({
  bool? isMarking = false,
  bool omitIsMarking = false,
  String mxik = '',
  num price = 39900,
  String createdAt = '2026-09-30T06:11:27.651784Z',
  String notifId = '6d481414-ed25-400a-bf47-b2fa93d2dce4',
}) =>
    productNotification(
      notifId: notifId,
      productId: kQimizId,
      sku: '53983',
      name: 'Qimiz KumИs & Med Yashil 500ml',
      barcode: [kQimizBarcode, kQimizBarcode2],
      mxik: mxik,
      price: price,
      isMarking: isMarking,
      omitIsMarking: omitIsMarking,
      packageCode: '1425516',
      categoryId: '2eae4099-e3d5-4c17-bd4b-4353fe8fd64e',
      createdAt: createdAt,
    );

/// 2026-09-30 06:13:44 dagi Alice javobi: 4 ta notification, server bergan
/// tartibda (created_at o'sish bo'yicha).
List<Map<String, dynamic>> incidentBatch() => [
      productNotification(
        notifId: 'bd13eca7-1491-4a93-87ec-1efc90750669',
        productId: kMarmeladId,
        sku: '53634',
        name: 'Marmelad KDV Strike 500gr',
        barcode: ['4607010743482'],
        mxik: '02007002003000000',
        price: 34950,
        tiers: [
          {'min_quantity': 1, 'retail_price': 34950},
          {'min_quantity': 2, 'retail_price': 33950},
          {'min_quantity': 4, 'retail_price': 33450},
        ],
        packageCode: '1433299',
        createdAt: '2026-09-30T06:10:56.206342Z',
      ),
      qimiz(),
      productNotification(
        notifId: 'bb51bbab-f444-409c-b684-9af553e94c44',
        productId: kKonfetId,
        sku: '53640',
        name: 'Konfet Strike Sharbatli 1kg',
        barcode: ['4680167314378', '4607109845318'],
        mxik: '01704001016000000',
        price: 42450,
        images: [
          {'image_url': 'a56fafa5-26e0-4068-9f72-fe5b0b4cdf7f'},
        ],
        tiers: [
          {'min_quantity': 1, 'retail_price': 42450},
          {'min_quantity': 2, 'retail_price': 41450},
          {'min_quantity': 4, 'retail_price': 40950},
        ],
        packageCode: '1352143',
        createdAt: '2026-09-30T06:12:33.580788Z',
      ),
      productNotification(
        notifId: '598b211b-b3b6-4bcc-83c4-459e67ac8edb',
        productId: kPonchikiId,
        sku: '44928',
        name: 'Ponchiki KDV Strike 500gr',
        // Hodisadagi kabi: barcode null.
        barcode: null,
        mxik: '01704001016000000',
        price: 34950,
        packageCode: '193503',
        categoryId: 'dc83ac1b-fc5d-4b28-90d4-5fadd440dcc2',
        createdAt: '2026-09-30T06:13:21.504425Z',
      ),
    ];

ShopPrices priceOf(num retail) => ShopPrices(
      shID: ShID(
        shopId: kShop,
        supplyPrice: retail - 1000,
        shopPriceTiers: [ShopPriceTiers(minQuantity: 1, retailPrice: retail)],
      ),
    );

ItemModel localProduct(
  String id, {
  required bool? isMarking,
  required List<String> barcode,
  String mxik = kOrgDefaultMxik,
  num price = 38900,
}) =>
    ItemModel(
      id: id,
      sku: 'sku-$id',
      name: 'Lokal $id',
      isActive: true,
      isMarking: isMarking,
      barcode: barcode,
      mxikCode: mxik,
      packageCode: '1',
      shopPrices: priceOf(price),
    );

/// Hodisadan OLDINGI kassa holati: Qimiz markirovkali (true), qolganlari
/// markirovkasiz. Hammasi xotira keshida ham (skaner shu keshdan qidiradi).
Future<void> seedBeforeIncident({bool? qimizMarking = true}) async {
  await ItemsSingleton.putItems([
    localProduct(kQimizId,
        isMarking: qimizMarking, barcode: [kQimizBarcode, kQimizBarcode2]),
    localProduct(kMarmeladId, isMarking: false, barcode: ['4607010743482']),
    localProduct(kKonfetId,
        isMarking: false, barcode: ['4680167314378', '4607109845318']),
    localProduct(kPonchikiId, isMarking: false, barcode: ['4600000000001']),
  ]);
  await ItemsSingleton.storeProducts();
}

void serve(List<Map<String, dynamic>> notifications) {
  // Baytlar bilan: nomlarda kirill harflari bor ("KumИs"), `http.Response`
  // satr konstruktori esa latin1 kutadi. Server ham utf-8 yuboradi.
  NotificationFetch.client = MockClient((req) async => http.Response.bytes(
        utf8.encode(jsonEncode({
          'notifications': notifications,
          'total_count': notifications.length,
          'total_unread_count': notifications.length,
        })),
        200,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          'date': 'Wed, 30 Sep 2026 06:13:44 GMT',
        },
      ));
}

Future<SyncFetchResult> runProductWindow(
    List<Map<String, dynamic>> notifications) {
  serve(notifications);
  return ProductsWsService.getReceivedWS(
      false, _NoContext(), '2026-09-30 06:08:00', '2026-09-30 06:13:44');
}

ItemModel stored(String id) => HiveBoxes.getProducts().get(id)!;

/// Skaner ishlatadigan xotira keshidan (barcodeProducts) topilgan mahsulot.
ItemModel scanned(String barcode) {
  final ItemModel? item = ItemsSingleton.getProductByBarcode(barcode);
  expect(item, isNotNull, reason: 'skaner $barcode ni topishi kerak');
  return item!;
}

void expectNoMarkingDialog(ItemModel item) {
  expect(item.isMarking == true, isFalse,
      reason: 'addProduct kirish nuqtasi: isMarking true bo\'lmasligi kerak');
  expect(MxikRules.isMxikAutoDetectCandidate(item), isFalse,
      reason: 'skaner kirish nuqtasi: MXIK avto-aniqlash nomzodi emas');
  expect(MxikRules.isProductMarkable(item), isFalse,
      reason: 'savat qatori markirovka guruhiga tushmasin');
}

void expectMarkingDialog(ItemModel item) {
  expect(MxikRules.isProductMarkable(item), isTrue);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('is_marking_sync_e2e_test', withEmployee: false);

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
    reg(SoliqMxikModelAdapter().typeId, SoliqMxikModelAdapter());

    await Hive.openBox<ItemModel>(HiveBoxNames.items);
    await Hive.openBox<MesUnitModel>(HiveBoxNames.mesUnit);
    await Hive.openBox<VatUnitModel>(HiveBoxNames.vatUnit);
    await Hive.openBox<SoliqMxikModel>(HiveBoxNames.markingProducts);

    await Pref.setString(PrefKeys.token, 'test-token');
    await Pref.setString(PrefKeys.orgID, '721e713b-d709-45e9-9bef-ade95fb6f2f8');
    await Pref.setString(PrefKeys.storeId, kShop);
    await Pref.setString(PrefKeys.acceptService, kShop);
    await Pref.setString(PrefKeys.mxikCode, kOrgDefaultMxik);
    await Pref.setString(PrefKeys.packageCode, '1');
    // Eng og'ir holat: OFD markirovka tekshiruvi va MXIK avto-aniqlash yoqiq.
    await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() async {
    ServerClock.reset();
    await HiveBoxes.getProducts().clear();
    await HiveBoxes.getCategories().clear();
    await HiveBoxes.markingProductsBox().clear();
    ItemsSingleton.clearTheProducts();
  });

  tearDown(() {
    NotificationFetch.client = null;
    ServerClock.reset();
  });

  group('2026-09-30 hodisasi — aynan o\'sha 4 ta notification', () {
    test('Qimiz true→false: Hive, skaner keshi va dialog qarori yangilanadi',
        () async {
      await seedBeforeIncident();
      // Boshlang'ich holat haqiqatan "markirovka so'raydi".
      expectMarkingDialog(scanned(kQimizBarcode));

      final SyncFetchResult r = await runProductWindow(incidentBatch());

      expect(r.ok, isTrue);
      expect(r.received, 4);
      expect(r.applyFailed, isFalse,
          reason: 'hech bir notification parse/qo\'llashda yiqilmasligi kerak');

      expect(stored(kQimizId).isMarking, isFalse);
      // Skaner xotira keshidan qidiradi — oyna oxirida yangilangan bo'lishi
      // shart (ikkala barcode bo'yicha ham).
      final ItemModel q1 = scanned(kQimizBarcode);
      final ItemModel q2 = scanned(kQimizBarcode2);
      expect(q1.isMarking, isFalse);
      expect(q2.isMarking, isFalse);
      expectNoMarkingDialog(q1);
      // Narx ham qo'llangan (batch'ning qolgan qismi yutilmagan).
      expect(ItemsSingleton.onePrice(q1.shopPrices), 39900);
    });

    test('batch\'dagi qolgan 3 mahsulot ham to\'liq qo\'llanadi', () async {
      await seedBeforeIncident();

      await runProductWindow(incidentBatch());

      expect(ItemsSingleton.onePrice(stored(kMarmeladId).shopPrices), 34950);
      expect(ItemsSingleton.onePrice(stored(kKonfetId).shopPrices), 42450);
      expect(stored(kKonfetId).image, isNotNull);
      // Ponchiki: barcode null keldi — saqlanadi, yiqilmaydi.
      expect(stored(kPonchikiId).barcode, isEmpty);
      expect(ItemsSingleton.onePrice(stored(kPonchikiId).shopPrices), 34950);
      for (final id in [kMarmeladId, kKonfetId, kPonchikiId]) {
        expect(stored(id).isMarking, isFalse, reason: id);
      }
    });

    test('server teskari tartibda (desc) qaytarsa ham natija bir xil',
        () async {
      await seedBeforeIncident();

      await runProductWindow(incidentBatch().reversed.toList());

      expect(stored(kQimizId).isMarking, isFalse);
      expectNoMarkingDialog(scanned(kQimizBarcode));
    });

    test('Qimiz yolg\'iz kelsa ham (foydalanuvchining 2-urinishi) — false',
        () async {
      await seedBeforeIncident();

      await runProductWindow([qimiz()]);

      expectNoMarkingDialog(scanned(kQimizBarcode));
    });

    test('oyna qayta so\'ralsa (overlap) natija o\'zgarmaydi', () async {
      await seedBeforeIncident();

      await runProductWindow(incidentBatch());
      await runProductWindow(incidentBatch());

      expect(stored(kQimizId).isMarking, isFalse);
      expectNoMarkingDialog(scanned(kQimizBarcode));
    });
  });

  group('MXIK markirovka ro\'yxatida, adminka esa false', () {
    test('notification: MXIK 02202..., is_marking false → dialog YO\'Q',
        () async {
      await seedBeforeIncident();

      await runProductWindow([qimiz(mxik: kMarkingMxik)]);

      final ItemModel q = scanned(kQimizBarcode);
      expect(q.mxikCode, kMarkingMxik);
      expectNoMarkingDialog(q);
    });

    test('type 20 (MXIK almashdi) markirovka MXIKiga o\'tsa ham false qoladi',
        () async {
      await seedBeforeIncident();
      await runProductWindow([qimiz()]);
      final String oldMxik = stored(kQimizId).mxikCode!;

      await ItemsSingleton.editMxik(MxikUpdates.fromJson({
        'mxik_codes': [
          {
            'old_mxik': oldMxik,
            'new_mxik': kMarkingMxik,
            'package': {
              'package_code': '1',
              'package_name': 'dona',
              'package_type': '1',
            },
          },
        ],
      }).mxikCodes!);
      await ItemsSingleton.storeProducts();

      final ItemModel q = scanned(kQimizBarcode);
      expect(q.mxikCode, kMarkingMxik);
      expectNoMarkingDialog(q);
    });

    test('Soliq job (qo\'lda yangilash) adminka false\'ini qaytarmaydi',
        () async {
      await seedBeforeIncident();
      await runProductWindow([qimiz(mxik: kMarkingMxik)]);
      await HiveBoxes.markingProductsBox().put(
          kMarkingMxik,
          SoliqMxikModel(
            mxik: kMarkingMxik,
            mxikNameUz: '',
            mxikNameRu: '',
            mxikNameLat: '',
            internationalCode: '',
            usePackage: 0,
            packages: const [],
          ));

      await OrdersService().updateMarkingStatusFromSoliq(fromLocal: true);

      expect(stored(kQimizId).isMarking, isFalse);
      expectNoMarkingDialog(scanned(kQimizBarcode));
    });
  });

  group('keyingi hodisalar false\'ni buzmaydi', () {
    test('type 13 narx o\'zgarishi — narx yangilanadi, false saqlanadi',
        () async {
      await seedBeforeIncident();
      await runProductWindow([qimiz()]);

      await ItemsSingleton.editItem(ProductPriceEdit.fromJson({
        'id': 'n-price',
        'type': 13,
        'data': {
          'product_values': [
            {
              'product_id': kQimizId,
              'price': {
                'shop_id': kShop,
                'retail_price': 41000,
                'supply_price': 39000,
                'shop_price_tiers': [
                  {'min_quantity': 1, 'retail_price': 41000},
                ],
              },
            },
          ],
        },
      }));
      await ItemsSingleton.storeProducts();

      final ItemModel q = scanned(kQimizBarcode);
      expect(ItemsSingleton.onePrice(q.shopPrices), 41000);
      expectNoMarkingDialog(q);
    });

    test('keyingi type 2 da is_marking KALITI yo\'q — false saqlanadi',
        () async {
      await seedBeforeIncident();
      await runProductWindow([qimiz()]);

      await runProductWindow([
        qimiz(
            omitIsMarking: true,
            price: 40500,
            notifId: 'n-later',
            createdAt: '2026-09-30T07:00:00Z'),
      ]);

      final ItemModel q = scanned(kQimizBarcode);
      expect(ItemsSingleton.onePrice(q.shopPrices), 40500);
      expectNoMarkingDialog(q);
    });

    test('is_marking: null (kalit bor, qiymat null) — mavjud false saqlanadi',
        () async {
      await seedBeforeIncident();
      await runProductWindow([qimiz()]);

      await runProductWindow([
        qimiz(
            isMarking: null,
            notifId: 'n-null',
            createdAt: '2026-09-30T07:00:00Z'),
      ]);

      expectNoMarkingDialog(scanned(kQimizBarcode));
    });

    test('to\'liq yuklash (clearAndPutItems) katalogdagi false\'ni yozadi',
        () async {
      await seedBeforeIncident();

      await ItemsSingleton.clearAndPutItems([
        localProduct(kQimizId,
            isMarking: false, barcode: [kQimizBarcode, kQimizBarcode2]),
      ]);
      await ItemsSingleton.storeProducts();

      expectNoMarkingDialog(scanned(kQimizBarcode));
    });
  });

  group('teskari yo\'nalish va bir oynadagi ziddiyat', () {
    test('false→true (adminka qayta yoqdi) darrov qo\'llanadi', () async {
      await seedBeforeIncident(qimizMarking: false);

      await runProductWindow([qimiz(isMarking: true)]);

      expectMarkingDialog(scanned(kQimizBarcode));
    });

    test('bir oynada false (06:11) keyin true (06:12) — oxirgisi (true)',
        () async {
      await seedBeforeIncident(qimizMarking: false);

      await runProductWindow([
        // Server desc qaytargan holat: yangi birinchi.
        qimiz(
            isMarking: true,
            notifId: 'n2',
            createdAt: '2026-09-30T06:12:00Z'),
        qimiz(
            isMarking: false,
            notifId: 'n1',
            createdAt: '2026-09-30T06:11:00Z'),
      ]);

      expect(stored(kQimizId).isMarking, isTrue);
    });

    test('bir oynada true (06:11) keyin false (06:12) — oxirgisi (false)',
        () async {
      await seedBeforeIncident();

      await runProductWindow([
        qimiz(
            isMarking: false,
            notifId: 'n2',
            createdAt: '2026-09-30T06:12:00Z'),
        qimiz(
            isMarking: true,
            notifId: 'n1',
            createdAt: '2026-09-30T06:11:00Z'),
      ]);

      expect(stored(kQimizId).isMarking, isFalse);
      expectNoMarkingDialog(scanned(kQimizBarcode));
    });
  });
}
