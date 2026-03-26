import 'package:flutter_bloc/flutter_bloc.dart';

part 'wrapper_event.dart';
part 'wrapper_state.dart';

class WrapperBloc extends Bloc<WrapperEvent, WrapperState> {
  WrapperBloc() : super(WrapperInitial()) {
    on<WrapperCallGoToEvent>(_goto);
    on<WrapperCallWaitEvent>(_wait);
  }
  _wait(WrapperCallWaitEvent event, Emitter<WrapperState> emit) {
    emit(WrapperWaitState());
  }

  _goto(WrapperCallGoToEvent event, Emitter<WrapperState> emit)async {
    emit(WrapperGoToState());
  }
}
