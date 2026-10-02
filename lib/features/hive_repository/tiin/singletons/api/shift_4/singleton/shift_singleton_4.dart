import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:invan2/changes/models/shift/shift_hive_model.dart';
import 'package:invan2/changes/repository/log_repository.dart';
import 'package:invan2/changes/services/api/result_http_model.dart';
import 'package:invan2/changes/services/shift/shift_diagnostics.dart';
import 'package:invan2/changes/services/shift/shift_sync_queue.dart';
import 'package:invan2/changes/services/shift_api_4.dart';
import 'package:invan2/features/hive_repository/hive_boxes.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/receipt_4/model/receipt_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/api/shift_4/model/rule_cash_model_4.dart';
import 'package:invan2/features/hive_repository/tiin/singletons/my_objectbox/my_objectbox.dart';
import 'package:invan2/objectbox.g.dart' hide Box;
import 'package:invan2/utils/utils.dart';
import 'package:uuid/uuid.dart';

import '../../../../../../../changes/models/shift/shifting_model.dart';
import 'package:invan2/changes/services/health/backend_health.dart';

class ShiftSingleton4 {
  /// Smena ochilish/yopilish vaqti shu soatdan olinadi. Testlarda ketma-ket
  /// amallarga aniq, farqli vaqt berish uchun almashtiriladi.
  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  static void updateTheShift(List<ReceiptModelPaymentType4> payments,
      double zdachaToCashBack, double discountAmount) async {
    num card = 0;
    num cash = 0;
    num cashback = 0;
    num debt = 0;

    for (int i = 0; i < payments.length; i++) {
      switch (payments[i].name) {
        case "card":
          card += payments[i].value;
          break;
        case "cash":
          cash += payments[i].value;
          break;
        case "cashback":
          cashback += payments[i].value;
          break;
        case "debt":
          debt += payments[i].value;
          break;
        default:
      }
    }

    int currentShiftKey = Pref.getInt(PrefKeys.currentShiftKey, -1);
    Box<ShiftModelHive> boxx = HiveBoxes.getShifts();
    ShiftModelHive data = boxx.get(currentShiftKey)!;
    // ----------------------------------
    CashDrawerHive cashDrawer = data.cashDrawerHive!;
    cashDrawer.cashPayment =
        data.cashDrawerHive!.cashPayment! + cash + zdachaToCashBack;
    cashDrawer.expCashAmount =
        cashDrawer.expCashAmount! + cash + zdachaToCashBack;
    cashDrawer.actCashAmount = cashDrawer.actCashAmount!;

    SalesSummaryHive salesSummary = data.salesSummary!;
    salesSummary.discounts = salesSummary.discounts! + discountAmount;
    salesSummary.card = data.salesSummary!.card! + card;
    salesSummary.cash = data.salesSummary!.cash! + cash + zdachaToCashBack;
    salesSummary.cashbackOut = data.salesSummary!.cashbackOut! + cashback;
    salesSummary.cashbackIn = data.salesSummary!.cashbackIn! + zdachaToCashBack;
    salesSummary.grossSales = data.salesSummary!.grossSales! +
        cash +
        card +
        cashback +
        zdachaToCashBack +
        debt;
    salesSummary.debt = debt;

    //-----------------------------------
    data.salesSummary = salesSummary;
    data.cashDrawerHive = cashDrawer;

    //-----------------------------------

    await boxx.put(currentShiftKey, data);
  }

