import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/features/authentication/authentication.dart';
import 'package:invan2/features/authentication/bloc/bloc_activate_pos/apd_bloc_bloc.dart';
import 'package:invan2/features/authentication/bloc/bloc_activate_pos/components/initial_activate_pos_card_widget.dart';
import 'package:invan2/features/authentication/view/apd_loading_for_products.dart';
import 'package:invan2/features/drawer/my_drawer.dart';
import 'package:invan2/features/lock/access_level/view/access_level_page.dart';
import 'package:invan2/idle_service.dart';
import 'package:invan2/widgets/apd_text_widget.dart';
import 'package:invan2/widgets/widgets.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:invan2/utils/utils.dart';

import '../../../changes/services/web_socket_service/web_socket_options/ws_service.dart';
import '../../../utils/l10n/app_localizations.dart';

// ignore: must_be_immutable
class ActivatePosCardBloc extends StatefulWidget {
  final String acceptService;
  final String token;
  final String macAddress;

  ActivatePosCardBloc({
    required this.acceptService,
    required this.macAddress,
    required this.token,
    super.key,
  });

  @override
  State<ActivatePosCardBloc> createState() => _ActivatePosCardBlocState();
}

class _ActivatePosCardBlocState extends State<ActivatePosCardBloc> {
  late AppLocalizations loc;
@override
void initState() {
  super.initState();
  IdleService().onCriticalAuthPageEntered();   // ← YANGI
}

@override
void dispose() {
  IdleService().onCriticalAuthPageExited();    // ← YANGI
  super.dispose();
}
  @override
  Widget build(BuildContext context) {
    APDblocc apDbloc = BlocProvider.of(context, listen: false);
    loc = AppLocalizations.of(context)!;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: SizeConfig.h * 30.3),
      height: SizeConfig.v * 25.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(SizeConfig.v * 1.56),
      ),
      child: BlocConsumer<APDblocc, APDstate>(
        listener: (context, state) async {
          if (state is APDloadingState) {
            switch (state.status) {
              case APDstatus.posDevice:
                {
                  APDactivatePosDeviceEvent(
                    macAddress: widget.macAddress,
                    selectedPos: apDbloc.selectedPos!,
                    selectedStore: apDbloc.selectedStore,
                    token: widget.token,
                  );
                }
                break;
              case APDstatus.employee:
                {
                  apDbloc.add(APDgetEmployeeEvent());
                }
                break;

              case APDstatus.category:
                {
                  apDbloc.add(APDgetCategoriesEvent());
                }
                break;
              case APDstatus.service:
                {
                  apDbloc.add(APDgetServiceEvent());
                }
                break;
              case APDstatus.discounts:
                {
                  apDbloc.add(APDgetDiscountsEvent());
                }
                break;
              case APDstatus.items:
                {
                  apDbloc.add(APDupdateProductsEvent());
                }
                break;
              case APDstatus.organization:
                {
                  apDbloc.add(APDgetOrganizationEvent(
                      posId: apDbloc.selectedPos?.sId ?? ""));
                }
                break;
            }
          }
          if (state is APDallDoneState) {
            Provider.of<PagingProvider>(context, listen: false)
                .setCurrentPageId(DrawerItemId.home);
            AppNavigation.pushReplacement(const AccessLevelPage());
          }
        },
        builder: (context, state) {
          if (state is APDinitial) {
            if (state.selectedPos != null) {
              if (state.availablePosList.length == 1) {
                apDbloc.add(APDactivatePosDeviceEvent(
                  macAddress: widget.macAddress,
                  selectedPos: state.availablePosList.first,
                  selectedStore: state.selectedStore,
                  token: widget.token,
                ));
              }

              return ActivatePosDeviceInitialWidget(
                availablePosList: state.availablePosList,
                selectedPosName: state.selectedPos!.name!,
                isButtonEnabled: state.isButtonEnabled,
                defaultButtonPressed: () async {
                  apDbloc.add(APDactivatePosDeviceEvent(
                    macAddress: widget.macAddress,
                    selectedPos: state.selectedPos!,
                    selectedStore: state.selectedStore,
                    token: widget.token,
                  ));
                },
              );
            }

            return Padding(
              padding: EdgeInsets.all(SizeConfig.v * 3.2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc.pos_qurilma_mavjud_emas,
                    textAlign: TextAlign.center,
                    style: MyThemes.txtStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  DefaultButton(
                    text: loc.qayta_yuklash,
                    onPress: () {
                      AppNavigation.pushAndRemoveUntil(const PhoneNumberPage());
                    },
                    isButtonEnabled: true,
                  )
                ],
              ),
            );
          }
          if (state is APDloadingFailedState) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.v * 2, vertical: SizeConfig.v * 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ApdText(state.error.isEmpty ? "" : "ERROR: ${state.error}"),
                    Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: ApdText(srtFunc(state.status, false)),
                      ),
                    ),
                    DefaultButton(
                      onPress: () => apDbloc.add(APDreloadEvent(
                        status: state.status,
                      )),
                      text: loc.qayta_yuklash,
                      isButtonEnabled: true,
                    ),
                  ],
                ),
              ),
            );
          }

          ////////////////////////// Horizontal Loader //////////////////////////////////
          /*if (state is APDLoadingForProductsState) {
            return Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: ApdLoadingForProducts(
                      length: state.length, total: state.total),
                ),
                Align(
                  alignment: const Alignment(0.0, 0.5),
                  child: ApdText(srtFunc(state.status, true)),
                ),
              ],
            );
          }*/
          ////////////////////////// Horizontal Loader //////////////////////////////////

          if (state is APDallDoneState) {
            return Center(
              child: ApdText(loc.yuklanishlar_muvaffaqiyatli_yakunlandi),
            );
          }
          if (state is APDloadingState) {
            return Stack(
              children: [
                Positioned.fill(
                  child: SpinKitCircle(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Align(
                  alignment: const Alignment(0.0, 0.5),
                  child: ApdText(srtFunc(state.status, true)),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  String srtFunc(APDstatus status, bool success) {
    switch (status) {
      case APDstatus.posDevice:
        {
          return success
              ? loc.pos_qurilma_aktivlashtirilmoqda
              : loc.pos_qurilma_activlashtirish_yakunlanmadi;
        }

      case APDstatus.employee:
        {
          return success
              ? loc.employee_yuklanmoqda
              : loc.employee_yuklash_yakunlanmadi;
        }

      case APDstatus.category:
        {
          return success
              ? loc.kategoriyalar_yuklanmoqda
              : loc.kategoriyalar_yuklash_yakunlanmadi;
        }

      case APDstatus.service:
        {
          return success
              ? loc.service_yuklanmoqda
              : loc.service_yuklash_yakunlanmadi;
        }

      case APDstatus.items:
        {
          return success
              ? loc.productlar_olib_kelinmoqda
              : loc.productlar_olib_kelish_yakunlanmadi;
        }
      case APDstatus.organization:
        {
          return success
              ? loc.organization_olib_kelinmoqda
              : loc.organization_olib_kelish_yakunlanmadi;
        }

      case APDstatus.discounts:
        {
          return success
              ? loc.ha == 'Ha'
                  ? 'Chegirmalar olib kelinmoqda...'
                  : 'Скидки уже близко...'
              : loc.ha == 'Ha'
                  ? 'Chegirmalarni olib kelish yakunlandi.'
                  : 'Процесс дисконтирования завершен.';
        }
    }
  }
}
