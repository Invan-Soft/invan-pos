import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../utils/l10n/app_localizations.dart';

class AlicePincodePage extends StatefulWidget {
  const AlicePincodePage({Key? key}) : super(key: key);

  @override
  State<AlicePincodePage> createState() => _AlicePincodePageState();
}

class _AlicePincodePageState extends State<AlicePincodePage> {
  late FocusNode focusNode;
  late TextEditingController controller;

  String? errorText;

  @override
  void initState() {
    focusNode = FocusNode();
    controller = TextEditingController();
    super.initState();
  }
  bool isPinValid(String enteredPin) {
    final now = DateTime.now();

    final pin24 = DateFormat('HHmm').format(now); // 24h format
    final pin12 = DateFormat('hhmm').format(now); // 12h format

    return enteredPin == pin24 || enteredPin == pin12;
  }
  void _checkPin(String enteredPin) {
    if (isPinValid(enteredPin)) {
      Navigator.of(context).pop();
      AppNavigation.showAliceInspector();
    } else {
      setState(() {
        errorText = "❌ Noto‘g‘ri PIN kiritildi";
      });

      controller.clear();
      focusNode.requestFocus();
    }
  }

  Widget _bg(Widget child) {
    return Container(
      width: SizeConfig.h * 40,
      padding: EdgeInsets.all(SizeConfig.h * 3),
      decoration: BoxDecoration(
        color: Theme.of(context).dialogBackgroundColor,
        borderRadius: BorderRadius.circular(SizeConfig.h * 2),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (!focusNode.hasFocus) focusNode.requestFocus();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 6),
      child: _bg(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.lock_outline,
              color: Theme.of(context).primaryColor,
              size: SizeConfig.h * 8,
            ),
            SizedBox(height: SizeConfig.v * 3),
            Text(
              loc.ha == "Ha" ? "Alice tizimiga kirish" : "Вход в систему Alice",
              style: MyThemes.txtStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 6,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: SizeConfig.v),
            Text(
              loc.pinkodni_kiriting,
              style: MyThemes.txtStyle(
                color: Theme.of(context).hintColor,
                fontSize: 4,
              ),
            ),
            SizedBox(height: SizeConfig.v * 3),
            SizedBox(
              width: SizeConfig.h * 22,
              child: PinCodeTextField(
                controller: controller,
                focusNode: focusNode,
                autoFocus: true,
                length: 4,
                obscureText: true,
                obscuringCharacter: "*",
                cursorColor: Colors.transparent,
                appContext: context,
                textStyle: MyThemes.txtStyle(
                  fontSize: 4.5,
                  color: Theme.of(context).canvasColor,
                ),
                pinTheme: PinTheme(
                  activeColor: Theme.of(context).canvasColor,
                  inactiveColor: Theme.of(context).primaryColor,
                  selectedColor: Theme.of(context).canvasColor,
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(SizeConfig.v),
                  fieldWidth: SizeConfig.h * 4.5,
                  borderWidth: 2.0,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onCompleted: _checkPin,
                onChanged: (_) {
                  if (errorText != null) {
                    setState(() {
                      errorText = null;
                    });
                  }
                },
              ),
            ),
            if (errorText != null)
              Padding(
                padding: EdgeInsets.only(top: SizeConfig.v * 1.5),
                child: Text(
                  errorText!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
