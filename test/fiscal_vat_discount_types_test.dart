// Diskont turlari × fiskal QQS — to'liq zanjir, HAQIQIY diskont mexanizmi bilan.
//
// `test/fiscal_vat_base_test.dart` qatorlarni qo'lda (realPrice/price) quradi.
// Bu fayl esa ilova yo'lini takrorlaydi:
//   SoldItemBuilder.build (savat qatori, ilova bilan bir xil)
//     → DiscountSingleton.addDiscountOnProduct (mahsulot / kategoriya /
//       mijoz guruhi foiz va summa chegirmalari — `_applyDiscounts` bilan bir xil)
//     → OrderingProvider4.findFreeProducts + useFreeProducts +
//       useFreeGiftProducts + useBuyXGetXProducts (1+1, 3+1, Buy X Get Y,
//       Free Gift — `pressDialogSaveButton` dagi standart 4 qadam)
//     → setNewClientDiscountPercentage (chek darajasidagi "tepa" foiz)
//     → ReceiptBuilder.build (chek) → ReceiptSingleton4.saleOnOFD
//     → FiscalReceiptModel.fromRequest → toJson()  ← modulga POST qilinadigan JSON
//
// Mac'da fiskal modul yo'q, shuning uchun modulga ketadigan JSON'ning o'zi
// tekshiriladi. Har holatda, har qatorda:
//   Price    = round(realPrice × qty) × 100          (chegirmasiz)
//   Discount = (realPrice − price) × qty × 100
//   VAT      = trunc((Price − Discount − Other) × p / (100 + p))
//   VAT      < Price × p / (100 + p)  (chegirma bo'lsa — eski xato formula emas)
// va §10.2.1 balansi. Rasmiy FiscalDriveService misoli: Price 100000,
// Discount 50000, VATPercent 12 → VAT 5357.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/sold_item_builder.dart';
import 'package:invan2/changes/domain/receipt/receipt_builder.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/changes/singletons/discounts/discount_singleton.dart';
import 'package:invan2/features/get_discounts/model/discounts_response.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/fiscal_service/model/fiscal_receipt_model.dart';
import 'package:invan2/fiscal_service/model/location/location.dart';
import 'package:invan2/fiscal_service/model/receipt_data_model.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';
import 'package:invan2/utils/util_functions.dart';

import 'support/provider_harness.dart';

const kStoreId = 'shop-1';
const kMxik = '01234567890123456';
const kCashbackPayId = 'pay-cashback-1';
const kFactory = 'UZ000000000MOCK';
const kTerminal = 'MOCK00000001';
const kCat = 'cat-ichimlik';
const kVip = 'vip-group';

// Diskont tizimidagi qat'iy GUIDlar (discount_helpers.dart).
const gGroupProduct = '22e778e1-e562-4649-b47e-b720a28d831c';
const gGroupCategory = '847808d6-5113-4235-a5aa-f5edb044f837';
const gGroupBuyXGetY = '86951e75-960f-45d7-9505-9b9cd2ce17a7';
const gGroupBuyXGetX = '316b623e-3bb7-43e2-b6d5-1028c927caba';
const gGroupFreeGift = 'e13e3ed0-2d03-42f2-8c5f-43bcb3b3c8e9';
const gTypePercentage = 'e908c52f-4c6f-46d8-b765-16e074425cd9';
const gTypeNumeric = 'b78fd1a6-38ed-45a6-b002-caac5de6ebe6';
const gTypeBuyXGetY = 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b';
const gTypeBuyXGetX = '90d1f774-44bd-49be-9bbf-2e9a44558377';

// ───────────────────────── Katalog ─────────────────────────

ItemModel prod(
  String id,
  String name,
  num price, {
  String? categoryId,
  int? vatPercent,
}) {
  final m = ItemModel();
  m.id = id;
  m.name = name;
  m.mxikCode = kMxik;
  m.isMarking = false;
  m.barcode = ['4780000000001'];
  m.packageCode = '1512199';
  m.packageName = 'dona';
  m.shopPrices = ShopPrices(
    shID: ShID(
      shopId: kStoreId,
      shopPriceTiers: [ShopPriceTiers(minQuantity: 1, retailPrice: price)],
    ),
  );
  if (categoryId != null) {
    m.categories = [CategoriesFromProducts(id: categoryId, name: categoryId)];
  }
  if (vatPercent != null) {
    m.vat = Vat(percentage: vatPercent, name: 'НДС $vatPercent%');
  }
  return m;
}

late ItemModel tovar; // 50 000, kategoriya kCat
late ItemModel oddiy; // 30 000, kategoriyasiz
late ItemModel coca; // 12 000 (Buy X Get Y — sotib olinadigan)
late ItemModel chips; // 6 000 (Buy X Get Y — tekin)
late ItemModel sovga; // 10 000 (Free Gift)
late ItemModel nolQqs; // 50 000, QQS 0%
late ItemModel tarozi; // 77 950 / kg
late ItemModel suv; // 5 000 dona (blok 12)

