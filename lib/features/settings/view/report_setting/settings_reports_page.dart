// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/changes/services/get_items_service.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/settings/bloc/settings_bloc.dart';
import 'package:invan2/features/settings/features/child_settings/view/switch_in_report_page.dart';
import 'package:invan2/features/settings/view/report_setting/qr_code_dialog/qrcode_dialog.dart';
import 'package:invan2/features/settings/view/report_setting/terminal_id_dialog.dart/terminal_id.dart';
import 'package:invan2/utils/util_functions.dart';

import 'package:invan2/utils/utils.dart';
import '../../../../widgets/my_snackbar.dart';
import '../components/marking_sync_dialog.dart';
import 'location_dialog/location_dialog.dart';
import 'rejected_receipts_dialog/rejected_receipts.dart';

class SettingsReportPage extends StatefulWidget {
  const SettingsReportPage({super.key});

  @override
  State<SettingsReportPage> createState() => _SettingsReportPageState();
}

class _SettingsReportPageState extends State<SettingsReportPage> {
  final List<String> items = const [
    "Open Z-report",
    "Close Z-report",
    "Sale",
    "Get receipts count",
    "Send Receipt",
    "GetUnsentsCount",
    "ResendUnsent",
  ];

  late bool successTooTelegram;
  late bool isRedDeleteActiv;
  late bool active;
  late bool switchClient;
  late bool switchProductName;
  late bool transfer;
  late bool preCheck;
  late bool ofd;
  late bool validation_onkm;
  late bool sellProductsWithMarking;

  late bool switchMarking;

  String casshierId = Pref.getString(PrefKeys.cashierId, "not initialized");
  String casshierName = Pref.getString(PrefKeys.cashierName, "not initialized");
  String posName = Pref.getString(PrefKeys.posName, "not initialized");

  String response = '';
  String resInInts = "";
  bool isWaiting = false;

