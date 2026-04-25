
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/services/api.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/discount_service.dart';
import 'package:invan2/changes/services/company_app_service.dart';
import 'package:invan2/changes/services/organization_service.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/features/authentication/model/get_available_pos_response.dart';
import 'package:invan2/features/authentication/model/stores_model.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/utils/constants/pref_keys.dart';
import 'package:invan2/utils/helpers/helpers.dart';

import '../../../../changes/dialogs/creat_product/model/mes_vat_unit_model/mes_unit.dart';
import '../../../../changes/services/measurement_unit.dart';
import '../../../../changes/services/var_unit.dart';
import '../../../../changes/singletons/service_singleton.dart';
import '../../../../utils/helpers/auth_backup.dart';
import '../../../../utils/util_functions.dart';
import '../../../features.dart';
import '../../../get_categories/service/category_service.dart';

part 'apd_bloc_event.dart';

part 'apd_bloc_state.dart';

class APDblocc extends Bloc<APDevent, APDstate> {
  final List<GetAvailablePosResponseData> availablePosList;
  GetAvailablePosResponseData? selectedPos;
  final StoresModel selectedStore;

  APDblocc({
    required this.selectedPos,
    required this.availablePosList,
    required this.selectedStore,
  }) : super(APDinitial(
          isButtonEnabled: false,
          availablePosList: availablePosList,
          selectedPos: selectedPos,
          selectedStore: selectedStore,
        )) {
    on<APDinitialEvent>(_initial);
    on<APDactivatePosDeviceEvent>(_activatePosDevicee);
    on<APDgetEmployeeEvent>(_getEmployee);
    on<APDgetCategoriesEvent>(_getCategories);
    on<APDgetDiscountsEvent>(_getDiscounts);
    on<APDgetServiceEvent>(_getService);
    on<APDupdateProductsEvent>(_updateProducts);
    on<APDreloadEvent>(_reload);
    on<APDselectPosEvent>(_posDeviceSelected);
    on<APDgetOrganizationEvent>(_getOrganization);
  }

