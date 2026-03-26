part of 'auth_bloc.dart';

abstract class AuthState {}

class AuthInitialState extends AuthState {
  final bool enabled;
  final bool isSms;
  final bool restart;
  bool? smsRestart;
  AuthInitialState({
    this.smsRestart,
    required this.enabled,
    required this.isSms,
    required this.restart,
  });
}

class AuthVerifyFailedState extends AuthState {
  final String phone;
  final String error;
  AuthVerifyFailedState({required this.error, required this.phone});
}

class AuthLoadingState extends AuthState {
  final String message;
  AuthLoadingState(this.message);
}

class AuthLoadingFailedState extends AuthState {
  final String message;
  AuthLoadingFailedState({required this.message});
}

class AuthNoInternetState extends AuthState {
  AuthNoInternetState();
}
