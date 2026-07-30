part of 'client_search_bloc.dart';

abstract class ClientEvent {}

class ClientInitialEvent extends ClientEvent {}

class ClientSearchEvent extends ClientEvent {
  bool isSpecialClient;

  // true bo'lsa, clients_by_pos'da topilmasa, xuddi shu INN bo'yicha
  // supplier (postavshik) API'siga ham so'rov yuboriladi (Perechisleniya/
  // Didox oynasi uchun — mijoz yoki supplier, qaysinisi javob qaytarsa).
  final bool alsoCheckSupplier;

  ClientSearchEvent(this.isSpecialClient, {this.alsoCheckSupplier = false});
}

class ClientFoundEvent extends ClientEvent {
  final ClientModel client;

  ClientFoundEvent(this.client);
}

class ClientClearControllerEvent extends ClientEvent {}
