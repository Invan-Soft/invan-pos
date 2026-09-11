// Fiskal MXIK fallback + `is_marking=false` savat qoidasi — CHETKI HOLATLAR.
//
// Asosiy holatlar test/fiscal_mxik_fallback_test.dart da. Bu fayl o'zgarish
// tegishi mumkin bo'lgan, lekin foydalanuvchi to'g'ridan-to'g'ri so'ramagan
// yo'llarni qamraydi: blok (box) qatori, invoice qatori, to'g'ridan-to'g'ri
// DataMatrix skan, `is_marking=null`, katalog bo'sh / o'zgargan / buzilgan,
// vozvrat mosligi, alkogol naqd cheklovi, katta katalogda tezlik.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/barcode/scanned_product_lookup.dart';
import 'package:invan2/changes/domain/cart/box_row_builder.dart';
import 'package:invan2/changes/domain/cart/cash_restriction_rules.dart';
import 'package:invan2/changes/domain/cart/invoice_row_builder.dart';
import 'package:invan2/changes/domain/cart/sold_item_builder.dart';
import 'package:invan2/changes/domain/marking/mark_cleaner.dart';
import 'package:invan2/changes/domain/marking/mxik_rules.dart';
import 'package:invan2/changes/models/invoice_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStaticMxik = '01905012001000000';
const kSuvMxik = '02202001001000000';
const kPivoMxik = '02203001001000000';
const kOddiyMxik = '01234567890123456';
const kBarcode = '4780000000001';
const kGtin14 = '04780000000001';
const kDataMatrix = '01${kGtin14}21Ab1cD2eF3g93XyZ';

ItemModel product(
  String id, {
  bool? isMarking = false,
  String mxik = kSuvMxik,
  String name = 'Suv 1L',
}) {
  final m = ItemModel();
  m.id = id;
  m.name = name;
  m.sku = '1001';
  m.isMarking = isMarking;
  m.mxikCode = mxik;
  m.packageCode = 'PACK-1';
  m.packageName = 'dona';
  m.packageType = 'BOTTLE';
  m.barcode = [kBarcode];
  m.vat = Vat(percentage: 12, name: 'NDS 12%');
  m.measurementUnit = MeasurementUnit(shortName: 'dona');
  m.shopPrices = ShopPrices(
    shID: ShID(
      shopId: 'shop-1',
      supplyPrice: 3000,
      shopPriceTiers: [ShopPriceTiers(minQuantity: 1, retailPrice: 5000)],
    ),
  );
  return m;
}

ReceiptModel4 receiptWith(List<ReceiptModelSoldItem4> rows,
    {bool isRefund = false}) {
  double total = 0;
  for (final r in rows) {
    total += r.price * r.value;
  }
  final r = ReceiptModel4(
    createdDate: '2026-09-11 10:00:00',
    orderId: 'order-1',
    cashboxId: 'cashbox-1',
    externalId: 'ext-1',
    orderType: isRefund ? 'refund' : 'sale',
    shopId: 'shop-1',
    userId: kUserId,
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: kCashierId,
    cashierName: kCashierName,
    date: DateTime.now().millisecondsSinceEpoch,
    isRefund: isRefund,
    totalPrice: total,
    uploaded: false,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: isRefund ? 'ext-0' : '',
    posName: 'Test POS',
    isDonate: false,
  );
  r.soldItemList.addAll(rows);
  r.payment.add(
    ReceiptModelPaymentType4(name: 'CASH', payId: 'cash', value: total),
  );
  return r;
}

List<Map<String, dynamic>> ofdItems(ReceiptModel4 r) {
  final body = ReceiptSingleton4.saleOnOFD(r);
  return (body['params']['items'] as List).cast<Map<String, dynamic>>();
}

