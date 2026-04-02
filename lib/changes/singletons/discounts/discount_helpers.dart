/*
    @author Suxrob Sattorov, 1/29/2025, 11:59 AM
*/

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:invan2/changes/models/product_discount_model.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../features/get_discounts/get_discounts.dart';
import '../../../../features/get_products/singletons/items_singleton.dart';
import '../../../../features/hive_repository/hive_boxes.dart';
import '../../providers/ordering_provider_4.dart';
import '../../services/api.dart';
import 'discount_singleton.dart';

class DiscountHelpers {
  static double _priceCat = 0;
  static double _priceProd = 0;
  static double _price = 0;

  static int _currentYear = -1;
  static int _currentMonth = -1;
  static int _currentDay = -1;
  static int _currentWeek = -1;
  static int _currentHour = -1;
  static int _currentMinute = -1;

  static int _startYear = -1;
  static int _startMonth = -1;
  static int _startDay = -1;

  static int _endYear = -1;
  static int _endMonth = -1;
  static int _endDay = -1;

  static int _week = -1;

  static int _startHour = -1;
  static int _startMinute = -1;
  static int _endHour = -1;
  static int _endMinute = -1;

  static ReturnedProduct _availableDiscount = ReturnedProduct();

  static ReturnedProduct get availableDiscount => _availableDiscount;

  static String _productId = '';

  static void productId(String value) => _productId = value;

  static num _maxPrice = 0;

  static void maxPrice() => _maxPrice = 0;

  /// Product & Category
  static ReceiptModelSoldItem4 addDiscountOnProduct(
    ReceiptModelSoldItem4 product,
    String categoryId,
    String clientGroupId,
  ) {
    final box = HiveBoxes.getDiscounts();

    if (box.isEmpty) return product;

    _priceCat = 0;
    _priceProd = 0;
    _price = product.price;

    for (DiscountItem dis in box.values.toList()) {
      if (dis.isExpirable == null || !_checkOptions(dis, clientGroupId)) {
        continue;
      }

      final groupId = dis.discountGroupType?.id;

      /// ---------------------------------------------------------- ///
      ///                        ☑️ Category ☑️                     ///
      /// ---------------------------------------------------------- ///
      if (groupId == '847808d6-5113-4235-a5aa-f5edb044f837') {
        product = _notAllProducts(product, dis, categoryId);
        continue;
      }

      /// ---------------------------------------------------------- ///
      ///                        ✅ Product ✅                      ///
      /// ---------------------------------------------------------- ///
      if (groupId == '22e778e1-e562-4649-b47e-b720a28d831c') {
        product = _isAllProductsCheckAndLogic(product, dis);
        continue;
      }
    }

    product.price = _price;
    product.discountPercent = 100 - (100 * product.price / product.realPrice);

    return product;
  }

  /// BuyXGetY & Free Gift
  static dynamic buyXGetYOrFreeGifts(
    List<ReceiptModelSoldItem4> products,
    String clientGroupId,
    num totalPrice,
    bool isGift,
  ) {
    final box = HiveBoxes.getDiscounts();
    if (box.isEmpty) return null;
    List<ReturnedProduct> returnedProducts = [];
    List<ReturnedGift> returnedGifts = [];

    for (DiscountItem dis in box.values.toList()) {
      if (dis.isExpirable == null || !_checkOptions(dis, clientGroupId)) {
        continue;
      }

      final groupId = dis.discountGroupType?.id;
      final typeId = dis.discountType?.id;

      /// ---------------------------------------------------------- ///
      ///                       ☑️ Buy X Get Y ☑️                   ///
      /// ---------------------------------------------------------- ///
      if (groupId == '86951e75-960f-45d7-9505-9b9cd2ce17a7' &&
          typeId == 'a9f3ceb1-4fa3-4f71-ab81-00889e26616b') {
        final returnedProduct = _getProductIdAndQty(products, dis);
        if (returnedProduct != null) {
          print('Discount bor');
          print(returnedProduct.availableProducts!.first.name);



          returnedProducts.add(returnedProduct);
        }
        continue;
      }

      /// ---------------------------------------------------------- ///
      ///                       ✅ Free Gift ✅                     ///
      /// ---------------------------------------------------------- ///
      if (groupId == 'e13e3ed0-2d03-42f2-8c5f-43bcb3b3c8e9') {
        returnedGifts.addAll(_getFreeGift(totalPrice, dis));
      }
    }

    if (isGift) return returnedGifts;
    return returnedProducts.isEmpty ? [] : returnedProducts;
    // return returnedProducts.isNotEmpty ? returnedProducts : null;
  }

