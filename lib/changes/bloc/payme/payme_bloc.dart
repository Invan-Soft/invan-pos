import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/services/api_state.dart';
import 'package:invan2/changes/services/payment/payme/models/item_payme_model.dart';
import 'package:invan2/changes/services/payment/payme_service.dart';
import '../../../features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
part 'payme_event.dart';
part 'payme_state.dart';

class PaymeBloc extends Bloc<PaymeEvent, PaymeState> {
  PaymeBloc() : super(PaymeInitial()) {
    on<PaymeCreateReceiptEvent>(_createReceipt);
    on<PaymePayEvent>(_pay);
  }

  FutureOr<void> _createReceipt(
    PaymeCreateReceiptEvent event,
    Emitter<PaymeState> emit,
  ) async {

    if (event.amount < 100) {
      emit(PaymeFailCreate(
        "Summa eng kam miqdordan kam",
      ));
      return;
    }
    emit(PaymeLoading());

    ApiState apiState = await PaymeGOService.receiptsCreate(
        (event.amount * 100), _itemsToPayme(event.items));

    if (apiState is Success) {
      emit(PaymeSuccessCreate(event.amount));
    }
    if (apiState is Failure) {
      emit(PaymeFailCreate(apiState.response.toString()));
    }
  }

  FutureOr<void> _pay(
    PaymePayEvent event,
    Emitter<PaymeState> emit,
  ) async {
    emit(PaymeLoading());

    ApiState apiState = await PaymeGOService.receiptsPay(event.token);

    if (apiState is Success) {
      emit(PaymeSuccessPay());
    }
    if (apiState is Failure) {
      emit(PaymeFailPay(apiState.response.toString()));
    }
  }

  List<PaymeItem> _itemsToPayme(List<ReceiptModelSoldItem4> items) {
    return items
        .map((e) => PaymeItem(
              title: e.productName,
              price: (e.price * 100).toInt(),
              count: e.value,
              code: e.barcode.isNotEmpty ? e.barcode[0] : "",
              units: 00,
              vatPercent: e.vatPercent,
              packageCode: e.barcode.isNotEmpty ? e.barcode[0] : "",
            ))
        .toList();
  }
}
