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
      cardType: 2,
      cardNumber: event.receiptModel4.cardNumber ?? '',
      pptId: event.receiptModel4.pptId ?? '',
    );

    newReceiptModel41.payment.clear();
    newReceiptModel41.soldItemList.clear();

    final double refundTotal = _getRightTotalPrice(event.rightList);
    final String cashId = Pref.getString(PrefKeys.cashId, '');

    // Vozvrat: to'lov turidan qat'iy nazar hammasi CASH orqali qaytariladi
    newReceiptModel41.payment.add(ReceiptModelPaymentType4(
      name: "CASH",
      value: refundTotal,
      payId: cashId,
    ));

    // Eski CASH/CARD ajratish logikasi (qachondir kerak bo'lsa):
    // final String cardId = Pref.getString(PrefKeys.cardId, '');
    // final String clickId = Pref.getString(PrefKeys.clickId, '');
    // final String uzumId = Pref.getString(PrefKeys.uzumId, '');
    // final String paymeId = Pref.getString(PrefKeys.paymeId, '');
    // double origCash = 0;
    // double origOther = 0;
    // String cashPayId = cashId;
    // String cardPayId = cardId;
    // for (final pay in event.receiptModel4.payment) {
    //   final n = pay.name.toUpperCase().trim();
    //   final id = pay.payId.trim();
    //   if (n == 'CASH' || (id.isNotEmpty && id == cashId)) {
    //     origCash += pay.value;
    //     if (id.isNotEmpty) cashPayId = id;
    //   } else {
    //     origOther += pay.value;
    //     if (id.isNotEmpty && id != clickId && id != uzumId && id != paymeId) {
    //       cardPayId = id;
    //     }
    //   }
    // }
    // final double srcTotal = origCash + origOther;
    // if (srcTotal <= 0) {
    //   newReceiptModel41.payment.add(ReceiptModelPaymentType4(name: "CARD", value: refundTotal, payId: cardPayId));
    // } else {
    //   double remaining = refundTotal;
    //   if (origCash > 0) {
    //     final double cashRefund = ((origCash / srcTotal) * refundTotal).roundToDouble();
    //     remaining -= cashRefund;
    //     if (cashRefund > 0) newReceiptModel41.payment.add(ReceiptModelPaymentType4(name: "CASH", value: cashRefund, payId: cashPayId));
    //   }
    //   if (remaining > 0) newReceiptModel41.payment.add(ReceiptModelPaymentType4(name: "CARD", value: remaining, payId: cardPayId));
    // }

    newReceiptModel41.soldItemList.addAll(event.rightList);

    // Qolgan kod o'zgarmadi...
    emit(ReturnLoadingState(message: ReturnMessage.internet));
    bool internet = await InternetConnectionChecker().hasConnection;
    if (event.isRetry) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    if (newReceiptModel41.isRefund == true && internet) {
      emit(ReturnLoadingState(message: ReturnMessage.returnig));
      newReceiptModel41.uploaded = true;

      // Yangi check raqami generate qilib APIga ham, local DBga ham bir xil yuboramiz
      newReceiptModel41.externalId = await ReceiptSingleton4.getCheckNo();

      HttpResult? refundResponse =
          await ReceiptApi4.receiptCreateGrouppForRefund(newReceiptModel41);

      if (refundResponse.statusCode == 200) {
        newReceiptModel41.uploaded = true;

        if (ofd) {
          // Sotuv OFDga ro'yxatdan o'tganligini tekshiramiz:
          // 1) URL bo'lishi kerak
          // 2) Fiskal ma'lumotlar (terminalId, fiscalSign, dateTimeOFD) bo'lishi kerak
          final urlValue = newReceiptModel41.url;
          final terminalId = newReceiptModel41.terminalId;
          final fiscalSign = newReceiptModel41.fiscalSign;
          final dateTimeOFD = newReceiptModel41.dateTimeOFD;

          final bool wasRegisteredOnOfd =
              (urlValue != null && urlValue.isNotEmpty) &&
              (terminalId != null && terminalId.isNotEmpty) &&
              (fiscalSign != null && fiscalSign.isNotEmpty) &&
              (dateTimeOFD != null &&
                  dateTimeOFD.isNotEmpty &&
                  dateTimeOFD != "0");

          if (!wasRegisteredOnOfd) {
            // OFDda sotuv yo'q — fiskal refund shart emas
            emit(ReturnSuccedState());
          } else {
            await LocalService.sell(
                    loc: event.loc, receiptData: newReceiptModel41)
                .then(
              (CommunicatorRESPONSE response) async {
                if (!(response.error ?? true) && response.info != null) {
                  newReceiptModel41.refundInfo =
                      jsonEncode(response.info?.toJson());
                  newReceiptModel41.url = response.info?.qrCodeUrl ?? '';
                  final refundInfoValue = newReceiptModel41.refundInfo;
                  if (refundInfoValue != null && refundInfoValue.isNotEmpty) {
                    Info info = Info.fromJson(jsonDecode(refundInfoValue));
                    newReceiptModel41.terminalId = info.terminalId;
                    newReceiptModel41.receiptSeq =
                        int.tryParse(info.receiptSeq ?? "0") ?? 0;
                    newReceiptModel41.dateTimeOFD = info.dateTime ?? "0";
                    newReceiptModel41.fiscalSign = info.fiscalSign;
                  }
                  await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41,
                      communicatorRECEIPT: response);
                  emit(ReturnSuccedState());
                } else {
                  await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41);
                  emit(ReturnFailedState(error: response.paycheck.toString()));
                }
              },
            ).catchError((err) async {
              await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41);
              emit(ReturnFailedState(error: err.toString()));
            });
          }

          //////////ofd
        } else {
          await ReceiptSingleton4.toOBJECTBOX(newReceiptModel41);
          emit(ReturnSuccedState());
        }
      } else {
        emit(ReturnFailedState(error: refundResponse.getError));
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
