part of 'tp_bloc.dart';

abstract class TpEvent {}

class TpNumPressedEvent extends TpEvent {
  final TpStatus inputStatus;
  final int pressed;
  final bool isAllSelected;

  TpNumPressedEvent({
    required this.pressed,
    required this.inputStatus,
    required this.isAllSelected,
  });
}

class TpBackSpacePressedEvent extends TpEvent {
  final TpStatus inputStatus;
  final bool isAllSelected;

  TpBackSpacePressedEvent(
      {required this.inputStatus, required this.isAllSelected});
}

class TpSaveButtonPressedEvent extends TpEvent {}

class TpSelectInputEvent extends TpEvent {
  TpStatus inputStatus;

  TpSelectInputEvent(this.inputStatus);
}
