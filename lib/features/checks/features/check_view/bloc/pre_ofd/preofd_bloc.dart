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
    final newReceiptModel41 =
        receiptForResend(event.receiptModel4, event.clientNumber);

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

  /// Fiskalga qayta yuboriladigan nusxa (asl chek o'rniga `box.put` bilan
  /// yoziladi). `_preOfd` dan ajratildi — tana o'zgarmagan; testlar uchun.
  static ReceiptModel4 receiptForResend(ReceiptModel4 src, String clientNumber) {
    final newReceiptModel41 = ReceiptModel4(
      supplierId: src.supplierId,
      newid: src.newid,
      clientPhone: clientNumber,
      cashierId: src.cashierId,
      cashierName: src.cashierName,
      date: DateTime.now().millisecondsSinceEpoch,
      isRefund: false,
      comment: src.comment,
      fiscalSign: src.fiscalSign,
      receiptSeq: src.receiptSeq,
      terminalId: src.terminalId,
      totalPrice: _getRightTotalPrice(src.soldItemList),
      uploaded: false,
      clientName: src.clientName,
      clientId: src.clientId,
      cashback: 0,
      sdacha: 0,
      returnForCheck: src.returnForCheck,
      posName: src.posName,
      refundInfo: src.refundInfo,
      commissionTIN: src.commissionTIN,
      isDonate: Pref.getBool('donate', false),
      createdDate: src.createdDate,
      orderId: src.orderId,
      cashboxId: src.cashboxId,
      externalId: src.externalId,
      orderType: src.orderType,
      shopId: src.shopId,
      userId: src.userId,
      discountVat: src.discountVat,
      discountID: src.discountID,
      rejected: src.rejected,
      url: src.url,
    );
    newReceiptModel41.id = src.id;
    newReceiptModel41.rejected = src.rejected;
    newReceiptModel41.uploaded = src.uploaded;
    newReceiptModel41.payment.clear();
    newReceiptModel41.soldItemList.clear();
    newReceiptModel41.payment.addAll(src.payment);
    // Shu chekning o'z to'lov ID'lari — xotiradagi oxirgi to'lovniki emas.
    // box.put shu nusxani asl chek o'rniga yozadi, shuning uchun yo'qolmasin.
    newReceiptModel41.epayJson = src.epayJson;
    newReceiptModel41.soldItemList.addAll(src.soldItemList);
    return newReceiptModel41;
  }

  static double _getRightTotalPrice(List<ReceiptModelSoldItem4> v) {
    double t = 0;
    for (var element in v) {
      t += element.price * element.value;
    }

    return t;
  }
}
