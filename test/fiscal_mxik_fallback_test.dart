// Fiskal MXIK fallback — test.
//
// HOLAT (2026-09-11): adminkada mahsulot markirovkali deb belgilanMAGAN
// (`is_marking=false` — birinchi mezon), lekin unga markirovka talab qiladigan
// MXIK (02202... va h.k.) xato kiritilgan; mahsulotda markirovka kodi yo'q.
// Bunday qator fiskal modulga asl MXIK bilan ketsa soliq rad etadi.
//
// KUTILGAN: FAQAT fiskal body'da `classCode` → statik MXIK (019...),
// `barcode` → bo'sh. Backend chek `order_pos` (`product_mxik`) va savat qatori
// o'zgarmaydi. Sotuv va vozvratda bir xil.
//
// Uch shart birga: is_marking=false + MXIK ro'yxatda + KM yo'q.
import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/marking/fiscal_mxik_fallback.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kStaticMxik = '01905012001000000';
const kSuvMxik = '02202001001000000'; // suv — markirovka ro'yxatida
const kPivoMxik = '02203001001000000'; // pivo — alkogol, ro'yxatda
const kSigaretaMxik = '02400000000000000'; // sigareta — ro'yxatda
const kSharbatMxik = '02009001001000000'; // sharbat — ro'yxatda
const kOddiyMxik = '01234567890123456'; // oddiy tovar
const kBarcode = '4780000000001';
const kMark = '0104780000000001215Ab1cD2eF3g';

/// Katalog mahsuloti IDlari (is_marking bayrog'i katalogdan o'qiladi).
const kSuvXatoId = 'suv-xato'; // is_marking=false, MXIK 02202 (adminka xatosi)
const kSuvHaqiqiyId = 'suv-haqiqiy'; // is_marking=true, MXIK 02202
const kNonId = 'non'; // is_marking=false, oddiy MXIK
const kOchirilganId = 'ochirilgan'; // katalogda YO'Q

ItemModel product(String id, {required bool isMarking, required String mxik}) {
  final m = ItemModel();
  m.id = id;
  m.name = id;
  m.isMarking = isMarking;
  m.mxikCode = mxik;
  m.barcode = [kBarcode];
  return m;
}

