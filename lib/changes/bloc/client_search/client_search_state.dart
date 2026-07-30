part of 'client_search_bloc.dart';

abstract class SearchClientState {}

class ClientInitialState extends SearchClientState {}

class ClientFoundState extends SearchClientState {
  final ClientModel client;
  ClientFoundState({required this.client});
}

class ClientNotFoundState extends SearchClientState {}

// clients_by_pos'da topilmadi, lekin xuddi shu INN bo'yicha supplier
// (postavshik) API'sida topildi.
class ClientSearchSupplierFoundState extends SearchClientState {
  final SupplierModel supplier;
  ClientSearchSupplierFoundState({required this.supplier});
}

class ClientErrorState extends SearchClientState {
  final String error;
  ClientErrorState(this.error);
}

class ClientNoInternetState extends SearchClientState {}

class ClientInvalidIdState extends SearchClientState {
  final String clientId;
  ClientInvalidIdState(this.clientId);
}

class ClientIdScannedState extends SearchClientState {
  final String clientId;
  ClientIdScannedState(this.clientId);
}

class ClientLoadingState extends SearchClientState {
  final ClientLS status;
  ClientLoadingState(this.status);
}
