part of 'usr_bloc.dart';

// Usr means UnSentReceipts
abstract class UsrState {}

class UsrInitial extends UsrState {}

class UsrInSendingState extends UsrState {}

class UsrLoadingState extends UsrState {
  final String message;
  UsrLoadingState(this.message);
}

class UsrBackendRejectedState extends UsrState {
  final String error;
  UsrBackendRejectedState(this.error);
}

class UsrErrorState extends UsrState {
  final String error;
  UsrErrorState(this.error);
}

class UsrNoInternetState extends UsrState {
  final String where;
  UsrNoInternetState(this.where);
}

class UsrNoUnsentReceiptsState extends UsrState {}

class UsrFinishedState extends UsrState {}

class UsrAlreadyInProgressState extends UsrState {}
