part of 'bl_bloc.dart';

// BARCODE LISTENER
abstract class BlEvent {}

class BlVisibilityChangedEvent extends BlEvent {
  final bool visibility;
  BlVisibilityChangedEvent(this.visibility);
}

class BlStatusChangedEvent extends BlEvent {
  final String where;
  final BLStatus status;
  BlStatusChangedEvent({required this.status, required this.where});
}
