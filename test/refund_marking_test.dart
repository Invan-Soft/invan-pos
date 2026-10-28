// Vozvratda markirovka (dona + blok KM): KM serverdan olinadi, kassir qaytayotgan
// shisha/blokni SKANERLAYDI, fiskalga sotuvdagidek har KM alohida pozitsiya.
//
// Nega kerak: server `api/v1/order` javobida `items[].marking_names` va
// `box_marking_names` bor (DEV, chek DT1 / #119, 2026-10-27), lekin ilova
// ularni o'qimasdi — vozvrat cheki `Label ""` bilan ketardi.
//
// Qoida: chap ro'yxatda mahsulot bitta qator (KM havzasi bilan). Qatorni bosib
// KM skanerlanadi; shu chekda sotilgan KM bo'lsa aynan o'sha 1 dona / 1 blok
// o'ngga o'tadi, bo'lmasa "bu mahsulot shu chekda sotilmagan".
//
// Zanjir (ilovadagidek): server JSON → `ReUpdateBloc.refundableItems` →
// `ChecksSingleton.globalToLocall` → vozvrat sahifasi (`refundReceiptOf`) →
// `ReturnPageProviderr.scanMark` → `ReceiptSingleton4.saleOnOFD` (modulga JSON).
//
// "Shu kassa" guruhi ObjectBox kerak (`libobjectbox.dylib` / `.so` / `.dll`
// loyiha ildizida yoki tizimda), topilmasa SKIP. Mac'da:
//   cp build/macos/Build/Products/Debug/invan2.app/Contents/Frameworks/ObjectBox.framework/Versions/A/ObjectBox libobjectbox.dylib
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/barcode/keyboard_layout.dart';
import 'package:invan2/changes/domain/receipt/refund_mark_split.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/models/receipts_get_model.dart';
import 'package:invan2/changes/providers/return_page_provider.dart';
import 'package:invan2/changes/services/receipt_api_4.dart';
import 'package:invan2/features/checks/features/check_view/bloc/re_update_bloc.dart';
import 'package:invan2/features/checks/return_page/return_page.dart';
import 'package:invan2/features/get_products/singletons/checks_singleton.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/fiscal_service/model/fiscal_receipt_model.dart';
import 'package:invan2/fiscal_service/model/location/location.dart';
import 'package:invan2/fiscal_service/model/receipt_data_model.dart';
import 'package:invan2/fiscal_service/model/request_receipt_model.dart';
import 'package:invan2/objectbox.g.dart' hide Box;
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

// DT1 (#119) dagi haqiqiy KM'lar — emulyatordagi sotuv `Label`lari bilan bir xil.
const kKm1 = '0104780101733767217VCy-1g)yILZf';
const kKm2 = '0104780101733767217zER/!Vzl;.>"';
const kBox1 = '010478006900052921Bx00000001';
const kBox2 = '010478006900052921Bx00000002';
const kBoxUnit = '010478006900051221AbC123xyZ9876';
// DT7 (#125) dagi haqiqiy blok KM'lari: sotuvda kripto qism bilan saqlanadi
// (skaner GS ni `029` qilib yuboradi, blok yo'li `scanTime` siz).
const kRealBox1 = '0114780101733764217DtZ53Oi"RYhH02993zdxZ';
const kRealBox2 = '0114780101733764217SAUN=DLsWfiV02993SgJ5';

const kMxik = '02201002001053001';
const kProductId = 'b5f52718-3a21-42f0-a397-5cf9e73e9168';

Store? _tryOpenStore() {
  try {
    final dir = Directory.systemTemp.createTempSync('refund_marking_obx');
    return Store(getObjectBoxModel(), directory: dir.path);
  } catch (_) {
    return null;
  }
}

/// DT1 itemi (server javobidan, keraksiz maydonlarsiz).
Map<String, dynamic> serverItem({
  num value = 2,
  num refundAmount = 0,
  num price = 2900,
  List<String>? markingNames = const [kKm1, kKm2],
  List<String>? boxMarkingNames = const [],
  int? saleType = 1,
  int? boxValue = 0,
  int? boxQuantity = 0,
  List<String>? refundedMarkingNames,
  List<String>? refundedBoxMarkingNames,
  String id = 'aa2a3531-fb85-43ac-aa83-b59bf6c2591b',
  String productId = kProductId,
}) =>
    {
      'id': id,
      'product_name': 'Montella Daily 0,33 л.',
      'product_id': productId,
      'value': value,
      'refund_amount': refundAmount,
      'price': price,
      'new_price': price,
      'total_price': price * value,
      'barcode': '4780101733767',
      'sku': '34875',
      'mxik_code': kMxik,
      'vat_name': 'Standart',
      'vat_percentage': 12,
      'discount': {'price': 0, 'value': 0, 'type': ''},
      'package_code': '1165863',
      'package_name': 'дона',
      'is_marking': true,
      'single_order_discount': 0,
      'marking_name': '',
      'product_type': '5',
      'product_package': 'KIZ',
      if (markingNames != null) 'marking_names': markingNames,
      if (boxMarkingNames != null) 'box_marking_names': boxMarkingNames,
      if (saleType != null) 'sale_type': saleType,
      if (boxValue != null) 'box_value': boxValue,
      if (boxQuantity != null) 'box_quantity': boxQuantity,
      if (refundedMarkingNames != null)
        'refunded_marking_names': refundedMarkingNames,
      if (refundedBoxMarkingNames != null)
        'refunded_box_marking_names': refundedBoxMarkingNames,
    };

GlobalReceipt serverOrder(Map<String, dynamic> item,
        {String externalId = 'DT1',
        num totalPrice = 5800,
        List<Map<String, dynamic>> more = const []}) =>
    GlobalReceipt.fromJson({
      'id': '01a17cce-a392-7ff8-8b68-3db62b5ad592',
      'type': 'sale',
      'external_id': externalId,
      'status': {'name': 'paid'},
      'total_price': totalPrice,
      'create_time': '2026-10-27T10:01:19Z',
      'terminal_id': 'VG300750000021',
      'fiscal_sign': '696533213019',
      'receipt_seq': 119,
      'date_time': '20261027150119',
      'pays': [],
      'items': [item, ...more],
    });

/// Vozvrat sahifasi ochilganda (ReUpdateBloc → globalToLocall → _copyWith).
RefundPageData openReturnPage(GlobalReceipt order) {
  final refunded = ReUpdateBloc.serverRefundedMarks(order);
  order.items = ReUpdateBloc.refundableItems(order);
  return refundReceiptOf(ChecksSingleton.globalToLocall(order),
      serverRefundedMarks: refunded);
}

ReturnPageProviderr providerOf(RefundPageData page) => ReturnPageProviderr(
      receiptModel4: page.receipt,
      refundedMarks: page.refundedMarks,
    );

/// Skaner chiqishi: KM + GS (0x1D) + kripto qism (93...) — sotuvdagidek tozalanadi.
String scanned(String km) => '$km\x1D93dGVz';

/// O'ng ro'yxatdan ReturnBloc kabi vozvrat chekini yig'adi.
ReceiptModel4 refundOf(RefundPageData page, ReturnPageProviderr p) {
  final rows = List<ReceiptModelSoldItem4>.from(p.getRightList);
  final r = page.receipt;
  r.soldItemList
    ..clear()
    ..addAll(rows);
  r.payment
    ..clear()
    ..add(ReceiptModelPaymentType4(
        name: 'CASH',
        payId: 'cash-id',
        value: rows.fold(0.0, (s, e) => s + e.price * e.value)));
  return r;
}

