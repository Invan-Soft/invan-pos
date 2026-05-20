import 'package:flutter_bloc/flutter_bloc.dart';

part 'set_driver_event.dart';

part 'set_driver_state.dart';

class SetDriverBloc extends Bloc<SetDriverEvent, SetDriverState> {
  SetDriverBloc() : super(SetDriverInitial()) {
    on<SetStartDriverName>(_setDriverName);
  }

  Future<void> _setDriverName(
    SetStartDriverName event,
    Emitter<SetDriverState> emit,
  ) async {
    emit(SetDriverNameSucces(
      event.name,
      event.pass,
    ));
  }
}
