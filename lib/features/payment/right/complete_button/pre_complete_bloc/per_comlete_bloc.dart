import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'pre_comlete_event.dart';

part 'pre_comlete_state.dart';

// COMPLETE BUTTON BLOC OF PAYMENT PAGE
class PreCmtBBloc extends Bloc<PreCtEvent, PreCtState> {
  PreCmtBBloc()
      : super(
          PreCtInitialState(),
        ) {
    on<PreCtPayEvent>(_pay);
    on<PreCtPrepareToPayEvent>(_prepere);
    on<PreCtErrorEvent>(_error);
    on<PreCtPaySuccessedEvent>(_success);
    on<PreCmtBInitialEvent>(_init);
  }

  _init(PreCmtBInitialEvent event, Emitter<PreCtState> emit) {
    emit(PreCtInitialState());
  }

  FutureOr<void> _success(
    PreCtPaySuccessedEvent event,
    Emitter<PreCtState> emit,
  ) {
    emit(PreCtSucceedState(
      sdacha: event.sdacha,
      showSdachaDialog: event.showSdachaDialog,
    ));
  }

  _error(PreCtErrorEvent event, Emitter<PreCtState> emit) async {
    emit(PreCtErrorState(error: event.error, subError: event.subError));
  }

  _prepere(PreCtPrepareToPayEvent event, Emitter<PreCtState> emit) {
    emit(PreCtPrepereState());
  }

  FutureOr<void> _pay(PreCtPayEvent event, Emitter<PreCtState> emit) async {
    emit(
      PreCtPayingState(
        ofd: event.ofd,
        sdacha: event.sdacha,
        sdachaToCashback: event.sdachaToCashbak,
      ),
    );
  }
}
