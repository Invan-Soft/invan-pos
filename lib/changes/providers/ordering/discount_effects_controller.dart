// Diskont effektlari: tekin mahsulot oqimlari (Buy X Get Y, Free Gift,
// Buy X Get X) va ular uchun kerak bo'lgan hisob-kitob holati.
//
// OrderingProvider4 dan ajratildi (2026-08-05) — tanalar o'zgartirilmadi,
// faqat savat ro'yxati va mijoz guruhi parametr sifatida uzatiladi.
//
// FAZA 1-3 DAN FARQI: bu kontroller savatga BOG'LIQ — u savat qatorlarini
// o'zgartiradi (narx, chegirma). Shuning uchun toza "mustaqil modul" emas,
// balki "savatga effekt qo'llovchi". Savat egaligi providerda qoladi.
//
// MUHIM — bu sinf ATAYLAB `ChangeNotifier` EMAS (Faza 2-3 dagi kabi).
//
// Testlar:
//   test/discount_free_products_test.dart   (Buy X Get Y)
//   test/discount_free_gift_test.dart       (Free Gift)
//   test/discount_buy_x_get_x_test.dart     (Buy X Get X)

import 'dart:math' show min;

import 'package:invan2/changes/models/product_discount_model.dart';
import 'package:invan2/changes/singletons/discounts/discount_singleton.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

class DiscountEffectsController {
  DiscountEffectsController(this._notify);

  final void Function() _notify;

  // Hisob-kitob holati. Public — fasad getter/setter orqali delegatsiya qiladi.
  Map<String, int> showCount = {};
  Map<String, int> showCountFreeGift = {};
  Map<String, ReturnedProduct> returnedProducts = {};
  List<ReturnedGift> returnedFreeGiftProducts = [];
  List<ReturnedGiftX> returnedBuyXGetX = [];
  Map<String, String> giftProducts = {};
  int freeGiftDialogCount = 0;

  /// Savat jami narxi (chegirma qo'llangandan keyingi narx bo'yicha).
  /// O'chirilgan qatorlar (red-delete) hisobga olinmaydi — ular sotilmaydi.
  static num totalPriceForAll(List<ReceiptModelSoldItem4> cart) => cart
      .where((p) => !(p.isDeleted ?? false))
      .fold(0, (sum, p) => sum + p.price * p.value);

  /// Barcha hisob-kitob holatini tozalaydi.
  void resetBookkeeping() {
    returnedProducts = {};
    returnedFreeGiftProducts = [];
    returnedBuyXGetX = [];
    giftProducts = {};
    freeGiftDialogCount = 0;
    showCount = {};
    showCountFreeGift = {};
  }

  void findFreeProducts(List<ReceiptModelSoldItem4> cart, String clientGroupId) {
    // Free Gift threshold har safar qayta hisoblansin
    DiscountSingleton.maxPrice();
    findFreeGiftProducts(cart, clientGroupId);
    findBuyXGetXProducts(cart, clientGroupId);

    // DIQQAT: lokal ro'yxat nomi maydon nomi (`returnedProducts`) bilan
    // to'qnashmasligi kerak — providerda maydon `_returnedProducts` edi,
    // prefiks olinganda ikkisi bir nomga tushib qolardi.
    final found = DiscountSingleton.buyXGetYOrFreeGifts(
          cart,
          clientGroupId,
          0,
          false,
        ) ??
        [];

    // MUHIM: xarita HAR SAFAR noldan qayta quriladi.
    //
    // Avval `found` bo'sh bo'lsa erta `return` qilinardi va eski yozuvlar
    // xaritada qolib ketardi. Natijada "A olsang B tekin" chegirmasida A
    // savatdan o'chirilganda ham `useFreeProducts` eski yozuv bo'yicha B ni
    // tekin qilishda davom etardi (savatda boshqa product bo'lsa —
    // quyidagi threshold ham uni ushlab qololmasdi).
    final rebuilt = <String, ReturnedProduct>{};
    for (final product in found) {
      final discountId = product.discountId;
      if (discountId != null) {
        rebuilt[discountId] = product;
      }
    }
    returnedProducts = rebuilt;
  }

  void findFreeGiftProducts(List<ReceiptModelSoldItem4> cart, String clientGroupId) {
    List<ReturnedGift> returned = DiscountSingleton.buyXGetYOrFreeGifts(
          cart,
          clientGroupId,
          totalPriceForAll(cart),
          true,
        ) ??
        [];
    returnedFreeGiftProducts = returned;
  }

