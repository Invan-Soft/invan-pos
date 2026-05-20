import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/changes/components/form_validator.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:invan2/widgets/inputs/app_text_field.dart';

import '../../../../../utils/constants/pref_keys.dart';
import '../../../../../utils/helpers/prefs.dart';
import '../../../../../utils/helpers/size_config.dart';
import '../../../../../utils/themes.dart';

class TerminalIDDialog extends StatefulWidget {
  const TerminalIDDialog({Key? key}) : super(key: key);

  @override
  State<TerminalIDDialog> createState() => _TerminalIDDialogState();
}

class _TerminalIDDialogState extends State<TerminalIDDialog> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController treminalID = TextEditingController();
  late bool isSwitch;
  @override
  Widget build(BuildContext context) {
    isSwitch = Pref.getBool(PrefKeys.isSwitchTerminal, false);
    treminalID.text = Pref.getString(PrefKeys.terminalID, '');
    return Card(
      shadowColor: Colors.white,
      elevation: 3,
      color: Theme.of(context).colorScheme.background,
      child: SizedBox(
        height: 600,
        width: 800,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 80),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.h * .5,
                    vertical: SizeConfig.v * 1.5,
                  ),
                  onTap: () {},
                  title: Padding(
                    padding: EdgeInsets.symmetric(horizontal: SizeConfig.v),
                    child: Text(
                      "Enable or Disable Terminal ID  ",
                      style: MyThemes.txtStyle(
                          fontSize: 2, color: Theme.of(context).canvasColor),
                    ),
                  ),
                  trailing: ClipRRect(
                    child: CupertinoSwitch(
                        value: isSwitch,
                        onChanged: (v) {
                          Pref.setBool(PrefKeys.isSwitchTerminal, v);
                          setState(() {});
                        }),
                  ),
                ),
                const SizedBox(height: 40),
                AppTextFormField(
                  enabled: isSwitch,
                  controller: treminalID,
                  title: "Terminal ID",
                  hint: "Введите Terminal ID",
                  validator: FormValidator.general,
                ),
                DefaultButton(
                  text: 'Enter',
                  isButtonEnabled: true,
                  onPress: isSwitch == true
                      ? () async {
                          await Pref.setString(
                              PrefKeys.terminalID, treminalID.text);
                          // ignore: use_build_context_synchronously
                          Navigator.pop(context);
                        }
                      : () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
