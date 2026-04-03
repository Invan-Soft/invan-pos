import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/product/sale_item_model.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/changes/services/receipt_api_4.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/singleton/shift_singleton_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/utils/utils.dart';
import 'package:objectbox/objectbox.dart';
import '../../../../../../../changes/services/app_constants.dart';
import 'package:uuid/uuid.dart';

import '../../../../../../../utils/util_functions.dart';

class ReceiptSingleton4 {
  static Future<void> toOBJECTBOX(
    ReceiptModel4 receiptModel4, {
    CommunicatorRESPONSE? communicatorRECEIPT,
    num? clientBalance,
  }) async {
    receiptModel4 = consolidateSoldItems(receiptModel4);

    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    int i = box.put(receiptModel4);
    receiptModel4.externalId = await getCheckNo();
    receiptModel4.id = i;

    if (!receiptModel4.isRefund) {
      receiptModel4.orderId = const Uuid().v7();
    }

    final refundInfo = receiptModel4.refundInfo;
    if (refundInfo != null && refundInfo.isNotEmpty) {
      try {
        final decoded = jsonDecode(refundInfo);
        if (decoded is Map<String, dynamic>) {
          Info info = Info.fromJson(decoded);
          receiptModel4.terminalId = info.terminalId;
          receiptModel4.receiptSeq = int.tryParse(info.receiptSeq ?? "0") ?? 0;
          receiptModel4.dateTimeOFD = info.dateTime ?? "";
          receiptModel4.fiscalSign = info.fiscalSign;
        } else {
          if (kDebugMode) {
            print("❌ refundInfo noto‘g‘ri formatda (Map emas)");
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print("❌ refundInfo JSON parse qilishda xatolik: $e");
        }
      }
    }

    box.put(receiptModel4, mode: PutMode.update);
    if (receiptModel4.isRefund) {
      ShiftSingleton4.updateShiftOnRefund(receiptModel4.payment);
    } else {
      double zdachaToCashBack = receiptModel4.zdachiToCashback ?? 0;
      ShiftSingleton4.updateTheShift(receiptModel4.payment, zdachaToCashBack,
          countDiscounts(receiptModel4));
    }

    bool doubleReceipt = Pref.getBool(PrefKeys.doubleReceipt, false);
    if (doubleReceipt) {
      int n = Pref.getInt(PrefKeys.restaurantReceiptNo, 1);
      await Pref.setInt(PrefKeys.restaurantReceiptNo, n == 999 ? 1 : n + 1);
      await PrintingMethods.printCheck(
        receiptModel4,
        receiptModel4.sdacha,
        incomInfo: communicatorRECEIPT?.info,
        method: communicatorRECEIPT?.method,
        itemInfo: communicatorRECEIPT?.itemInfo,
        clientBalance: clientBalance,
      );
    } else {
      await PrintingMethods.printCheck(
        receiptModel4,
        receiptModel4.sdacha,
        incomInfo: communicatorRECEIPT?.info,
        method: communicatorRECEIPT?.method,
        itemInfo: communicatorRECEIPT?.itemInfo,
        clientBalance: clientBalance,
      );
    }
  }

  static ReceiptModel4 consolidateSoldItems(ReceiptModel4 receiptModel4) {
    Map<String, ReceiptModelSoldItem4> uniqueItems = {};

    for (ReceiptModelSoldItem4 r in receiptModel4.soldItemList) {
      if (uniqueItems.containsKey(r.productId)) {
        uniqueItems[r.productId]!.value += r.value;
      } else {
        uniqueItems[r.productId] = r;
      }
    }

    receiptModel4.soldItemList.clear();
    receiptModel4.soldItemList.addAll(uniqueItems.values.toList());
    return receiptModel4;
  }

  static Future<String> getCheckNo() async {
    int i = Pref.getInt(PrefKeys.checkNo, 1);
    await Pref.setInt(PrefKeys.checkNo, i + 1);
    String charcter = Pref.getString(PrefKeys.checkId, "");
    return "$charcter$i";
  }

  /*static Map<String, dynamic> saleOnOFD(ReceiptModel4 incomingReceipt) {
    // print('========================================================');
    // print(jsonEncode(incomingReceipt));
    ReceiptModel4 receipt = ReceiptApi4.func(incomingReceipt);

    // print('========================================================');
    // print(jsonEncode(receipt));
    // ignore: unused_local_variable
    String inn = Pref.getString(PrefKeys.organizationINN, "not initialized");
    int cardIndex = receipt.payment.indexWhere(
          (element) => element.name == "card",
    );
    int clickIndex = receipt.payment.indexWhere(
          (element) => element.name == "click",
    );
    int paymeIndex = receipt.payment.indexWhere(
          (element) => element.name == "payme",
    );
    int uzumIndex = receipt.payment.indexWhere(
          (element) => element.name == "uzum",
    );
    int cashIndex = receipt.payment.indexWhere(
          (element) => element.name == "cash",
    );

    double receivedCashValue =
    cashIndex >= 0 ? (receipt.payment[cashIndex].value * 100) : 0;
    double receivedCardValue =
    cardIndex >= 0 ? (receipt.payment[cardIndex].value * 100) : 0;

    receivedCardValue +=
    clickIndex >= 0 ? (receipt.payment[clickIndex].value * 100) : 0;
    receivedCardValue +=
    paymeIndex >= 0 ? (receipt.payment[paymeIndex].value * 100) : 0;
    receivedCardValue +=
    uzumIndex >= 0 ? (receipt.payment[uzumIndex].value * 100) : 0;

    //TOKEN EPOSNIKI

    String token = "DXJFX32CN1296678504F2";
    String staff = Pref.getString(PrefKeys.cashierName, "not initialized");
    String? compname =
    Pref.getString(PrefKeys.organizationName, "not initialized");
    String? companyAdress =
    Pref.getString(PrefKeys.serviceAddress, "not initialized");
    if (receipt.refundInfo == null || receipt.refundInfo == 'null') {
      receipt.refundInfo = null;
    }
    int itemsLen = receipt.soldItemList.length;
    String terId = Pref.getString(PrefKeys.terminalID, '');
    double totalPrice = ItemsSingleton.getOfdTotalPrice(receipt.soldItemList);

    Map<String, dynamic> receiptMap = {
      'token': token,
      'method': receipt.isRefund
          ? 'refund'
          : Pref.getBool("credit", false) == true
          ? "credit"
          : Pref.getBool("advance", false) == true
          ? "advance"
          : 'sale',
      "staffName": staff,
      "companyName": compname,
      "companyAddress": companyAdress,
      "printerSize": 80,
      // "companyINN": inn,
      "refundInfo": _refundInfo(receipt),
      "senderInfo": {
        "name": "Invan",
        "sn": Pref.getString(PrefKeys.serialNumber, ""),
        "version": AppConstants.version,
      },
      "otherInfo": {
        "terminalID": terId,
      },
      "params": {
        if (!receipt.isRefund) ...{'paycheckNumber': receipt.externalId},
        "receivedCash": receivedCashValue,
        "receivedCard": receivedCardValue,
        "receivedClick": receipt.hasClick,
        "receivedUzum": receipt.hasUzum,
        "receivedPayme": receipt.hasPayme,
        "receivedDept": receipt.hasDept,
        "externalInfo": {
          "qrPaymentProvider": Pref.getInt('epayPay_Id', 0).toString(),
          "qrPaymentID": Pref.getString('epay_Id', "").toString(),
          "phoneNumber": Pref.getString('epay_phone', "").toString(),
          "cardType": Pref.getInt('card_type', 0),
        },
        "items": receipt.soldItemList.map((e) {
          double discount = _countDiscountOFD(
            e,
            cashback: receipt.cashback,
            len: itemsLen,
          );
          double other = _countOtherOFD(
            e,
            cashback: receipt.cashback,
            totalPrice: totalPrice,
          );
          num price = _countPrice(e);
          return SalingItemModel(
                  id: e.productId,
                  tin: e.commissionTIN,
                  label: e.mark ?? '',
                  amount: e.value * 1000,
                  barcode: e.barcode,
                  classCode: e.mxik,
                  name: e.productName,
                  discount: discount,
                  ownerType: e.ownerType,
                  other: other,
                  vat: _countVat(e.price, e.vatPercent, e.value, other / 100),
                  vatPercent: e.vatPercent,
                  price: price,
                  packageCode: e.packageCode,
                  packageName: e.packageName)
              .toJson();
        }).toList(),
      },
    };
    return receiptMap;
  }*/

  static Map<String, dynamic> saleOnOFD(ReceiptModel4 incomingReceipt) {
    ReceiptModel4 receipt = ReceiptApi4.func(incomingReceipt);

    final clickId = Pref.getString(PrefKeys.clickId, "");
    final uzumId = Pref.getString(PrefKeys.uzumId, "");
    final paymeId = Pref.getString(PrefKeys.paymeId, "");
    final cashId = Pref.getString(PrefKeys.cashId, "cash");
    final cashbackId = Pref.getString(PrefKeys.cashbackId, "cash");

    double receivedCashValue = 0;
    double receivedCardValue = 0;
    double otherValue = 0;
    double cashbackValue = 0;

    for (var p in receipt.payment) {
      final id = p.payId;
      if (id == cashId) {
        receivedCashValue += p.value * 100;
      } else if (id == cashbackId) {
        cashbackValue += p.value;
      } else if ((id.replaceFirst('@', '') == clickId &&
              p.name.toUpperCase() == 'CLICK QR') ||
          (id.replaceFirst('@', '') == paymeId &&
              p.name.toUpperCase() == 'PAYME QR') ||
          (id.replaceFirst('@', '') == uzumId &&
              p.name.toUpperCase() == 'UZUM QR')) {
        otherValue += p.value;
      } else {
        receivedCardValue += p.value * 100;
      }
    }
    receipt.cashback = cashbackValue.round();

    String token = "DXJFX32CN1296678504F2";
    String staff = Pref.getString(PrefKeys.cashierName, "not initialized");
    String? compname =
        Pref.getString(PrefKeys.organizationName, "not initialized");
    String? companyAdress =
        Pref.getString(PrefKeys.serviceAddress, "not initialized");

    if (receipt.refundInfo == null || receipt.refundInfo == 'null') {
      receipt.refundInfo = null;
    }

    int itemsLen = receipt.soldItemList.length;
    String terId = Pref.getString(PrefKeys.terminalID, '');
    double totalPrice = ItemsSingleton.getOfdTotalPrice(receipt.soldItemList);

    Map<String, dynamic> receiptMap = {
      'token': token,
      'method': receipt.isRefund
          ? 'refund'
          : Pref.getBool("credit", false) == true
              ? "credit"
              : Pref.getBool("advance", false) == true
                  ? "advance"
                  : 'sale',
      "staffName": staff,
      "companyName": compname,
      "companyAddress": companyAdress,
      "printerSize": 80,
      "refundInfo": _refundInfo(receipt),
      "senderInfo": {
        "name": "Invan",
        "sn": Pref.getString(PrefKeys.serialNumber, ""),
        "version": AppConstants.version,
      },
      "otherInfo": {
        "terminalID": terId,
      },
      "params": {
        if (!receipt.isRefund) ...{'paycheckNumber': receipt.externalId},
        "receivedCash": receivedCashValue,
        "receivedCard": receivedCardValue,
        "receivedClick": receipt.hasClick,
        "receivedUzum": receipt.hasUzum,
        "receivedPayme": receipt.hasPayme,
        "receivedDept": receipt.hasDept,
        "externalInfo": {
          "qrPaymentProvider": Pref.getInt('epayPay_Id', 0).toString(),
          "qrPaymentID": Pref.getString('epay_Id', "").toString(),
          "phoneNumber": Pref.getString('epay_phone', "").toString(),
          "cardType": receipt.cardType ?? Pref.getInt('card_type', 0),
          "cardNumber": receipt.cardNumber ?? '',
          "pptId": receipt.pptId ?? '',
        },
        "items": receipt.soldItemList.map((e) {
          double discount = _countDiscountOFD(e);
          double other = _countOtherOFD(
            e,
            cashback: receipt.cashback + otherValue,
            totalPrice: totalPrice,
          );
          num price = _countPrice(e);
          return SalingItemModel(
                  id: e.productId,
                  tin: e.commissionTIN,
                  label: e.mark ?? '',
                  amount: e.value * 1000,
                  barcode: e.barcode,
                  classCode: e.mxik,
                  name: e.productName,
                  discount: discount,
                  ownerType: e.ownerType,
                  other: other,
                  vat: _countVat(e.price, e.vatPercent, e.value, other / 100),
                  vatPercent: e.vatPercent,
                  price: price,
                  packageCode: e.packageCode,
                  packageName: e.packageName)
              .toJson();
        }).toList(),
      },
    };
    // print('=== SALE ON OFD — EXTERNAL INFO YUBORILDI ===');
print(jsonEncode(receiptMap['params']['externalInfo']));
    return receiptMap;
  }

  static num _countPrice(ReceiptModelSoldItem4 e) {
    if ((e.discountPercent ?? 0) > 0) {
      return UtilFunctions.roundToNearest(e.value * e.onlyPrice) * 100;
    }
    return UtilFunctions.roundToNearest(e.value * e.price) * 100;
  }

  static num _countVat(num price, num nds, num value, num other) {
    num n = (100 * ((price * value) - other) * nds / (100 + nds));
    return n;
  }

  static _refundInfo(ReceiptModel4 receipt) {
    if (receipt.refundInfo == null) {
      return null;
    }
    Info info = Info.fromJson(jsonDecode(receipt.refundInfo!));
    return {
      "terminalId": info.terminalId,
      "receiptSeq": int.tryParse(info.receiptSeq ?? "0") ?? 0,
      "dateTime": int.tryParse(info.dateTime ?? "0") ?? 0,
      "fiscalSign": info.fiscalSign,
    };
  }

  static double countDiscounts(ReceiptModel4 receiptModel4) {
    List<ReceiptModelSoldItem4> soldItems = receiptModel4.soldItemList;
    double discountAmount = 0;
    for (int i = 0; i < soldItems.length; i++) {
      for (int n = 0; n < soldItems[i].discount.length; n++) {
        discountAmount += (soldItems[i].discount[n].total * soldItems[i].value);
      }
    }
    return discountAmount;
  }

  static double _countDiscountOFD(ReceiptModelSoldItem4 v) {
    double discountAmount = 0;
    if (v.onlyPrice != v.realPrice && v.discount.isEmpty) {
      discountAmount = 0;
    } else if (v.onlyPrice != v.realPrice && v.discount.isNotEmpty) {
      for (int n = 0; n < v.discount.length; n++) {
        discountAmount += (v.discount[n].total * v.value);
      }
    } else {
      for (int n = 0; n < v.discount.length; n++) {
        discountAmount += (v.discount[n].total * v.value);
      }
      if (discountAmount + v.price * v.value != v.realPrice * v.value) {
        discountAmount += v.realPrice * v.value -
            (v.price * v.value / (100 - v.discountPercent!)) * 100;
      }
    }

    return discountAmount * 100;
  }

  // static double _countDiscountOFD(ReceiptModelSoldItem4 v) {
  //   double discountAmount = 0;
  //
  //   if (v.discount.isNotEmpty) {
  //     for (int n = 0; n < v.discount.length; n++) {
  //       discountAmount += v.discount[n].total;
  //     }
  //   }
  //
  //   if (discountAmount == 0 && v.discountPercent != null && v.discountPercent! > 0) {
  //     discountAmount = (v.realPrice - v.price) * v.value;
  //   }
  //
  //   if (discountAmount == 0 && v.onlyPrice != v.realPrice) {
  //     discountAmount = (v.realPrice - v.onlyPrice) * v.value;
  //   }
  //
  //   if (discountAmount < 0) {
  //     return 0;
  //   }
  //
  //   double totalPrice = v.realPrice * v.value * 100;
  //   double discountInTiyin = discountAmount * 100;
  //
  //   if (discountInTiyin > totalPrice) {
  //     return totalPrice;
  //   }
  //
  //   return discountInTiyin;
  // }
  // ============================================================ //

  static double _countOtherOFD(
    ReceiptModelSoldItem4 v, {
    num cashback = 0,
    double totalPrice = 0,
  }) {
    double otherAmount = 0;
    if (cashback != 0) {
      otherAmount =
          cashback * ((((v.price * v.value) * 100) / totalPrice) / 100);
    }
    return UtilFunctions.roundToNearest(otherAmount) * 100;
  }

  static Map<String, dynamic> fromReceipt4ToClick({
    required Map<String, dynamic> receipt,
  }) {
    Map<String, dynamic> params = receipt['params'];
    List<Map<String, dynamic>> items = params['items'];

    var clickData = {
      "service_id": Pref.getInt(PrefKeys.serviceId, -1),
      "payment_id": num.tryParse(ClickService.paymentId ?? ''),
      "items": List.generate(items.length, (index) {
        Map<String, dynamic> map = {};
        Map<String, dynamic> item = items[index];
        num price = item['price'];
        num amount = item['amount'];
        map['Name'] = item['name'];
        map['Barcode'] = item['barcode'];
        map['Labels'] = [item['label']];
        map['SPIC'] = item['classCode'];
        map['Units'] = 123;
        map['PackageCode'] = '';
        map['GoodPrice'] = price;
        map['Price'] = (price * (amount / 1000)).toInt();
        map['Amount'] = item['amount'];
        map['VAT'] = item['vat'];
        map['VATPercent'] = item['vatPercent'];
        map['Discount'] = item['discount'];
        map['Other'] = item['other'];
        map['CommissionInfo'] = {
          'TIN': item['commissionTIN'],
          'PINFL': '',
        };
        return map;
      }),
    };

    return clickData;
  }
}
