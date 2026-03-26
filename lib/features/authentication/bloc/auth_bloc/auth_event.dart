part of 'auth_bloc.dart';

abstract class AuthEvent {}

class AuthInitialEvent extends AuthEvent {
  AuthInitialEvent();
}

class AuthTypePhoneNumberEvent extends AuthEvent {
  final String str;

  AuthTypePhoneNumberEvent(this.str);
}

class AuthTypeStringEvent extends AuthEvent {
  final String strUsername;

  AuthTypeStringEvent(this.strUsername);
}

class AuthTypeSMScodeEvent extends AuthEvent {
  final String str;
  AuthTypeSMScodeEvent(this.str);
}

class AuthOnSubmittedPhoneNumberEvent extends AuthEvent {
  AppLocalizations loc;
  final String str;
  final String pass;

  AuthOnSubmittedPhoneNumberEvent({
    required this.pass,
    required this.str,
    required this.loc,
  });
}

class AuthOnSubmittedSmsCodeEvent extends AuthEvent {
  AppLocalizations loc;
  final String phone;

  final String str;
  AuthOnSubmittedSmsCodeEvent({
    required this.str,
    required this.phone,
    required this.loc,
  });
}

class AuthSmsIncorrectEvent extends AuthEvent {}