  static void updateShiftOnRefund(
      List<ReceiptModelPaymentType4> payments) async {
    num cash = 0;

    for (int i = 0; i < payments.length; i++) {
      cash += payments[i].value;
    }
    int currentShiftKey = Pref.getInt(PrefKeys.currentShiftKey, -1);
    Box<ShiftModelHive> box = HiveBoxes.getShifts();
    ShiftModelHive data = box.get(currentShiftKey)!;
    // ----------------------------------f
    CashDrawerHive cashDrawer = data.cashDrawerHive!;
    cashDrawer.cashPayment = data.cashDrawerHive!.cashPayment! - cash;
    cashDrawer.expCashAmount = cashDrawer.expCashAmount! - cash;
    cashDrawer.actCashAmount = cashDrawer.actCashAmount!;
    //-----------------------------------
    SalesSummaryHive salesSummary = data.salesSummary!;
    salesSummary.cash = data.salesSummary!.cash! - cash;

    //-----------------------------------
    data.salesSummary = salesSummary;
    data.cashDrawerHive = cashDrawer;

    //-----------------------------------
    await box.put(currentShiftKey, data);
  }

/////////////////////////////////////////////////////////////////////////////////
// in use
  static Future<bool?> openShift(BuildContext context,
      {required double startingCash}) async {
    Box<ShiftModelHive> box = HiveBoxes.getShifts();
    int i = box.isEmpty ? 0 : box.keys.last + 1;
    ShiftModelHive shift = _initOfflineShiftOnHive(startingCash);
    await box.put(i, shift);
    ShiftModelHive sh = box.get(i)!;
    sh.iV = i;
    bool? isReturn = true;

    // Ochilish vaqti, kassir va kassa BIR MARTA olinadi: onlayn yuborilsa
    // ham, navbatga tushsa ham serverga aynan shu qiymatlar ketadi.
    final String openedAt =
        DateFormat('yyyy-MM-dd HH:mm:ss').format(clock().toUtc());
    final String userId = Pref.getString(PrefKeys.userId, '');
    final String cashboxId = Pref.getString(PrefKeys.activatedPosId, '');
    await Pref.setInt(PrefKeys.currentShiftKey, i);
    // Har urinishdan oldin oldingi sababni tozalaymiz — UI faqat shu
    // urinishning sababini ko'rsatishi kerak.
    ShiftDiagnostics.resetOpenIssue();

    /// Smenani serversiz (lokal) ochish — ochilish navbatga qo'yiladi.
    ///
    /// Internet yo'q, server yiqilgan yoki navbatda serverga yetmagan eski
    /// voqealar bor — kassa uchun hammasi bir xil: kassir sotishi kerak,
    /// ochilish esa navbat orqali o'z tartibida yetadi.
    ///
    /// Har ochilish navbatga alohida yoziladi. Ilgari navbatda ochish uchun
    /// bitta joy bor edi va ikkinchi oflayn ochilish birinchisining vaqtini
    /// o'chirib yuborardi (qarang: `ShiftSyncQueue`).
    Future<void> openOffline() async {
      isReturn = true;
      await ShiftSyncQueue.enqueueOpen(openedAt,
          userId: userId, cashboxId: cashboxId);
    }

    if (await BackendHealth.isUsable()) {
      // Serverga yetmagan eski voqealar (masalan oldingi smenaning yopilishi)
      // avval ketsin — serverdagi kassa holati shundan keyingina to'g'ri.
      await ShiftSyncQueue.flush(reason: 'before-open');

      // Ular baribir ketmagan bo'lsa, serverdagi holat ESKIRGAN: masalan
      // server kassani "ochiq" deb ko'rsatadi, chunki bizning yopilishimiz
      // unga hali yetmagan. Unga ishonib ochishni bloklash noto'g'ri —
      // smena lokal ochiladi va navbatda ularning ortidan turadi.
      if (ShiftSyncQueue.hasPending) {
        await openOffline();
        return isReturn;
      }

      await ShiftApi4.shiftStatusInvan2().then((HttpResult status) async {
        // 1a) Server yiqilgan (5xx / timeout / ulanmadi) — bu "smena
        // ochilmasin" degani EMAS. Internet uzilgandagi kabi lokal ochamiz
        // va navbatga qo'yamiz. Aks holda server o'chganda butun do'kon
        // sotolmay qoladi: 2026-09-02 dagi to'xtash aynan shu sabab edi.
        //
        // Muhim: `BackendHealth` hali `down` ga o'tmagan bo'lishi mumkin
        // (buning uchun ketma-ket bir necha xato kerak), shuning uchun bu
        // yerda status kodining o'zi tekshiriladi — birinchi urinishdayoq.
        if (BackendHealth.isServerFailureStatus(status.statusCode)) {
          ShiftDiagnostics.lastOpenIssue = ShiftIssue.serverStatusUnavailable;
          ShiftDiagnostics.lastOpenDetail =
              'GET api/v1/shift_statuses → status ${status.statusCode} '
              '(server yiqilgan — smena lokal ochildi, navbatga qo\'yildi)';
          await openOffline();
          return;
        }

        // 1b) Server TIRIK, lekin so'rovni rad etdi (401/403/404 va h.k.) —
        // bu haqiqiy muammo, lokal ochib yashirmaymiz.
        if (status.statusCode >= 400 || !status.isSuccess) {
          ShiftDiagnostics.lastOpenIssue = ShiftIssue.serverStatusUnavailable;
          ShiftDiagnostics.lastOpenDetail =
              'GET api/v1/shift_statuses → status ${status.statusCode}';
          isReturn = false;
          return;
        }

        final List<dynamic> cashBoxes = status.result;
        final String posId = Pref.getString(PrefKeys.activatedPosId, '');

        // 2) POS aktivlashtirilmagan.
        if (posId.isEmpty) {
          ShiftDiagnostics.lastOpenIssue = ShiftIssue.posNotActivated;
          ShiftDiagnostics.lastOpenDetail = 'activatedPosId bo\'sh';
          isReturn = null;
          return;
        }

        // 3) Shu kassani server ro'yxatidan topamiz.
        dynamic myCashBox;
        for (final dynamic cashBox in cashBoxes) {
          if (cashBox is Map && cashBox['cashbox_id'] == posId) {
            myCashBox = cashBox;
            break;
          }
        }

        if (myCashBox == null) {
          ShiftDiagnostics.lastOpenIssue = ShiftIssue.cashboxNotFoundOnServer;
          ShiftDiagnostics.lastOpenDetail =
              'activatedPosId = $posId\nServer ro\'yxatida ${cashBoxes.length} '
              'ta kassa bor, lekin bu ID yo\'q.';
          isReturn = null;
          return;
        }

        // 4) Kassa serverda to'liq yopiqmi?
        final bool isFullyClosed = ShiftApi4.isCashboxFullyClosed(myCashBox);

        if (!isFullyClosed) {
          ShiftDiagnostics.lastOpenIssue = myCashBox['opened_by_web'] == true
              ? ShiftIssue.cashboxOpenOnWeb
              : ShiftIssue.cashboxOpenOnServer;
          ShiftDiagnostics.lastOpenDetail = 'Serverdagi holat:\n'
              'cashbox_name = ${myCashBox["cashbox_name"]}\n'
              'status = ${myCashBox["status"]}\n'
              'opened_by_pos = ${myCashBox["opened_by_pos"]}\n'
              'opened_by_web = ${myCashBox["opened_by_web"]}\n'
              'opened_by_user_id = ${myCashBox["opened_by_user_id"]}\n'
              'cashbox_id = ${myCashBox["cashbox_id"]}';
          isReturn = null;
          return;
        }

        // 5) Hammasi joyida. Lekin navbatda hali ketmagan eski voqealar
        // qolgan bo'lsa, bu ochilish ularning ORTIDAN ketishi kerak —
        // to'g'ridan-to'g'ri yuborilsa server ularni noto'g'ri tartibda oladi.
        if (ShiftSyncQueue.hasPending) {
          await openOffline();
          unawaited(ShiftSyncQueue.flush(reason: 'after-open'));
          return;
        }

        // Navbat bo'sh — smenani serverda to'g'ridan-to'g'ri ochamiz.
        //
        // Javob KUTILADI: yiqilsa ochilish shu zahoti navbatga tushishi
        // kerak. Ilgari so'rov kutilmasdi — kassir smenani ochib darhol
        // yopsa, yopilish ochilishdan oldin serverga yetib bekor ketishi
        // (server yopiq kassani yopishga 200 qaytaradi) va smena serverda
        // ochiq qolishi mumkin edi.
        try {
          final HttpResult value = await ShiftApi4.openShift(
              openedAt: openedAt, userId: userId, cashboxId: cashboxId);
          if (value.isSuccess) {
            String localSUuid = const Uuid().v4();
            sh
              ..shiftId = localSUuid
              ..iV = i;
            await box.put(
              i,
              sh,
            );
          } else {
            await box.put(i, sh);
            // Server ochilishni tasdiqlamadi — navbatga qo'yamiz: server
            // yiqilgan bo'lsa keyin yetadi, rad etgan bo'lsa navbat uni
            // hisobot bilan olib tashlaydi. Ilgari bu ochilish yo'qolardi
            // va kechqurun "kassa serverda ochiq emas" muammosi chiqardi.
            await ShiftSyncQueue.enqueueOpen(openedAt,
                userId: userId, cashboxId: cashboxId);
            await ShiftDiagnostics.report(
              issue: ShiftIssue.pendingOpenNotSynced,
              action: ShiftAction.open,
              detail: 'POST api/v1/shift_pos (open) → '
                  'status ${value.statusCode}',
            );
          }
        } catch (err) {
          LogRepository.addLog(
            err.toString(),
            file: "ShiftSingleton_4 / openShift / catchError",
            method: "OPEN SHIFT",
            where: "SHIFT SINGLETON / CATCH ERROR",
            path: "ShiftSingleton_4.dart",
            statusCode: 0,
            url: '-',
          );
        }
        isReturn = true;
      });
    } else {
      await openOffline();
    }
    return isReturn;
  }

////////////////////////////////////////////////////////////////////////////////
  static Future<ShiftModelHive> closeShift(BuildContext context) async {
    final closingTime = DateTime.now().millisecondsSinceEpoch;
    int currentShiftKey = Pref.getInt(PrefKeys.currentShiftKey, -1);
    Box<ShiftModelHive> box = HiveBoxes.getShifts();
    final ShiftModelHive shift = getCurrentHiveShift()!;
    final ShiftModelHive returnedShift = shift;
    shift
      ..isUploaded = false
      ..isClosed = true;
    shift.closingTime = closingTime;

    await box.put(currentShiftKey, shift);
    //-------------

    final bool delivered = await syncCloseToServer(
      // Yopilish vaqti, kassir va kassa BIR MARTA olinadi: onlayn yuborilsa
      // ham, navbatga tushsa ham serverga aynan shu qiymatlar ketadi.
      closedAt: DateFormat('yyyy-MM-dd HH:mm:ss').format(clock().toUtc()),
      userId: Pref.getString(PrefKeys.userId, ''),
      cashboxId: Pref.getString(PrefKeys.activatedPosId, ''),
    );
    if (delivered) uploadHiveShifts();
    return returnedShift;
  }

