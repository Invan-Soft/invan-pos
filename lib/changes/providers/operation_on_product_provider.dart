
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

import '../../features/home/features/operation_on_product/delete_item/input_alert_dialog.dart';
import 'ordering_provider_4.dart';

class OperationOnProductProvider extends ChangeNotifier {
  OperationOnProductProvider({
    required ReceiptModelSoldItem4 item,
    required bool isClientMinimumPrice,
  })  : _isClientMinimumPrice = isClientMinimumPrice,
        target = item,
        _currentEmployee = HiveBoxes.getCurrentEmployee! {
    _oldValue = target.value.toDouble();
  }

  final Employee? _currentEmployee;

  bool _dialogOpened = false;
  bool _ignoreInput = false;

  bool get isDialogOpened => _dialogOpened;

  bool get isInputIgnored => _ignoreInput;

  num itemPrice = 0;
  final bool _isClientMinimumPrice;
  final ReceiptModelSoldItem4 target;
  bool _saveButtonIsEnabled = true;
  bool _dotted = false;
  FocusNode focusNode = FocusNode();
  Timer? _debounceTimer;


  String get boxValueStr {
    try {
      return MoneyFormatter.inputMoneyFormatter
          .format(target.value ~/ target.inBox);
    } catch (e) {
      return "error";
    }
  }

  int get boxValueInt {
    try {
      return target.value ~/ target.inBox;
    } catch (e) {
      return 0;
    }
  }

  String get discountStr =>
      MoneyFormatter.inputMoneyFormatter.format(target.discountPercent);

  String get priceStr =>
      MoneyFormatter.inputMoneyFormatter.format(target.price);

  String get onlyPriceStr =>
      MoneyFormatter.inputMoneyFormatter.format(target.onlyPrice);
  bool onlyPriceIsEdited = false;
  bool _usedDiscountInput = false;
  double _oldValue = 0;

  String get valueStr {
    if (target.soldBy == "box") {
      return MoneyFormatter.inputMoneyFormatter
          .format(target.value % target.inBox);
    }
    return "${MoneyFormatter.inputMoneyFormatter.format(target.value)}${_dotted ? "." : ""}";
  }

  double get _outsideBox => target.value.toDouble() % target.inBox;

  double get basePrice {
    return target.realPrice.toDouble();
  }

  bool get getSaveButtonIsEnabled => _saveButtonIsEnabled;

  ReceiptModelSoldItem4 get getItem => target;



  Future<void> selectInputWithCheck(int v, BuildContext context) async {
    if (v == 1 && target.value > 0) {
      double currentValue = target.value.toDouble();

      focusNode.requestFocus();
      _selectedInput = v;
      _switchSelectedAlls();
      notifyListeners();
    } else {
      selectInput(v);
    }
  }

  void increaseQuantity(int n) {
    _cancelSelectedAll();
    if (target.marking) return;

    target.value = n + target.value;

    ItemModel item = ItemsSingleton.getProductById(target.productId)!;

    double price;
    if (target.isPriceOnlyChanged) {
      price = target.onlyPrice;
    } else {
      price = ItemsSingleton.finalPrice(item, target.value.toInt(), target.isKg)
          .toDouble();
    }

    if (!target.isPriceOnlyChanged) {
      target.realPrice = price;
      target.price = price;
      target.onlyPrice = price;
    }

    _checkSaveButtonIsEnable();
    notifyListeners();
  }

  void decreaseQuantity(int n) {
    _cancelSelectedAll();
    if (n < target.value) {
      target.value = target.value - n;

      ItemModel item = ItemsSingleton.getProductById(target.productId)!;

      double price;
      if (target.isPriceOnlyChanged) {
        price = target.onlyPrice;
      } else {
        price =
            ItemsSingleton.finalPrice(item, target.value.toInt(), target.isKg)
                .toDouble();
      }

      if (!target.isPriceOnlyChanged) {
        target.realPrice = price;
        target.price = price;
        target.onlyPrice = price;
      }
      _updatePricesAfterQuantityChange();

      _checkSaveButtonIsEnable();
      notifyListeners();
    }
  }

