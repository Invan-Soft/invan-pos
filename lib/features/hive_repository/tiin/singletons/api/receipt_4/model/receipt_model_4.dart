import 'package:invan2/changes/models/product_discount_model.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:objectbox/objectbox.dart';
import 'package:invan2/changes/models/discount_model.dart';

import '../../../../../../../changes/services/api/api_provider.dart';
import '../../../../../../../utils/helpers/helpers.dart';

@Entity()
class ReceiptModel4 {
  int id = 0;
  String newid;
  String cashierId;
  String cashierName;
  int date;
  bool isRefund;
  double totalPrice;
  bool uploaded;
  bool rejected;
  String clientName;
  String clientPhone;
  int cashback;
  double sdacha;
  String returnForCheck;
  String posName;
  double? zdachiToCashback;
  String? refundInfo;
  String? commissionTIN;
  bool hasClick = false;
  bool hasUzum = false;
  bool hasPayme = false;
  bool hasDept = false;
  String? terminalId;
  int? receiptSeq;
  String? dateTimeOFD;
  String? fiscalSign;
  String orderId;
  String createdDate;
  String cashboxId;
  String externalId;
  String clientId;
  String supplierId;
  String discountID;
  double discountVat;
  String orderType;
  String shopId;
  String userId;
  final soldItemList = ToMany<ReceiptModelSoldItem4>();
  final payment = ToMany<ReceiptModelPaymentType4>();
  bool? isDonate;
  String? comment;
  bool? isShow = true;
  String? url;

  ReceiptModel4({
    required this.createdDate,
    required this.orderId,
    required this.cashboxId,
    required this.externalId,
    required this.orderType,
    required this.shopId,
    required this.userId,
    required this.discountVat,
    required this.discountID,
    this.url,
    this.terminalId,
    this.receiptSeq,
    this.dateTimeOFD,
    this.fiscalSign,
    this.zdachiToCashback,
    required this.newid,
    required this.cashierId,
    required this.cashierName,
    required this.date,
    required this.isRefund,
    required this.totalPrice,
    required this.uploaded,
    required this.rejected,
    required this.clientName,
    required this.clientPhone,
    required this.clientId,
    required this.supplierId,
    required this.cashback,
    required this.sdacha,
    required this.returnForCheck,
    required this.posName,
    this.refundInfo,
    this.commissionTIN,
    this.hasClick = false,
    this.hasUzum = false,
    this.hasPayme = false,
    this.isShow,
    this.comment,
    required this.isDonate,
  });

  thePayment() => payment;