  /// Smena yopilishini serverga yetkazadi. `true` — server darhol tasdiqladi.
  ///
  /// Smena kassada HAR DOIM yopiladi (`shiftsOpened = false`). Server bilan
  /// aloqa bo'lmasa, navbatda serverga yetmagan eski voqealar bo'lsa yoki
  /// server tasdiqlamasa — yopilish navbatga tushadi. Navbat ro'yxat, har
  /// yopilish alohida yoziladi: ilgari navbatda yopish uchun bitta joy bor
  /// edi va internetsiz ikkinchi marta yopib bo'lmasdi.
  ///
  /// ObjectBox'ga tegmaydi (cheklar `closeShift` da) — shuning uchun
  /// testlarda haqiqiy so'rovlar bilan alohida sinaladi.
  @visibleForTesting
  static Future<bool> syncCloseToServer({
    required String closedAt,
    required String userId,
    required String cashboxId,
  }) async {
    Future<void> closeOffline() async {
      await Pref.setBool(PrefKeys.shiftsOpened, false);
      await ShiftSyncQueue.enqueueClose(closedAt,
          userId: userId, cashboxId: cashboxId);
    }

    if (!await BackendHealth.isUsable()) {
      await closeOffline();
      return false;
    }

    if (ShiftSyncQueue.hasPending) {
      // Navbatda serverga yetmagan eski voqealar bor — bu yopilish ularning
      // ORTIDAN ketishi kerak. To'g'ridan-to'g'ri yuborilsa, masalan,
      // oflayn ochilgan smenaning yopilishi ochilishidan OLDIN yetib bekor
      // ketardi (server yopiq kassani yopishga 200 qaytaradi), keyin
      // yetgan ochilish esa kassani serverda ochiq qoldirardi.
      await closeOffline();
      unawaited(ShiftSyncQueue.flush(reason: 'after-close'));
      return false;
    }

    final ShiftingModel shiftingModel = await ShiftApi4.closeShift(
        closedAt: closedAt, userId: userId, cashboxId: cashboxId);
    if (shiftingModel.statusCode == 200 || shiftingModel.statusCode == 201) {
      await Pref.setBool(PrefKeys.shiftsOpened, false);
      return true;
    }

    // Server yopilishni tasdiqlamadi — smena baribir kassada yopiladi,
    // yopilish navbatga tushadi: server yiqilgan bo'lsa keyin yetadi,
    // rad etgan bo'lsa navbat uni hisobot bilan olib tashlaydi.
    await closeOffline();
    return false;
  }

//////////////////////////////////////////////////////////////////////////////
  static Future<void> uploadHiveShifts() async {
    _removeUploadedShiftReceipts(from: 0, to: DateTime.now().millisecond);
  }

