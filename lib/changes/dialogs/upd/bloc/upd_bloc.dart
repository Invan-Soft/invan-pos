import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/changes/models/product/item_model.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/get_items_service.dart';
import 'package:invan2/changes/services/organization_service.dart';
import 'package:invan2/changes/singletons/organization_singleton.dart';
import 'package:invan2/changes/singletons/service_singleton.dart';
import 'package:invan2/features/authentication/bloc/bloc_activate_pos/apd_bloc_bloc.dart';
import 'package:invan2/features/authentication/model/model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/get_products/singletons/items_singleton.dart';
import 'package:invan2/features/get_products/soliq/tasnif_service.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import '../../../../app_navigation.dart';
import '../../../../features/get_categories/service/category_service.dart';
import '../../../../features/hive_repository/hive_boxes.dart';
import '../../../../utils/util_functions.dart';
import '../../../services/discount_service.dart';
import '../../../services/log_service.dart';
import '../../../services/measurement_unit.dart';
import '../../../services/var_unit.dart';
import '../../creat_product/model/mes_vat_unit_model/mes_unit.dart';

part 'upd_event.dart';

part 'upd_state.dart';

List<APDstatus> statuss = const [
  APDstatus.discounts,
  APDstatus.items,
  APDstatus.category,
  APDstatus.organization,
  APDstatus.employee,
  APDstatus.service,
];

class UpdBloc extends Bloc<UpdEvent, UpdState> {
  List<UpdFailedRepo> repos = List.generate(
    statuss.length,
    (i) => UpdFailedRepo(
      apdStatus: statuss[i],
      error: null,
      repoStatus: RepoStatus.inProgress,
    ),
  );

  UpdBloc() : super(UpdInitial()) {
    on<UpdInitialEvent>(_initial);
    on<UpdStartEvent>(_start);
    on<UpdShowErrorEvent>(_showError);
    on<UpdCallSomeFailedEvent>(_callSomeFailed);
  }

  _callSomeFailed(UpdCallSomeFailedEvent event, Emitter<UpdState> emit) {
    emit(UpdAllDoneSomeFailedState(repos));
  }

  _showError(UpdShowErrorEvent event, Emitter<UpdState> emit) {
    emit(UpdShowErrorState(event.repo));
  }

  _initial(UpdInitialEvent event, Emitter<UpdState> emit) {
    emit(UpdInitialState2(repos));
  }

  _start(UpdStartEvent event, Emitter<UpdState> emit) async {
    repos = List.generate(
      event.status.length,
      (i) => UpdFailedRepo(
        apdStatus: event.status[i],
        error: null,
        repoStatus: RepoStatus.inProgress,
      ),
    );

    if (event.isRetry) {
      for (int i = 0; i < repos.length; i++) {
        if (repos[i].repoStatus == RepoStatus.failed) {
          repos[i].repoStatus = RepoStatus.inProgress;
        }
      }
    }
    emit(UpdLoadingState(repos: repos));
    List<UpdFailedRepo> unsuccesess =
        repos.where((e) => e.repoStatus == RepoStatus.inProgress).toList();
    for (int i = 0; i < unsuccesess.length; i++) {
      switch (unsuccesess[i].apdStatus) {
        case APDstatus.organization:
          {
            String? v = await _organization(emit);
            List<UpdFailedRepo> r = _changeRepoStatus(i, v);
            emit(UpdLoadingState(repos: r));
          }
          break;

        case APDstatus.employee:
          {
            String? v = await _employee(emit);

            List<UpdFailedRepo> r = _changeRepoStatus(i, v);
            emit(UpdLoadingState(repos: r));
          }
          break;
        case APDstatus.category:
          {
            String? v = await _category(emit);
            List<UpdFailedRepo> r = _changeRepoStatus(i, v);
            emit(UpdLoadingState(repos: r));
          }
          break;
        case APDstatus.service:
          {
            String? v = await _service(emit);
            List<UpdFailedRepo> r = _changeRepoStatus(i, v);
            emit(UpdLoadingState(repos: r));
          }
          break;
        case APDstatus.items:
          {
            await Future.delayed(const Duration(seconds: 1));
            String? v = await _items(emit);

            List<UpdFailedRepo> r = _changeRepoStatus(i, v);
            emit(UpdLoadingState(repos: r));
          }
          break;
        case APDstatus.posDevice:
          {}
          break;
        case APDstatus.discounts:
          {
            String? v = await _discounts(emit);
            List<UpdFailedRepo> r = _changeRepoStatus(i, v);
            emit(UpdLoadingState(repos: r));
          }
          break;
      }
    }
    await Future.delayed(const Duration(seconds: 2));
    List<UpdFailedRepo> r = repos.where((e) => e.error != null).toList();
    if (r.isEmpty) {
      emit(UpdAllDoneState());
    } else {
      emit(UpdAllDoneSomeFailedState(repos));
    }
  }

