// ignore_for_file: unused_local_variable
import 'dart:convert';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/api/api_provider.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/fiscal_service/model/last_receipt_model.dart/last_receipt_model.dart';
import 'package:invan2/utils/utils.dart';
import '../../features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_refund_model.dart';
import '../models/organization_model.dart';
import '../singletons/organization_singleton.dart';

class ReceiptApi4 {
  static Future<HttpResult> receiptCreateGroup(
    List<ReceiptModel4> list,
  ) async {
    final token = Pref.getString(PrefKeys.token, "not initialized");
    const uri = "api/v1/order_pos";
    String cashbackTypeid = Pref.getString(PrefKeys.cashbackId, '');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': "Bearer $token",
      "timezone": "-300",
      'Accept-User': 'employee',
    };
    List<Map<String, dynamic>> jsonList = [];
    List<Map<String, dynamic>> jsonListFromRefund = [];
    List<ReceiptModel4> cashbackOrders = [];
    List<Map<String, String>> zdachiToCashbackList = [];
    for (var e in list) {
      if (e.externalId.isEmpty || (e.isRefund == false && e.orderId.isEmpty)) {
        LogRepository.addLog("external id or order id are not create yet",
            where: "api/v1/orderpos");
      }
      if (e.isRefund == false) {
        jsonList.add(func(e, isServer: true).toJson());
      } else {
        jsonListFromRefund.add(func(e, isServer: true).toJson());
      }
      if (e.payment.any((element) => element.payId == cashbackTypeid)) {
        cashbackOrders.add(e);
      }
      if (e.zdachiToCashback != null &&
          e.zdachiToCashback! > 0 &&
          e.clientId.isNotEmpty) {
        zdachiToCashbackList.add(
          {
            'client_id': e.clientId,
            "total_price": e.zdachiToCashback!.toString(),
          },
        );
      }
    }
    ///////////////////////////////  cashbackOrders  ///////////////////////////////////
    for (var cashback in cashbackOrders) {
      num payValue = 0;
      for (var element in cashback.payment) {
        if (element.payId == cashbackTypeid) {
          payValue = element.value;
        }
      }
      var cashBackBody = {
        "client_id": cashback.clientId,
        "total_price": payValue,
      };
      var uriCashback = "api/v1/pay_by_loyalty/${cashback.clientId}";

      HttpResult res = await ApiProvider.putResponse(
        path: uriCashback,
        body: jsonEncode(cashBackBody),
        headers: headers,
      );
      if (!res.isSuccess) {
        jsonList.remove(cashback);
      }
    }
    /////////////////////////////////////////////////////////////

    ///////////////////////////////  zdachiToCashback ///////////////////////////////////
    for (var zdachiToCashback in zdachiToCashbackList) {
      var zdachiToCashbackBody = {
        "total_price": num.parse(zdachiToCashback["total_price"].toString()),
      };
      var uriCashback = "api/v1/add_loyalty/${zdachiToCashback["client_id"]}";

      HttpResult res = await ApiProvider.putResponse(
        path: uriCashback,
        body: jsonEncode(zdachiToCashbackBody),
        headers: headers,
      );
    }
    /////////////////////////////////////////////////////////////
    final body = jsonEncode({"order": jsonList});
    Pref.setString("bodyForDiscountError", body);
    HttpResult res = await ApiProvider.postResponse(
      path: uri,
      body: body,
      headers: headers,
    );
    return res;
  }

  static Future<HttpResult> receiptCreateGrouppForRefund(
    ReceiptModel4 refundedRec,
  ) async {
    final token = Pref.getString(PrefKeys.token, "not initialized");
    var refundPath = "api/v1/refund_for_pos_new";
    final headers = <String, String>{
      'Content-Type': "application/json",
      'Authorization': "Bearer $token",
      "timezone": "-300",
    };
    final headersForRefund = <String, String>{
      'Content-Type': "application/json",
      'Authorization': "Bearer $token",
      "timezone": "-300",
    };
    String shopId = Pref.getString(PrefKeys.storeId, '');
    String posId = Pref.getString(PrefKeys.activatedPosId, '');
    var refundForPosBody = {
      "shop_id": shopId,
      "cashbox_id": posId,
      "comment": refundedRec.comment,
      "external_id": refundedRec.externalId,
      "url": refundedRec.url
    };
    HttpResult creatRefundCheck = await ApiProvider.postResponse(
      path: refundPath,
      body: jsonEncode(refundForPosBody),
      headers: headersForRefund,
    );
    if (creatRefundCheck.statusCode == 201) {
      var uri =
          "api/v1/refund_order_items/${refundedRec.orderId}?cashbox_id=${Pref.getString(PrefKeys.activatedPosId, '')}&cashier_id=${refundedRec.cashierId}";
      var body = funcToRefund(refundedRec);
      HttpResult res = await ApiProvider.postResponse(
        path: uri,
        body: jsonEncode(body),
        headers: headers,
      );
      return res;
    } else {
      return creatRefundCheck;
    }
  }

  static ReceiptModel4 func(ReceiptModel4 r, {bool isServer = false}) {
    final Map<String, ReceiptModelPaymentType4> paymentMap = {};
    bool hasClick = false;
    bool hasUzum = false;
    bool hasPayme = false;
    bool hasDebt = false;

    final clickId = Pref.getString(PrefKeys.clickId, "");
    final uzumId = Pref.getString(PrefKeys.uzumId, "");
    final paymeId = Pref.getString(PrefKeys.paymeId, "");
    final debtId = Pref.getString(PrefKeys.debtId, "");
    String finalComment = r.comment?.trim() ?? "";
    final invoiceId = Pref.getString("invoice_id_for_order", "");
    if (invoiceId.isNotEmpty) {
      if (finalComment.isEmpty) {
        finalComment = "$invoiceId";
      } else {
        finalComment = "$finalComment | $invoiceId";
      }
      Pref.removeWithKey("invoice_id_for_order");
    }
    for (final p in r.payment) {
      String pid = p.payId.replaceFirst('@', '');
      final amount = p.value;

      if (pid == clickId) hasClick = true;
      if (pid == uzumId) hasUzum = true;
      if (pid == paymeId) hasPayme = true;
      if (pid == debtId) hasDebt = true;

      if (!isServer) {
        pid = p.payId;
      }

      if (paymentMap.containsKey(pid)) {
        paymentMap[pid]!.value += amount;
      } else {
        paymentMap[pid] = ReceiptModelPaymentType4(
          name: p.name,
          payId: pid,
          value: amount,
        );
      }
    }

    final receipt = ReceiptModel4(
      newid: r.newid,
      url: r.url,
      rejected: r.rejected,
      discountID: r.discountID,
      discountVat: r.discountVat,
      dateTimeOFD: r.dateTimeOFD,
      fiscalSign: r.fiscalSign,
      receiptSeq: r.receiptSeq,
      terminalId: r.terminalId,
      cashback: r.cashback,
      createdDate: r.createdDate,
      cashierId: r.cashierId,
      cashierName: r.cashierName,
      clientId: r.clientId,
      supplierId: r.supplierId,
      clientName: r.clientName,
      clientPhone: r.clientPhone,
      date: r.date,
      isRefund: r.isRefund,
      posName: r.posName,
      externalId: r.externalId,
      returnForCheck: r.returnForCheck,
      sdacha: r.sdacha,
      totalPrice: r.totalPrice,
      uploaded: r.uploaded,
      refundInfo: r.refundInfo,
      zdachiToCashback: r.zdachiToCashback,
      hasClick: hasClick,
      isDonate: Pref.getBool('donate', false),
      hasUzum: hasUzum,
      hasPayme: hasPayme,
      orderId: r.orderId,
      cashboxId: Pref.getString(PrefKeys.activatedPosId, ""),
      orderType: "sale",
      shopId: Pref.getString(PrefKeys.storeId, ""),
      userId: Pref.getString(PrefKeys.userId, ""),
      comment: finalComment,
      cardNumber: r.cardNumber,
      cardType: r.cardType,
      pptId: r.pptId,
    );

    receipt.soldItemList.addAll(r.soldItemList);
    receipt.payment.addAll(paymentMap.values);
    return receipt;
  }

  static List<ReceiptModelPaymentType4> setPaymentList(
    Map<String, ReceiptModelPaymentType4> map,
  ) {
    return map.entries.map((e) => e.value).toList();
  }

