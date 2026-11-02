part of 'settings_bloc.dart';

abstract class SettingsState {}

class SettingsInitial extends SettingsState {}

class SettingsSettingsState extends SettingsState {}

class SettingsPinState extends SettingsState {
  final PinStatus status;
  SettingsPinState(this.status);
}

class SettingsReportsState extends SettingsState {}

class SettingsPaymeState extends SettingsState {}

class SettingsClickState extends SettingsState {}

class SettingsHumoState extends SettingsState {}

class SettingsUzumState extends SettingsState {}

class SettingsInvalidPinState extends SettingsState {
  final PinStatus status;
  SettingsInvalidPinState(this.status);
}
