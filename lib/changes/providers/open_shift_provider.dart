// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
import 'package:invan2/features/checks/features/checks_app_bar/bloc/usr_bloc.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/widgets/my_snackbar.dart';
import 'package:invan2/widgets/shift_warning_dialog.dart';
import 'package:provider/provider.dart';
import '../../features/hive_repository/hive_boxes.dart';
import '../models/shift/shifting_model.dart';
import '../services/api.dart';

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
    if (!await _confirmCloseWithWarnings(context)) return;

    _isWaiting = true;
    notifyListeners();
    final bool closed = await closeShift(context);

    // Savat va RuleCash faqat smena HAQIQATAN yopilganda tozalanadi. Ilgari
    // yopish bajarilmagan holatda ham tozalanardi — smena ochiq qolib,
    // ma'lumot esa o'chib ketardi.
    if (closed) {
      await Provider.of<OrderingProvider4>(context, listen: false)
          .clearSixClient4List();
      MyObjectbox.saleStore.box<RuleCashModel4>().removeAll();
    }
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

  bool _isUz(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return loc == null || loc.ha.toLowerCase() == 'ha';
  }

  Future<bool> _confirmCloseWithWarnings(BuildContext context) async {
    final bool isUz = _isUz(context);

    // Internet tekshiruvi bir necha soniya olishi mumkin — shu vaqtda spinner.
    _isWaiting = true;
    notifyListeners();
    ShiftSnapshot snapshot = await ShiftDiagnostics.capture();

    // Navbatda ochish/yopish turgan bo'lsa, internet bor ekan — avval o'shani
    // yuboramiz. Aks holda serverda ochilmagan smenani yopishga urinamiz va
    // server rad etadi. Bu yerda `flush` tartibi ham to'g'ri: avval yopish,
    // keyin ochish.
    if (snapshot.internet && !snapshot.canCloseOffline) {
      await ShiftSyncQueue.flush(reason: 'before-close');
      snapshot = await ShiftDiagnostics.capture(internet: true);
    }

    _isWaiting = false;
    notifyListeners();

    // 1) Yopish umuman mumkinmi? Mumkin bo'lmasa hech narsa yozilmasligi
    // kerak: `ShiftSingleton4.closeShift` Hive yozuviga `isClosed=true` va
    // `closedDate` ni shartni tekshirishdan OLDIN yozadi, keyin esa smenani
    // yopmay qo'yadi. 2026-08-17 da kassir aynan shu sababli "Smena yopildi"
    // degan xabarni ko'rib, smena ochiq qolganini keyin bilgan.
    final ShiftIssue? blocker = ShiftDiagnostics.blockingCloseIssue(snapshot);
    if (blocker != null) {
      await ShiftDiagnostics.report(
        issue: blocker,
        action: ShiftAction.close,
        snapshot: snapshot,
        detail: 'Yopish boshlanmadi (oflayn shart bajarilmaydi): '
            'openedCount=${snapshot.openedCount}, '
            'closedCount=${snapshot.closedCount}',
      );
      await showShiftWarningDialog(
        context,
        issues: [blocker],
        snapshot: snapshot,
        isUz: isUz,
        action: ShiftAction.close,
        infoOnly: true,
        succeeded: false,
      );
      return false;
    }

    // 2) Yopish mumkin, lekin e'tibor berish kerak bo'lgan holatlar.
    final List<ShiftIssue> warnings = ShiftDiagnostics.closeWarnings(snapshot);
    if (warnings.isEmpty) return true;

    final ShiftWarningAction choice = await showShiftWarningDialog(
      context,
      issues: warnings,
      snapshot: snapshot,
      isUz: isUz,
      action: ShiftAction.close,
    );

    switch (choice) {
      case ShiftWarningAction.sendReceipts:
        BlocProvider.of<UsrBloc>(context).add(
          UsrSendEvent("Smena yopishdan oldin", snapshot.unsentReceipts),
        );
        ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
          context,
          msg: isUz
              ? 'Cheklar yuborilmoqda. Tugagach smenani qayta yoping.'
              : 'Чеки отправляются. После завершения закройте смену снова.',
          duration: 3000,
        ));
        return false;

      case ShiftWarningAction.sendPendingClose:
        await sendPendingCloseToServer(context, isUz: isUz);
        return false;

      case ShiftWarningAction.continueAnyway:
        await ShiftDiagnostics.report(
          issue: warnings.first,
          action: ShiftAction.close,
          snapshot: snapshot,
          detail: 'Kassir ogohlantirishga qaramay yopishni davom ettirdi.\n'
              'Aniqlangan muammolar: ${warnings.map((e) => e.name).join(", ")}',
        );
        return true;

      case ShiftWarningAction.cancel:
        return false;
    }
  }

  /// Serverga yetmagan smena yopilishini qo'lda qayta yuboradi.
  ///
  /// 2026-08-13 hodisasida aynan shu yo'l yetishmagan edi: lokal smena yopiq,
  /// serverda ochiq — va yopishni qayta yuborishning hech qanday usuli yo'q edi,
  /// shu sababli kassa butunlay bloklanib qolgan.
  Future<void> sendPendingCloseToServer(
    BuildContext context, {
    required bool isUz,
  }) async {
    _isWaiting = true;
    notifyListeners();

    ShiftingModel result = await ShiftApi4.closeShift();
    final bool ok = result.statusCode == 200;

    if (ok) {
      await Pref.setString(PrefKeys.closedDate, '');
      await Pref.setInt(PrefKeys.closedCount, 0);
      await Pref.setBool(PrefKeys.shiftsOpened, false);
      _isShiftOpened = false;
    } else {
      await ShiftDiagnostics.report(
        issue: ShiftIssue.serverCloseFailed,
        action: ShiftAction.close,
        detail: 'Kassir "Yopishni yuborish" tugmasini bosdi, server javobi: '
            '${result.statusCode ?? "-"} / ${result.message ?? "-"}',
      );
    }

    _isWaiting = false;
    notifyListeners();

    ScaffoldMessenger.of(context).showSnackBar(mySnackBar(
      context,
      msg: ok
          ? (isUz
              ? 'Smena yopilishi serverga yuborildi. Endi yangi smena ochishingiz mumkin.'
              : 'Закрытие смены отправлено на сервер. Теперь можно открыть новую смену.')
          : (isUz
              ? 'Serverga yuborib bo\'lmadi. Internetni tekshirib, qayta urinib ko\'ring.'
              : 'Не удалось отправить на сервер. Проверьте интернет и попробуйте снова.'),
      duration: 4000,
    ));
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

  /// Smena yopildimi — `false` bo'lsa POS'da smena ochiq qoladi.
  Future<bool> closeShift(BuildContext context) async {
    final bool isUz = _isUz(context);

    late ShiftModelHive shiftResponse;
    try {
      shiftResponse = await ShiftSingleton4.closeShift(context);
    } catch (e) {
      // Masalan lokal smena yozuvi yo'q bo'lsa (getCurrentHiveShift() == null).
      // Ilgari bu holat qizil ekran/jim xatolik bilan tugardi.
      await ShiftDiagnostics.report(
        issue: ShiftIssue.localShiftMissing,
        action: ShiftAction.close,
        detail: 'ShiftSingleton4.closeShift xatosi: $e',
      );
      await _showShiftIssue(context, ShiftIssue.localShiftMissing,
          isUz: isUz, succeeded: false);
      return false;
    }

    if (Pref.getBool(PrefKeys.shiftsOpened, false)) {
      // Server yopishni tasdiqlamadi — smena hali ochiq hisoblanadi.
      await ShiftDiagnostics.report(
        issue: ShiftIssue.serverCloseFailed,
        action: ShiftAction.close,
      );
      await _showShiftIssue(context, ShiftIssue.serverCloseFailed,
          isUz: isUz, succeeded: false);
      AppNavigation.pop();
      notifyListeners();
      return false;
    } else {
      int currentShiftKey = Pref.getInt(PrefKeys.currentShiftKey, -1);
      Box<ShiftModelHive> box = HiveBoxes.getShifts();
      ShiftModelHive? data = box.get(currentShiftKey);
      if (data == null) {
        await ShiftDiagnostics.report(
          issue: ShiftIssue.localShiftMissing,
          action: ShiftAction.close,
          detail: 'Hive smena yozuvi topilmadi: key=$currentShiftKey',
        );
        await _showShiftIssue(context, ShiftIssue.localShiftMissing,
            isUz: isUz, succeeded: false);
        notifyListeners();
        return false;
      }
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
        PrintingMethods.printSmena(
            shift: shiftResponse, isZ: true, loc: AppLocalizations.of(context)!);
      }
      _isShiftOpened = false;

      // Smena kassada yopildi. Lekin serverga yetdimi? `closedDate` faqat
      // server 200 qaytarganda tozalanadi — bo'sh bo'lmasa, yopilish navbatda
      // qolgan va bu kassada yangi smena OCHILMAYDI. Kassir buni hozir
      // bilishi kerak, 15 marta "smena ochish"ni bosgandan keyin emas.
      if (Pref.getString(PrefKeys.closedDate, '').isNotEmpty) {
        await ShiftDiagnostics.report(
          issue: ShiftIssue.pendingCloseNotSynced,
          action: ShiftAction.close,
        );
        // Smena YOPILDI — sarlavha ham shuni aytishi kerak.
        await _showShiftIssue(context, ShiftIssue.pendingCloseNotSynced,
            isUz: isUz, succeeded: true);
      }
    }

    notifyListeners();
    return true;
  }

  /// Muammoni kassirga sabab + tavsiya bilan ko'rsatadi (amal bajarilgandan
  /// keyin — faqat xabar, "Baribir yopish" tugmasisiz).
  Future<void> _showShiftIssue(
    BuildContext context,
    ShiftIssue issue, {
    required bool isUz,
    required bool succeeded,
  }) async {
    final ShiftSnapshot snapshot = await ShiftDiagnostics.capture();
    final ShiftWarningAction choice = await showShiftWarningDialog(
      context,
      issues: [issue],
      snapshot: snapshot,
      isUz: isUz,
      action: ShiftAction.close,
      infoOnly: true,
      succeeded: succeeded,
    );

    if (choice == ShiftWarningAction.sendPendingClose) {
      await sendPendingCloseToServer(context, isUz: isUz);
    } else if (choice == ShiftWarningAction.sendReceipts) {
      BlocProvider.of<UsrBloc>(context).add(
        UsrSendEvent("Smena yopilgandan keyin", snapshot.unsentReceipts),
      );
    }
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