  static _removeUploadedShiftReceipts(
      {required int from, required int to}) async {
    final receiptBox = MyObjectbox.saleStore.box<ReceiptModel4>();
    List<int> removedItemID = [];
    receiptBox.getAll().forEach((element) {
      if (element.uploaded == true) {
        removedItemID.add(element.id);
      }
    });

    receiptBox.removeMany(removedItemID);
  }

  static ShiftModelHive _initOfflineShiftOnHive(double startingCash) {
    String cashier = Pref.getString(PrefKeys.cashierName, "not initialized");
    String cashierId = Pref.getString(PrefKeys.cashierId, "not initialized");
    String organization =
        Pref.getString(PrefKeys.organization, "not initialized");
    String posID = Pref.getString(PrefKeys.activatedPosId, "not initialized");
    String posName = Pref.getString(PrefKeys.posName, "not initialized");
    String service = Pref.getInt(PrefKeys.serviceId, -1).toString();
    DateTime openedTime = DateTime.fromMillisecondsSinceEpoch(
        Pref.getInt(PrefKeys.shiftOpenedTime, 0));

    return ShiftModelHive()
      ..isUploaded = false
      ..byWhom = cashierId
      ..byWhomName = cashier
      ..byWhomNameClose = ""
      ..cashDrawerHive = _initZeroCashdrawer(startingCash: startingCash)
      ..closingTime = 0
      ..createdAt = openedTime.toIso8601String()
      ..currency = "uzs"
      ..openingTime = openedTime.millisecondsSinceEpoch
      ..organization = organization
      ..pays = []
      ..pos = posName
      ..posId = posID
      ..salesSummary = _inetZeroSalesSummary()
      ..service = service
      ..updatedAt = openedTime.toIso8601String();
  }

// in use
  static SalesSummaryHive _inetZeroSalesSummary() {
    return SalesSummaryHive()
      ..card = 0
      ..cash = 0
      ..debt = 0
      ..discounts = 0.0
      ..grossSales = 0
      ..netSales = 0
      ..refunds = 0
      ..taxes = 0
      ..cashbackOut = 0
      ..cashbackIn = 0;
  }

// in use
  static CashDrawerHive _initZeroCashdrawer({double startingCash = 0}) {
    return CashDrawerHive()
      ..actCashAmount = 0
      ..cashPayment = 0
      ..cashRefund = 0
      ..difference = 0
      ..expCashAmount = startingCash
      ..inkassa = 0
      ..paidIn = 0
      ..paidOut = 0
      ..startingCash = startingCash
      ..withdrawal = 0;
  }