void seedCatalog() {
  tovar = prod('tovar', 'Tovar', 50000, categoryId: kCat);
  oddiy = prod('oddiy', 'Oddiy', 30000);
  coca = prod('coca', 'Coca 1L', 12000);
  chips = prod('chips', 'Chips', 6000);
  sovga = prod('sovga', 'Sovg\'a', 10000);
  nolQqs = prod('nol-qqs', 'QQS siz', 50000, vatPercent: 0);
  tarozi = prod('tarozi', 'Tarozi', 77950);
  suv = prod('suv', 'Suv 1L', 5000);
  ItemsSingleton.products = [tovar, oddiy, coca, chips, sovga, nolQqs, tarozi, suv];
}

// ───────────────────────── Diskontlar ─────────────────────────

DiscountItem simple({
  required String group,
  required String type,
  required int value,
  bool isAllProducts = true,
  List<String> productIds = const [],
  List<String> categoryIds = const [],
  bool isForAllClients = true,
  List<String> customerGroups = const [],
  String id = 'd-1',
}) {
  return DiscountItem(
    id: id,
    name: 'Chegirma $id',
    displayName: 'Chegirma $id',
    discountGroupType: DiscountGroupType(id: group),
    discountType: DiscountType(id: type),
    discountValue: value,
    isExpirable: false,
    isAllProducts: isAllProducts,
    productIds: productIds.map((e) => ProductIds(id: e, name: e)).toList(),
    categoryIds: categoryIds.map((e) => CategoryIds(id: e, name: e)).toList(),
    isForAllClients: isForAllClients,
    customerGroups: customerGroups.map((e) => CustomerGroups(id: e)).toList(),
    shopIds: [ShopIds(id: kStoreId)],
  );
}

DiscountItem bxgx({
  required int buy,
  required int get,
  required String productId,
  bool repeat = false,
  String id = 'bxgx-1',
}) =>
    DiscountItem(
      id: id,
      name: 'Buy X Get X',
      displayName: '$buy olsang $get tekin',
      discountGroupType: DiscountGroupType(id: gGroupBuyXGetX),
      discountType: DiscountType(id: gTypeBuyXGetX),
      isExpirable: false,
      isForAllClients: true,
      isRepeatable: repeat,
      shopIds: [ShopIds(id: kStoreId)],
      buyXGetX: BuyXGetX(
        productsToBuy: [ProductsToBuy(id: productId, name: productId)],
        buyProductsAmount: buy,
        getProductsAmount: get,
      ),
    );

DiscountItem bxgy({
  required int buy,
  required int get,
  required String buyId,
  required String getId,
  bool repeat = false,
  String id = 'bxgy-1',
}) =>
    DiscountItem(
      id: id,
      name: 'Buy X Get Y',
      displayName: '$buy olsang $get tekin',
      discountGroupType: DiscountGroupType(id: gGroupBuyXGetY),
      discountType: DiscountType(id: gTypeBuyXGetY),
      isExpirable: false,
      isForAllClients: true,
      isRepeatable: repeat,
      shopIds: [ShopIds(id: kStoreId)],
      buyXGetY: BuyXGetY(
        productsToBuy: [ProductsToBuy(id: buyId, name: buyId)],
        buyProductsAmount: buy,
        productToGet: ProductsToGet(id: getId, name: getId),
        getProductsAmount: get,
      ),
    );

DiscountItem freeGift({
  required int buyAmount,
  required int getAmount,
  required String giftId,
  String id = 'fg-1',
}) =>
    DiscountItem(
      id: id,
      name: 'Free Gift',
      displayName: '$buyAmount dan oshsa sovg\'a',
      discountGroupType: DiscountGroupType(id: gGroupFreeGift),
      discountType: DiscountType(id: 'fg-type'),
      isExpirable: false,
      isForAllClients: true,
      shopIds: [ShopIds(id: kStoreId)],
      gifts: [
        Gifts(
          buyAmount: buyAmount,
          getProductAmount: getAmount,
          getProduct: ProductIds(id: giftId, name: giftId),
        ),
      ],
    );

Future<void> seed(List<DiscountItem> items) async {
  final box = HiveBoxes.getDiscounts();
  await box.clear();
  await box.addAll(items);
}

// ───────────────────────── Savat ─────────────────────────

List<ReceiptModelSoldItem4> cartOf(OrderingProvider4 p) =>
    p.getCurrentClient.orderedProducts;

ReceiptModelSoldItem4 rowOf(OrderingProvider4 p, String productId) =>
    cartOf(p).firstWhere((e) => e.productId == productId);

/// `addProduct` → `_createSoldItem` + `_applyDiscounts` bilan bir xil:
/// qator SoldItemBuilder bilan quriladi, keyin mahsulot/kategoriya/mijoz
/// guruhi chegirmalari qo'llanadi.
ReceiptModelSoldItem4 addToCart(
  OrderingProvider4 p,
  ItemModel product,
  double qty, {
  bool isKg = false,
  String clientGroupId = '',
}) {
  final price = ItemsSingleton.finalPrice(product, qty.toInt(), isKg,
          isFirst: true)
      .toDouble();
  final row = SoldItemBuilder.build(product, price, qty, isKg);
  cartOf(p).add(row);
  final categoryId = product.categories?.isNotEmpty == true
      ? product.categories![0].id ?? ''
      : '';
  DiscountSingleton.addDiscountOnProduct(row, categoryId, clientGroupId);
  return row;
}