/// Kod rus (Windows ЙЦУКЕН) tartibi yoqiq kassada skanerlansa nima keladi.
String typedOnRu(String en) {
  const map = {
    'q': 'й', 'w': 'ц', 'e': 'у', 'r': 'к', 't': 'е', 'y': 'н', 'u': 'г',
    'i': 'ш', 'o': 'щ', 'p': 'з', '[': 'х', ']': 'ъ', 'a': 'ф', 's': 'ы',
    'd': 'в', 'f': 'а', 'g': 'п', 'h': 'р', 'j': 'о', 'k': 'л', 'l': 'д',
    ';': 'ж', "'": 'э', 'z': 'я', 'x': 'ч', 'c': 'с', 'v': 'м', 'b': 'и',
    'n': 'т', 'm': 'ь', ',': 'б', '.': 'ю', '`': 'ё',
    'Q': 'Й', 'W': 'Ц', 'E': 'У', 'R': 'К', 'T': 'Е', 'Y': 'Н', 'U': 'Г',
    'I': 'Ш', 'O': 'Щ', 'P': 'З', '{': 'Х', '}': 'Ъ', 'A': 'Ф', 'S': 'Ы',
    'D': 'В', 'F': 'А', 'G': 'П', 'H': 'Р', 'J': 'О', 'K': 'Л', 'L': 'Д',
    ':': 'Ж', '"': 'Э', 'Z': 'Я', 'X': 'Ч', 'C': 'С', 'V': 'М', 'B': 'И',
    'N': 'Т', 'M': 'Ь', '<': 'Б', '>': 'Ю', '~': 'Ё',
    '@': '"', '#': '№', r'$': ';', '^': ':', '&': '?', '/': '.', '?': ',',
    '|': '/',
  };
  return en.split('').map((c) => map[c] ?? c).join();
}

/// O'zgarishdan oldingi sotuv funksiyasi (MyBarcodeListenerState.fixKeyboardLayout)
/// — KeyboardLayout.ruLettersToEn u bilan bir xil bo'lishi kerak.
String legacyFixKeyboardLayout(String input) {
  if (input.isEmpty) return input;
  const Map<String, String> ruToEn = {
    'й': 'q', 'ц': 'w', 'у': 'e', 'к': 'r', 'е': 't', 'н': 'y', 'г': 'u',
    'ш': 'i', 'щ': 'o', 'з': 'p', 'х': '[', 'ъ': ']',
    'ф': 'a', 'ы': 's', 'в': 'd', 'а': 'f', 'п': 'g', 'р': 'h',
    'о': 'j', 'л': 'k', 'д': 'l', 'ж': ';', 'э': "'",
    'я': 'z', 'ч': 'x', 'с': 'c', 'м': 'v', 'и': 'b', 'т': 'n',
    'ь': 'm', 'б': ',', 'ю': '.',
    'Й': 'Q', 'Ц': 'W', 'У': 'E', 'К': 'R', 'Е': 'T', 'Н': 'Y', 'Г': 'U',
    'Ш': 'I', 'Щ': 'O', 'З': 'P', 'Х': '{', 'Ъ': '}',
    'Ф': 'A', 'Ы': 'S', 'В': 'D', 'А': 'F', 'П': 'G', 'Р': 'H',
    'О': 'J', 'Л': 'K', 'Д': 'L', 'Ж': ':', 'Э': '"',
    'Я': 'Z', 'Ч': 'X', 'С': 'C', 'М': 'V', 'И': 'B', 'Т': 'N',
    'Ь': 'M', 'Б': '<', 'Ю': '>',
    'ё': '`', 'Ё': '~',
  };
  String result = input;
  ruToEn.forEach((rus, eng) {
    result = result.replaceAll(rus, eng);
  });
  return result;
}

ReceiptModelSoldItem4 leftRow(ReturnPageProviderr p, {bool block = false}) =>
    p.getLeftList.firstWhere((e) => (e.saleType == 2) == block);

