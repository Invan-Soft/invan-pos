// ignore_for_file: unused_local_variable
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/employees_api.dart';
import 'package:invan2/features/get_employees/model/employees_find_response.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/utils.dart';
import '../../../../../utils/helpers/prefs.dart';
import '../../../../../utils/util_functions.dart';

part 'pin_event.dart';

part 'pin_state.dart';

class PinBloc extends Bloc<PinEvent, PinState> {
  // passwordLenth can only be 4 or 6
  final int passwordLength = 4;
  int numOfTry = 0;
  final int accessLevel;
  List<Employee> employeeList =
      HiveBoxes.getEmployees().values.toList().cast<Employee>();
  Employee? selectedEmployee;
  String pinCode = '';

  PinBloc(this.accessLevel)
      : super(PinInitial(length: 0, status: PinSuccesStatus.initial)) {
    on<PinPressNumEvent>(_pressNum);
    on<PinDeleteEvent>(_delete);
    on<PinCButtonPressedEvent>(_cPressed);
    on<PinSubmitEvent>(_submit);
    on<PinGetOrganizationEvent>(_getOrganization);
  }

  _getOrganization(
      PinGetOrganizationEvent event, Emitter<PinState> emit) async {
    emit(PinLoadingStatee());

    // if (e.data != null) {
    //   emit(PinInitial(length: 0, status: PinSuccesStatus.initial));
    // } else {
    //   emit(PinInitial(
    //     length: 0,
    //     status: PinSuccesStatus.getOrgErr,
    //     error: httpResult.getError,
    //   ));
    // }

    ///////////////////////

    String? result = await UtilFunctions.fullUpdateEmployee();
    if (result == null) {
      emit(PinInitial(length: 0, status: PinSuccesStatus.initial));
    } else {
      emit(
        PinInitial(
          length: 0,
          status: PinSuccesStatus.getOrgErr,
          error: result,
        ),
      );
    }
  }

  _submit(PinSubmitEvent event, Emitter<PinState> emit) async {
    if (event.pin.length == passwordLength) {
      emit(PinLoadingStatee());

      pinCode = event.pin;

      bool result = await checkPinCode();
      if (result) {
        emit(PinInitial(
            length: pinCode.length, status: PinSuccesStatus.pinSucced));
        return;
      }
      numOfTry++;
      emit(
          PinInitial(length: pinCode.length, status: PinSuccesStatus.pinWrong));
    }
    return;
  }

  _cPressed(PinCButtonPressedEvent event, Emitter<PinState> emit) {
    pinCode = '';
    emit(
      PinInitial(
        length: pinCode.length,
        status: PinSuccesStatus.initial,
      ),
    );
  }

  _delete(PinDeleteEvent event, Emitter<PinState> emit) {
    if (pinCode.isNotEmpty) {
      pinCode = pinCode.substring(0, pinCode.length - 1);
      emit(PinInitial(length: pinCode.length, status: PinSuccesStatus.initial));
      return;
    }
    return;
  }

  _pressNum(PinPressNumEvent event, Emitter<PinState> emit) async {
    // for (int i = 0; i < employeeList.length; i++) {
    //   Log.d(employeeList[i].superPassword, name: 'pin_bloc');
    //   Log.d(employeeList[i].password, name: 'pin_bloc');
    //   Log.d(employeeList[i].name, name: 'pin_bloc');
    //   Log.d(employeeList[i].fullName, name: 'pin_bloc');
    // }
    if (pinCode.length < passwordLength) {
      pinCode += event.pressed;
    }
    if (pinCode.length == passwordLength) {
      emit(PinLoadingStatee());
      bool result = await checkPinCode();
      if (result) {
        emit(
          PinInitial(length: pinCode.length, status: PinSuccesStatus.pinSucced),
        );
        return;
      }
      numOfTry++;
      emit(
        PinInitial(length: pinCode.length, status: PinSuccesStatus.pinWrong),
      );
      return;
    }

    emit(PinInitial(length: pinCode.length, status: PinSuccesStatus.initial));
  }

  Future<bool> checkPinCode() async {
    for (int i = 0; i < employeeList.length; i++) {
      employeeList[i].toJson();
    }
    int index = -1;
    if (accessLevel > 2) {
      index = employeeList.indexWhere((element) {
        if (element.user!.passCode == pinCode) {
          Pref.setString(PrefKeys.userId, element.user!.id!);
        }
        return element.user!.passCode == pinCode &&
            element.access!.receiptHistory!;
      });
    } else {
      index = employeeList.indexWhere(
        (element) {
          if (element.user!.passCode == pinCode) {
            Pref.setString(PrefKeys.userId, element.user!.id!);
          }
          return element.user!.passCode == pinCode;
        },
      );
    }

    if (index >= 0) {
      pinCode = '';
      Pref.setDeleteItem(
          'delete_ticket', employeeList[index].access?.deleteS ?? false);
      selectedEmployee = employeeList[index];
      return true;
    } else {
      return false;
    }
  }
}
