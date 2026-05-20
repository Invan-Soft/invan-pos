import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';

part 'nad_event.dart';
part 'nad_state.dart';

// no access bloc
class NadBloc extends Bloc<NadEvent, NadState> {
  NadBloc() : super(NadInitial()) {
    on<NadScannedEvent>(_scanned);
    on<NadCallInitialEvent>(_callInitial);
  }
  _callInitial(NadCallInitialEvent event, Emitter<NadState> emit) {
    emit(NadInitial());
  }

  _scanned(NadScannedEvent event, Emitter<NadState> emit) async {
    emit(NadLoadingState());
    List<Employee> employees =
        HiveBoxes.getEmployees().values.cast<Employee>().toList();
    await Future.delayed(const Duration(milliseconds: 250));
    Employee? e;
    if (employees.isNotEmpty) {
      try {
        e = employees.firstWhere((e) =>
            "${e.user?.passCode}" == event.scanned &&
            // (e.superPassword ?? "NULL") == event.scanned &&
            (e.access?.deleteS ?? false));
      } catch (err) {
        e = null;
      }
    }

    if (e != null) {
      emit(NadSuccessedState());
      return;
    }

    emit(NadFailedState());
  }
}
