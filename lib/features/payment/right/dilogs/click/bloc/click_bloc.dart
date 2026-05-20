import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/click_response_model.dart';
import 'package:invan2/changes/services/payment/click_service.dart';
import 'package:invan2/features/payment/right/dilogs/click/clic_pass_dialog.dart';

part 'click_event.dart';
part 'click_state.dart';

class ClickBloc extends Bloc<ClickEvent, ClickState> {
  ClickBloc() : super(ClickInitial()) {
    on<ClickPayEvent>(_pay);
    on<ClickCallInitialEvent>(_callInitial);
  }
  _callInitial(ClickCallInitialEvent event, Emitter<ClickState> emit) {
    emit(ClickInitial());
  }

  _pay(ClickPayEvent event, Emitter<ClickState> emit) async {
    emit(ClickLoadingState(ClickLoadingStatus.internet));

    if (event.isRetry) {
      await Future.delayed(const Duration(milliseconds: 500));
    }

    emit(ClickLoadingState(ClickLoadingStatus.paying));
    ClickResponseModel result = await ClickService.payment(
      amount: event.summa,
      otpData: event.otp,
      receiptNumber: event.receiptNumber,
    );

    if (result.errorCode == 0) {
      emit(ClickPaymentSuccessState());
      return;
    }
    emit(ClickPaymentErrorState(result.errorNote ?? "Error was null"));
  }
}
