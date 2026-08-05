// Umumiy test muhiti (harness).
//
// Sabab: box_price_edit_sync, deleted_items_orderpos, mark_block_manual_price va
// box_return_block testlarida bir xil Hive setup so'zma-so'z takrorlangan edi
// (temp dir + 6 adapter + 5 box + test kassir). Har yangi test uni yana
// ko'chirishga majbur bo'lardi, va bitta joyda o'zgarish kerak bo'lsa 4 joyni
// tahrirlash kerak edi.
//
// Ishlatish:
//   setUpAll(() => setUpPosTestEnv('mening_testim'));
//   tearDownAll(tearDownPosTestEnv);
//   final p = freshProvider();
//
// Hive'ga bog'liq bo'lmagan testlar (masalan sof funksiya testlari) buni
// umuman ishlatmaydi.

import 'dart:io';

import 'package:hive/hive.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/providers/ordering_provider_4.dart';
import 'package:invan2/features/get_discounts/model/discounts_response.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

/// Test kassir IDsi. `OrderingProvider4` konstruktorda
/// `HiveBoxes.getCurrentEmployee!` ni o'qiydi, shuning uchun bu ID bilan
/// xodim Hive'ga oldindan yozilishi shart — aks holda provider yaratilmaydi.
const kCashierId = 'kassir-001';

/// Test foydalanuvchi IDsi (refund oqimi `PrefKeys.userId` ni o'qiydi).
const kUserId = 'user-1';

const kCashierName = 'Test Kassir';

Directory? _tempDir;

/// To'liq POS test muhiti: adapterlar, boxlar va test kassir.
///
/// [name] — temp papka prefiksi (test fayllarini ajratish uchun).
/// [withEmployee] — `false` bo'lsa xodim yozilmaydi; `OrderingProvider4`
/// yaratmaydigan, faqat Pref/box kerak bo'lgan testlar uchun.
Future<void> setUpPosTestEnv(
  String name, {
  bool withEmployee = true,
}) async {
  _tempDir = await Directory.systemTemp.createTemp(name);
  Hive.init(_tempDir!.path);

  _registerAdapters();

  await Hive.openBox(HiveBoxNames.prefs);
  await Hive.openBox<DiscountItem>(HiveBoxNames.discounts);
  // Offline flush paytida ApiProvider xato loglari shu boxlarga yoziladi.
  await Hive.openBox<LogModel>(HiveBoxNames.logs);
  await Hive.openBox<LogModel>(HiveBoxNames.tglogs);
  final empBox = await Hive.openBox<Employee>(HiveBoxNames.employees);

  await Pref.setString(PrefKeys.cashierId, kCashierId);
  await Pref.setString(PrefKeys.userId, kUserId);

  if (withEmployee) {
    await empBox.add(
      Employee(user: EmployeeUser(id: kCashierId, firstName: kCashierName)),
    );
  }
}

Future<void> tearDownPosTestEnv() async {
  await Hive.close();
  await _tempDir?.delete(recursive: true);
  _tempDir = null;
}

/// Adapter ikki marta ro'yxatdan o'tsa Hive xato beradi — shuning uchun guard.
void _registerAdapters() {
  void reg<T>(int typeId, TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(typeId)) Hive.registerAdapter(adapter);
  }

  reg(EmployeeAdapter().typeId, EmployeeAdapter());
  reg(EmployeeUserAdapter().typeId, EmployeeUserAdapter());
  reg(EmployeeRoleAdapter().typeId, EmployeeRoleAdapter());
  reg(EmployeeAccessAdapter().typeId, EmployeeAccessAdapter());
  reg(DiscountItemAdapter().typeId, DiscountItemAdapter());
  reg(LogModelAdapter().typeId, LogModelAdapter());
}

/// Toza savatli yangi provider.
///
/// `OrderingProvider4` ichida `_currentClient` maydonini konstruktorda
/// yaratadi, lekin ba'zi holatlarda ro'yxat qayta ishlatilishi mumkin —
/// shuning uchun savat va o'chirilganlar ro'yxati aniq tozalanadi.
OrderingProvider4 freshProvider() {
  final p = OrderingProvider4();
  p.getCurrentClient.orderedProducts.clear();
  p.getCurrentClient.deletedItems.clear();
  return p;
}

/// Savat qatori (sotilgan mahsulot) yasovchi.
///
/// Barcha muhim maydonlar nomlangan parametr — testda faqat kerakligi
/// ko'rsatiladi, qolgani real POS qiymatlariga yaqin standart qiymat oladi.
///
/// [saleType]: 1 = dona, 2 = blok.
ReceiptModelSoldItem4 makeSoldItem({
  String productId = 'pepsi-id',
  String name = 'Pepsi 1.5L',
  String barcode = '4780000000000',
  String mxik = '02202001001000000',
  int sku = 1001,
  double price = 5000,
  double? realPrice,
  double? onlyPrice,
  double value = 1,
  double vatPercent = 12,
  double singleDiscount = 0,
  bool marking = false,
  String? mark,
  bool isKg = false,
  bool isDeleted = false,
  bool isFreeGift = false,
  bool isPriceChanged = false,
  bool isPriceOnlyChanged = false,
  int saleType = 1,
  int boxValue = 0,
  int boxQuantity = 0,
  String? boxMark,
  String productType = '',
  String productPackage = '',
  int? createdTime,
}) {
  return ReceiptModelSoldItem4(
    inBox: 0,
    barcode: barcode,
    sku: sku,
    vatPercent: vatPercent,
    vat: (price * vatPercent) / (100 + vatPercent),
    mxik: mxik,
    tin: '',
    onlyPrice: onlyPrice ?? price,
    realPrice: realPrice ?? price,
    price: price,
    cost: 0,
    vatName: 'НДС ${vatPercent.toInt()}%',
    createdTime: createdTime ?? DateTime.now().millisecondsSinceEpoch,
    value: value,
    productId: productId,
    productName: name,
    sellerId: '',
    soldBy: kCashierId,
    singleDiscount: singleDiscount,
    ownerType: 0,
    isDeleted: isDeleted,
    marking: marking,
    mark: mark,
    isKg: isKg,
    isFreeGift: isFreeGift,
    isPriceChanged: isPriceChanged,
    isPriceOnlyChanged: isPriceOnlyChanged,
    saleType: saleType,
    boxValue: boxValue,
    boxQuantity: boxQuantity,
    boxMark: boxMark,
    productType: productType,
    productPackage: productPackage,
  );
}
