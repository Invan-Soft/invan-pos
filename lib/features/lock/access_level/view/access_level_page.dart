// ignore_for_file: use_build_context_synchronously

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/changes/components/logo_widget.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/features/lock/access_level/bloc/pin/pin_bloc.dart';
import 'package:invan2/features/lock/access_level/view/access_blocked_widget.dart';
import 'package:invan2/features/lock/access_level/view/access_widget.dart';
import 'package:invan2/features/lock/lock/view/lock_buttons_with_shortcuts.dart';
import '../../../../app_navigation.dart';
import '../../../../changes/services/api/result_http_model.dart';
import '../../../../changes/services/log_service.dart';
import '../../../../changes/services/shift_api_4.dart';
import '../../../../changes/services/web_socket_service/web_socket_options/ws_service.dart';
import '../../../../utils/upgrade/update_checker.dart';
import '../../../../utils/utils.dart';
import '../../../../widgets/alice_pincode.dart';
import '../../../authentication/view/phone_number_page.dart';
import '../../../hive_repository/hive_boxes.dart';
import '../../../../idle_service.dart';

bool isWebSocketConnected = false;

class AccessLevelPage extends StatefulWidget {
  const AccessLevelPage({super.key});

  @override
  State<AccessLevelPage> createState() => _AccessLevelPageState();
}

class _AccessLevelPageState extends State<AccessLevelPage> {
  bool isAccessLevel = true;
  late AccessBloc lockBloc;

  /*@override
  void initState() {
    super.initState();
    isWebSocketConnected = false;
    Future.delayed(Duration(seconds: 0), () async {
      if (kDebugMode) {
      }
      if (!mounted) return;
      await WsService.connectWebSocket(mounted, context);
      isWebSocketConnected = true;
    });
  }*/

  @override
  void initState() {
    super.initState();
    IdleService().enable();
    IdleService().onLockPageEntered(); // Endi bu pageda turibmiz
    versionUpdate();
  }

  @override
  void dispose() {
    IdleService().onLockPageExited(); // Bu pagedan chiqildi (login qilindi)
    super.dispose();
  }

  Future<void> versionUpdate() async {
    await ShiftApi4.versionUpdate();
  }

  @override
  Widget build(BuildContext context) {
    lockBloc = BlocProvider.of(context, listen: false);
    return WillPopScope(
      onWillPop: () async => false,
      child: Stack(
        children: [
          Scaffold(
                        floatingActionButtonLocation:
                FloatingActionButtonLocation.startFloat,
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
            backgroundColor: MyThemes.darkPrimaryColor,
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  child: BlocBuilder<AccessBloc, AccessState>(
                    builder: (context, state) {
                      if (state is AccessPincodeState) {
                        return Container(
                          margin: EdgeInsets.only(
                              left: SizeConfig.v * 3, top: SizeConfig.v * 3),
                          padding: EdgeInsets.all(SizeConfig.v * 0.42),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                          ),
                          child: FloatingActionButton(
                            focusNode: FocusNode(skipTraversal: true),
                            backgroundColor: MyThemes.darkPrimaryColor,
                            onPressed: () =>
                                lockBloc.add(AccessSwitchToAccessEvent()),
                            child: Icon(
                              Icons.arrow_back,
                              size: SizeConfig.v * 4,
                              color: Colors.white,
                            ),
                          ),
                        );
                      }
                      return const SizedBox();
                    },
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Spacer(flex: 136),
                        Expanded(
                          flex: 346,
                          child: Hero(
                            tag: "logo_access",
                            child: LogoInvanWidget(
                              width: SizeConfig.h * 25,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const Spacer(flex: 150),
                        Expanded(
                          flex: 314,
                          child: Container(
                            height: SizeConfig.v * 75,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(SizeConfig.v * 1.71),
                            ),
                            child: BlocBuilder<AccessBloc, AccessState>(
                              builder: (context, state) {
                                if (state is AccessAccessState) {
                                  return AccessWidget(lockBloc);
                                }
                                if (state is AccessBlockedState) {
                                  return AccessBlocedWidget(
                                    state.passwordLenth,
                                    remainingSeconds: state.remainingSeconds,
                                  );
                                }

                                if (state is AccessPincodeState) {
                                  return BlocProvider(
                                    create: (context) =>
                                        PinBloc(lockBloc.level),
                                    child:
                                        PincodeKeyboardWidget(lockBloc.level),
                                  );
                                }

                                return const SizedBox();
                              },
                            ),
                          ),
                        ),
                        const Spacer(flex: 107),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
