// Chek yig'ish (`ReceiptBuilder.build`) — to'liq test to'plami.
//
// Bu kod Faza 6 da `pressPaymentButton` dan ajratildi (tana o'zgartirilmadi).
// Ilgari uni testlab bo'lmasdi: metod `BuildContext` talab qilardi va
// ichida `ReceiptSingleton4.toOBJECTBOX` bor edi (ObjectBox testda ishlamaydi).
// Ajratilgandan keyin sof funksiya bo'ldi — mana shu testlar.
//
// Qamrov: mijoz maydonlari, supplier nomi, chegirma turlari (summa/foiz),
// to'lovlar va qarz belgisi, o'chirilgan (isDeleted) itemlar, deleted_items +
// orphan, markirovka KM tozalash, sdacha/keshbek, izoh, Pref maydonlari.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:invan2/changes/domain/receipt/receipt_builder.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/changes/models/deleted_item_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/models/supplier_model.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/discount_type_status.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import 'support/provider_harness.dart';

const kPosName = 'Kassa-1';
const kShopId = 'shop-1';
const kCashboxId = 'cashbox-1';

/// Mijozsiz chekdagi standart chegirma ID (kod ichidagi qat'iy qiymat).
const kNoClientDiscountId = '9a2aa8fe-806e-44d7-8c9d-575fa67ebefd';
const kSummaDiscountId = '9fb3ada6-a73b-4b81-9295-5c1605e54552';
const kPercentDiscountId = '1fe92aa8-2a61-4bf1-b907-182b497584ad';

SixClientModel4 clientSlot({
  List<ReceiptModelSoldItem4>? items,
  ClientModel? client,
  double? discountPercent,
  List<DeletedItemModel4> deleted = const [],
}) {
  final s = SixClientModel4(
    clientNumber: 1,
    lastAddedIndex: -1,
    orderedProducts: items ?? [],
    discountAmountFromNewClient: 0,
  );
  s.selectedClient = client;
  s.discountPercent = discountPercent;
  s.deletedItems.addAll(deleted);
  return s;
}

ClientModel testClient({
  String id = 'client-1',
  String phone = '998901234567',
  String firstName = 'Ali',
  double discountValue = 5,
  String? discountId = 'client-disc-id',
}) =>
    ClientModel(
      id: id,
      phoneNumber: phone,
      firstName: firstName,
      discountValue: discountValue,
      discountId: discountId,
    );

SupplierModel testSupplier({
  String company = 'Alfa MChJ',
  String name = 'Alfa',
}) =>
    SupplierModel(
      id: 'sup-1',
      supplierCompanyName: company,
      agreementNumber: const [],
      name: name,
      phoneNumber: const [],
      externalId: '',
      status: '',
      contact: '',
      inn: '',
      email: '',
    );

DeletedItemModel4 deletedItem(String productId, {String checkNumber = ''}) =>
    DeletedItemModel4(
      deletedBy: kCashierId,
      deletedTime: '2026-08-06 10:00:00',
      addedTime: '2026-08-06 09:59:00',
      checkNumber: checkNumber,
      productId: productId,
      quantity: 1,
      totalPrice: 1000,
    );