  _getOrganization(
      APDgetOrganizationEvent event, Emitter<APDstate> emit) async {
    HttpResult httpResult = await OrganizationService.getOrganization();
    if (httpResult.isSuccess) {
      OrganizationModel organizationModel =
          OrganizationModel.fromJson(httpResult.result);

      final address = organizationModel.legalAddress ?? '';
      String greeting = "";
      String orgId = '';
      orgId = organizationModel.id ?? "";
      String companyName = organizationModel.name ?? "";
      bool companyActive = organizationModel.companyActive ?? false;
      bool autoGenerate = organizationModel.autoGenerate ?? false;
      bool soliqValidation = organizationModel.soliqValidation ?? false;

      // apps_soliq_app ni company_apps endpointidan olamiz
      bool markCheck = soliqValidation;
      final String token = Pref.getString(PrefKeys.token, '');
      HttpResult companyAppsResult = await CompanyAppsService.getCompanyApps(token);
      if (companyAppsResult.statusCode == 200 && companyAppsResult.result != null) {
        final appsData = companyAppsResult.result;
        if (appsData['apps_soliq_app'] != null) {
          markCheck = appsData['apps_soliq_app'] == true;
        }
      }


      await Pref.setString(PrefKeys.greeting, greeting);
      await Pref.setString(PrefKeys.orgID, orgId);
      await Pref.setString(PrefKeys.serviceAddress, address);
      await Pref.setString(PrefKeys.comName, companyName);
      await Pref.setString(PrefKeys.discountPercentageId,
          "1fe92aa8-2a61-4bf1-b907-182b497584ad");
      await Pref.setString(
          PrefKeys.discountDefaultId, "9a2aa8fe-806e-44d7-8c9d-575fa67ebefd");
      await Pref.setString(
          PrefKeys.discountAmountId, "9fb3ada6-a73b-4b81-9295-5c1605e54552");
      await Pref.setString(
          PrefKeys.cashBeckCC, "b9bf7285-fca9-4850-901f-9cf232cafc0c");
      await Pref.setString(
          PrefKeys.flatRate, "bee6b08e-46be-43e8-a5e7-4e36dfc29205");
      await Pref.setBool(PrefKeys.companyActive, companyActive);
      await Pref.setBool(PrefKeys.autoGenerate, autoGenerate);
      await Pref.setBool(PrefKeys.markCheckWithOfd, markCheck);
      await Pref.setBool(PrefKeys.withOFD, markCheck);

      HttpResult paymentRes =
          await OrganizationService.getPayments(event.posId);
      if (paymentRes.isSuccess) {
        List<Payment> pList = List<Payment>.from(
          paymentRes.result['payment_types'].map(
            (e) => Payment.fromJson(e),
          ),
          
        );
        Pref.setString(PrefKeys.chequeId, paymentRes.result["cheque_id"]);
        await OrganizationSingleton.setOrgPrefs(organizationModel, pList);

        HttpResult storeFields = await OrganizationService.getStoreFields(
            Pref.getString(PrefKeys.storeId, ""));
        if (storeFields.isSuccess) {
          StoresModel ss = StoresModel(
            id: storeFields.result["id"]!,
            name: storeFields.result["title"]!,
            address: storeFields.result["address"] ?? "",
            number: storeFields.result["phone_number"] ?? "",
            // number_of_cashbox: storeFields.result["number_of_cashbox"] ?? "",
          );
          await Pref.setString(PrefKeys.storeName, ss.name);
          await Pref.setString(PrefKeys.storeAddress, ss.address);
          await Pref.setString(PrefKeys.storePhoneNum, ss.number);
        }

        emit(APDloadingState(status: APDstatus.employee));
      }
    } else {
      emit(
        APDloadingFailedState(
          status: APDstatus.organization,
          error: httpResult.getError,
        ),
      );
    }
  }

  _posDeviceSelected(APDselectPosEvent event, Emitter<APDstate> emit) {
    selectedPos =
        availablePosList.firstWhere((e) => e.sId == event.selectedPosId);
    emit(APDinitial(
        isButtonEnabled: true,
        availablePosList: availablePosList,
        selectedPos: selectedPos,
        selectedStore: selectedStore));
  }

  _initial(APDinitialEvent event, Emitter<APDstate> emit) {
    emit(
      APDinitial(
        isButtonEnabled: true,
        availablePosList: event.availablePosList,
        selectedPos: event.selectedPos,
        selectedStore: event.selectedStore,
      ),
    );
  }

  _reload(APDreloadEvent event, Emitter<APDstate> emit) async {
    emit(APDloadingState(status: event.status));
  }

  _updateProducts(APDupdateProductsEvent event, Emitter<APDstate> emit) async {
    String? result = await UtilFunctions.fullUpdateProduct(apd: true);

    if (result == null) {
      emit(APDallDoneState());
      // Opened cashBox
      await ShiftApi4.openCashBox();
    } else {
      emit(APDloadingFailedState(
        error: result,
        status: APDstatus.items,
      ));
    }
  }

  _getService(APDgetServiceEvent event, Emitter<APDstate> emit) async {
    // emit(APDloadingState(status: APDstatus.service));
    HttpResult httpResult = await ServiceGetApi.serviceGet(
      Pref.getString(PrefKeys.chequeId, ""),
    );
    if (httpResult.isSuccess) {
      ServiceGetResponseData recDesign =
          ServiceGetResponseData.fromJson(httpResult.result);
      await ServiceSingleton.setPrefs(recDesign);
      emit(APDloadingState(status: APDstatus.items));
      return;
    }
    emit(APDloadingFailedState(
        status: APDstatus.service, error: httpResult.getError));
  }

