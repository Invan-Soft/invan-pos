part of 'usr_bloc.dart';

// Usr means UnSentReceipts
abstract class UsrEvent {}

class UsrSendEvent extends UsrEvent {
  final String where;
  int? unsents;
  UsrSendEvent(this.where, this.unsents);
}

class UsrSendSpecialEvent extends UsrEvent {
  final String where;
  int? unsents;
  UsrSendSpecialEvent(this.where, this.unsents);
}

class UsrCallInitialEvent extends UsrEvent {}

class UsrDataChangedEvent extends UsrEvent {
  int unsents;
  UsrDataChangedEvent(this.unsents);
}