///////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////REFUND`S INFO////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////
  static Map<String, dynamic> funcToRefund(ReceiptModel4 r) {
    final Map<String, ReceiptModelPaymentType4> refundMap = {};

    for (var element in r.payment) {
      final name = element.name;
      if (refundMap.containsKey(name)) {
        refundMap[name]!.value += element.value;
      } else {
        refundMap[name] = ReceiptModelPaymentType4(
            name: name, value: element.value, payId: element.payId);
      }
    }

    List<RefundedReceipt> refundedProducts = [];
    for (var element in r.soldItemList) {
      RefundedReceipt reseipt = RefundedReceipt(
        id: element.refundItemId,
        price: element.price,
        quantity: element.value,
      );
      refundedProducts.add(reseipt);
    }

    List<ItemsI2> i2 = refundedProducts
        .map((e) => ItemsI2(id: e.id, price: e.price, quantity: e.quantity))
        .toList();

    List<PaymentsI2> p2 = refundMap.values
        .map((e) => PaymentsI2(paymentTypeId: e.payId, value: e.value))
        .toList();

    RefundMI2 body = RefundMI2(
      items: i2,
      payments: p2,
      userId: Pref.getString(PrefKeys.userId, "not initialized"),
    );
    return body.toJson();
  }
}

class RefundMI2 {
  List<ItemsI2>? items;
  List<PaymentsI2>? payments;
  String? userId;

  RefundMI2({
    this.items,
    this.payments,
    this.userId,
  });

  RefundMI2.fromJson(Map<String, dynamic> json) {
    if (json['items'] != null) {
      items = <ItemsI2>[];
      json['items'].forEach((v) {
        items!.add(ItemsI2.fromJson(v));
      });
    }
    if (json['payments'] != null) {
      payments = <PaymentsI2>[];
      json['payments'].forEach((v) {
        payments!.add(PaymentsI2.fromJson(v));
      });
    }
    if (json['user_id'] != null) {
      userId = json['user_id'];
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (items != null) {
      data['items'] = items!.map((v) => v.toJson()).toList();
    }
    if (payments != null) {
      data['payments'] = payments!.map((v) => v.toJson()).toList();
    }
    if (userId != null) {
      data['user_id'] = userId;
    }
    return data;
  }
}

class ItemsI2 {
  num? price;
  num? quantity;
  String? id;

  ItemsI2({this.quantity, this.id, required this.price});

  ItemsI2.fromJson(Map<String, dynamic> json) {
    quantity = json['quantity'];
    id = json['id'];
    price = json['price'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['quantity'] = quantity;
    data['id'] = id;
    data['price'] = price;
    return data;
  }
}

class PaymentsI2 {
  String? paymentTypeId;
  num? value;

  PaymentsI2({this.paymentTypeId, this.value});

  PaymentsI2.fromJson(Map<String, dynamic> json) {
    paymentTypeId = json['payment_type_id'];
    value = json['value'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['payment_type_id'] = paymentTypeId;
    data['value'] = value;
    return data;
  }
}