  @override
  Widget build(BuildContext context) {
    successTooTelegram = Pref.getBool(PrefKeys.isSendToTelegram, true);
    isRedDeleteActiv = Pref.getBool(PrefKeys.isRedDeleteActivated, false);
    switchClient = Pref.getBool('switchClients', true);
    switchProductName = Pref.getBool('switchProductName', true);
    validation_onkm = Pref.getBool('validation_onkm', false);
    sellProductsWithMarking = Pref.getBool(PrefKeys.sellProductsWithMarking, true);
    transfer = Pref.getBool(PrefKeys.transfer, false);
    preCheck = Pref.getBool(PrefKeys.preCheck, false);
    ofd = Pref.getBool(PrefKeys.withOFD, false);

    switchMarking = Pref.getBool('switchMarking', false);

    AppLocalizations loc = AppLocalizations.of(context)!;
    SettingsBloc settingsBloc = BlocProvider.of(context);
    String? markingLastUpdated = Pref.getString('markingLastUpdated', '');
    final String? markingSubtitle =
        (markingLastUpdated != null && markingLastUpdated.isNotEmpty)
            ? (loc.ha.toLowerCase() == 'ha'
                ? "Oxirgi yangilanish: $markingLastUpdated"
                : "Последнее обновление: $markingLastUpdated")
            : null;
    return Stack(children: [
      SingleChildScrollView(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 1.3,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.only(left: SizeConfig.h * 2.5),
                alignment: Alignment.centerLeft,
                height: SizeConfig.h * 6,
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back,
                    size: SizeConfig.v * 4,
                  ),
                  onPressed: () =>
                      settingsBloc.add(SettingsLeftItemPressedEvent(1)),
                ),
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool(PrefKeys.isSendToTelegram, v);
                  setState(() {});
                },
                onTap: () {},
                title: loc.send_telegram,
                activ: successTooTelegram,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool(PrefKeys.withOFD, v);
                  setState(() {});
                },
                onTap: () {},
                title: "Enable OFD",
                activ: ofd,
              ),
              Pref.getBool(PrefKeys.withOFD, false)
                  ? SwitchTileOfReportPage(
                      onChanged: (v) {
                        Pref.setBool(PrefKeys.preCheck, v);
                        setState(() {});
                      },
                      onTap: () {},
                      title: "Enable or disable pre-check",
                      activ: preCheck,
                    )
                  : const SizedBox.shrink(),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool(PrefKeys.transfer, v);
                  setState(() {});
                },
                onTap: () {},
                title: "Enable or disable transfer order",
                activ: transfer,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool(PrefKeys.isRedDeleteActivated, v);
                  setState(() {});
                },
                onTap: () {},
                title: "Red delete",
                activ: isRedDeleteActiv,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool('switchClients', v);
                  setState(() {});
                },
                onTap: () {},
                title: "Access search by client number",
                activ: switchClient,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool('switchProductName', v);
                  setState(() {});
                },
                onTap: () {},
                title: "Access search by product name",
                activ: switchProductName,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool(PrefKeys.sellProductsWithMarking, v);
                  setState(() {});
                },
                onTap: () {},
                title: "Sell Products With marking",
                activ: sellProductsWithMarking,
              ),
              // SwitchTileOfReportPage(
              //   subtitle: markingSubtitle,
              //   onChanged: (v) async {
              //     Pref.setBool('switchMarking', v);
              //     setState(() {});

              //     if (v) {
              //       final result = await showDialog<bool>(
              //         context: context,
              //         barrierDismissible: false,
              //         builder: (_) => MarkingSyncDialog(
              //           onFetch: () => OrdersService.getAllMxikItemsWithHistory(),

              //           onCompare: () async {
              //             await OrdersService().updateMarkingStatusFromSoliq(fromLocal: true);

              //             final now = DateTime.now();
              //             final formatted =
              //                 "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year} "
              //                 "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
              //             Pref.setString('markingLastUpdated', formatted);
              //           },
              //         ),
              //       );

              //       if (result != true) {
              //         Pref.setBool('switchMarking', false);
              //       }
              //       setState(() {});
              //     }
              //   },
              //   onTap: () {},
              //   title: loc.ha.toLowerCase() == 'ha'
              //       ? "Soliqdan mahsulot markinglarini olish"
              //       : "Синхронизация маркировки товаров из Солика",
              //   activ: switchMarking,
              // ),

              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool('validation_onkm', v);
                  setState(() {});
                },
                onTap: () {},
                title: "Validation Onkm",
                activ: validation_onkm,
              ),

              !Pref.getBool(PrefKeys.withOFD, false)
                  ? setQrCode("Enter url for qr code", () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: MaterialLocalizations.of(context)
                            .modalBarrierDismissLabel,
                        barrierColor: Colors.transparent,
                        builder: (_) {
                          return const AlertDialog(
                              alignment: Alignment.topRight,
                              backgroundColor: Colors.transparent,
                              content: QRCodeDialog());
                        },
                      );
                    })
                  : const Text(''),

              setQrCode("Enter Terminal ID", () {
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  barrierLabel: MaterialLocalizations.of(context)
                      .modalBarrierDismissLabel,
                  barrierColor: Colors.transparent,
                  builder: (_) {
                    return const AlertDialog(
                        alignment: Alignment.topRight,
                        backgroundColor: Colors.transparent,
                        content: TerminalIDDialog());
                  },
                );
              }),
              setQrCode(
                "Enter store location",
                () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: MaterialLocalizations.of(context)
                        .modalBarrierDismissLabel,
                    barrierColor: Colors.transparent,
                    builder: (_) {
                      return const AlertDialog(
                          alignment: Alignment.center,
                          backgroundColor: Colors.transparent,
                          content: LocationEditHandleDialog());
                    },
                  );
                },
              ),
              setQrCode(
                "Edit rejected receipts",
                () {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    barrierLabel: MaterialLocalizations.of(context)
                        .modalBarrierDismissLabel,
                    barrierColor: Colors.transparent,
                    builder: (_) {
                      return const AlertDialog(
                          alignment: Alignment.center,
                          backgroundColor: Colors.transparent,
                          content: EditRejectedReceiptsDialog());
                    },
                  );
                },
              ),
              setQrCode(
                loc.ha.toLowerCase() == 'ha'
                    ? 'Shtrix M-ni yangilash'
                    : 'Обновление штрихкода M',
                () async {
                  setState(() {
                    isWaiting = true;
                  });

                  bool isDownloaded = await UtilFunctions.downloadShtrixM();

                  ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
                    context,
                    duration: 1500,
                    msg: !isDownloaded ? "ERROR" : "SUCCESS ",
                  ));

                  setState(() {
                    isWaiting = false;
                  });
                },
              ),
              // const DropdownOfAutoSync(),

              SizedBox(
                height: SizeConfig.v * 3,
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    response,
                    textAlign: TextAlign.center,
                    style: MyThemes.txtStyle(color: Colors.white, fontSize: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      isWaiting
          ? Positioned.fill(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    SizeConfig.v * 1.1,
                  ),
                  color: Theme.of(context).primaryColor.withOpacity(.4),
                ),
                child: Center(
                  child: SpinKitCircle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            )
          : const Positioned(
              top: 0,
              left: 0,
              child: SizedBox(
                height: 0,
                width: 0,
              ),
            )
    ]);
  }

  Widget setQrCode(String title, VoidCallback ontap) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 3.5),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: SizeConfig.h * .5,
              vertical: SizeConfig.v * 1.5,
            ),
            onTap: ontap,
            title: Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
              child: Text(
                title,
                style: MyThemes.txtStyle(
                    fontSize: 2.7, color: Theme.of(context).canvasColor),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: Theme.of(context).dividerColor,
          ),
        ],
      ),
    );
  }
}
