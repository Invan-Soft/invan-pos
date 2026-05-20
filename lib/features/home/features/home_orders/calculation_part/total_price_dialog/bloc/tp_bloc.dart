import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../../../../utils/util_functions.dart';
import '../../../../../../features.dart';
import '../../../../../../hive_repository/hive_boxes.dart';

part 'tp_event.dart';

part 'tp_state.dart';

num? tpBlocDiscount;

// total price bloc
class TpBloc extends Bloc<TpEvent, TpState> {
  List<ReceiptModelSoldItem4> products;
  final bool isClientMinimumPriced;
  bool selectedAll;
  num _newTotalPrice;
  num totalPrice;
  String totalPriceString;
  num discountPercent;
  String discountString;
  TpStatus inputStatus;

  TpBloc({
    required this.isClientMinimumPriced,
    required this.products,
    required this.discountString,
    required this.discountPercent,
    required this.selectedAll,
    required this.totalPrice,
    required this.totalPriceString,
    required this.inputStatus,
  })  : _newTotalPrice = totalPrice,
        super(TpInitial(
          inputStatus: TpStatus.discount,
          isAllSelected: true,
        )) {
    on<TpNumPressedEvent>(_numPressed);
    on<TpBackSpacePressedEvent>(_backSpacePressed);
    on<TpSaveButtonPressedEvent>(_save);
    on<TpSelectInputEvent>(_selectInput);
  }

  _selectInput(TpSelectInputEvent event, Emitter<TpState> emit) {
    if (inputStatus == event.inputStatus) {
      selectedAll = !selectedAll;
    } else {
      inputStatus = event.inputStatus;
      selectedAll = true;
    }
    emit(TpInitial(inputStatus: inputStatus, isAllSelected: selectedAll));
  }

  FutureOr<void> _save(TpSaveButtonPressedEvent event, Emitter<TpState> emit) {
    double newPRICE = 0;

    // num subGetBaseTotalPrice = _newTotalPrice;
    // if (tpBlocDiscount != null && tpBlocDiscount! > 0) {
    //   subGetBaseTotalPrice = _newTotalPrice * (100 - tpBlocDiscount!) / 100;
    // }
    // print(subGetBaseTotalPrice);
    double difference = 0;
    // if (subGetBaseTotalPrice < _newTotalPrice) {
    // difference = (_newTotalPrice - subGetBaseTotalPrice).toDouble();
    // discountPercent = _newTotalPrice.toDouble() * 100 / getBaseTotalPrice;
    // print(difference);
    // print(discountPercent);
    // if (_newTotalPrice < subGetBaseTotalPrice) {
    //   discountPercent = difference / (getBaseTotalPrice / 100);
    // } else {
    //   discountPercent = tpBlocDiscount!;
    // }
    // } else {}

    difference = getBaseTotalPrice - _newTotalPrice;
    discountPercent = difference / (getBaseTotalPrice / 100);

    if (100 > discountPercent && 0 < discountPercent) {
      for (int i = 0; i < products.length; i++) {
        num basePrice = products[i].onlyPrice;

        newPRICE = (basePrice / 100) * (100 - discountPercent);
        products[i].discount.clear();
        products[i].discount.add(
              ItemsSingleton.discounter(
                howMuch: basePrice - newPRICE,
                quantity: 1,
                where: DiscountFromWhere.total,
              ),
            );
        products[i].price = newPRICE;
        products[i].singleDiscount = 0;
        products[i].discountPercent = discountPercent + 0;
        products[i].isPriceChanged = false;
        products[i].isPriceOnlyChanged = false;
      }
    } else {
      for (int i = 0; i < products.length; i++) {
        products[i].discountPercent = 0;

        products[i].price = ItemsSingleton.getItemBasePrice(
                products[i], isClientMinimumPriced) +
            0;
        for (int n = 0; n < products[i].discount.length; n++) {
          if (products[i].discount[n].type == "sum") {
            products[i].discount.removeAt(n);
          }
        }
        products[i].isPriceChanged = false;
      }

      discountString = '0';
    }
    emit(
      TpComletedState(
        TpStatus.summa,
        false,
        dicountPercent: discountPercent,
        products: products,
      ),
    );
    isTpEdited = true;
  }

