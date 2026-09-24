// Vozvrat qatorining fiskal OwnerType va komitent STIR'i — sotuv bilan bir xil.
//
// Nega kerak: vozvrat qatorlari serverdan keladi (`owner_type`/`commission_tin`
// yo'q) va ilgari `ChecksSingleton` `ownerType: 0`, `tin: ""` qattiq yozardi.
// Soliqqa sotuvda `OwnerType: 1` ketgan tovar vozvratda `OwnerType: 0` bilan
// ketardi (soliq sahifasi: "Komitent STIR/JSHSHIR: 0", 2026-09-23).
//
// Tekshiriladi:
//   1. `RefundItemOrigin.resolve` — `SoldItemBuilder` bilan bir xil qoida
//   2. `ChecksSingleton.globalToLocall` — server itemi katalog mahsulotidan OwnerType/STIR oladi
//   3. Modulga ketadigan JSON (`Api.SendRefundReceipt`) — `OwnerType` sotuvdagi bilan bir xil
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/sold_item_builder.dart';
import 'package:invan2/changes/domain/receipt/refund_item_origin.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/models/receipts_get_model.dart';
import 'package:invan2/features/get_products/singletons/checks_singleton.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/fiscal_service/model/fiscal_receipt_model.dart';
import 'package:invan2/fiscal_service/model/location/location.dart';
import 'package:invan2/fiscal_service/model/receipt_data_model.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kMxik = '02202002001010021';
const kTin9 = '309072901';
const kPinfl14 = '31234567890123';

ItemModel product(String id, {String? ownerType, String? commissionTin}) {
  final m = ItemModel();
  m.id = id;
  m.name = 'Tovar $id';
  m.mxikCode = kMxik;
  m.barcode = ['4780069000017'];
  m.ownerType = ownerType;
  m.commissionTin = commissionTin;
  m.packageCode = '104579';
  return m;
}

/// Server `api/v1/order` javobidagi bitta sotuv cheki (vozvrat sahifasi
/// aynan shu shakldan boshlanadi).
GlobalReceipt serverSale(List<String> productIds) => GlobalReceipt.fromJson({
      'id': 'order-1',
      'external_id': 'DP-1',
      'status': {'name': 'paid'},
      'total_price': 191760 * productIds.length,
      'create_time': '2026-09-23T11:46:24Z',
      'terminal_id': 'LG230110020538',
      'receipt_seq': 38390,
      'date_time': '20260923164600',
      'fiscal_sign': '111111111111',
      'url': 'https://ofd.soliq.uz/check?t=LG230110020538&r=38390&c=20260923164600&s=111111111111',
      'pays': [],
      'items': [
        for (final pid in productIds)
          {
            'id': 'item-$pid',
            'product_id': pid,
            'product_name': 'Coca-Cola energy 250ml',
            'price': 7990,
            'value': 24,
            'refund_amount': 0,
            'total_price': 191760,
            'barcode': '4780069000017',
            'sku': '1',
            'mxik_code': kMxik,
            'vat_name': 'QQS 12%',
            'vat_percentage': 12,
            'package_code': '104579',
            'package_name': 'dona',
          },
      ],
    });

/// Modulga ketadigan JSON — `LocalService.saleWithOutIncom` zanjiri tarmoqsiz.
Map<String, dynamic> wireJson(ReceiptModel4 receipt) {
  final ofdBody = ReceiptSingleton4.saleOnOFD(receipt);
  final model = RequestSaleModel.fromJson(ofdBody);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: 'UZ000000000MOCK',
      terminalID: 'LG230110020538',
      location: Location(latitude: 41.311081, longitude: 69.240562),
    ),
    DateTime(2026, 9, 23, 16, 46, 24),
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

