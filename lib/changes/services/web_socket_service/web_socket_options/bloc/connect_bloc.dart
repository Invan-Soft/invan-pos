import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../ws_service.dart';

part 'connect_event.dart';

part 'connect_state.dart';

class ConnectBloc extends Bloc<ConnectEvent, ConnectState> {
  ConnectBloc() : super(ConnectInitial()) {
    on<InitialEvent>((event, emit) {
      emit(ConnectSuccessState());
    });
    on<DisconnectEvent>((event, emit) {
      emit(DisconnectState());
    });
    on<ConnectRequestEvent>((event, emit) async {
      emit(LoadingConnectState());
      WsService.disconnect(event.context);
      // await WsService.connectToInvan(event.mounded, event.context,
      //     onDisconnect: event.onDisconnect);
      if (WsService.channel != null) {
        emit(ConnectSuccessState());
      } else {
        emit(DisconnectState());
      }
    });
  }
}
