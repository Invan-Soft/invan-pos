import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invan2/app_navigation.dart';
import 'package:invan2/utils/utils.dart';
import 'package:invan2/features/features.dart';

class AutoSyncDialog extends StatefulWidget {
  const AutoSyncDialog({Key? key}) : super(key: key);

  @override
  AutoSyncDialogState createState() => AutoSyncDialogState();
}

class AutoSyncDialogState extends State<AutoSyncDialog> {
  int _interval = 0;
  final _controller = TextEditingController();
  bool isButtonValid = true;

  @override
  void initState() {
    super.initState();
    _interval = Pref.getInt(PrefKeys.autoSyncInterval, 0);
    _controller.text = _interval.toString();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SizeConfig.v),
        side: BorderSide(
          color: Theme.of(context).dividerColor,
        ),
      ),
      content: SizedBox(
        width: SizeConfig.h * 30,
        height: SizeConfig.v * 25,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  loc.oraliq_vaqtni_kiriting,
                  style: MyThemes.txtStyle(
                    color: Theme.of(context).canvasColor,
                    fontSize: 2.6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "  (${loc.daqiqa})",
                  style: MyThemes.txtStyle(
                    color: Theme.of(context).canvasColor,
                    fontSize: 1.6,
                  ),
                ),
              ],
            ),
            TextField(
              autofocus: true,
              onChanged: (v) {
                _interval = int.tryParse(v) ?? 0;
                if (_interval > 0) {
                  isButtonValid = true;
                } else {
                  isButtonValid = false;
                }

                setState(() {});
              },
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                LengthLimitingTextInputFormatter(3),
              ],
              controller: _controller,
              textAlign: TextAlign.center,
              style: MyThemes.txtStyle(
                color: Theme.of(context).canvasColor,
                fontSize: 2.7,
                fontWeight: FontWeight.bold,
              ),
            ),
            MaterialButton(
              focusNode: FocusNode(skipTraversal: true),
              onPressed: isButtonValid
                  ? () async {
                      await Pref.setInt(
                          PrefKeys.autoSyncInterval, (_interval * 60000));
                      await Pref.setBool(PrefKeys.isAutoSyncActive, true);
                      AppNavigation.pop();
                    }
                  : null,
              color: Theme.of(context).primaryColor,
              minWidth: double.infinity,
              height: SizeConfig.v * 7,
              disabledColor: Theme.of(context).primaryColor.withOpacity(.7),
              child: Text(
                loc.saqlash.toUpperCase(),
                style: MyThemes.txtStyle(
                  fontSize: 2.7,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
