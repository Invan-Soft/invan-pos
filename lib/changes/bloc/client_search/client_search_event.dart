part of 'client_search_bloc.dart';

abstract class ClientEvent {}

class ClientInitialEvent extends ClientEvent {}

class ClientSearchEvent extends ClientEvent {
  bool isSpecialClient;

  ClientSearchEvent(this.isSpecialClient);
}

class ClientFoundEvent extends ClientEvent {
  final ClientModel client;

  ClientFoundEvent(this.client);
}

class ClientClearControllerEvent extends ClientEvent {}
