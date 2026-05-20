part of 'preofd_bloc.dart';

abstract class PreOfdState {}

class PreOfdInitial extends PreOfdState {}

class PreOfdLoadingState extends PreOfdState {
  final ReturnMessage message;

  PreOfdLoadingState({required this.message});
}

class PreOfdNoInternetState extends PreOfdState {}

class PreOfdSuccedState extends PreOfdState {
  ReceiptModel4 receiptModel4;

  PreOfdSuccedState(this.receiptModel4);
}

class PreOfdFailedState extends PreOfdState {
  final String error;

  PreOfdFailedState({required this.error});
}
