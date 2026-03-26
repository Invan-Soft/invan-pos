import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:invan2/changes/components/form_validator.dart';
import 'package:invan2/widgets/default_button.dart';
import 'package:invan2/widgets/inputs/app_text_field.dart';

import '../../../../../utils/helpers/prefs.dart';
import '../../../../../utils/helpers/size_config.dart';
import '../../../../../utils/themes.dart';

class QRCodeDialog extends StatefulWidget {
  const QRCodeDialog({Key? key}) : super(key: key);

  @override
  State<QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<QRCodeDialog> {
  final GlobalKey<FormState> formKey = GlobalKey();
  final TextEditingController urlController = TextEditingController();
  late bool qRcode;
  @override
  Widget build(BuildContext context) {
    qRcode = Pref.getBool('enableQrReceipts', false);
    urlController.text = Pref.getString('setQrUrl', '');
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
                      "Enable or Disable QR code receipts",
                      style: MyThemes.txtStyle(
                          fontSize: 2, color: Theme.of(context).canvasColor),
                    ),
                  ),
                  trailing: ClipRRect(
                    child: CupertinoSwitch(
                        value: qRcode,
                        onChanged: (v) {
                          Pref.setBool('enableQrReceipts', v);
                          setState(() {});
                        }),
                  ),
                ),
                const SizedBox(height: 40),
                AppTextFormField(
                  enabled: qRcode,
                  controller: urlController,
                  title: "URL",
                  hint: "Введите URL-адрес",
                  validator: FormValidator.general,
                ),
                DefaultButton(
                  text: 'Create',
                  isButtonEnabled: true,
                  onPress: qRcode == true
                      ? () async {
                          await Pref.setString('setQrUrl', urlController.text);
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