InvoiceItem invoiceItem() => InvoiceItem(
      id: 'ii-1',
      productId: 'suv',
      productName: 'Suv 1L',
      barcode: kBarcode,
      sku: '1001',
      expectedAmount: 3,
      cost: 3000,
      totalAmount: 0,
      invoiceId: 'inv-1',
      productStock: 0,
      prices: const [],
      realPrices: const [],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('fiscal_mxik_scenarios', withEmployee: false);
    await Pref.setString(PrefKeys.mxikCode, kStaticMxik);
    await Pref.setBool(PrefKeys.markCheckWithOfd, true);
    await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
  });
  tearDownAll(tearDownPosTestEnv);
  tearDown(() {
    ItemsSingleton.products = [];
    ItemsSingleton.barcodeProducts = [];
  });

  /// Skaner qidiruvi (`getProductByBarcode`) alohida `barcodeProducts`
  /// ro'yxatidan o'qiydi — ikkalasi ham to'ldiriladi.
  void seedCatalog(List<ItemModel> items) {
    ItemsSingleton.products = items;
    ItemsSingleton.barcodeProducts = items;
  }

  group('1. Blok (box) qatori', () {
    test('is_marking=false + MXIK 022: blok KM saqlanmaydi, fiskalga statik',
        () {
      final p = product('suv', isMarking: false);
      ItemsSingleton.products = [p];

      final row = BoxRowBuilder.build(p,
          boxPrice: 60000,
          boxValue: 12,
          boxQuantity: 1,
          rawMark: 'BOX-KM-1',
          sellerId: kCashierId);
      expect(row.mark, isNull);
      expect(row.marking, isFalse);
      expect(row.productType, '');

      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], kStaticMxik);
      expect(items.single['barcode'], '');
      expect(items.single['name'], 'Suv 1L',
          reason: '//blok qo\'shimchasi kesiladi');
    });

    test('is_marking=true blok: KM saqlanadi, fiskalga asl MXIK', () {
      final p = product('suv', isMarking: true);
      ItemsSingleton.products = [p];

      final row = BoxRowBuilder.build(p,
          boxPrice: 60000,
          boxValue: 12,
          boxQuantity: 1,
          rawMark: 'BOX-KM-1',
          sellerId: kCashierId);
      expect(row.mark, 'BOX-KM-1');

      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['label'], 'BOX-KM-1');
    });
  });

  group('2. Invoice (yuk xati) qatori', () {
    test('is_marking=false + MXIK 022: oddiy qator, fiskalga statik', () {
      final p = product('suv', isMarking: false);
      ItemsSingleton.products = [p];

      final row = InvoiceRowBuilder.build(invoiceItem(), p);
      expect(row.marking, isFalse);

      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], kStaticMxik);
      expect(items.single['barcode'], '');
      expect(items.single['amount'], 3000, reason: '3 dona x 1000');
    });

    test(
        'is_marking=true + KM yo\'q (invoice KM bermaydi): asl MXIK, label bo\'sh '
        '- ESKI xatti-harakat, fallback aralashmaydi', () {
      final p = product('suv', isMarking: true);
      ItemsSingleton.products = [p];

      final row = InvoiceRowBuilder.build(invoiceItem(), p);
      expect(row.marking, isTrue);
      expect(row.mark, isNull);

      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['label'], '');
    });
  });

  group('3. To\'g\'ridan-to\'g\'ri DataMatrix skan (ScannedProductLookup)', () {
    test('is_marking=false mahsulotga DataMatrix skanerlansa KM biriktirilMAYDI',
        () {
      seedCatalog([product('suv', isMarking: false)]);

      final match = ScannedProductLookup.find(
        kDataMatrix,
        isMarkable: MxikRules.isProductMarkable,
        cleanMark: MarkCleaner.scanTime,
      );
      expect(match.item, isNotNull, reason: 'GTIN bo\'yicha topiladi');
      expect(match.item!.mark, isNull);
    });

    test('is_marking=true mahsulotga DataMatrix: KM biriktiriladi (o\'zgarmagan)',
        () {
      seedCatalog([product('suv', isMarking: true)]);

      final match = ScannedProductLookup.find(
        kDataMatrix,
        isMarkable: MxikRules.isProductMarkable,
        cleanMark: MarkCleaner.scanTime,
      );
      expect(match.item!.mark, isNotNull);
      expect(match.item!.mark, isNot(contains('93')),
          reason: 'kripto qism kesiladi');
    });

    test(
        'is_marking=null mahsulotga DataMatrix: KM biriktiriladi (eski avto-aniqlash)',
        () {
      seedCatalog([product('suv', isMarking: null)]);

      final match = ScannedProductLookup.find(
        kDataMatrix,
        isMarkable: MxikRules.isProductMarkable,
        cleanMark: MarkCleaner.scanTime,
      );
      expect(match.item!.mark, isNotNull);
    });
  });

  group('4. is_marking = null (bayroq kelmagan)', () {
    test(
        'avto-aniqlash YOQIQ: markirovkali (eski), fiskalga asl MXIK (KM bilan)',
        () {
      final p = product('suv', isMarking: null);
      ItemsSingleton.products = [p];
      expect(MxikRules.isProductMarkable(p), isTrue);

      // Kassir KM skanerlagan (dialog orqali) - qator KM bilan
      final row = SoldItemBuilder.build(p, 5000, 1, false)..mark = 'KM-1';
      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['label'], 'KM-1');
    });

    test('avto-aniqlash O\'CHIQ: oddiy qator, fiskalga STATIK (null != true)',
        () async {
      await Pref.setBool(PrefKeys.sellProductsWithMarking, false);
      try {
        final p = product('suv', isMarking: null);
        ItemsSingleton.products = [p];
        expect(MxikRules.isProductMarkable(p), isFalse);

        final row = SoldItemBuilder.build(p, 5000, 1, false);
        expect(row.mark, isNull);
        final items = ofdItems(receiptWith([row]));
        expect(items.single['classCode'], kStaticMxik,
            reason: 'is_marking null -> true emas -> fallback qo\'llanadi');
      } finally {
        await Pref.setBool(PrefKeys.sellProductsWithMarking, true);
      }
    });
  });

  group('5. Katalog holati (saleOnOFD qidiruvi)', () {
    test('katalog BO\'SH: xato yo\'q, MXIK+KM bo\'yicha almashtiriladi', () {
      ItemsSingleton.products = [];
      final row = SoldItemBuilder.build(product('suv'), 5000, 1, false);
      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], kStaticMxik);
    });

    test('katalogda id=null mahsulot bor: to\'lov yo\'li YIQILMAYDI', () {
      final broken = product('x')..id = null;
      ItemsSingleton.products = [broken, product('suv')];
      final row = SoldItemBuilder.build(product('suv'), 5000, 1, false);

      late List<Map<String, dynamic>> items;
      expect(() => items = ofdItems(receiptWith([row])), returnsNormally);
      // Qidiruv xato bersa `false` - MXIK+KM bo'yicha almashtiriladi
      expect(items.single['classCode'], kStaticMxik);
    });

    test(
        'oddiy MXIK li qatorda katalog qidiruvi umuman chaqirilmaydi '
        '(buzilgan katalog ham xalaqit bermaydi): asl MXIK', () {
      final broken = product('x')..id = null;
      ItemsSingleton.products = [broken];
      final row = SoldItemBuilder.build(
          product('non', mxik: kOddiyMxik, name: 'Non'), 5000, 1, false);
      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], kOddiyMxik);
      expect(items.single['barcode'], kBarcode);
    });

    test('productId katta-kichik harf farqi: qidiruv topadi', () {
      ItemsSingleton.products = [product('SUV-abc', isMarking: true)];
      final row = SoldItemBuilder.build(
          product('suv-ABC', isMarking: true), 5000, 1, false);
      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], kSuvMxik,
          reason: 'katalogda is_marking=true topildi -> almashtirilmaydi');
    });
  });

  group('6. Vozvrat mosligi (katalog sotuvdan keyin o\'zgargan)', () {
    test(
        'sotuvda is_marking=false (statik ketdi), adminka keyin true qildi -> '
        'vozvrat ASL MXIK bilan ketadi (HUJJATLASHTIRILGAN chetki holat)', () {
      // Sotuv
      ItemsSingleton.products = [product('suv', isMarking: false)];
      final row = SoldItemBuilder.build(product('suv'), 5000, 1, false);
      expect(ofdItems(receiptWith([row])).single['classCode'], kStaticMxik);

      // Adminka bayroqni tuzatdi, katalog yangilandi
      ItemsSingleton.products = [product('suv', isMarking: true)];
      final refund = ofdItems(receiptWith([row], isRefund: true));
      expect(refund.single['classCode'], kSuvMxik);
    });

    test('sotuvda ham, vozvratda ham is_marking=false -> ikkalasi statik', () {
      ItemsSingleton.products = [product('suv', isMarking: false)];
      final row = SoldItemBuilder.build(product('suv'), 5000, 1, false);
      expect(ofdItems(receiptWith([row])).single['classCode'], kStaticMxik);
      expect(ofdItems(receiptWith([row], isRefund: true)).single['classCode'],
          kStaticMxik);
    });
  });

  group('7. Alkogol MXIK + is_marking=false', () {
    test(
        'fiskalga statik ketadi, LEKIN naqd cheklovi hamon MXIK bo\'yicha ishlaydi',
        () {
      final p =
          product('pivo', isMarking: false, mxik: kPivoMxik, name: 'Pivo');
      ItemsSingleton.products = [p];
      expect(MxikRules.isProductMarkable(p), isFalse,
          reason: 'markirovka dialogi chiqmaydi');

      final row = SoldItemBuilder.build(p, 5000, 1, false);
      expect(ofdItems(receiptWith([row])).single['classCode'], kStaticMxik);

      // Naqd cheklovi `row.mxik` ga qaraydi, `marking` ga emas - o'zgarmagan
      expect(
        CashRestrictionRules.cashHiddenByMarking([row],
            ofdOn: true, markingSaleOn: true),
        isTrue,
        reason: 'naqd yopiladi - is_marking=false bo\'lsa ham (eski qoida)',
      );
    });
  });

  group('8. Aralash savat va miqdor', () {
    test(
        'bir mahsulot 3 dona oddiy qator: amount 3000, statik SPIC bitta item',
        () {
      ItemsSingleton.products = [product('suv')];
      final row = SoldItemBuilder.build(product('suv'), 5000, 3, false);
      final items = ofdItems(receiptWith([row]));
      expect(items.length, 1);
      expect(items.single['amount'], 3000);
      expect(items.single['price'], 1500000);
      expect(items.single['classCode'], kStaticMxik);
    });

    test('o\'chirilgan (isDeleted) qator ham saleOnOFD ga kelsa xato bermaydi',
        () {
      ItemsSingleton.products = [product('suv')];
      final row = SoldItemBuilder.build(product('suv'), 5000, 1, false)
        ..isDeleted = true;
      expect(() => ofdItems(receiptWith([row])), returnsNormally);
    });

    test('mxik bo\'sh qator: fallback aralashmaydi (SPIC bo\'sh - eski)', () {
      ItemsSingleton.products = [product('suv')];
      final row =
          SoldItemBuilder.build(product('suv', mxik: ''), 5000, 1, false);
      final items = ofdItems(receiptWith([row]));
      expect(items.single['classCode'], '');
      expect(items.single['barcode'], kBarcode);
    });
  });

  group('9. Tezlik', () {
    test('20 000 mahsulotli katalog, 60 qatorli chek - 1 soniyadan tez', () {
      ItemsSingleton.products = List.generate(
          20000, (i) => product('p-$i', isMarking: i.isEven, mxik: kSuvMxik));
      final rows = List.generate(
          60,
          (i) => SoldItemBuilder.build(
              product('p-${19999 - i}', mxik: kSuvMxik), 5000, 1, false));

      final sw = Stopwatch()..start();
      final items = ofdItems(receiptWith(rows));
      sw.stop();

      // ignore: avoid_print
      print('saleOnOFD 20k katalog / 60 qator: ${sw.elapsedMilliseconds} ms');
      expect(items.length, 60);
      // Toq indekslar is_marking=false -> statik; juftlar true -> asl
      expect(items.where((e) => e['classCode'] == kStaticMxik).length, 30);
      expect(sw.elapsedMilliseconds, lessThan(1000),
          reason: '${sw.elapsedMilliseconds} ms');
    });
  });
}
