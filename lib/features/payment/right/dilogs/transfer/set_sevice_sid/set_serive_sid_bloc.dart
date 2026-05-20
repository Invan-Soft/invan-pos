import 'package:flutter_bloc/flutter_bloc.dart';

part 'set_serive_sid_event.dart';

part 'set_serive_sid_state.dart';

class SetServeceSidBloc extends Bloc<SetServeceSidEvent, SetServiceSidState> {
  SetServeceSidBloc() : super(SetServiceSidInitial()) {
    on<StartSetServiceSidEvent>(_setServiceSid);
  }

  Future<void> _setServiceSid(
    StartSetServiceSidEvent event,
    Emitter<SetServiceSidState> emit,
  ) async {
    emit(SetServiceSidSuccesState(
      event.sID,
      event.name,
    ));
  }
}
