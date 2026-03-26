part of 'set_serive_sid_bloc.dart';

abstract class SetServiceSidState {}

class SetServiceSidInitial extends SetServiceSidState {}

class SetServiceSidSuccesState extends SetServiceSidState {
  final String sID;
  final String name;

  SetServiceSidSuccesState(
    this.sID,
    this.name,
  );
}