  Future<String?> _service(Emitter<UpdState> emit) async {
    String? error;
    HttpResult httpResult =
        await ServiceGetApi.serviceGet(Pref.getString(PrefKeys.chequeId, ""));
    if (httpResult.isSuccess) {
      final recDesign = ServiceGetResponseData.fromJson(httpResult.result);
      if (recDesign.id != null) {
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
          } else {
            error = "Error";
          }
        } else {
          error = "Error";
        }
        await ServiceSingleton.setPrefs(recDesign);
      } else {
        error = "Error";
      }
    } else {
      error = httpResult.getError;
    }
    return error;
  }

  Future<String?> _employee(Emitter<UpdState> emit) async =>
      await UtilFunctions.fullUpdateEmployee();

  Future<String?> _organization(Emitter<UpdState> emit) async {
    String? error;
    HttpResult httpResult = await OrganizationService.getOrganization();
    if (httpResult.isSuccess) {
      OrganizationModel organizationModel =
          OrganizationModel.fromJson(httpResult.result);

      final address = organizationModel.legalAddress ?? '';
      String greeting = "";
      String companyName = organizationModel.name ?? "";
      bool companyActive = organizationModel.companyActive ?? false;
      bool autoGenerate = organizationModel.autoGenerate ?? false;
      String orgId = "";
      orgId = organizationModel.id ?? "";
      bool soliqValidation = organizationModel.soliqValidation ?? false;
      bool appsApp = organizationModel.appsApp ?? false;

      print('[UPD] RAW → apps_soliq_validation: ${httpResult.result['apps_soliq_validation']} | apps_soliq_app: ${httpResult.result['apps_soliq_app']}');
      print('[UPD] PARSED → apps_soliq_validation: $soliqValidation | apps_soliq_app: $appsApp | markCheckWithOfd will be: $appsApp');

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
      await Pref.setBool(PrefKeys.markCheckWithOfd, appsApp);

      HttpResult paymentRes = await OrganizationService.getPayments(
          Pref.getString(PrefKeys.activatedPosId, ""));
      if (paymentRes.isSuccess) {
        List<Payment> pList = List<Payment>.from(
          paymentRes.result['payment_types'].map(
            (e) => Payment.fromJson(e),
          ),
        );
        String cashBoxTitle = '';
        cashBoxTitle = json.decode(utf8.decode(paymentRes.reBytes))['title'];
        if (cashBoxTitle != "") {
          await Pref.setString(PrefKeys.posName, cashBoxTitle);
        }
        Pref.setString(PrefKeys.chequeId, paymentRes.result["cheque_id"]);
        OrganizationModel org = OrganizationModel.fromJson(httpResult.result);
        OrganizationSingleton.setOrgPrefs(org, pList);
      }

      HttpResult storeFields = await OrganizationService.getStoreFields(
          Pref.getString(PrefKeys.storeId, ""));
      if (storeFields.isSuccess) {
        StoresModel ss = StoresModel(
          id: storeFields.result["id"]!,
          name: storeFields.result["title"]!,
          address: storeFields.result["address"] ?? "",
          number: storeFields.result["phone_number"] ?? "",
        );
        await Pref.setString(PrefKeys.storeName, ss.name);
        await Pref.setString(PrefKeys.storeAddress, ss.address);
        await Pref.setString(PrefKeys.storePhoneNum, ss.number);
      }
    } else {
      error = httpResult.getError;
    }
    return error;
  }

  Future<String?> _category(Emitter<UpdState> emit) async {
    return await CategoryService.category();
  }

  Future<String?> _discounts(Emitter<UpdState> emit) async {
    return await DiscountService.discounts();
  }

  Future<String?> _items(Emitter<UpdState> emit) async {
    String? error;

    error = await UtilFunctions.fullUpdateProduct();

    if (error == null) {
      final bool isMarkingSyncEnabled = Pref.getBool('switchMarking', false);

      if (isMarkingSyncEnabled) {
        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult != ConnectivityResult.none) {
            final markingBox = HiveBoxes.markingProductsBox();
            if (markingBox.isEmpty) {
            } else {
              await OrdersService()
                  .updateMarkingStatusFromSoliq(fromLocal: true);
            }
          }
        } catch (e, stack) {
          print('[_items] marking sync xato: $e\n$stack');
        }
      }
    }

    final List<UpdFailedRepo> r = _changeRepoStatus(
      repos.indexWhere((e) => e.apdStatus == APDstatus.items),
      error,
    );
    emit(UpdLoadingState(repos: r));

    return error;
  }

  List<UpdFailedRepo> _changeRepoStatus(int i, String? error) {
    repos[i]
      ..repoStatus = (error == null ? RepoStatus.done : RepoStatus.failed)
      ..error = error;
    return repos;
  }
}

