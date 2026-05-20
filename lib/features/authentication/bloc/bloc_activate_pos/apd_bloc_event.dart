part of 'apd_bloc_bloc.dart';

abstract class APDevent {}

class APDinitialEvent extends APDevent {
  final List<GetAvailablePosResponseData> availablePosList;
  final GetAvailablePosResponseData selectedPos;
  final StoresModel selectedStore;

  APDinitialEvent({
    required this.selectedStore,
    required this.availablePosList,
    required this.selectedPos,
  });
}

class APDupdateProductsEvent extends APDevent {}

class APDgetCategoriesEvent extends APDevent {}

class APDgetDiscountsEvent extends APDevent {}

class APDgetOrganizationEvent extends APDevent {
  final String posId;

  APDgetOrganizationEvent({required this.posId});
}

class APDselectPosEvent extends APDevent {
  final Object selectedPosId;

  APDselectPosEvent(this.selectedPosId);
}

class APDallGetEvent extends APDevent {}

class APDgetEmployeeEvent extends APDevent {}

class APDgetServiceEvent extends APDevent {}

class APDactivatePosDeviceEvent extends APDevent {
  final GetAvailablePosResponseData? selectedPos;
  final StoresModel selectedStore;
  final String token;
  final String macAddress;

  APDactivatePosDeviceEvent({
    required this.macAddress,
    required this.selectedPos,
    required this.selectedStore,
    required this.token,
  });
}

class APDreloadEvent extends APDevent {
  final APDstatus status;

  APDreloadEvent({
    required this.status,
  });
}
