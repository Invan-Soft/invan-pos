import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/receipts_get_model.dart';
import '../../../../../changes/services/api.dart';
import '../../../../../changes/services/api/result_http_model.dart';
import '../../../../../changes/services/search_receipt_sevice.dart';
import '../../../../get_products/singletons/checks_singleton.dart';

part 're_update_event.dart';

part 're_update_state.dart';

class ReUpdateBloc extends Bloc<ReUpdateEvent, ReUpdateState> {
  ReUpdateBloc() : super(ReUpdateInitial()) {
    on<GetReUpdateEvent>(reUpdate);
  }

  Future<void> reUpdate(
    GetReUpdateEvent event,
    Emitter<ReUpdateState> emit,
  ) async {
    emit(ReUpdateProccesState());

    HttpResult httpResult =
        await SearchReceiptService.getReceiptss(event.receiptModel4.orderId);

    if (httpResult.isSuccess) {
      List<GlobalReceipt> getReceiptModel = List<GlobalReceipt>.from(
        json.decode(utf8.decode(httpResult.reBytes))['data'].map((e) {
          return GlobalReceipt.fromJson(e);
        }),
      ).toList();

      for (var element in getReceiptModel) {
        if (event.receiptModel4.orderId == element.id) {
          List<ItemsGTR> itemsGTRList = [];
          if (element.items != null) {
            for (ItemsGTR itemsGTR in element.items!) {
              if (itemsGTR.value != null && itemsGTR.refundAmount != null) {
                if (itemsGTR.value! - itemsGTR.refundAmount! > 0) {
                  itemsGTR.value = itemsGTR.value! - itemsGTR.refundAmount!;
                  itemsGTRList.add(itemsGTR);
                }
              }
            }
            element.items = itemsGTRList;
          }
          ReceiptModel4 rMod = ChecksSingleton.globalToLocall(
            element,
            cashierId: event.receiptModel4.cashierId,
            cashierName: event.receiptModel4.cashierName,
          );
          rMod.refundInfo = event.receiptModel4.refundInfo;
          emit(ReUpdateSuccesState(receiptModel4: rMod));
        }
      }
      emit(ReUpdateFailureState());
    } else {
      emit(ReUpdateFailureState());
    }
  }
}