  static ShiftModelHive? getCurrentHiveShift() {
    final shiftBox = HiveBoxes.getShifts();
    int currentShiftKey = Pref.getInt(PrefKeys.currentShiftKey, -1);
    ShiftModelHive? currentShift = shiftBox.get(currentShiftKey);

    if (currentShift == null) {
      final openedTime = Pref.getInt(PrefKeys.shiftOpenedTime, 0);
    
      if (currentShiftKey < 0 ||
          openedTime <= 0 ||
          !Pref.getBool(PrefKeys.shiftsOpened, false)) {
        return null;
      }
      final restored = _initOfflineShiftOnHive(0)..iV = currentShiftKey;
      shiftBox.put(currentShiftKey, restored);
      currentShift = restored;
    }

    int shiftOpenedTime = currentShift.openingTime!;
    final receiptBox = MyObjectbox.saleStore.box<ReceiptModel4>();
    final receiptQuery = receiptBox
        .query(ReceiptModel4_.date.greaterOrEqual(shiftOpenedTime))
        .build();
    final receipts = receiptQuery.find();

    final ruleCashBox = MyObjectbox.saleStore.box<RuleCashModel4>();
    final ruleCashList = ruleCashBox.getAll();
    double paidIn = 0, paidOut = 0, inkassa = 0;
    for (var e in ruleCashList) {
      if (e.cashType == 0) {
        paidIn += e.money;
      } else if (e.cashType == 1) {
        paidOut += e.money;
      } else if (e.cashType == 2) {
        inkassa += e.money;
      }
    }

    currentShift.cashDrawerHive!
      ..paidIn = paidIn
      ..paidOut = paidOut
      ..inkassa = inkassa;

    double cashRefund = 0;
    double discountAmount = 0;
    double debt = 0;

    /// Payment turlari
    double fromCashback = 0, cashPayment = 0, cardPayment = 0, otherPayment = 0;
    double uzCardPayment = 0, humoCardPayment = 0;
    double clickPayment = 0, clickQrPayment = 0;
    double uzumPayment = 0, uzumQrPayment = 0;
    double paymePayment = 0, paymeQrPayment = 0;

    for (var e in receipts) {
      if (e.isRefund) {
        cashRefund += e.totalPrice;
        continue;
      }

      for (var p in e.payment) {
        final name = p.name.toLowerCase();

        switch (name) {
          case 'cashback':
            fromCashback += p.value;
            break;
          case 'cash':
            cashPayment += p.value;
            break;
          case 'click pass':
            clickPayment += p.value;
            break;
          case 'click qr':
            clickQrPayment += p.value;
            break;
          case 'uzum pass':
            uzumPayment += p.value;
            break;
          case 'uzum qr':
            uzumQrPayment += p.value;
            break;
          case 'payme go':
            paymePayment += p.value;
            break;
          case 'payme qr':
            paymeQrPayment += p.value;
            break;
          case 'humo':
            humoCardPayment += p.value;
            break;
          case 'uzcard':
            uzCardPayment += p.value;
            break;
          case 'debt':
            debt += p.value;
            break;
          default:
            // Agar `name` nomalum bo‘lsa, `cardPayment`ga qo‘shamiz
            otherPayment += p.value;
            break;
        }
      }

      for (var item in e.soldItemList) {

        final double perUnitDiscount = item.realPrice - item.price;
        if (perUnitDiscount > 0) {
          discountAmount += perUnitDiscount * item.value;
        }
      }
    }

    cardPayment += uzCardPayment + humoCardPayment + otherPayment;

    currentShift.salesSummary!
      ..cashbackOut = fromCashback
      ..refunds = cashRefund
      ..discounts = discountAmount
      ..debt = debt
      ..card = cardPayment
      ..cash = cashPayment
      ..uzCard = uzCardPayment
      ..humoCard = humoCardPayment
      ..click = clickPayment
      ..clickQr = clickQrPayment
      ..payme = paymePayment
      ..paymeQr = paymeQrPayment
      ..uzum = uzumPayment
      ..uzumQr = uzumQrPayment
      ..other = otherPayment;

    final grossSales = discountAmount +
        fromCashback +
        cardPayment +
        clickPayment +
        clickQrPayment +
        paymeQrPayment +
        uzumQrPayment +
        uzumPayment +
        paymePayment +
        cashPayment -
        cashRefund +
        debt;

    currentShift.salesSummary!
      ..grossSales = grossSales
      ..netSales = grossSales
      ..taxes = 0;

    currentShift.cashDrawerHive!
      ..cashRefund = cashRefund
      ..cashPayment = cashPayment;

    double expCashAmount = cashPayment +
        paidIn +
        (currentShift.cashDrawerHive!.startingCash ?? 0) -
        (currentShift.cashDrawerHive!.withdrawal ?? 0) -
        cashRefund -
        (currentShift.cashDrawerHive?.inkassa ?? 0) -
        paidOut;

    currentShift.cashDrawerHive!
      ..expCashAmount = expCashAmount
      ..difference = 0;

    receiptQuery.close();
    return currentShift;
  }

  static void saveRuleCash(RuleCashModel4 ruleCashModel4) {
    final box = MyObjectbox.saleStore.box<RuleCashModel4>();
    box.put(ruleCashModel4);
  }
}
