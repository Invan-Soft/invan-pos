// ignore_for_file: use_build_context_synchronously


import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import 'package:provider/provider.dart';

import '../../features/hive_repository/hive_boxes.dart';
import '../services/api.dart';
import 'ordering_provider_4.dart';

class OpenShiftProvider extends ChangeNotifier {
  OpenShiftProvider({required bool isShiftOpened})
      : _isShiftOpened = isShiftOpened;

  TextEditingController controller = TextEditingController();

  bool _isWaiting = false;

  bool _isShiftOpened;

  bool _printReport = true;

  /* //////////////////////// PROVIDER GETTERS //////////////////////// */

  bool get getIsShiftOpened => _isShiftOpened;

  bool get getPrintReport => _printReport;

  bool get getIsWaiting => _isWaiting;



  onShiftCloseButtonPressed(BuildContext context) async {
    _isWaiting = true;
    notifyListeners();
    await closeShift(context);
    await Provider.of<OrderingProvider4>(context, listen: false)
        .clearSixClient4List();
    MyObjectbox.saleStore.box<RuleCashModel4>().removeAll();
    _isWaiting = false;
    notifyListeners();
    AppNavigation.pop();
    // if (await InternetConnectionChecker().hasConnection) {
    /*if (Pref.getBool(PrefKeys.withOFD, false)) {
      // LocalResModel result = await ShiftingSerivce.closeZReport();

      LocalResModel result = LocalResModel();
      if (Pref.getBool(PrefKeys.withINCOM, false)) {
        result = await ShiftingSerivce.closeZReport();
      } else {
        var dataresult = await PostMethods.closeZReport();
        result = LocalResModel.fromJson(dataresult);
      }

      if (!result.error!) {
        await closeShift(context);
        await Provider.of<OrderingProvider4>(context, listen: false)
            .clearSixClient4List();
        MyObjectbox.saleStore.box<RuleCashModel4>().removeAll();
        _isWaiting = false;
        // await Prefs.setBool(PrefKeys.withOFD, false);
        notifyListeners();
        AppNavigation.pop();
      } else {
        AppNavigation.pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(mySnackBar(context, msg: result.message!));
        _isWaiting = false;
        notifyListeners();
      }
    } else {
      await closeShift(context);
      await Provider.of<OrderingProvider4>(context, listen: false)
          .clearSixClient4List();
      MyObjectbox.saleStore.box<RuleCashModel4>().removeAll();
      _isWaiting = false;
      notifyListeners();
      await Pref.setBool(PrefKeys.withOFD, false);
      AppNavigation.pop();
    }*/
    // } else {
    //   if (Pref.getBool(PrefKeys.shiftsOpened, false)) {
    //     _isWaiting = false;
    //     ScaffoldMessenger.of(context).showSnackBar(
    //       mySnackBar(context, msg: "Невозможно закрыть смену", duration: 2000),
    //     );
    //     AppNavigation.pop();
    //   }
    // }
  }

  ////////////////////////////////////////////////////////////////////////
  ///                                                                 ////
  ///                     OPEN  SHIFT                                 ////
  ///                                                                 ////
  ////////////////////////////////////////////////////////////////////////

  Future<bool?> openShift(BuildContext context, int startingCash) async {
    late bool? result = false;
    int openedTime = DateTime.now().millisecondsSinceEpoch;
    await Pref.setInt(PrefKeys.shiftOpenedTime, openedTime);
    result = await ShiftSingleton4.openShift(context,
        startingCash: startingCash.toDouble());

    await Pref.setBool(PrefKeys.shiftsOpened, result ?? false);
    _isShiftOpened = result ?? false;
    notifyListeners();
    return result;
  }

  ////////////////////////////////////////////////////////////////////////
  ///                                                                 ////
  ///                    CLOSE  SHIFT                                 ////
  ///                                                                 ////
  ////////////////////////////////////////////////////////////////////////

  closeShift(BuildContext context) async {
    ShiftModelHive shiftResponse = await ShiftSingleton4.closeShift(context);
    if (Pref.getBool(PrefKeys.shiftsOpened, false)) {
      ScaffoldMessenger.of(context).showSnackBar(
        mySnackBar(context, msg: "Невозможно закрыть смену", duration: 2000),
      );
      AppNavigation.pop();
    } else {
      int currentShiftKey = Pref.getInt(PrefKeys.currentShiftKey, -1);
      Box<ShiftModelHive> box = HiveBoxes.getShifts();
      ShiftModelHive data = box.get(currentShiftKey)!;
      CashDrawerHive cashDrawer = data.cashDrawerHive!;
      if (controller.text.isNotEmpty) {
        controller.text = controller.text.replaceAll(',', '');
        cashDrawer.actCashAmount =
            cashDrawer.actCashAmount! + int.parse(controller.text);
      }
      data.cashDrawerHive = cashDrawer;
      await box.put(currentShiftKey, data);
      controller.clear();
      if (_printReport) {
        ShiftModelHive? shift;
        try {
          shift = shiftResponse;
        } catch (e) {
          return;
        }
        PrintingMethods.printSmena(
            shift: shift, isZ: true, loc: AppLocalizations.of(context)!);
      }
      _isShiftOpened = false;
    }

    notifyListeners();
  }

  void setPrintReport() {
    _printReport = !_printReport;
    notifyListeners();
  }

  void setPrintReportFalse() {
    _printReport = false;

    notifyListeners();
  }
}