  static List<ReturnedGiftX> getBuyXGetXDiscountsOnly(
      List<ReceiptModelSoldItem4> products, String clientGroupId,
      {bool forDialogOnly = false}) {
    final box = HiveBoxes.getDiscounts();
    if (box.isEmpty) return [];

    List<ReturnedGiftX> result = [];

    for (DiscountItem dis in box.values.toList()) {
      if (dis.isExpirable == null || !_checkOptions(dis, clientGroupId)) {
        continue;
      }

      final groupId = dis.discountGroupType?.id;
      final typeId = dis.discountType?.id;

      // Faqat Buy X Get X turi
      if (groupId == '316b623e-3bb7-43e2-b6d5-1028c927caba' &&
          typeId == '90d1f774-44bd-49be-9bbf-2e9a44558377') {
        final buyXGetXAsGift =
            _getBuyXGetXAsGift(products, dis, forDialogOnly: true);
        result.addAll(buyXGetXAsGift);
      }
    }

    return result;
  }

  /// BuyXGetY
  // static ReturnedProduct? _getProductIdAndQty(
  //   List<ReceiptModelSoldItem4> products,
  //   DiscountItem dis,
  // ) {
  //   final buyXGetY = dis.buyXGetY;
  //
  //   if (buyXGetY == null ||
  //       buyXGetY.buyProductsAmount == null ||
  //       buyXGetY.getProductsAmount == null ||
  //       buyXGetY.productToGet == null ||
  //       buyXGetY.productsToBuy == null ||
  //       buyXGetY.productsToBuy!.isEmpty) {
  //     return null;
  //   }
  //
  //   double length1 = 0;
  //   double length2 = 0;
  //   double value = 0;
  //
  //   for (final productsToBuy in buyXGetY.productsToBuy!) {
  //     for (final product in products) {
  //       /// Available Discounts ///
  //       if (productsToBuy.id == product.productId &&
  //           productsToBuy.id == _productId) {
  //         _availableDiscount = ReturnedProduct(
  //           availableProducts: buyXGetY.productsToBuy!,
  //           returnedProductId: buyXGetY.productToGet!.id ?? '',
  //           returnedProductQuantity: buyXGetY.getProductsAmount ?? 0,
  //           mustProductQuantity: buyXGetY.buyProductsAmount ?? 0,
  //           discountId: dis.id ?? '',
  //           discountName: dis.displayName ?? '',
  //           discountGroupType: dis.discountGroupType!.id,
  //         );
  //       }
  //
  //       if (productsToBuy.id == product.productId &&
  //           buyXGetY.buyProductsAmount! <= product.value &&
  //           productsToBuy.id != buyXGetY.productToGet!.id) {
  //         length1++;
  //         value = product.value;
  //       } else if (productsToBuy.id == product.productId &&
  //           product.value %
  //                   (buyXGetY.buyProductsAmount! +
  //                       buyXGetY.getProductsAmount!) ==
  //               0 &&
  //           productsToBuy.id == buyXGetY.productToGet!.id) {
  //         length2++;
  //         value = product.value;
  //       }
  //     }
  //   }
  //
  //   ReturnedProduct buildResult(num returnedQty) => ReturnedProduct(
  //         availableProducts: buyXGetY.productsToBuy!,
  //         returnedProductId: buyXGetY.productToGet!.id ?? '',
  //         returnedProductQuantity: returnedQty,
  //         mustProductQuantity: buyXGetY.buyProductsAmount ?? 0,
  //         discountId: dis.id ?? '',
  //         discountName: dis.displayName ?? '',
  //         discountGroupType: dis.discountGroupType!.id,
  //       );
  //
  //   if (length1 == buyXGetY.productsToBuy!.length) {
  //     _printDiscountName('Buy X Get Y');
  //     if (dis.isRepeatable == true) {
  //       final qty = ((buyXGetY.getProductsAmount ?? 0).toDouble() *
  //               (value / buyXGetY.buyProductsAmount!.toInt()))
  //           .toInt();
  //       return buildResult(qty);
  //     } else {
  //       return buildResult(buyXGetY.getProductsAmount ?? 0);
  //     }
  //   }
  //
  //   if (length2 == buyXGetY.productsToBuy!.length) {
  //     _printDiscountName('Buy X Get Y');
  //
  //     final buy = buyXGetY.buyProductsAmount ?? 0;
  //     final get = buyXGetY.getProductsAmount ?? 0;
  //     final setSize = buy + get;
  //
  //     if (setSize == 0) return null;
  //
  //     num freeQty = 0;
  //
  //     if (dis.isRepeatable == true) {
  //       final sets = (value / setSize).floor();
  //       freeQty = sets * get;
  //     } else {
  //       if (value >= setSize) {
  //         freeQty = get;  // Faqat bitta tekin, qancha dona bo'lsa ham
  //       }
  //     }
  //
  //     if (freeQty > 0) {
  //       return buildResult(freeQty);
  //     } else {
  //       return null;
  //     }
  //   }
  //
  //
  //
  //   return null;
  // }
  static ReturnedProduct? _getProductIdAndQty(
    List<ReceiptModelSoldItem4> products,
    DiscountItem dis,
  ) {
    final buyXGetY = dis.buyXGetY;

    if (buyXGetY == null ||
        buyXGetY.buyProductsAmount == null ||
        buyXGetY.getProductsAmount == null ||
        buyXGetY.productToGet == null ||
        buyXGetY.productsToBuy == null ||
        buyXGetY.productsToBuy!.isEmpty) {
      return null;
    }

    double length1 = 0;
    double length2 = 0;
    double value = 0;

    // Markirovkali mahsulotlar bir xil productId bilan alohida entry sifatida
    // qo'shiladi (har biri value=1). Umumiy sonni yig'amiz.
    final Map<String, double> totalQtyByProductId = {};
    for (final p in products) {
      totalQtyByProductId[p.productId] =
          (totalQtyByProductId[p.productId] ?? 0) + p.value;
    }

    for (final productsToBuy in buyXGetY.productsToBuy!) {
      // _availableDiscount faqat bir marta o'rnatiladi (UI uchun)
      for (final product in products) {
        if (productsToBuy.id == product.productId &&
            productsToBuy.id == _productId) {
          _availableDiscount = ReturnedProduct(
            availableProducts: buyXGetY.productsToBuy!,
            returnedProductId: buyXGetY.productToGet!.id ?? '',
            returnedProductQuantity: buyXGetY.getProductsAmount ?? 0,
            mustProductQuantity: buyXGetY.buyProductsAmount ?? 0,
            discountId: dis.id ?? '',
            discountName: dis.displayName ?? '',
            discountGroupType: dis.discountGroupType!.id,
          );
          break;
        }
      }

      // Umumiy qty (markirovkali va oddiy mahsulotlar uchun ham to'g'ri)
      final totalQty = totalQtyByProductId[productsToBuy.id] ?? 0;

      if (totalQty > 0 &&
          productsToBuy.id != buyXGetY.productToGet!.id &&
          buyXGetY.buyProductsAmount! <= totalQty) {
        length1++;
        value = totalQty;
      } else if (productsToBuy.id == buyXGetY.productToGet!.id &&
          totalQty > 0) {
        length2++;
        value = totalQty;
      }
    }

    ReturnedProduct buildResult(num returnedQty) => ReturnedProduct(
          availableProducts: buyXGetY.productsToBuy!,
          returnedProductId: buyXGetY.productToGet!.id ?? '',
          returnedProductQuantity: returnedQty,
          mustProductQuantity: buyXGetY.buyProductsAmount ?? 0,
          discountId: dis.id ?? '',
          discountName: dis.displayName ?? '',
          discountGroupType: dis.discountGroupType!.id,
        );

    if (length1 == buyXGetY.productsToBuy!.length) {
      _printDiscountName('Buy X Get Y');
      if (dis.isRepeatable == true) {
        final qty = ((buyXGetY.getProductsAmount ?? 0).toDouble() *
                (value / buyXGetY.buyProductsAmount!.toInt()))
            .toInt();
        return buildResult(qty);
      } else {

        return buildResult(buyXGetY.getProductsAmount ?? 0);
      }
    }

    if (length2 == buyXGetY.productsToBuy!.length) {
      _printDiscountName('Buy X Get Y');

      final buy = buyXGetY.buyProductsAmount ?? 0;
      final get = buyXGetY.getProductsAmount ?? 0;
      final setSize = buy + get;

      if (setSize == 0) return null;

      num freeQty = 0;

      if (dis.isRepeatable == true) {
        final sets = (value / setSize).floor();
        freeQty = sets * get;
      } else {
        if (value >= setSize) {
          freeQty = get;
        }
      }

      if (freeQty > 0) {
        return buildResult(freeQty);
      } else {
        return null;
      }
    }

    return null;
  }

