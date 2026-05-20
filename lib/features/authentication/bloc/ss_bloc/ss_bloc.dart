import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/get_available_pos_api.dart';
import 'package:invan2/features/authentication/model/get_available_pos_response.dart';
import 'package:invan2/features/authentication/model/stores_model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import '../../../../utils/l10n/app_localizations.dart';

part 'ss_event.dart';

part 'ss_state.dart';

// means Select Storage
class SsBloc extends Bloc<SsEvent, SsState> {
  String token;
  List<StoresModel> stores;
  StoresModel selectedStore;

  SsBloc(
      {required this.selectedStore, required this.stores, required this.token})
      : super(
          SsInitial(
            selectedStore: selectedStore,
            stores: stores,
          ),
        ) {
    on<SsButtonPressedEvent>(_buttonPressed);
    on<SsSelectStoreEvent>(_selectStore);
    on<SsRetryEvent>(_retry);
  }

  _retry(SsRetryEvent event, Emitter<SsState> emit) {
    emit(SsInitial(selectedStore: selectedStore, stores: stores));
  }

  _selectStore(SsSelectStoreEvent event, Emitter<SsState> emit) {
    selectedStore = stores.firstWhere((element) => element.id == event.storeId);
    emit(SsInitial(selectedStore: selectedStore, stores: stores));
  }

  _buttonPressed(SsButtonPressedEvent event, Emitter<SsState> emit) async {
    emit(SsLoadingState(event.loc.internet_tekshirilmoqda));

    emit(SsLoadingState(event.loc.mavjud_qurilmalar_yuklanmoqda));
    await Pref.setString(PrefKeys.macAddress.toLowerCase(), "");

    HttpResult httpResult =
        await GetAvailablePosApi.getAvailablePoss(token: token);

    List<GetAvailablePosResponseData> allPosList =
        <GetAvailablePosResponseData>[];

    List<GetAvailablePosResponseData> availablePosList =
        <GetAvailablePosResponseData>[];

    if (httpResult.isSuccess) {
      allPosList = List<GetAvailablePosResponseData>.from(
        httpResult.result["data"].map(
          (x) => GetAvailablePosResponseData.fromJson(x),
        ),
      ).toList();

      for (var p in allPosList) {
        if (p.isActive == false) {
          if (p.storesId == selectedStore.id) {
            availablePosList.add(p);
          }
        }
      }
    } else {
      if (httpResult.getError == "Internet Error") {
        emit(SsLoadingFailedState("net"));
        return;
      }
      emit(SsLoadingFailedState(httpResult.getError));
      return;
    }
    if (availablePosList.isNotEmpty) {
      AppNavigation.pushReplacement(
        ActivatePosPage(
          token: token,
          availablePosList: availablePosList,
          selectedStore: selectedStore,
          macAddress: "",
        ),
      );
    } else {
      emit(
        SsLoadingFailedState(event.loc.pos_qurilma_mavjud_emas),
      );
    }
  }
}
