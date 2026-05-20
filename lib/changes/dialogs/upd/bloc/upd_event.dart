part of 'upd_bloc.dart';

abstract class UpdEvent {}

class UpdStartEvent extends UpdEvent {
  bool isRetry;
  List<APDstatus> status;

  UpdStartEvent(this.isRetry, this.status);
}

class UpdCallSomeFailedEvent extends UpdEvent {}

class UpdInitialEvent extends UpdEvent {}

class UpdShowErrorEvent extends UpdEvent {
  UpdFailedRepo repo;

  UpdShowErrorEvent(this.repo);
}
