import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'operation_on_product_dialog.dart';

class OperationOnProduct {
  static Future<void> operationOnProductDialog({
    required BuildContext context,
    required bool isClientMinimumPrice,
    required ReceiptModelSoldItem4 item,
  }) async {
    final focusedItem = ReceiptModelSoldItem4(
      isPriceOnlyChanged: item.isPriceOnlyChanged,
      inBox: item.inBox,
      isDeleted: item.isDeleted,
      soldBy: item.soldBy,
      onlyPrice: item.onlyPrice,
      cost: item.cost,
      singleDiscount: item.singleDiscount,
      createdTime: item.createdTime,
      price: item.price,
      value: item.value,
      ownerType: item.ownerType,
      realPrice: item.realPrice,
      productId: item.productId,
      productName: item.productName,
      marking: item.marking,
      mark: item.mark,
      commissionTIN: item.commissionTIN,
      barcode: item.barcode,
      sku: item.sku,
      vat: (item.price * item.vatPercent) / (100 + item.vatPercent),
      mxik: item.mxik,
      packageCode: item.packageCode,
      packageName: item.packageName,
      discountPercent: item.discountPercent ?? 0,
      vatPercent: item.vatPercent,
      isPriceChanged: item.isPriceChanged,
      tin: item.tin,
      sellerId: item.sellerId,
      vatName: item.vatName,
      isKg: item.isKg,
    );
    focusedItem.discount.addAll(item.discount);
    focusedItem.productDiscount.addAll(item.productDiscount);
    await showDialog(
      context: context,
      builder: (_) => OperationOnProductDialog(
        item: focusedItem,
        isClientMinimumPrice: isClientMinimumPrice,
      ),
    );
    return;
  }
}
