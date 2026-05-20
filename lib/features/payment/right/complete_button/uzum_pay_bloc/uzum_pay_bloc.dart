import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/log/log_model.dart';
import 'package:invan2/changes/models/uzum_model.dart';
import '../../../../../changes/data/security.dart';
import '../../../../../changes/services/app_constants.dart';
import '../../../../../changes/services/log_service.dart';
import '../../../../../changes/services/payment/uzum_service.dart';
import '../../../../../utils/constants/pref_keys.dart';
import '../../../../../utils/helpers/prefs.dart';

part 'uzum_pay_event.dart';

part 'uzum_pay_state.dart';

class UzumPayBloc extends Bloc<UzumPayEvent, UzumPayState> {
  UzumPayBloc() : super(UzumPayInitial()) {
    on<StartUzumPay>(payWithUzum);
  }

  Future payWithUzum(
    StartUzumPay event,
    Emitter<UzumPayState> emit,
  ) async {
    emit(UzumPayProcessState());
    UzumModel uzumResponse = await UzumService.payment(
      otpData: event.otpData,
      amount: event.amount * 100,
      receiptNumber: event.transactionId,
    );
    LogModel log = LogModel(
      dateTime: DateTime.now(),
      file: uzumResponse.paymentStatus,
      isSent: true,
      message: uzumResponse.errorMessage,
      method: "POST",
      path: 'UzumPayBloc',
      phone: uzumResponse.clientPhoneNumber,
      phoneModel: "",
      statusCode: uzumResponse.errorCode,
      type: true,
      url: 'right/uzum_pay_bloc/UzumPayBloc',
      userName: Pref.getString(PrefKeys.cashierName, "not initialized"),
      version: AppConstants.version,
    );

    if (uzumResponse.errorCode == 0) {
      emit(UzumPaySuccessState());
    } else {
      emit(UzumPayFailureState(uzumResponse.errorMessage ?? ""));
    }
    LogService.sendToTelegramm(log, SecureKeys.TELEGRAM_BOT_UZUM_ERROR_CHANEL);
  }
}
