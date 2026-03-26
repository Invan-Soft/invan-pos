import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:invan2/changes/services/api.dart';
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

ReceiptModel4 _copyWith(ReceiptModel4 receipt, BuildContext context) {
  final List<ReceiptModelSoldItem4> list = [];
  for (var e in receipt.soldItemList) {
    final soldItem = ReceiptModelSoldItem4(
      inBox: e.inBox,
      // unnecessary
      mark: e.mark,
      onlyPrice: e.price,
      realPrice: e.realPrice,
      ownerType: e.ownerType,
      refundItemId: e.refundItemId,
      marking: e.marking,
      soldBy: e.soldBy,
      cost: e.cost,
      createdTime: e.createdTime,
      price: e.price,
      value: e.value,
      productId: e.productId,
      productName: e.productName,
      // pricePosition: e.pricePosition,
      barcode: e.barcode,
      sku: e.sku,
      vat: (e.price * e.vatPercent) / (100 + e.vatPercent),
      mxik: e.mxik,
      discountPercent: e.discountPercent,
      vatPercent: e.vatPercent,
      // tin: e.tin,
      singleDiscount: e.singleDiscount,
      packageCode: e.packageCode,
      packageName: e.packageName,
      sellerId: e.sellerId,
      tin: e.tin,
      vatName: e.vatName,
    );
    list.add(soldItem);
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
    totalPrice: receipt.totalPrice,
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
  newReceiptModel4.payment.add(ReceiptModelPaymentType4(
    name: "cash",
    value: receipt.totalPrice,
    payId: "",
  ));

  return newReceiptModel4;
}
