
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
    // Refund uchun externalId return_bloc da oldindan set qilingan (API bilan bir xil bo'lsin)
    // Sotuv uchun yangi raqam generate qilamiz
    if (!receiptModel4.isRefund) {
      receiptModel4.externalId = await getCheckNo();
    }
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
    Map<String, double> totalSingleDiscount = {};
    Map<String, double> totalPrice = {};
    // Har bir productId uchun barcha marklarni yig'amiz
    Map<String, List<String>> allMarks = {};

    for (ReceiptModelSoldItem4 r in receiptModel4.soldItemList) {
      if (uniqueItems.containsKey(r.productId)) {
        uniqueItems[r.productId]!.value += r.value;
        totalSingleDiscount[r.productId] =
            (totalSingleDiscount[r.productId] ?? 0) + r.singleDiscount;
        totalPrice[r.productId] =
            (totalPrice[r.productId] ?? 0) + r.price * r.value;
      } else {
        uniqueItems[r.productId] = r;
        totalSingleDiscount[r.productId] = r.singleDiscount;
        totalPrice[r.productId] = r.price * r.value;
        allMarks[r.productId] = [];
      }
      // Markni ro'yxatga qo'shamiz (bo'sh bo'lmasa)
      if (r.mark != null && r.mark!.isNotEmpty) {
        allMarks[r.productId]!.add(r.mark!);
      }
    }

    for (final productId in uniqueItems.keys) {
      final item = uniqueItems[productId]!;
      final totalDiscount = totalSingleDiscount[productId] ?? 0;
      final priceTotal = totalPrice[productId] ?? 0;
      if (item.value > 0) {
        item.singleDiscount = totalDiscount / item.value;
        item.price = priceTotal / item.value;
      }
      // Barcha marklarni '\n' bilan birlashtirib mark ga saqlaymiz
      final marks = allMarks[productId] ?? [];
      item.mark = marks.join('\n');
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

    if (receipt.isRefund) {
      // Vozvrat: to'lov turidan qat'iy nazar hammasi CASH orqali qaytariladi
      for (var p in receipt.payment) {
        receivedCashValue += p.value * 100;
      }
    } else {
      // ==================== SOTUV: YANGI KUCHLI TEKSHIRUV ====================
      for (var p in receipt.payment) {
        final nameUpper = (p.name ?? '').toUpperCase().trim();
        final id = p.payId.replaceFirst('@', '').trim();

        if (nameUpper == 'CASH' || id == cashId) {
          receivedCashValue += p.value * 100;
        }
        else if (nameUpper == 'CARD' ||
                 nameUpper == 'UZCARD' ||
                 nameUpper == 'HUMO' ||
                 id == Pref.getString(PrefKeys.cardId, '')) {
          receivedCardValue += p.value * 100;
        }
        else if (id == cashbackId) {
          cashbackValue += p.value;
        }
        else if ((id == clickId && nameUpper.contains('CLICK')) ||
                 (id == paymeId && nameUpper.contains('PAYME')) ||
                 (id == uzumId && nameUpper.contains('UZUM'))) {
          otherValue += p.value;
        }
        else {
          // Boshqa barcha holatlar (xavfsizlik uchun) → CARD
          receivedCardValue += p.value * 100;
        }
      }
    }

    receipt.cashback = cashbackValue.round();

    String token = "DXJFX32CN1296678504F2";
    String staff = Pref.getString(PrefKeys.cashierName, "not initialized");
    String? compname = Pref.getString(PrefKeys.organizationName, "not initialized");
    String? companyAdress = Pref.getString(PrefKeys.serviceAddress, "not initialized");

    if (receipt.refundInfo == null || receipt.refundInfo == 'null') {
      receipt.refundInfo = null;
    }

    int itemsLen = receipt.soldItemList.length;
    String terId = Pref.getString(PrefKeys.terminalID, '');
    double totalPrice = ItemsSingleton.getOfdTotalPrice(receipt.soldItemList);

    Map<String, dynamic> receiptMap = {
      'token': token,
      'method': receipt.isRefund ? 'refund' : 'sale',
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
      "otherInfo": {"terminalID": terId},
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
            packageName: e.packageName,
            commissionInfo: {"TIN": e.commissionTIN ?? "", "PINFL": ""},
          ).toJson();
        }).toList(),
      },
    };

    // print('📤 saleOnOFD | cardType: ${receipt.cardType} | receivedCash: $receivedCashValue | receivedCard: $receivedCardValue');

    return receiptMap;
  }
  static num _countPrice(ReceiptModelSoldItem4 e) {
    if (e.realPrice > e.price) {
      return UtilFunctions.roundToNearest(e.value * e.realPrice) * 100;
    }
    return UtilFunctions.roundToNearest(e.value * e.price) * 100;
  }

  static num _countVat(num price, num nds, num value, num other) {
    num n = (100 * ((price * value) - other) * nds / (100 + nds));
    return n < 0 ? 0 : n;
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
    // Discount = narq kamayishi × miqdor (realPrice - discounted price) × value
    // Bu formula barcha holatlar uchun to'g'ri:
    // - marking (value=1), oddiy mahsulot (value>1), BuyXGetX, BuyXGetY, foiz chegirma
    double discountAmount = (v.realPrice - v.price) * v.value;
    if (discountAmount < 0) discountAmount = 0;
    return discountAmount * 100;
  }


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
  // static Map<String, dynamic> fromReceipt4ToClick({
  //   required Map<String, dynamic> receipt,
  // }) {
  //   Map<String, dynamic> params = receipt['params'];
  //   List<Map<String, dynamic>> items = params['items'];

  //   var clickData = {
  //     "service_id": Pref.getInt(PrefKeys.serviceId, -1),
  //     "payment_id": num.tryParse(ClickService.paymentId ?? ''),
  //     "items": List.generate(items.length, (index) {
  //       Map<String, dynamic> map = {};
  //       Map<String, dynamic> item = items[index];
  //       num price = item['price'];
  //       num amount = item['amount'];

  //       map['Name'] = item['name'];
  //       map['Barcode'] = item['barcode'];
  //       map['Labels'] = [item['label']];
  //       map['SPIC'] = item['classCode'];
  //       map['Units'] = 123;
  //       map['PackageCode'] = '';
  //       map['GoodPrice'] = price;
  //       map['Price'] = (price * (amount / 1000)).toInt();
  //       map['Amount'] = item['amount'];
  //       map['VAT'] = item['vat'];
  //       map['VATPercent'] = item['vatPercent'];
  //       map['Discount'] = item['discount'];
  //       map['Other'] = item['other'];

  //       // ← ENG MUHIM: Click uchun ham ARRAY qilamiz
  //       map['CommissionInfo'] = item['commissionInfo'] is List
  //           ? item['commissionInfo']
  //           : (item['commissionInfo'] != null
  //               ? [item['commissionInfo']]
  //               : [{"TIN": item['commissionTIN'] ?? "", "PINFL": ""}]);

  //       return map;
  //     }),
  //   };

  //   return clickData;
  // }
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