  void _updatePricesAfterQuantityChange() {
    ItemModel item = ItemsSingleton.getProductById(target.productId)!;

    double price;
    if (target.isPriceOnlyChanged) {
      price = target.onlyPrice;
    } else {
      price = ItemsSingleton.finalPrice(item, target.value.toInt(), target.isKg)
          .toDouble();
    }

    if (!target.isPriceOnlyChanged) {
      target.realPrice = price;
      target.price = price;
      target.onlyPrice = price;
    }
  }

  Future<bool> attemptDecreaseQuantity(int amount, BuildContext context) async {
    if (_currentEmployee?.access?.deletePrice == true) {
      decreaseQuantity(amount);
      return true;
    }

    _ignoreInput = true;

    final Employee? authorizedEmployee =
        await _showInputAlertForDecrease(context);

    if (authorizedEmployee != null) {
      decreaseQuantity(amount);

      await Future.delayed(Duration(milliseconds: 300));
      _ignoreInput = false;

      return true;
    }

    await Future.delayed(Duration(milliseconds: 300));
    _ignoreInput = false;

    return false;
  }

  Future<Employee?> _showInputAlertForDecrease(BuildContext context) async {
    final result = await showDialog<Employee?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return InputAlertDialog(
          onValueEntered: (Employee employee) {
            if (employee.access?.deletePrice == true) {
              Navigator.pop(dialogContext, employee);
            } else {
              Navigator.pop(dialogContext, null);
            }
          },
          onUniversalPinEntered: () {
            Navigator.pop(dialogContext, HiveBoxes.getCurrentEmployee);
          },
        );
      },
    );

    await Future.delayed(Duration(milliseconds: 100));
    focusNode.requestFocus();

    return result;
  }

  void _checkSaveButtonIsEnable() {
    if (target.value > 0) {
      _saveButtonIsEnabled = true;
    } else {
      _saveButtonIsEnabled = false;
    }
  }

  String? _commitentt;
  bool? _commitenON;

  void onINNcomitenta(bool v, String comitent) {
    _commitenON = v;
    _commitentt = comitent;
  }

  Future<void> onSaveButtonPressed(BuildContext context) async {
    final bool priceManuallyEdited =
        onlyPriceIsEdited || target.isPriceOnlyChanged || target.isPriceChanged;

    if (priceManuallyEdited) {
      target.discount.clear();
      if (_usedDiscountInput) {
        // Discount input used: preserve discountPercent for strikethrough.
        // Send original price to server + singleDiscount so adminka shows
        // the discount correctly (toJson sends "price": onlyPrice).
        target.singleDiscount = (target.realPrice - target.price).clamp(0.0, double.infinity);
        target.onlyPrice = target.realPrice; // server sees original price
      } else {
        target.discountPercent = 0;
      }
      target.isPriceOnlyChanged = true;
      target.isPriceChanged = true;
    } else {
      target.discount.removeWhere((d) => d.type == "sum");
    }

    if (_commitenON ?? false) {
      target.tin = _commitentt;
      _commitenON = false;
      _commitentt = _commitentt;
    }

    if (onlyPriceIsEdited == true) {
      target.price = target.onlyPrice;
      target.isPriceOnlyChanged = true;
    }

    await Provider.of<OrderingProvider4>(context, listen: false)
        .pressDialogSaveButton(target);
    AppNavigation.pop();
    Provider.of<OrderingProvider4>(context, listen: false).freeGiftDialog();
  }


  List<bool> isSelectedAlls = List.generate(6, (index) => index == 1);
  int _selectedInput = 1;

  _cancelSelectedAll() {
    if (isSelectedAlls.contains(true)) {
      isSelectedAlls = List.generate(6, (index) => false);
      notifyListeners();
    }
  }

  _switchSelectedAlls() {
    isSelectedAlls = List.generate(
        6, (index) => index == _selectedInput ? !isSelectedAlls[index] : false);
    notifyListeners();
  }

  selectInput(int v) {
    focusNode.requestFocus();
    _selectedInput = v;
    _switchSelectedAlls();
    notifyListeners();
  }

  onNumPressed(String s) {
    switch (_selectedInput) {
      case 0:
        if (s != '.') onPriceChanged(num.parse(s));
        break;
      case 1: // stands for value
        onCountChanged(s);
        break;
      case 2: // stands for box
        if (s != '.') onBoxChanged(num.parse(s));
        break;
      case 3: // stands for discount
        if (s != '.') onDiscountChanged(num.parse(s));
        break;
      case 4: // stands for total
        if (s != '.') onTotalPriceChanged(num.parse(s));
        break;
      case 5: // stands for discount
        if (s != '.') onlyPriceChanged(num.parse(s));
        break;
    }
    focusNode.requestFocus();
  }

  void onPriceChanged(num v) {
    if (!(_currentEmployee?.access?.editPrice ?? false)) {
      return;
    }

    if (!_chekFor122(target.price)) {
      return;
    }

    double newPrice;

    if (v == 10) {
      newPrice = (target.price ~/ 10).toDouble();
    } else {
      newPrice = _extend(target.price, v).toDouble();

      if (isSelectedAlls[_selectedInput]) {
        _switchSelectedAlls();
        newPrice = v.toDouble();
      }
    }

    target.discount.clear();
    target.discountPercent = 0;
    target.isPriceOnlyChanged = true;
    target.isPriceChanged = true;
    _usedDiscountInput = true;
    // ====================================================

    target.price = newPrice;
    target.onlyPrice = newPrice;
    // target.realPrice is intentionally NOT changed here:
    // it holds the original price so strikethrough is shown in the order list.

    if (newPrice < basePrice && basePrice > 0) {
      target.discountPercent = ((basePrice - newPrice) / basePrice) * 100;
    } else {
      target.discountPercent = 0;
    }

    notifyListeners();
  }

  void onlyPriceChanged(num v) {
    if (!(_currentEmployee?.access?.editPrice ?? false)) {
      return;
    }

    if (!_chekFor122(target.onlyPrice)) {
      return;
    }

    double newOnlyPrice;

    if (v == 10) {
      newOnlyPrice = (target.onlyPrice ~/ 10).toDouble();
    } else {
      newOnlyPrice = _extend(target.onlyPrice, v).toDouble();

      if (isSelectedAlls[_selectedInput]) {
        _switchSelectedAlls();
        newOnlyPrice = v.toDouble();
        target.discountPercent = 0;
      }
    }

    target.discount.clear();
    target.discountPercent = 0;
    target.isPriceOnlyChanged = true;
    target.isPriceChanged = true;
    onlyPriceIsEdited = true;

    target.onlyPrice = newOnlyPrice;
    target.price = newOnlyPrice;
    target.realPrice = newOnlyPrice;

    if (newOnlyPrice < basePrice && basePrice > 0) {
      target.discountPercent = ((basePrice - newOnlyPrice) / basePrice) * 100;
    } else {
      target.discountPercent = 0;
    }

    notifyListeners();
  }

  bool isDouble = false;
  bool index1 = false;
  bool index2 = false;
  bool index3 = false;
  double? _snapshotBeforeTyping;

  void onCountChanged(String s) {
    if (_ignoreInput) {
      return;
    }

    if (target.marking) {
      return;
    }
    if (_dialogOpened) {
      return;
    }

    final double oldValue = target.value.toDouble();

    if (_debounceTimer == null || !_debounceTimer!.isActive) {
      _snapshotBeforeTyping = target.value.toDouble();
    }

    if (target.isKg) {
      if (s == '10') {
        if (num.parse((target.value % 1).toStringAsFixed(1)) == 0) {
          target.value = (target.value / 10).toInt().toDouble();
          isDouble = false;
          index1 = false;
          index2 = false;
          index3 = false;
        } else {
          String valueStr = target.value.toString();
          if (valueStr.contains('.')) {
            if (valueStr.split('.')[1].length == 3) {
              index1 = false;
              index2 = false;
              index3 = true;
            } else if (valueStr.split('.')[1].length == 2) {
              index1 = false;
              index2 = true;
              index3 = false;
            } else if (valueStr.split('.')[1].length == 1) {
              index1 = true;
              index2 = false;
              index3 = false;
            }

            valueStr = valueStr.substring(0, valueStr.length - 1);
            if (valueStr.endsWith('.')) {
              valueStr = valueStr.substring(0, valueStr.length - 1);
            }
          } else {
            valueStr = "0";
          }
          target.value = double.tryParse(valueStr) ?? target.value;

          isDouble = true;
        }
      }
      num v = 0;
      if (s == '.' && !isDouble) {
        isDouble = true;
        index1 = true;
      } else if (s != '10' && s != '.') {
        v = num.parse(s);
        if (!isSelectedAlls[_selectedInput] &&
            !isDouble &&
            num.parse((target.value % 1).toStringAsFixed(1)) > 0) {
          isDouble = true;
          index2 = true;
          if (num.parse((target.value % 1 * 10 % 1).toStringAsFixed(1)) > 0) {
            index3 = true;
            index2 = false;
            if (num.parse(
                    (target.value % 1 * 10 % 1 * 10 % 1).toStringAsFixed(1)) >
                0) {
              index3 = false;
            }
          }
        }

        if (isDouble && index1) {
          v /= 10;
          index2 = true;
          index1 = false;
        } else if (isDouble && index2) {
          v /= 100;
          index3 = true;
          index2 = false;
        } else if (isDouble && index3) {
          v /= 1000;
          index3 = false;
        }

        if (isDouble && v > 0.99) v = 0;

        if (!_chekFor122(target.value)) {
          return;
        }

        if (isSelectedAlls[_selectedInput]) {
          _switchSelectedAlls();
          isDouble = false;
          index1 = false;
          index2 = false;
          index3 = false;
          target.value = v + 0;
        } else {
          target.value = _extendValueDouble(target.value, v) + 0;
        }

        if (!target.isPriceChanged) {
          target.price = basePrice;
        }

        ItemModel item = ItemsSingleton.getProductById(target.productId)!;

        double price;
        if (target.isPriceOnlyChanged) {
          price = target.onlyPrice;
        } else {
          price =
              ItemsSingleton.finalPrice(item, target.value.toInt(), target.isKg)
                  .toDouble();
        }

        if (!target.isPriceOnlyChanged) {
          target.realPrice = price;
          target.price = price;
          target.onlyPrice = price;
        }
      }
    } else {
      num v = num.parse(s);

      if (!_chekFor122(target.value)) {
        return;
      }

      if (v == 10) {
        target.value =
            double.parse((target.value / 10).toString().split('.')[0]);
      } else if (isSelectedAlls[_selectedInput]) {
        _switchSelectedAlls();
        target.value = v + 0;
      } else {
        target.value = _extendValue(target.value, v) + 0;
      }

      if (!target.isPriceChanged) {
        target.price = basePrice;
      }

      ItemModel item = ItemsSingleton.getProductById(target.productId)!;

      double price;
      if (target.isPriceOnlyChanged) {
        price = target.onlyPrice;
      } else {
        price =
            ItemsSingleton.finalPrice(item, target.value.toInt(), target.isKg)
                .toDouble();
      }

      if (!target.isPriceOnlyChanged) {
        target.realPrice = price;
        target.price = price;
        target.onlyPrice = price;
      }
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final double snapshot = _snapshotBeforeTyping ?? _oldValue;

      if (target.value < snapshot && snapshot > 0) {
        final double newValue = target.value.toDouble();
        final num decreaseAmount = snapshot - newValue;

        target.value = snapshot;
        _updatePricesAfterQuantityChange();

        _dialogOpened = true;
        _ignoreInput = true;
        _snapshotBeforeTyping = null;

        attemptDecreaseQuantity(
          decreaseAmount.toInt(),
          focusNode.context!,
        ).then((success) {
          _dialogOpened = false;
          _ignoreInput = false;

          if (success) {
            target.value = newValue;
            _updatePricesAfterQuantityChange();
            _oldValue = target.value.toDouble();
          } else {
            _oldValue = snapshot;
          }

          notifyListeners();
        });
      } else {
        _snapshotBeforeTyping = null;
        _oldValue = target.value.toDouble();
      }

      notifyListeners();
    });
    notifyListeners();
  }

  void onTotalPriceChanged(num v) {
    if (true == true) {
      num summa = target.price * target.value;

      if (isSelectedAlls[_selectedInput]) {
        summa = v;
        _switchSelectedAlls();
      } else {
        summa = _extend(summa, v);
      }

      double difference = (basePrice * target.value) - summa;

      target.discountPercent = difference / (basePrice * (target.value / 100));

      target.price = basePrice - (target.discountPercent! * (basePrice / 100));
      target.isPriceChanged = true;
    } else {
      return;
    }
  }

  onBackSpacePressed() {
    switch (_selectedInput) {
      case 0: // stands for price
        {
          target.price = _cutBack(target.price).toDouble();

          if (isSelectedAlls[_selectedInput] || target.price < 10) {
            _switchSelectedAlls();
            target.price = 0;
            target.discountPercent = 100;
          }
          double difference = basePrice - target.price;
          if (difference > 0) {
            target.discountPercent = difference / (basePrice / 100);
          }
        }
        break;
      case 1: // stands for value
        {
          if (target.value == 0) return;

          if (isSelectedAlls[_selectedInput]) {
            _switchSelectedAlls();
            target.value = 0;
            target.discountPercent = 0;
            target.price = basePrice;
            _checkSaveButtonIsEnable();
            notifyListeners();
            return;
          }

          target.value = _cutBackValue(target.value).toDouble();
        }
        break;
      case 2: // stands for box
        {
          if (boxValueInt == 0) return;
          if (boxValueInt < 10 || isSelectedAlls[_selectedInput]) {
            if (isSelectedAlls[_selectedInput]) {
              _switchSelectedAlls();
            }
            target.value = target.value % target.inBox;
            notifyListeners();
            return;
          }
          double outsideBox = target.value.toDouble() % target.inBox;
          target.value = _cutBack(boxValueInt) * target.inBox + outsideBox;
        }
        break;
      case 3: // stands for discount
        {
          if ((target.discountPercent ?? 0) == 0) {
            return target.discountPercent = 0;
          }
          if ((target.discountPercent ?? 0) < 10 ||
              isSelectedAlls[_selectedInput]) {
            if (isSelectedAlls[_selectedInput]) {
              _switchSelectedAlls();
            }
            target.discountPercent = 0;
            target.price = basePrice;
            notifyListeners();
            return;
          }

          target.discountPercent =
              _cutBack(target.discountPercent ?? 0).toDouble();

          target.price = double.parse(
              (basePrice - (target.discountPercent! * (basePrice / 100)))
                  .toStringAsFixed(0));
        }
        break;

      case 4: // stands for total
        {
          num summa = target.price * target.value;

          if (isSelectedAlls[_selectedInput]) {
            if (isSelectedAlls[_selectedInput]) {
              _switchSelectedAlls();
            }
            summa = 0;
            target.price = 0;
            target.discountPercent = 0;
            notifyListeners();
            return;
          }

          summa = _cutBack(summa);
          target.price = _countPriceFromTotal(summa);
          target.discountPercent = _countDiscountPercent();
        }
        break;
      case 5: // stands for total
        {
          num summa = target.onlyPrice * target.value;
          if (isSelectedAlls[_selectedInput]) {
            if (isSelectedAlls[_selectedInput]) {
              _switchSelectedAlls();
            }
            summa = 0;
            target.onlyPrice = 0;
            target.discountPercent = 0;
            notifyListeners();
            return;
          }
          summa = _cutBack(summa);
          target.onlyPrice = _countPriceFromTotal(summa);
        }
        break;
    }

    focusNode.requestFocus();
    notifyListeners();
  }

  onDotPressed() {
    switch (_selectedInput) {
      case 0: // stands for price
        break;
      case 1: // stands for  value
        {
          if (target.value % 1 == 0) {
            if (isSelectedAlls[_selectedInput]) {
              _switchSelectedAlls();
              if (!_dotted) {
                _dotted = true;
              }
              target.value = 0;
            } else {
              if (!_dotted) {
                _dotted = true;
              }
            }
          }
        }
        break;
      case 2:
        break;
      case 3:
        break;
      case 4:
        break;
    }
    focusNode.requestFocus();
    notifyListeners();
  }

  bool _chekFor122(num v) => v < 100000000000;

  double _countPriceFromTotal(num total) {
    num v = target.soldBy == "box"
        ? (boxValueInt * target.inBox) + target.value
        : target.value;
    final result = total / v;
    return result;
  }

  double _countDiscountPercent() {
    double differance = basePrice - target.price;
    if (differance > 0) {
      return differance / (basePrice / 100);
    }
    return 0;
  }

  _extend(num n, num v) => (n * 10) + v;

  num _extendValue(num n, num v) {
    if (_dotted) {
      _dotted = false;
      final result = num.parse("${n.toInt()}.$v");
      return result;
    }
    final remainder = n % 1;
    if (remainder <= 0) return (n * 10) + v;
    int indexOfDot = -1;
    String str = n.toString();
    for (int i = 0; i < str.length; i++) {
      if (str[i] == ".") {
        indexOfDot = i;
      }
    }
    String remainderAsString = str.substring(indexOfDot);

    if (remainderAsString.length > 3) return n;
    num result = num.parse("${n.toInt()}$remainderAsString$v");
    return result;
  }

  num _extendValueDouble(num n, num v) {
    if (_dotted) {
      _dotted = false;
      final result = num.parse("${n.toDouble()}");
      return result;
    }
    final remainder = n % 1;
    if (remainder <= 0 && v > 0.99) return (n * 10) + v;
    if (remainder <= 0 && v == 0 && !isDouble) return (n * 10) + v;
    n = n + v;
    num result = num.parse("${n.toDouble()}");
    return result;
  }

  _cutBackValue(num n) {
    if (_dotted) {
      _dotted = false;
      return n;
    }

    {
      if (num.parse((target.value % 1).toStringAsFixed(1)) == 0) {
        target.value = (target.value / 10).toInt().toDouble();
        isDouble = false;
        index1 = false;
        index2 = false;
        index3 = false;
      } else {
        String valueStr = target.value.toString();
        if (valueStr.contains('.')) {
          if (valueStr.split('.')[1].length > 3) {
            valueStr = target.value.toStringAsFixed(3);
          }
          if (valueStr.split('.')[1].length == 3) {
            index1 = false;
            index2 = false;
            index3 = true;
          } else if (valueStr.split('.')[1].length == 2) {
            index1 = false;
            index2 = true;
            index3 = false;
          } else if (valueStr.split('.')[1].length == 1) {
            index1 = true;
            index2 = false;
            index3 = false;
          }

          valueStr = valueStr.substring(0, valueStr.length - 1);
          if (valueStr.endsWith('.')) {
            valueStr = valueStr.substring(0, valueStr.length - 1);
          }
        } else {
          valueStr = "0";
        }
        target.value = double.tryParse(valueStr) ?? target.value;

        isDouble = true;
      }
      if (isSelectedAlls[_selectedInput]) {
        _switchSelectedAlls();
        isDouble = false;
        index1 = false;
        index2 = false;
        index3 = false;
      }
    }

    final remainder = n % 1;
    if (remainder <= 0) return n ~/ 10;
    int indexOfDot = -1;
    String str = n.toString();
    for (int i = 0; i < str.length; i++) {
      if (str[i] == ".") {
        indexOfDot = i;
        break;
      }
    }
    String remainderAsString = str.substring(indexOfDot, str.length - 1);
    if (remainderAsString == '.') {
      _dotted = true;
      notifyListeners();
    }
    num result = num.parse("${n.toInt()}$remainderAsString");
    return result;
  }

  _cutBack(num n) => n ~/ 10;

  void onDiscountChanged(num v) {
    if (onlyPriceIsEdited == false) {
      if (!(_currentEmployee?.access?.editPrice ?? false)) {
        return;
      }
      Log.d('Item price: $itemPrice', name: 'operation_on_product_provider');
      Log.d("TARGET PRICE: ${target.price}",
          name: 'operation_on_product_provider');
      Log.d('BASE PRICE: $basePrice', name: 'operation_on_product_provider');

      // ! TODO: Discount hisoblash uchun

      if (v == 10) {
        target.discountPercent = double.parse(
            ((target.discountPercent ?? 0) / 10).toString().split('.')[0]);
      } else if (isSelectedAlls[_selectedInput] ||
          (target.discountPercent ?? 0) == 0) {
        if (isSelectedAlls[_selectedInput]) {
          _switchSelectedAlls();
        }

        target.discountPercent = v + 0;
      } else {
        double n = _extend(target.discountPercent ?? 0, v).toDouble();
        target.discountPercent = !(n > 100) ? n : v + 0;
      }

      target.price =
          basePrice - ((target.discountPercent ?? 0) * (basePrice / 100));
      target.isPriceChanged = true;
      _usedDiscountInput = true;
    }
  }

  void onBoxChanged(num v) {
    if (!target.marking && target.soldBy == "box") {
      if (_chekFor122(boxValueInt)) {
        if (isSelectedAlls[_selectedInput] || boxValueInt == 0) {
          if (isSelectedAlls[_selectedInput]) {
            _switchSelectedAlls();
          }

          target.value = _outsideBox + (v * target.inBox);
        } else {
          int box = _extend(boxValueInt, v).toInt();

          target.value = _outsideBox + (box * target.inBox);
        }
      }
    } else {
      return;
    }
  }
}
