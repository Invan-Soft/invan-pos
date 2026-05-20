part of 'addclient_bloc.dart';

abstract class AddClientEvent {}

class AddClientAddEvent extends AddClientEvent {
  final AddClientInfo info;
  AddClientAddEvent({
   required this.info
  });
}

class AddClientCallInitialEvent extends AddClientEvent {}

