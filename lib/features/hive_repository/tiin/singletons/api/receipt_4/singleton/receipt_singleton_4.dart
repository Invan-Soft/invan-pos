
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/discount_model.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/models/product/sale_item_model.dart';
import 'package:invan2/changes/models/product_discount_model.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/changes/services/receipt_api_4.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
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

    // Refund uchun externalId return_bloc da oldindan set qilingan (API bilan bir xil bo'lsin)
    // Sotuv uchun: ID larni box.put DAN OLDIN beramiz — crash bo'lsa to'liq saqlanadi yoki umuman saqlanmaydi
    if (!receiptModel4.isRefund) {
      receiptModel4.externalId = await getCheckNo();
      receiptModel4.orderId = const Uuid().v7();
    }

    // Discount ToMany'larni qayta print ucun ishonchli saqlash — nested cascade
    // ba'zida ToMany linklarni to'liq saqlamaydi, shu sababli explicit put
    final pdBox = MyObjectbox.saleStore.box<ProductDiscountModel>();
    final dBox = MyObjectbox.saleStore.box<DiscountModel>();
    for (final soldItem in receiptModel4.soldItemList) {
      for (final pd in soldItem.productDiscount) {
        if (pd.id == 0) pdBox.put(pd);
      }
      for (final d in soldItem.discount) {
        if (d.id == 0) dBox.put(d);
      }
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
    // DIQQAT: smena yig'indilari endi HAR sotuvda shifts.hive ga yozilmaydi.
    // Sabab: getCurrentHiveShift() Z/X-otchotda barcha summalarni ObjectBox
    // cheklaridan qaytadan hisoblaydi — shu sababli per-sotuv yozuv ortiqcha edi.
    // Eski kod shifts.hive ni har sotuvda yangilab, Hive compaction'ini tez-tez
    // ishga tushirardi; svet o'chgan/ilova o'ldirilgan lahzaga to'g'ri kelsa,
    // fayl 0KB bo'lib buzilardi (smena yozuvi yo'qoladi, otchot bo'sh chiqadi).
    // Eski chaqiruvlar (endi kerak emas):
    //   ShiftSingleton4.updateShiftOnRefund(receiptModel4.payment);
    //   ShiftSingleton4.updateTheShift(receiptModel4.payment,
    //       receiptModel4.zdachiToCashback ?? 0, countDiscounts(receiptModel4));

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

    // OFD itemlarini avval MODEL sifatida quramiz (toJson keyin). Shunda
    // yuborishdan oldin §10.2.1 balansini tekshirib/tuzatish imkoni bo'ladi.
    final List<SalingItemModel> ofdItems = receipt.soldItemList.map((e) {
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
      );
    }).toList();

    // §10.2.1 BALANS MAJBURLASH (sotuv uchun): yarim-so'mli tarozi mahsuloti
    // (masalan 0.29×204950=59435.5) `_countPrice` da yuqoriga, to'lov tomonida
    // pastga yaxlitlanib, Σ(Price−Disc) bilan haqiqiy to'lov o'rtasida 1 so'mlik
    // farq qoladi. 100% elektron to'lovda (cashback/click) bu §10.2.1 ni buzadi.
    // Qoldiqni eng katta narxli item'ning Other'iga yig'amiz — balans allaqachon
    // 0 bo'lsa hech narsa o'zgarmaydi (ishlayotgan sotuvlar xavfsiz).
    if (!receipt.isRefund) {
      _enforce1021Balance(
        ofdItems,
        receivedCash: receivedCashValue,
        receivedCard: receivedCardValue,
      );
    }

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
        "items": ofdItems.map((e) => e.toJson()).toList(),
      },
    };

    // print('📤 saleOnOFD | cardType: ${receipt.cardType} | receivedCash: $receivedCashValue | receivedCard: $receivedCardValue');

    return receiptMap;
  }
  /// §10.2.1 balans tenglamasini yuborishdan OLDIN majburlaydi:
  ///   Σ(Price − Discount) == ReceivedCash + ReceivedCard + Σ Other
  ///
  /// Yarim-so'mli tarozi item OFD tomonida yuqoriga, to'lov tomonida pastga
  /// yaxlitlanib, Σ(Price) bilan haqiqiy to'lov o'rtasida farq qoladi (1 so'm
  /// yoki bir necha so'm — bir necha yarim-so'mli item bo'lsa). Bu farq 100%
  /// elektron to'lovda §10.2.1 ni buzadi.
  ///
  /// Yechim: farq qancha bo'lsa ham, OFD goods jamini (Σ Price) mijoz HAQIQATAN
  /// to'lagan summaga AYNAN tenglashtiramiz — eng katta narxli item'ning Price'ini
  /// qoldiq miqdoricha to'g'rilab (OFD = to'lov, ortiqcha ko'rsatmaymiz). Agar
  /// o'sha item'da Other Price'dan oshib ketadigan bo'lsa (kam holatda), qoldiqni
  /// Other'ga yig'ish zaxira yo'liga o'tamiz. Qoldiq 0 ⇒ NO-OP (ishlayotgan
  /// sotuvlar umuman o'zgarmaydi). Hammasi tiyinda (Price/Other allaqachon ×100).
  static void _enforce1021Balance(
    List<SalingItemModel> items, {
    required double receivedCash,
    required double receivedCard,
  }) {
    if (items.isEmpty) return;

    num sumPrice = 0;
    num sumDiscount = 0;
    num sumOther = 0;
    int largestIdx = 0;
    num largestPrice = -1;
    for (int i = 0; i < items.length; i++) {
      final it = items[i];
      final num p = it.price ?? 0;
      sumPrice += p;
      // DIQQAT: `it.discount` getter'i List<DiscountModel>? deb tiplangan, lekin
      // bu yerda unga double saqlanadi → getter'ni o'qish cast-crash beradi.
      // Shuning uchun xom qiymatni toJson() orqali olamiz.
      final dynamic dRaw = it.toJson()['discount'];
      sumDiscount += (dRaw is num) ? dRaw : 0;
      sumOther += it.other ?? 0;
      if (p > largestPrice) {
        largestPrice = p;
        largestIdx = i;
      }
    }

    final num residual =
        (sumPrice - sumDiscount) - (receivedCash + receivedCard + sumOther);
    if (residual == 0) return; // balans joyida — tegmaymiz

    // XAVFSIZLIK CHEGARASI: farq faqat YAXLITLASH o'lchamida bo'lsa to'g'rilaymiz.
    // Maksimal 500 so'm — yaxlitlash qoldig'i bundan oshmaydi (har item ≤ ~1 so'm).
    // 500 so'mdan KATTA farq = boshqa bug (yaxlitlash emas) → jimgina narxga yopib
    // YASHIRMAYMIZ, OFD'ga o'z holicha ketsin (xato ko'rinib qolsin).
    const num maxRoundingTiyin = 500 * 100; // 500 so'm = 50000 tiyin
    if (residual.abs() > maxRoundingTiyin) return;

    final SalingItemModel target = items[largestIdx];
    final num price = target.price ?? 0;
    final num other = target.other ?? 0;

    if (price - residual >= other) {
      // Afzal yo'l: Price'ni qoldiqcha to'g'rilaymiz → Σ Price = to'langan summa.
      target.price = price - residual;
    } else {
      // Zaxira: Other Price'dan oshib ketmasligi uchun qoldiqni Other'ga yig'amiz.
      final num newOther = other + residual;
      target.other = newOther < 0 ? 0 : newOther;
    }

    target.vat = _countVat(
      target.price ?? 0,
      target.vatPercent ?? 0,
      target.other ?? 0,
    );
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