  _getCategories(APDgetCategoriesEvent event, Emitter<APDstate> emit) async {
    String? result = await CategoryService.category();
    if (result == null) {
      emit(APDloadingState(status: APDstatus.discounts));
    } else {
      emit(APDloadingFailedState(status: APDstatus.category, error: result));
    }
  }

  _getDiscounts(APDgetDiscountsEvent event, Emitter<APDstate> emit) async {
    String? result = await DiscountService.discounts();

    if (result == null) {
      emit(APDloadingState(status: APDstatus.service));
    } else {
      emit(APDloadingFailedState(status: APDstatus.discounts, error: result));
    }
  }

  _getEmployee(APDgetEmployeeEvent even, Emitter<APDstate> emit) async {
    String? result = await UtilFunctions.fullUpdateEmployee();

    if (result == null) {
      emit(APDloadingState(status: APDstatus.category));
    } else {
      emit(
        APDloadingFailedState(status: APDstatus.employee, error: result),
      );
    }
  }

  _activatePosDevicee(
      APDactivatePosDeviceEvent event, Emitter<APDstate> emit) async {
    emit(
      APDloadingState(
        status: APDstatus.posDevice,
      ),
    );
    await Pref.setString(PrefKeys.acceptService, event.selectedStore.id);
    await Pref.setString(PrefKeys.token, event.token);
    await AuthBackup.save(event.token);
    await Pref.setString(PrefKeys.macAddress, event.macAddress);
    await Pref.setString(PrefKeys.activatedPosId, event.selectedPos!.sId!);
    await Pref.setString(PrefKeys.storeName, event.selectedStore.name);
    await Pref.setString(PrefKeys.storeAddress, event.selectedStore.address);
    await Pref.setString(PrefKeys.storePhoneNum, event.selectedStore.number);
    await Pref.setString(PrefKeys.storeId, event.selectedStore.id);
    await Pref.setString(PrefKeys.posName, event.selectedPos!.name!);
    await Pref.setString(PrefKeys.checkId, event.selectedPos?.prefix ?? "");

    //   await Pref.setInt(PrefKeys.receiptNo, v.receiptNo!);
    //   await Pref.setString(PrefKeys.organization, v.organization!);
    //   await Pref.setBool(PrefKeys.orgINITIALIZED, true);

    HttpResult mesRes = await MeasurementUnitSer.mesunit();
    if (mesRes.isSuccess) {
      HttpResult vatRes = await VatUnit.vatUnit();
      if (vatRes.isSuccess) {
        List<MesUnitModel> mesUnits = [];
        List<VatUnitModel> vatUnits = [];
        vatUnits = List<VatUnitModel>.from(
          vatRes.result['data'].map((e) => VatUnitModel.fromJson(e)),
        ).toList();
        mesUnits = List<MesUnitModel>.from(
          mesRes.result['data'].map((e) => MesUnitModel.fromJson(e)),
        ).toList();

        Box<VatUnitModel> vatBox = HiveBoxes.vatUnitBox();
        Box<MesUnitModel> mesBox = HiveBoxes.mesUnitBox();

        vatBox.clear();
        mesBox.clear();

        Map<String, VatUnitModel> mapVat = {};
        for (var vat in vatUnits) {
          mapVat[vat.key] = vat;
          await vatBox.putAll(mapVat);
        }

        Map<String, MesUnitModel> mesMap = {};
        for (var mes in mesUnits) {
          mesMap[mes.key] = mes;
          await mesBox.putAll(mesMap);
        }

        emit(APDloadingState(status: APDstatus.organization));
      } else {
        emit(APDloadingFailedState(
            status: APDstatus.posDevice, error: vatRes.getError));
      }
    } else {
      emit(APDloadingFailedState(
          status: APDstatus.posDevice, error: mesRes.getError));
    }
  }
}

enum APDstatus {
  items,
  category,
  organization,
  employee,
  service,
  posDevice,
  discounts
}
