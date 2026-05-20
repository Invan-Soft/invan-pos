import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:invan2/changes/models/ofd/epos_response_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/local_selling_service.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/utils/utils.dart';
import '../../../../../../utils/l10n/app_localizations.dart';
import '../../../../../hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import '../../../../return_page/right/return_dialog/return_dialog.dart';

part 'preofd_event.dart';

part 'preofd_state.dart';

class PreOfdBloc extends Bloc<PreOfdEvent, PreOfdState> {
  PreOfdBloc() : super(PreOfdInitial()) {
    on<SetPreOfdEvent>(_preOfd);
  }

  _preOfd(SetPreOfdEvent event, Emitter<PreOfdState> emit) async {
    Log.d(event, name: 'PreOfd_bloc');
    final String character =
        Pref.getString(PrefKeys.checkId, "not initialized");
    bool ofd = Pref.getBool(PrefKeys.withOFD, false);
    final newReceiptModel41 = ReceiptModel4(
      supplierId: event.receiptModel4.supplierId,
      newid: event.receiptModel4.newid,
      clientPhone: event.clientNumber,
      cashierId: event.receiptModel4.cashierId,
      cashierName: event.receiptModel4.cashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: false,
      comment: event.receiptModel4.comment,
      fiscalSign: event.receiptModel4.fiscalSign,
      receiptSeq: event.receiptModel4.receiptSeq,
      terminalId: event.receiptModel4.terminalId,
      totalPrice: _getRightTotalPrice(event.receiptModel4.soldItemList),
      uploaded: false,
      clientName: event.receiptModel4.clientName,
      clientId: event.receiptModel4.clientId,
      cashback: 0,
      sdacha: 0,
      returnForCheck: event.receiptModel4.returnForCheck,
      posName: event.receiptModel4.posName,
      refundInfo: event.receiptModel4.refundInfo,
      commissionTIN: event.receiptModel4.commissionTIN,
      isDonate: Pref.getBool('donate', false),
      createdDate: event.receiptModel4.createdDate,
      orderId: event.receiptModel4.orderId,
      cashboxId: event.receiptModel4.cashboxId,
      externalId: event.receiptModel4.externalId,
      orderType: event.receiptModel4.orderType,
      shopId: event.receiptModel4.shopId,
      userId: event.receiptModel4.userId,
      discountVat: event.receiptModel4.discountVat,
      discountID: event.receiptModel4.discountID,
      rejected: event.receiptModel4.rejected,
      url: event.receiptModel4.url,
    );
    newReceiptModel41.id = event.receiptModel4.id;
    newReceiptModel41.rejected = event.receiptModel4.rejected;
    newReceiptModel41.uploaded = event.receiptModel4.uploaded;
    newReceiptModel41.payment.clear();
    newReceiptModel41.soldItemList.clear();
    newReceiptModel41.payment.addAll(event.receiptModel4.payment);
    newReceiptModel41.soldItemList.addAll(event.receiptModel4.soldItemList);

    if (ofd) {
      emit(PreOfdLoadingState(message: ReturnMessage.internet));
      bool internet = await InternetConnectionChecker().hasConnection;
      if (event.isRetry) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      if (internet) {
        emit(PreOfdLoadingState(message: ReturnMessage.returnig));
        newReceiptModel41.url != null && newReceiptModel41.url!.isNotEmpty
            ? emit(PreOfdFailedState(
                error: 'Данный чек был отправлен в налоговую инспекцию.'))
            : await LocalService.sell(
                loc: event.loc,
                receiptData: newReceiptModel41,
              ).then(
                (CommunicatorRESPONSE response) async {
                  if (!response.error! && response.info != null) {
                    newReceiptModel41.url = response.info?.qrCodeUrl ?? '';
                    newReceiptModel41.refundInfo = jsonEncode(
                      response.info!.toJson(),
                    );
                    final box = MyObjectbox.saleStore.box<ReceiptModel4>();
                    box.put(newReceiptModel41);
                    emit(PreOfdSuccedState(newReceiptModel41));
                  } else {
                    LogRepository.addLog(
                      "${response.paycheck} / RECEIPT NO: $character",
                      file: "PreOfdBloc / _PreOfd",
                      method: "OFD SELL",
                      where: "PreOfd BLOC ",
                    );
                    emit(
                        PreOfdFailedState(error: response.paycheck.toString()));
                  }
                },
              ).catchError((err) {
                LogRepository.addLog(
                  "$err / RECEIPT NO: $character",
                  file: "PreOfdBloc / _PreOfd",
                  where: "PreOfd BLOC / CATCHERROR",
                  method: "OFD SELL",
                );
                emit(PreOfdFailedState(
                  error: err.toString(),
                ));
              });
      } else {
        emit(PreOfdNoInternetState());
      }
    } else {
      emit(PreOfdFailedState(error: 'No OFD.'));
    }
  }

  double _getRightTotalPrice(List<ReceiptModelSoldItem4> v) {
    double t = 0;
    for (var element in v) {
      t += element.price * element.value;
    }

    return t;
  }
}
