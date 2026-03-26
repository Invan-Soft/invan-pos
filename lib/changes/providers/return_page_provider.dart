import 'package:flutter/material.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import '../../utils/util_functions.dart';

class ReturnPageProviderr extends ChangeNotifier {
  ReturnPageProviderr({
    required ReceiptModel4 receiptModel4,
  })  : _receiptModel4 = receiptModel4,
        _leftList = receiptModel4.soldItemList;

  final ReceiptModel4 _receiptModel4;
  final List<ReceiptModelSoldItem4> _leftList;
  final List<ReceiptModelSoldItem4> _rightList = [];

  int _leftIndex = 0;
  int _rightIndex = 0;

  /* //////////////////////// PROVIDER GETTERS //////////////////////// */
  /* //////////////////////// PROVIDER GETTERS //////////////////////// */
  /* //////////////////////// PROVIDER GETTERS //////////////////////// */
  /* //////////////////////// PROVIDER GETTERS //////////////////////// */

  ReceiptModel4 get getReceipt => _receiptModel4;

  List<ReceiptModelSoldItem4> get getLeftList => _leftList;

  List<ReceiptModelSoldItem4> get getRightList => _rightList;

  double get getLeftTotalPrice {
    double t = 0;
    for (var element in _leftList) {
      t += UtilFunctions.roundToNearest(element.price * element.value);
    }

    return t;
  }

  double get getRightTotalPrice {
    double t = 0;
    for (var element in _rightList) {
      t += UtilFunctions.roundToNearest(element.price * element.value);
    }

    return t;
  }

  /* //////////////////////// PROVIDER METHODS //////////////////////// */
  /* //////////////////////// PROVIDER METHODS //////////////////////// */
  /* //////////////////////// PROVIDER METHODS //////////////////////// */
  /* //////////////////////// PROVIDER METHODS //////////////////////// */

  void pressLeftIndex(int i) {
    _leftIndex = i;
  }

  void pressRightIndex(int i) {
    _rightIndex = i;
  }

  void pressLeftProduct() {
    final item = _leftList.removeAt(_leftIndex);
    final i = _rightList.indexWhere((e) => e.productId == item.productId);
    if (i >= 0) {
      double v = _rightList[i].value.toDouble();
      v++;
      _rightList[i].value = v;
    } else {
      _rightList.add(item);
    }
    notifyListeners();
  }

  void pressRightProduct() {
    final item = _rightList.removeAt(_rightIndex);
    final i = _leftList.indexWhere((e) => e.productId == item.productId);
    if (i >= 0) {
      double v = _leftList[i].value.toDouble();
      v++;
      _leftList[i].value = v;
    } else {
      _leftList.add(item);
    }
    notifyListeners();
  }

  void pressLeftProductDialog2(double arrivedValue) {
    if (_leftList[_leftIndex].value <= arrivedValue) {
      final item = _leftList.removeAt(_leftIndex);
      final i = _rightList.indexWhere((e) => e.productId == item.productId);
      if (i >= 0) {
        double v = _rightList[i].value.toDouble();
        v += arrivedValue;
        _rightList[i].value = v;
      } else {
        _rightList.add(item);
      }
    } else {
      double v = _leftList[_leftIndex].value.toDouble();
      v -= arrivedValue;
      _leftList[_leftIndex].value = v;
      final item = _itemCopyWith(_leftList[_leftIndex], arrivedValue);
      final i = _rightList.indexWhere((e) => e.productId == item.productId);
      if (i >= 0) {
        double v = _rightList[i].value.toDouble();
        v += arrivedValue;
        _rightList[i].value = v;
      } else {
        _rightList.add(item);
      }
    }

    notifyListeners();
  }

  void pressRightProductDialog2(double arrivedValue) {
    if (_rightList[_rightIndex].value <= arrivedValue) {
      final item = _rightList.removeAt(_rightIndex);
      final i = _leftList.indexWhere((e) => e.productId == item.productId);
      if (i >= 0) {
        double v = _leftList[i].value.toDouble();
        v += arrivedValue;
        _leftList[i].value = v;
      } else {
        _leftList.add(item);
      }
    } else {
      double v = _rightList[_rightIndex].value.toDouble();
      v -= arrivedValue;
      _rightList[_rightIndex].value = v;
      final item = _itemCopyWith(_rightList[_rightIndex], arrivedValue);
      final i = _leftList.indexWhere((e) => e.productId == item.productId);
      if (i >= 0) {
        double v = _leftList[i].value.toDouble();
        v += arrivedValue;
        _leftList[i].value = v;
      } else {
        _leftList.add(item);
      }
    }

    notifyListeners();
  }
}

ReceiptModelSoldItem4 _itemCopyWith(
  ReceiptModelSoldItem4 item,
  double value,
) {
  final receipt = ReceiptModelSoldItem4(
    // inBox: 0,
    tin: item.tin,
    inBox: 0,
    singleDiscount: item.singleDiscount,
    realPrice: item.realPrice,
    onlyPrice: item.realPrice,
    ownerType: item.ownerType,
    soldBy: item.soldBy,
    refundItemId: item.refundItemId,
    cost: item.cost,
    createdTime: item.createdTime,
    price: item.price,
    value: value,
    productId: item.productId,
    productName: item.productName,
    barcode: item.barcode,
    sku: item.sku,
    vat: (item.price * item.vatPercent) / (100 + item.vatPercent),
    mxik: item.mxik,
    discountPercent: item.discountPercent,
    vatPercent: item.vatPercent,
    packageCode: item.packageCode,
    packageName: item.packageName,
    sellerId: item.sellerId,
    vatName: item.vatName,
  );

  return receipt;
}