  FutureOr<void> _backSpacePressed(
    TpBackSpacePressedEvent event,
    Emitter<TpState> emit,
  ) {
    final Employee currentEmployee = HiveBoxes.getCurrentEmployee!;
    if ((currentEmployee.access?.editPrice ?? false)) {
      switch (event.inputStatus) {
        case TpStatus.discount:
          {
            if (discountString.length > 1 && !event.isAllSelected) {
              discountString =
                  discountString.substring(0, discountString.length - 1);
            } else {
              discountString = "0";
            }
            discountPercent = double.parse(discountString);
            if (discountPercent < 101) {
              tpBlocDiscount ??= 0;
              _newTotalPrice = getBaseTotalPrice -
                  ((getBaseTotalPrice / 100) *
                      (discountPercent + tpBlocDiscount!));
            } else {
              discountPercent = 0;

              _newTotalPrice = getBaseTotalPrice;
            }
            discountString = discountPercent.toStringAsFixed(0);
            totalPriceString =
                MoneyFormatter.inputMoneyFormatter.format(_newTotalPrice);
          }
          break;
        case TpStatus.summa:
          {
            totalPriceString = MoneyFormatter.remover(totalPriceString);
            if (totalPriceString.length > 1) {
              totalPriceString =
                  totalPriceString.substring(0, totalPriceString.length - 1);
            } else {
              totalPriceString = "0";
            }
            _newTotalPrice = double.parse(totalPriceString);
            double subGetBaseTotalPrice = getBaseTotalPrice;
            if (tpBlocDiscount != null && tpBlocDiscount! > 0) {
              subGetBaseTotalPrice =
                  getBaseTotalPrice * (100 - tpBlocDiscount!) / 100;
            }
            if (_newTotalPrice < subGetBaseTotalPrice) {
              discountPercent = (getBaseTotalPrice - _newTotalPrice) /
                  (getBaseTotalPrice / 100);
            } else {
              discountPercent = 0;
            }
            discountString = discountPercent.toStringAsFixed(0);
            totalPriceString =
                MoneyFormatter.inputMoneyFormatter.format(_newTotalPrice);
          }
          break;
      }
    }
    emit(TpInitial(inputStatus: event.inputStatus, isAllSelected: selectedAll));
  }

  FutureOr<void> _numPressed(
    TpNumPressedEvent event,
    Emitter<TpState> emit,
  ) {
    final Employee currentEmployee = HiveBoxes.getCurrentEmployee!;
    if ((currentEmployee.access?.editPrice ?? false)) {
      switch (event.inputStatus) {
        case TpStatus.discount:
          {
            if (event.isAllSelected) {
              discountString = event.pressed.toString();
              selectedAll = false;
            } else {
              discountString += event.pressed.toString();
            }
            discountPercent = num.parse(discountString);
            if (discountPercent < 101 && discountPercent > 0) {
              discountString =
                  MoneyFormatter.inputMoneyFormatter.format(discountPercent);
              tpBlocDiscount ??= 0;
              _newTotalPrice = (getBaseTotalPrice / 100) *
                  (100 - (discountPercent + tpBlocDiscount!));
            } else {
              discountString = event.pressed.toString();
              discountPercent = event.pressed;
              _newTotalPrice =
                  (getBaseTotalPrice / 100) * (100 - discountPercent);
            }
            totalPriceString =
                MoneyFormatter.inputMoneyFormatter.format(_newTotalPrice);
          }
          break;
        case TpStatus.summa:
          {
            totalPriceString = MoneyFormatter.remover(totalPriceString);
            if (totalPriceString.startsWith("0") &&
                !totalPriceString.startsWith("0.")) {
              for (; totalPriceString.startsWith('0');) {
                totalPriceString =
                    totalPriceString.substring(1, totalPriceString.length);
              }
            }

            if (event.isAllSelected) {
              totalPriceString = event.pressed.toString();
              selectedAll = false;
            } else {
              totalPriceString += event.pressed.toString();
            }
            _newTotalPrice = double.parse(totalPriceString);
            totalPriceString =
                MoneyFormatter.inputMoneyFormatter.format(_newTotalPrice);
            double subGetBaseTotalPrice = getBaseTotalPrice;
            if (tpBlocDiscount != null && tpBlocDiscount! > 0) {
              subGetBaseTotalPrice =
                  getBaseTotalPrice * (100 - tpBlocDiscount!) / 100;
            }
            if (_newTotalPrice < subGetBaseTotalPrice) {
              discountPercent = (getBaseTotalPrice - _newTotalPrice) /
                  (getBaseTotalPrice / 100);
              discountString = discountPercent.toStringAsFixed(2);
            } else {
              discountPercent = 0;
              discountString = '0';
            }
          }
          break;
      }
    }
    emit(TpInitial(inputStatus: event.inputStatus, isAllSelected: selectedAll));
  }

  double get getBaseTotalPrice {
    double baseTotalPrice = 0;
    for (int i = 0; i < products.length; i++) {
      if (!products[i].isDeleted!) {
        baseTotalPrice += UtilFunctions.roundToNearest(
            products[i].onlyPrice * products[i].value);
      }
    }
    return UtilFunctions.roundToNearest(baseTotalPrice);
  }
}
