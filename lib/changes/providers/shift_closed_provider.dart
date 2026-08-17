// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
import 'package:invan2/features/checks/features/checks_app_bar/bloc/usr_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/home/home_page.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/widgets/shift_warning_dialog.dart';
import 'package:provider/provider.dart';

import '../../fiscal_service/fiscal.dart';
import '../../widgets/my_snackbar.dart';
import '../models/log/loc_res_model.dart';
import '../services/shifting_service.dart';

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

    if (success == true) {
      AppNavigation.pushAndRemoveUntil(const HomePage());
      return;
    }

    // success == null → kassa serverda ochiq / ro'yxatda yo'q / aktivlashmagan
    // success == false → server smena holatini bermadi
    // Ilgari ikkalasi ham "Pos is open on the web" deb ko'rsatilardi.
    await _showOpenFailure(context, serverUnavailable: success == false);
  }

  /// Smena ochilmagan sababni kassirga tushunarli qilib ko'rsatadi va
  /// (imkoni bo'lsa) tuzatish tugmasini beradi.
  Future<void> _showOpenFailure(
    BuildContext context, {
    required bool serverUnavailable,
  }) async {
    final loc = AppLocalizations.of(context);
    final bool isUz = loc == null || loc.ha.toLowerCase() == 'ha';

    // Dialog ochilishidan oldin spinnerni olib tashlaymiz.
    _isWaiting = false;
    notifyListeners();

    final ShiftSnapshot snapshot = await ShiftDiagnostics.capture();
    final ShiftIssue issue = ShiftDiagnostics.lastOpenIssue ??
        (serverUnavailable
            ? ShiftIssue.serverStatusUnavailable
            : ShiftIssue.unknown);

    final List<ShiftIssue> issues = [issue];
    // Kassa serverda ochiq bo'lsa-yu, lokalda yuborilmagan yopish tursa —
    // asl sabab aynan shu, uni ham ko'rsatamiz.
    if (issue == ShiftIssue.cashboxOpenOnServer && snapshot.hasPendingClose) {
      issues.add(ShiftIssue.pendingCloseNotSynced);
    }

    await ShiftDiagnostics.report(
      issue: issue,
      action: ShiftAction.open,
      snapshot: snapshot,
      detail: ShiftDiagnostics.lastOpenDetail,
    );

    final ShiftWarningAction choice = await showShiftWarningDialog(
      context,
      issues: issues,
      snapshot: snapshot,
      isUz: isUz,
      action: ShiftAction.open,
    );

    if (choice == ShiftWarningAction.sendPendingClose) {
      await Provider.of<OpenShiftProvider>(context, listen: false)
          .sendPendingCloseToServer(context, isUz: isUz);
    } else if (choice == ShiftWarningAction.sendReceipts) {
      BlocProvider.of<UsrBloc>(context).add(
        UsrSendEvent("Smena ochishdan oldin", snapshot.unsentReceipts),
      );
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
