part of 'payme_bloc.dart';

@immutable
abstract class PaymeState {}

class PaymeInitial extends PaymeState {}

class PaymeLoading extends PaymeState {}

class PaymeSuccessCreate extends PaymeState {
final  int amount;
  PaymeSuccessCreate(this.amount);
}

class PaymeSuccessPay extends PaymeState {
  
  PaymeSuccessPay();
}

class PaymeFailCreate extends PaymeState {
  final String message;
  PaymeFailCreate(this.message);
}

class PaymeFailPay extends PaymeState {
  final String message;
  PaymeFailPay(this.message);
}


