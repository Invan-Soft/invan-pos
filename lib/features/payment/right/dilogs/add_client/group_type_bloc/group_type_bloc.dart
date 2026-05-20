// ignore_for_file: avoid_function_literals_in_foreach_calls

import 'dart:async';
import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/payment/right/dilogs/add_client/model/client_group.dart';

import '../../../../../../changes/services/api.dart';
import '../../../../../../changes/services/api/result_http_model.dart';
part 'group_type_event.dart';
part 'group_type_state.dart';

class GroupTypeBloc extends Bloc<GroupTypeEvent, GroupTypeState> {
  GroupTypeBloc() : super(GroupTypeInitial()) {
    on<GetGroupTypeEvent>(getGroupType);
  }

  Future<void> getGroupType(
    GetGroupTypeEvent event,
    Emitter<GroupTypeState> emit,
  ) async {
    emit(GroupTypeProccesState());
    HttpResult httpResult = await ClientApi.getClientGroup();
    List<ClientGroupType> groups = [];
    if (httpResult.isSuccess) {
      groups = List<ClientGroupType>.from(
        httpResult.result['data'].map(
          (e) => ClientGroupType.fromJson(e),
        ),
      ).toList();
    }
    ClientGroupType dt = ClientGroupType();
    groups.forEach((element) {
      if (element.setAsDef == true) {
        dt = element;
      }
    });
    if (dt.id == "" || dt.id == null) {
      dt = groups.first;
    }
    emit(GroupTypeSuccesState(types: groups, defaultType: dt));
  }
}
