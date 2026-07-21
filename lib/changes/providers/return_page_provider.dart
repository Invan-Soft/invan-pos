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

  void pressLeftIndex(int i) {
    _leftIndex = i;
  }

  void pressRightIndex(int i) {
    _rightIndex = i;
  }

  /// Blok qatori (saleType==2) faqat blok qatoriga, dona qatori dona qatoriga
  /// qo'shiladi — aks holda blok donaga aralashib blok granulyarligi buziladi.
  bool _sameRow(ReceiptModelSoldItem4 a, ReceiptModelSoldItem4 b) =>
      a.productId == b.productId && (a.saleType == 2) == (b.saleType == 2);

  /// value dona hisobida o'zgargach blok sonini sinxron ushlaymiz.
  void _syncBoxQuantity(ReceiptModelSoldItem4 e) {
    if (e.saleType == 2 && e.boxValue > 0) {
      e.boxQuantity = e.value ~/ e.boxValue;
    }
  }

  void pressLeftProduct() {
    final item = _leftList.removeAt(_leftIndex);
    final i = _rightList.indexWhere((e) => _sameRow(e, item));
    if (i >= 0) {
      double v = _rightList[i].value.toDouble();
      // Butun qator ko'chdi — blok qatorida value=boxValue×blok (dona), oddiyda 1
      v += item.value;
      _rightList[i].value = v;
      _syncBoxQuantity(_rightList[i]);
    } else {
      _rightList.add(item);
    }
    notifyListeners();
  }

  void pressRightProduct() {
    final item = _rightList.removeAt(_rightIndex);
    final i = _leftList.indexWhere((e) => _sameRow(e, item));
    if (i >= 0) {
      double v = _leftList[i].value.toDouble();
      v += item.value;
      _leftList[i].value = v;
      _syncBoxQuantity(_leftList[i]);
    } else {
      _leftList.add(item);
    }
    notifyListeners();
  }

  void pressLeftProductDialog2(double arrivedValue) {
    if (_leftList[_leftIndex].value <= arrivedValue) {
      final item = _leftList.removeAt(_leftIndex);
      final i = _rightList.indexWhere((e) => _sameRow(e, item));
      if (i >= 0) {
        double v = _rightList[i].value.toDouble();
        v += arrivedValue;
        _rightList[i].value = v;
        _syncBoxQuantity(_rightList[i]);
      } else {
        _rightList.add(item);
      }
    } else {
      double v = _leftList[_leftIndex].value.toDouble();
      v -= arrivedValue;
      _leftList[_leftIndex].value = v;
      _syncBoxQuantity(_leftList[_leftIndex]);
      final item = _itemCopyWith(_leftList[_leftIndex], arrivedValue);
      final i = _rightList.indexWhere((e) => _sameRow(e, item));
      if (i >= 0) {
        double v = _rightList[i].value.toDouble();
        v += arrivedValue;
        _rightList[i].value = v;
        _syncBoxQuantity(_rightList[i]);
      } else {
        _rightList.add(item);
      }
    }

    notifyListeners();
  }

  void pressRightProductDialog2(double arrivedValue) {
    if (_rightList[_rightIndex].value <= arrivedValue) {
      final item = _rightList.removeAt(_rightIndex);
      final i = _leftList.indexWhere((e) => _sameRow(e, item));
      if (i >= 0) {
        double v = _leftList[i].value.toDouble();
        v += arrivedValue;
        _leftList[i].value = v;
        _syncBoxQuantity(_leftList[i]);
      } else {
        _leftList.add(item);
      }
    } else {
      double v = _rightList[_rightIndex].value.toDouble();
      v -= arrivedValue;
      _rightList[_rightIndex].value = v;
      _syncBoxQuantity(_rightList[_rightIndex]);
      final item = _itemCopyWith(_rightList[_rightIndex], arrivedValue);
      final i = _leftList.indexWhere((e) => _sameRow(e, item));
      if (i >= 0) {
        double v = _leftList[i].value.toDouble();
        v += arrivedValue;
        _leftList[i].value = v;
        _syncBoxQuantity(_leftList[i]);
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
    saleType: item.saleType,
    boxValue: item.boxValue,
    boxQuantity: item.boxValue > 0 ? value ~/ item.boxValue : 0,
  );

  return receipt;
}
