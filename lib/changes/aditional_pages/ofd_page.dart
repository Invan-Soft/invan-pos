import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/bloc/network/network_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/features/home_products/shift_opened/bottom_layer_of_home_page.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';
import 'package:invan2/features/report/features/report_app_bar/report_app_bar.dart';
import 'package:windows1251/windows1251.dart';

import '../../features/settings/view/report_setting/report_item.dart';
import '../../fiscal_service/fisal_receipt_service.dart';
import '../../fiscal_service/fiscal_app_strings.dart';
import '../../fiscal_service/model/fiscal_data_model.dart';
import '../../fiscal_service/model/info_service.dart';
import '../../fiscal_service/post_methods.dart';
import '../../utils/utils.dart';
import '../../widgets/alice_pincode.dart';
import '../../widgets/my_snackbar.dart';
import '../models/log/loc_res_model.dart';
import '../models/ofd/epos_response_model.dart';
import '../repository/log_repository.dart';
import '../services/api_state.dart';
import '../services/local_selling_service.dart';

class OfdPage extends StatefulWidget {
  const OfdPage({super.key});

  @override
  OfdPageState createState() => OfdPageState();
}

class OfdPageState extends State<OfdPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late NetworkBloc networkBloc;

  final List<String> items = const [
    "Open Z-report",
    "Close Z-report",
    "Sale",
    "Get receipts count",
    "Send Receipt",
    "GetUnsentsCount",
    "ResendUnsent",
  ];

  String response = '';
  String resInInts = "";
  bool isWaiting = false;

  @override
  void initState() {
    networkBloc = BlocProvider.of(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AppLocalizations loc = AppLocalizations.of(context)!;
    final AccessBloc lockBloc = BlocProvider.of(context, listen: false);
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
        floatingActionButton: Pref.getBool(PrefKeys.isDevAlice, false)
            ? FloatingActionButton(
                heroTag: null,
                backgroundColor: Theme.of(context).primaryColor,
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlicePincodePage(),
                  );
                },
                child: const Icon(
                  Icons.http_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              )
            : const SizedBox(),
        backgroundColor: Theme.of(context).colorScheme.background,
        key: _scaffoldKey,
        endDrawer: MyDrawer(scaffoldKey: _scaffoldKey),
        body: Column(
          children: [
            ReportAppBarr(
              scaffoldKey: _scaffoldKey,
              pressLockButton: () {
                lockBloc.add(AccessSwitchToAccessEvent());
                AppNavigation.pushAndRemoveUntil(const AccessLevelPage());
              },
            ),
            BlocListener<NetworkBloc, NetworkState>(
              listener: (context, state) async {
                if (state is NetworkFailure) {
                  await Future.delayed(const Duration(seconds: 1));
                  networkBloc.add(NetworkNoEvent());
                }
              },
              child: Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: SizeConfig.h * 5,
                      right: SizeConfig.h * 5,
                      top: SizeConfig.v,
                    ),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        items.length,
                        (__) => SettingsReportPageButton(
                          onPressed: () async {
                            switch (__) {
                              case 0:
                                {
                                  isWaiting = true;
                                  setState(() {});
                                  var fiscalData =
                                      await PostMethods.openZReport();
                                  LocalResModel result =
                                      LocalResModel.fromJson(fiscalData);

                                  // response = result.message!;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(mySnackBar(
                                    context,
                                    duration: 1000,
                                    msg: result.message ?? "...",
                                  ));

                                  resInInts = response.codeUnits.toString();

                                  response = windows1251.inverted
                                      .encode(response.codeUnits);

                                  isWaiting = false;

                                  if (result.error!) {
                                    LogRepository.addLog(
                                      "${result.message!} ",
                                      file: "MANUAL REPORT",
                                      where: "MANUAL REPORT / $__",
                                      method: "OPEN ZET REPORT",
                                    );
                                  }
                                  setState(() {});
                                }
                                break;
                              case 1:
                                {
                                  isWaiting = true;
                                  setState(() {});

                                  var dataresult =
                                      await PostMethods.closeZReport();
                                  LocalResModel result =
                                      LocalResModel.fromJson(dataresult);

                                  // response = result.message!;
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(mySnackBar(
                                    context,
                                    duration: 1000,
                                    msg: result.message ?? "...",
                                  ));
                                  resInInts = response.codeUnits.toString();

                                  response = windows1251.inverted
                                      .encode(response.codeUnits);
                                  if (result.error!) {
                                    LogRepository.addLog(
                                      "${result.message!} //\\ $resInInts",
                                      file: "MANUAL REPORT",
                                      where: "MANUAL REPORT / $__",
                                      method: "CLOSE ZET REPORT",
                                    );
                                  }
                                  isWaiting = false;
                                  setState(() {});
                                }
                                break;
                              case 2:
                                {
                                  isWaiting = true;
                                  setState(() {});
                                  CommunicatorRESPONSE result =
                                      await LocalService.sell(
                                    loc: loc,
                                    receiptData: _receipt(),
                                  );
                                  // response =
                                  //     result.error! ? "ERROR" : "SUCCESS ";

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(mySnackBar(
                                    context,
                                    duration: 1000,
                                    msg: response =
                                        result.error! ? "ERROR" : "SUCCESS ",
                                  ));
                                  resInInts =
                                      result.paycheck!.codeUnits.toString();
                                  response = windows1251.inverted
                                      .encode(response.codeUnits);
                                  if (result.error!) {
                                    LogRepository.addLog(
                                      "${result.paycheck!} //\\ $resInInts",
                                      file: "MANUAL REPORT",
                                      where: "MANUAL REPORT / $__",
                                      method: "SALE",
                                    );
                                  }
                                  isWaiting = false;
                                  setState(() {});
                                }
                                break;
                              case 3:
                                {
                                  isWaiting = true;
                                  setState(() {});

                                  ApiState state =
                                      await ReceiptService.getReceiptCount();
                                  if (state is Success) {
                                    FiscalDataModel dataModel = FiscalDataModel(
                                      "Количество",
                                      state.decodeResult()['Count'].toString(),
                                    );

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(mySnackBar(
                                      context,
                                      duration: 1000,
                                      msg: dataModel.data,
                                    ));
                                  }

                                  if (state is Failure) {
                                    String message = state.code == 200
                                        ? state.errorMessage()
                                        : state.response.toString();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(mySnackBar(
                                      context,
                                      duration: 1000,
                                      msg: message,
                                    ));
                                  }

                                  isWaiting = false;
                                  setState(() {});
                                }
                                break;
                              case 4:
                                {
                                  isWaiting = true;
                                  setState(() {});
                                  ApiState state =
                                      await ReceiptService.sendReceipt();

                                  if (state is Success) {
                                    var decoded =
                                        jsonDecode(state.response.toString());
                                    FiscalDataModel dataModel = FiscalDataModel(
                                        'QueuedToSendCount',
                                        decoded['result']['QueuedToSendCount']
                                            .toString());

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(mySnackBar(
                                      context,
                                      duration: 1000,
                                      msg: "Отправка чеков: ${dataModel.data}",
                                    ));
                                  }

                                  if (state is Failure) {
                                    String message = state.code == 200
                                        ? state.errorMessage()
                                        : state.response.toString();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(mySnackBar(
                                      context,
                                      duration: 1000,
                                      msg: message,
                                    ));
                                  }

                                  isWaiting = false;
                                  setState(() {});
                                }

                                break;
                              case 5:
                                {
                                  isWaiting = true;
                                  setState(() {});
                                  ApiState localState =
                                      await InfoService.getUnsentCount();

                                  if (localState is Success) {
                                    FiscalDataModel dataModel = FiscalDataModel(
                                      AppStrings.countOfunsentZReports,
                                      localState
                                          .decodedData()['Count']
                                          .toString(),
                                    );

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(mySnackBar(
                                      context,
                                      duration: 1000,
                                      msg:
                                          "${AppStrings.countOfunsentZReports}: ${dataModel.data}",
                                    ));
                                  }

                                  if (localState is Failure) {
                                    String message = localState.code == 200
                                        ? localState.errorMessage()
                                        : localState.response.toString();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(mySnackBar(
                                      context,
                                      duration: 1000,
                                      msg: message,
                                    ));
                                  }

                                  isWaiting = false;
                                  setState(() {});
                                }

                                break;
                              case 6:
                                {
                                  isWaiting = true;
                                  setState(() {});
                                  ApiState localState =
                                      await InfoService.resendUnsent();

                                  if (localState is Success) {
                                    FiscalDataModel dataModel = FiscalDataModel(
                                      AppStrings.countOfunsentZReports,
                                      localState
                                          .decodedData()['result']
                                          .toString(),
                                    );

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(mySnackBar(
                                      context,
                                      duration: 1000,
                                      msg:
                                          "${AppStrings.countOfunsentZReports}: ${dataModel.data}",
                                    ));
                                  }

                                  if (localState is Failure) {
                                    String message = localState.code == 200
                                        ? localState.errorMessage()
                                        : localState.response.toString();
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(mySnackBar(
                                      context,
                                      duration: 1000,
                                      msg: message,
                                    ));
                                  }

                                  isWaiting = false;
                                  setState(() {});
                                }

                                break;
                              default:
                            }
                          },
                          title: items[__],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(
                      -1,
                      -2,
                    ),
                    blurRadius: .1,
                    color: Theme.of(context).colorScheme.background,
                  ),
                ],
              ),
              child: const BottomLayerOfHomePage(),
            ),
          ],
        ),
      ),
    );
  }

  Map _receipt() {
    Log.d('data', name: 'settings_reports_page');
    String companyName =
        Pref.getString(PrefKeys.organizationName, "not initialized");
    String address = Pref.getString(PrefKeys.serviceAddress, "not initialized");
    String inn = Pref.getString(PrefKeys.organizationINN, "not initialized");
    String staff = Pref.getString(PrefKeys.cashierName, "not initialized");
    String terId = Pref.getString(PrefKeys.terminalID, '');

    var v = {
      "token": "DXJFX32CN1296678504F2",
      "method": 'sale',
      "companyName": companyName,
      "companyAddress": address,
      "companyINN": inn,
      "staffName": staff,
      "printerSize": 80,
      "otherInfo": {
        "terminalID": terId,
      },
      "params": {
        "paycheckNumber": "test",
        "externalInfo": {
          "qrPaymentProvider": Pref.getInt('epayPay_Id', 0).toString(),
          "qrPaymentID": Pref.getString('epay_Id', "").toString(),
          "phoneNumber": Pref.getString('epay_phone', "").toString(),
        },
        "items": [
          {
            "discount": 0,
            "price": 10000,
            "barcode": "98743154313",
            "amount": 1000,
            "vatPercent": 15,
            "vat": 1304,
            "name": "Gugurt",
            "classCode": "03605001001000000",
            "other": 0,
            "label": ""
          }
        ],
        "receivedCash": 10000,
        "receivedCard": 0,
        "receivedClick": false,
        "receivedUzum": false,
        "receivedPayme": false,
      }
    };
    return v;
  }
}