  void findBuyXGetXProducts(List<ReceiptModelSoldItem4> cart, String clientGroupId) {
    final buyXGetXList = DiscountSingleton.getBuyXGetXDiscounts(
      cart,
      clientGroupId,
    );

    if (buyXGetXList.isNotEmpty) {
      returnedBuyXGetX = buyXGetXList;
      returnedBuyXGetX.forEach(
        (element) {},
      );
    } else {
      returnedBuyXGetX = [];
    }
  }

  void useFreeProducts(List<ReceiptModelSoldItem4> cart) {
    // Amal qilmay qolgan Buy X Get Y qatorlarini avval tozalaymiz — bu
    // `returnedProducts` bo'sh bo'lganda ham bajarilishi shart.
    _clearStale(cart, 'Buy X Get Y', returnedProducts.keys.toSet());

    if (returnedProducts.isEmpty) return;

    final orderedProducts = cart;

    for (final returnedProduct in returnedProducts.values) {
      final mustQty = returnedProduct.mustProductQuantity ?? 0;
      final availableProducts = returnedProduct.availableProducts;
      final returnedProductId = returnedProduct.returnedProductId;
      final returnedProductQty =
          returnedProduct.returnedProductQuantity?.toDouble() ?? 0.0;

      if (availableProducts == null ||
          availableProducts.isEmpty ||
          returnedProductId == null) {
        continue;
      }

      final isSameProduct =
          availableProducts.any((p) => p.id == returnedProductId);

      bool thresholdMet;
      if (isSameProduct) {
        final totalQtyOfProduct = orderedProducts
            .where((p) =>
                p.productId == returnedProductId && !p.isPriceOnlyChanged)
            .fold<num>(
                0,
                (sum, p) =>
                    sum + (p.saleType == 2 ? p.value * p.boxValue : p.value));
        thresholdMet = totalQtyOfProduct >= mustQty + returnedProductQty;
      } else {
        // Har bir "sotib olinishi kerak" product savatda yetarli DONA
        // miqdorida borligini tekshiramiz.
        //
        // Avval bu yerda savatdagi BOSHQA barcha productlarning PUL summasi
        // `mustQty` (dona soni) bilan solishtirilardi. Shu sababli savatga
        // chegirmaga aloqasi yo'q bitta product qo'shilsa ham shart
        // "bajarilgan" bo'lib qolardi va A o'chirilgach B tekinligicha
        // qolib ketardi.
        final buyIds = availableProducts
            .map((p) => p.id)
            .whereType<String>()
            .where((id) => id != returnedProductId)
            .toSet();

        thresholdMet = buyIds.isNotEmpty &&
            buyIds.every((id) => _cartQtyOf(orderedProducts, id) >= mustQty);
      }

      if (!thresholdMet) {
        for (final item in orderedProducts) {
          if (item.productId == returnedProductId) {
            resetItemDiscount(item);
          }
        }
        continue;
      }

      final prod = ItemsSingleton.getProductById(returnedProductId);
      final firstTierPrice = (prod != null)
          ? ItemsSingleton.onePrice(prod.shopPrices).toDouble()
          : 0.0;

      // Tegishli barcha qatorlar (to'lanadigan + tekin bo'ladigan)
      final eligibleItems = orderedProducts
          .where((item) =>
              item.productId == returnedProductId &&
              !item.isPriceOnlyChanged &&
              !item.isPriceChanged &&
              !(item.isDeleted ?? false))
          .toList();

      // Box itemlar (katta effectiveQty) avval ishlansin — individual itemlar keyinida
      eligibleItems.sort((a, b) {
        final aQty = a.saleType == 2 ? (a.value * a.boxValue) : a.value;
        final bQty = b.saleType == 2 ? (b.value * b.boxValue) : b.value;
        return bQty.compareTo(aQty);
      });

      num freeLeft = returnedProductQty;

      for (final item in eligibleItems) {
        // 1. Har bir qator uchun 6050 ni majburiy qo'yamiz
        if (firstTierPrice > 0) {
          final adjustedFirstTierPrice = item.saleType == 2
              ? firstTierPrice * item.boxValue
              : firstTierPrice;
          item.realPrice = adjustedFirstTierPrice;
          item.onlyPrice = adjustedFirstTierPrice;
        }

        if (freeLeft <= 0) {
          // To'lanadigan qator — chegirmasiz qoladi
          item.price = item.realPrice;
          item.discountPercent = 0;
          item.singleDiscount = 0;
          resetItemDiscount(item); // eski chegirmalarni tozalaydi
          continue;
        }

        final itemQty = item.saleType == 2
            ? (item.value * item.boxValue).toDouble()
            : item.value.toDouble();
        final effectiveFree = freeLeft >= itemQty ? itemQty : freeLeft;
        freeLeft -= effectiveFree;

        final paidQty = itemQty - effectiveFree;
        final ratio = paidQty / itemQty;

        item
          ..price = item.realPrice * ratio
          ..discountPercent = 100 - (ratio * 100)
          ..singleDiscount = (item.realPrice * effectiveFree) / itemQty;

        item.discount.clear();

        final discountModel = ProductDiscountModel(
          idd: returnedProduct.discountId ?? '',
          typeId: returnedProduct.discountGroupType ?? '',
          typeName: 'Buy X Get Y',
          name: returnedProduct.discountName ?? '',
          value: item.discountPercent ?? 100,
          total: item.singleDiscount * item.value,
        );

        item.productDiscount.removeWhere((e) => e.idd == discountModel.idd);
        item.productDiscount.add(discountModel);
        DiscountSingleton.addDiscountForProduct(item);
      }
    }

    // (ro'yxat havolasi o'zgarmaydi — qayta tayinlash no-op edi)
    _notify();
  }