List<Map<String, dynamic>> itemsOf(Map<String, dynamic> wire) =>
    (wire['params']['Receipt']['Items'] as List).cast<Map<String, dynamic>>();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => setUpPosTestEnv('refund_item_origin', withEmployee: false));
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [
      product('p-own', ownerType: '1'),
      product('p-komissiya', ownerType: '2', commissionTin: kTin9),
      product('p-fiz', ownerType: '2', commissionTin: kPinfl14),
      product('p-null'), // adminka owner_type bermagan
    ];
  });
  tearDown(() => ItemsSingleton.products = []);

  group('RefundItemOrigin.resolve — SoldItemBuilder bilan bir xil', () {
    test('o\'z tovari → OwnerType 1, STIR bo\'sh', () {
      final o = RefundItemOrigin.resolve(product('x', ownerType: '1'));
      expect(o.ownerType, 1);
      expect(o.tin, '');
    });

    test('komissiya tovari → OwnerType 2, STIR adminkadan', () {
      final o = RefundItemOrigin.resolve(
          product('x', ownerType: '2', commissionTin: kTin9));
      expect(o.ownerType, 2);
      expect(o.tin, kTin9);
    });

    test('owner_type yo\'q / buzuq → 1 (spec: oddiy tovar)', () {
      expect(RefundItemOrigin.resolve(product('x')).ownerType, 1);
      expect(RefundItemOrigin.resolve(product('x', ownerType: 'abc')).ownerType, 1);
    });

    test('mahsulot katalogda yo\'q → fallback 1, ""', () {
      expect(RefundItemOrigin.resolve(null), same(RefundItemOrigin.fallback));
      expect(RefundItemOrigin.fromCatalog('yo-q-id').ownerType, 1);
      expect(RefundItemOrigin.fromCatalog('').ownerType, 1);
      expect(RefundItemOrigin.fromCatalog(null).tin, '');
    });

    test('katalogda id == null mahsulot bo\'lsa ham exception yo\'q', () {
      ItemsSingleton.products = [ItemModel()..name = 'buzuq', product('p-own', ownerType: '1')];
      expect(() => RefundItemOrigin.fromCatalog('p-own'), returnsNormally);
    });

    for (final p in [
      product('a', ownerType: '1'),
      product('b', ownerType: '2', commissionTin: kTin9),
      product('c'),
    ]) {
      test('sotuv qatori (SoldItemBuilder) bilan aynan bir xil: ${p.id}', () {
        final sale = SoldItemBuilder.build(p, 7990, 1, false);
        final o = RefundItemOrigin.resolve(p);
        expect(o.ownerType, sale.ownerType);
        expect(o.tin, sale.tin);
      });
    }
  });

  group('ChecksSingleton.globalToLocall — vozvrat qatori', () {
    test('OwnerType va STIR katalogdan (ilgari 0 va "")', () {
      final r = ChecksSingleton.globalToLocall(
          serverSale(['p-own', 'p-komissiya', 'p-fiz', 'p-none']));
      final byId = {for (final e in r.soldItemList) e.productId: e};

      expect(byId['p-own']!.ownerType, 1);
      expect(byId['p-own']!.tin, '');
      expect(byId['p-komissiya']!.ownerType, 2);
      expect(byId['p-komissiya']!.tin, kTin9);
      expect(byId['p-fiz']!.tin, kPinfl14);
      expect(byId['p-none']!.ownerType, 1,
          reason: 'katalogda yo\'q (o\'chirilgan tovar) — spec default');
      expect(byId['p-none']!.tin, '');
    });

    test('refundItemId server item idsi bo\'lib qoladi (regressiya)', () {
      final r = ChecksSingleton.globalToLocall(serverSale(['p-own']));
      expect(r.soldItemList.single.refundItemId, 'item-p-own');
      expect(r.soldItemList.single.value, 24);
    });
  });

  group('Api.SendRefundReceipt — modulga ketadigan JSON', () {
    setUp(() async {
      await Pref.setString(PrefKeys.cashId, 'cash-id');
      await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
    });

    test('vozvrat OwnerType sotuvdagi bilan bir xil (1), 0 emas', () {
      final original = ChecksSingleton.globalToLocall(serverSale(['p-own']));

      // return_bloc vozvrat modelini shunday quradi: isRefund, CASH, refundInfo.
      final refund = original
        ..isRefund = true
        ..externalId = 'DP-2'
        ..returnForCheck = 'DP-1';
      refund.payment
        ..clear()
        ..add(ReceiptModelPaymentType4(
            name: 'CASH', payId: 'cash-id', value: 191760));

      final wire = wireJson(refund);
      expect(wire['method'], 'Api.SendRefundReceipt');
      final it = itemsOf(wire).single;
      expect(it['OwnerType'], 1);
      expect(it['CommissionInfo'], {'TIN': '', 'PINFL': ''});

      // Sotuv qatori xuddi shu mahsulotdan — bir xil OwnerType.
      final saleRow = SoldItemBuilder.build(
          ItemsSingleton.getProductById('p-own')!, 7990, 24, false);
      expect(saleRow.ownerType, it['OwnerType']);
    });

    test('komissiya tovari: OwnerType 2 ketadi', () {
      final original = ChecksSingleton.globalToLocall(serverSale(['p-komissiya']));
      final refund = original
        ..isRefund = true
        ..externalId = 'DP-3'
        ..returnForCheck = 'DP-1';
      refund.payment
        ..clear()
        ..add(ReceiptModelPaymentType4(
            name: 'CASH', payId: 'cash-id', value: 191760));
      final it = itemsOf(wireJson(refund)).single;
      expect(it['OwnerType'], 2);
    });
  });
}
