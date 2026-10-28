import 'dart:convert';

import 'package:flutter/foundation.dart';
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
          // To'liq qaytarilgan item'lar filtrlanishidan OLDIN.
          final refundedMarks = serverRefundedMarks(element);
          if (element.items != null) {
            element.items = refundableItems(element);
          }
          ReceiptModel4 rMod = ChecksSingleton.globalToLocall(
            element,
            cashierId: event.receiptModel4.cashierId,
            cashierName: event.receiptModel4.cashierName,
          );
          rMod.refundInfo = event.receiptModel4.refundInfo;
          emit(ReUpdateSuccesState(
            receiptModel4: rMod,
            refundedMarks: refundedMarks,
          ));
        }
      }
      emit(ReUpdateFailureState());
    } else {
      emit(ReUpdateFailureState());
    }
  }

  /// Serverda shu chek bo'yicha qaytarilgan KM'lar — har qanday kassada
  /// (vozvratda KM yuborilgan bo'lsa): `refunded_marking_names` +
  /// `refunded_box_marking_names`. Vozvrat sahifasida bular havzadan
  /// chiqariladi va skanerlansa "oldin qaytarilgan".
  @visibleForTesting
  static Set<String> serverRefundedMarks(GlobalReceipt receipt) => {
        for (final it in receipt.items ?? <ItemsGTR>[]) ...[
          ...it.refundedMarkingNames,
          ...it.refundedBoxMarkingNames,
        ],
      };

  /// Server itemlaridan vozvrat qilish mumkin bo'lgan qoldiq: `value` dan
  /// `refund_amount` ayriladi, to'liq qaytarilganlari tushib qoladi.
  ///
  /// Shu kassada blok bo'lib sotilgan mahsulotlar (lokal originalda
  /// saleType==2) filtrlanmaydi — qoldiq ReturnPage._copyWith da lokal DB
  /// hisobidan aniqlanadi. Lokal original yo'q (boshqa kassa) blok itemi
  /// server qiymatidan: ItemsGTR token'ni donaga o'girgan, `refund_amount`
  /// bilan bir birlikda.
  ///
  /// To'plam ObjectBox'dagi asl chekdan olinadi: tanlangan chek server
  /// qidiruvidan kelgan (saleType bilan) yoki PIN yo'lida qatorlarsiz nusxa
  /// (`ggg`) bo'lishi mumkin.
  @visibleForTesting
  static List<ItemsGTR> refundableItems(GlobalReceipt receipt) {
    final localBlockProductIds =
        ChecksSingleton.localOriginalItems(receipt.externalId ?? '')
            .values
            .where((it) => it.saleType == 2 && it.boxValue > 0)
            .map((it) => it.productId)
            .toSet();
    final List<ItemsGTR> itemsGTRList = [];
    for (ItemsGTR itemsGTR in receipt.items ?? <ItemsGTR>[]) {
      if (localBlockProductIds.contains(itemsGTR.productId)) {
        itemsGTRList.add(itemsGTR);
      } else if (itemsGTR.value != null && itemsGTR.refundAmount != null) {
        if (itemsGTR.value! - itemsGTR.refundAmount! > 0) {
          itemsGTR.value = itemsGTR.value! - itemsGTR.refundAmount!;
          itemsGTRList.add(itemsGTR);
        }
      }
    }
    return itemsGTRList;
  }
}