  void useFreeGiftProducts(List<ReceiptModelSoldItem4> cart) {
    final orderedProducts = cart;

    // Endi amal qilmaydigan sovg'alarni bekor qilamiz.
    //
    // Ilgari bu faqat `returnedFreeGiftProducts` TO'LIQ bo'sh bo'lgandagina
    // bajarilardi. Bir nechta Free Gift bosqichi bo'lganda (50k → B, 100k → G)
    // savat 100k dan pastga tushsa ro'yxat bo'sh bo'lmasdi — pastki bosqich
    // qolardi — va yuqori bosqichning sovg'asi (G) tekinligicha qolib ketardi.
    final activeGiftIds = returnedFreeGiftProducts
        .map((g) => g.getProduct?.id)
        .whereType<String>()
        .toSet();

    for (final giftId in giftProducts.keys.toList()) {
      if (activeGiftIds.contains(giftId)) continue;
      for (final item in orderedProducts) {
        if (item.isPriceOnlyChanged) continue;
        if (item.productId == giftId && item.price != item.realPrice) {
          resetItemDiscount(item);
        }
      }
      giftProducts.remove(giftId);
    }

    if (returnedFreeGiftProducts.isEmpty) return;

    for (final gift in returnedFreeGiftProducts) {
      final giftProductId = gift.getProduct?.id;
      if (giftProductId == null) continue;

      final nonGiftTotal = orderedProducts
          .where((p) =>
              p.productId != giftProductId &&
              !p.isPriceOnlyChanged &&
              !(p.isDeleted ?? false))
          .fold<num>(0, (sum, p) => sum + p.realPrice * p.value);

      final giftItems = orderedProducts
          .where((item) =>
              item.productId == giftProductId &&
              !item.isPriceOnlyChanged &&
              !item.isPriceChanged &&
              !(item.isDeleted ?? false))
          .toList();

      // Sovg'a producti savatda bo'lsa, uning to'lanadigan qismi ham
      // threshold ga kiritiladi: (savatdagi sovg'a product summasi − tekin qism)
      // + boshqa productlar summasi >= buyAmount.
      final giftProductInCartValue =
          giftItems.fold<num>(0, (sum, p) => sum + p.realPrice * p.value);
      final giftRealPrice =
          giftItems.isNotEmpty ? giftItems.first.realPrice : 0;
      final freeValue = giftRealPrice * gift.getProductAmount;
      final effectivePaidTotal =
          nonGiftTotal + giftProductInCartValue - freeValue;

      if (effectivePaidTotal >= gift.buyAmount) {
        // Threshold qondirildi — faqat gift.getProductAmount miqdorini tekin ber
        giftProducts[giftProductId] = gift.discountId ?? '';
        num freeLeft = gift.getProductAmount.toDouble();

        for (final item in giftItems) {
          if (freeLeft <= 0) {
            // Kvota tugadi — bu qatorni to'liq narxda qoldirish kerak
            resetItemDiscount(item);
            continue;
          }

          final itemQty = item.saleType == 2
              ? (item.value * item.boxValue).toDouble()
              : item.value.toDouble();
          final effectiveFree = freeLeft >= itemQty ? itemQty : freeLeft;
          freeLeft -= effectiveFree;

          final ratio = (itemQty - effectiveFree) / itemQty;
          item
            ..price = item.realPrice * ratio
            ..discountPercent = 100 - (ratio * 100)
            ..singleDiscount = (item.realPrice * effectiveFree) / itemQty;

          item.discount.clear();
          DiscountSingleton.addDiscountForProduct(item);
          addDiscountForReceipt(item, gift.discountName ?? '',
              gift.discountId ?? '', gift.discountGroupType ?? '');
        }
      } else {
        for (final item in giftItems) {
          if (item.price != item.realPrice) {
            resetItemDiscount(item);
          }
        }
        giftProducts.remove(giftProductId);
      }
    }

    // (ro'yxat havolasi o'zgarmaydi — qayta tayinlash no-op edi)
  }

