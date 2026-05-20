import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/models/client_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/client_api.dart';

part 'addclient_event.dart';
part 'addclient_state.dart';

class AddClientBloc extends Bloc<AddClientEvent, AddClientState> {
  AddClientBloc() : super(AddclientInitial()) {
    on<AddClientAddEvent>(_add);
    on<AddClientCallInitialEvent>(_callInitial);
  }

  _callInitial(AddClientCallInitialEvent event, Emitter<AddClientState> emit) {
    emit(AddclientInitial());
  }

  _add(AddClientAddEvent event, Emitter<AddClientState> emit) async {
    emit(AddClientLoadingState("add"));
    await Future.delayed(const Duration(milliseconds: 500));
    emit(AddClientLoadingState("add"));
    ClientModel client = ClientModel(
      firstName: event.info.name,
      lastName: event.info.lastname,
      phoneNumber: event.info.phone,
      gender: event.info.idf
          ? '1fe92aa8-2a61-4bf1-b907-182b497584ad'
          : '9fb3ada6-a73b-4b81-9295-5c1605e54552',
      group: event.info.groupId,
      cardNumber: event.info.cardNumber,
      // userId: event.info.cardId,
    );
    HttpResult httpResult = await ClientApi.createClientt(client);
    if (httpResult.isSuccess) {
      emit(AddClientSuccedState(event.info.name, event.info.phone, ));
      return;
    }
    if (httpResult.getError == "Internet Error") {
      emit(AddClientNoInternetState(info: event.info));
      return;
    }
    emit(AddClientFailedState(result: httpResult, info: event.info));
  }
}

class AddClientInfo {
  String name;
  String lastname;
  String phone;
  String cardNumber;
  bool idf;
  String groupId;
  AddClientInfo({
    required this.cardNumber,
    required this.idf,
    required this.lastname,
    required this.name,
    required this.phone,
    required this.groupId,
  });
}