  static bool hasBuyXGetXDiscountForProduct(
    List<ReceiptModelSoldItem4> products,
    String productId,
    String clientGroupId,
  ) {
    final box = HiveBoxes.getDiscounts();
    if (box.isEmpty) return false;

    for (DiscountItem dis in box.values.toList()) {
      if (dis.isExpirable == null || !_checkOptions(dis, clientGroupId)) {
        continue;
      }

      final groupId = dis.discountGroupType?.id;
      final typeId = dis.discountType?.id;

      if (groupId == '316b623e-3bb7-43e2-b6d5-1028c927caba' &&
          typeId == '90d1f774-44bd-49be-9bbf-2e9a44558377') {
        final buyXGetX = dis.buyXGetX;
        if (buyXGetX == null || buyXGetX.productsToBuy == null) continue;

        for (final p in buyXGetX.productsToBuy!) {
          if (p.id == productId) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // static List<ReturnedGiftX> _getBuyXGetXAsGift(
  //   List<ReceiptModelSoldItem4> products,
  //   DiscountItem dis,
  //     {bool forDialogOnly = false}
  // ) {
  //   final buyXGetX = dis.buyXGetX;
  //   List<ReturnedGiftX> result = [];
  //
  //   if (buyXGetX == null ||
  //       buyXGetX.buyProductsAmount == null ||
  //       buyXGetX.getProductsAmount == null ||
  //       buyXGetX.productsToBuy == null ||
  //       buyXGetX.productsToBuy!.isEmpty) {
  //     return result;
  //   }
  //
  //   for (final productToBuy in buyXGetX.productsToBuy!) {
  //     double totalQty = 0.0;
  //
  //     for (final product in products) {
  //       if (product.productId == productToBuy.id) {
  //         totalQty += product.value.toDouble();
  //       }
  //     }
  //
  //     if (totalQty < buyXGetX.buyProductsAmount!.toDouble()) continue;
  //
  //     num freeQty = 0;
  //
  //     if (dis.isRepeatable == true) {
  //       final perSet =
  //           buyXGetX.buyProductsAmount! + buyXGetX.getProductsAmount!;
  //
  //       final sets = (totalQty / perSet.toDouble()).floor();
  //
  //       freeQty = sets * buyXGetX.getProductsAmount!;
  //     } else {
  //       freeQty = buyXGetX.getProductsAmount!;
  //     }
  //
  //     if (freeQty > 0) {
  //       result.add(ReturnedGiftX(
  //         buyAmount: buyXGetX.buyProductsAmount ?? 0,
  //         getProduct: ProductIds(id: productToBuy.id, name: productToBuy.name),
  //         getProductAmount: freeQty.toInt(),
  //         discountId: dis.id ?? '',
  //         discountName: dis.displayName ?? '',
  //         discountGroupType: dis.discountGroupType!.id,
  //       ));
  //     }
  //   }
  //
  //   return result;
  // }
  // static List<ReturnedGiftX> _getBuyXGetXAsGift(
  //   List<ReceiptModelSoldItem4> products,
  //   DiscountItem dis, {
  //   bool forDialogOnly = false,
  // }) {
  //   final buyXGetX = dis.buyXGetX;
  //   List<ReturnedGiftX> result = [];

  //   if (buyXGetX == null ||
  //       buyXGetX.buyProductsAmount == null ||
  //       buyXGetX.getProductsAmount == null ||
  //       buyXGetX.productsToBuy == null ||
  //       buyXGetX.productsToBuy!.isEmpty) {
  //     return result;
  //   }

  //   for (final productToBuy in buyXGetX.productsToBuy!) {
  //     double totalQty = 0.0;

  //     for (final product in products) {
  //       if (product.productId == productToBuy.id) {
  //         totalQty += product.value.toDouble();
  //       }
  //     }
  //     if (forDialogOnly) {
  //       if (totalQty + 1 >= buyXGetX.buyProductsAmount!.toDouble()) {
  //         result.add(ReturnedGiftX(
  //           buyAmount: buyXGetX.buyProductsAmount ?? 0,
  //           getProduct:
  //               ProductIds(id: productToBuy.id, name: productToBuy.name),
  //           getProductAmount: buyXGetX.getProductsAmount ?? 0,
  //           discountId: dis.id ?? '',
  //           discountName: dis.displayName ?? '',
  //           discountGroupType: dis.discountGroupType!.id,
  //         ));
  //       }
  //     }

  //     if (totalQty < buyXGetX.buyProductsAmount!.toDouble()) continue;

  //     num freeQty = 0;

  //     if (dis.isRepeatable == true) {
  //       final perSet =
  //           buyXGetX.buyProductsAmount! + buyXGetX.getProductsAmount!;
  //       final sets = (totalQty / perSet.toDouble()).floor();
  //       freeQty = sets * buyXGetX.getProductsAmount!;
  //     } else {
  //       freeQty = buyXGetX.getProductsAmount!;
  //     }

  //     if (freeQty > 0) {
  //       result.add(ReturnedGiftX(
  //         buyAmount: buyXGetX.buyProductsAmount ?? 0,
  //         getProduct: ProductIds(id: productToBuy.id, name: productToBuy.name),
  //         getProductAmount: freeQty.toInt(),
  //         discountId: dis.id ?? '',
  //         discountName: dis.displayName ?? '',
  //         discountGroupType: dis.discountGroupType!.id,
  //       ));
  //     }
  //   }

  //   return result;
  // }
static List<ReturnedGiftX> _getBuyXGetXAsGift(
  List<ReceiptModelSoldItem4> products,
  DiscountItem dis, {
  bool forDialogOnly = false,
}) {
  final buyXGetX = dis.buyXGetX;
  List<ReturnedGiftX> result = [];

  if (buyXGetX == null ||
      buyXGetX.buyProductsAmount == null ||
      buyXGetX.getProductsAmount == null ||
      buyXGetX.productsToBuy == null ||
      buyXGetX.productsToBuy!.isEmpty) {
    return result;
  }

  for (final productToBuy in buyXGetX.productsToBuy!) {
    double totalQty = 0.0;
    for (final product in products) {
      if (product.productId == productToBuy.id) {
        totalQty += product.value.toDouble();
      }
    }

    if (forDialogOnly) {
      if (totalQty + 1 >= buyXGetX.buyProductsAmount!.toDouble()) {
        result.add(ReturnedGiftX(
          buyAmount: buyXGetX.buyProductsAmount ?? 0,
          getProduct: ProductIds(id: productToBuy.id, name: productToBuy.name),
          getProductAmount: buyXGetX.getProductsAmount ?? 0,
          discountId: dis.id ?? '',
          discountName: dis.displayName ?? '',
          discountGroupType: dis.discountGroupType!.id,
          isRepeatable: dis.isRepeatable ?? false,   // ← BU YERDA UZATAMIZ
        ));
      }
      continue;
    }

    if (totalQty < buyXGetX.buyProductsAmount!.toDouble()) continue;

    num freeQty = 0;
    final buy = buyXGetX.buyProductsAmount!.toDouble();
    final get = buyXGetX.getProductsAmount!.toDouble();

    if (dis.isRepeatable == true) {
      final perSet = buy + get;
      freeQty = perSet > 0 ? (totalQty / perSet).floor() * get : 0;
    } else {
      freeQty = totalQty >= (buy + get) ? get : 0;
    }

    if (freeQty > 0) {
      result.add(ReturnedGiftX(
        buyAmount: buyXGetX.buyProductsAmount ?? 0,
        getProduct: ProductIds(id: productToBuy.id, name: productToBuy.name),
        getProductAmount: freeQty.toInt(),
        discountId: dis.id ?? '',
        discountName: dis.displayName ?? '',
        discountGroupType: dis.discountGroupType!.id,
        isRepeatable: dis.isRepeatable ?? false,
      ));
    }
  }

  return result;
}
  /// Get Free Gift
  static List<ReturnedGift> _getFreeGift(num totalPrice, DiscountItem dis) {
    final gifts = dis.gifts;
    if (gifts == null || gifts.isEmpty) return [];

    final List<ReturnedGift> returned = [];

    for (final gift in gifts) {
      final buyAmount = gift.buyAmount;
      final getProduct = gift.getProduct;
      final getProductAmount = gift.getProductAmount;

      final isValidBuy =
          buyAmount != null && buyAmount > _maxPrice && buyAmount < totalPrice;
      final isValidGift = getProduct != null &&
          getProductAmount != null &&
          getProductAmount > 0;

      if (isValidBuy && isValidGift) {
        _printDiscountName('Free Gift');
        _maxPrice = buyAmount;

        returned.add(
          ReturnedGift(
            buyAmount: buyAmount,
            getProduct: getProduct,
            getProductAmount: getProductAmount,
            discountId: dis.id ?? '',
            discountName: dis.displayName ?? '',
            discountGroupType: dis.discountGroupType!.id,
            isGetX: false,
          ),
        );
      }
    }

    return returned;
  }

  /// Category
  static ReceiptModelSoldItem4 _notAllProducts(
    ReceiptModelSoldItem4 product,
    DiscountItem dis,
    String categoryId,
  ) {
    final isNotAllProducts = dis.isAllProducts == false;
    final categories = dis.categoryIds;

    if (isNotAllProducts && categories != null && categories.isNotEmpty) {
      final exists = categories.any((c) => c.id == categoryId);
      final hasDiscountType = dis.discountType?.id != null;

      if (exists && hasDiscountType) {
        product = _categoryPercentage(product, dis);
        product = _categoryNumeric(product, dis);
      }
    }

    return product;
  }

  /// Product
  static ReceiptModelSoldItem4 _isAllProductsCheckAndLogic(
    ReceiptModelSoldItem4 product,
    DiscountItem dis,
  ) {
    final hasDiscountType = dis.discountType?.id != null;

    if (!hasDiscountType) return product;

    if (dis.isAllProducts == true) {
      product = _productPercentage(product, dis);
      product = _productNumeric(product, dis);
    } else if (dis.isAllProducts == false) {
      final products = dis.productIds;
      final exists = products?.any((p) => p.id == product.productId) ?? false;

      if (exists) {
        product = _productPercentage(product, dis);
        product = _productNumeric(product, dis);
      }
    }

    return product;
  }

  /// Category Percentage (%)
  static ReceiptModelSoldItem4 _categoryPercentage(
    ReceiptModelSoldItem4 product,
    DiscountItem dis,
  ) {
    const categoryDiscountId = 'e908c52f-4c6f-46d8-b765-16e074425cd9';

    final isCategoryPercentage = dis.discountType?.id == categoryDiscountId;
    final discountValue = dis.discountValue;

    if (isCategoryPercentage &&
        discountValue != null &&
        discountValue >= 0 &&
        discountValue <= 100) {
      _printDiscountName('Category Percentage (%)');

      final percentage = discountValue / 100;

      if (_priceCat > 0) {
        if (product.value == 1) {
          product.singleDiscount += _priceCat * percentage;
        }
        _priceCat -= _priceCat * percentage;
      } else {
        if (product.value == 1) {
          product.singleDiscount += product.realPrice * percentage;
        }
        _priceCat = product.realPrice - (product.realPrice * percentage);
      }

      _price = _priceCat;
      product = _addDiscount(product, dis, false);
    }

    product.price = _price;
    return product;
  }

  /// Category Numeric
  static ReceiptModelSoldItem4 _categoryNumeric(
    ReceiptModelSoldItem4 product,
    DiscountItem dis,
  ) {
    const categoryNumericId = 'b78fd1a6-38ed-45a6-b002-caac5de6ebe6';

    final isCategoryNumeric = dis.discountType?.id == categoryNumericId;
    final discountValue = dis.discountValue?.toDouble();

    if (isCategoryNumeric && discountValue != null && discountValue >= 0) {
      _printDiscountName('Category Numeric');

      if (_price <= discountValue) {
        if (product.value == 1) {
          product.singleDiscount += _price;
        }
        _priceCat = 0;
      } else if (_priceCat > 0) {
        if (product.value == 1) {
          product.singleDiscount += discountValue;
        }
        _priceCat -= discountValue;
      } else {
        if (product.value == 1) {
          product.singleDiscount += discountValue;
        }
        _priceCat = product.realPrice - discountValue;
      }

      _price = _priceCat;
      product = _addDiscount(product, dis, true);
    }

    product.price = _price;
    return product;
  }

  /// Product Percentage (%)
  static ReceiptModelSoldItem4 _productPercentage(
    ReceiptModelSoldItem4 product,
    DiscountItem dis,
  ) {
    const productPercentageId = 'e908c52f-4c6f-46d8-b765-16e074425cd9';

    final isProductPercentage = dis.discountType?.id == productPercentageId;
    final discountValue = dis.discountValue;

    if (isProductPercentage &&
        discountValue != null &&
        discountValue >= 0 &&
        discountValue <= 100) {
      _printDiscountName('Product Percentage (%)');

      final percentage = discountValue / 100;

      if (_priceCat > 0 && _priceProd <= 0) {
        if (product.value == 1) {
          product.singleDiscount += _priceCat * percentage;
        }
        _priceProd = _priceCat - (_priceCat * percentage);
      } else if (_priceProd > 0) {
        if (product.value == 1) {
          product.singleDiscount += _priceProd * percentage;
        }
        _priceProd -= _priceProd * percentage;
      } else {
        if (product.value == 1) {
          product.singleDiscount += product.realPrice * percentage;
        }
        _priceProd = product.realPrice - (product.realPrice * percentage);
      }

      _price = _priceProd;
      product = _addDiscount(product, dis, false);
    }

    product.price = _price;
    return product;
  }

  // static ReceiptModelSoldItem4 _productPercentage(
  //     ReceiptModelSoldItem4 product,
  //     DiscountItem dis,
  //     ) {
  //
  //   const productPercentageId = 'e908c52f-4c6f-46d8-b765-16e074425cd9';
  //
  //   final isProductPercentage = dis.discountType?.id == productPercentageId;
  //   final discountValue = dis.discountValue;
  //
  //   if (isProductPercentage && discountValue != null && discountValue >= 0 && discountValue <= 100) {
  //     final percentage = discountValue / 100;
  //
  //     // To‘g‘ri: quantity ni hisobga olish
  //     final originalTotal = product.realPrice * product.value;
  //     final discountedTotal = originalTotal * (1 - percentage);
  //
  //     // Yangi unit price (chegirmali)
  //     final newUnitPrice = product.realPrice * (1 - percentage);
  //
  //     // To‘g‘ri discount summasi (jami chegirma miqdori)
  //     product.singleDiscount = originalTotal - discountedTotal;
  //
  //     _price = newUnitPrice; // bu keyin product.price ga tushadi
  //     product = _addDiscount(product, dis, false);
  //   }
  //
  //   product.price = _price;
  //   return product;
  // }
  /// Product Numeric
  static ReceiptModelSoldItem4 _productNumeric(
    ReceiptModelSoldItem4 product,
    DiscountItem dis,
  ) {
    const productNumericId = 'b78fd1a6-38ed-45a6-b002-caac5de6ebe6';

    final isProductNumeric = dis.discountType?.id == productNumericId;
    final discountValue = dis.discountValue?.toDouble();

    if (isProductNumeric && discountValue != null && discountValue >= 0) {
      _printDiscountName('Product Numeric');

      if (_price <= discountValue) {
        if (product.value == 1) {
          product.singleDiscount += _price;
        }
        _priceProd = 0;
      } else if (_priceCat > 0 && _priceProd <= 0) {
        if (product.value == 1) {
          product.singleDiscount += discountValue;
        }
        _priceProd = _priceCat - discountValue;
      } else if (_priceProd > 0) {
        if (product.value == 1) {
          product.singleDiscount += discountValue;
        }
        _priceProd -= discountValue;
      } else {
        if (product.value == 1) {
          product.singleDiscount += discountValue;
        }
        _priceProd = product.realPrice - discountValue;
      }

      _price = _priceProd;
      product = _addDiscount(product, dis, true);
    }

    product.price = _price;
    return product;
  }

  /// Add Discount
  static ReceiptModelSoldItem4 _addDiscount(
    ReceiptModelSoldItem4 product,
    DiscountItem dis,
    bool isNumeric,
  ) {
    final discountValue = dis.discountValue?.toDouble() ?? 0;

    final disSum =
        isNumeric ? discountValue : product.price * discountValue / 100;

    final productDiscountModel = ProductDiscountModel(
      idd: dis.id ?? '',
      typeId: dis.discountType?.id ?? '',
      typeName: dis.discountType?.label ?? '',
      name: dis.displayName ?? '',
      value: discountValue,
      total: disSum * product.value,
    );

    if (product.value > 0) {
      product.productDiscount
          .removeWhere((e) => e.idd == productDiscountModel.idd);
      product.productDiscount.add(productDiscountModel);
    }

    product = addDiscountForProduct(product);
    return product;
  }

  /// Check Date
  static bool _checkTheDate(DiscountItem dis) {
    bool expires = dis.isExpirable!;

    final now = DateTime.now();
    _currentYear = now.year;
    _currentMonth = now.month;
    _currentDay = now.day;

    if (dis.startDate != null && dis.startDate!.isNotEmpty) {
      dis.startDate = dis.startDate!.replaceAll(' ', 'T');
      _startYear = int.parse(dis.startDate!.split('T')[0].split('-')[0]);
      _startMonth = int.parse(dis.startDate!.split('T')[0].split('-')[1]);
      _startDay = int.parse(dis.startDate!.split('T')[0].split('-')[2]);
    }

    if (expires && dis.expireDate != null && dis.expireDate!.isNotEmpty) {
      dis.expireDate = dis.expireDate!.replaceAll(' ', 'T');
      _endYear = int.parse(dis.expireDate!.split('T')[0].split('-')[0]);
      _endMonth = int.parse(dis.expireDate!.split('T')[0].split('-')[1]);
      _endDay = int.parse(dis.expireDate!.split('T')[0].split('-')[2]);
    }

    if ([
      _currentYear,
      _currentMonth,
      _currentDay,
      _startYear,
      _startMonth,
      _startDay
    ].contains(-1)) {
      return false;
    }

    if (expires && [_endYear, _endMonth, _endDay].contains(-1)) {
      return false;
    }

    if (_currentYear < _startYear) {
      return false;
    } else if (_currentYear == _startYear) {
      if (_currentMonth < _startMonth) {
        return false;
      } else if (_currentMonth == _startMonth) {
        if (_currentDay < _startDay) {
          return false;
        }
      }
    }

    if (expires) {
      if (_currentYear > _endYear) {
        return false;
      } else if (_currentYear == _endYear) {
        if (_currentMonth > _endMonth) {
          return false;
        } else if (_currentMonth == _endMonth) {
          if (_currentDay > _endDay) {
            return false;
          }
        }
      }
    }

    return _checkTheWeek(dis);
  }

  /// Check Week
  static bool _checkTheWeek(DiscountItem dis) {
    if (dis.discountSchedules == null || dis.discountSchedules!.isEmpty) {
      return true;
    }

    final now = DateTime.now();
    _currentWeek = now.weekday;
    _currentHour = now.hour;
    _currentMinute = now.minute;

    for (DiscountSchedules discountSchedules in dis.discountSchedules!) {
      _week = discountSchedules.dayOfWeek ?? -1;

      if (discountSchedules.dayOfWeek == null && _week == -1) {
        _week = 0;
      }

      if (_week == -1) continue;

      if (dis.isWholeDay == true) {
        if (_week + 1 == _currentWeek) return true;
        continue;
      }

      if (dis.isWholeDay == false && _week + 1 == _currentWeek) {
        if (discountSchedules.startTime?.isNotEmpty == true) {
          final parts = discountSchedules.startTime!.split(':');
          _startHour = int.parse(parts[0]);
          _startMinute = int.parse(parts[1]);
        }

        if (discountSchedules.endTime?.isNotEmpty == true) {
          final parts = discountSchedules.endTime!.split(':');
          _endHour = int.parse(parts[0]);
          _endMinute = int.parse(parts[1]);
        }

        if ([_startHour, _startMinute, _endHour, _endMinute].contains(-1)) {
          return false;
        }

        if (_currentHour < _startHour) {
          return false;
        } else if (_currentHour == _startHour) {
          if (_currentMinute < _startMinute) {
            return false;
          }
        }

        if (_currentHour > _endHour) {
          return false;
        } else if (_currentHour == _endHour) {
          if (_currentMinute > _endMinute) {
            return false;
          }
        }
      }
    }

    return true;
  }

  /// Check Shop Id
  static bool _checkShopId(List<ShopIds>? shopIds) =>
      shopIds?.any((ids) => ids.id == Pref.getString(PrefKeys.storeId, '')) ??
      false;

  /// Check Customer Group
  static bool _checkCustomerGroups(
          List<CustomerGroups> customerGroups, String clientGroupId) =>
      customerGroups.any((ids) => ids.id == clientGroupId);

  /// Check Option
  static bool _checkOptions(DiscountItem dis, String clientGroupId) {
    bool isTrue = !dis.isExpirable! ? true : _checkTheDate(dis);
    bool isTrue2 = _checkShopId(dis.shopIds);
    bool isTrue3 = false;
    if (dis.isForAllClients != null && dis.isForAllClients!) {
      isTrue3 = true;
    } else if (dis.customerGroups != null && dis.customerGroups!.isNotEmpty) {
      isTrue3 = _checkCustomerGroups(dis.customerGroups!, clientGroupId);
    }
    return (isTrue && isTrue2 && isTrue3);
  }

  /// Print
  static void _printDiscountName(String name) {
    if (kDebugMode) {
      print('------------------------------------------------------------');
      print('    ✨✨✨✨✨  $name  ✨✨✨✨✨                       ');
      print('------------------------------------------------------------');
    }
  }

  /// Add discount for product
  static ReceiptModelSoldItem4 addDiscountForProduct(
      ReceiptModelSoldItem4 product) {
    if (product.discount.isEmpty) {
      product.discount.add(
        ItemsSingleton.discounter(
            howMuch: (product.singleDiscount),
            quantity: 1,
            where: DiscountFromWhere.single),
      );
    } else {
      for (int i = 0; i < product.discount.length; i++) {
        if (product.discount[i].type == "sum") {
          product.discount.removeAt(i);
        }
      }
      product.discount.add(
        ItemsSingleton.discounter(
            howMuch: (product.singleDiscount),
            quantity: 1,
            where: DiscountFromWhere.single),
      );
    }
    return product;
  }
}
