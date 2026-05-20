part of 'ss_bloc.dart';

abstract class SsEvent {}

class SsSelectStoreEvent extends SsEvent {
  final Object storeId;
  SsSelectStoreEvent(this.storeId);
}

class SsButtonPressedEvent extends SsEvent {
  final AppLocalizations loc;
  final String selectedStoreId;
  SsButtonPressedEvent({
    required this.loc,
    required this.selectedStoreId,
  });
}

class SsRetryEvent extends SsEvent {}
