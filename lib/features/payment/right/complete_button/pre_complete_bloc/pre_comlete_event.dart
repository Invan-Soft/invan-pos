part of 'per_comlete_bloc.dart';

abstract class PreCtEvent {}

class PreCmtBInitialEvent extends PreCtEvent {}

class PreCtPayEvent extends PreCtEvent {
  final double sdacha;
  final bool ofd;
  final bool sdachaToCashbak;
  PreCtPayEvent(
      {required this.sdacha, required this.ofd, required this.sdachaToCashbak});
}

class PreCtPaySuccessedEvent extends PreCtEvent {
  final bool showSdachaDialog;
  final double sdacha;
  PreCtPaySuccessedEvent(
      {required this.sdacha, required this.showSdachaDialog});
}

class PreCtPrepareToPayEvent extends PreCtEvent {
  PreCtPrepareToPayEvent();
}

class PreCtErrorEvent extends PreCtEvent {
  Object subError;
  final String error;
  PreCtErrorEvent({required this.error, required this.subError});
}