/*Future<String?> _items(Emitter<UpdState> emit) async {
    DateTime time = DateTime.now();
    List<ItemModel> allProducts = [];
    String getError = '';
    bool isLoaded = false;
    await TasnifService.setPackageCode();
    // while (!isLoaded) {
    HttpResult httpResult = await OrdersService.getItems();
    print(httpResult.isSuccess);
    if (httpResult.isSuccess) {
      List<ItemModel> i = List<ItemModel>.from(
        json.decode(httpResult.result)['data'].map((e) {
          return ItemModel.fromJson(e);
        }),
      ).toList();
      print(i.length);
      i = ItemsSingleton.addPackageCodeAndMxikCode(
        i,
        Pref.getString(PrefKeys.mxikCode, ''),
        Pref.getString(PrefKeys.packageCode, ''),
      );
      // if (i.length < 1000) {
      //   allProducts.addAll(i);
      //   isLoaded = true;
      //   break;
      // }
      allProducts.addAll(i);
    } else {
      getError = httpResult.getError;
    }
    // }
    print(allProducts.length);
    await Pref.setInt(PrefKeys.lastSyncTime, time.millisecondsSinceEpoch);
    if (allProducts.isNotEmpty) {
      await ItemsSingleton.clearAndPutItems(allProducts);
      await ItemsSingleton.storeProducts();
      CategorySingleton.init();
      await Pref.setInt(
          PrefKeys.lastSyncTime,
          DateTime.now()
              .subtract(const Duration(seconds: 3))
              .millisecondsSinceEpoch);
      return null;
    }
    return getError;
  }*/

