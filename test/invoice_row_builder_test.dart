// Invoice (yuk xati) qatoridan savat qatori yasash — `InvoiceRowBuilder`.
//
// Bu kod Faza 9.5 gacha `loadInvoiceByBarcodeWithBloc` ichida edi va uni
// testlab bo'lmasdi: metod `BuildContext` oladi va `InvoiceBloc` stream'ini
// kutadi. Narx tanlash qoidasi (invoice tiers → katalog fallback) shu
// yerda muzlatiladi.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/cart/invoice_row_builder.dart';
import 'package:invan2/changes/models/invoice_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

InvoiceItem invoiceItem({
  String name = 'Suv (yuk xatidan)',
  int amount = 3,
  double cost = 4000,
  List<Price> prices = const [],
}) =>
    InvoiceItem(
      id: 'ii-1',
      productId: 'suv-id',
      productName: name,
      barcode: '4780000000001',
      sku: '1001',
      expectedAmount: amount,
      cost: cost,
      totalAmount: 0,
      invoiceId: 'inv-1',
      productStock: 0,
      prices: prices,
      realPrices: const [],
    );

Price price(int minQty, double p) =>
    Price(minQuantity: minQty, price: p, invoiceItemId: 'ii-1');

ItemModel product({
  String unit = 'dona',
  int vatPercent = 12,
  num catalogPrice = 5000,
  String mxik = '01101001001000000',
  String? ownerType = '2',
  bool? isMarking,
}) {
  final m = ItemModel();
  m.id = 'suv-id';
  m.name = 'Suv (katalogdan)';
  m.sku = '1001';
  m.mxikCode = mxik;
  m.isMarking = isMarking;
  m.packageCode = 'PACK-1';
  m.commissionTin = '123456789';
  m.ownerType = ownerType;
  m.barcode = ['4780000000001', '4780000000002'];
  m.vat = Vat(percentage: vatPercent, name: 'NDS $vatPercent%');
  m.measurementUnit = MeasurementUnit(shortName: unit);
  m.shopPrices = ShopPrices(
    shID: ShID(shopId: 'shop-1', shopPriceTiers: [
      ShopPriceTiers(minQuantity: 1, retailPrice: catalogPrice),
    ]),
  );
  return m;
}

void main() {
  setUpAll(() async {
    await setUpPosTestEnv('invoice_row_builder_test');
    // Markirovka qoidasi OFD sozlamasiga bog'liq.
    await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
  });
  tearDownAll(tearDownPosTestEnv);

  group('Narx tanlash', () {
    test('invoice narxi bo\'lsa o\'sha olinadi', () {
      final r = InvoiceRowBuilder.build(
          invoiceItem(prices: [price(1, 4500)]), product());
      expect(r.price, 4500);
    });

    test('bir nechta tier: eng KATTA minQuantity ustun', () {
      final r = InvoiceRowBuilder.build(
        invoiceItem(prices: [price(1, 5000), price(12, 4200), price(6, 4600)]),
        product(),
      );
      expect(r.price, 4200);
    });

    test('invoice narx bermasa katalogning 1 donalik narxi olinadi', () {
      final r = InvoiceRowBuilder.build(invoiceItem(), product());
      expect(r.price, 5000);
    });

    test('invoice narxi 0 bo\'lsa ham katalogga tushadi', () {
      final r = InvoiceRowBuilder.build(
          invoiceItem(prices: [price(1, 0)]), product());
      expect(r.price, 5000);
    });

    test('realPrice va onlyPrice narx bilan bir xil', () {
      final r = InvoiceRowBuilder.build(
          invoiceItem(prices: [price(1, 4500)]), product());
      expect([r.realPrice, r.onlyPrice], [4500, 4500]);
    });
  });

  group('Maydonlar manbasi: invoice vs katalog', () {
    test('nom INVOICE dan olinadi (katalog nomidan emas)', () {
      final r =
          InvoiceRowBuilder.build(invoiceItem(name: 'Yuk xati nomi'), product());
      expect(r.productName, 'Yuk xati nomi');
    });

    test('miqdor invoice expectedAmount dan', () {
      expect(InvoiceRowBuilder.build(invoiceItem(amount: 7), product()).value,
          7);
    });

    test('tannarx invoice cost dan', () {
      expect(InvoiceRowBuilder.build(invoiceItem(cost: 3300), product()).cost,
          3300);
    });

    test('barcode katalogning BIRINCHI kodidan', () {
      expect(InvoiceRowBuilder.build(invoiceItem(), product()).barcode,
          '4780000000001');
    });

    test('MXIK, paket kodi va komissiya INN katalogdan', () {
      final r = InvoiceRowBuilder.build(invoiceItem(), product());
      expect(r.mxik, '01101001001000000');
      expect(r.packageCode, 'PACK-1');
      expect(r.tin, '123456789');
    });

    test('ownerType katalogdan raqamga o\'giriladi', () {
      expect(
          InvoiceRowBuilder.build(invoiceItem(), product(ownerType: '3'))
              .ownerType,
          3);
    });

    test('ownerType yo\'q bo\'lsa 1', () {
      expect(
          InvoiceRowBuilder.build(invoiceItem(), product(ownerType: null))
              .ownerType,
          1);
    });

    test('sellerId bo\'sh qoladi (yuk xatida kassir yo\'q)', () {
      expect(InvoiceRowBuilder.build(invoiceItem(), product()).sellerId, '');
    });
  });

  group('Hisoblanadigan maydonlar', () {
    test('kilo mahsulot isKg = true', () {
      expect(InvoiceRowBuilder.build(invoiceItem(), product(unit: 'кг')).isKg,
          isTrue);
    });

    test('dona mahsulot isKg = false', () {
      expect(InvoiceRowBuilder.build(invoiceItem(), product()).isKg, isFalse);
    });

    test('vatPercent katalogdan, yo\'q bo\'lsa 12', () {
      expect(
          InvoiceRowBuilder.build(invoiceItem(), product(vatPercent: 0))
              .vatPercent,
          0);
    });

    test('yangi qator o\'chirilmagan va diskontsiz', () {
      final r = InvoiceRowBuilder.build(invoiceItem(), product());
      expect(r.isDeleted, isFalse);
      expect(r.discountPercent, 0);
      expect(r.singleDiscount, 0);
      expect(r.inBox, 0);
    });

    test('markirovkali MXIK bo\'lsa marking true', () {
      final r = InvoiceRowBuilder.build(
          invoiceItem(), product(mxik: '02202001001000000'));
      expect(r.marking, isTrue);
    });

    // 2026-09-11: `is_marking=false` — MXIK ro'yxatda bo'lsa ham oddiy qator.
    test('is_marking = false + MXIK ro\'yxatda -> marking false', () {
      final r = InvoiceRowBuilder.build(invoiceItem(),
          product(mxik: '02202001001000000', isMarking: false));
      expect(r.marking, isFalse);
      expect(r.mxik, '02202001001000000');
    });

    test('markirovkasiz MXIK bo\'lsa marking false', () {
      expect(InvoiceRowBuilder.build(invoiceItem(), product()).marking, isFalse);
    });
  });
}