ReceiptModel4 build({
  SixClientModel4? slot,
  SupplierModel? supplier,
  double? clientDiscountPercent,
  List<ReceiptModelSoldItem4>? currentCart,
  num totalPrice = 100000,
  double zdachaToCashBack = 0,
  double sdacha = 0,
  double fromPointBalance = 0,
  String comments = '',
  bool showComments = true,
  List<ReceiptModelPaymentType4>? payments,
  List<DeletedItemModel4> orphans = const [],
  bool isTpEdited = true,
}) {
  final s = slot ?? clientSlot(items: [makeSoldItem()]);
  return ReceiptBuilder.build(
    sixClient: s,
    selectedSupplier: supplier,
    currentClientDiscountPercent: clientDiscountPercent,
    currentCart: currentCart ?? s.orderedProducts,
    totalPrice: totalPrice,
    zdachaToCashBack: zdachaToCashBack,
    sdacha: sdacha,
    fromPointBalance: fromPointBalance,
    comments: comments,
    showComments: showComments,
    payments: payments ??
        [ReceiptModelPaymentType4(name: 'cash', payId: 'cash-id', value: 100000)],
    orphanDeletedItems: orphans,
    isTpEdited: isTpEdited,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpPosTestEnv('receipt_builder_test');
    await Pref.setString(PrefKeys.posName, kPosName);
    await Pref.setString(PrefKeys.storeId, kShopId);
    await Pref.setString(PrefKeys.activatedPosId, kCashboxId);
    await Pref.setString(PrefKeys.cashierName, kCashierName);
  });
  tearDownAll(tearDownPosTestEnv);

  // Har testdan oldin global "tepa chegirma" holatini tiklaymiz —
  // build() uni o'qiydi va oxirida discount ga qaytaradi.
  setUp(() => DiscountTypeStatus.disTypeStatus = TpStatus.discount);

  group('Mijozsiz chek', () {
    test('mijoz maydonlari bo\'sh, standart chegirma ID qo\'yiladi', () {
      final r = build();

      expect(r.clientId, '');
      expect(r.clientPhone, '');
      expect(r.clientName, '');
      expect(r.discountID, kNoClientDiscountId);
      expect(r.discountVat, 0);
    });
  });

  group('Mijozli chek', () {
    test('mijoz ID, telefon, ism va chegirmasi ko\'chadi', () {
      final r = build(
        slot: clientSlot(items: [makeSoldItem()], client: testClient()),
      );

      expect(r.clientId, 'client-1');
      expect(r.clientPhone, '998901234567');
      expect(r.clientName, 'Ali');
      expect(r.discountID, 'client-disc-id');
      expect(r.discountVat, 5);
      expect(r.newid, 'client-1');
    });

    test('mijozda discountId bo\'lmasa standart ID ishlatiladi', () {
      final r = build(
        slot: clientSlot(
          items: [makeSoldItem()],
          client: testClient(discountId: null),
        ),
      );

      expect(r.discountID, kNoClientDiscountId);
    });
  });

  group('Supplier tanlanganda', () {
    test('chekdagi nom supplier kompaniyasiga almashadi', () {
      final r = build(
        slot: clientSlot(items: [makeSoldItem()], client: testClient()),
        supplier: testSupplier(company: 'Alfa MChJ'),
      );

      expect(r.clientName, 'Alfa MChJ');
      // client_id o'zgarmaydi — order_pos xato bermasligi uchun
      expect(r.clientId, 'client-1');
      expect(r.supplierId, 'sup-1');
    });

    test('kompaniya nomi bo\'sh bo\'lsa supplier ismi olinadi', () {
      final r = build(
        supplier: testSupplier(company: '', name: 'Alfa'),
      );

      expect(r.clientName, 'Alfa');
    });
  });

  group('Tepa (total) chegirma turlari', () {
    test('summa rejimi: chegirma = kiritilgan summa - savat jami', () {
      DiscountTypeStatus.disTypeStatus = TpStatus.summa;
      DiscountTypeStatus.summa = 90000;
      final cart = [makeSoldItem(price: 50000, value: 2)]; // jami 100000

      final r = build(currentCart: cart, slot: clientSlot(items: cart));

      expect(r.discountID, kSummaDiscountId);
      expect(r.discountVat, -10000); // 90000 - 100000
    });

    test('foiz rejimi: mijoz foizi chekka tushadi', () {
      DiscountTypeStatus.disTypeStatus = TpStatus.discount;

      final r = build(clientDiscountPercent: 15);

      expect(r.discountID, kPercentDiscountId);
      expect(r.discountVat, 15);
    });

    test('foiz 0 bo\'lsa tepa chegirma qo\'llanmaydi', () {
      final r = build(clientDiscountPercent: 0);

      expect(r.discountID, kNoClientDiscountId);
    });

    test('build tugagach global holat discount ga qaytariladi', () {
      DiscountTypeStatus.disTypeStatus = TpStatus.summa;
      DiscountTypeStatus.summa = 50000;

      build();

      expect(DiscountTypeStatus.disTypeStatus, TpStatus.discount);
    });
  });

  group('To\'lovlar', () {
    test('to\'lovlar chekka ko\'chadi', () {
      final r = build(payments: [
        ReceiptModelPaymentType4(name: 'cash', payId: 'c', value: 40000),
        ReceiptModelPaymentType4(name: 'card', payId: 'k', value: 60000),
      ]);

      expect(r.payment.length, 2);
      expect(r.payment.map((e) => e.value).reduce((a, b) => a + b), 100000);
    });

    test('qarz (debt) bo\'lsa hasDept = true', () {
      final r = build(payments: [
        ReceiptModelPaymentType4(name: 'debt', payId: 'd', value: 100000),
      ]);

      expect(r.hasDept, isTrue);
    });

    test('qarzsiz to\'lovda hasDept = false', () {
      final r = build();

      expect(r.hasDept, isFalse);
    });

    test('katta-kichik harf farq qilmaydi (DEBT)', () {
      final r = build(payments: [
        ReceiptModelPaymentType4(name: 'DEBT', payId: 'd', value: 100000),
      ]);

      expect(r.hasDept, isTrue);
    });
  });

  group('Savat itemlari', () {
    test('oddiy itemlar chekka tushadi', () {
      final items = [
        makeSoldItem(productId: 'a', price: 1000),
        makeSoldItem(productId: 'b', price: 2000),
      ];

      final r = build(slot: clientSlot(items: items));

      expect(r.soldItemList.length, 2);
    });

    test('isDeleted = true itemlar chekka TUSHMAYDI (OFD 10.2.1)', () {
      final items = [
        makeSoldItem(productId: 'a', price: 1000),
        makeSoldItem(productId: 'b', price: 2000, isDeleted: true),
      ];

      final r = build(slot: clientSlot(items: items));

      expect(r.soldItemList.length, 1);
      expect(r.soldItemList.first.productId, 'a');
    });
  });

  group('Markirovka KM tozalash', () {
    test('(93) kripto qismi chekka ketmaydi', () {
      const raw = '0104780069000505217SERIAL(93)SECRET';
      final items = [makeSoldItem(marking: true, mark: raw)];

      final r = build(slot: clientSlot(items: items));

      expect(r.soldItemList.first.mark, isNot(contains('SECRET')));
      expect(r.soldItemList.first.mark, startsWith('01'));
    });

    test('mark bo\'lmagan itemga tegilmaydi', () {
      final r = build(slot: clientSlot(items: [makeSoldItem()]));

      expect(r.soldItemList.first.mark, isNull);
    });
  });

  group('deleted_items (o\'chirilgan mahsulotlar)', () {
    test('slot yozuvlari chekka biriktiriladi', () {
      final slot = clientSlot(
        items: [makeSoldItem()],
        deleted: [deletedItem('x')],
      );

      final r = build(slot: slot);
      final list = jsonDecode(r.deletedItemsJson) as List;

      expect(list.length, 1);
    });

    test('orphan yozuvlar ham qo\'shiladi (avval orphanlar)', () {
      final slot = clientSlot(
        items: [makeSoldItem()],
        deleted: [deletedItem('slot-item')],
      );

      final r = build(
        slot: slot,
        orphans: [deletedItem('orphan-item', checkNumber: '-')],
      );
      final list = jsonDecode(r.deletedItemsJson) as List;

      expect(list.length, 2);
    });

    test('hech narsa o\'chirilmagan bo\'lsa bo\'sh massiv', () {
      final r = build();

      expect(jsonDecode(r.deletedItemsJson), isEmpty);
    });
  });

  group('Pul maydonlari', () {
    test('sdacha, keshbek va zdacha-to-cashback ko\'chadi', () {
      final r = build(
        sdacha: 5000,
        fromPointBalance: 1200.6,
        zdachaToCashBack: 300,
      );

      expect(r.sdacha, 5000);
      expect(r.cashback, 1201); // round()
      expect(r.zdachiToCashback, 300);
    });

    test('totalPrice ko\'chadi', () {
      final r = build(totalPrice: 123456);

      expect(r.totalPrice, 123456);
    });
  });

  group('Izoh va meta maydonlar', () {
    test('izoh va ko\'rsatish bayrog\'i', () {
      final r = build(comments: 'Tez yetkazish', showComments: false);

      expect(r.comment, 'Tez yetkazish');
      expect(r.isShow, isFalse);
    });

    test('Pref dan kelgan maydonlar', () {
      final r = build();

      expect(r.posName, kPosName);
      expect(r.shopId, kShopId);
      expect(r.cashboxId, kCashboxId);
      expect(r.cashierId, kCashierId);
      expect(r.cashierName, kCashierName);
    });

    test('sotuv cheki: isRefund false, orderType sale, uploaded false', () {
      final r = build();

      expect(r.isRefund, isFalse);
      expect(r.orderType, 'sale');
      expect(r.uploaded, isFalse);
      expect(r.rejected, isFalse);
      expect(r.returnForCheck, '');
    });
  });

  group('Kassir xizmat vaqti', () {
    test('boshlanish vaqti yo\'q bo\'lsa: bo\'sh satr va 0 soniya', () {
      final r = build();

      expect(r.serviceStartedTime, '');
      expect(r.serviceDurationSeconds, 0);
      // Yopilish vaqti har doim yoziladi
      expect(r.serviceClosedTime, isNotEmpty);
    });
  });
}
