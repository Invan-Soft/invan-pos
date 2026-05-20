import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';

import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';

part 'supplier_search_event.dart';
part 'supplier_search_state.dart';

class SupplierBloc extends Bloc<SupplierEvent, SupplierSearchState> {
  TextEditingController controller = TextEditingController();

  SupplierBloc() : super(SupplierInitialState()) {
    on<SupplierSearchEvent>(_supplierSearch);
    on<SupplierInitialEvent>(_initial);
    on<SupplierClearControllerEvent>(_clearController);
  }

  _clearController(
      SupplierClearControllerEvent event, Emitter<SupplierSearchState> emit) {
    controller.text = '';
  }

  _initial(SupplierInitialEvent event, Emitter<SupplierSearchState> emit) {
    // controller = TextEditingController();
    controller.clear();
    emit(SupplierInitialState());
  }

  _supplierSearch(
      SupplierSearchEvent event, Emitter<SupplierSearchState> emit) async {
    final query = controller.text.trim();
    if (query.isEmpty) return;

    emit(SupplierLoadingState());

    HttpResult result = await SupplierApi.searchSuppliers(search: query);

    if (result.isSuccess) {
      final data = result.result['data'] as List;
      if (data.isEmpty) {
        emit(SupplierNotFoundState());
      } else {
        final supplier = SupplierModel.fromJson(data[0]);
        emit(SupplierFoundState(supplier: supplier));
      }
    } else {
      emit(SupplierErrorState(result.getError));
    }
  }
}