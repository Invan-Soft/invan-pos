part of 'comlete_bloc.dart';

abstract class CtEvent {}

class CmtBInitialEvent extends CtEvent {}

class CtPayEvent extends CtEvent {
  final double sdacha;
  final bool ofd;
  final bool sdachaToCashbak;
  CtPayEvent(
      {required this.sdacha, required this.ofd, required this.sdachaToCashbak});
}

class CtPaySuccessedEvent extends CtEvent {
  final bool showSdachaDialog;
  final double sdacha;
  CtPaySuccessedEvent({required this.sdacha, required this.showSdachaDialog});
}

class CtPrepareToPayEvent extends CtEvent {
  CtPrepareToPayEvent();
}

class CtErrorEvent extends CtEvent {
  Object subError;
  final String error;
  CtErrorEvent({required this.error, required this.subError});
}
