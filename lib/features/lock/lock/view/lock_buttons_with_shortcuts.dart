// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/aditional_pages/ofd_page.dart';
import 'package:invan2/changes/aditional_pages/report_page.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/bloc/barcode_listener_bloc/bl_bloc.dart';
import 'package:invan2/features/home/home_page.dart';
import 'package:invan2/features/lock/access_level/bloc/access/access_bloc.dart';
import 'package:invan2/features/lock/access_level/bloc/pin/pin_bloc.dart';
import 'package:invan2/features/lock/lock/view/pincode_keyboard_widget.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:invan2/utils/utils.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:windows1251/windows1251.dart';

import '../../../../changes/models/log/loc_res_model.dart';
import '../../../../changes/repository/log_repository.dart';
import '../../../../changes/services/shifting_service.dart';
import '../../../../fiscal_service/post_methods.dart';
import '../../../settings_page.dart';

class PincodeKeyboardWidget extends StatefulWidget {
  final int accessLevel;

  const PincodeKeyboardWidget(this.accessLevel, {super.key});

  @override
  PincodeKeyboardWidgetState createState() => PincodeKeyboardWidgetState();
}

class PincodeKeyboardWidgetState extends State<PincodeKeyboardWidget>
    with SingleTickerProviderStateMixin {
  TextEditingController magneticStripeController = TextEditingController();
  late AnimationController animeController;
  final focusNode = FocusNode();
  bool isMagneticStripe = false;

  // --- Xato kiritish bloklash ---
  bool _isLocked = false;
  int _remainingSeconds = 60;
  Timer? _lockTimer;

  void _startLockTimer(AccessBloc accessBloc, {int fromSeconds = 60}) {
    _isLocked = true;
    _remainingSeconds = fromSeconds;
    _lockTimer?.cancel();
    _lockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _isLocked = false;
          timer.cancel();
          accessBloc.resetKeyboardLock();
        }
      });
    });
  }
  // --------------------------------

  bool _lockInitialized = false;

  @override
  void initState() {
    animeController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_lockInitialized) {
      _lockInitialized = true;
      final ab = BlocProvider.of<AccessBloc>(context, listen: false);
      if (ab.isKeyboardLocked) {
        _isLocked = true;
        _remainingSeconds = ab.keyboardRemainingSeconds;
        _startLockTimer(ab, fromSeconds: ab.keyboardRemainingSeconds);
      }
    }
  }

  @override
  void dispose() {
    _lockTimer?.cancel();
    animeController.dispose();
    focusNode.dispose();
    super.dispose();
  }

  late PinBloc pinBloc;
  late BlBloc blBloc;
  late AccessBloc accessBloc;

  @override
  Widget build(BuildContext context) {
    pinBloc = BlocProvider.of(context, listen: false);
    blBloc = BlocProvider.of(context, listen: false);
    accessBloc = BlocProvider.of(context, listen: false);

    blBloc.add(BlStatusChangedEvent(
        status: BLStatus.magneticStripe,
        where:
            "lib/features/lock/lock/view/lock_buttons_with_shortcuts.dart build"));
    final Animation<double> offsetAnimation = Tween(begin: 0.0, end: 24.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(animeController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          animeController.reverse();
        }
      });

    return AnimatedBuilder(
      animation: offsetAnimation,
      builder: (context, child) {
        return Container(
          height: SizeConfig.v * 66.0,
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(SizeConfig.v * 1.71)),
          padding: EdgeInsets.only(
            top: SizeConfig.v * 2.8,
            left: offsetAnimation.value + 24.0,
            right: 24.0 - offsetAnimation.value,
          ),
          child: VisibilityDetector(
            onVisibilityChanged: (VisibilityInfo v) {
              blBloc.add(BlVisibilityChangedEvent(v.visibleFraction > 0));
            },
            key: const Key('magnetic_stripe_listener'),
            child: MyBarcodeListener(
              bufferDuration: const Duration(milliseconds: 300),
              onBarcodeScannedMagnetic: (v) => pinBloc.add(PinSubmitEvent(v)),
              onBarcodeScanned: (v) {},
              onBarcodeScannedClick: (v) {},
              onBarcodeScannedPayme: (v) {},
              onDelPressed: () {},
              onF12Pressed: () {},
              onF5pressed: () {},
              onShiftDeletePressed: () {},
              onF1pressed: () {},
              onF2pressed: () {},
              onF3pressed: () {},
              onDownPressed: () {},
              onUpPressed: () {},
              onBarcodeScannedClient: (s) {},
              child: BlocConsumer<PinBloc, PinState>(
                listener: (context, state) {
                  if (state is PinInitial) {
                    switch (state.status) {
                      case PinSuccesStatus.pinSucced:
                        {
                          goHomePage(pinBloc.selectedEmployee!);
                        }
                        break;
                      case PinSuccesStatus.pinWrong:
                        {
                          if (pinBloc.numOfTry > 3 &&
                              pinBloc.passwordLength == 6) {
                            accessBloc
                                .add(AccessBlocEvent(pinBloc.passwordLength));
                          }
                          shake();
                          pinBloc.add(PinCButtonPressedEvent());
                          accessBloc.keyboardWrongAttempts++;
                          if (accessBloc.keyboardWrongAttempts >= 3) {
                            accessBloc.recordKeyboardLock();
                            setState(() {
                              _startLockTimer(accessBloc, fromSeconds: 60);
                            });
                          }
                        }
                        break;
                      case PinSuccesStatus.initial:
                        {}
                        break;
                      case PinSuccesStatus.getOrgErr:
                        {}
                    }
                  }
                },
                builder: (context, state) {
                  if (state is PinInitial) {
                    return Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        AbsorbPointer(
                          absorbing: _isLocked,
                          child: Opacity(
                            opacity: _isLocked ? 0.4 : 1.0,
                            child: PincodeKeyboardWidgetOff(
                              passwordLenth: pinBloc.passwordLength,
                              length: state.length,
                              cardPressedd: _isLocked
                                  ? () {}
                                  : () => pinBloc.add(PinGetOrganizationEvent()),
                              pressDeleteButton: _isLocked
                                  ? () {}
                                  : () => pinBloc.add(PinDeleteEvent()),
                              pressNum: _isLocked
                                  ? (_) {}
                                  : (v) => pinBloc.add(PinPressNumEvent(v.toString())),
                            ),
                          ),
                        ),
                        _isLocked
                            ? Positioned(
                                bottom: SizeConfig.v * 1.2,
                                left: SizeConfig.h * 2,
                                right: SizeConfig.h * 2,
                                child: Text(
                                  AppLocalizations.of(context)!.ha == 'Ha'
                                      ? '3 marta xato! $_remainingSeconds soniyadan so\'ng urinib ko\'ring'
                                      : '3 попытки неверны! Попробуйте через $_remainingSeconds сек.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: SizeConfig.v * 1.7,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ],
                    );
                  }
                  if (state is PinLoadingStatee) {
                    return Center(
                      child: SpinKitCircle(
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> goHomePage(Employee employee) async {
    // last change
    blBloc.add(BlStatusChangedEvent(
        status: BLStatus.home,
        where:
            "lib/features/lock/lock/view/lock_buttons_with_shortcuts.dart goHomepage"));
    AppLocalizations loc = AppLocalizations.of(context)!;
    await Pref.setString(PrefKeys.cashierName, employee.user!.firstName!);
    await Pref.setString(PrefKeys.cashierId, employee.user!.id!);
    Provider.of<PagingProvider>(context, listen: false)
        .setCurrentPageId(DrawerItemId.home);
    switch (widget.accessLevel) {
      case 0:
        {
          if (employee.access?.creatNewSale == true &&
              employee.access?.openShift == true) {
            final isShiftOpen = Pref.getBool(PrefKeys.shiftsOpened, false);

            if (isShiftOpen) {
              AppNavigation.pushAndRemoveUntil(const HomePage());
            } else {
              AppNavigation.pushReplacement(const ReportPage(isZet: false));
            }
          }
        }

        break;
      case 1: // X - otchet
        {
          if (employee.access?.xreport ?? false) {
            AppNavigation.pushReplacement(const ReportPage(isZet: false));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                mySnackBar(context, msg: loc.x_otchetga_access_yoq));
            shake();
          }
        }
        break;
      case 2: // Z - otchet

        {
          if (employee.access?.zreport ?? false) {
            AppNavigation.pushReplacement(const ReportPage(isZet: true));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                mySnackBar(context, msg: loc.z_otchetga_access_yoq));
            shake();
          }
        }
        break;
      case 3: // Настройки

        {
          AppNavigation.pushReplacement(const SettingsPage());
        }
        break;
      case 4: // OFD

        {
          if (employee.access?.openShift ?? false) {
            AppNavigation.pushReplacement(OfdPage());
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
                mySnackBar(context, msg: loc.z_otchetga_access_yoq));
            shake();
          }
        }
        break;
      default:
        break;
    }
  }

  void shake() async {
    animeController.reset();
    animeController.forward(from: 0.0);
    await Future.delayed(const Duration(milliseconds: 100));
    magneticStripeController.text = '';
  }
}
