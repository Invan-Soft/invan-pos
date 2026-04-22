import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/click_response_model.dart';
import 'package:invan2/changes/services/payment/paynet_service.dart';
import 'package:invan2/utils/utils.dart';

part 'paynet_event.dart';
part 'paynet_state.dart';

class PaynetBloc extends Bloc<PaynetEvent, PaynetState> {
  PaynetBloc() : super(PaynetInitial()) {
    on<PaynetPayEvent>(_pay);
    on<PaynetCallInitialEvent>(_callInitial);
  }

  void _callInitial(PaynetCallInitialEvent event, Emitter<PaynetState> emit) {
    Log.d('PaynetBloc reset to initial', name: 'PaynetBloc');
    emit(PaynetInitial());
  }

  Future<void> _pay(PaynetPayEvent event, Emitter<PaynetState> emit) async {
    print('========== PAYNET PASS ==========');
    print('Skanerlangan OTP : ${event.otp}');
    print('Summa            : ${event.summa}');
    print('Tiyin (x100)     : ${(event.summa * 100).toInt()}');
    print('Receipt raqami   : ${event.receiptNumber}');
    print('=================================');

    Log.d('_pay() boshlandi — otp: ${event.otp}, summa: ${event.summa}', name: 'PaynetBloc');

    emit(PaynetLoadingState(PaynetLoadingStatus.internet));

    if (event.isRetry) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    emit(PaynetLoadingState(PaynetLoadingStatus.paying));

    // Paynet amount = tiyin (x100)
    ClickResponseModel result = await PaynetService.payment(
      otpData: event.otp,
      amount: (event.summa * 100).toInt(),
      receiptNumber: event.receiptNumber,
    );

    Log.d(
      '_pay() natija — error_code: ${result.errorCode}, payment_status: ${result.paymentStatus}, confirm_mode: ${result.confirmMode}',
      name: 'PaynetBloc',
    );

    // payment_status < 0 → xato
    if ((result.paymentStatus ?? -1) < 0 || (result.errorCode ?? -1) < 0) {
      Log.e('_pay() to\'lov xatosi — status: ${result.paymentStatus}, note: ${result.errorNote}', name: 'PaynetBloc');
      emit(PaynetPaymentErrorState(result.errorNote ?? 'Xato yuz berdi'));
      return;
    }

    // payment_status == 2 → muvaffaqiyatli
    if (result.paymentStatus == 2) {
      // confirm_mode == 1 bo'lsa tasdiqlash kerak
      if (result.confirmMode == true) {
        Log.d('_pay() confirm_mode=1, tasdiqlash so\'rovi yuborilmoqda', name: 'PaynetBloc');
        final pid = PaynetService.paymentId;
        if (pid != null) {
          final confirmResult = await PaynetService.confirm(pid);
          Log.d('confirm() natija — error_code: ${confirmResult.errorCode}', name: 'PaynetBloc');
          if ((confirmResult.errorCode ?? -1) != 0) {
            emit(PaynetPaymentErrorState(confirmResult.errorNote ?? 'Tasdiqlashda xato'));
            return;
          }
        }
      }
      Log.d('_pay() muvaffaqiyatli to\'lov', name: 'PaynetBloc');
      emit(PaynetPaymentSuccessState());
      return;
    }

    // payment_status == 0 yoki 1 → hali tugamagan
    Log.e('_pay() kutilmagan status: ${result.paymentStatus}', name: 'PaynetBloc');
    emit(PaynetPaymentErrorState('To\'lov kutilmoqda (status: ${result.paymentStatus})'));
  }
}
