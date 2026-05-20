import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../utils/constants/constants.dart';
import '../../../utils/helpers/helpers.dart';
import '../../features.dart';
import '../../hive_repository/hive_boxes.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  int index;

  SettingsBloc(this.index) : super(SettingsInitial()) {
    on<SettingsLeftItemPressedEvent>(_leftItemPressed);
    on<SettingsCallReportsEvent>(_callReports);
    on<SettingsPinCompeteEvent>(_pinComplete);
    on<SettingsCallPinEvent>(_callPin);
  }

  _callPin(SettingsCallPinEvent event, Emitter<SettingsState> emit) {
    emit(SettingsPinState(event.status));
  }

  _pinComplete(SettingsPinCompeteEvent event, Emitter<SettingsState> emit) {
    // if (event.pin == "2705") {
    //2705 pass
    List<Employee> employeeList =
        HiveBoxes.getEmployees().values.toList().cast<Employee>();
    List<Employee>? cemp =
        employeeList.where((e) => e.user?.passCode == event.pin).toList();
    if (cemp.isNotEmpty &&
        event.pin == cemp.first.user?.passCode.toString() &&
        cemp.first.access?.openShift == true) {
      switch (event.status) {
        case PinStatus.payme:
          emit(SettingsPaymeState());
          break;
        case PinStatus.click:
          emit(SettingsClickState());
          break;
        case PinStatus.humo:
          emit(SettingsHumoState());
          break;
        case PinStatus.report:
          emit(SettingsReportsState());
          break;
        case PinStatus.uzum:
          emit(SettingsUzumState());
          break;
      }
    } else {
      emit(SettingsInvalidPinState(event.status));
    }
  }

  _callReports(SettingsCallReportsEvent event, Emitter<SettingsState> emit) {
    emit(SettingsPinState(PinStatus.report));
  }

  _leftItemPressed(
      SettingsLeftItemPressedEvent event, Emitter<SettingsState> emit) {
    index = event.index;
    switch (event.index) {
      case 0:
        emit(SettingsInitial());

        break;
      case 1:
        emit(SettingsSettingsState());

        break;
      case 2:
        emit(SettingsPinState(PinStatus.click));

        break;
      case 3:
        // emit(SettingsPinState(PinStatus.humo));
        emit(SettingsHumoState());
        break;

      case 4:
        emit(SettingsPinState(PinStatus.payme));
        break;

      case 5:
        emit(SettingsPinState(PinStatus.uzum));
        break;

      default:
    }
  }
}

enum PinStatus { payme, click, humo, report, uzum }