/// `pressDialogSaveButton` / `addProduct` dagi standart 4 qadam.
void recalc(OrderingProvider4 p) {
  p.findFreeProducts();
  p.useFreeProducts();
  p.useFreeGiftProducts();
  p.useBuyXGetXProducts();
}

ReceiptModelPaymentType4 cash(double v) =>
    ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: v);

ReceiptModelPaymentType4 cashback(double v) =>
    ReceiptModelPaymentType4(name: 'Cashback', payId: kCashbackPayId, value: v);

/// Kassir to'laydigan summa — ilova bilan bir xil (`getTotalPrice`).
double payable(OrderingProvider4 p) => ItemsSingleton.getTotalPrice(cartOf(p));

/// `pressPaymentButton` dagi chek yig'ish.
ReceiptModel4 receiptOf(OrderingProvider4 p,
    {List<ReceiptModelPaymentType4>? payments}) {
  final cart = cartOf(p);
  final total = payable(p);
  return ReceiptBuilder.build(
    sixClient: p.getCurrentClient,
    selectedSupplier: null,
    currentClientDiscountPercent: p.getCurrentClient.discountPercent,
    currentCart: cart,
    totalPrice: total,
    zdachaToCashBack: 0,
    sdacha: 0,
    fromPointBalance: 0,
    comments: '',
    showComments: false,
    payments: payments ?? [cash(total)],
    orphanDeletedItems: const [],
    isTpEdited: true,
  );
}

// ───────────────────────── Fiskal wire ─────────────────────────

/// `LocalService.sell` → `saleOnOFD` → modulga ketadigan JSON (tarmoqsiz).
Map<String, dynamic> wireOf(ReceiptModel4 receipt) {
  final Map<String, dynamic> ofdBody = ReceiptSingleton4.saleOnOFD(receipt);
  final RequestSaleModel model = RequestSaleModel.fromJson(ofdBody);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: kFactory,
      terminalID: kTerminal,
      location: Location(latitude: 41.311081, longitude: 69.240562),
    ),
    DateTime(2026, 9, 24, 12, 0, 0),
    ExtraInfo(
      carNumber: '',
      phoneNumber: '',
      cardType: 0,
      pinfl: '',
      tin: '',
      qrPaymentID: '',
      qrPaymentProvider: 0,
      cardNumber: '',
      pptId: '',
      cashedOutFromCard: 0,
    ),
  );
  return jsonDecode(jsonEncode(fiscal.toJson())) as Map<String, dynamic>;
}

Map<String, dynamic> receiptPart(Map<String, dynamic> wire) =>
    wire['params']['Receipt'] as Map<String, dynamic>;

List<Map<String, dynamic>> itemsOf(Map<String, dynamic> wire) =>
    (receiptPart(wire)['Items'] as List).cast<Map<String, dynamic>>();

num n(Map<String, dynamic> it, String k) => (it[k] as num? ?? 0);

/// Modul kutadigan VAT: trunc((Price − Discount − Other) × p / (100 + p)).
num netVat(Map<String, dynamic> it) {
  final num p = n(it, 'VATPercent');
  if (p == 0) return 0;
  final num base = n(it, 'Price') - n(it, 'Discount') - n(it, 'Other');
  final num v = base * p / (100 + p);
  return v < 0 ? 0 : v.floor();
}

/// Eski (xato) formula: chegirmasiz Price dan.
num grossVat(Map<String, dynamic> it) {
  final num p = n(it, 'VATPercent');
  return p == 0 ? 0 : (n(it, 'Price') * p / (100 + p)).floor();
}

void expectBalanced(Map<String, dynamic> wire) {
  final receipt = receiptPart(wire);
  num left = 0, other = 0;
  for (final it in itemsOf(wire)) {
    left += n(it, 'Price') - n(it, 'Discount');
    other += n(it, 'Other');
    expect(n(it, 'Other') + n(it, 'Discount'), lessThanOrEqualTo(n(it, 'Price')),
        reason: '${it['Name']}: Other + Discount ≤ Price');
  }
  final right = n(receipt, 'ReceivedCash') + n(receipt, 'ReceivedCard') + other;
  expect(left, right, reason: '§10.2.1: Σ(Price − Discount) = naqd + karta + ΣOther');
}