  factory ReceiptModel4.fromJson(Map<String, dynamic> json) {

    final orderJson =
        json['order'] is List<dynamic>
            ? (json['order'] as List<dynamic>).isNotEmpty
                ? json['order'][0] as Map<String, dynamic>
                : {}
            : {};

    // Items (soldItemList) ni olish
    final items =
        (orderJson['items'] as List<dynamic>?)?.map((item) {
          final itemJson = item as Map<String, dynamic>;
          return ReceiptModelSoldItem4(
            inBox: itemJson['inBox'] ?? 0,
            barcode: itemJson['product_barcode'] ?? "",
            sku: int.tryParse(itemJson['product_sku']?.toString() ?? "0") ?? 0,
            vatPercent: (itemJson['vat_percentage'] as num?)?.toDouble() ?? 0.0,
            vat: itemJson['vat']?.toDouble() ?? 0.0,
            mxik: itemJson['product_mxik'] ?? "",
            tin: itemJson['tin'] ?? "",
            onlyPrice: (itemJson['price'] as num?)?.toDouble() ?? 0.0,
            realPrice: (itemJson['price'] as num?)?.toDouble() ?? 0.0,
            price: (itemJson['price'] as num?)?.toDouble() ?? 0.0,
            cost: itemJson['cost']?.toDouble() ?? 0.0,
            vatName: itemJson['vat_name'] ?? "",
            createdTime: itemJson['createdTime'] ?? 0,
            value: (itemJson['value'] as num?)?.toDouble() ?? 0.0,
            productId: itemJson['product_id'] ?? "",
            productName: itemJson['product_name'] ?? "",
            sellerId: itemJson['seller_id'] ?? "",
            soldBy: itemJson['soldBy'] ?? "",
            singleDiscount:
                (itemJson['single_item_discount'] as num?)?.toDouble() ?? 0.0,
            ownerType: itemJson['ownerType'] ?? 0,
            packageCode: itemJson['package_code'],
            packageName: itemJson['package_name'],
          );
        }).toList() ??
        [];

    // Pays (payment) ni olish
    final paysJson = orderJson['pays'] as Map<String, dynamic>?;
    final pays =
        (paysJson?['pays'] as List<dynamic>?)?.map((pay) {
          final payJson = pay as Map<String, dynamic>;
          return ReceiptModelPaymentType4(
            name: payJson['name'] ?? "",
            payId: payJson['payment_type_id'] ?? "",
            value: (payJson['value'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList() ??
        [];

    return ReceiptModel4(
        createdDate: orderJson['created_date'] ?? "",
        orderId: orderJson['id'] ?? "",
        cashboxId: orderJson['cashbox_id'] ?? "",
        externalId: orderJson['external_id'] ?? "",
        orderType: orderJson['order_type'] ?? "sale",
        shopId: orderJson['shop_id'] ?? "",
        userId: orderJson['user_id'] ?? "",
        discountVat:
            (orderJson['order_discount']?['value'] as num?)?.toDouble() ?? 0.0,
        discountID: orderJson['order_discount']?['type'] ?? "",
        url: orderJson['url'],
        terminalId: orderJson['terminal_id'],
        receiptSeq: orderJson['receipt_seq'],
        dateTimeOFD: orderJson['date_time'],
        fiscalSign: orderJson['fiscal_sign'],
        zdachiToCashback: (orderJson['zdachi_to_cashback'] as num?)?.toDouble(),
        newid: orderJson['client_id'] ?? "",
      supplierId: orderJson['supplier_id'] ?? "",
        cashierId: orderJson['cashier_id'] ?? "",
        cashierName: orderJson['cashier_name'] ?? "",
        date: orderJson['date'] ?? 0,
        isRefund: orderJson['is_refund'] ?? false,
        totalPrice: (orderJson['total_price'] as num?)?.toDouble() ?? 0.0,
        uploaded: orderJson['uploaded'] ?? false,
        rejected: orderJson['rejected'] ?? false,
        clientName: orderJson['client_name'] ?? "",
        clientPhone: orderJson['phone_number'] ?? "",
        clientId: orderJson['client_id'] ?? "",
        cashback: orderJson['cashback'] ?? 0,
        sdacha: (orderJson['sdacha'] as num?)?.toDouble() ?? 0.0,
        returnForCheck: orderJson['return_for_check'] ?? "",
        posName: orderJson['pos_name'] ?? "",
        refundInfo: orderJson['refund_info'],
        commissionTIN: orderJson['commissionTIN'],
        hasClick: orderJson['has_click'] ?? false,
        hasUzum: orderJson['has_uzum'] ?? false,
        hasPayme: orderJson['has_payme'] ?? false,
        isShow: orderJson['is_show'],
        comment: orderJson['comment'],
        isDonate: orderJson['is_donate'] ?? false,
      )
      ..soldItemList.addAll(items)
      ..payment.addAll(pays);
  }

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> paymentJsonList = [];
    List<Map<String, dynamic>> soldItemJsonList = [];

    for (var e in payment) {
      paymentJsonList.add(e.toJson());
    }
    for (var e in soldItemList) {
      e.orderId = orderId;
      soldItemJsonList.add(e.toJson());
    }
    Map<String, dynamic> json = {
      "comment": comment,
      "user_id": userId,
      "url": url,
      "terminal_id": terminalId,
      "receipt_seq": receiptSeq,
      "date_time": dateTimeOFD,
      "fiscal_sign": fiscalSign,
      "cashbox_id": cashboxId,
      "external_id": externalId,
      "client_id": clientId,
      "supplier_id":supplierId,
      "id": orderId,
      "order_type": "sale",
      "shop_id": shopId,
      "items": soldItemJsonList,
      "created_date": createdDate,
      "order_discount": {
        "order_id": orderId,
        "type": discountID,
        "value": discountVat,
      },
      "pays": {
        "order_id": orderId,
        "pays": paymentJsonList,
        if (Pref.getBool(PrefKeys.withOFD, false))
          "qr_code_url":
              "${ApiProvider.imageUrl}31129fb7-b4cf-4df5-8b58-171c70ca33c4.html",
      },
    };
    return json;
  }

  Map<String, dynamic> toJsonForTest() {
    List<Map<String, dynamic>> paymentJsonList = [];
    List<Map<String, dynamic>> soldItemJsonList = [];

    for (var e in payment) {
      paymentJsonList.add(e.toJson());
    }
    for (var e in soldItemList) {
      e.orderId = orderId;
      soldItemJsonList.add(e.toJson());
    }

    Map<String, dynamic> json = {
      "comment": comment,
      "user_id": userId,
      'phone_number': clientPhone,
      'client_id': newid,
      "supplier_id":supplierId,
      "cashback_phone": clientPhone,
      "cashier_id": cashierId,
      "cashier_name": cashierName,
      "date": date,
      "is_refund": isRefund,
      "is_self": true,
      "discount_id": discountID,
      "discount_vat": discountVat,
      "service_value": 0,
      "total_price": totalPrice,
      // "user_id": 10,
      "point_balance": 11611,
      "currency": "uzs",
      "zdachi_to_cashback": zdachiToCashback ?? 0,
      "refund_info": refundInfo,
      "commissionTIN": commissionTIN,
      "has_click": hasClick,
      "has_uzum": hasUzum,
      "has_payme": hasPayme,
      'is_donate': isDonate ?? false,
      "terminal_id": terminalId,
      "receipt_seq": receiptSeq,
      "date_time": dateTimeOFD,
      "fiscal_sign": fiscalSign,
      "cashbox_id": cashboxId,
      "external_id": externalId,
      "id": orderId,
      "order_type": "sale",
      "shop_id": shopId,
      "items": soldItemJsonList,
      "created_date": createdDate,
      "order_discount": {
        "order_id": orderId,
        "type": "9a2aa8fe-806e-44d7-8c9d-575fa67ebefd",
        "value": 10,
      },
      "pays": {
        "order_id": orderId,
        "pays": paymentJsonList,
        if (Pref.getBool(PrefKeys.withOFD, false))
          "qr_code_url":
              "${ApiProvider.imageUrl}31129fb7-b4cf-4df5-8b58-171c70ca33c4.html",
      },
    };
    return json;
  }
}

@Entity()
class ReceiptModelPaymentType4 {
  int id = 0;
  String name;
  String payId;
  double value;

  ReceiptModelPaymentType4({
    required this.name,
    required this.payId,
    required this.value,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      // "name": name,
      "payment_type_id": payId,
      "value": value,
    };
    return json;
  }
}

@Entity()
class ReceiptModelSoldItem4 {
  //=============================
  final productDiscount = ToMany<ProductDiscountModel>();
  final discount = ToMany<DiscountModel>();
  String orderId = "";
  String? refundItemId = "";
  double price;
  double realPrice;
  double onlyPrice;
  double singleDiscount;
  String barcode;
  String productId;
  String mxik;
  String productName;
  int sku;
  String sellerId;
  double cost;
  double? totalDiscountPrice;
  double value;
  String vatName;
  double vat;
  double vatPercent;
  String? packageCode;
  String? packageName;
  String? commissionTIN;
  bool isPriceChanged = false;
  bool isPriceOnlyChanged = false;
  bool isKg = false;

  int createdTime;
  int inBox;
  String? tin;
  bool marking;
  String? mark;
  bool? mxikError;
  double? discountPercent;
  bool? isDeleted;
  String soldBy;
  int? ownerType;
  int id = 0;
  bool isFreeGift;


  ReceiptModelSoldItem4({
    required this.inBox,
    required this.barcode,
    required this.sku,
    required this.vatPercent,
    required this.vat,
    required this.mxik,
    required this.tin,
    required this.onlyPrice,
    required this.realPrice,
    required this.price,
    required this.cost,
    required this.vatName,
    required this.createdTime,
    required this.value,
    required this.productId,
    required this.productName,
    required this.sellerId,
    required this.soldBy,
    required this.singleDiscount,
    required this.ownerType,
    this.isDeleted,
    this.commissionTIN,
    this.mxikError,
    this.totalDiscountPrice,
    this.mark,
    this.refundItemId,
    this.marking = false,
    this.discountPercent,
    this.isPriceChanged = false,
    this.isPriceOnlyChanged = false,
    this.isKg = false,
    this.packageCode,
    this.packageName,
    this.isFreeGift = false,
  });

  Map<String, dynamic> toJson() {
    List<Map<String, dynamic>> discounts = [];
    for (var d in productDiscount) {
      discounts.add({'discount_name': d.name, 'value': d.total});
    }
    Map<String, dynamic> json = {
      "product_name": productName,
      "value": value,
      "order_id": orderId,
      "price": onlyPrice,
      "product_barcode": barcode,
      "product_id": productId,
      "product_mxik": mxik,
      "package_code": packageCode,
      "product_sku": sku.toString(),
      "seller_id": sellerId,
      "total_discount_price": 0,
      "vat_name": vatName,
      "vat_percentage": vatPercent,
      'single_item_discount': singleDiscount,
      'discounts': discounts,
    };
    return json;
  }

  Map<String, dynamic> toAllJson() {
    List<Map<String, dynamic>> discounts = [];
    List<Map<String, dynamic>> productDiscounts = [];
    for (var e in discount) {
      discounts.add(e.toJson());
    }
    for (var e in productDiscount) {
      productDiscounts.add(e.toJson());
    }
    Map<String, dynamic> json = {
      "product_name": productName,
      "value": value,
      "order_id": orderId,
      "price": realPrice,
      "product_barcode": barcode,
      "product_id": productId,
      "product_mxik": mxik,
      "product_sku": sku.toString(),
      "seller_id": sellerId,
      "total_discount_price": 0,
      "vat_name": vatName,
      "vat_percentage": vatPercent,
      'single_item_discount': singleDiscount,
      "inBox": inBox,
      "barcode": barcode,
      "sku": sku,
      "vatPercent": vatPercent,
      "vat": vat,
      "mxik": mxik,
      "tin": tin,
      "onlyPrice": onlyPrice,
      "realPrice": realPrice,
      "cost": cost,
      "vatName": vatName,
      "createdTime": createdTime,
      "productId": productId,
      "productName": productName,
      "sellerId": sellerId,
      "soldBy": soldBy,
      "singleDiscount": singleDiscount,
      "isDeleted": isDeleted,
      "commissionTIN": commissionTIN,
      "mxikError": mxikError,
      "totalDiscountPrice": totalDiscountPrice,
      "mark": mark,
      "refundItemId": refundItemId,
      "marking ": marking,
      "discountPercent": discountPercent,
      "isPriceChanged ": isPriceChanged,
      "isPriceOnlyChanged": isPriceOnlyChanged,
      "packageCode": packageCode,
      "packageName": packageName,
    };
    return json;
  }
}

@Entity()
class ReceiptModelOFD4 {
  int id = 0;
  int? receiptSeq;
  int? dateTime;
  String? terminalId;
  String? fiscalSign;

  ReceiptModelOFD4({
    this.dateTime,
    this.fiscalSign,
    this.receiptSeq,
    this.terminalId,
  });

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {
      "terminal_id": terminalId,
      "fiscal_sign": fiscalSign,
      "receipt_seq": receiptSeq,
      "date_time": dateTime,
    };
    return json;
  }

  factory ReceiptModelOFD4.fromJson(Map<String, dynamic> json) =>
      ReceiptModelOFD4(
        dateTime: json["date_time"],
        fiscalSign: json["fiscal_sign"],
        receiptSeq: json["receipt_seq"],
        terminalId: json["terminal_id"],
      );
}
