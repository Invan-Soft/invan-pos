import 'package:hive/hive.dart';
import 'package:invan2/changes/models/epay/e_pay_model.dart';

class EPayHelper {
  EPayHelper._();
  static final EPayHelper instance = EPayHelper._();
  final Box<EPayModel> box = Hive.box('epay');

  Future<void> setPayment(EPayModel ePay) async {
    await box.put(ePay.type.value, ePay);
  }

  EPayModel? getPayment(EPayModel ePay) {
    return box.get(ePay.type.value, defaultValue: ePay);
  }

  Future<void> enablePaymentType(EPayEnum ePayEnum, bool value) async {
    EPayModel? ePay = box.get(ePayEnum.value);
    if (ePay == null) return;
    ePay.setEnabled = value;
    await ePay.save();
  }

  bool hasEnabled(EPayEnum ePayEnum) =>
      box.get(ePayEnum.value)?.enabled ?? false;
}
