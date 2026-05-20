import 'package:flutter/material.dart';
import 'package:invan2/changes/models/epay/e_pay_model.dart';
import 'package:invan2/utils/helpers/e_pay_helper.dart';
import 'package:invan2/utils/utils.dart';

import '../components/settings_input_field.dart';
import '../components/settings_submit_button.dart';
import '../components/settings_switch.dart';

class UzumContent extends StatefulWidget {
  const UzumContent({Key? key}) : super(key: key);

  @override
  State<UzumContent> createState() => _UzumContentState();
}

class _UzumContentState extends State<UzumContent> {
  final _formKey = GlobalKey<FormState>();
  final _serviceIdController = TextEditingController();
  final _merchantIdController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _merchantUserController = TextEditingController();

  late bool isEnabled;

  final _ePayHelper = EPayHelper.instance;

  @override
  void initState() {
    isEnabled = _ePayHelper.hasEnabled(EPayEnum.uzum);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var pay = EPayModel(
      type: EPayEnum.uzum,
      enabled: false,
      merchantId: "",
      merchantUserId: "",
      secretKey: "",
      serviceId: "",
    );
    EPayModel? epay = _ePayHelper.getPayment(pay);

    _serviceIdController.text = epay?.serviceId ?? "Service Id";
    _merchantIdController.text = epay?.merchantId ?? "Merchant Id";
    _secretKeyController.text = epay?.secretKey ?? "Secret Key";
    _merchantUserController.text = epay?.merchantUserId ?? "Merchant User Id";

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.h * 10,
        vertical: SizeConfig.v * 3,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SettingsSwitch(
              title: "Uzum pay",
              value: isEnabled,
              onChanged: (value) async {
                setState(() => isEnabled = value);
                await _ePayHelper.enablePaymentType(EPayEnum.uzum, value);
              },
            ),
            SizedBox(height: SizeConfig.v * 7),
            SettingsInputField(
              controller: _serviceIdController,
              label: "Service Id",
              enabled: isEnabled,
              onlyDigits: true,
            ),
            SettingsInputField(
              controller: _merchantIdController,
              label: "Merchant Id",
              enabled: isEnabled,
              onlyDigits: true,
            ),
            SettingsInputField(
              controller: _secretKeyController,
              label: "Secret Key",
              onlyDigits: false,
              enabled: isEnabled,
            ),
            SettingsInputField(
              controller: _merchantUserController,
              label: "Merchant User Id",
              enabled: isEnabled,
              onlyDigits: true,
            ),
            SettingsSubmitButtom(onSubmitted: _onSubmitted),
          ],
        ),
      ),
    );
  }

  void _onSubmitted() async {
    if (!isEnabled) return;
    FormState? formState = _formKey.currentState;
    bool isValidate = formState?.validate() ?? false;
    if (!isValidate) return;

    String serviceId = _serviceIdController.text;
    String merchantId = _merchantIdController.text;
    String merchantUserId = _merchantUserController.text.trim();
    String secretKey = _secretKeyController.text;

    EPayModel ePay = EPayModel(
      type: EPayEnum.uzum,
      merchantId: merchantId,
      merchantUserId: merchantUserId,
      secretKey: secretKey,
      serviceId: serviceId,
      enabled: true,
    );
    await _ePayHelper.setPayment(ePay);
    Log.d(ePay, name: 'setting_uzum_data_page');

    _serviceIdController.clear();
    _merchantIdController.clear();
    _secretKeyController.clear();
    _merchantUserController.clear();
    isEnabled = true;
  }
}
