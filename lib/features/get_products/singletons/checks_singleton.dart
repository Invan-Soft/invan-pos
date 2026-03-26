import 'dart:convert';

import 'package:invan2/changes/models/discount_model.dart';
import 'package:invan2/changes/models/receipts_get_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import '../../../utils/constants/constants.dart';
import '../../../utils/helpers/helpers.dart';

class ChecksSingleton {
  static ReceiptModel4 globalToLocall(
      GlobalReceipt r, {String? cashierId, String? cashierName}) {
    Map<String, double> paymentMap = {};
    r.pays!
        .map((e) => paymentMap[e.paymentType?.name ?? ""] = (e.value ?? 0) + 0);
    ReceiptModel4 data = ReceiptModel4(
      newid: '',
supplierId: "",
      dateTimeOFD: r.dateTimeOFD,
      fiscalSign: r.fiscalSign,
      receiptSeq: r.receiptSeq,
      terminalId: r.terminalId,
      discountID: r.discount?.type ?? "",
      discountVat: (r.discount?.value ?? 0).toDouble(),
      cashierId:cashierId?? r.cashierId ?? "",
      cashierName:cashierName?? r.createdBy?.firstName ?? "",
      date: r.createTime != null
          ? DateTime.parse(r.createTime!).millisecondsSinceEpoch
          : 0,
      isRefund: r.status?.name == "paid" ? false : true,
      createdDate: r.createTime ?? "",
      externalId: r.externalId ?? "",
      totalPrice: r.totalPrice?.toDouble() ?? 0,
      uploaded: true,
      rejected: false,
      clientName: r.client?.firstName ?? "",
      clientPhone: r.client?.phoneNumber ?? "",
      clientId: r.client?.id ?? "",
      url: r.url ?? "",
      cashback: 0,
      sdacha: 0,
      returnForCheck: '',
      posName: r.cashbox?.title ?? "",
      isDonate: false,
      cashboxId: r.cashbox?.id ?? "",
      orderId: r.id ?? "",
      refundInfo: _refundInfo(
        r.terminalId ?? "",
        r.receiptSeq ?? 0,
        r.dateTimeOFD ?? "",
        r.fiscalSign ?? "",
      ).toString(),
      orderType: "Refund",
      shopId: r.shop?.id ?? "",
      userId: Pref.getString(PrefKeys.userId, ''),
    );
    data.soldItemList.addAll(_globalToLocalSoldItem(r.items ?? <ItemsGTR>[]));
    data.payment.addAll(_globalTolocalPayment(r.pays ?? <PaysGTR>[]));
    return data;
  }

  static _refundInfo(
    String terminalID,
    int receiptSeq,
    String dateTimeOFD,
    String fiscalSign,
  ) {
    if (terminalID == "" ||
        receiptSeq == 0 ||
        dateTimeOFD == 0 ||
        fiscalSign == "") {
      return null;
    }
    final Map<String, dynamic> data = {};

    data["terminalId"] = terminalID;
    data["receiptSeq"] = receiptSeq.toString();
    data["dateTime"] = dateTimeOFD.toString();
    data["fiscalSign"] = fiscalSign;
    return jsonEncode(data);
  }

  static List<ReceiptModelSoldItem4> _globalToLocalSoldItem(
    List<ItemsGTR> v,
  ) {
    return List.generate(v.length, (i) {
      // DateTime parseDate =
      //      DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(v[i].create_time);
      double vat = (v[i].newPrice ?? 0) * (v[i].vatPercentage?.toDouble() ?? 0);

      final receipt = ReceiptModelSoldItem4(
        inBox: 0,
        singleDiscount: v[i].singleDiscount?.toDouble() ?? 0,
        realPrice: v[i].price?.toDouble() ?? 0,
        onlyPrice: v[i].newPrice?.toDouble() ?? 0,
        refundItemId: v[i].id ?? "",
        barcode: v[i].barcode ?? "",
        cost: 0,
        createdTime: 0,
        mxik: v[i].mxikCode ?? "",
        price: v[i].newPrice?.toDouble() ?? 0,
        ownerType: 0,
        productId: v[i].productId ?? "",
        productName: v[i].productName ?? '',
        sku: int.parse(v[i].sku ?? "0"),
        soldBy: '',
        value: v[i].value?.toDouble() ?? 0,
        vat: vat,
        vatPercent: v[i].vatPercentage?.toDouble() ?? 0,
        tin: "",
        packageCode: v[i].packageCode,
        packageName: v[i].packageName,
        // mark: ,
        // commissionTIN: ,
        // discountPercent: ,
        // isDeleted: ,
        // isPriceChanged: ,
        // marking: ,
        sellerId: v[i].seller?.id ?? "",
        vatName: v[i].vatName ?? "",
      );
      // for (DiscountModel d in v[i].discount!) {
      DiscountGTR dGTR = v[i].discount ?? DiscountGTR();
      DiscountModel d = DiscountModel(
        idd: dGTR.type ?? "",
        name: "DiscountFromRefund",
        total: dGTR.price?.toDouble() ?? 0,
        type: dGTR.type ?? "",
        value: dGTR.value?.toDouble() ?? 0,
      );
      receipt.discount.add(d);
      // }
      return receipt;
    });
  }

  static List<ReceiptModelPaymentType4> _globalTolocalPayment(List<PaysGTR> v) {
    return List.generate(
      v.length,
      (index) => ReceiptModelPaymentType4(
        name: v[index].paymentType?.name ?? "",
        value: v[index].value?.toDouble() ?? 0,
        payId: v[index].paymentType?.id ?? "",
      ),
    );
  }
}
