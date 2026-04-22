part of 'paynet_bloc.dart';

abstract class PaynetState {}

class PaynetInitial extends PaynetState {}

class PaynetLoadingState extends PaynetState {
  final PaynetLoadingStatus status;
  PaynetLoadingState(this.status);
}

class PaynetPaymentSuccessState extends PaynetState {}

class PaynetPaymentErrorState extends PaynetState {
  final String error;
  PaynetPaymentErrorState(this.error);
}

class PaynetNoInternetState extends PaynetState {
  final String otp;
  PaynetNoInternetState(this.otp);
}

enum PaynetLoadingStatus { internet, paying }
