part of 'addclient_bloc.dart';

abstract class AddClientState {}

class AddclientInitial extends AddClientState {}

class AddClientLoadingState extends AddClientState {
  final String message;
  AddClientLoadingState(this.message);
}

class AddClientNoInternetState extends AddClientState {
  final AddClientInfo info;
  AddClientNoInternetState({required this.info});
}

class AddClientSuccedState extends AddClientState {
  final String name;
  final String number;

  AddClientSuccedState(this.name, this.number);
}

class AddClientFailedState extends AddClientState {
  final HttpResult result;
  final AddClientInfo info;
  AddClientFailedState({required this.result, required this.info});
}
