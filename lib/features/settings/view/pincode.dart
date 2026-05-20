import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invan2/features/features.dart';
import 'package:invan2/features/settings/bloc/settings_bloc.dart';
import 'package:invan2/utils/helpers/size_config.dart';
import 'package:invan2/utils/themes.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

class PincodeWidgetOfSettingss extends StatefulWidget {
  final PinStatus status;

  const PincodeWidgetOfSettingss({Key? key, required this.status})
      : super(key: key);

  @override
  State<PincodeWidgetOfSettingss> createState() =>
      _PincodeWidgetOfSettingsState();
}

class _PincodeWidgetOfSettingsState extends State<PincodeWidgetOfSettingss> {
  late FocusNode focusNode;
  late TextEditingController controller;

  @override
  void initState() {
    focusNode = FocusNode();
    controller = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (!focusNode.hasFocus) {
      focusNode.requestFocus();
    }
    SettingsBloc settingsBloc = BlocProvider.of(context);
    AppLocalizations loc = AppLocalizations.of(context)!;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: SizeConfig.h * 15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              loc.pinkodni_kiriting,
              textAlign: TextAlign.center,
              style: MyThemes.txtStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 5,
              ),
            ),
            SizedBox(height: SizeConfig.v * 2),
            SizedBox(
              width: SizeConfig.h * 20,
              child: PinCodeTextField(
                controller: controller,
                onCompleted: (v) {
                  settingsBloc.add(SettingsPinCompeteEvent(widget.status, v));
                  controller.text = '';
                  focusNode.requestFocus();
                  setState(() {});
                },
                focusNode: focusNode,
                autoFocus: true,
                textStyle: MyThemes.txtStyle(
                  fontSize: 4,
                  color: Theme.of(context).canvasColor,
                ),
                cursorColor: Colors.transparent,
                pinTheme: PinTheme(
                  activeColor: Theme.of(context).canvasColor,
                  inactiveColor: Theme.of(context).primaryColor,
                  selectedFillColor: Colors.amber,
                  fieldOuterPadding: const EdgeInsets.all(0.0),
                  selectedColor: Theme.of(context).canvasColor,
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(SizeConfig.v),
                  activeFillColor: Theme.of(context).dividerColor,
                  fieldWidth: SizeConfig.h * 4,
                  borderWidth: 2.0,
                ),
                obscureText: true,
                obscuringCharacter: "*",
                appContext: context,
                length: 4,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (String value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
