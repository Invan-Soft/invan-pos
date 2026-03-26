import 'package:flutter_bloc/flutter_bloc.dart';

part 'access_event.dart';
part 'access_state.dart';

class AccessBloc extends Bloc<AccessEvent, AccessState> {
  int level;
  bool isSyncCancelled = false;
  AccessBloc(this.level) : super(AccessAccessState()) {
    // on<AccessEvent>(_autoUpdate);
    on<AccessBlocEvent>(_block);
    on<AccessSwitchToAccessEvent>(_switchToAccess);
    on<LockSwitchToPinEvent>(_switchToPin);
  }
  _block(AccessBlocEvent event, Emitter<AccessState> emit) async {
    emit(AccessBlockedState(event.passwordLenth));
    await Future.delayed(const Duration(seconds: 30));
    emit(AccessPincodeState());
  }

  _switchToPin(LockSwitchToPinEvent event, Emitter<AccessState> emit) {
    level = event.level;
    emit(AccessPincodeState());
  }

  _switchToAccess(AccessSwitchToAccessEvent event, Emitter<AccessState> emit) {
    emit(AccessAccessState());
  }
}
