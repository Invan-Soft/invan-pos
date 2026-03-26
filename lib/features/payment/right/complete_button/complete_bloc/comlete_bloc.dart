import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

part 'comlete_event.dart';
part 'comlete_state.dart';

// COMPLETE BUTTON BLOC OF PAYMENT PAGE
class CmtBBloc extends Bloc<CtEvent, CtState> {
  CmtBBloc()
      : super(
          CtInitialState(),
        ) {
    on<CtPayEvent>(_pay);
    on<CtPrepareToPayEvent>(_prepere);
    on<CtErrorEvent>(_error);
    on<CtPaySuccessedEvent>(_success);
    on<CmtBInitialEvent>(_init);
  }
  _init(CmtBInitialEvent event, Emitter<CtState> emit) {
    emit(CtInitialState());
  }

  FutureOr<void> _success(
    CtPaySuccessedEvent event,
    Emitter<CtState> emit,
  ) {
    emit(CtSucceedState(
      sdacha: event.sdacha,
      showSdachaDialog: event.showSdachaDialog,
    ));
  }

  _error(CtErrorEvent event, Emitter<CtState> emit) async {
    emit(CtErrorState(error: event.error, subError: event.subError));
  }

  _prepere(CtPrepareToPayEvent event, Emitter<CtState> emit) {
    emit(CtPrepereState());
  }

  FutureOr<void> _pay(CtPayEvent event, Emitter<CtState> emit) async {
    emit(
      CtPayingState(
        ofd: event.ofd,
        sdacha: event.sdacha,
        sdachaToCashback: event.sdachaToCashbak,
      ),
    );
  }
}
