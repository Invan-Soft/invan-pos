// Chek yig'ish: to'lov tugmasi bosilganda provider holatidan `ReceiptModel4`
// hosil qiladi.
//
// OrderingProvider4.pressPaymentButton dan ajratildi (2026-08-06) —
// tana o'zgartirilmadi, faqat provider maydonlari aniq parametrga aylandi.
//
// BU YERDA YO'Q (ataylab): BuildContext, ObjectBox saqlash, tarmoq, dialog.
// Saqlash (`ReceiptSingleton4.toOBJECTBOX`) va keyingi tozalash providerda
// qoladi — chegara `pressPaymentButton` ning o'zida ham shu joyda edi.
//
// Testlar: test/receipt_builder_test.dart

import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:invan2/changes/domain/marking/mark_cleaner.dart';
import 'package:invan2/changes/models/deleted_item_model.dart';
import 'package:invan2/changes/models/six_client_model.dart';
import 'package:invan2/changes/models/supplier_model.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/changes/services/cashier_service_time/cashier_service_time_service.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/bloc/tp_bloc.dart';
import 'package:invan2/features/home/features/home_orders/calculation_part/total_price_dialog/discount_type_status.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

class ReceiptBuilder {
  const ReceiptBuilder._();

  /// Sotuv cheki yig'adi.
  ///
  /// [isTpEdited] — "tepa" (total price) chegirmasi tahrirlanmagan bo'lsa true;
  /// global holat, provider uzatadi.
  static ReceiptModel4 build({
    required SixClientModel4 sixClient,
    required SupplierModel? selectedSupplier,
    required double? currentClientDiscountPercent,
    required List<ReceiptModelSoldItem4> currentCart,
    required num totalPrice,
    required double zdachaToCashBack,
    required double sdacha,
    required double fromPointBalance,
    required String comments,
    required bool showComments,
    required List<ReceiptModelPaymentType4> payments,
    required List<DeletedItemModel4> orphanDeletedItems,
    required bool isTpEdited,
  }) {
    ClientModel? xClient = sixClient.selectedClient;
    String clientPhone = xClient == null ? "" : xClient.phoneNumber!;
    String clientId = xClient == null ? "" : xClient.id!;
    //---------------------------------------------------------------------
    double clientDiscountVat = xClient == null ? 0 : xClient.discountValue!;
    String clientDiscountID = xClient == null
        ? "9a2aa8fe-806e-44d7-8c9d-575fa67ebefd"
        : xClient.discountId ?? "9a2aa8fe-806e-44d7-8c9d-575fa67ebefd";
    String? clientName = xClient?.firstName ?? "";

    // Supplier tanlangan bo'lsa, uning nomi chekda "Klient" o'rnida
    // ko'rsatiladi (faqat lokal — clientName API'ga yuborilmaydi,
    // client_id o'zgarmaydi, shuning uchun order_pos xato bermaydi).
    if (selectedSupplier != null) {
      clientName = selectedSupplier.supplierCompanyName.isNotEmpty
          ? selectedSupplier.supplierCompanyName
          : selectedSupplier.name;
    }

    if (DiscountTypeStatus.disTypeStatus == TpStatus.summa) {
      double totalPrice =
          ItemsSingleton.getTotalPrice(currentCart);
      clientDiscountID = "9fb3ada6-a73b-4b81-9295-5c1605e54552";
      clientDiscountVat = DiscountTypeStatus.summa - totalPrice;
    } else if (DiscountTypeStatus.disTypeStatus == TpStatus.discount) {
      if (currentClientDiscountPercent != null &&
          currentClientDiscountPercent != 0) {
        clientDiscountID = "1fe92aa8-2a61-4bf1-b907-182b497584ad";
        // `!` olib tashlandi: bu endi parametr, Dart promotion qiladi
        // (maydonda promotion yo'q edi, shuning uchun asl kodda `!` kerak edi)
        clientDiscountVat = currentClientDiscountPercent;
      }
    }
    DiscountTypeStatus.disTypeStatus = TpStatus.discount;

    double allDiscountVat = clientDiscountVat;
    String allDiscountID = clientDiscountID;
    //-----------     PREFS -----------------------------------------------
    final cashierId = Pref.getString(PrefKeys.cashierId, "not initialized");
    final cashierName = Pref.getString(PrefKeys.cashierName, "not initialized");
    final posName = Pref.getString(PrefKeys.posName, "not initialized");
    // ignore: unused_local_variable
    final donate = Pref.getDonate('donate', false);
    String supplierId = selectedSupplier?.id ?? "";
    //-------------------------------------------------------
    // Kassir xizmat vaqti: sotuv boshlanishi (savatga birinchi mahsulot
    // qo'shilgan payt) shu yerda "olinadi" (slot tozalanadi) va yopilish
    // vaqti hozir belgilanadi — order_pos body'siga "order_time" bo'lib ketadi.
    final DateTime? serviceStartedAt = CashierServiceTimeService.instance
        .takeStartedTime(sixClient.clientNumber);
    final DateTime serviceClosedAt = DateTime.now();
    final String serviceStartedTimeStr = serviceStartedAt != null
        ? DateFormat('yyyy-MM-dd HH:mm:ss').format(serviceStartedAt.toUtc())
        : "";
    final String serviceClosedTimeStr =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(serviceClosedAt.toUtc());
    final int serviceDurationSecondsVal = serviceStartedAt != null
        ? serviceClosedAt.difference(serviceStartedAt).inSeconds
        : 0;
    final receiptModel4 = ReceiptModel4(
      newid: clientId,
      zdachiToCashback: zdachaToCashBack,
      clientPhone: clientPhone,
      cashierId: cashierId,
      supplierId: supplierId,
      cashierName: cashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: false,
      externalId: "",
      createdDate:
          DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now().toUtc()),
      totalPrice: totalPrice + 0,
      discountVat: double.parse(allDiscountVat.round().toStringAsFixed(1)),
      discountID: allDiscountID,
      uploaded: false,
      rejected: false,
      clientName: clientName,
      clientId: clientId,
      cashback: fromPointBalance.round(),
      sdacha: sdacha,
      returnForCheck: "",
      posName: posName,
      isDonate: true,
      cashboxId: Pref.getString(PrefKeys.activatedPosId, ""),
      orderId: "",
      orderType: "sale",
      comment: comments,
      isShow: showComments,
      shopId: Pref.getString(PrefKeys.storeId, ""),
      userId: Pref.getString(PrefKeys.userId, ""),
      serviceStartedTime: serviceStartedTimeStr,
      serviceClosedTime: serviceClosedTimeStr,
      serviceDurationSeconds: serviceDurationSecondsVal,
    );
    receiptModel4.payment.addAll(payments);
    receiptModel4.hasDept =
        payments.any((p) => p.name.toLowerCase() == 'debt');
    // Red-delete rejimida o'chirilgan (isDeleted=true) mahsulotlar listda qoladi,
    // lekin kassir totali (getTotalPrice) ularni hisobga olmaydi. Shuning uchun
    // ularni fiskal/server/qog'oz chekka ham yubormaymiz — aks holda OFD 10.2.1
    // tenglamasi buziladi (items jami ≠ to'langan summa).
    receiptModel4.soldItemList.addAll(
      sixClient.orderedProducts.where((p) => !(p.isDeleted ?? false)),
    );

