// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import 'package:invan2/changes/models/epay/e_pay_model.dart';
import 'package:invan2/utils/constants/constants.dart';
import 'package:invan2/utils/helpers/e_pay_helper.dart';
import 'package:invan2/utils/helpers/helpers.dart';

import '../components/settings_input_field.dart';
import '../components/settings_submit_button.dart';
import '../components/settings_switch.dart';

class ClickContent extends StatefulWidget {
  const ClickContent({Key? key}) : super(key: key);

  @override
  State<ClickContent> createState() => _ClickContentState();
}

class _ClickContentState extends State<ClickContent> {
  final _formKey = GlobalKey<FormState>();
  final _serviceIdController = TextEditingController();
  final _merchantIdController = TextEditingController();
  final _secretKeyController = TextEditingController();
  final _merchantUserIdcontroller = TextEditingController();
  final _ePayHelper = EPayHelper.instance;

  late bool isEnabled;

  @override
  void initState() {
    isEnabled = Pref.getBool(PrefKeys.isClickPassActivated, false);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // _serviceIdController.text = Pref.getInt(PrefKeys.serviceId, 0).toString();
    // _merchantIdController.text = Pref.getInt(PrefKeys.merchantId, 0).toString();
    // _secretKeyController.text = Pref.getString(PrefKeys.secretKeyOfClick, "");
    // _merchantUserIdcontroller.text =
    //     Pref.getInt(PrefKeys.merchantUserId, 0).toString();
    // isEnabled = Pref.getBool(PrefKeys.isClickPassActivated, false);
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
              title: "Click pass",
              value: isEnabled,
              onChanged: (value) async {
                await Pref.setBool('PrefKeys.isClickPassActivated', value);
                setState(() => isEnabled = value);
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
              enabled: isEnabled,
              onlyDigits: true,
              controller: _merchantIdController,
              label: "Merchant Id",
            ),
            SettingsInputField(
              enabled: isEnabled,
              controller: _secretKeyController,
              label: "Secret Key",
              onlyDigits: false,
            ),
            SettingsInputField(
              enabled: isEnabled,
              onlyDigits: true,
              controller: _merchantUserIdcontroller,
              label: "Merchant User Id",
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
    String merchantUserId = _merchantUserIdcontroller.text;
    String sercetKey = _secretKeyController.text.trim();

    EPayModel ePay = EPayModel(
      type: EPayEnum.click,
      merchantId: merchantId,
      merchantUserId: merchantUserId,
      secretKey: sercetKey,
      serviceId: serviceId,
    );

    await _ePayHelper.setPayment(ePay);

    await Pref.setInt(PrefKeys.serviceId, int.parse(serviceId));
    await Pref.setInt(PrefKeys.merchantId, int.parse(merchantId));
    await Pref.setString(PrefKeys.secretKeyOfClick, sercetKey);
    await Pref.setInt(PrefKeys.merchantUserId, int.parse(merchantUserId));
    await Pref.setBool(PrefKeys.isClickPassActivated, true);
    setState(() {
      _serviceIdController.text = '';
      _merchantIdController.text = '';
      _secretKeyController.text = '';
      _merchantUserIdcontroller.text = '';
      isEnabled = Pref.getBool(PrefKeys.isClickPassActivated, false);
    });
  }
}