  void useBuyXGetXProducts(List<ReceiptModelSoldItem4> cart) {
    // Amal qilmay qolgan Buy X Get X qatorlarini avval tozalaymiz — bu
    // `returnedBuyXGetX` bo'sh bo'lganda ham bajarilishi shart (masalan
    // diskont bazadan o'chirilgan yoki muddati tugagan).
    _clearStale(cart, 'Buy X Get X', _activeBuyXGetXIds());

    if (returnedBuyXGetX.isEmpty) return;

    final orderedProducts = cart;

    for (ReturnedGiftX gift in returnedBuyXGetX) {
      final productId = gift.getProduct?.id;
      if (productId == null) continue;

      // Shu productId ga tegishli barcha normal qatorlar
      final items = orderedProducts
          .where((item) =>
              item.productId == productId &&
              !item.isPriceOnlyChanged &&
              !item.isPriceChanged &&
              !(item.isDeleted ?? false))
          .toList();

      if (items.isEmpty) continue;

      num freeQtyLeft = gift.getProductAmount; // nechta tekin berish kerak

      // ================== 1. BITTA QATOR (oddiy mahsulot) ==================
      if (items.length == 1) {
        final item = items.first;
        final totalQty = item.saleType == 2
            ? (item.value * item.boxValue).toDouble()
            : item.value.toDouble();
        final buy = gift.buyAmount.toDouble();
        final get = gift.getProductAmount.toDouble();

        // Discount bo'lsa - 3 talik narx emas, 1-chi (asosiy) narxdan hisoblansin
        final prod = ItemsSingleton.getProductById(gift.getProduct?.id ?? '');
        final firstTierPrice = prod != null
            ? ItemsSingleton.onePrice(prod.shopPrices).toDouble()
            : 0.0;
        if (firstTierPrice > 0 && firstTierPrice > item.realPrice) {
          item.realPrice = firstTierPrice;
          item.onlyPrice = firstTierPrice;
          item.price = firstTierPrice;
        }

        num freeQty = 0;
        final setSize = buy + get;
        if (gift.isRepeatable) {
          // isRepeatable=true: nechta set bo'lsa shuncha tekin
          if (totalQty >= setSize) {
            freeQty = (totalQty / setSize).floor() * get;
          }
        } else {
          // isRepeatable=false: faqat bitta set, qancha olmasin
          if (totalQty >= setSize) {
            freeQty = get;
          }
        }

        final paidQty = totalQty - freeQty;

        if (paidQty > 0) {
          final ratio = paidQty / totalQty;
          item.price = item.realPrice * ratio;
          item.discountPercent = 100 - (ratio * 100);
          item.singleDiscount = (item.realPrice * freeQty) / totalQty;
        } else {
          item.price = 0;
          item.discountPercent = 100;
          item.singleDiscount = item.realPrice;
        }

        // Discount model
        item.discount.clear();
        final discountModel = ProductDiscountModel(
          idd: gift.discountId ?? '',
          typeId: gift.discountGroupType ?? '',
          typeName: 'Buy X Get X',
          name: gift.discountName ?? '',
          value: item.discountPercent ?? 100,
          total: item.singleDiscount * item.value,
        );

        item.productDiscount.removeWhere((e) => e.idd == discountModel.idd);
        item.productDiscount.add(discountModel);
        DiscountSingleton.addDiscountForProduct(item);
      } else {
        // BuyXGetX: perSetGet == perSetBuy (symmetric), perSet = buy + get = 2 × buyAmount
        final perSetGet = gift.buyAmount.toDouble();
        final perSetSize = perSetGet * 2;

        for (final item in items.reversed) {
          if (freeQtyLeft <= 0) {
            resetItemDiscount(item);
            continue;
          }

          final itemQty = item.saleType == 2
              ? (item.value * item.boxValue).toDouble()
              : item.value.toDouble();

          // Box: cap free at natural ratio so excess free slots pass to individual items.
          // Individual: can absorb all remaining free slots (up to itemQty).
          final naturalCap = item.saleType == 2
              ? (itemQty / perSetSize).floor() * perSetGet
              : itemQty;
          final freeInThis = min(naturalCap, freeQtyLeft);

          if (freeInThis <= 0) {
            resetItemDiscount(item);
            continue;
          }

          if (freeInThis >= itemQty) {
            // Butun qator tekin
            item.price = 0;
            item.discountPercent = 100;
            item.singleDiscount = item.realPrice;
            freeQtyLeft -= itemQty;
          } else {
            // Qisman tekin
            final paidQty = itemQty - freeInThis;
            final ratio = paidQty / itemQty;
            item.price = item.realPrice * ratio;
            item.discountPercent = 100 - (ratio * 100);
            item.singleDiscount = (item.realPrice * freeInThis) / itemQty;
            freeQtyLeft -= freeInThis;
          }

          // Discount model
          item.discount.clear();
          final discountModel = ProductDiscountModel(
            idd: gift.discountId ?? '',
            typeId: gift.discountGroupType ?? '',
            typeName: 'Buy X Get X',
            name: gift.discountName ?? '',
            value: item.discountPercent ?? 100,
            total: item.singleDiscount * item.value,
          );

          item.productDiscount.removeWhere((e) => e.idd == discountModel.idd);
          item.productDiscount.add(discountModel);
          DiscountSingleton.addDiscountForProduct(item);
        }
      }
    }

    _notify();
  }

