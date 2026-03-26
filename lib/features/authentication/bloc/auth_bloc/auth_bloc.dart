import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/auth_api.dart';
import 'package:invan2/features/authentication/model/model.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import '../../../../changes/services/company_app_service.dart';
import '../../../../changes/services/get_available_pos_api.dart';
import '../../../../utils/l10n/app_localizations.dart';

part 'auth_event.dart';

part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc()
      : super(AuthInitialState(
          enabled: false,
          isSms: false,
          restart: true,
        )) {
    on<AuthTypePhoneNumberEvent>(_typingPhoneNumber);
    on<AuthTypeSMScodeEvent>(_typeSmsCode);
    on<AuthOnSubmittedPhoneNumberEvent>(_submitPhone);
    on<AuthInitialEvent>(_initial);
    on<AuthSmsIncorrectEvent>(_smsIncorrect);
  }

  _smsIncorrect(AuthSmsIncorrectEvent event, Emitter<AuthState> emit) {
    emit(AuthInitialState(
      smsRestart: true,
      enabled: false,
      isSms: true,
      restart: false,
    ));
  }

  _initial(AuthInitialEvent event, Emitter<AuthState> emit) {
    emit(
      AuthInitialState(
        enabled: true,
        isSms: false,
        restart: true,
      ),
    );
  }

  // _submitSms(AuthOnSubmittedSmsCodeEvent event, Emitter<AuthState> emit) async {
  //   List<StoresModel> stores = [];
  //   String token = '';
  //   emit(AuthLoadingState(event.loc.malumotlar_tekshirilmoqda));
  //   String smsCode = event.str.replaceAll("-", "");
  //   String phoneNumber = '+998${event.phone.replaceAll(RegExp('[^0-9]'), "")}';
  //   final HttpResult httpResult =
  //       await AuthenticationApi.sendVerificationCodee(phoneNumber, smsCode);
  //   if (httpResult.isSuccess) {
  //     LoginVerifyResponseData data =
  //         LoginVerifyResponseData.fromJson(httpResult.result["data"]);
  //     String serialNumber = 'SN${DateTime.now().millisecondsSinceEpoch}';
  //     Pref.setString(PrefKeys.serialNumber, serialNumber);

  //     List<LoginVerifyResponseServices> services = data.services!;
  //     for (int i = 0; i < services.length; i++) {
  //       if (services[i].available!) {
  //         stores.add(StoresModel(
  //             id: services[i].service!,
  //             name: services[i].serviceName!,
  //             available: services[i].available!));
  //       }
  //     }
  //     token = data.token!;
  //     await Pref.setString(PrefKeys.cashierName, data.name!);
  //     await Pref.setString(PrefKeys.cashierId, data.sId!);

  //     if (stores.isNotEmpty) {
  //       AppNavigation.pushReplacement(
  //         ChooseStorePage(
  //           token: token,
  //           stores: stores,
  //         ),
  //       );
  //       emit(AuthInitialState(
  //         enabled: false,
  //         isSms: false,
  //         restart: true,
  //       ));
  //     } else {
  //       emit(AuthVerifyFailedState(error: "empty", phone: event.phone));
  //     }
  //   } else {
  //     stores = [];
  //     token = '';
  //     emit(AuthVerifyFailedState(
  //         error: httpResult.getError, phone: event.phone));
  //   }
  // }

  _submitPhone(
      AuthOnSubmittedPhoneNumberEvent event, Emitter<AuthState> emit) async {
    String v = event.str.replaceAll(RegExp('[^0-9]'), "");
    if (v.length == 9 && event.pass != "") {
      emit(AuthLoadingState(event.loc.tasdiqlash_kodi_jonatilmoqda));
      String phoneNumber = '+998$v';
      await Pref.setBool(PrefKeys.orgINITIALIZED, false);
      HttpResult httpResult =
          await AuthenticationApi.sendPhoneNumber(phoneNumber, event.pass);
      if (httpResult.isSuccess) {
        String token = '';
        token = httpResult.result['token'];
        List<StoresModel> stores = [];
        HttpResult httpShopResult = await AuthenticationApi.getShop(token);
        bool alreadyFetched = Pref.getBool(PrefKeys.companyAppsFetched, false);

        if (!alreadyFetched) {
          HttpResult companyAppsResult =
              await CompanyAppsService.getCompanyApps(token);

          if (companyAppsResult.statusCode == 200) {
            final data = companyAppsResult.result;
            bool withOFD = false;

            if (data != null && data['apps_soliq_app'] != null) {
              withOFD = data['apps_soliq_app'] == true;
            }

            await Pref.setBool(PrefKeys.withOFD, withOFD);
            await Pref.setBool(PrefKeys.companyAppsFetched, true);

          }
        }
        List<LoginVerifyResponseServices> services =
            List<LoginVerifyResponseServices>.from(httpShopResult.result["data"]
                .map((e) => LoginVerifyResponseServices.fromJson(e)));
        String serialNumber = 'SN${DateTime.now().millisecondsSinceEpoch}';
        Pref.setString(PrefKeys.serialNumber, serialNumber);
        for (int i = 0; i < services.length; i++) {
          stores.add(StoresModel(
            id: services[i].id!,
            name: services[i].title!,
            address: services[i].address ?? "",
            number: services[i].number ?? "",
          ));
        }

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
        if (stores.length == 1) {
          List<GetAvailablePosResponseData> allPosList =
              <GetAvailablePosResponseData>[];
          List<GetAvailablePosResponseData> availablePosList =
              <GetAvailablePosResponseData>[];
          HttpResult posResult =
              await GetAvailablePosApi.getAvailablePoss(token: token);
          if (httpResult.isSuccess) {
            dynamic i = jsonDecode(utf8.decode(posResult.reBytes))["data"];
            for (dynamic d in i) {
              if (d['shop']['id'] == stores.first.id) {
                allPosList.add(GetAvailablePosResponseData.fromJson(d));
              }
            }
            // allPosList = List<GetAvailablePosResponseData>.from(
            //   jsonDecode(utf8.decode(posResult.reBytes))["data"].map(
            //     (x) {
            //       if (x['shop']['id'] == stores.first.id) {
            //         return GetAvailablePosResponseData.fromJson(x);
            //       }
            //     },
            //   ),
            // ).toList();
            for (var p in allPosList) {
              if (p.isActive == false) {
                availablePosList.add(p);
              }
            }
          }
          AppNavigation.pushReplacement(
            ActivatePosPage(
              token: token,
              availablePosList: availablePosList,
              selectedStore: stores.first,
              macAddress: "",
            ),
          );
        } else {
          ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
          AppNavigation.pushReplacement(
            ChooseStorePage(
              token: token,
              stores: stores,
            ),
          );
        }

        emit(AuthInitialState(
          enabled: false,
          isSms: true,
          restart: false,
        ));
      } else {
        emit(
          AuthLoadingFailedState(
            message:
                "${event.loc.raqam_jonatishda_hatolik} ${httpResult.getError}",
          ),
        );
      }
    }
  }

  _typeSmsCode(AuthTypeSMScodeEvent event, Emitter<AuthState> emit) {
    String smsCode = event.str.replaceAll("-", "");
    if (smsCode.length == 4) {
      emit(AuthInitialState(
        enabled: true,
        isSms: true,
        restart: false,
      ));
    }
  }

  _typingPhoneNumber(
      AuthTypePhoneNumberEvent event, Emitter<AuthState> emit) async {
    String phoneNumber = event.str.replaceAll(RegExp('[^0-9]'), "");

    if (phoneNumber.length == 9) {
      emit(
        AuthInitialState(
          enabled: true,
          isSms: false,
          restart: false,
        ),
      );
    }
  }
}
