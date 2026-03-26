part of 'access_bloc.dart';

abstract class AccessState {}

class AccessAccessState extends AccessState {
  AccessAccessState();
}

class AccessPincodeState extends AccessState {
  AccessPincodeState();
}

class AccessBlockedState extends AccessState {
  final int passwordLenth;
  AccessBlockedState(this.passwordLenth);
}
