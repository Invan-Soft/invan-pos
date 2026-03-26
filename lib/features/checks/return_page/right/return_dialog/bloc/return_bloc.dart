import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/local_selling_service.dart';
import 'package:invan2/features/checks/return_page/right/return_dialog/return_dialog.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/singleton/receipt_singleton_4.dart';
import 'package:invan2/utils/util_functions.dart';
import 'package:invan2/utils/utils.dart';

import '../../../../../../changes/services/api.dart';
import '../../../../../../changes/services/api/result_http_model.dart';
import '../../../../../../utils/l10n/app_localizations.dart';

part 'return_event.dart';

part 'return_state.dart';

class ReturnBloc extends Bloc<ReturnEvent, ReturnState> {
  ReturnBloc() : super(ReturnInitial()) {
    on<ReturnReturnEvent>(_return);
  }

  _return(ReturnReturnEvent event, Emitter<ReturnState> emit) async {
    Log.d(event, name: 'return_bloc');

    bool ofd = Pref.getBool(PrefKeys.withOFD, false);
    final newReceiptModel41 = ReceiptModel4(
      supplierId: event.receiptModel4.supplierId,
      dateTimeOFD: event.receiptModel4.dateTimeOFD,
      fiscalSign: event.receiptModel4.fiscalSign,
      receiptSeq: event.receiptModel4.receiptSeq,
      discountID: event.receiptModel4.discountID,
      discountVat: event.receiptModel4.discountVat,
      terminalId: event.receiptModel4.terminalId,
      newid: event.receiptModel4.newid,
      rejected: event.receiptModel4.rejected,
      clientPhone: event.clientNumber,
      cashierId: event.receiptModel4.cashierId,
      cashierName: event.receiptModel4.cashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: true,
      externalId: event.receiptModel4.externalId,
      totalPrice: _getRightTotalPrice(event.rightList),
      uploaded: false,
      clientName: event.receiptModel4.clientName,
      clientId: event.receiptModel4.clientId,
      cashback: 0,
      comment: "Refund made from ${event.receiptModel4.externalId}",
      sdacha: 0,
      createdDate: event.receiptModel4.createdDate,
      returnForCheck: event.receiptModel4.returnForCheck,
      posName: event.receiptModel4.posName,
      refundInfo: event.receiptModel4.refundInfo,
      commissionTIN: event.receiptModel4.commissionTIN,
      isDonate: Pref.getBool('donate', false),
      cashboxId: event.receiptModel4.cashboxId,
      orderId: event.receiptModel4.orderId,
      orderType: event.receiptModel4.orderType,
      shopId: event.receiptModel4.shopId,
      userId: event.receiptModel4.userId,
      url: event.receiptModel4.url,
    );
    newReceiptModel41.payment.clear();
    newReceiptModel41.soldItemList.clear();
    newReceiptModel41.payment.add(ReceiptModelPaymentType4(
      name: "cash",
      value: _getRightTotalPrice(event.rightList),
      payId: Pref.getString(PrefKeys.cashId, ''),
    ));
    newReceiptModel41.soldItemList.addAll(event.rightList);

    emit(ReturnLoadingState(message: ReturnMessage.internet));
    bool internet = await InternetConnectionChecker().hasConnection;
    if (event.isRetry) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    if (newReceiptModel41.isRefund == true && internet) {
      emit(ReturnLoadingState(message: ReturnMessage.returnig));
      newReceiptModel41.uploaded = true;
      await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41);
      HttpResult? refundResponse =
          await ReceiptApi4.receiptCreateGrouppForRefund(newReceiptModel41);
      if (refundResponse.statusCode == 200) {
        newReceiptModel41.uploaded = true;

        if (ofd) {
          final urlValue = newReceiptModel41.url;
          if (urlValue == null || urlValue.isEmpty) {
            // await ReceiptSingleton4.toOBJECTBOX(
            //   newReceiptModel41,
            // );
            emit(ReturnSuccedState());
          } else {
            await LocalService.sell(
              loc: event.loc,
              receiptData: newReceiptModel41,
            ).then(
              (CommunicatorRESPONSE response) async {
                if (!(response.error ?? true) && response.info != null) {
                  newReceiptModel41.refundInfo =
                      jsonEncode(response.info?.toJson());
                  if (newReceiptModel41.refundInfo != null) {
                    final refundInfoValue = newReceiptModel41.refundInfo;
                    if (refundInfoValue != null && refundInfoValue.isNotEmpty) {
                      Info info = Info.fromJson(jsonDecode(refundInfoValue));
                      newReceiptModel41.terminalId = info.terminalId;
                      newReceiptModel41.receiptSeq =
                          int.tryParse(info.receiptSeq ?? "0") ?? 0;
                      newReceiptModel41.dateTimeOFD = (info.dateTime ?? "0");
                      newReceiptModel41.fiscalSign = info.fiscalSign;
                    }
                  }

                  // HttpResult? refundResponse =
                  //     await ReceiptApi4.receiptCreateGrouppForRefund(
                  //         newReceiptModel41);
                  // if (refundResponse.isSuccess) {
                  //   newReceiptModel41.uploaded = true;
                  // await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41,
                  //     communicatorRECEIPT: response);
                  emit(ReturnSuccedState());
                  // } else {
                  //   emit(ReturnFailedState(
                  //     error: 'Refund not possible',
                  //   ));
                  // }
                } else {
                  LogRepository.addLog(
                    "${response.paycheck ?? "Unknown Error"} / RECEIPT NO: ${newReceiptModel41.externalId}",
                    file: "ReturnBloc / _return",
                    method: "OFD SELL",
                    where: "RETURN BLOC ",
                  );
                  emit(ReturnFailedState(error: response.paycheck.toString()));
                }
              },
            ).catchError((err) {
              LogRepository.addLog(
                "$err / RECEIPT NO: ${newReceiptModel41.externalId}",
                file: "ReturnBloc / _return",
                where: "RETURN BLOC / CATCHERROR",
                method: "OFD SELL",
              );
              emit(ReturnFailedState(
                error: err.toString(),
              ));
            });
          }
        } else {
          // await ReceiptSingleton4.toOBJECTBOX(
          //   newReceiptModel41,
          // );
          emit(ReturnSuccedState());
        }
      } else {
        emit(ReturnFailedState(
          error: refundResponse.getError,
        ));
      }
    } else {
      emit(ReturnNoInternetState());
    }
  }

  double _getRightTotalPrice(List<ReceiptModelSoldItem4> v) {
    double t = 0;
    for (var element in v) {
      t += UtilFunctions.roundToNearest(element.price * element.value);
    }

    return t;
  }
}
