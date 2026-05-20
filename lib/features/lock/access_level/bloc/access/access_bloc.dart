import 'package:flutter_bloc/flutter_bloc.dart';

part 'access_event.dart';
part 'access_state.dart';

class AccessBloc extends Bloc<AccessEvent, AccessState> {
  int level;
  bool isSyncCancelled = false;
  DateTime? _blockEndTime;
  int _blockedPasswordLength = 4;

  // Keyboard lock state (survives widget rebuild)
  int keyboardWrongAttempts = 0;
  DateTime? keyboardLockEndTime;

  bool get isKeyboardLocked =>
      keyboardLockEndTime != null &&
      DateTime.now().isBefore(keyboardLockEndTime!);

  int get keyboardRemainingSeconds => isKeyboardLocked
      ? keyboardLockEndTime!.difference(DateTime.now()).inSeconds
      : 0;

  void recordKeyboardLock() {
    keyboardLockEndTime = DateTime.now().add(const Duration(seconds: 60));
  }

  void resetKeyboardLock() {
    keyboardWrongAttempts = 0;
    keyboardLockEndTime = null;
  }

  AccessBloc(this.level) : super(AccessAccessState()) {
    // on<AccessEvent>(_autoUpdate);
    on<AccessBlocEvent>(_block);
    on<AccessSwitchToAccessEvent>(_switchToAccess);
    on<LockSwitchToPinEvent>(_switchToPin);
  }

  bool get _isStillBlocked =>
      _blockEndTime != null && DateTime.now().isBefore(_blockEndTime!);

  _block(AccessBlocEvent event, Emitter<AccessState> emit) async {
    _blockedPasswordLength = event.passwordLenth;
    _blockEndTime = DateTime.now().add(const Duration(seconds: 30));
    emit(AccessBlockedState(event.passwordLenth));
    await Future.delayed(const Duration(seconds: 30));
    _blockEndTime = null;
    emit(AccessPincodeState());
  }

  _switchToPin(LockSwitchToPinEvent event, Emitter<AccessState> emit) {
    if (_isStillBlocked) {
      final remaining = _blockEndTime!.difference(DateTime.now()).inSeconds;
      emit(AccessBlockedState(_blockedPasswordLength, remainingSeconds: remaining));
      return;
    }
    level = event.level;
    emit(AccessPincodeState());
  }

  _switchToAccess(AccessSwitchToAccessEvent event, Emitter<AccessState> emit) {
    if (_isStillBlocked) {
      final remaining = _blockEndTime!.difference(DateTime.now()).inSeconds;
      emit(AccessBlockedState(_blockedPasswordLength, remainingSeconds: remaining));
      return;
    }
    emit(AccessAccessState());
  }
}