/// Modulga ketadigan JSON — `LocalService.saleWithOutIncom` zanjiri tarmoqsiz.
Map<String, dynamic> wireJson(ReceiptModel4 receipt) {
  final ofdBody = ReceiptSingleton4.saleOnOFD(receipt);
  final model = RequestSaleModel.fromJson(ofdBody);
  final fiscal = FiscalReceiptModel.fromRequest(
    model,
    ReceiptDataModel(
      factoryID: 'UZ000000000MOCK',
      terminalID: 'VG300750000021',
      location: Location(latitude: 41.311081, longitude: 69.240562),
    ),
    DateTime(2026, 10, 27, 15, 30),
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

ReceiptModelSoldItem4 localRow({
  double value = 2,
  double price = 2900,
  String? mark,
  String? boxMark,
  int saleType = 1,
  int boxValue = 0,
  int boxQuantity = 0,
}) =>
    ReceiptModelSoldItem4(
      inBox: 0,
      barcode: '4780101733767',
      sku: 34875,
      vatPercent: 12,
      vat: price * 12 / 112,
      mxik: kMxik,
      tin: '',
      onlyPrice: price,
      realPrice: price,
      price: price,
      cost: 0,
      vatName: 'Standart',
      createdTime: 0,
      value: value,
      productId: kProductId,
      productName: 'Montella Daily 0,33 л.',
      sellerId: '',
      soldBy: '',
      singleDiscount: 0,
      ownerType: 1,
      mark: mark,
      boxMark: boxMark,
      marking: mark != null,
      saleType: saleType,
      boxValue: boxValue,
      boxQuantity: boxQuantity,
    );

ReceiptModel4 localReceipt({
  required String externalId,
  required bool isRefund,
  required List<ReceiptModelSoldItem4> items,
  bool uploaded = true,
}) {
  final r = ReceiptModel4(
    createdDate: '2026-10-27 15:01:19',
    orderId: 'order-$externalId-$isRefund',
    cashboxId: 'cashbox-1',
    externalId: isRefund ? 'R-$externalId' : externalId,
    orderType: 'sale',
    shopId: 'shop-1',
    userId: 'user-1',
    discountVat: 0,
    discountID: '',
    newid: '',
    cashierId: 'kassir-001',
    cashierName: 'Test Kassir',
    date: 0,
    isRefund: isRefund,
    totalPrice: 0,
    uploaded: uploaded,
    rejected: false,
    clientName: '',
    clientPhone: '',
    clientId: '',
    supplierId: '',
    cashback: 0,
    sdacha: 0,
    returnForCheck: isRefund ? externalId : '',
    posName: 'Test POS',
    isDonate: false,
  );
  r.soldItemList.addAll(items);
  return r;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('refund_marking', withEmployee: false);
    await Pref.setString(PrefKeys.cashId, 'cash-id');
    await Pref.setString(PrefKeys.mxikCode, '01905012001000000');
  });
  tearDownAll(tearDownPosTestEnv);

  setUp(() {
    ItemsSingleton.products = [
      ItemModel()
        ..id = kProductId
        ..name = 'Montella Daily 0,33 л.'
        ..mxikCode = kMxik
        ..barcode = ['4780101733767']
        ..packageCode = '1165863'
        ..ownerType = '1'
        ..isMarking = true,
    ];
  });
  tearDown(() => ItemsSingleton.products = []);

  group('ItemsGTR — server javobidan KM va blok', () {
    test('DT1: marking_names o\'qiladi (ilgari tashlab yuborilardi)', () {
      final it = ItemsGTR.fromJson(serverItem());
      expect(it.markingNames, [kKm1, kKm2]);
      expect(it.boxMarkingNames, isEmpty);
      expect(it.isBox, isFalse);
      expect(it.value, 2);
    });

    test('blok: token (2 blok + 1 dona = 3) → 13 dona, refund_amount bilan bir birlik',
        () {
      final it = ItemsGTR.fromJson(serverItem(
        value: 3,
        saleType: 2,
        boxValue: 6,
        boxQuantity: 2,
        boxMarkingNames: [kBox1, kBox2],
        markingNames: [kBoxUnit],
      ));
      expect(it.isBox, isTrue);
      expect(it.value, 13);
      expect(it.boxMarkingNames, [kBox1, kBox2]);
      expect(it.markingNames, [kBoxUnit]);
    });

    test('eski server (maydonlar yo\'q) — bo\'sh ro\'yxat, oddiy item', () {
      final it = ItemsGTR.fromJson(serverItem(
        markingNames: null,
        boxMarkingNames: null,
        saleType: null,
        boxValue: null,
        boxQuantity: null,
      ));
      expect(it.markingNames, isEmpty);
      expect(it.boxMarkingNames, isEmpty);
      expect(it.saleType, 1);
      expect(it.value, 2);
    });

    test('sale_type 2, lekin box_quantity 0 — blok emas, value o\'zgarmaydi', () {
      final it = ItemsGTR.fromJson(
          serverItem(value: 4, saleType: 2, boxValue: 6, boxQuantity: 0));
      expect(it.isBox, isFalse);
      expect(it.value, 4);
    });

    test('globalToLocall: mark/boxMark lokal konsolidatsiya shaklida (\\n)', () {
      final r = ChecksSingleton.globalToLocall(serverOrder(serverItem(
        value: 3,
        saleType: 2,
        boxValue: 6,
        boxQuantity: 2,
        boxMarkingNames: [kBox1, kBox2],
        markingNames: [kBoxUnit],
        price: 4500,
      ), totalPrice: 58500));
      final e = r.soldItemList.single;
      expect(e.mark, kBoxUnit);
      expect(e.boxMark, '$kBox1\n$kBox2');
      expect(e.marking, isTrue);
      expect(e.saleType, 2);
      expect(e.boxValue, 6);
      expect(e.boxQuantity, 2);
      expect(e.value, 13);
    });
  });

  group('RefundMarkSplit.plan — chap qatorlar (KM havzasi)', () {
    test('KM yo\'q — avvalgidek bitta qator', () {
      final rows = RefundMarkSplit.plan(remainingUnits: 5);
      expect(rows.single.units, 5);
      expect(rows.single.marks, isEmpty);
    });

    test('10 ta sotilgan, 10 KM — bitta qator "x 10", havzada 10 KM', () {
      final marks = [for (var i = 0; i < 10; i++) '${kKm1}_$i'];
      final rows = RefundMarkSplit.plan(remainingUnits: 10, unitMarks: marks);
      expect(rows.length, 1);
      expect(rows.single.units, 10);
      expect(rows.single.marks, marks);
    });

    test('oldingi vozvratda ketgan KM havzadan chiqariladi', () {
      final rows = RefundMarkSplit.plan(
          remainingUnits: 1, unitMarks: [kKm1, kKm2], refundedMarks: {kKm1});
      expect(rows.single.units, 1);
      expect(rows.single.marks, [kKm2]);
    });

    test('KM qoldiqdan ko\'p (boshqa kassada qaytarilgan) — hammasi havzada, miqdor qoldiq',
        () {
      final rows =
          RefundMarkSplit.plan(remainingUnits: 1, unitMarks: [kKm1, kKm2]);
      expect(rows.single.units, 1);
      expect(rows.single.marks, [kKm1, kKm2]);
    });

    test('KM qoldiqdan kam (bir qismi KM\'siz sotilgan) — havza qatori + KM\'siz qator',
        () {
      final rows = RefundMarkSplit.plan(remainingUnits: 3, unitMarks: [kKm1]);
      expect(rows.length, 2);
      expect(rows[0].units, 1);
      expect(rows[0].marks, [kKm1]);
      expect(rows[1].units, 2);
      expect(rows[1].marks, isEmpty);
    });

    test('blok + dona: blok qatori blok KM havzasi bilan, dona qatori dona KM bilan',
        () {
      final rows = RefundMarkSplit.plan(
        remainingUnits: 13,
        boxValue: 6,
        blocksAvailable: 2,
        boxMarks: [kBox1, kBox2],
        unitMarks: [kBoxUnit],
      );
      expect(rows.length, 2);
      expect(rows[0].isBlock, isTrue);
      expect(rows[0].blocks, 2);
      expect(rows[0].units, 12);
      expect(rows[0].marks, [kBox1, kBox2]);
      expect(rows[1].isBlock, isFalse);
      expect(rows[1].units, 1);
      expect(rows[1].marks, [kBoxUnit]);
    });

    test('blok KM bloklardan kam — havza blok qatori + KM\'siz blok qatori', () {
      final rows = RefundMarkSplit.plan(
          remainingUnits: 12, boxValue: 6, blocksAvailable: 2, boxMarks: [kBox1]);
      expect(rows.length, 2);
      expect(rows[0].blocks, 1);
      expect(rows[0].marks, [kBox1]);
      expect(rows[1].blocks, 1);
      expect(rows[1].marks, isEmpty);
    });

    test('KM\'siz blok — avvalgidek "N blok" + dona', () {
      final rows = RefundMarkSplit.plan(
          remainingUnits: 26, boxValue: 12, blocksAvailable: 2);
      expect(rows.length, 2);
      expect(rows[0].blocks, 2);
      expect(rows[0].units, 24);
      expect(rows[1].units, 2);
    });

    test('kasr qoldiq (kg) — havza yo\'q', () {
      final rows = RefundMarkSplit.plan(remainingUnits: 1.5, unitMarks: [kKm1]);
      expect(rows.single.units, 1.5);
      expect(rows.single.marks, isEmpty);
    });

    test('takror KM bir marta', () {
      final rows =
          RefundMarkSplit.plan(remainingUnits: 2, unitMarks: [kKm1, kKm1]);
      expect(rows[0].marks, [kKm1]);
      expect(rows[0].units, 1);
      expect(rows[1].units, 1);
      expect(rows[1].marks, isEmpty);
    });

    test('marksOf: server bo\'lsa server, bo\'lmasa lokal', () {
      expect(RefundMarkSplit.marksOf('a\nb', 'c'), ['a', 'b']);
      expect(RefundMarkSplit.marksOf('', 'c\n\nd'), ['c', 'd']);
      expect(RefundMarkSplit.marksOf(null, null), isEmpty);
    });
  });

  group('KeyboardLayout — kassada rus tartibi', () {
    const samples = [
      kKm1, kKm2, kRealBox1, kRealBox2,
      '01047801017337672177j=16?_+I/FF', '01047801017337672176Cu=&jr&KtV=',
      'йцукенгшщзхъфывапролджэячсмитьбюё ЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИТЬБЮЁ',
      'aralash Жmix 123 ?.,;:"№/',
      '',
    ];
    test('ruLettersToEn sotuvdagi eski fixKeyboardLayout bilan aynan bir xil', () {
      for (final x in [...samples, for (final k in samples) typedOnRu(k)]) {
        expect(KeyboardLayout.ruLettersToEn(x), legacyFixKeyboardLayout(x),
            reason: x);
      }
    });

    test('ruToEnFull rus tartibida terilgan KM ni to\'liq tiklaydi', () {
      for (final km in [
        kKm1, kKm2, kRealBox1, kRealBox2,
        '01047801017337672177j=16?_+I/FF', '01047801017337672176Cu=&jr&KtV=',
      ]) {
        expect(KeyboardLayout.ruToEnFull(typedOnRu(km)), km, reason: km);
      }
    });

    test('ruLettersToEn faqat harflarni tiklaydi — & ? / qaytmaydi', () {
      const km = '01047801017337672177j=16?_+I/FF';
      expect(KeyboardLayout.ruLettersToEn(typedOnRu(km)), isNot(km));
    });
  });

  group('RefundMarkScan — skanerlangan KM', () {
    test('candidates: dona yo\'li — kripto qism, skaner "-" prefiksi, AI qavslari', () {
      expect(RefundMarkScan.candidates(scanned(kKm1)), contains(kKm1));
      expect(RefundMarkScan.candidates('-$kKm2'), contains(kKm2));
      expect(RefundMarkScan.candidates('(01)04780101733767(21)7VCy-1g)yILZf'),
          contains(kKm1));
      expect(RefundMarkScan.candidates('  $kKm1\n'), contains(kKm1));
    });

    test('candidates: blok yo\'li — kripto qism saqlanadi (sotuvdagidek)', () {
      final c = RefundMarkScan.candidates(kRealBox1);
      expect(c, contains(kRealBox1));
      // scanTime shaklining o'zi birinchi "93" da kesilgan — yolg'iz u mos kelmasdi
      expect(c, contains('0114780101733764217DtZ53Oi"RYhH029'));
    });

    test('candidates: rus tartibida skanerlangan dona va blok KM', () {
      for (final km in [
        kKm1, kKm2, kRealBox1, kRealBox2,
        '01047801017337672177j=16?_+I/FF', '01047801017337672176Cu=&jr&KtV=',
      ]) {
        expect(RefundMarkScan.candidates(typedOnRu(km)), contains(km),
            reason: km);
      }
      // GS + kripto qism bilan (dona yo'li kesadi)
      expect(RefundMarkScan.candidates(typedOnRu(scanned(kKm1))), contains(kKm1));
    });

    RefundScanResult check(String km,
            {bool block = false,
            List<String> pool = const [kKm1, kKm2],
            List<String> other = const [kBox1],
            Set<String> inRight = const {},
            Set<String> refunded = const {}}) =>
        RefundMarkScan.check(
          candidates: RefundMarkScan.candidates(km),
          isBlockRow: block,
          pool: pool,
          otherKindPool: other,
          inRight: inRight,
          refunded: refunded,
        );

    test('havzada — matched', () {
      expect(check(kKm2), RefundScanResult.matched);
    });
    test('chekda yo\'q — notInReceipt', () {
      expect(check('0104780101733767217NOTSOLD12345'),
          RefundScanResult.notInReceipt);
    });
    test('o\'ngda bor — alreadyAdded', () {
      expect(check(kKm1, pool: [kKm2], inRight: {kKm1}),
          RefundScanResult.alreadyAdded);
    });
    test('oldin qaytarilgan — alreadyRefunded', () {
      expect(check(kKm1, pool: [kKm2], refunded: {kKm1}),
          RefundScanResult.alreadyRefunded);
    });
    test('dona qatorida blok KM — boxMarkOnUnitRow', () {
      expect(check(kBox1), RefundScanResult.boxMarkOnUnitRow);
    });
    test('blok qatorida dona KM — unitMarkOnBoxRow', () {
      expect(check(kKm1, block: true, pool: [kBox1], other: [kKm1]),
          RefundScanResult.unitMarkOnBoxRow);
    });
    test('bo\'sh / qisqa — empty', () {
      expect(check(''), RefundScanResult.empty);
      expect(check('4780101733767'), RefundScanResult.empty);
    });
  });

  group('Vozvrat sahifasi: skanerlab qaytarish (boshqa kassa cheki)', () {
    test('DT1: chapda bitta qator "x 2", KM ko\'rinmaydi — faqat skan orqali', () {
      final page = openReturnPage(serverOrder(serverItem()));
      final p = providerOf(page);
      expect(p.getLeftList.length, 1);
      final row = p.getLeftList.single;
      expect(row.value, 2);
      expect(p.needsScan(row), isTrue);

      // Skansiz ko'chirib bo'lmaydi
      p.pressLeftIndex(0);
      p.pressLeftProduct();
      p.pressLeftProductDialog2(2);
      expect(p.getRightList, isEmpty);
      expect(row.value, 2);
    });

    test('to\'g\'ri KM — aynan o\'sha 1 dona o\'ngga, chapda 1 qoladi', () {
      final page = openReturnPage(serverOrder(serverItem()));
      final p = providerOf(page);
      final row = p.getLeftList.single;

      expect(p.scanMark(row, scanned(kKm2)), RefundScanResult.matched);
      final right = p.getRightList.single;
      expect(right.mark, kKm2);
      expect(right.value, 1);
      expect(right.marking, isTrue);
      expect(row.value, 1);
      expect(row.mark, kKm1);
    });

    test('chekda sotilmagan KM — hech narsa o\'tmaydi', () {
      final page = openReturnPage(serverOrder(serverItem()));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      expect(p.scanMark(row, scanned('0104780101733767217NOTSOLD12345')),
          RefundScanResult.notInReceipt);
      expect(p.getRightList, isEmpty);
      expect(row.value, 2);
    });

    test('bir KM ikki marta — alreadyAdded', () {
      final page = openReturnPage(serverOrder(serverItem()));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      p.scanMark(row, scanned(kKm1));
      expect(p.scanMark(row, scanned(kKm1)), RefundScanResult.alreadyAdded);
      expect(p.getRightList.length, 1);
    });

    test('o\'ngdan bekor qilish — KM chapdagi havzaga qaytadi', () {
      final page = openReturnPage(serverOrder(serverItem()));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      p.scanMark(row, scanned(kKm1));
      p.pressRightIndex(0);
      p.pressRightProduct();
      expect(p.getRightList, isEmpty);
      expect(p.getLeftList.single.value, 2);
      expect(RefundMarkSplit.marksOf(p.getLeftList.single.mark).toSet(),
          {kKm1, kKm2});
    });

    test('hammasi skanerlansa chap qator yo\'qoladi, o\'ngda 2 alohida qator', () {
      final page = openReturnPage(serverOrder(serverItem()));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      p.scanMark(row, scanned(kKm1));
      p.scanMark(row, scanned(kKm2));
      expect(p.getLeftList, isEmpty);
      expect(p.getRightList.map((e) => e.mark), [kKm1, kKm2]);
    });

    test('1 tasi boshqa kassada qaytarilgan (qaysi biri noma\'lum) — qaytayotgani skanerlanadi',
        () {
      final page = openReturnPage(serverOrder(serverItem(refundAmount: 1)));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      expect(row.value, 1);
      expect(p.scanMark(row, scanned(kKm2)), RefundScanResult.matched);
      expect(p.getLeftList, isEmpty, reason: 'qoldiq 1 — boshqasi o\'tmaydi');

      // Bekor qilinsa qator ikkala KM bilan tiklanadi
      p.pressRightIndex(0);
      p.pressRightProduct();
      expect(p.getLeftList.single.value, 1);
      expect(RefundMarkSplit.marksOf(p.getLeftList.single.mark).toSet(),
          {kKm1, kKm2});
      expect(p.scanMark(p.getLeftList.single, scanned(kKm1)),
          RefundScanResult.matched);
    });

    test('blok: blok qatorida blok KM, dona qatorida dona KM; turlar aralashmaydi', () {
      final page = openReturnPage(serverOrder(
        serverItem(
          value: 3, // token: 2 blok + 1 dona
          price: 4500,
          saleType: 2,
          boxValue: 6,
          boxQuantity: 2,
          boxMarkingNames: [kBox1, kBox2],
          markingNames: [kBoxUnit],
        ),
        totalPrice: 58500,
      ));
      final p = providerOf(page);
      expect(p.getLeftList.length, 2);
      final block = leftRow(p, block: true);
      final unit = leftRow(p);
      expect(block.value, 12);
      expect(block.boxQuantity, 2);
      expect(unit.value, 1);

      expect(p.scanMark(block, scanned(kBoxUnit)),
          RefundScanResult.unitMarkOnBoxRow);
      expect(p.scanMark(unit, scanned(kBox1)), RefundScanResult.boxMarkOnUnitRow);
      expect(p.getRightList, isEmpty);

      expect(p.scanMark(block, scanned(kBox2)), RefundScanResult.matched);
      final right = p.getRightList.single;
      expect(right.saleType, 2);
      expect(right.value, 6);
      expect(right.boxQuantity, 1);
      expect(right.mark, kBox2);
      expect(right.marking, isFalse);
      expect(block.value, 6);
      expect(block.boxQuantity, 1);
    });

    test('rus tartibida skanerlansa ham o\'sha KM o\'tadi — soliqqa sotuvdagi Label', () {
      const km = '01047801017337672176Cu=&jr&KtV=';
      final page = openReturnPage(serverOrder(serverItem(markingNames: [km, kKm1])));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      expect(p.scanMark(row, typedOnRu(km)), RefundScanResult.matched);
      expect(p.getRightList.single.mark, km);
      expect(itemsOf(wireJson(refundOf(page, p))).single['Label'], km);
    });

    test('haqiqiy blok KM (kripto qism bilan) — blok qatorida mos keladi (DT7 regressiya)',
        () {
      final page = openReturnPage(serverOrder(
        serverItem(
          value: 4, // token: 3 blok + 1 dona
          price: 2800,
          saleType: 2,
          boxValue: 12,
          boxQuantity: 3,
          boxMarkingNames: [kRealBox1, kRealBox2, '${kRealBox2}x'],
          markingNames: [kKm1],
        ),
        totalPrice: 2800 * 37,
      ));
      final p = providerOf(page);
      final block = leftRow(p, block: true);
      final unit = leftRow(p);
      expect(p.scanMark(unit, kRealBox1), RefundScanResult.boxMarkOnUnitRow);
      expect(p.scanMark(block, kRealBox1), RefundScanResult.matched);
      expect(p.getRightList.single.mark, kRealBox1);
      expect(p.getRightList.single.value, 12);

      final items = itemsOf(wireJson(refundOf(page, p)));
      expect(items.single['Label'], kRealBox1, reason: 'sotuvdagi Label aynan');
      expect(items.single['Amount'], 1000);
      expect(items.single['Price'], 3360000);
    });

    test('KM\'siz chek (server KM bermagan, lokal yo\'q) — avvalgidek miqdor bilan', () {
      final page = openReturnPage(serverOrder(
          serverItem(markingNames: null, boxMarkingNames: null)));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      expect(p.needsScan(row), isFalse);
      p.pressLeftIndex(0);
      p.pressLeftProductDialog2(1);
      expect(p.getRightList.single.value, 1);
      expect(p.getRightList.single.mark, isNull);
    });
  });

  group('Sotuv (order_pos) — refunded_* maydonlar doim bo\'sh', () {
    test('dona KM, blok KM va oddiy qator: ikkala maydon bo\'sh massiv', () {
      final rows = [
        localRow(value: 2, mark: '$kKm1\n$kKm2'),
        localRow(
            value: 13, saleType: 2, boxValue: 6, boxQuantity: 2,
            boxMark: '$kRealBox1\n$kRealBox2', mark: kBoxUnit),
        localRow(value: 3),
      ];
      for (final r in rows) {
        final j = jsonDecode(jsonEncode(r.toJson())) as Map<String, dynamic>;
        expect(j['refunded_marking_names'], isEmpty);
        expect(j['refunded_box_marking_names'], isEmpty);
        expect(j['refunded_marking_names'], isA<List>());
      }
      // Sotilgan KM'lar avvalgidek o'z maydonlarida
      final dona = rows[0].toJson();
      expect(dona['marking_names'], [kKm1, kKm2]);
      final blok = rows[1].toJson();
      expect(blok['box_marking_names'], [kRealBox1, kRealBox2]);
    });
  });

  group('Serverga vozvrat (refund_order_items) — KM\'lar bilan', () {
    ReceiptModelSoldItem4 row(String itemId,
        {double value = 1, String? mark, int saleType = 1, int boxValue = 0}) {
      final r = localRow(
          value: value, mark: mark, saleType: saleType, boxValue: boxValue,
          boxQuantity: boxValue > 0 ? value ~/ boxValue : 0);
      r.refundItemId = itemId;
      return r;
    }

    Map<String, dynamic> body(List<ReceiptModelSoldItem4> rows) {
      final r = localReceipt(externalId: 'R1', isRefund: true, items: rows);
      r.payment.add(
          ReceiptModelPaymentType4(name: 'CASH', payId: 'cash-id', value: 1));
      return ReceiptApi4.funcToRefund(r);
    }

    test('shablon: items[] da id, price, quantity, marking_names, box_marking_names', () {
      final b = body([row('item-1', mark: kKm1)]);
      final it = (b['items'] as List).single as Map<String, dynamic>;
      expect(it.keys.toSet(),
          {'id', 'price', 'quantity', 'marking_names', 'box_marking_names'});
      expect(b.keys.toSet(), containsAll(['items', 'payments', 'user_id']));
      // JSON'ga massiv bo'lib ketadi
      expect(jsonDecode(jsonEncode(b))['items'][0]['marking_names'], [kKm1]);
    });

    test('bir item\'ning dona KM qatorlari bitta itemga jamlanadi', () {
      final it = (body([
        row('item-1', mark: kKm1),
        row('item-1', mark: kKm2),
      ])['items'] as List).single;
      expect(it['quantity'], 2);
      expect(it['marking_names'], [kKm1, kKm2]);
      expect(it['box_marking_names'], isEmpty);
    });

    test('blok qatorlari box_marking_names ga, dona qatori marking_names ga', () {
      final it = (body([
        row('item-1', value: 12, mark: kRealBox1, saleType: 2, boxValue: 12),
        row('item-1', value: 12, mark: kRealBox2, saleType: 2, boxValue: 12),
        row('item-1', mark: kKm1),
      ])['items'] as List).single;
      expect(it['quantity'], 25);
      expect(it['box_marking_names'], [kRealBox1, kRealBox2]);
      expect(it['marking_names'], [kKm1]);
    });

    test('KM\'siz qator — bo\'sh massivlar (eski xatti-harakat + yangi maydonlar)', () {
      final it = (body([row('item-2', value: 3)])['items'] as List).single;
      expect(it['quantity'], 3);
      expect(it['marking_names'], isEmpty);
      expect(it['box_marking_names'], isEmpty);
    });

    test('har xil item\'lar KM\'lari aralashmaydi', () {
      final items = body([
        row('item-1', mark: kKm1),
        row('item-2', mark: kKm2),
      ])['items'] as List;
      final byId = {for (final i in items) i['id']: i};
      expect(byId['item-1']['marking_names'], [kKm1]);
      expect(byId['item-2']['marking_names'], [kKm2]);
    });
  });

  group('Soliqqa (fiskal modul) vozvrat — sotuvdagidek', () {
    test('DT1: 2 KM skanerlandi → 2 pozitsiya, Label = KM, Amount 1000', () {
      final page = openReturnPage(serverOrder(serverItem()));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      p.scanMark(row, scanned(kKm1));
      p.scanMark(row, scanned(kKm2));

      final refund = refundOf(page, p);
      final items = itemsOf(wireJson(refund));
      expect(items.length, 2);
      expect(items.map((i) => i['Label']), [kKm1, kKm2]);

      // Serverga (refund_order_items): bitta item, qaytgan KM'lar bilan
      final body = ReceiptApi4.funcToRefund(refund)['items'] as List;
      expect(body.single['quantity'], 2);
      expect(body.single['marking_names'], [kKm1, kKm2]);
      expect(body.single['box_marking_names'], isEmpty);
      for (final i in items) {
        expect(i['Amount'], 1000);
        expect(i['Price'], 290000);
        expect(i['SPIC'], kMxik);
        expect(i['Barcode'], '4780101733767');
      }
    });

    test('2 tadan 1 tasi skanerlandi → bitta pozitsiya, o\'sha KM bilan', () {
      final page = openReturnPage(serverOrder(serverItem()));
      final p = providerOf(page);
      p.scanMark(p.getLeftList.single, scanned(kKm2));
      final items = itemsOf(wireJson(refundOf(page, p)));
      expect(items.single['Label'], kKm2);
      expect(items.single['Amount'], 1000);
    });

    test('blok: blok KM pozitsiyasi Amount 1000 × blok narxi; serverga dona hisobida',
        () {
      final page = openReturnPage(serverOrder(
        serverItem(
          value: 3,
          price: 4500,
          saleType: 2,
          boxValue: 6,
          boxQuantity: 2,
          boxMarkingNames: [kBox1, kBox2],
          markingNames: [kBoxUnit],
        ),
        totalPrice: 58500,
      ));
      final p = providerOf(page);
      p.scanMark(leftRow(p, block: true), scanned(kBox1));
      p.scanMark(leftRow(p, block: true), scanned(kBox2));
      p.scanMark(leftRow(p), scanned(kBoxUnit));

      final refund = refundOf(page, p);
      final items = itemsOf(wireJson(refund));
      expect(items.length, 3);
      expect(items[0]['Label'], kBox1);
      expect(items[0]['Amount'], 1000);
      expect(items[0]['Price'], 2700000);
      expect(items[1]['Label'], kBox2);
      expect(items[1]['Amount'], 1000);
      expect(items[2]['Label'], kBoxUnit);
      expect(items[2]['Amount'], 1000);
      expect(items[2]['Price'], 450000);

      final refunded = ReceiptApi4.funcToRefund(refund)['items'] as List;
      expect(refunded.single['quantity'], 13);
      expect(refunded.single['box_marking_names'], [kBox1, kBox2]);
      expect(refunded.single['marking_names'], [kBoxUnit]);
    });

    test('blok, 1 blok boshqa kassada qaytarilgan: qolgan 1 blok skanerlanadi (ilgari item yo\'qolardi)',
        () {
      final page = openReturnPage(serverOrder(
        serverItem(
          value: 3,
          refundAmount: 6,
          price: 4500,
          saleType: 2,
          boxValue: 6,
          boxQuantity: 2,
          boxMarkingNames: [kBox1, kBox2],
          markingNames: [kBoxUnit],
        ),
        totalPrice: 58500,
      ));
      final p = providerOf(page);
      final block = leftRow(p, block: true);
      expect(block.value, 6);
      expect(p.scanMark(block, scanned(kBox2)), RefundScanResult.matched);
      expect(p.getLeftList.where((e) => e.saleType == 2), isEmpty);

      final items = itemsOf(wireJson(refundOf(page, p)));
      expect(items.single['Label'], kBox2);
      expect(items.single['Amount'], 1000);
      expect(items.single['Price'], 2700000);
    });
  });

  group('Serverdagi qaytarilgan KM\'lar (refunded_marking_names / refunded_box_marking_names)', () {
    final k = [for (var i = 0; i < 10; i++) '0104780101733767217Km${i}abcdefgh'];

    test('ItemsGTR o\'qiydi; serverRefundedMarks barcha item\'lardan dona + blok', () {
      final order = serverOrder(
        serverItem(refundedMarkingNames: [k[0]], refundedBoxMarkingNames: [kRealBox1]),
        more: [serverItem(id: 'item-2', refundedMarkingNames: [k[5]])],
      );
      expect(order.items!.first.refundedMarkingNames, [k[0]]);
      expect(order.items!.first.refundedBoxMarkingNames, [kRealBox1]);
      expect(ReUpdateBloc.serverRefundedMarks(order), {k[0], kRealBox1, k[5]});
    });

    test('eski server (maydonlar yo\'q) — bo\'sh, avvalgidek ishlaydi', () {
      final order = serverOrder(serverItem());
      expect(order.items!.first.refundedMarkingNames, isEmpty);
      expect(ReUpdateBloc.serverRefundedMarks(order), isEmpty);
    });

    test('10 tadan 3 tasi boshqa kassada qaytarilgan — havzada 7 ta, qaytarilgani "oldin qaytarilgan"', () {
      final page = openReturnPage(serverOrder(serverItem(
        value: 10,
        refundAmount: 3,
        markingNames: k,
        refundedMarkingNames: [k[0], k[1], k[2]],
      ), totalPrice: 28000));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      expect(row.value, 7);
      expect(RefundMarkSplit.marksOf(row.mark), k.sublist(3));
      for (final r in [k[0], k[1], k[2]]) {
        expect(p.scanMark(row, r), RefundScanResult.alreadyRefunded);
      }
      expect(p.getRightList, isEmpty);
      expect(p.scanMark(row, k[3]), RefundScanResult.matched);
      expect(row.value, 6);
    });

    test('blok boshqa kassada qaytarilgan — blok qatorida ham, dona qatorida ham "oldin qaytarilgan"', () {
      final page = openReturnPage(serverOrder(serverItem(
        value: 4, // token: 3 blok + 1 dona
        refundAmount: 12, // 1 blok
        price: 2800,
        saleType: 2,
        boxValue: 12,
        boxQuantity: 3,
        boxMarkingNames: [kRealBox1, kRealBox2, '${kRealBox2}b'],
        markingNames: [k[0]],
        refundedBoxMarkingNames: [kRealBox1],
      ), totalPrice: 2800 * 37));
      final p = providerOf(page);
      final block = leftRow(p, block: true);
      final unit = leftRow(p);
      expect(block.boxQuantity, 2);
      expect(RefundMarkSplit.marksOf(block.mark), [kRealBox2, '${kRealBox2}b']);
      expect(p.scanMark(block, kRealBox1), RefundScanResult.alreadyRefunded);
      expect(p.scanMark(unit, kRealBox1), RefundScanResult.alreadyRefunded);
      expect(p.scanMark(block, kRealBox2), RefundScanResult.matched);
    });

    test('qaytarilgan KM rus tartibida skanerlansa ham "oldin qaytarilgan"', () {
      const km = '01047801017337672176Cu=&jr&KtV=';
      final page = openReturnPage(serverOrder(serverItem(
        refundAmount: 1,
        markingNames: [km, kKm1],
        refundedMarkingNames: [km],
      )));
      final p = providerOf(page);
      expect(p.scanMark(p.getLeftList.single, typedOnRu(km)),
          RefundScanResult.alreadyRefunded);
    });

    test('eski versiyada (KM\'siz) qaytarilgan — KM noma\'lum, lekin miqdor server qoldig\'idan oshmaydi', () {
      // refund_amount 3, refunded ro'yxat bo'sh: qaysi 3 KM qaytgani noma'lum.
      final page = openReturnPage(serverOrder(serverItem(
        value: 10,
        refundAmount: 3,
        markingNames: k,
        refundedMarkingNames: [],
      ), totalPrice: 28000));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      expect(row.value, 7);
      for (var i = 0; i < 7; i++) {
        expect(p.scanMark(row, k[i]), RefundScanResult.matched);
      }
      expect(p.getLeftList, isEmpty, reason: '8-chisini qaytarib bo\'lmaydi');
      expect(p.getRightList.length, 7);
    });

    test('A chekda qaytarilib, B chekda qayta sotilgan KM — B chek bo\'yicha qaytariladi', () {
      final pageB = openReturnPage(serverOrder(
        serverItem(markingNames: [k[0], k[1]]), // B chekda refunded yo'q
        externalId: 'DT-B',
      ));
      final p = providerOf(pageB);
      expect(p.scanMark(p.getLeftList.single, k[0]), RefundScanResult.matched);
    });

    test('boshqa mahsulot qatorini bosib skanerlansa — "boshqa mahsulotniki" (chekda yo\'q emas)', () {
      const hydro = '0104780069000512217Hydro0abcdefg';
      final page = openReturnPage(serverOrder(
        serverItem(markingNames: [k[0]]),
        more: [serverItem(id: 'item-h', productId: 'hydro-id', markingNames: [hydro])],
        totalPrice: 5800,
      ));
      final p = providerOf(page);
      final montella = p.getLeftList.firstWhere((e) => e.productId == kProductId);
      expect(p.scanMark(montella, hydro), RefundScanResult.otherProduct);
      expect(p.getRightList, isEmpty);
      final h = p.getLeftList.firstWhere((e) => e.productId == 'hydro-id');
      expect(p.scanMark(h, hydro), RefundScanResult.matched);
    });

    test('bir chekda bir mahsulot ikki item bo\'lsa — bekor qilingan KM o\'z item\'iga qaytadi', () {
      final page = openReturnPage(serverOrder(
        serverItem(id: 'item-1', markingNames: [k[0], k[1]]),
        more: [serverItem(id: 'item-2', markingNames: [k[2], k[3]])],
        totalPrice: 11600,
      ));
      final p = providerOf(page);
      final row2 = p.getLeftList.firstWhere((e) => e.refundItemId == 'item-2');
      expect(p.scanMark(row2, k[2]), RefundScanResult.matched);
      p.pressRightIndex(0);
      p.pressRightProduct();
      final back = p.getLeftList.firstWhere((e) => e.refundItemId == 'item-2');
      expect(RefundMarkSplit.marksOf(back.mark).toSet(), {k[2], k[3]});
      final row1 = p.getLeftList.firstWhere((e) => e.refundItemId == 'item-1');
      expect(RefundMarkSplit.marksOf(row1.mark).toSet(), {k[0], k[1]});
      // Serverga KM o'z item id'si bilan ketadi
      p.scanMark(back, k[3]);
      final body = ReceiptApi4.funcToRefund(refundOf(page, p))['items'] as List;
      expect(body.single['id'], 'item-2');
      expect(body.single['marking_names'], [k[3]]);
    });
  });

  group('Umumiy hayot sikli: sotuv → A kassada vozvrat → B, C kassa (server holati vozvrat tanasidan)', () {
    final k = [for (var i = 0; i < 10; i++) '0104780101733767217Km${i}abcdefgh'];
    final b = ['0114780101733764217Box1abcdefg02993zzzz', '0114780101733764217Box2abcdefg02993yyyy'];
    const price = 2800;

    // Sotuv: 2 blok (12 dona) + 10 dona = 34 dona, serverda token 12.
    GlobalReceipt server({
      num refundAmount = 0,
      List<String> refunded = const [],
      List<String> refundedBox = const [],
    }) =>
        serverOrder(serverItem(
          value: 12,
          refundAmount: refundAmount,
          price: price,
          saleType: 2,
          boxValue: 12,
          boxQuantity: 2,
          boxMarkingNames: b,
          markingNames: k,
          refundedMarkingNames: refunded,
          refundedBoxMarkingNames: refundedBox,
        ), totalPrice: price * 34);

    test('to\'liq oqim', () {
      // ---- A kassa: 1 blok + 3 dona
      final a = openReturnPage(server());
      final pa = providerOf(a);
      expect(leftRow(pa, block: true).boxQuantity, 2);
      expect(leftRow(pa).value, 10);
      expect(pa.scanMark(leftRow(pa, block: true), b[0]), RefundScanResult.matched);
      for (final km in [k[0], k[1], k[2]]) {
        expect(pa.scanMark(leftRow(pa), km), RefundScanResult.matched);
      }
      final refundA = refundOf(a, pa);
      final wireA = itemsOf(wireJson(refundA));
      expect(wireA.map((i) => i['Label']), [b[0], k[0], k[1], k[2]]);
      expect(wireA.first['Amount'], 1000);
      expect(wireA.first['Price'], 12 * price * 100);
      expect(wireA.skip(1).every((i) => i['Amount'] == 1000 && i['Price'] == price * 100), isTrue);
      final bodyA = (ReceiptApi4.funcToRefund(refundA)['items'] as List).single;
      expect(bodyA['quantity'], 15);
      expect(bodyA['box_marking_names'], [b[0]]);
      expect(bodyA['marking_names'], [k[0], k[1], k[2]]);

      // ---- Server A vozvratini qabul qildi (holat aynan yuborilgan tanadan)
      final refunded1 = List<String>.from(bodyA['marking_names']);
      final refundedBox1 = List<String>.from(bodyA['box_marking_names']);

      // ---- B kassa (lokal ma'lumot yo'q)
      final bPage = openReturnPage(server(
          refundAmount: 15, refunded: refunded1, refundedBox: refundedBox1));
      final pb = providerOf(bPage);
      expect(leftRow(pb, block: true).boxQuantity, 1);
      expect(leftRow(pb).value, 7);
      expect(pb.scanMark(leftRow(pb, block: true), b[0]), RefundScanResult.alreadyRefunded);
      expect(pb.scanMark(leftRow(pb), k[1]), RefundScanResult.alreadyRefunded);
      expect(pb.scanMark(leftRow(pb), '0104780101733767217NOTSOLD12345'), RefundScanResult.notInReceipt);
      expect(pb.scanMark(leftRow(pb), k[3]), RefundScanResult.matched);
      expect(pb.scanMark(leftRow(pb, block: true), b[1]), RefundScanResult.matched);
      final bodyB = (ReceiptApi4.funcToRefund(refundOf(bPage, pb))['items'] as List).single;
      expect(bodyB['quantity'], 13);
      expect(bodyB['marking_names'], [k[3]]);
      expect(bodyB['box_marking_names'], [b[1]]);

      // ---- C kassa: qolgan 6 dona
      final c = openReturnPage(server(
        refundAmount: 28,
        refunded: [...refunded1, ...List<String>.from(bodyB['marking_names'])],
        refundedBox: [...refundedBox1, ...List<String>.from(bodyB['box_marking_names'])],
      ));
      final pc = providerOf(c);
      expect(pc.getLeftList.where((e) => e.saleType == 2), isEmpty);
      final rest = leftRow(pc);
      expect(rest.value, 6);
      expect(RefundMarkSplit.marksOf(rest.mark), k.sublist(4));
      for (final km in k.sublist(4)) {
        expect(pc.scanMark(rest, km), RefundScanResult.matched);
      }
      expect(pc.getLeftList, isEmpty);
      final bodyC = (ReceiptApi4.funcToRefund(refundOf(c, pc))['items'] as List).single;
      expect(bodyC['quantity'], 6);
      expect(bodyC['marking_names'], k.sublist(4));

      // ---- Hammasi qaytgan: vozvrat sahifasi bo'sh
      final done = openReturnPage(server(refundAmount: 34, refunded: k, refundedBox: b));
      expect(done.receipt.soldItemList, isEmpty);
    });
  });

  final Store? store = _tryOpenStore();

  group('Shu kassa / lokal vozvratlar (ObjectBox)', skip: store == null
      ? 'ObjectBox kutubxonasi topilmadi (libobjectbox) — fayl boshidagi izohga qarang'
      : false, () {
    setUpAll(() => MyObjectbox.saleStore = store!);
    tearDownAll(() => store?.close());
    setUp(() => MyObjectbox.saleStore.box<ReceiptModel4>().removeAll());

    test('shu kassada 1 tasi qaytarilgan — havzada faqat qolgani, qaytarilgani "oldin qaytarilgan"',
        () {
      final box = MyObjectbox.saleStore.box<ReceiptModel4>();
      box.put(localReceipt(
          externalId: 'DT1',
          isRefund: false,
          items: [localRow(value: 2, mark: '$kKm1\n$kKm2')]));
      box.put(localReceipt(
          externalId: 'DT1',
          isRefund: true,
          items: [localRow(value: 1, mark: kKm1)]));

      final page = openReturnPage(serverOrder(serverItem(refundAmount: 1)));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      expect(row.value, 1);
      expect(row.mark, kKm2);
      expect(p.scanMark(row, scanned(kKm1)), RefundScanResult.alreadyRefunded);
      expect(p.scanMark(row, scanned(kKm2)), RefundScanResult.matched);
    });

    test('server KM bermasa (eski chek) — havza lokal originaldan', () {
      MyObjectbox.saleStore.box<ReceiptModel4>().put(localReceipt(
          externalId: 'DT1',
          isRefund: false,
          items: [localRow(value: 2, mark: '$kKm1\n$kKm2')]));

      final page = openReturnPage(
          serverOrder(serverItem(markingNames: null, boxMarkingNames: null)));
      final row = page.receipt.soldItemList.single;
      expect(RefundMarkSplit.marksOf(row.mark), [kKm1, kKm2]);
    });

    test('shu kassa blok cheki — blok qoldig\'i lokal hisobdan, havzalar bilan', () {
      MyObjectbox.saleStore.box<ReceiptModel4>().put(localReceipt(
        externalId: 'DB1',
        isRefund: false,
        items: [
          localRow(
            value: 13,
            price: 4500,
            saleType: 2,
            boxValue: 6,
            boxQuantity: 2,
            boxMark: '$kBox1\n$kBox2',
            mark: kBoxUnit,
          ),
        ],
      ));

      final page = openReturnPage(serverOrder(
        serverItem(
          value: 3,
          price: 4500,
          saleType: 2,
          boxValue: 6,
          boxQuantity: 2,
          boxMarkingNames: [kBox1, kBox2],
          markingNames: [kBoxUnit],
        ),
        externalId: 'DB1',
        totalPrice: 58500,
      ));
      final rows = page.receipt.soldItemList;
      expect(rows.map((e) => e.value), [12, 1]);
      expect(RefundMarkSplit.marksOf(rows[0].mark), [kBox1, kBox2]);
      expect(RefundMarkSplit.marksOf(rows[1].mark), [kBoxUnit]);
    });

    test('boshqa kassa cheki shu yerda qisman qaytarilgan — qolgani chiqadi (ilgari 2 marta ayirilardi)',
        () {
      // Lokal original YO'Q (boshqa kassa), shu kassadagi vozvrat serverga yetgan.
      MyObjectbox.saleStore.box<ReceiptModel4>().put(localReceipt(
          externalId: 'DT1',
          isRefund: true,
          items: [localRow(value: 1, mark: kKm1)]));

      final page = openReturnPage(serverOrder(serverItem(refundAmount: 1)));
      final row = page.receipt.soldItemList.single;
      expect(row.value, 1, reason: 'ilgari 2 − 1 (server) − 1 (lokal) = 0 bo\'lib yo\'qolardi');
      expect(row.mark, kKm2);
    });

    test('server ro\'yxati + shu kassadagi hali yuborilmagan vozvrat — ikkalasi ham chiqariladi', () {
      MyObjectbox.saleStore.box<ReceiptModel4>().put(localReceipt(
          externalId: 'DT1',
          isRefund: true,
          uploaded: false,
          items: [localRow(value: 1, mark: kKm2)]));
      const k3 = '0104780101733767217Km3abcdefgh';
      // Server faqat kKm1 ni biladi (kKm2 vozvrati hali yetib bormagan)
      final page = openReturnPage(serverOrder(serverItem(
        value: 3,
        refundAmount: 1,
        markingNames: [kKm1, kKm2, k3],
        refundedMarkingNames: [kKm1],
      ), totalPrice: 8700));
      final p = providerOf(page);
      final row = p.getLeftList.single;
      expect(row.value, 1, reason: '3 − 1 (server) − 1 (yuborilmagan lokal)');
      expect(row.mark, k3);
      expect(p.scanMark(row, kKm1), RefundScanResult.alreadyRefunded);
      expect(p.scanMark(row, kKm2), RefundScanResult.alreadyRefunded);
      expect(p.scanMark(row, k3), RefundScanResult.matched);
    });

    test('shu kassadagi vozvrat serverga hali yetmagan — lokal hisobdan ayiriladi', () {
      MyObjectbox.saleStore.box<ReceiptModel4>().put(localReceipt(
          externalId: 'DT1',
          isRefund: true,
          uploaded: false,
          items: [localRow(value: 1, mark: kKm1)]));

      final page = openReturnPage(serverOrder(serverItem()));
      final row = page.receipt.soldItemList.single;
      expect(row.value, 1);
      expect(row.mark, kKm2);
    });
  });
}
