part of 'settings_bloc.dart';

abstract class SettingsEvent {}

class SettingsLeftItemPressedEvent extends SettingsEvent {
  final int index;
  SettingsLeftItemPressedEvent(this.index);
}

class SettingsCallReportsEvent extends SettingsEvent {}

class SettingsCallPinEvent extends SettingsEvent {
  final PinStatus status;
  SettingsCallPinEvent(this.status);
}

class SettingsPinCompeteEvent extends SettingsEvent {
  final String pin;
  final PinStatus status;
  SettingsPinCompeteEvent(this.status, this.pin);
}
