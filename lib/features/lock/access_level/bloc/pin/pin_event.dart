part of 'pin_bloc.dart';

abstract class PinEvent {}



class PinPressNumEvent extends PinEvent {
  final String pressed;
  PinPressNumEvent(this.pressed);
}
class PinGetOrganizationEvent extends PinEvent{
  
}
class PinDeleteEvent extends PinEvent {}

class PinSubmitEvent extends PinEvent {
  final String pin;
  PinSubmitEvent(this.pin);
}

class PinCButtonPressedEvent extends PinEvent {}


