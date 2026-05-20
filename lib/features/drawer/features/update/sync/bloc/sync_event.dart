part of 'sync_bloc.dart';

abstract class SyncEvent {}

class SyncSyncEvent extends SyncEvent {
 
  SyncSyncEvent();
}

class SyncInitialEvent extends SyncEvent {}