    // Savat sessiyasida o'chirilgan mahsulotlar chekka biriktiriladi —
    // order_pos "deleted_items" massivida serverga ketadi. Slot o'chirilganda
    // saqlab qolinganlar ("-" belgili, egasiz) ham shu chek bilan ketadi.
    receiptModel4.deletedItemsJson = jsonEncode(
      [...orphanDeletedItems, ...sixClient.deletedItems]
          .map((e) => e.toJson())
          .toList(),
    );

    for (var item in receiptModel4.soldItemList) {
      if (item.mark != null && item.mark!.isNotEmpty) {
        item.mark = MarkCleaner.forFiscal(item.mark!);
      }
    }
    //-------------------------------------------------------------------------
    bool isChanged = false;
    if (!isTpEdited) {
      isChanged = true;
    } else {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        if (receiptModel4.soldItemList[i].isPriceOnlyChanged ||
            receiptModel4.soldItemList[i].isPriceChanged) {
          isChanged = true;
          break;
        }
      }
    }
    if (isChanged) {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        double discountSingle =
            receiptModel4.soldItemList[i].discount.isNotEmpty
                ? receiptModel4.soldItemList[i].discount.first.total
                : 0;

        if (receiptModel4.soldItemList[i].discount.isNotEmpty) {
          if (receiptModel4.soldItemList[i].discount.first.name == 'single') {
            receiptModel4.soldItemList[i].singleDiscount =
                double.parse(discountSingle.round().toStringAsFixed(1));
          } else {
            receiptModel4.soldItemList[i].singleDiscount =
                double.parse(discountSingle.round().toStringAsFixed(1));
          }
        }
      }
      receiptModel4.discountVat = 0;
    } else {
      for (int i = 0; i < receiptModel4.soldItemList.length; i++) {
        double discountSingle =
            receiptModel4.soldItemList[i].discount.isNotEmpty
                ? receiptModel4.soldItemList[i].discount.first.total
                : 0;

        if (receiptModel4.soldItemList[i].discount.isNotEmpty) {
          if (receiptModel4.soldItemList[i].discount.first.name == 'single') {
            receiptModel4.soldItemList[i].singleDiscount =
                double.parse(discountSingle.round().toStringAsFixed(1));
          }
        }
      }
    }
    receiptModel4.discountVat =
        double.parse(receiptModel4.discountVat.round().toStringAsFixed(1));

    return receiptModel4;
  }
}