  /// [productId] uchun savatdagi umumiy dona soni (blok qatorlari donaga
  /// yoyiladi). Qo'lda narxi tuzatilgan va o'chirilgan qatorlar hisobga
  /// olinmaydi.
  static num _cartQtyOf(List<ReceiptModelSoldItem4> cart, String productId) =>
      cart
          .where((p) =>
              p.productId == productId &&
              !p.isPriceOnlyChanged &&
              !(p.isDeleted ?? false))
          .fold<num>(
              0,
              (sum, p) =>
                  sum + (p.saleType == 2 ? p.value * p.boxValue : p.value));

  /// Hozir amal qilayotgan Buy X Get X chegirmalarining IDlari.
  Set<String> _activeBuyXGetXIds() => returnedBuyXGetX
      .map((g) => g.discountId)
      .whereType<String>()
      .toSet();

  /// Endi amal qilmaydigan chegirmalarni savat qatorlaridan olib tashlaydi.
  ///
  /// [typeName] — `productDiscount` dagi belgi ('Buy X Get Y' / 'Buy X Get X').
  /// Qatorda shu turdagi yozuv bor, lekin uning IDsi [activeIds] da yo'q
  /// bo'lsa (masalan "sotib olinishi kerak" product savatdan o'chirilgan yoki
  /// diskontning o'zi bazadan yo'qolgan), qator asl narxiga qaytariladi.
  void _clearStale(
    List<ReceiptModelSoldItem4> cart,
    String typeName,
    Set<String> activeIds,
  ) {
    for (final item in cart) {
      if (item.isPriceOnlyChanged) continue;
      final hasStale = item.productDiscount
          .any((d) => d.typeName == typeName && !activeIds.contains(d.idd));
      if (hasStale) resetItemDiscount(item);
    }
  }

  void resetItemDiscount(ReceiptModelSoldItem4 item) {
    item
      ..price = item.realPrice
      ..discountPercent = 0
      ..singleDiscount = 0
      ..discount.clear()
      ..productDiscount.clear();
  }

  ReceiptModelSoldItem4 addDiscountForReceipt(ReceiptModelSoldItem4 item,
      String discountName, String discountId, String discountGroupType) {
    ProductDiscountModel productDiscountModel = ProductDiscountModel(
      idd: discountId,
      typeId: discountGroupType,
      typeName: discountName,
      name: discountName,
      value: item.singleDiscount,
      total: 0,
    );
    item.productDiscount.removeWhere((e) => e.idd == productDiscountModel.idd);
    item.productDiscount.add(productDiscountModel);
    return item;
  }
}
