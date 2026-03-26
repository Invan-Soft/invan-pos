// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/providers/open_shift_provider.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/features/home/home_page.dart';
import 'package:invan2/utils/utils.dart';
import 'package:provider/provider.dart';

import '../../features/hive_repository/hive_boxes.dart';
import '../../fiscal_service/fiscal.dart';
import '../../utils/l10n/app_localizations.dart';
import '../../widgets/my_snackbar.dart';
import '../models/log/loc_res_model.dart';
import '../services/shifting_service.dart';
import 'ordering_provider_4.dart';

class ShiftClosedProvider extends ChangeNotifier {
  TextEditingController startingCash = TextEditingController(text: "0");
  bool _isWaiting = false;
  FocusNode focusNode = FocusNode();


  ////////////////  GETTERS  /////////////////////
  bool get getIsWaiting => _isWaiting;

  ////////////////////////////////////////////////
  increaseController(String num) {
    startingCash.text = MoneyFormatter.remover(startingCash.text);
    startingCash.text += num;
    startingCash.text = MoneyFormatter.inputMoneyFormatter.format(
      double.parse(startingCash.text),
    );
    focusNode.requestFocus();
    notifyListeners();
  }

  decreaseController() {
    if (startingCash.text.isNotEmpty && startingCash.text.length > 1) {
      startingCash.text = MoneyFormatter.remover(startingCash.text);

      startingCash.text =
          startingCash.text.substring(0, startingCash.text.length - 1);
      startingCash.text = MoneyFormatter.inputMoneyFormatter
          .format(double.parse(startingCash.text));
    } else {
      startingCash.text = '0';
    }
    focusNode.requestFocus();
    notifyListeners();
  }

  cButtonPressed() {
    startingCash.text = '0';
    focusNode.requestFocus();
    notifyListeners();
  }

  onDotPressed() {
    if (startingCash.text.contains('.')) return;
    startingCash.text += ".";
    focusNode.requestFocus();
    notifyListeners();
  }

  onOpenShiftButtonPressed(BuildContext context) async {
    // AppLocalizations loc = AppLocalizations.of(context)!;
    //
    // final currentEmployeeId = Pref.getString(PrefKeys.cashierId, 'no data');
    // final box = HiveBoxes.getEmployees();
    // final employee = box.get(currentEmployeeId);
    //
    // if (employee?.access?.openShift != true) {
    //   ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
    //     context,
    //     duration: 1500,
    //     msg: loc.ha !="Ha" ?"У вас нет разрешения на открытие смены !!!": "Sizda Smena ochishga ruxsat mavjud emas !!!",
    //   ));
    //   return;
    // }
    startingCash.text = MoneyFormatter.remover(startingCash.text);
    int startCash =
        double.parse(startingCash.text.isEmpty ? '0' : startingCash.text)
            .toInt();
    _isWaiting = true;
    notifyListeners();

    /*if (Pref.getBool(PrefKeys.withOFD, false)) {
      await _ofd(context, startCash);
    } else {
      await _simple(context, startCash);
    }*/

    await _simple(context, startCash);

    focusNode.requestFocus();
    _isWaiting = false;
    startingCash.text = '0';
    notifyListeners();
    return;
  }

  // ignore: unused_element
  Future<void> _simple(BuildContext context, int startingCash) async {
    bool? success = await Provider.of<OpenShiftProvider>(context, listen: false)
        .openShift(context, startingCash);
    Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
    cButtonPressed();
    if (success == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          mySnackBar(context, msg: 'Pos is open on the web', duration: 2000));
      LogRepository.addLog(
        "OpenShiftProvider / openshift / funcsiyasi false qaytargan holat",
        file: "ShiftClosedProvider / onOpenShiftButtonPresed",
        method: "-",
        path: '-',
        where: "SHIFTCLOSEDPROVIDER / onOpenShiftButtonPresed ",
        statusCode: -1,
      );
    } else if (success == true) {
      AppNavigation.pushAndRemoveUntil(const HomePage());
    } else {
      ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
          msg: 'Потолок открыть невозможно.', duration: 2000));
    }
  }

  Future<void> _ofd(BuildContext context, int startingCash) async {
    await Pref.setBool(PrefKeys.withOFD, true);
    if (Pref.getBool(PrefKeys.withINCOM, false)) {
      LocalResModel info = await ShiftingSerivce.openeZetReport();
      if (info.error! && info.message != "ERROR_ZREPORT_IS_ALREADY_OPEN") {
        ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
            msg: "OpenZetReport: ==> ${info.message!} ", duration: 2000));
        _isWaiting = false;
        notifyListeners();
      } else {
        bool? success =
            await Provider.of<OpenShiftProvider>(context, listen: false)
                .openShift(context, startingCash);

        Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
        cButtonPressed();
        if (success == null) {
          ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
              msg: 'Pos is open on the web', duration: 2000));
          LogRepository.addLog(
            "OpenShiftProvider / openshift / funcsiyasi false qaytargan holat",
            file: "ShiftClosedProvider / onOpenShiftButtonPresed",
            method: "-",
            where: "SHIFTCLOSEDPROVIDER / onOpenShiftButtonPresed / OFD",
            path: '-',
            statusCode: -1,
          );
        } else if (success == true) {
          ScaffoldMessenger.of(context)
              .showSnackBar(mySnackBar(context, msg: info.message!));
          AppNavigation.pushAndRemoveUntil(const HomePage());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
              msg: 'Потолок открыть невозможно.', duration: 2000));
        }
        _isWaiting = false;
        notifyListeners();
      }
    } else {
      var fiscalData = await PostMethods.openZReport();
      LocalResModel info = LocalResModel.fromJson(fiscalData);
      if (fiscalData['error']) {
        ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
            msg: "OpenZetReport: ==> ${fiscalData['message']} ",
            duration: 2000));
        _isWaiting = false;
        notifyListeners();
      } else {
        bool? success =
            await Provider.of<OpenShiftProvider>(context, listen: false)
                .openShift(context, startingCash);
        Provider.of<OrderingProvider4>(context, listen: false).pressAllPath();
        cButtonPressed();
        if (success == null) {
          ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
              msg: 'Pos is open on the web', duration: 2000));
          LogRepository.addLog(
            "OpenShiftProvider / openshift / funcsiyasi false qaytargan holat",
            file: "ShiftClosedProvider / onOpenShiftButtonPresed",
            method: "-",
            where: "SHIFTCLOSEDPROVIDER / onOpenShiftButtonPresed / OFD",
            path: '-',
            statusCode: -1,
          );
        } else if (success == true) {
          ScaffoldMessenger.of(context)
              .showSnackBar(mySnackBar(context, msg: info.message!));
          AppNavigation.pushAndRemoveUntil(const HomePage());
        } else {
          ScaffoldMessenger.of(context).showSnackBar(mySnackBar(context,
              msg: 'Потолок открыть невозможно.', duration: 2000));
        }
        _isWaiting = false;
        notifyListeners();
      }
    }
  }
}