/*
  Future<String?> _employee(Emitter<UpdState> emit) async {
    String? error;

    bool xreport = false;
    bool openShift = false;
    bool zreport = false;
    bool editPrice = false;
    bool creatNewCustomer = false;
    bool receiptHistory = false;
    bool delete = false;
    bool printReports = false;
    bool viewOnlyAllSale = false;
    bool stock = false;
    bool saleAsDebt = false;
    bool refund = false;
    bool applyManualDiscountsNewSale = false;
    bool viewOnlyNewSale = false;
    bool creatNewSale = false;
    bool deletePrice = false;

    HttpResult httpResult = await EmployeesApi.findEmployees();

    if (httpResult.isSuccess) {
      final box = HiveBoxes.getEmployees();
      await box.clear();
      final employeeList = List<Employee>.from(
        httpResult.result['employees'].map(
          (e) => Employee.fromJson(e),
        ),
      ).toList();
      Map<String, Employee> entries = {};
      for (var employe in employeeList) {
        entries[employe.key] = employe;
      }
      if (employeeList.isNotEmpty) await box.putAll(entries);
      for (var emps in box.values) {
        HttpResult empRoleResult =
            await EmployeesApi.getEmployeesRoles(emps.role?.id ?? "");
        if (empRoleResult.isSuccess) {
          List<RolePermissions> roleList = List<RolePermissions>.from(
            empRoleResult.result['modules'].map(
              (e) => RolePermissions.fromJson(e),
            ),
          );

          for (var rl in roleList) {
            if (rl.id == "ca19a21a-664d-4ed1-8a49-eb2a1db2a38f") {
              for (var sec in rl.sections ?? <SectionsModel>[]) {
                for (var permission
                    in sec.permissions ?? <PermissionsModel>[]) {
                  if (permission.id == "53c360f9-a10b-4f4b-8b52-670c3b8f87ca") {
                    //creatNew Sale
                    creatNewSale = permission.isAdded ?? false;
                  }
                  if (permission.id == "d45d234a-e2eb-4861-b825-37217f821142") {
                    //viewOnly newSale
                    viewOnlyNewSale = permission.isAdded ?? false;
                  }
                  if (permission.id == "888fde2d-812c-4e5e-9e51-601e367eecbf") {
                    //applyManualDiscountsNewSale
                    applyManualDiscountsNewSale = permission.isAdded ?? false;
                  }
                  if (permission.id == "e84a7e7d-2c6e-441f-82b7-1eeaf3a361fe") {
                    //refund
                    refund = permission.isAdded ?? false;
                  }

                  if (permission.id == "f89ca40a-f2f9-4745-bebc-9cf293521c95") {
                    //saleAsDebt
                    creatNewSale = permission.isAdded ?? false;
                  }
                  if (permission.id == "49f674fc-efbf-42fc-bb7c-2904c9c15a07") {
                    //stock
                    stock = permission.isAdded ?? false;
                  }
                  if (permission.id == "8f5f5316-becc-44b9-9c50-ed91ef430733") {
                    //viewOnlyAllSale
                    viewOnlyAllSale = permission.isAdded ?? false;
                  }

                  if (permission.id == "4d8c05a0-fa2b-468a-9c87-f5adc07cee23") {
                    //printReports
                    printReports = permission.isAdded ?? false;
                  }

                  if (permission.id == "25ae23a7-d395-4f99-afb4-4fcec02ed1b6") {
                    //delete
                    delete = permission.isAdded ?? false;
                  }

                  if (permission.id == "d24b0e6c-cc77-4e5b-935b-25a65a98f720") {
                    //receipt history
                    receiptHistory = permission.isAdded ?? false;
                  }

                  if (permission.id == "6f79f732-777c-4c76-98d9-d519ebf7ec78") {
                    //creatNewCustomer
                    creatNewCustomer = permission.isAdded ?? false;
                  }

                  if (permission.id == "1a9b575b-31f5-47b7-9056-8875889921cd") {
                    //openShift
                    openShift = permission.isAdded ?? false;
                  }

                  if (permission.id == "e7ffe144-757b-420e-b57d-4f04095b97e9") {
                    //xreport
                    xreport = permission.isAdded ?? false;
                  }
                  if (permission.id == "2b641aa6-26b1-4d5b-9fc4-f5538338aec2") {
                    //zreport
                    zreport = permission.isAdded ?? false;
                  }
                  if (permission.id == "615e159d-4a69-489f-87d5-abb32489fdd5") {
                    //edit price
                    editPrice = permission.isAdded ?? false;
                  }
                  if (permission.id == "02766f7d-49e9-4353-aef6-e5a5d53f3e88") {
                    //delete price
                    deletePrice = permission.isAdded ?? false;
                  }
                }
              }
            }
          }
        }
        Employee setedEmployee = Employee(
          access: EmployeeAccess(
            applyManualDiscountsNewSale: applyManualDiscountsNewSale,
            creatNewCustomer: creatNewCustomer,
            creatNewSale: creatNewSale,
            deleteS: delete,
            openShift: openShift,
            printReports: printReports,
            receiptHistory: receiptHistory,
            refund: refund,
            saleAsDebt: saleAsDebt,
            stock: stock,
            viewOnlyAllSale: viewOnlyAllSale,
            viewOnlyNewSale: viewOnlyNewSale,
            xreport: xreport,
            zreport: zreport,
            editPrice: editPrice,
            deletePrice: deletePrice,
          ),
          role: emps.role,
          user: emps.user,
        );
        box.put(emps.user?.id, setedEmployee);
      }
    } else {
      error = httpResult.getError;
    }
    return error;
  }*/
