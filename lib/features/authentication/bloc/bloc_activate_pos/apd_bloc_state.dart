part of 'apd_bloc_bloc.dart';

abstract class APDstate {}

class APDinitial extends APDstate {
  final bool isButtonEnabled;
  final List<GetAvailablePosResponseData> availablePosList;
  final GetAvailablePosResponseData? selectedPos;
  final StoresModel selectedStore;

  APDinitial({
    required this.isButtonEnabled,
    required this.availablePosList,
    required this.selectedPos,
    required this.selectedStore,
  });
}

class APDnoDeviceAvailable extends APDstate {}

class APDloadingState extends APDstate {
  final APDstatus status;

  APDloadingState({required this.status});
}

class APDallDoneState extends APDstate {}

class APDloadingFailedState extends APDstate {
  final APDstatus status;
  final String error;

  APDloadingFailedState({
    required this.error,
    required this.status,
  });
}

class APDupdateProductsFailedState extends APDstate {}

class APDinitPrefsBeforeStartState extends APDstate {}