ReceiptModelSoldItem4 row({
  required String mxik,
  String? mark,
  String productId = kSuvXatoId,
  String name = 'Suv 1L',
  double price = 5000,
  double value = 1,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: kBarcode,
    sku: 1001,
    vatPercent: 12,
    vat: (price * 12) / 112,
    mxik: mxik,
    tin: '',
    onlyPrice: price,
    realPrice: price,
    price: price,
    cost: 0,
    vatName: 'НДС 12%',
    createdTime: DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: name,
    sellerId: kCashierId,
    soldBy: kCashierId,
    singleDiscount: 0,
    ownerType: 1,
    mark: mark,
    marking: mark != null,
    packageCode: 'PACK-1',
    packageName: 'dona',
  );
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('needsFallback (sof qoida)', () {
    test('is_marking=false + markirovka MXIK + KM yo\'q → kerak', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: null),
          isTrue);
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: ''),
          isTrue);
    });

    test('is_marking=TRUE → hech qachon kerak emas (haqiqiy markirovkali)', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: true, mxik: kSuvMxik, mark: null),
          isFalse);
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: true, mxik: kSuvMxik, mark: kMark),
          isFalse);
    });

    test('KM faqat bo\'sh joy → KM yo\'q deb hisoblanadi', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: '   '),
          isTrue);
    });

    test('is_marking=false, lekin KM skanerlangan → kerak emas', () {
      // "Avto markirovkani aniqlash" haqiqiy markirovkali tovarni ushlagan —
      // asl MXIK ketishi shart.
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kSuvMxik, mark: kMark),
          isFalse);
    });

    test('oddiy MXIK + KM yo\'q → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kOddiyMxik, mark: null),
          isFalse);
    });

    test('statik MXIK ning o\'zi ro\'yxatda emas → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: kStaticMxik, mark: null),
          isFalse);
    });

    test('bo\'sh MXIK → kerak emas', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: '', mark: null),
          isFalse);
    });

    test('butun avto-markirovka ro\'yxati qamrab olinadi', () {
      for (final m in [kSuvMxik, kPivoMxik, kSigaretaMxik, kSharbatMxik]) {
        expect(
            FiscalMxikFallback.needsFallback(
                isMarkingProduct: false, mxik: m, mark: null),
            isTrue,
            reason: m);
      }
      for (final p in ['02201', '02204', '02205', '02206', '02207', '02208']) {
        expect(
            FiscalMxikFallback.needsFallback(
                isMarkingProduct: false, mxik: '${p}000000000000', mark: null),
            isTrue,
            reason: p);
      }
    });

    test('MXIK atrofidagi bo\'sh joy e\'tiborga olinmaydi', () {
      expect(
          FiscalMxikFallback.needsFallback(
              isMarkingProduct: false, mxik: ' $kSuvMxik ', mark: null),
          isTrue);
    });
  });

  group('resolve (sof qoida)', () {
    test('almashtirish: classCode = statik, barcode bo\'sh', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isTrue);
      expect(c.classCode, kStaticMxik);
      expect(c.barcode, '');
    });

    test('is_marking=true → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: true,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('KM bor → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: kMark,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('oddiy tovar → hech narsa o\'zgarmaydi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kOddiyMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: kStaticMxik,
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kOddiyMxik);
      expect(c.barcode, kBarcode);
    });

    test('statik MXIK bo\'sh (Pref yozilmagan) → xavfsiz: asl MXIK qoladi',
        () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: '  ',
      );
      expect(c.substituted, isFalse);
      expect(c.classCode, kSuvMxik);
      expect(c.barcode, kBarcode);
    });

    test('statik MXIK atrofidagi bo\'sh joy tozalanadi', () {
      final c = FiscalMxikFallback.resolve(
        isMarkingProduct: false,
        mxik: kSuvMxik,
        mark: null,
        barcode: kBarcode,
        staticMxik: ' $kStaticMxik ',
      );
      expect(c.classCode, kStaticMxik);
    });
  });

  group('saleOnOFD (fiskal body)', () {
    setUpAll(() async {
      await setUpPosTestEnv('fiscal_mxik_fallback_test',
          withEmployee: false);
      await Pref.setString(PrefKeys.mxikCode, kStaticMxik);
    });
    tearDownAll(tearDownPosTestEnv);

    setUp(() {
      // Katalog: `is_marking` shu yerdan o'qiladi.
      ItemsSingleton.products = [
        product(kSuvXatoId, isMarking: false, mxik: kSuvMxik),
        product(kSuvHaqiqiyId, isMarking: true, mxik: kSuvMxik),
        product(kNonId, isMarking: false, mxik: kOddiyMxik),
      ];
    });
    tearDown(() => ItemsSingleton.products = []);

    test(
        'sotuv: is_marking=false + KM siz suv → statik SPIC, bo\'sh Barcode; qolganlar tegilmaydi',
        () {
      final rows = [
        row(mxik: kSuvMxik, productId: kSuvXatoId),
        row(mxik: kSuvMxik, mark: kMark, productId: kSuvHaqiqiyId),
        row(mxik: kOddiyMxik, productId: kNonId, name: 'Non'),
      ];
      final items = ofdItems(receiptWith(rows));

      expect(items.length, 3);

      final xato = items.firstWhere((e) => e['id'] == kSuvXatoId);
      expect(xato['classCode'], kStaticMxik);
      expect(xato['barcode'], '');
      expect(xato['label'], '');

      final haqiqiy = items.firstWhere((e) => e['id'] == kSuvHaqiqiyId);
      expect(haqiqiy['classCode'], kSuvMxik);
      expect(haqiqiy['barcode'], kBarcode);
      expect(haqiqiy['label'], kMark);

      final non = items.firstWhere((e) => e['id'] == kNonId);
      expect(non['classCode'], kOddiyMxik);
      expect(non['barcode'], kBarcode);
      expect(non['label'], '');
    });

    test('is_marking=true + KM yo\'q (masalan invoice qatori) → asl MXIK qoladi',
        () {
      final items =
          ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kSuvHaqiqiyId)]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['barcode'], kBarcode);
    });

    test('is_marking=false, lekin KM skanerlangan (avto-aniqlash) → asl MXIK',
        () {
      final items = ofdItems(
          receiptWith([row(mxik: kSuvMxik, mark: kMark, productId: kSuvXatoId)]));
      expect(items.single['classCode'], kSuvMxik);
      expect(items.single['barcode'], kBarcode);
      expect(items.single['label'], kMark);
    });

    test('mahsulot katalogda yo\'q (o\'chirilgan) → MXIK + KM bo\'yicha almashtiriladi',
        () {
      final items =
          ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kOchirilganId)]));
      expect(items.single['classCode'], kStaticMxik);
      expect(items.single['barcode'], '');
    });

    test('alkogol MXIK, is_marking=false, KM siz → statik SPIC', () {
      ItemsSingleton.products = [
        product('pivo', isMarking: false, mxik: kPivoMxik),
      ];
      final items = ofdItems(
          receiptWith([row(mxik: kPivoMxik, productId: 'pivo', name: 'Pivo')]));
      expect(items.single['classCode'], kStaticMxik);
      expect(items.single['barcode'], '');
    });

    test('vozvrat: sotuv bilan bir xil almashtiriladi', () {
      final rows = [
        row(mxik: kSuvMxik, productId: kSuvXatoId),
        row(mxik: kSuvMxik, mark: kMark, productId: kSuvHaqiqiyId),
      ];
      final body =
          ReceiptSingleton4.saleOnOFD(receiptWith(rows, isRefund: true));
      expect(body['method'], 'refund');
      final items =
          (body['params']['items'] as List).cast<Map<String, dynamic>>();

      final xato = items.firstWhere((e) => e['id'] == kSuvXatoId);
      expect(xato['classCode'], kStaticMxik);
      expect(xato['barcode'], '');

      final haqiqiy = items.firstWhere((e) => e['id'] == kSuvHaqiqiyId);
      expect(haqiqiy['classCode'], kSuvMxik);
      expect(haqiqiy['barcode'], kBarcode);
    });

    test(
        'faqat fiskal: chek qatori va order_pos JSON (product_mxik/product_barcode) o\'zgarmaydi',
        () {
      final r = receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId)]);
      ofdItems(r);

      final item = r.soldItemList.first;
      expect(item.mxik, kSuvMxik);
      expect(item.barcode, kBarcode);
      expect(item.toJson()['product_mxik'], kSuvMxik);
      expect(item.toJson()['product_barcode'], kBarcode);
    });

    test('narx/summa maydonlariga ta\'sir qilmaydi', () {
      final items = ofdItems(
          receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId, price: 5000)]));
      expect(items.single['price'], 500000); // tiyinda
      expect(items.single['amount'], 1000);
    });

    test('Pref statik MXIK bo\'sh → asl MXIK ketadi (xavfsiz chetki holat)',
        () async {
      await Pref.setString(PrefKeys.mxikCode, '');
      try {
        final items =
            ofdItems(receiptWith([row(mxik: kSuvMxik, productId: kSuvXatoId)]));
        expect(items.single['classCode'], kSuvMxik);
        expect(items.single['barcode'], kBarcode);
      } finally {
        await Pref.setString(PrefKeys.mxikCode, kStaticMxik);
      }
    });
  });
}
