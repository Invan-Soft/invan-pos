import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'bl_event.dart';

part 'bl_state.dart';

// BARCODE LISTENER
class BlBloc extends Bloc<BlEvent, BlState> {
  bool isVisible = false;
  BLStatus status = BLStatus.home;

  BlBloc() : super(BlInitial(BLStatus.home)) {
    on<BlVisibilityChangedEvent>(_visibility);
    on<BlStatusChangedEvent>(_statusChanged);
  }

  FutureOr<void> _statusChanged(
    BlStatusChangedEvent event,
    Emitter<BlState> emit,
  ) {
    status = event.status;
    emit(BlInitial(status));
  }

  FutureOr<void> _visibility(
    BlVisibilityChangedEvent event,
    Emitter<BlState> emit,
  ) {
    isVisible = event.visibility;
    emit(BlInitial(status));
  }
}

enum BLStatus { home, other, click, client, payme, magneticStripe, uzum }
