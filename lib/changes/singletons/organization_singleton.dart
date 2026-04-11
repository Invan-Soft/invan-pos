import 'package:hive/hive.dart';
import 'package:invan2/changes/models/epay/e_pay_model.dart';
import 'package:invan2/changes/models/organization_model.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/prefs.dart';

import '../../utils/helpers/e_pay_helper.dart';

List<Payment> otherPaymentsGlobal = [];

class OrganizationSingleton {
  const OrganizationSingleton._();

  static const String _otherPaymentsBox = 'other_payments';

  static Future<void> setOrgPrefs(OrganizationModel v, List<Payment> pl) async {
    await Pref.setString(PrefKeys.organizationName, v.name ?? "NULLL");
    await Pref.setString(PrefKeys.organizationINN, v.taxPayerId ?? '');
    await Pref.setObject(PrefKeys.organizationModel, v);
    await _initEnabledPayments(pl);
  }

  static Future<void> _initEnabledPayments(List<Payment> v) async {
    bool card = false;
    bool cash = false;

    bool click = false;
    bool payme = false;
    bool uzum = false;

    bool cashback = false;
    bool gift = false;
    bool nfc = false;
    bool debt = false;
    String cardId = "";
    String cashId = "";

    String paymeId = "";
    String clickId = "";
    String uzumId = "";

    String cashbackId = "";
    String giftId = "";
    String nfcId = "";
    String debtId = "";
    String creditId = "";
    String advanceId = "";

    List<Payment> otherPayments = [];
    final box = await Hive.openBox<Payment>(_otherPaymentsBox);
    await box.clear();

    for (int i = 0; i < v.length; i++) {

      if (v[i].name == 'CASH') {
        cash = v[i].isAdded!;
        cashId = v[i].id!;
      } else if (v[i].name == 'PAYME') {
        payme = v[i].isAdded!;
        _onSubmittedPayme(v[i]);
        paymeId = v[i].id!;
      } else if (v[i].name == 'CLICK') {
        click = v[i].isAdded!;
        _onSubmittedClick(v[i]);
        clickId = v[i].id!;
      } else if (v[i].name == 'UZUM') {
        uzum = v[i].isAdded!;
        _onSubmittedUzum(v[i]);
        uzumId = v[i].id!;
      } else if (v[i].name == 'CARD') {
        card = v[i].isAdded!;
        cardId = v[i].id!;
      } else if (v[i].name == 'CASHBACK') {
        cashback = v[i].isAdded!;
        cashbackId = v[i].id!;
      } else if (v[i].name == 'gift') {
        giftId = v[i].id!;
        gift = v[i].isAdded!;
      } else if (v[i].name == 'DEBT') {
        debtId = v[i].id!;
        debt = v[i].isAdded!;
      } else if (v[i].name == 'nfc') {
        nfcId = v[i].id!;
        nfc = v[i].isAdded!;
      } else if (v[i].name?.toUpperCase() == 'CREDIT') {
        creditId = v[i].id!;
      } else if (v[i].name?.toUpperCase() == 'ADVANCE') {
        advanceId = v[i].id!;
      }
      otherPayments.add(v[i]);
    }

    await box.addAll(otherPayments);
    await OrganizationSingleton.setOtherPayments();

    await Pref.setBool(PrefKeys.cashEnabled, cash);
    await Pref.setBool(PrefKeys.cardEnabled, card);
    await Pref.setBool(PrefKeys.cashbackEnable, cashback);

    await Pref.setBool(PrefKeys.clickEnable, click);
    await Pref.setBool(PrefKeys.paymeEnable, payme);
    await Pref.setBool(PrefKeys.uzumEnable, uzum);

    await Pref.setBool(PrefKeys.giftEnabled, gift);
    await Pref.setBool(PrefKeys.debtEnabled, debt);
    await Pref.setBool(PrefKeys.nfcEnabled, nfc);

    //////////////////////////

    await Pref.setString(PrefKeys.cashId, cashId);
    await Pref.setString(PrefKeys.cardId, cardId);
    await Pref.setString(PrefKeys.cashbackId, cashbackId);

    await Pref.setString(PrefKeys.clickId, clickId);
    await Pref.setString(PrefKeys.uzumId, uzumId);
    await Pref.setString(PrefKeys.paymeId, paymeId);

    await Pref.setString(PrefKeys.giftId, giftId);
    await Pref.setString(PrefKeys.debtId, debtId);
    await Pref.setString(PrefKeys.nfcId, nfcId);
    await Pref.setString(PrefKeys.creditId, creditId);
    await Pref.setString(PrefKeys.advanceId, advanceId);
  }

  static Future<List<Payment>> getOtherPayments() async {
    final box = await Hive.openBox<Payment>(_otherPaymentsBox);
    return box.values.toList();
  }

  static Future<void> setOtherPayments() async {
    otherPaymentsGlobal = [];
    otherPaymentsGlobal = await OrganizationSingleton.getOtherPayments();
  }

  static final _ePayHelper = EPayHelper.instance;

  static _onSubmittedClick(Payment payment) async {
    if (payment.isAdded ?? false) {
      EPayModel ePay = EPayModel(
        type: EPayEnum.click,
        merchantId: payment.merchantId.toString(),
        merchantUserId: payment.merchantUserId.toString(),
        secretKey: payment.secretKey,
        serviceId: payment.serviceId.toString(),
      );
      await _ePayHelper.setPayment(ePay);
      await Pref.setInt(PrefKeys.serviceId, payment.serviceId ?? 0);
      await Pref.setInt(
          PrefKeys.merchantId, int.parse(payment.merchantId ?? "0"));
      await Pref.setString(PrefKeys.secretKeyOfClick, payment.secretKey ?? "");
      await Pref.setInt(
          PrefKeys.merchantUserId, int.parse(payment.merchantId ?? "0"));
      await Pref.setBool(
          PrefKeys.isClickPassActivated, payment.isAdded ?? false);
    }
  }

  static void _onSubmittedUzum(Payment payment) async {
    if (payment.isAdded ?? false) {
      EPayModel ePay = EPayModel(
        type: EPayEnum.uzum,
        merchantId: payment.merchantId.toString(),
        merchantUserId: payment.merchantUserId.toString(),
        secretKey: payment.secretKey,
        serviceId: payment.serviceId.toString(),
        enabled: payment.isAdded,
      );

      await _ePayHelper.setPayment(ePay);
    }
  }

  static void _onSubmittedPayme(Payment payment) async {
    if (payment.isAdded ?? false) {
      EPayModel ePay = EPayModel(
        type: EPayEnum.payme,
        merchantId: payment.merchantId.toString(),
        password: payment.password,
      );
      await _ePayHelper.setPayment(ePay);
      await Pref.setString(
          PrefKeys.paymeGoMerchantId, payment.merchantId.toString());
      await Pref.setString(
          PrefKeys.paymeGoPassword, payment.password.toString());
      await Pref.setBool(PrefKeys.isPaymegoActivated, payment.isAdded ?? false);
    }
  }
}
