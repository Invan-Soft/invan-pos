import 'package:flutter/material.dart';
import 'package:invan2/changes/domain/receipt/refund_mark_split.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';

import '../../utils/util_functions.dart';

class ReturnPageProviderr extends ChangeNotifier {
  ReturnPageProviderr({
    required ReceiptModel4 receiptModel4,
    Set<String> refundedMarks = const {},
  })  : _receiptModel4 = receiptModel4,
        _leftList = receiptModel4.soldItemList,
        _refundedMarks = refundedMarks;

  final ReceiptModel4 _receiptModel4;
  final List<ReceiptModelSoldItem4> _leftList;
  final List<ReceiptModelSoldItem4> _rightList = [];

  /// Shu chek bo'yicha oldingi vozvratlarda ketgan KM'lar.
  final Set<String> _refundedMarks;

  /// Havza qatori oxirigacha skanerlanib ro'yxatdan tushganda ortib qolgan
  /// KM'lar (boshqa kassada qaytarilgani noma'lum bo'lgan holat) — o'ngdan
  /// bekor qilinganda qator ular bilan qayta tiklanadi.
  final Map<String, List<String>> _leftoverMarks = {};

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
  /// KM'li qator (bitta KM = bitta qator) hech qaysi qatorga qo'shilmaydi —
  /// fiskalga har KM alohida pozitsiya bo'lib ketadi.
  bool _sameRow(ReceiptModelSoldItem4 a, ReceiptModelSoldItem4 b) =>
      a.productId == b.productId &&
      (a.saleType == 2) == (b.saleType == 2) &&
      (a.mark ?? '') == (b.mark ?? '');

  // Server item'i ham kalitda: KM bekor qilinganda boshqa item'ning havzasiga
  // tushib qolmasin (serverga KM o'z item id'si bilan ketadi).
  String _kindKey(ReceiptModelSoldItem4 e) =>
      '${e.refundItemId}|${e.productId}|${e.saleType == 2}';

  /// Chap qator markirovkali (KM havzasi bor) — faqat skanerlab qaytariladi.
  bool needsScan(ReceiptModelSoldItem4 e) => e.mark?.isNotEmpty ?? false;

  /// Bosilgan chap qatorga skanerlangan KM. Havzada bo'lsa aynan o'sha 1 dona
  /// (blok qatorida 1 blok) o'ngga o'sha KM bilan alohida qator bo'lib o'tadi —
  /// fiskalga sotuvdagidek bitta KM = bitta pozitsiya ketadi.
  RefundScanResult scanMark(ReceiptModelSoldItem4 row, String raw) {
    final candidates = RefundMarkScan.candidates(raw);
    final bool isBlock = row.saleType == 2;
    final pool = RefundMarkSplit.marksOf(row.mark);
    final result = RefundMarkScan.check(
      candidates: candidates,
      isBlockRow: isBlock,
      pool: pool,
      otherKindPool: _poolOf(row.productId, block: !isBlock),
      inRight: {
        for (final e in _rightList)
          if (needsScan(e)) e.mark!,
      },
      refunded: _refundedMarks,
    );
    if (result == RefundScanResult.notInReceipt &&
        RefundMarkScan.matchIn(candidates, _allPools()) != null) {
      return RefundScanResult.otherProduct;
    }
    if (result != RefundScanResult.matched || !_leftList.contains(row)) {
      return result;
    }

    final String km = RefundMarkScan.matchIn(candidates, pool)!;
    final int unit = isBlock ? row.boxValue : 1;
    pool.remove(km);
    row.value -= unit;
    row.mark = pool.isEmpty ? null : pool.join('\n');
    _syncBoxQuantity(row);
    if (row.value <= 0) {
      _leftList.remove(row);
      if (pool.isNotEmpty) _leftoverMarks[_kindKey(row)] = pool;
    }
    _rightList.add(_itemCopyWith(row, unit.toDouble(), mark: km));
    notifyListeners();
    return result;
  }

  List<String> _poolOf(String productId, {required bool block}) => [
        for (final e in _leftList)
          if (e.productId == productId && (e.saleType == 2) == block && needsScan(e))
            ...RefundMarkSplit.marksOf(e.mark),
        for (final entry in _leftoverMarks.entries)
          if (entry.key.endsWith('|$productId|$block')) ...entry.value,
      ];

  /// Chekdagi barcha mahsulotlarning qaytarilmagan KM'lari.
  List<String> _allPools() => [
        for (final e in _leftList)
          if (needsScan(e)) ...RefundMarkSplit.marksOf(e.mark),
        for (final v in _leftoverMarks.values) ...v,
      ];

  /// O'ngdagi KM qatori bekor qilindi — KM chapdagi havzaga qaytadi.
  void _returnMarkToPool(ReceiptModelSoldItem4 item) {
    final key = _kindKey(item);
    final i = _leftList.indexWhere((e) => _kindKey(e) == key && needsScan(e));
    if (i >= 0) {
      final row = _leftList[i];
      row.value += item.value;
      row.mark = [...RefundMarkSplit.marksOf(row.mark), item.mark!].join('\n');
      _syncBoxQuantity(row);
    } else {
      item.mark = [item.mark!, ...?_leftoverMarks.remove(key)].join('\n');
      _leftList.add(item);
    }
  }

  /// value dona hisobida o'zgargach blok sonini sinxron ushlaymiz.
  void _syncBoxQuantity(ReceiptModelSoldItem4 e) {
    if (e.saleType == 2 && e.boxValue > 0) {
      e.boxQuantity = e.value ~/ e.boxValue;
    }
  }

  void pressLeftProduct() {
    if (needsScan(_leftList[_leftIndex])) return; // faqat scanMark orqali
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
    if (needsScan(item)) {
      _returnMarkToPool(item);
      notifyListeners();
      return;
    }
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
    if (needsScan(_leftList[_leftIndex])) return; // faqat scanMark orqali
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
  double value, {
  String? mark,
}) {
  final receipt = ReceiptModelSoldItem4(
    // Bitta KM — fiskal `Label` (blok qatorida blok KM'i, savatdagidek).
    mark: mark,
    marking: mark != null && item.saleType != 2,
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
