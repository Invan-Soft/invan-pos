
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
import 'package:invan2/utils/constants/secrets.dart';
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

    // Refund uchun externalId return_bloc da oldindan set qilingan (API bilan bir xil bo'lsin)
    // Sotuv uchun: ID larni box.put DAN OLDIN beramiz — crash bo'lsa to'liq saqlanadi yoki umuman saqlanmaydi
    if (!receiptModel4.isRefund) {
      receiptModel4.externalId = await getCheckNo();
      receiptModel4.orderId = const Uuid().v7();
    }

    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
    int i = box.put(receiptModel4);
    receiptModel4.id = i;

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
    Map<String, double> totalOnlyPrice = {};
    Map<String, double> totalRealPrice = {};
    Map<String, List<String>> allMarks = {};
    Map<String, List<String>> allBoxMarks = {};
    Map<String, int> totalBoxQuantity = {};
    Map<String, int> boxValueMap = {};

    for (ReceiptModelSoldItem4 r in receiptModel4.soldItemList) {
      // Bir xil productId dagi barcha itemlar (box, individual, utsenka) birlashtiriladi
      final key = r.productId;

      // Actual amount paid per item (not normalized): box price already represents N units
      if (uniqueItems.containsKey(key)) {
        uniqueItems[key]!.value += r.value;
        totalSingleDiscount[key] =
            (totalSingleDiscount[key] ?? 0) + r.singleDiscount * r.value;
        totalPrice[key] = (totalPrice[key] ?? 0) + r.price * r.value;
        totalOnlyPrice[key] =
            (totalOnlyPrice[key] ?? 0) + r.onlyPrice * r.value;
        totalRealPrice[key] =
            (totalRealPrice[key] ?? 0) + r.realPrice * r.value;
        if (r.saleType == 2) {
          totalBoxQuantity[key] =
              (totalBoxQuantity[key] ?? 0) + r.value.toInt();
          if (r.boxValue > 0) boxValueMap[key] = r.boxValue;
          uniqueItems[key]!.saleType = 2;
        }
      } else {
        uniqueItems[key] = r;
        totalSingleDiscount[key] = r.singleDiscount * r.value;
        totalPrice[key] = r.price * r.value;
        totalOnlyPrice[key] = r.onlyPrice * r.value;
        totalRealPrice[key] = r.realPrice * r.value;
        allMarks[key] = [];
        allBoxMarks[key] = [];
        if (r.saleType == 2) {
          totalBoxQuantity[key] = r.value.toInt();
          if (r.boxValue > 0) boxValueMap[key] = r.boxValue;
        } else {
          totalBoxQuantity[key] = 0;
        }
      }
      if (r.mark != null && r.mark!.isNotEmpty) {
        if (r.saleType == 2) {
          allBoxMarks[key]!.add(r.mark!);
        } else {
          allMarks[key]!.add(r.mark!);
        }
      }
    }

    for (final key in uniqueItems.keys) {
      final item = uniqueItems[key]!;
      final totalDiscount = totalSingleDiscount[key] ?? 0;
      final priceTotal = totalPrice[key] ?? 0;
      final onlyPriceTotal = totalOnlyPrice[key] ?? 0;
      final realPriceTotal = totalRealPrice[key] ?? 0;

      item.boxQuantity = totalBoxQuantity[key] ?? 0;
      item.boxValue = boxValueMap[key] ?? 0;
      if (item.boxQuantity > 0) {
        item.saleType = 2;
        item.productName = item.productName.replaceAll(' //blok', '');
      }
      // Expand value to physical unit count FIRST so price division is correct.
      // Example: 1 box(8) + 4 individual → value = 1*8 + (5-1) = 12 physical units
      if (item.boxQuantity > 0 && item.boxValue > 0) {
        item.value = item.boxQuantity * item.boxValue + (item.value - item.boxQuantity);
      }

      // Divide total money by physical unit count → correct per-unit price
      if (item.value > 0) {
        item.price = priceTotal / item.value;
        item.onlyPrice = onlyPriceTotal / item.value;
        item.realPrice = realPriceTotal / item.value;
        item.singleDiscount = item.realPrice > item.price
            ? double.parse((item.realPrice - item.price).toStringAsFixed(2))
            : double.parse((totalDiscount / item.value).toStringAsFixed(2));
      }

      item.mark = (allMarks[key] ?? []).join('\n');
      item.boxMark = (allBoxMarks[key] ?? []).join('\n');
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
    final paynetId = Pref.getString(PrefKeys.paynetId, "");

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

    final bool receivedPaynet = paynetId.isNotEmpty &&
        receipt.payment.any(
          (p) => p.payId.replaceFirst('@', '').trim() == paynetId,
        );

    print('======= saleOnOFD | receivedPaynet: $receivedPaynet | paynetId: "$paynetId" =======');

    String token = Secrets.fiscalApiToken;
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
        "receivedPaynet": receivedPaynet,
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
            name: e.productName.replaceAll(' //blok', ''),
            discount: discount,
            ownerType: e.ownerType,
            other: other,
            vat: _countVat(price, e.vatPercent, other),
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

  static num _countVat(num priceJson, num nds, num other) {
    // priceJson and other are both in tiins (already rounded), ensuring price = other + vat
    num n = (priceJson - other) * nds / (100 + nds);
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
