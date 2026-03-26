import 'package:flutter/material.dart';
import 'package:invan2/changes/models/epay/e_pay_model.dart';

import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/e_pay_helper.dart';
import 'package:invan2/utils/helpers/helpers.dart';

import '../components/settings_input_field.dart';
import '../components/settings_submit_button.dart';
import '../components/settings_switch.dart';

class PaymeContent extends StatefulWidget {
  const PaymeContent({Key? key}) : super(key: key);

  @override
  State<PaymeContent> createState() => _PaymeContentState();
}

class _PaymeContentState extends State<PaymeContent> {
  final _formKey = GlobalKey<FormState>();

  final _paymeGoMercantId = TextEditingController();
  final _paymeGoKassaPassword = TextEditingController();

  final _ePayHelper = EPayHelper.instance;

  late bool isEnabled;

  @override
  void initState() {
    isEnabled = Pref.getBool(PrefKeys.isPaymegoActivated, false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // _paymeGoMercantId.text =
    //     Pref.getString(PrefKeys.paymeGoMerchantId, "Merchant ID");
    // _paymeGoKassaPassword.text =
    //     Pref.getString(PrefKeys.paymeGoPassword, "Password");
    // isEnabled = Pref.getBool(PrefKeys.isPaymegoActivated, false);
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
                title: "Payme GO",
                value: isEnabled,
                onChanged: (v) async {
                  setState(() => isEnabled = v);
                  await Pref.setBool(PrefKeys.isPaymegoActivated, v);
                }),
            SizedBox(height: SizeConfig.v * 5),
            SettingsInputField(
              controller: _paymeGoMercantId,
              label: "Merchant ID",
              onlyDigits: false,
              enabled: isEnabled,
            ),
            SettingsInputField(
              controller: _paymeGoKassaPassword,
              label: "Password",
              onlyDigits: false,
              enabled: isEnabled,
            ),
            SettingsSubmitButtom(onSubmitted: _onSubmitted)
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
    String merchantId = _paymeGoMercantId.text.trim();
    String password = _paymeGoKassaPassword.text.trim();
    EPayModel ePay = EPayModel(
      type: EPayEnum.payme,
      merchantId: merchantId,
      password: password,
    );
    await _ePayHelper.setPayment(ePay);
    await Pref.setString(PrefKeys.paymeGoMerchantId, merchantId);
    await Pref.setString(PrefKeys.paymeGoPassword, password);
    await Pref.setBool(PrefKeys.isPaymegoActivated, isEnabled);

    setState(() {
      isEnabled = false;
      _paymeGoMercantId.clear();
      _paymeGoKassaPassword.clear();
    });
  }
}
