// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/settings/bloc/settings_bloc.dart';
import 'package:invan2/features/settings/features/child_settings/view/switch_in_report_page.dart';
import 'package:invan2/features/settings/view/report_setting/qr_code_dialog/qrcode_dialog.dart';
import 'package:invan2/features/settings/view/report_setting/terminal_id_dialog.dart/terminal_id.dart';
import 'package:invan2/utils/util_functions.dart';
import 'package:invan2/utils/utils.dart';
import '../../../../widgets/my_snackbar.dart';
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
  late bool checkProductByCashsale;

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
    validation_onkm = Pref.getBool('validation_onkm', true);
    sellProductsWithMarking = Pref.getBool(PrefKeys.sellProductsWithMarking, true);
    transfer = Pref.getBool(PrefKeys.transfer, false);
    preCheck = Pref.getBool(PrefKeys.preCheck, false);
    ofd = Pref.getBool(PrefKeys.withOFD, false);

    switchMarking = Pref.getBool('switchMarking', false);
    checkProductByCashsale = Pref.getBool('checkProductByCashsale', true);

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
                title: loc.ha == 'Ha' ? "OFD modulini yoqish" : "Включить модуль OFD",
                activ: ofd,
              ),
              Pref.getBool(PrefKeys.withOFD, false)
                  ? SwitchTileOfReportPage(
                      onChanged: (v) {
                        Pref.setBool(PrefKeys.preCheck, v);
                        setState(() {});
                      },
                      onTap: () {},
                      title: loc.ha == 'Ha' ? "Soliqsiz sotish" : "Продажа без налога",
                      activ: preCheck,
                    )
                  : const SizedBox.shrink(),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool(PrefKeys.transfer, v);
                  setState(() {});
                },
                onTap: () {},
                title: loc.ha == 'Ha' ? "Buyurtmani kassaga o'tkazish" : "Перевод заказа на кассу",
                activ: transfer,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool(PrefKeys.isRedDeleteActivated, v);
                  setState(() {});
                },
                onTap: () {},
                title: loc.ha == 'Ha' ? "O'chirishni qizil ko'rsatish" : "Показывать удаление красным",
                activ: isRedDeleteActiv,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool('switchClients', v);
                  setState(() {});
                },
                onTap: () {},
                title: loc.ha == 'Ha' ? "Mijozni raqami bo'yicha qidirish" : "Поиск клиента по номеру",
                activ: switchClient,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool('switchProductName', v);
                  setState(() {});
                },
                onTap: () {},
                title: loc.ha == 'Ha' ? "Mahsulotni nomi bo'yicha qidirish" : "Поиск товара по названию",
                activ: switchProductName,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool(PrefKeys.sellProductsWithMarking, v);
                  Provider.of<OrderingProvider4>(context, listen: false)
                      .resetCashRestrictionWarnings();
                  setState(() {});
                },
                onTap: () {},
                title: loc.ha == 'Ha' ? "Avto markirovkani aniqlash" : "Автоматическое определение маркировки",
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
                title: loc.ha == 'Ha' ? "ONKM kodi tekshiruvi" : "Проверка кода ОНКМ",
                activ: validation_onkm,
              ),
              SwitchTileOfReportPage(
                onChanged: (v) {
                  Pref.setBool('checkProductByCashsale', v);
                  Provider.of<OrderingProvider4>(context, listen: false)
                      .resetCashRestrictionWarnings();
                  setState(() {});
                },
                onTap: () {},
                title: loc.ha == 'Ha' ? "Mahsulotning naqd to'lov cheklovini tekshirish" : "Проверка ограничения наличной оплаты товара",
                activ: checkProductByCashsale,
              ),

              !Pref.getBool(PrefKeys.withOFD, false)
                  ? setQrCode(loc.ha == 'Ha' ? "QR kod uchun URL manzilini kiriting" : "Введите URL адрес для QR кода", () {
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

              setQrCode(loc.ha == 'Ha' ? "Terminal ID sini kiriting" : "Введите ID терминала", () {
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
                loc.ha == 'Ha' ? "Do'kon joylashuvini kiriting" : "Введите местоположение магазина",
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
                loc.ha == 'Ha' ? "Rad etilgan cheklarni tahrirlash" : "Редактировать отклонённые чеки",
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

              Padding(
                padding: EdgeInsets.symmetric(vertical: SizeConfig.v * 2),
                child: Text(
                  response,
                  textAlign: TextAlign.center,
                  style: MyThemes.txtStyle(color: Colors.white, fontSize: 3),
                ),
              ),
            ],
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