/// Chekni yig'ib, modulga ketadigan JSON'ni savat qatorlari bilan solishtiradi.
/// Qaytaradi: `Items[]` (aniq raqamlarni tekshirish uchun).
List<Map<String, dynamic>> verify(
  OrderingProvider4 p, {
  List<ReceiptModelPaymentType4>? payments,
}) {
  final rows = cartOf(p).where((r) => !(r.isDeleted ?? false)).toList();
  final wire = wireOf(receiptOf(p, payments: payments));
  expect(wire['method'], 'Api.SendSaleReceipt');
  final items = itemsOf(wire);
  expect(items.length, rows.length,
      reason: 'har savat qatori = bitta fiskal item (o\'chirilganlar chiqmaydi)');

  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    final it = items[i];
    final why = '${r.productName} (qator $i)';

    final double unit = r.realPrice > r.price ? r.realPrice : r.price;
    final num expPrice = UtilFunctions.roundToNearest(r.value * unit) * 100;
    // Balans majburlash tarozi yaxlitlashida Price'ni ≤ 1 so'm surishi mumkin.
    expect(n(it, 'Price'), closeTo(expPrice, 100),
        reason: '$why: Price = round(realPrice × qty) × 100');

    final num expDisc =
        r.realPrice > r.price ? (r.realPrice - r.price) * r.value * 100 : 0;
    expect(n(it, 'Discount'), closeTo(expDisc, 1),
        reason: '$why: Discount = (realPrice − price) × qty × 100');

    expect(n(it, 'VATPercent'), r.vatPercent, reason: '$why: VATPercent');
    expect(n(it, 'Amount'), closeTo(r.value * 1000, 0.5), reason: '$why: Amount');

    expect(n(it, 'VAT'), closeTo(netVat(it), 1),
        reason: '$why: VAT = (Price − Discount − Other) × p/(100+p) '
            '(Price=${it['Price']} Discount=${it['Discount']} Other=${it['Other']})');
    if (n(it, 'Discount') > 0 && n(it, 'VATPercent') > 0) {
      expect(n(it, 'VAT'), lessThan(grossVat(it)),
          reason: '$why: chegirmali qatorda QQS chegirmasiz narxdan KETMASLIGI kerak');
    }
  }
  expectBalanced(wire);
  return items;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('fiscal_vat_discount_types');
    await Pref.setString(PrefKeys.storeId, kStoreId);
    await Pref.setString(PrefKeys.mxikCode, kMxik);
    await Pref.setString(PrefKeys.cashbackId, kCashbackPayId);
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(seedCatalog);
  tearDown(() async {
    await HiveBoxes.getDiscounts().clear();
    ItemsSingleton.products = [];
  });

  group('Mahsulot / kategoriya / mijoz guruhi chegirmalari (addDiscountOnProduct)',
      () {
    test('mahsulot 10%: 50 000 → 45 000, QQS 45 000 dan', () async {
      await seed([simple(group: gGroupProduct, type: gTypePercentage, value: 10)]);
      final p = freshProvider();
      addToCart(p, tovar, 1);
      recalc(p);
      expect(rowOf(p, 'tovar').price, 45000);

      final it = verify(p).single;
      expect(it['Price'], 5000000);
      expect(it['Discount'], 500000);
      // 4 500 000 × 12 / 112 = 482 142.86
      expect(it['VAT'], closeTo(482142, 1));
      expect(it['VAT'], isNot(closeTo(535714, 1)), reason: 'eski formula');
    });

    test('mahsulot 10%, 3 dona: Discount va QQS qator bo\'yicha', () async {
      await seed([simple(group: gGroupProduct, type: gTypePercentage, value: 10)]);
      final p = freshProvider();
      addToCart(p, tovar, 3);
      recalc(p);

      final it = verify(p).single;
      expect(it['Amount'], 3000);
      expect(it['Price'], 15000000);
      expect(it['Discount'], 1500000);
      // 13 500 000 × 12 / 112 = 1 446 428.57
      expect(it['VAT'], closeTo(1446428, 1));
    });

    test('mahsulot summa chegirmasi 5 000: 50 000 → 45 000', () async {
      await seed([simple(group: gGroupProduct, type: gTypeNumeric, value: 5000)]);
      final p = freshProvider();
      addToCart(p, tovar, 1);
      recalc(p);
      expect(rowOf(p, 'tovar').price, 45000);

      final it = verify(p).single;
      expect(it['Discount'], 500000);
      expect(it['VAT'], closeTo(482142, 1));
    });

    test('kategoriya 20%: faqat shu kategoriyadagi qatorga', () async {
      await seed([
        simple(
            group: gGroupCategory,
            type: gTypePercentage,
            value: 20,
            isAllProducts: false,
            categoryIds: [kCat]),
      ]);
      final p = freshProvider();
      addToCart(p, tovar, 1); // kCat
      addToCart(p, oddiy, 1); // kategoriyasiz
      recalc(p);
      expect(rowOf(p, 'tovar').price, 40000);
      expect(rowOf(p, 'oddiy').price, 30000);

      final items = verify(p);
      final t = items[0], o = items[1];
      expect(t['Discount'], 1000000);
      // 4 000 000 × 12 / 112 = 428 571.43
      expect(t['VAT'], closeTo(428571, 1));
      expect(o['Discount'], 0);
      // 3 000 000 × 12 / 112 = 321 428.57
      expect(o['VAT'], closeTo(321428, 1));
    });

    test('kategoriya 20% + mahsulot 10% zanjiri: 50 000 → 36 000', () async {
      await seed([
        simple(
            id: 'cat',
            group: gGroupCategory,
            type: gTypePercentage,
            value: 20,
            isAllProducts: false,
            categoryIds: [kCat]),
        simple(id: 'prod', group: gGroupProduct, type: gTypePercentage, value: 10),
      ]);
      final p = freshProvider();
      addToCart(p, tovar, 1);
      recalc(p);
      expect(rowOf(p, 'tovar').price, closeTo(36000, 0.01));

      final it = verify(p).single;
      expect(it['Discount'], closeTo(1400000, 1));
      // 3 600 000 × 12 / 112 = 385 714.28
      expect(it['VAT'], closeTo(385714, 1));
    });

    test('mijoz guruhi chegirmasi: VIP mijozga 10%, boshqaga yo\'q', () async {
      await seed([
        simple(
            group: gGroupProduct,
            type: gTypePercentage,
            value: 10,
            isForAllClients: false,
            customerGroups: [kVip]),
      ]);
      // VIP
      final vip = freshProvider();
      vip.getCurrentClient.selectedClient =
          ClientModel(
              id: 'c-1',
              firstName: 'Vip',
              phoneNumber: '998',
              groupId: kVip,
              discountValue: 0);
      addToCart(vip, tovar, 1, clientGroupId: kVip);
      recalc(vip);
      expect(rowOf(vip, 'tovar').price, 45000);
      final v = verify(vip).single;
      expect(v['Discount'], 500000);
      expect(v['VAT'], closeTo(482142, 1));

      // Oddiy mijoz — chegirma yo'q, QQS to'liq
      final plain = freshProvider();
      addToCart(plain, tovar, 1);
      recalc(plain);
      final o = verify(plain).single;
      expect(o['Discount'], 0);
      expect(o['VAT'], closeTo(535714, 1));
    });

    test('QQS 0% tovar + 10% chegirma: VATPercent 0, VAT 0, Discount bor',
        () async {
      await seed([simple(group: gGroupProduct, type: gTypePercentage, value: 10)]);
      final p = freshProvider();
      addToCart(p, nolQqs, 1);
      recalc(p);

      final it = verify(p).single;
      expect(it['VATPercent'], 0);
      expect(it['VAT'], 0);
      expect(it['Discount'], 500000);
    });

    test('100% chegirma: Discount = Price, VAT 0', () async {
      await seed([simple(group: gGroupProduct, type: gTypePercentage, value: 100)]);
      final p = freshProvider();
      addToCart(p, tovar, 2);
      recalc(p);
      expect(rowOf(p, 'tovar').price, 0);

      final it = verify(p).single;
      expect(it['Price'], 10000000);
      expect(it['Discount'], 10000000);
      expect(it['VAT'], 0);
      expect(receiptPart(wireOf(receiptOf(p)))['ReceivedCash'], 0);
    });
  });

  group('Buy X Get X — bir xil mahsulotdan tekin (1+1, 3+1)', () {
    test('3+1, 4 dona: 1 tasi tekin → Discount = 1 dona, QQS 3 donadan', () async {
      await seed([bxgx(buy: 3, get: 1, productId: 'tovar')]);
      final p = freshProvider();
      addToCart(p, tovar, 4);
      recalc(p);
      expect(rowOf(p, 'tovar').price, 37500);

      final it = verify(p).single;
      expect(it['Amount'], 4000);
      expect(it['Price'], 20000000);
      expect(it['Discount'], 5000000);
      // 15 000 000 × 12 / 112 = 1 607 142.86
      expect(it['VAT'], closeTo(1607142, 1));
    });

    test('1+1 takrorlanuvchi, 6 dona: 3 tasi tekin', () async {
      await seed([bxgx(buy: 1, get: 1, productId: 'tovar', repeat: true)]);
      final p = freshProvider();
      addToCart(p, tovar, 6);
      recalc(p);
      expect(rowOf(p, 'tovar').price, 25000);

      final it = verify(p).single;
      expect(it['Price'], 30000000);
      expect(it['Discount'], 15000000);
      expect(it['VAT'], closeTo(1607142, 1));
    });

    test('1+1 takrorlanuvchi, 5 dona (toq): 2 tasi tekin', () async {
      await seed([bxgx(buy: 1, get: 1, productId: 'tovar', repeat: true)]);
      final p = freshProvider();
      addToCart(p, tovar, 5);
      recalc(p);
      expect(rowOf(p, 'tovar').price, 30000);

      final it = verify(p).single;
      expect(it['Price'], 25000000);
      expect(it['Discount'], 10000000);
      // 15 000 000 × 12 / 112
      expect(it['VAT'], closeTo(1607142, 1));
    });

    // ⚠️ QAYD ETILGAN XATTI-HARAKAT (bu branch'da tuzatilmadi — diskont
    // mexanizmi, QQS'ga aloqasi yo'q). Bir mahsulot bir nechta qatorda bo'lsa
    // (markirovka: har KM value=1), `useBuyXGetXProducts` ning ko'p qatorli
    // yo'li `gift.getProductAmount` ni ishlatadi, u esa
    // `getBuyXGetXDiscountsOnly` da `forDialogOnly: true` bilan olingani uchun
    // XOM "get" soni (1), hisoblangan tekin soni (floor(4/2)×1 = 2) EMAS.
    // Natija: 1+1 takrorlanuvchi, 4 ta KM → faqat 1 tasi tekin (bitta qatorda
    // 4 dona bo'lsa 2 tasi tekin — yuqoridagi testlar). Alohida task.
    //
    // Bu test QQS uchun: qaysi qator tekin bo'lmasin, har qatorda
    // VAT = (Price − Discount − Other) × p/(100+p) va KM Label'da ketadi.
    test('QAYD: 1+1 markirovkali (4 ta KM alohida qator) — hozir 1 tasi tekin, QQS har qatorda netdan',
        () async {
      await seed([bxgx(buy: 1, get: 1, productId: 'tovar', repeat: true)]);
      final p = freshProvider();
      for (var i = 1; i <= 4; i++) {
        final r = addToCart(p, tovar, 1);
        r.mark = '0104780000000001215KM$i';
        r.marking = true;
      }
      recalc(p);

      final items = verify(p);
      expect(items.length, 4);
      num sumDisc = 0, sumVat = 0, sumPrice = 0;
      for (var i = 0; i < 4; i++) {
        expect(items[i]['Label'], cartOf(p)[i].mark, reason: 'KM Label da');
        sumDisc += n(items[i], 'Discount');
        sumVat += n(items[i], 'VAT');
        sumPrice += n(items[i], 'Price');
      }
      expect(sumPrice, 20000000);
      // Hozirgi xatti-harakat: 1 dona tekin (to'g'risi 2 bo'lishi kerak edi)
      expect(sumDisc, closeTo(5000000, 4));
      final free = items.where((e) => n(e, 'Discount') == n(e, 'Price')).toList();
      expect(free.length, 1);
      expect(free.single['VAT'], 0);
      // To'langan 3 qator: har biri 5 000 000 × 12/112 = 535 714
      expect(sumVat, closeTo(3 * 535714, 4));
    });

    test('3+1, 2 dona (shart bajarilmagan): chegirma yo\'q, QQS to\'liq', () async {
      await seed([bxgx(buy: 3, get: 1, productId: 'tovar')]);
      final p = freshProvider();
      addToCart(p, tovar, 2);
      recalc(p);

      final it = verify(p).single;
      expect(it['Discount'], 0);
      // 10 000 000 × 12 / 112 = 1 071 428.57
      expect(it['VAT'], closeTo(1071428, 1));
    });
  });

  group('Buy X Get Y — boshqa mahsulot tekin', () {
    test('2 Coca + 1 Chips: Chips Discount = Price, VAT 0; Coca to\'liq', () async {
      await seed([bxgy(buy: 2, get: 1, buyId: 'coca', getId: 'chips')]);
      final p = freshProvider();
      addToCart(p, coca, 2);
      addToCart(p, chips, 1);
      recalc(p);
      expect(rowOf(p, 'chips').price, 0);

      final items = verify(p);
      final c = items[0], ch = items[1];
      expect(c['Price'], 2400000);
      expect(c['Discount'], 0);
      expect(c['VAT'], closeTo(257142, 1), reason: 'hujjatdagi misol (Coca-Cola)');
      expect(ch['Price'], 600000);
      expect(ch['Discount'], 600000);
      expect(ch['VAT'], 0);
    });

    test('2 Coca + 2 Chips (get=1): Chips qatorining yarmi tekin', () async {
      await seed([bxgy(buy: 2, get: 1, buyId: 'coca', getId: 'chips')]);
      final p = freshProvider();
      addToCart(p, coca, 2);
      addToCart(p, chips, 2);
      recalc(p);
      expect(rowOf(p, 'chips').price, 3000);

      final ch = verify(p)[1];
      expect(ch['Price'], 1200000);
      expect(ch['Discount'], 600000);
      // 600 000 × 12 / 112 = 64 285.7
      expect(ch['VAT'], closeTo(64285, 1));
    });
  });

  group('Free Gift — summadan oshsa sovg\'a', () {
    test('150 000 ≥ 100 000: sovg\'a qatori Discount = Price, VAT 0', () async {
      await seed([freeGift(buyAmount: 100000, getAmount: 1, giftId: 'sovga')]);
      final p = freshProvider();
      addToCart(p, tovar, 3);
      addToCart(p, sovga, 1);
      recalc(p);
      expect(rowOf(p, 'sovga').price, 0);
      expect(rowOf(p, 'tovar').price, 50000);

      final items = verify(p);
      final t = items[0], g = items[1];
      expect(t['Discount'], 0);
      // 15 000 000 × 12 / 112 = 1 607 142.86
      expect(t['VAT'], closeTo(1607142, 1));
      expect(g['Price'], 1000000);
      expect(g['Discount'], 1000000);
      expect(g['VAT'], 0);
    });
  });

  group('Chek darajasidagi ("tepa") foiz chegirma', () {
    test('10% butun chekka: har qator o\'z Discount va QQS bilan', () async {
      await seed([]);
      final p = freshProvider();
      addToCart(p, tovar, 1);
      addToCart(p, oddiy, 2);
      recalc(p);
      p.setNewClientDiscountPercentage(10);
      expect(rowOf(p, 'tovar').price, 45000);
      expect(rowOf(p, 'oddiy').price, 27000);

      final items = verify(p);
      final t = items[0], o = items[1];
      expect(t['Discount'], 500000);
      expect(t['VAT'], closeTo(482142, 1));
      expect(o['Price'], 6000000);
      expect(o['Discount'], 600000);
      // 5 400 000 × 12 / 112 = 578 571.43
      expect(o['VAT'], closeTo(578571, 1));
    });

    test('mahsulot 10% ustiga tepa 10%: 50 000 → 45 000 → 40 500', () async {
      await seed([simple(group: gGroupProduct, type: gTypePercentage, value: 10)]);
      final p = freshProvider();
      addToCart(p, tovar, 1);
      recalc(p);
      p.setNewClientDiscountPercentage(10);
      expect(rowOf(p, 'tovar').price, closeTo(40500, 0.01));

      final it = verify(p).single;
      expect(it['Discount'], closeTo(950000, 1));
      // 4 050 000 × 12 / 112 = 433 928.57
      expect(it['VAT'], closeTo(433928, 1));
    });
  });

  group('Qo\'lda narx / chegirma (dialog, utsenka QR)', () {
    test('utsenka QR: realPrice 50 000, sotuv 35 000 → Discount 15 000, QQS 35 000 dan',
        () async {
      await seed([]);
      final p = freshProvider();
      // `_parseUtsenkaQr` bilan bir xil
      final r = SoldItemBuilder.build(tovar, 35000, 1, false)
        ..realPrice = 50000
        ..onlyPrice = 50000
        ..singleDiscount = 15000
        ..discountPercent = 30
        ..isPriceChanged = true
        ..isPriceOnlyChanged = true;
      cartOf(p).add(r);
      recalc(p);
      expect(r.price, 35000, reason: 'qo\'lda narxga avto-chegirma tegmaydi');

      final it = verify(p).single;
      expect(it['Price'], 5000000);
      expect(it['Discount'], 1500000);
      // 3 500 000 × 12 / 112 = 375 000
      expect(it['VAT'], closeTo(375000, 1));
    });

    test('dialogda narx qo\'lda 40 000 ga o\'zgartirilgan (realPrice ham): Discount 0',
        () async {
      await seed([]);
      final p = freshProvider();
      // `onlyPriceChanged` bilan bir xil: price = onlyPrice = realPrice
      final r = SoldItemBuilder.build(tovar, 50000, 1, false)
        ..price = 40000
        ..onlyPrice = 40000
        ..realPrice = 40000
        ..isPriceChanged = true
        ..isPriceOnlyChanged = true;
      cartOf(p).add(r);

      final it = verify(p).single;
      expect(it['Price'], 4000000);
      expect(it['Discount'], 0);
      // 4 000 000 × 12 / 112 = 428 571.43
      expect(it['VAT'], closeTo(428571, 1));
    });

    test('dialogda chegirma kiritilgan (realPrice qoladi): 50 000 → 42 000', () async {
      await seed([]);
      final p = freshProvider();
      // `onPriceChanged` + `onSaveButtonPressed` bilan bir xil
      final r = SoldItemBuilder.build(tovar, 50000, 1, false)
        ..price = 42000
        ..onlyPrice = 50000
        ..singleDiscount = 8000
        ..discountPercent = 16
        ..isPriceChanged = true
        ..isPriceOnlyChanged = true;
      cartOf(p).add(r);

      final it = verify(p).single;
      expect(it['Discount'], 800000);
      // 4 200 000 × 12 / 112 = 450 000
      expect(it['VAT'], closeTo(450000, 1));
    });
  });

  group('Tarozi (kg) va blok', () {
    test('0.29 kg × 77 950, 10% chegirma: yarim so\'m yaxlitlash bilan ham QQS netdan',
        () async {
      await seed([simple(group: gGroupProduct, type: gTypePercentage, value: 10)]);
      final p = freshProvider();
      addToCart(p, tarozi, 0.29, isKg: true);
      recalc(p);
      expect(rowOf(p, 'tarozi').price, closeTo(70155, 0.01));

      final it = verify(p).single;
      expect(it['Amount'], 290);
      // Price = round(0.29 × 77 950 = 22 605.5) × 100 = 2 260 600 (±1 so'm balans)
      expect(it['Price'], closeTo(2260600, 100));
      // Discount = 7 795 × 0.29 × 100 = 226 055
      expect(it['Discount'], closeTo(226055, 1));
      // To'lov = round(70 155 × 0.29) = 20 345 → VAT = 2 034 500 × 12/112 = 217 982.14
      expect(it['VAT'], closeTo(217982, 1));
    });

    test('blok (12 dona × 5 000) + "10 olsang 2 tekin": blok narxi 60 000 → 50 000',
        () async {
      await seed([bxgx(buy: 10, get: 2, productId: 'suv')]);
      final p = freshProvider();
      cartOf(p).add(makeSoldItem(
        productId: 'suv',
        name: 'Suv 1L (blok)',
        price: 60000,
        realPrice: 60000,
        value: 1,
        saleType: 2,
        boxValue: 12,
        boxQuantity: 1,
        mxik: kMxik,
      ));
      recalc(p);
      expect(rowOf(p, 'suv').price, closeTo(50000, 0.01));

      final it = verify(p).single;
      expect(it['Price'], 6000000);
      expect(it['Discount'], closeTo(1000000, 1));
      // 5 000 000 × 12 / 112 = 535 714.28
      expect(it['VAT'], closeTo(535714, 1));
    });
  });

  group('Chegirma + cashback + aralash chek', () {
    test('mahsulot 10% + oddiy tovar, cashback 15 000 + naqd 60 000', () async {
      await seed([simple(group: gGroupProduct, type: gTypePercentage, value: 10, isAllProducts: false, productIds: ['tovar'])]);
      final p = freshProvider();
      addToCart(p, tovar, 1); // 45 000
      addToCart(p, oddiy, 1); // 30 000
      recalc(p);
      expect(payable(p), 75000);

      final items = verify(p, payments: [cashback(15000), cash(60000)]);
      final t = items[0], o = items[1];
      // Other ulushi: 45/75 × 15 000 = 9 000; 30/75 × 15 000 = 6 000
      expect(t['Other'], 900000);
      expect(o['Other'], 600000);
      // (5 000 000 − 500 000 − 900 000) × 12 / 112 = 385 714.28
      expect(t['VAT'], closeTo(385714, 1));
      // (3 000 000 − 600 000) × 12 / 112 = 257 142.86
      expect(o['VAT'], closeTo(257142, 1));
    });

    test('3+1 (4 dona) + 100% cashback: Other = Price − Discount, VAT 0', () async {
      await seed([bxgx(buy: 3, get: 1, productId: 'tovar')]);
      final p = freshProvider();
      addToCart(p, tovar, 4);
      recalc(p);
      expect(payable(p), 150000);

      final it = verify(p, payments: [cashback(150000)]).single;
      expect(it['Other'], 15000000);
      expect(n(it, 'Other') + n(it, 'Discount'), it['Price']);
      expect(it['VAT'], 0);
    });

    test('sovg\'a (0 so\'m) qatori + cashback: sovg\'aga Other tushmaydi', () async {
      await seed([freeGift(buyAmount: 100000, getAmount: 1, giftId: 'sovga')]);
      final p = freshProvider();
      addToCart(p, tovar, 3); // 150 000
      addToCart(p, sovga, 1); // 0
      recalc(p);
      expect(payable(p), 150000);

      final items = verify(p, payments: [cashback(50000), cash(100000)]);
      final t = items[0], g = items[1];
      expect(t['Other'], 5000000);
      // (15 000 000 − 5 000 000) × 12 / 112 = 1 071 428.57
      expect(t['VAT'], closeTo(1071428, 1));
      expect(g['Other'], 0);
      expect(g['Discount'], g['Price']);
      expect(g['VAT'], 0);
    });

    test('red-delete: o\'chirilgan chegirmali qator fiskalga ketmaydi, balans saqlanadi',
        () async {
      await seed([simple(group: gGroupProduct, type: gTypePercentage, value: 10)]);
      final p = freshProvider();
      addToCart(p, tovar, 1);
      addToCart(p, oddiy, 1);
      recalc(p);
      rowOf(p, 'oddiy').isDeleted = true;
      expect(payable(p), 45000);

      final items = verify(p);
      expect(items.single['Name'], 'Tovar');
      expect(items.single['VAT'], closeTo(482142, 1));
    });

    test('katta aralash chek: foiz + Buy X Get Y + Free Gift + QQS 0% + cashback',
        () async {
      await seed([
        simple(id: 'p10', group: gGroupProduct, type: gTypePercentage, value: 10,
            isAllProducts: false, productIds: ['tovar', 'nol-qqs']),
        bxgy(buy: 2, get: 1, buyId: 'coca', getId: 'chips'),
        freeGift(buyAmount: 100000, getAmount: 1, giftId: 'sovga'),
      ]);
      final p = freshProvider();
      addToCart(p, tovar, 2); // 2 × 45 000
      addToCart(p, coca, 2); // 24 000
      addToCart(p, chips, 1); // tekin
      addToCart(p, oddiy, 1); // 30 000
      addToCart(p, nolQqs, 1); // 45 000, QQS 0
      addToCart(p, sovga, 1); // sovg'a
      recalc(p);
      expect(rowOf(p, 'chips').price, 0);
      expect(rowOf(p, 'sovga').price, 0);
      final total = payable(p);
      expect(total, 90000 + 24000 + 30000 + 45000);

      final items = verify(p, payments: [cashback(20000), cash(total - 20000)]);
      expect(items.length, 6);
      expect(items.where((e) => n(e, 'Discount') > 0).length, 4,
          reason: 'tovar, chips, nol-qqs, sovg\'a');
      // QQS 0% qatorida VAT 0, qolganlarda > 0 (tekinlardan tashqari)
      expect(items[4]['VAT'], 0);
      expect(n(items[0], 'VAT'), greaterThan(0));
      expect(n(items[1], 'VAT'), greaterThan(0));
      expect(n(items[3], 'VAT'), greaterThan(0));
    });
  });
}
