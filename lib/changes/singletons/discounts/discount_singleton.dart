/*
    @author Suxrob Sattorov, 9/26/2025, 4:05 PM
*/

import '../../../features/get_discounts/get_discounts.dart';
import '../../services/api.dart';
import 'discount_helpers.dart';

class DiscountSingleton {
  /// Product & Category
  static ReceiptModelSoldItem4 addDiscountOnProduct(
    ReceiptModelSoldItem4 product,
    String categoryId,
    String clientGroupId,
  ) =>
      DiscountHelpers.addDiscountOnProduct(product, categoryId, clientGroupId);

  /// BuyXGetY & Free Gift
  static dynamic buyXGetYOrFreeGifts(
    List<ReceiptModelSoldItem4> products,
    String clientGroupId,
    num totalPrice,
    bool isGift,
  ) =>
      DiscountHelpers.buyXGetYOrFreeGifts(
          products, clientGroupId, totalPrice, isGift);

  static List<ReturnedGiftX> getBuyXGetXDiscounts(
    List<ReceiptModelSoldItem4> products,
    String clientGroupId, {bool forDialogOnly = false}
  ) =>
      DiscountHelpers.getBuyXGetXDiscountsOnly(products, clientGroupId,forDialogOnly: forDialogOnly);

  /// Add discount for product
  static ReceiptModelSoldItem4 addDiscountForProduct(
          ReceiptModelSoldItem4 product) =>
      DiscountHelpers.addDiscountForProduct(product);

  static bool hasBuyXGetXForProduct(String productId, String clientGroupId) {
    return DiscountHelpers.hasBuyXGetXDiscountForProduct(
      [],
      productId,
      clientGroupId,
    );
  }

  static ReturnedProduct get availableDiscount =>
      DiscountHelpers.availableDiscount;

  static void productId(String value) => DiscountHelpers.productId(value);

  static void maxPrice() => DiscountHelpers.maxPrice();
}

class ReturnedProduct {
  List<ProductsToBuy>? availableProducts;
  String? returnedProductId;
  num? returnedProductQuantity;
  num? mustProductQuantity;
  String? discountId;
  String? discountName;
  String? discountGroupType;

  ReturnedProduct({
    this.availableProducts,
    this.returnedProductId,
    this.returnedProductQuantity,
    this.mustProductQuantity,
    this.discountId,
    this.discountName,
    this.discountGroupType,
  });
}

class ReturnedGift {
  num buyAmount;
  ProductIds? getProduct;
  num getProductAmount;
  String? discountId;
  String? discountName;
  String? discountGroupType;
  bool? isGetX;

  ReturnedGift({
    required this.buyAmount,
    required this.getProduct,
    required this.getProductAmount,
    this.discountId,
    this.discountName,
    this.discountGroupType,
    this.isGetX,
  });
}
class ReturnedGiftX {
  num buyAmount;
  ProductIds? getProduct;
  num getProductAmount;
  String? discountId;
  String? discountName;
  String? discountGroupType;
  bool isRepeatable;          // ← YANGI MAYDON

  ReturnedGiftX({
    required this.buyAmount,
    required this.getProduct,
    required this.getProductAmount,
    this.discountId,
    this.discountName,
    this.discountGroupType,
    this.isRepeatable = false,   // default false
  });
}