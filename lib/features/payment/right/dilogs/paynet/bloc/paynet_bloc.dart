import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/paynet_response_model.dart';
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
    if (event.isRetry) await Future.delayed(const Duration(milliseconds: 500));

    emit(PaynetLoadingState(PaynetLoadingStatus.paying));

    // 1-qadam: to'lovni yaratish
    final PaynetResponseModel result = await PaynetService.payment(
      otpData: event.otp,
      amount: (event.summa * 100).toInt(),
      receiptNumber: event.receiptNumber,
    );

    Log.d(
      '_pay() natija — error_code: ${result.errorCode}, payment_status: ${result.paymentStatus}, confirm_mode: ${result.confirmMode}',
      name: 'PaynetBloc',
    );

    // Xato holat
    if ((result.errorCode ?? -1) < 0 || (result.paymentStatus ?? -1) < 0) {
      Log.e('_pay() xato — status: ${result.paymentStatus}, note: ${result.errorNote}', name: 'PaynetBloc');
      emit(PaynetPaymentErrorState(result.errorNote ?? 'Xato yuz berdi'));
      return;
    }

    final int? pid = result.paymentId ?? PaynetService.paymentId;
    if (pid == null) {
      emit(PaynetPaymentErrorState('payment_id topilmadi'));
      return;
    }

    // confirm_mode ni birinchi javobdan olib qo'yamiz
    // (keyingi status so'rovlarida bu maydon kelmaydi)
    final bool needsConfirm = result.isConfirmMode;

    // Birinchi javobdanoq muvaffaqiyatli bo'lsa
    if (result.paymentStatus == 2) {
      await _handleSuccess(pid, needsConfirm, emit);
      return;
    }

    // status 0 yoki 1 → polling
    if (result.paymentStatus == 0 || result.paymentStatus == 1) {
      await _pollStatus(pid, needsConfirm, emit);
      return;
    }

    emit(PaynetPaymentErrorState('Kutilmagan status: ${result.paymentStatus}'));
  }

  // Har 2 soniyada status so'raydi, max 15 marta (30 soniya)
  Future<void> _pollStatus(
    int pid,
    bool needsConfirm,
    Emitter<PaynetState> emit,
  ) async {
    const int maxAttempts = 15;
    const Duration interval = Duration(seconds: 2);

    Log.d('_pollStatus() boshlandi — pid: $pid, max: $maxAttempts', name: 'PaynetBloc');

    for (int i = 0; i < maxAttempts; i++) {
      emit(PaynetLoadingState(PaynetLoadingStatus.polling));
      await Future.delayed(interval);

      Log.d('_pollStatus() urinish ${i + 1}/$maxAttempts', name: 'PaynetBloc');

      final statusResult = await PaynetService.checkPaymentStatus(pid);

      // Xato keldi
      if ((statusResult.paymentStatus ?? -1) < 0) {
        Log.e('_pollStatus() xato — status: ${statusResult.paymentStatus}', name: 'PaynetBloc');
        emit(PaynetPaymentErrorState(statusResult.errorNote ?? 'To\'lov bekor qilindi'));
        return;
      }

      // Muvaffaqiyatli
      if (statusResult.paymentStatus == 2) {
        Log.d('_pollStatus() muvaffaqiyat — urinish: ${i + 1}', name: 'PaynetBloc');
        await _handleSuccess(pid, needsConfirm, emit);
        return;
      }

      // status 0 yoki 1 — davom etamiz
      Log.d('_pollStatus() hali kutilmoqda — status: ${statusResult.paymentStatus}', name: 'PaynetBloc');
    }

    // 30 soniya o'tdi, javob yo'q
    Log.e('_pollStatus() timeout — pid: $pid', name: 'PaynetBloc');
    emit(PaynetPaymentErrorState('To\'lov vaqti tugadi. Qayta urinib ko\'ring.'));
  }

  // Muvaffaqiyatli to'lovni yakunlash (confirm_mode bo'lsa tasdiqlash)
  Future<void> _handleSuccess(
    int pid,
    bool needsConfirm,
    Emitter<PaynetState> emit,
  ) async {
    if (needsConfirm) {
      Log.d('_handleSuccess() confirm_mode=1, tasdiqlash yuborilmoqda — pid: $pid', name: 'PaynetBloc');
      final confirmResult = await PaynetService.confirm(pid);
      Log.d('confirm() natija — error_code: ${confirmResult.errorCode}', name: 'PaynetBloc');
      if ((confirmResult.errorCode ?? -1) != 0) {
        emit(PaynetPaymentErrorState(confirmResult.errorNote ?? 'Tasdiqlashda xato'));
        return;
      }
    }
    Log.d('_handleSuccess() to\'lov yakunlandi — pid: $pid', name: 'PaynetBloc');
    emit(PaynetPaymentSuccessState());
  }
}
