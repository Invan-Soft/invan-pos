part of 'sync_bloc.dart';

abstract class SyncState {}

class SyncInitialState extends SyncState {}

class SyncNoInternetState extends SyncState {}

class SyncLoadingState extends SyncState {}

class SyncDoneState extends SyncState {
  DateTime lastUpdate;
  final SyncResult updated;
  SyncDoneState(this.updated, this.lastUpdate);
}

class SyncFailedState extends SyncState {
  final String error;
  SyncFailedState(this.error);
}
