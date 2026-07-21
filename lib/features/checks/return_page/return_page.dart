import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:provider/provider.dart';
import '../../../app_navigation.dart';
import '../../../widgets/alice_pincode.dart';
import 'return_page_appbar/return_page_appbar.dart';
import 'package:invan2/utils/utils.dart';
import '../../../changes/providers/return_page_provider.dart';
import 'return_page_card.dart';
import 'left/left.dart';
import 'right/right.dart';

class ReturnPage extends StatelessWidget {
  const ReturnPage({
    super.key,
    required this.receiptModel4,
  });

  final ReceiptModel4 receiptModel4;

  @override
  Widget build(BuildContext context) {
    final r = _copyWith(receiptModel4, context);
    return ChangeNotifierProvider(
      create: (_) => ReturnPageProviderr(receiptModel4: r),
      child: WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
          floatingActionButton: Pref.getBool(PrefKeys.isDevAlice, false)
              ? FloatingActionButton(
                  heroTag: null,
                  backgroundColor: Theme.of(context).primaryColor,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlicePincodePage(),
                    );
                  },
                  child: const Icon(
                    Icons.http_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
                )
              : const SizedBox(),
          backgroundColor: Theme.of(context).colorScheme.background,
          appBar: AppBar(
            elevation: 2,
            shadowColor: Colors.grey,
            leadingWidth: 0.0,
            automaticallyImplyLeading: false,
            toolbarHeight: SizeConfig.v * 9.5,
            backgroundColor: Theme.of(context).colorScheme.background,
            title: const ReturnPageAppbar(),
          ),
          body: Center(
            child: Row(
              children: [
                const ReturnPageCard(child: Left()),
                SizedBox(
                  width: 30,
                  child: Icon(
                    Icons.arrow_right_alt,
                    color: Theme.of(context).canvasColor,
                    size: SizeConfig.v * 5,
                  ),
                ),
                const ReturnPageCard(
                  child: Right(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Local DB dan original sotuv receiptining itemlarini productId bo'yicha qaytaradi.
/// Narxlar (price, realPrice, singleDiscount) API GET javobida har doim ham
/// to'g'ri qaytmasligi mumkin (masalan free gift va order-level diskontda),
/// shuning uchun bu yerda sotuv momentidagi original qiymatlarga tayanamiz.
Map<String, ReceiptModelSoldItem4> _getOriginalItemsFromLocalDB(String externalId) {
  final result = <String, ReceiptModelSoldItem4>{};
  try {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final all = box.getAll();
    final originals = all.where((r) => !r.isRefund && r.externalId == externalId).toList();
    if (originals.isNotEmpty) {
      for (final item in originals.first.soldItemList) {
        result[item.productId] = item;
      }
    }
  } catch (e) {
    // ignore
  }
  return result;
}

/// Shu checkga tegishli oldingi refundlarda qaytarilgan miqdorlarni hisoblaymiz
/// productId → qaytarilgan jami qty (dona hisobida)
Map<String, double> _getAlreadyRefundedQty(
  String originalExternalId,
  Map<String, ReceiptModelSoldItem4> originalItems,
) {
  final Map<String, double> refundedQty = {};
  try {
    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    final allRefunds = box.getAll().where((r) =>
        r.isRefund && r.returnForCheck == originalExternalId).toList();
    for (final refund in allRefunds) {
      for (final item in refund.soldItemList) {
        double dona = item.value;
        // Self-heal: eski buzilgan yozuvlar (vozvrat cheki qayta konsolidatsiya
        // bo'lib value boxValue marta oshib ketgan — 12 dona "12 blok"=144
        // bo'lib saqlangan). Belgi: qaytarilgan blok soni sotilgandan ko'p.
        final orig = originalItems[item.productId];
        if (item.saleType == 2 &&
            item.boxValue > 0 &&
            orig != null &&
            orig.boxQuantity > 0 &&
            item.boxQuantity > orig.boxQuantity) {
          dona = item.value / item.boxValue;
        }
        refundedQty[item.productId] =
            (refundedQty[item.productId] ?? 0) + dona;
      }
    }
  } catch (e) {
    // ignore
  }
  return refundedQty;
}

ReceiptModel4 _copyWith(ReceiptModel4 receipt, BuildContext context) {
  // Local DB dan original sotuv itemlarini olamiz. Narxlarni shulardan
  // tiklaymiz — API GET javobi free gift va order-level diskontda har doim
  // ham per-item discount ma'lumotini saqlamaydi, lokal sotuv esa to'g'ri saqlangan.
  final Map<String, ReceiptModelSoldItem4> originalItemsMap =
      _getOriginalItemsFromLocalDB(receipt.externalId);
  // Allaqachon qaytarilgan miqdorlarni olamiz
  final Map<String, double> alreadyRefunded =
      _getAlreadyRefundedQty(receipt.externalId, originalItemsMap);

  final List<ReceiptModelSoldItem4> list = [];
  for (var e in receipt.soldItemList) {
    final ReceiptModelSoldItem4? local = originalItemsMap[e.productId];
    // Agar local DB da original topilsa — undan foydalanamiz (API reduced bo'lmasin).
    // Topilmasa — e.value dan foydalanamiz (refund bo'lmagan holat).
    final double baseQty = local?.value ?? e.value;
    final double refundedSoFar = alreadyRefunded[e.productId] ?? 0;

    // Blok sotuv maydonlari (lokal originaldan — API ularni qaytarmaydi)
    final int boxValue = local?.boxValue ?? 0;
    final int soldBoxQuantity = local?.boxQuantity ?? 0;
    final bool hasBox =
        local?.saleType == 2 && boxValue > 0 && soldBoxQuantity > 0;

    // min() — admin paneldan qilingan refundlarni ham hisobga olamiz:
    // e.value = API dan kelgan qoldiq (refundAmount ni chegirilgan),
    // baseQty - refundedSoFar = local DB dan hisoblab topilgan qoldiq.
    //
    // Blok mahsulotda esa API value birligi ishonchsiz (blok itemda token/dona
    // aralash kelishi mumkin — 1 blok vozvratdan keyin item butunlay yo'qolib
    // qolardi), shuning uchun faqat lokal hisob ishlatiladi: sotuvdagi dona
    // soni minus shu kassada qilingan vozvratlar.
    final double remainingQty =
        hasBox ? (baseQty - refundedSoFar) : min(baseQty - refundedSoFar, e.value);
    if (remainingQty <= 0) continue; // Hammasi qaytarilgan — ro'yxatga qo'shmaymiz

    // Narxlarni local DB dan olamiz (free gift = 0, diskontli = effektiv narx).
    // Topilmasa API qiymatlariga qaytamiz.
    final double itemPrice = local?.price ?? e.price;
    final double itemRealPrice = local?.realPrice ?? e.realPrice;
    final double itemOnlyPrice = local?.onlyPrice ?? e.price;
    final double itemSingleDiscount = local?.singleDiscount ?? e.singleDiscount;

    ReceiptModelSoldItem4 makeItem(
      double qty, {
      int saleType = 1,
      int boxValue = 0,
      int boxQuantity = 0,
    }) {
      return ReceiptModelSoldItem4(
        inBox: e.inBox,
        // unnecessary
        mark: e.mark,
        onlyPrice: itemOnlyPrice,
        realPrice: itemRealPrice,
        ownerType: e.ownerType,
        refundItemId: e.refundItemId,
        marking: e.marking,
        soldBy: e.soldBy,
        cost: e.cost,
        createdTime: e.createdTime,
        price: itemPrice,
        value: qty,
        productId: e.productId,
        productName: e.productName,
        // pricePosition: e.pricePosition,
        barcode: e.barcode,
        sku: e.sku,
        vat: (itemPrice * e.vatPercent) / (100 + e.vatPercent),
        mxik: e.mxik,
        discountPercent: e.discountPercent,
        vatPercent: e.vatPercent,
        // tin: e.tin,
        singleDiscount: itemSingleDiscount,
        packageCode: e.packageCode,
        packageName: e.packageName,
        sellerId: e.sellerId,
        tin: e.tin,
        vatName: e.vatName,
        saleType: saleType,
        boxValue: boxValue,
        boxQuantity: boxQuantity,
      );
    }

    // Blok sotuv (saleType==2): qoldiqni blok va dona qatorlariga ajratamiz.
    // Blok qatori faqat butun blok qaytarish uchun — value baribir DONA hisobida
    // turadi (refund API, fiskal va DB dona bilan ishlaydi), blok faqat UI qatlami.
    final int blocksAvailable =
        hasBox ? min(soldBoxQuantity, remainingQty ~/ boxValue) : 0;
    final double blockUnits = (blocksAvailable * boxValue).toDouble();
    final double looseUnits = remainingQty - blockUnits;

    if (blocksAvailable > 0) {
      list.add(makeItem(
        blockUnits,
        saleType: 2,
        boxValue: boxValue,
        boxQuantity: blocksAvailable,
      ));
    }
    if (looseUnits > 0) {
      list.add(makeItem(looseUnits));
    }
  }

  final newReceiptModel4 = ReceiptModel4(
    supplierId: receipt.supplierId,
    dateTimeOFD: receipt.dateTimeOFD,
    fiscalSign: receipt.fiscalSign,
    receiptSeq: receipt.receiptSeq,
    discountID: receipt.discountID,
    discountVat: receipt.discountVat,
    terminalId: receipt.terminalId,
    newid: receipt.newid,
    rejected: receipt.rejected,
    createdDate: receipt.createdDate,
    refundInfo: receipt.refundInfo,
    clientPhone: receipt.clientPhone,
    cashierId: receipt.cashierId,
    cashierName: receipt.cashierName,
    date: receipt.date,
    isRefund: true,
    externalId: receipt.externalId,
    totalPrice: list.fold(0.0, (sum, e) => sum + e.price * e.value),
    uploaded: false,
    clientName: receipt.clientName,
    clientId: receipt.clientId,
    cashback: receipt.cashback,
    sdacha: receipt.sdacha,
    returnForCheck: receipt.externalId,
    posName: receipt.posName,
    isDonate: Pref.getBool('donate', false),
    commissionTIN: receipt.commissionTIN,
    cashboxId: receipt.cashboxId,
    orderId: receipt.orderId,
    orderType: receipt.orderType,
    shopId: receipt.shopId,
    userId: receipt.userId,
    url: receipt.url,
  );

  newReceiptModel4.soldItemList.clear();
  newReceiptModel4.payment.clear();
  newReceiptModel4.soldItemList.addAll(list);
  for (final p in receipt.payment) {
    newReceiptModel4.payment.add(ReceiptModelPaymentType4(
      name: p.name,
      value: p.value,
      payId: p.payId,
    ));
  }
  if (newReceiptModel4.payment.isEmpty) {
    newReceiptModel4.payment.add(ReceiptModelPaymentType4(
      name: "CASH",
      value: receipt.totalPrice,
      payId: Pref.getString(PrefKeys.cashId, ''),
    ));
  }

  return newReceiptModel4;
}
