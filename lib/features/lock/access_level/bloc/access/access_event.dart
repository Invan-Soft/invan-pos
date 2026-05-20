part of 'access_bloc.dart';

abstract class AccessEvent {}

class AccessSwitchToAccessEvent extends AccessEvent {}

class LockSwitchToPinEvent extends AccessEvent {
  final int level;
  LockSwitchToPinEvent(this.level);
}

class AccessBlocEvent extends AccessEvent {
  final int passwordLenth;
  AccessBlocEvent(this.passwordLenth);
}
