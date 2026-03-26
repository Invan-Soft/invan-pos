part of 'click_bloc.dart';

abstract class ClickState {}

class ClickInitial extends ClickState {}

class ClickLoadingState extends ClickState {
  final ClickLoadingStatus status;
  ClickLoadingState(this.status);
}

class ClickPaymentSuccessState extends ClickState {}

class ClickPaymentErrorState extends ClickState {
  final String error;
  ClickPaymentErrorState(this.error);
}

class ClickNoInternetState extends ClickState {
  final String otp;
  ClickNoInternetState(this.otp);
}
